package com.example.trainforge

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val preferences = getSharedPreferences("trainforge_appearance", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trainforge/appearance").setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(preferences.getString("mode", "system"))
                "write" -> {
                    val mode = call.arguments as? String
                    if (mode !in setOf("system", "light", "dark")) {
                        result.error("invalid_mode", "Unsupported appearance", null)
                    } else if (preferences.edit().putString("mode", mode).commit()) {
                        result.success(null)
                    } else {
                        result.error("storage_unavailable", "Appearance was not saved", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        val localePreferences = getSharedPreferences("trainforge_locale", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "trainforge/locale").setMethodCallHandler { call, result ->
            when (call.method) {
                "read" -> result.success(localePreferences.getString("language", "system"))
                "write" -> {
                    val language = call.arguments as? String
                    if (language !in setOf("system", "pt-BR", "pt-PT", "en", "es")) {
                        result.error("invalid_locale", "Unsupported locale", null)
                    } else if (localePreferences.edit().putString("language", language).commit()) {
                        result.success(null)
                    } else {
                        result.error("storage_unavailable", "Locale was not saved", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
