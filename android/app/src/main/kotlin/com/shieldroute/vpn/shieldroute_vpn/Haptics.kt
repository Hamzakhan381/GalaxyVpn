package com.shieldroute.vpn.shieldroute_vpn

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Haptic feedback played on the vibrator itself. Flutter's HapticFeedback goes
 * through View haptic constants, which many budget phones play too faintly to
 * feel or not at all. Predefined effects, where the hardware has them, or
 * short pulses sized for the phone's motor are felt everywhere.
 */
object Haptics {

    private class Pulse(val millis: Long, val amplitude: Int)

    fun play(context: Context, kind: String) {
        val vibrator = vibrator(context) ?: return
        if (!vibrator.hasVibrator()) return
        runCatching {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(effect(vibrator, kind) ?: return)
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(legacyPattern(kind) ?: return, -1)
            }
        }
    }

    private fun vibrator(context: Context): Vibrator? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java)?.defaultVibrator
        } else {
            context.getSystemService(Vibrator::class.java)
        }

    private fun effect(vibrator: Vibrator, kind: String): VibrationEffect? {
        predefinedEffect(vibrator, kind)?.let { return it }
        val pulses = pulses(kind, vibrator.hasAmplitudeControl()) ?: return null
        if (pulses.size == 1) {
            return VibrationEffect.createOneShot(pulses[0].millis, pulses[0].amplitude)
        }
        // Alternating gap / pulse timings, starting with no delay.
        val timings = mutableListOf<Long>()
        val amplitudes = mutableListOf<Int>()
        pulses.forEachIndexed { i, pulse ->
            timings += if (i == 0) 0L else GAP_MILLIS
            amplitudes += 0
            timings += pulse.millis
            amplitudes += pulse.amplitude
        }
        return VibrationEffect.createWaveform(timings.toLongArray(), amplitudes.toIntArray(), -1)
    }

    /** Tuned by the phone maker, so used only where the hardware reports support. */
    private fun predefinedEffect(vibrator: Vibrator, kind: String): VibrationEffect? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val id = when (kind) {
            "tick" -> VibrationEffect.EFFECT_TICK
            "click" -> VibrationEffect.EFFECT_CLICK
            "heavy" -> VibrationEffect.EFFECT_HEAVY_CLICK
            "success" -> VibrationEffect.EFFECT_DOUBLE_CLICK
            else -> return null
        }
        val supported = vibrator.areAllEffectsSupported(id) == Vibrator.VIBRATION_EFFECT_SUPPORT_YES
        return if (supported) VibrationEffect.createPredefined(id) else null
    }

    /**
     * Motors without amplitude control are mostly slow to spin up, so their
     * pulses run longer to be felt at all.
     */
    private fun pulses(kind: String, amplitudeControl: Boolean): List<Pulse>? {
        fun pulse(millis: Long, slowMotorMillis: Long, amplitude: Int) =
            if (amplitudeControl) {
                Pulse(millis, amplitude)
            } else {
                Pulse(slowMotorMillis, VibrationEffect.DEFAULT_AMPLITUDE)
            }
        return when (kind) {
            "tick" -> listOf(pulse(10, 16, 90))
            "click" -> listOf(pulse(18, 26, 170))
            "heavy" -> listOf(pulse(30, 40, 255))
            "success" -> listOf(pulse(18, 26, 200), pulse(28, 36, 255))
            "error" -> listOf(pulse(40, 45, 255), pulse(40, 45, 255), pulse(40, 45, 255))
            else -> null
        }
    }

    private fun legacyPattern(kind: String): LongArray? = when (kind) {
        "tick" -> longArrayOf(0, 16)
        "click" -> longArrayOf(0, 26)
        "heavy" -> longArrayOf(0, 40)
        "success" -> longArrayOf(0, 26, GAP_MILLIS, 36)
        "error" -> longArrayOf(0, 45, GAP_MILLIS, 45, GAP_MILLIS, 45)
        else -> null
    }

    private const val GAP_MILLIS = 70L
}
