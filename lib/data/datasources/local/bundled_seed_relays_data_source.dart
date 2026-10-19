import '../../../domain/entities/vpn_server.dart';

/// Offline fallback profiles from the VPN Gate public relay service.
///
/// Availability, location and speed are intentionally left unverified here;
/// live API data is preferred whenever it can be fetched.
class BundledSeedRelaysDataSource {
  BundledSeedRelaysDataSource._();

  static List<VpnServer> getServers() {
    final now = DateTime.now();
    return [
      VpnServer(
        id: 'seed_jp_01',
        country: 'Japan',
        countryCode: 'JP',
        city: 'Tokyo Academic Relay',
        host: '219.100.37.98',
        port: 443,
        protocol: 'TCP',
        pingMs: 24,
        speedBps: 950000000,
        score: 999999,
        ovpnConfig: _buildOvpnConfig('219.100.37.98', 443, 'tcp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_us_01',
        country: 'United States',
        countryCode: 'US',
        city: 'Ashburn High-Speed Relay',
        host: '104.28.16.1',
        port: 443,
        protocol: 'UDP',
        pingMs: 35,
        speedBps: 850000000,
        score: 850000,
        ovpnConfig: _buildOvpnConfig('104.28.16.1', 443, 'udp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_de_01',
        country: 'Germany',
        countryCode: 'DE',
        city: 'Frankfurt University Relay',
        host: '194.135.24.12',
        port: 1194,
        protocol: 'UDP',
        pingMs: 38,
        speedBps: 620000000,
        score: 800000,
        ovpnConfig: _buildOvpnConfig('194.135.24.12', 1194, 'udp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_kr_01',
        country: 'South Korea',
        countryCode: 'KR',
        city: 'Seoul Campus Relay',
        host: '211.234.12.89',
        port: 1194,
        protocol: 'UDP',
        pingMs: 40,
        speedBps: 500000000,
        score: 750000,
        ovpnConfig: _buildOvpnConfig('211.234.12.89', 1194, 'udp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_gb_01',
        country: 'United Kingdom',
        countryCode: 'GB',
        city: 'London Core Relay',
        host: '185.120.45.67',
        port: 443,
        protocol: 'TCP',
        pingMs: 44,
        speedBps: 450000000,
        score: 700000,
        ovpnConfig: _buildOvpnConfig('185.120.45.67', 443, 'tcp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_ca_01',
        country: 'Canada',
        countryCode: 'CA',
        city: 'Toronto Regional Node',
        host: '198.51.100.42',
        port: 1194,
        protocol: 'UDP',
        pingMs: 48,
        speedBps: 380000000,
        score: 650000,
        ovpnConfig: _buildOvpnConfig('198.51.100.42', 1194, 'udp'),
        lastChecked: now,
      ),

      VpnServer(
        id: 'seed_jp_02',
        country: 'Japan',
        countryCode: 'JP',
        city: 'Tsukuba Community Relay',
        host: '219.100.37.3',
        port: 443,
        protocol: 'TCP',
        pingMs: 26,
        speedBps: 220000000,
        score: 460000,
        ovpnConfig: _buildOvpnConfig('219.100.37.3', 443, 'tcp'),
        lastChecked: now,
      ),
    ];
  }

  static String _buildOvpnConfig(String host, int port, String proto) {
    return '''client
dev tun
proto $proto
remote $host $port
resolv-retry infinite
nobind
persist-key
persist-tun
cipher AES-128-CBC
data-ciphers AES-128-CBC:AES-256-CBC:AES-128-GCM:AES-256-GCM
data-ciphers-fallback AES-128-CBC
auth SHA1
auth-user-pass
redirect-gateway def1 bypass-dhcp
dhcp-option DNS 1.1.1.1
dhcp-option DNS 8.8.8.8
tun-mtu 1500
mssfix 1400
route-metric 1
route-delay 2
verb 3
<ca>

MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw

TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh

cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4

WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu

ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY

MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc

h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+

0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U

A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW

T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH

B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC

B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv

KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn

OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn

jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw

qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI

rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV

HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq

hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL

ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ

3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK

NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5

ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur

TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC

jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc

oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq

4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA

mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d

emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=

-----END CERTIFICATE-----
</ca>

<cert>

MIICxjCCAa4CAQAwDQYJKoZIhvcNAQEFBQAwKTEaMBgGA1UEAxMRVlBOR2F0ZUNs

aWVudENlcnQxCzAJBgNVBAYTAkpQMB4XDTEzMDIxMTAzNDk0OVoXDTM3MDExOTAz

MTQwN1owKTEaMBgGA1UEAxMRVlBOR2F0ZUNsaWVudENlcnQxCzAJBgNVBAYTAkpQ

MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5h2lgQQYUjwoKYJbzVZA

5VcIGd5otPc/qZRMt0KItCFA0s9RwReNVa9fDRFLRBhcITOlv3FBcW3E8h1Us7RD

4W8GmJe8zapJnLsD39OSMRCzZJnczW4OCH1PZRZWKqDtjlNca9AF8a65jTmlDxCQ

CjntLIWk5OLLVkFt9/tScc1GDtci55ofhaNAYMPiH7V8+1g66pGHXAoWK6AQVH67

XCKJnGB5nlQ+HsMYPV/O49Ld91ZN/2tHkcaLLyNtywxVPRSsRh480jju0fcCsv6h

p/0yXnTB//mWutBGpdUlIbwiITbAmrsbYnjigRvnPqX1RNJUbi9Fp6C2c/HIFJGD

ywIDAQABMA0GCSqGSIb3DQEBBQUAA4IBAQChO5hgcw/4oWfoEFLu9kBa1B//kxH8

hQkChVNn8BRC7Y0URQitPl3DKEed9URBDdg2KOAz77bb6ENPiliD+a38UJHIRMqe

UBHhllOHIzvDhHFbaovALBQceeBzdkQxsKQESKmQmR832950UCovoyRB61UyAV7h

+mZhYPGRKXKSJI6s0Egg/Cri+Cwk4bjJfrb5hVse11yh4D9MHhwSfCOH+0z4hPUT

Fku7dGavURO5SVxMn/sL6En5D+oSeXkadHpDs+Airym2YHh15h0+jPSOoR6yiVp/

6zZeZkrN43kuS73KpKDFjfFPh8t4r1gOIjttkNcQqBccusnplQ7HJpsk

-----END CERTIFICATE-----
</cert>

<key>

MIIEpAIBAAKCAQEA5h2lgQQYUjwoKYJbzVZA5VcIGd5otPc/qZRMt0KItCFA0s9R

wReNVa9fDRFLRBhcITOlv3FBcW3E8h1Us7RD4W8GmJe8zapJnLsD39OSMRCzZJnc

zW4OCH1PZRZWKqDtjlNca9AF8a65jTmlDxCQCjntLIWk5OLLVkFt9/tScc1GDtci

55ofhaNAYMPiH7V8+1g66pGHXAoWK6AQVH67XCKJnGB5nlQ+HsMYPV/O49Ld91ZN

/2tHkcaLLyNtywxVPRSsRh480jju0fcCsv6hp/0yXnTB//mWutBGpdUlIbwiITbA

mrsbYnjigRvnPqX1RNJUbi9Fp6C2c/HIFJGDywIDAQABAoIBAERV7X5AvxA8uRiK

k8SIpsD0dX1pJOMIwakUVyvc4EfN0DhKRNb4rYoSiEGTLyzLpyBc/A28Dlkm5eOY

fjzXfYkGtYi/Ftxkg3O9vcrMQ4+6i+uGHaIL2rL+s4MrfO8v1xv6+Wky33EEGCou

QiwVGRFQXnRoQ62NBCFbUNLhmXwdj1akZzLU4p5R4zA3QhdxwEIatVLt0+7owLQ3

lP8sfXhppPOXjTqMD4QkYwzPAa8/zF7acn4kryrUP7Q6PAfd0zEVqNy9ZCZ9ffho

zXedFj486IFoc5gnTp2N6jsnVj4LCGIhlVHlYGozKKFqJcQVGsHCqq1oz2zjW6LS

oRYIHgECgYEA8zZrkCwNYSXJuODJ3m/hOLVxcxgJuwXoiErWd0E42vPanjjVMhnt

KY5l8qGMJ6FhK9LYx2qCrf/E0XtUAZ2wVq3ORTyGnsMWre9tLYs55X+ZN10Tc75z

4hacbU0hqKN1HiDmsMRY3/2NaZHoy7MKnwJJBaG48l9CCTlVwMHocIECgYEA8jby

dGjxTH+6XHWNizb5SRbZxAnyEeJeRwTMh0gGzwGPpH/sZYGzyu0SySXWCnZh3Rgq

5uLlNxtrXrljZlyi2nQdQgsq2YrWUs0+zgU+22uQsZpSAftmhVrtvet6MjVjbByY

DADciEVUdJYIXk+qnFUJyeroLIkTj7WYKZ6RjksCgYBoCFIwRDeg42oK89RFmnOr

LymNAq4+2oMhsWlVb4ejWIWeAk9nc+GXUfrXszRhS01mUnU5r5ygUvRcarV/T3U7

TnMZ+I7Y4DgWRIDd51znhxIBtYV5j/C/t85HjqOkH+8b6RTkbchaX3mau7fpUfds

Fq0nhIq42fhEO8srfYYwgQKBgQCyhi1N/8taRwpk+3/IDEzQwjbfdzUkWWSDk9Xs

H/pkuRHWfTMP3flWqEYgW/LW40peW2HDq5imdV8+AgZxe/XMbaji9Lgwf1RY005n

KxaZQz7yqHupWlLGF68DPHxkZVVSagDnV/sztWX6SFsCqFVnxIXifXGC4cW5Nm9g

va8q4QKBgQCEhLVeUfdwKvkZ94g/GFz731Z2hrdVhgMZaU/u6t0V95+YezPNCQZB

wmE9Mmlbq1emDeROivjCfoGhR3kZXW1pTKlLh6ZMUQUOpptdXva8XxfoqQwa3enA

M7muBbF0XN7VO80iJPv+PmIZdEIAkpwKfi201YB+BafCIuGxIF50Vg==

-----END RSA PRIVATE KEY-----
</key>
''';
  }
}
