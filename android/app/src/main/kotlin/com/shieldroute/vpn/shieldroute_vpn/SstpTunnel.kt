package com.shieldroute.vpn.shieldroute_vpn

import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import java.io.DataInputStream
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLSocket
import javax.net.ssl.SSLSocketFactory

/**
 * Minimal MS-SSTP client (SSTP over TLS, PPP with PAP, IPCP) feeding an Android TUN.
 *
 * SSTP looks like ordinary HTTPS on the wire, so it works on networks whose deep
 * packet inspection resets OpenVPN handshakes. VPN Gate relays accept it on the
 * same TCP port they publish for OpenVPN, with a valid `*.opengw.net` certificate,
 * so the TLS session is fully verified against the relay's hostname.
 *
 * [run] blocks until the tunnel ends; call [stop] from any thread to end it.
 */
class SstpTunnel(
    private val service: VpnService,
    private val config: Config,
    private val listener: Listener,
) {
    data class Config(
        /** TLS/SNI hostname, e.g. `public-vpn-108.opengw.net`. */
        val hostname: String,
        /** IP address to dial (avoids a DNS lookup that could be blocked). */
        val address: String,
        val port: Int,
        val username: String,
        val password: String,
        val sessionName: String,
    )

    interface Listener {
        fun onConnected(assignedIp: String)
        fun onTraffic(bytesIn: Long, bytesOut: Long)
    }

    class SstpException(message: String) : IOException(message)

    private val running = AtomicBoolean(true)
    private val stopRequested = AtomicBoolean(false)

    /** True once [stop] was called, so failures after it are not errors. */
    val wasStopped: Boolean get() = stopRequested.get()
    private val bytesIn = AtomicLong(0)
    private val bytesOut = AtomicLong(0)
    private val writeLock = Any()

    private var socket: SSLSocket? = null
    private var tun: ParcelFileDescriptor? = null
    private lateinit var input: DataInputStream
    private lateinit var output: OutputStream

    fun stop() {
        stopRequested.set(true)
        if (!running.getAndSet(false)) return
        try {
            sendControl(MSG_CALL_DISCONNECT)
        } catch (_: Exception) {
        }
        closeQuietly()
    }

    /** Connects, runs the tunnel until it ends, and throws if it fails. */
    fun run() {
        try {
            val certDer = openTls()
            httpHandshake()
            val binding = callConnect()
            val ipConfig = negotiatePpp(certDer, binding)
            establishTun(ipConfig)
            listener.onConnected(ipConfig.address.hostAddress ?: "")
            pump()
        } finally {
            closeQuietly()
        }
    }

    // ── TLS + HTTP ──────────────────────────────────────────────────────────

    private fun openTls(): ByteArray {
        val raw = Socket()
        raw.bind(null)
        // Keep the control connection outside the tunnel it carries.
        if (!service.protect(raw)) throw SstpException("Could not protect VPN socket")
        raw.connect(InetSocketAddress(InetAddress.getByName(config.address), config.port), CONNECT_TIMEOUT_MS)
        raw.soTimeout = HANDSHAKE_TIMEOUT_MS
        raw.tcpNoDelay = true

        val ssl = (SSLSocketFactory.getDefault() as SSLSocketFactory)
            .createSocket(raw, config.hostname, config.port, true) as SSLSocket
        ssl.startHandshake()
        val session = ssl.session
        if (!HttpsURLConnection.getDefaultHostnameVerifier().verify(config.hostname, session)) {
            ssl.close()
            throw SstpException("Relay certificate does not match ${config.hostname}")
        }
        socket = ssl
        input = DataInputStream(ssl.inputStream.buffered(64 * 1024))
        output = ssl.outputStream
        return session.peerCertificates[0].encoded
    }

    private fun httpHandshake() {
        val request = "SSTP_DUPLEX_POST /sra_{BA195980-CD49-458b-9E23-C84EE0ADCD75}/ HTTP/1.1\r\n" +
            "Content-Length: 18446744073709551615\r\n" +
            "Host: ${config.hostname}\r\n" +
            "SSTPCORRELATIONID: {${UUID.randomUUID().toString().uppercase()}}\r\n\r\n"
        write(request.toByteArray(Charsets.US_ASCII))

        val header = StringBuilder()
        while (!header.endsWith("\r\n\r\n")) {
            val b = input.read()
            if (b < 0) throw SstpException("Relay closed the connection during setup")
            header.append(b.toChar())
            if (header.length > 4096) throw SstpException("Malformed relay response")
        }
        val status = header.lineSequence().first()
        if (!status.contains(" 200")) throw SstpException("Relay refused SSTP: $status")
    }

    // ── SSTP control ────────────────────────────────────────────────────────

    private class Binding(val hashBitmask: Int, val nonce: ByteArray)

    private fun callConnect(): Binding {
        val attr = ByteBuffer.allocate(6)
            .put(0).put(ATTR_ENCAPSULATED_PROTOCOL_ID).putShort(6).putShort(1)
            .array()
        sendControl(MSG_CALL_CONNECT_REQUEST, attr, 1)

        while (true) {
            val packet = readPacket()
            if (!packet.isControl) continue
            when (packet.messageType) {
                MSG_CALL_CONNECT_ACK -> {
                    val attrs = packet.body
                    // attrs: [reserved][id=4][len:2][reserved:3][hash bitmask][nonce:32]
                    if (attrs.size < 40 || attrs[1] != ATTR_CRYPTO_BINDING_REQ) {
                        throw SstpException("Relay sent no crypto binding request")
                    }
                    return Binding(attrs[7].toInt() and 0xFF, attrs.copyOfRange(8, 40))
                }
                MSG_CALL_CONNECT_NAK -> throw SstpException("Relay rejected the SSTP call")
                MSG_CALL_ABORT, MSG_CALL_DISCONNECT -> throw SstpException("Relay aborted the SSTP call")
            }
        }
    }

    private fun sendCallConnected(certDer: ByteArray, binding: Binding) {
        val sha256 = binding.hashBitmask and 2 != 0
        val algorithm = if (sha256) "SHA-256" else "SHA-1"
        val macAlgorithm = if (sha256) "HmacSHA256" else "HmacSHA1"
        val hashLength = if (sha256) 32 else 20

        // PAP derives no keys, so the higher-layer key is all zeros [MS-SSTP 3.2.5.2.3].
        val hlak = ByteArray(32)
        val cmk = hmac(macAlgorithm, hlak, CMK_SEED + byteArrayOf(hashLength.toByte(), 0, 1))
        val certHash = MessageDigest.getInstance(algorithm).digest(certDer).copyOf(32)

        val attr = ByteBuffer.allocate(104)
            .put(0).put(ATTR_CRYPTO_BINDING).putShort(104)
            .put(0).put(0).put(0).put(if (sha256) 2 else 1)
            .put(binding.nonce)
            .put(certHash)
            .put(ByteArray(32))
            .array()
        val packet = controlPacket(MSG_CALL_CONNECTED, attr, 1)
        val mac = hmac(macAlgorithm, cmk, packet).copyOf(32)
        System.arraycopy(mac, 0, packet, packet.size - 32, 32)
        write(packet)
    }

    // ── PPP ─────────────────────────────────────────────────────────────────

    private class IpConfig(val address: InetAddress, val dns: List<InetAddress>, val mtu: Int)

    private fun negotiatePpp(certDer: ByteArray, binding: Binding): IpConfig {
        var lcpLocalUp = false
        var lcpRemoteUp = false
        var authRequested = false
        var authed = false
        var ipcpLocalUp = false
        var ipcpRemoteUp = false
        var mru = DEFAULT_MRU
        var ipcpId = 10
        val ipOptions = linkedMapOf(
            IPCP_ADDRESS to ByteArray(4),
            IPCP_PRIMARY_DNS to ByteArray(4),
            IPCP_SECONDARY_DNS to ByteArray(4),
        )

        fun sendIpcpRequest() {
            ipcpId++
            val opts = ByteBuffer.allocate(ipOptions.size * 6)
            ipOptions.forEach { (type, value) -> opts.put(type.toByte()).put(6).put(value) }
            sendPpp(PROTO_IPCP, pppPacket(CODE_CONF_REQ, ipcpId, opts.array()))
        }

        sendPpp(PROTO_LCP, pppPacket(CODE_CONF_REQ, 1, option(LCP_MRU, shortBytes(DEFAULT_MRU))))

        val deadline = System.currentTimeMillis() + HANDSHAKE_TIMEOUT_MS
        while (!(ipcpLocalUp && ipcpRemoteUp)) {
            if (System.currentTimeMillis() > deadline) throw SstpException("PPP negotiation timed out")
            val packet = readPacket()
            if (packet.isControl) {
                handleControl(packet)
                continue
            }
            val frame = PppFrame.parse(packet.body) ?: continue
            when (frame.protocol) {
                PROTO_LCP -> when (frame.code) {
                    CODE_CONF_REQ -> {
                        var nak = ByteArray(0)
                        for ((type, value) in parseOptions(frame.data)) {
                            if (type == LCP_AUTH) {
                                val protocol = ((value[0].toInt() and 0xFF) shl 8) or (value[1].toInt() and 0xFF)
                                if (protocol != PROTO_PAP) nak += option(LCP_AUTH, shortBytes(PROTO_PAP))
                            }
                        }
                        if (nak.isNotEmpty()) {
                            sendPpp(PROTO_LCP, pppPacket(CODE_CONF_NAK, frame.id, nak))
                        } else {
                            sendPpp(PROTO_LCP, pppPacket(CODE_CONF_ACK, frame.id, frame.data))
                            lcpRemoteUp = true
                        }
                    }
                    CODE_CONF_ACK -> lcpLocalUp = true
                    CODE_CONF_NAK -> {
                        parseOptions(frame.data).firstOrNull { it.first == LCP_MRU }?.let {
                            mru = ((it.second[0].toInt() and 0xFF) shl 8) or (it.second[1].toInt() and 0xFF)
                        }
                        sendPpp(PROTO_LCP, pppPacket(CODE_CONF_REQ, frame.id + 1, option(LCP_MRU, shortBytes(mru))))
                    }
                    CODE_CONF_REJ -> sendPpp(PROTO_LCP, pppPacket(CODE_CONF_REQ, frame.id + 1, ByteArray(0)))
                    CODE_TERM_REQ -> throw SstpException("Relay closed the PPP link")
                    else -> handleLcpMaintenance(frame)
                }
                PROTO_PAP -> {
                    if (frame.code == CODE_PAP_ACK) {
                        authed = true
                        sendCallConnected(certDer, binding)
                        sendIpcpRequest()
                    } else {
                        throw SstpException("Relay rejected the login")
                    }
                }
                PROTO_IPCP -> when (frame.code) {
                    CODE_CONF_REQ -> {
                        sendPpp(PROTO_IPCP, pppPacket(CODE_CONF_ACK, frame.id, frame.data))
                        ipcpRemoteUp = true
                    }
                    CODE_CONF_NAK -> {
                        for ((type, value) in parseOptions(frame.data)) {
                            if (value.size == 4) ipOptions[type] = value
                        }
                        sendIpcpRequest()
                    }
                    CODE_CONF_REJ -> {
                        for ((type, _) in parseOptions(frame.data)) {
                            if (type != IPCP_ADDRESS) ipOptions.remove(type)
                        }
                        sendIpcpRequest()
                    }
                    CODE_CONF_ACK -> if (authed) ipcpLocalUp = true
                }
                else -> rejectProtocol(frame)
            }

            if (lcpLocalUp && lcpRemoteUp && !authRequested) {
                authRequested = true
                val user = config.username.toByteArray()
                val pass = config.password.toByteArray()
                val body = byteArrayOf(user.size.toByte()) + user + byteArrayOf(pass.size.toByte()) + pass
                sendPpp(PROTO_PAP, pppPacket(CODE_PAP_REQ, 1, body))
            }
        }

        val address = InetAddress.getByAddress(ipOptions.getValue(IPCP_ADDRESS))
        val dns = listOf(IPCP_PRIMARY_DNS, IPCP_SECONDARY_DNS)
            .mapNotNull { ipOptions[it] }
            .filter { bytes -> bytes.any { it.toInt() != 0 } }
            .map { InetAddress.getByAddress(it) }
        // SSTP + PPP framing adds ~ 20 bytes inside the relay's MRU.
        return IpConfig(address, dns, minOf(mru, DEFAULT_MRU) - 100)
    }

    private fun handleLcpMaintenance(frame: PppFrame) {
        when (frame.code) {
            CODE_ECHO_REQ -> {
                // Echo-Reply carries our magic number (0: none negotiated) then the data.
                val data = ByteArray(4) + frame.data.copyOfRange(minOf(4, frame.data.size), frame.data.size)
                sendPpp(PROTO_LCP, pppPacket(CODE_ECHO_REPLY, frame.id, data))
            }
            CODE_TERM_REQ -> {
                sendPpp(PROTO_LCP, pppPacket(CODE_TERM_ACK, frame.id, ByteArray(0)))
                throw SstpException("Relay closed the PPP link")
            }
        }
    }

    private fun rejectProtocol(frame: PppFrame) {
        val rejected = shortBytes(frame.protocol) + frame.raw
        sendPpp(PROTO_LCP, pppPacket(CODE_PROTO_REJ, 99, rejected))
    }

    private fun handleControl(packet: SstpPacket) {
        when (packet.messageType) {
            MSG_ECHO_REQUEST -> sendControl(MSG_ECHO_RESPONSE)
            MSG_CALL_DISCONNECT -> {
                sendControl(MSG_CALL_DISCONNECT_ACK)
                throw SstpException("Relay ended the session")
            }
            MSG_CALL_ABORT -> throw SstpException("Relay aborted the session")
        }
    }

    // ── Tunnel ──────────────────────────────────────────────────────────────

    private fun establishTun(ip: IpConfig) {
        val builder = service.Builder()
            .setSession(config.sessionName)
            .setMtu(ip.mtu)
            .addAddress(ip.address, 32)
            .addRoute("0.0.0.0", 0)
            .setBlocking(true)
        val dns = ip.dns.ifEmpty { listOf(InetAddress.getByName("1.1.1.1")) }
        dns.forEach { builder.addDnsServer(it) }
        // The app's own traffic (relay catalog, latency probes) stays outside.
        try {
            builder.addDisallowedApplication(service.packageName)
        } catch (_: Exception) {
        }
        tun = builder.establish() ?: throw SstpException("VPN permission was revoked")
    }

    private fun pump() {
        val tunFd = tun ?: return
        socket?.soTimeout = IDLE_TIMEOUT_MS

        val upstream = Thread({
            val tunIn = FileInputStream(tunFd.fileDescriptor)
            val buffer = ByteArray(32 * 1024)
            try {
                while (running.get()) {
                    val n = tunIn.read(buffer)
                    if (n <= 0) continue
                    sendPpp(PROTO_IP, buffer.copyOf(n))
                    bytesOut.addAndGet(n.toLong())
                }
            } catch (e: Exception) {
                if (running.get()) Log.w(TAG, "TUN read ended: ${e.message}")
                running.set(false)
                closeQuietly()
            }
        }, "sstp-upstream").apply { isDaemon = true; start() }

        val keepAlive = Thread({
            try {
                while (running.get()) {
                    Thread.sleep(KEEPALIVE_MS)
                    sendControl(MSG_ECHO_REQUEST)
                }
            } catch (_: Exception) {
            }
        }, "sstp-keepalive").apply { isDaemon = true; start() }

        val reporter = Thread({
            try {
                while (running.get()) {
                    listener.onTraffic(bytesIn.get(), bytesOut.get())
                    Thread.sleep(1000)
                }
            } catch (_: InterruptedException) {
            }
        }, "sstp-traffic").apply { isDaemon = true; start() }

        val tunOut = FileOutputStream(tunFd.fileDescriptor)
        try {
            while (running.get()) {
                val packet = readPacket()
                if (packet.isControl) {
                    handleControl(packet)
                    continue
                }
                val frame = PppFrame.parse(packet.body) ?: continue
                when (frame.protocol) {
                    PROTO_IP -> {
                        tunOut.write(frame.raw)
                        bytesIn.addAndGet(frame.raw.size.toLong())
                    }
                    PROTO_LCP -> handleLcpMaintenance(frame)
                    PROTO_IPCP, PROTO_PAP -> Unit
                    else -> rejectProtocol(frame)
                }
            }
        } catch (e: Exception) {
            if (running.get()) throw e
        } finally {
            running.set(false)
            upstream.interrupt()
            keepAlive.interrupt()
            reporter.interrupt()
        }
    }

    // ── Framing ─────────────────────────────────────────────────────────────

    private class SstpPacket(val isControl: Boolean, val messageType: Int, val body: ByteArray)

    private fun readPacket(): SstpPacket {
        val header = ByteArray(4)
        input.readFully(header)
        if (header[0] != SSTP_VERSION) throw SstpException("Unexpected SSTP version")
        val isControl = header[1].toInt() and 1 == 1
        val length = ((header[2].toInt() and 0x0F) shl 8) or (header[3].toInt() and 0xFF)
        if (length < 4) throw SstpException("Malformed SSTP packet")
        val payload = ByteArray(length - 4)
        input.readFully(payload)
        if (!isControl) return SstpPacket(false, 0, payload)
        val type = ((payload[0].toInt() and 0xFF) shl 8) or (payload[1].toInt() and 0xFF)
        return SstpPacket(true, type, payload.copyOfRange(4, payload.size))
    }

    private class PppFrame(val protocol: Int, val code: Int, val id: Int, val data: ByteArray, val raw: ByteArray) {
        companion object {
            fun parse(body: ByteArray): PppFrame? {
                var offset = 0
                if (body.size >= 2 && body[0] == 0xFF.toByte() && body[1] == 0x03.toByte()) offset = 2
                if (body.size < offset + 1) return null
                val first = body[offset].toInt() and 0xFF
                // Protocol-field compression sends odd single-byte protocol numbers.
                val protocol: Int
                if (first and 1 == 1) {
                    protocol = first
                    offset += 1
                } else {
                    if (body.size < offset + 2) return null
                    protocol = (first shl 8) or (body[offset + 1].toInt() and 0xFF)
                    offset += 2
                }
                val raw = body.copyOfRange(offset, body.size)
                if (protocol == PROTO_IP || raw.size < 4) return PppFrame(protocol, 0, 0, ByteArray(0), raw)
                val length = (((raw[2].toInt() and 0xFF) shl 8) or (raw[3].toInt() and 0xFF)).coerceIn(4, raw.size)
                return PppFrame(protocol, raw[0].toInt() and 0xFF, raw[1].toInt() and 0xFF, raw.copyOfRange(4, length), raw)
            }
        }
    }

    private fun parseOptions(data: ByteArray): List<Pair<Int, ByteArray>> {
        val result = mutableListOf<Pair<Int, ByteArray>>()
        var i = 0
        while (i + 2 <= data.size) {
            val type = data[i].toInt() and 0xFF
            val len = data[i + 1].toInt() and 0xFF
            if (len < 2 || i + len > data.size) break
            result += type to data.copyOfRange(i + 2, i + len)
            i += len
        }
        return result
    }

    private fun sendPpp(protocol: Int, payload: ByteArray) {
        val length = 4 + 4 + payload.size
        val packet = ByteBuffer.allocate(length)
            .put(SSTP_VERSION).put(0).putShort(length.toShort())
            .put(0xFF.toByte()).put(0x03).putShort(protocol.toShort())
            .put(payload)
            .array()
        write(packet)
    }

    private fun controlPacket(type: Int, attrs: ByteArray = ByteArray(0), count: Int = 0): ByteArray {
        val length = 8 + attrs.size
        return ByteBuffer.allocate(length)
            .put(SSTP_VERSION).put(1).putShort(length.toShort())
            .putShort(type.toShort()).putShort(count.toShort())
            .put(attrs)
            .array()
    }

    private fun sendControl(type: Int, attrs: ByteArray = ByteArray(0), count: Int = 0) =
        write(controlPacket(type, attrs, count))

    private fun write(bytes: ByteArray) {
        synchronized(writeLock) {
            output.write(bytes)
            output.flush()
        }
    }

    private fun closeQuietly() {
        running.set(false)
        try {
            socket?.close()
        } catch (_: Exception) {
        }
        try {
            tun?.close()
        } catch (_: Exception) {
        }
        socket = null
        tun = null
    }

    companion object {
        private const val TAG = "SstpTunnel"

        private const val CONNECT_TIMEOUT_MS = 10_000
        private const val HANDSHAKE_TIMEOUT_MS = 20_000
        private const val IDLE_TIMEOUT_MS = 90_000
        private const val KEEPALIVE_MS = 25_000L
        private const val DEFAULT_MRU = 1500

        private const val SSTP_VERSION: Byte = 0x10
        private const val MSG_CALL_CONNECT_REQUEST = 0x0001
        private const val MSG_CALL_CONNECT_ACK = 0x0002
        private const val MSG_CALL_CONNECT_NAK = 0x0003
        private const val MSG_CALL_CONNECTED = 0x0004
        private const val MSG_CALL_ABORT = 0x0005
        private const val MSG_CALL_DISCONNECT = 0x0006
        private const val MSG_CALL_DISCONNECT_ACK = 0x0007
        private const val MSG_ECHO_REQUEST = 0x0008
        private const val MSG_ECHO_RESPONSE = 0x0009

        private const val ATTR_ENCAPSULATED_PROTOCOL_ID: Byte = 1
        private const val ATTR_CRYPTO_BINDING: Byte = 3
        private const val ATTR_CRYPTO_BINDING_REQ: Byte = 4
        private val CMK_SEED = "SSTP inner method derived CMK".toByteArray(Charsets.US_ASCII)

        private const val PROTO_IP = 0x0021
        private const val PROTO_IPCP = 0x8021
        private const val PROTO_LCP = 0xC021
        private const val PROTO_PAP = 0xC023

        private const val CODE_CONF_REQ = 1
        private const val CODE_CONF_ACK = 2
        private const val CODE_CONF_NAK = 3
        private const val CODE_CONF_REJ = 4
        private const val CODE_TERM_REQ = 5
        private const val CODE_TERM_ACK = 6
        private const val CODE_PROTO_REJ = 8
        private const val CODE_ECHO_REQ = 9
        private const val CODE_ECHO_REPLY = 10
        private const val CODE_PAP_REQ = 1
        private const val CODE_PAP_ACK = 2

        private const val LCP_MRU = 1
        private const val LCP_AUTH = 3
        private const val IPCP_ADDRESS = 3
        private const val IPCP_PRIMARY_DNS = 129
        private const val IPCP_SECONDARY_DNS = 131

        private fun pppPacket(code: Int, id: Int, data: ByteArray): ByteArray =
            ByteBuffer.allocate(4 + data.size)
                .put(code.toByte()).put(id.toByte()).putShort((4 + data.size).toShort())
                .put(data)
                .array()

        private fun option(type: Int, value: ByteArray): ByteArray =
            byteArrayOf(type.toByte(), (2 + value.size).toByte()) + value

        private fun shortBytes(value: Int): ByteArray =
            byteArrayOf((value shr 8).toByte(), value.toByte())

        private fun hmac(algorithm: String, key: ByteArray, data: ByteArray): ByteArray {
            val mac = Mac.getInstance(algorithm)
            mac.init(SecretKeySpec(key, algorithm))
            return mac.doFinal(data)
        }
    }
}
