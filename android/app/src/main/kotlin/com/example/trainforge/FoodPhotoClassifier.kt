package com.example.trainforge

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.os.Handler
import android.os.Looper
import com.google.android.gms.tasks.Task
import com.google.android.gms.tflite.java.TfLite
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.InterpreterApi
import org.tensorflow.lite.InterpreterApi.Options.TfLiteRuntime
import java.io.File
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.MappedByteBuffer
import java.nio.channels.FileChannel
import java.util.concurrent.Executors

/**
 * Classifies a meal photo with the bundled int8 model. The LiteRT runtime comes from
 * Google Play services, so the APK carries only the model (~4.4 MB) and no native runtime.
 * Without Play services the photo feature reports "unavailable" and the rest of the app works.
 */
class FoodPhotoClassifier(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private val worker = Executors.newSingleThreadExecutor()
        private const val MODEL_ASSET = "assets/models/food_photo_int8.tflite"
        private const val SIZE = 224
        private const val RESIZE = 256
        private const val CLASSES = 370
    }

    private val main = Handler(Looper.getMainLooper())
    private var initialize: Task<Void>? = null
    @Volatile private var interpreter: InterpreterApi? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "status" -> ready { status -> result.success(status) }
            "classify" -> {
                val image = call.argument<String>("path")?.let { allowedImage(it) }
                if (image == null) {
                    result.error("invalid_image", "Invalid photo", null)
                    return
                }
                ready { status ->
                    if (status != "ready") {
                        result.error("unavailable", status, null)
                        return@ready
                    }
                    worker.execute {
                        try {
                            val scores = classify(image)
                            main.post { result.success(scores) }
                        } catch (e: Exception) {
                            main.post { result.error("classify_failed", "Photo could not be read", null) }
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Only photos the app itself stored (image_picker cache or app files) are read. */
    private fun allowedImage(path: String): File? {
        val file = File(path).canonicalFile
        val roots = listOfNotNull(context.cacheDir, context.filesDir, context.externalCacheDir).map { it.canonicalPath + File.separator }
        return if (file.isFile && roots.any { file.path.startsWith(it) }) file else null
    }

    private fun ready(done: (String) -> Unit) {
        if (interpreter != null) {
            done("ready")
            return
        }
        val task = initialize ?: TfLite.initialize(context).also { initialize = it }
        task.addOnSuccessListener {
            worker.execute {
                val status = try {
                    synchronized(this) {
                        if (interpreter == null) {
                            val options = InterpreterApi.Options().setRuntime(TfLiteRuntime.FROM_SYSTEM_ONLY).setNumThreads(4)
                            interpreter = InterpreterApi.create(model(), options)
                        }
                    }
                    "ready"
                } catch (e: Exception) {
                    "model_error"
                }
                main.post { done(status) }
            }
        }.addOnFailureListener {
            initialize = null // Play services may become available later (update or sign-in).
            done("runtime_unavailable")
        }
    }

    private fun model(): MappedByteBuffer {
        val lookup = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(MODEL_ASSET)
        return context.assets.openFd(lookup).use { fd ->
            FileInputStream(fd.fileDescriptor).channel.use { channel ->
                channel.map(FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength)
            }
        }
    }

    /** Same preprocessing as training: shorter side to 256, center 224 crop, RGB. */
    private fun classify(image: File): List<Double> {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(image.path, bounds)
        var sample = 1
        while (minOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= RESIZE) sample *= 2
        val decoded = BitmapFactory.decodeFile(image.path, BitmapFactory.Options().apply { inSampleSize = sample })
            ?: throw IllegalArgumentException("not an image")
        val upright = rotate(decoded, image)
        val scale = RESIZE.toFloat() / minOf(upright.width, upright.height)
        val resized = Bitmap.createScaledBitmap(upright, Math.round(upright.width * scale), Math.round(upright.height * scale), true)
        val crop = Bitmap.createBitmap(resized, (resized.width - SIZE) / 2, (resized.height - SIZE) / 2, SIZE, SIZE)
        val pixels = IntArray(SIZE * SIZE)
        crop.getPixels(pixels, 0, SIZE, 0, 0, SIZE, SIZE)
        // int8 input: scale 1/255, zero point -128, so each channel byte is value - 128.
        val input = ByteBuffer.allocateDirect(SIZE * SIZE * 3).order(ByteOrder.nativeOrder())
        for (p in pixels) {
            input.put(((p shr 16 and 0xFF) - 128).toByte())
            input.put(((p shr 8 and 0xFF) - 128).toByte())
            input.put(((p and 0xFF) - 128).toByte())
        }
        input.rewind()
        val output = Array(1) { ByteArray(CLASSES) }
        val runner = interpreter ?: throw IllegalStateException("not ready")
        synchronized(this) { runner.run(input, output) }
        // int8 output: scale 1/256, zero point -128 → probability in [0, 1).
        return output[0].map { (it + 128) / 256.0 }
    }

    private fun rotate(bitmap: Bitmap, image: File): Bitmap {
        val degrees = when (ExifInterface(image.path).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)) {
            ExifInterface.ORIENTATION_ROTATE_90 -> 90f
            ExifInterface.ORIENTATION_ROTATE_180 -> 180f
            ExifInterface.ORIENTATION_ROTATE_270 -> 270f
            else -> return bitmap
        }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, Matrix().apply { postRotate(degrees) }, true)
    }
}
