package com.example.trainforge

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.zip.GZIPInputStream

/** Stream bundled catalog files without sending their contents over the Dart channel. */
class CatalogAssetInstaller(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private val worker = Executors.newSingleThreadExecutor()
    }
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "copyAsset") {
            result.notImplemented()
            return
        }
        val asset = call.argument<String>("asset")
        val destination = call.argument<String>("destination")
        val decompressGzip = call.argument<Boolean>("decompressGzip") == true
        val maxBytes = call.argument<Number>("maxBytes")?.toLong() ?: Long.MAX_VALUE
        if (asset == null || destination == null ||
            !Regex("^assets/food_catalog/[A-Za-z0-9_.-]+$").matches(asset) ||
            maxBytes <= 0 || (decompressGzip && !asset.endsWith(".gz"))) {
            result.error("invalid_catalog_asset", "Invalid catalog file", null)
            return
        }
        worker.execute {
            var target: File? = null
            var created = false
            try {
                val root = context.filesDir.canonicalFile
                val targetFile = File(destination).canonicalFile
                target = targetFile
                require(targetFile.path.startsWith(root.path + File.separator))
                require(targetFile.parentFile?.isDirectory == true)
                // Never replace an active catalog or a file owned by another installation.
                require(targetFile.createNewFile())
                created = true
                val lookup = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
                val count = context.assets.open(lookup).use { raw ->
                  val source = if (decompressGzip) GZIPInputStream(raw, 64 * 1024) else raw
                  source.use { input ->
                    targetFile.outputStream().use { output ->
                        val buffer = ByteArray(64 * 1024)
                        var count = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read < 0) break
                            count += read
                            require(count <= maxBytes)
                            output.write(buffer, 0, read)
                        }
                        if (maxBytes != Long.MAX_VALUE) require(count == maxBytes)
                        output.fd.sync()
                        count
                    }
                  }
                }
                main.post { result.success(count) }
            } catch (_: Exception) {
                if (created) target?.delete()
                main.post { result.error("catalog_copy_failed", "Catalog file could not be copied", null) }
            }
        }
    }
}
