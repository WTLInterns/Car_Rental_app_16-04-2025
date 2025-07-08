package com.yourcompany.worldtriplink

import android.app.Application
import com.facebook.FacebookSdk
import com.facebook.appevents.AppEventsLogger

class MyApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()

        try {
            // Initialize Facebook SDK - client token is configured in AndroidManifest.xml
            FacebookSdk.sdkInitialize(applicationContext)

            // Enable automatic app event logging
            AppEventsLogger.activateApp(this)

            // Set auto log app events enabled for production tracking
            FacebookSdk.setAutoLogAppEventsEnabled(true)

            // Set advertiser ID collection enabled for better attribution
            FacebookSdk.setAdvertiserIDCollectionEnabled(true)

            android.util.Log.i("FacebookSDK", "Facebook SDK initialized successfully with real client token")
        } catch (e: Exception) {
            // Log the error but don't crash the app
            android.util.Log.e("FacebookSDK", "Failed to initialize Facebook SDK: ${e.message}")
        }
    }
}
