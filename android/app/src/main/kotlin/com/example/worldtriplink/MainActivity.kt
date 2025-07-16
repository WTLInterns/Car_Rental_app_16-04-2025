package com.yourcompany.worldtriplink

import android.os.Bundle
import android.util.Log
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.facebook.appevents.AppEventsLogger
import com.facebook.appevents.AppEventsConstants
import java.math.BigDecimal
import java.security.MessageDigest
import java.security.NoSuchAlgorithmException

class MainActivity : FlutterActivity() {
    private val CHANNEL = "facebook_analytics"
    private lateinit var appEventsLogger: AppEventsLogger

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Generate and log Facebook key hash for debugging
        try {
            val info = packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_SIGNATURES)
            info.signatures?.let { signatures ->
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                    Log.d("FacebookKeyHash", "Key Hash: $keyHash")
                    println("Facebook Key Hash: $keyHash")
                }
            }
        } catch (e: Exception) {
            Log.e("FacebookKeyHash", "Error generating key hash", e)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appEventsLogger = AppEventsLogger.newLogger(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "logAppOpen" -> {
                    appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_ACTIVATED_APP)
                    result.success(null)
                }
                "logRegistration" -> {
                    val method = call.argument<String>("method") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    bundle.putString(AppEventsConstants.EVENT_PARAM_REGISTRATION_METHOD, method)
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_COMPLETED_REGISTRATION, bundle)
                    result.success(null)
                }
                "logBooking" -> {
                    val amount = call.argument<Double>("amount") ?: 0.0
                    val currency = call.argument<String>("currency") ?: "USD"
                    val carType = call.argument<String>("carType") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    bundle.putString(AppEventsConstants.EVENT_PARAM_CURRENCY, currency)
                    bundle.putString(AppEventsConstants.EVENT_PARAM_CONTENT_TYPE, "car_rental")
                    bundle.putString("car_type", carType)
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logPurchase(BigDecimal.valueOf(amount), java.util.Currency.getInstance(currency), bundle)
                    result.success(null)
                }
                "logPayment" -> {
                    val amount = call.argument<Double>("amount") ?: 0.0
                    val currency = call.argument<String>("currency") ?: "USD"
                    val paymentMethod = call.argument<String>("paymentMethod") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    bundle.putString(AppEventsConstants.EVENT_PARAM_CURRENCY, currency)
                    bundle.putString(AppEventsConstants.EVENT_PARAM_PAYMENT_INFO_AVAILABLE, "1")
                    bundle.putString("payment_method", paymentMethod)
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_ADDED_PAYMENT_INFO, amount, bundle)
                    result.success(null)
                }
                "logSearch" -> {
                    val searchTerm = call.argument<String>("searchTerm") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    bundle.putString(AppEventsConstants.EVENT_PARAM_SEARCH_STRING, searchTerm)
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_SEARCHED, bundle)
                    result.success(null)
                }
                "logViewContent" -> {
                    val contentType = call.argument<String>("contentType") ?: ""
                    val contentId = call.argument<String>("contentId") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    bundle.putString(AppEventsConstants.EVENT_PARAM_CONTENT_TYPE, contentType)
                    bundle.putString(AppEventsConstants.EVENT_PARAM_CONTENT_ID, contentId)
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logEvent(AppEventsConstants.EVENT_NAME_VIEWED_CONTENT, bundle)
                    result.success(null)
                }
                "logCustomEvent" -> {
                    val eventName = call.argument<String>("eventName") ?: ""
                    val parameters = call.argument<Map<String, Any>>("parameters") ?: emptyMap()

                    val bundle = Bundle()
                    parameters.forEach { (key, value) ->
                        when (value) {
                            is String -> bundle.putString(key, value)
                            is Int -> bundle.putInt(key, value)
                            is Double -> bundle.putDouble(key, value)
                            is Boolean -> bundle.putBoolean(key, value)
                        }
                    }

                    appEventsLogger.logEvent(eventName, bundle)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
