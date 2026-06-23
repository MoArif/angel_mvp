package com.example.angle_mvp

import android.os.Build
import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val SMS_CHANNEL = "com.angel.sms/send"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "sendSms") {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")

                    if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "Phone and message are required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        var smsManager: SmsManager? = null
                        var useDefault = false

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            try {
                                smsManager = getSystemService(SmsManager::class.java)
                            } catch (e: Exception) {
                                useDefault = true
                            }
                        } else {
                            useDefault = true
                        }

                        if (useDefault || smsManager == null) {
                            @Suppress("DEPRECATION")
                            smsManager = SmsManager.getDefault()
                        }

                        try {
                            val parts = smsManager.divideMessage(message)
                            if (parts.size == 1) {
                                smsManager.sendTextMessage(phone, null, message, null, null)
                            } else {
                                try {
                                    smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
                                } catch (ex: Exception) {
                                    // Fallback to sending separate messages if multipart fails
                                    for (part in parts) {
                                        smsManager.sendTextMessage(phone, null, part, null, null)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            // If the context-bound SmsManager failed completely,
                            // attempt to send via the legacy default SmsManager.
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !useDefault) {
                                @Suppress("DEPRECATION")
                                val fallbackManager = SmsManager.getDefault()
                                val parts = fallbackManager.divideMessage(message)
                                if (parts.size == 1) {
                                    fallbackManager.sendTextMessage(phone, null, message, null, null)
                                } else {
                                    try {
                                        fallbackManager.sendMultipartTextMessage(phone, null, parts, null, null)
                                    } catch (ex2: Exception) {
                                        // Fallback to sending separate messages on default manager if multipart fails
                                        for (part in parts) {
                                            fallbackManager.sendTextMessage(phone, null, part, null, null)
                                        }
                                    }
                                }
                            } else {
                                throw e
                            }
                        }

                        result.success("SMS sent successfully to $phone")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
