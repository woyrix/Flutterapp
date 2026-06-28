package com.example.priyatam_kavya

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "priyatam_kavya/gallery_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveImage") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val bytes = call.argument<ByteArray>("bytes")
            val fileName = call.argument<String>("fileName")
            val mimeType = call.argument<String>("mimeType") ?: "image/jpeg"

            if (bytes == null || fileName.isNullOrBlank()) {
                result.error("INVALID_IMAGE", "Image data is missing.", null)
                return@setMethodCallHandler
            }

            try {
                val savedTo = saveImageToGallery(bytes, fileName, mimeType)
                result.success(savedTo)
            } catch (error: Exception) {
                result.error("SAVE_FAILED", error.message, null)
            }
        }
    }

    private fun saveImageToGallery(
        bytes: ByteArray,
        fileName: String,
        mimeType: String
    ): String {
        val folderName = "Priyatam Kavya"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                put(MediaStore.Images.Media.MIME_TYPE, mimeType)
                put(
                    MediaStore.Images.Media.RELATIVE_PATH,
                    "${Environment.DIRECTORY_PICTURES}/$folderName"
                )
                put(MediaStore.Images.Media.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Could not create image.")

            resolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
            } ?: throw IllegalStateException("Could not write image.")

            values.clear()
            values.put(MediaStore.Images.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            return "Gallery/Pictures/$folderName"
        }

        val pictures = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_PICTURES
        )
        val directory = File(pictures, folderName)
        if (!directory.exists()) directory.mkdirs()

        val file = uniqueFile(directory, fileName)
        FileOutputStream(file).use { stream ->
            stream.write(bytes)
        }

        MediaScannerConnection.scanFile(
            applicationContext,
            arrayOf(file.absolutePath),
            arrayOf(mimeType),
            null
        )

        return file.absolutePath
    }

    private fun uniqueFile(directory: File, fileName: String): File {
        val dot = fileName.lastIndexOf('.')
        val base = if (dot == -1) fileName else fileName.substring(0, dot)
        val extension = if (dot == -1) "" else fileName.substring(dot)
        var file = File(directory, fileName)
        var index = 1

        while (file.exists()) {
            file = File(directory, "$base-$index$extension")
            index += 1
        }

        return file
    }
}
