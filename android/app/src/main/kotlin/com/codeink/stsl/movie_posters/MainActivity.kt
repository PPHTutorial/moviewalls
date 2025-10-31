package com.codeink.stsl.movie_posters

import android.content.ContentValues
import android.media.MediaScannerConnection
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.movieposters.media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveImageToDownloads" -> {
                    val fileName = call.argument<String>("fileName") ?: ""
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName.isNotEmpty() && bytes != null) {
                        try {
                            val path = saveImageToDownloads(fileName, bytes)
                            result.success(mapOf("path" to path))
                        } catch (e: Exception) {
                            result.error("SAVE_ERROR", "Failed to save image: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "FileName or bytes is empty", null)
                    }
                }
                "scanFile" -> {
                    val path = call.argument<String>("path") ?: ""
                    if (path.isNotEmpty()) {
                        scanFileToMediaStore(path)
                        result.success(true)
                    } else {
                        result.error("INVALID_PATH", "File path is empty", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveImageToDownloads(fileName: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+) - Use MediaStore API directly
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Download")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            
            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(bytes)
                }
                
                // Mark as not pending so it becomes visible
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                
                // Return the content URI as path (MediaStore URI)
                return uri.toString()
            } else {
                throw Exception("Failed to create MediaStore entry")
            }
        } else {
            // Android 9 and below - Save to Downloads folder directly
            val downloadsDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), fileName)
            downloadsDir.writeBytes(bytes)
            
            // Scan file to make it visible
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(downloadsDir.absolutePath),
                arrayOf("image/jpeg")
            ) { _, _ ->
                // File scanned successfully
            }
            
            return downloadsDir.absolutePath
        }
    }

    private fun scanFileToMediaStore(filePath: String) {
        val file = File(filePath)
        if (!file.exists()) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // For Android 10+, files should already be in MediaStore
            // Just ensure it's scanned
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, file.name)
                put(MediaStore.MediaColumns.MIME_TYPE, "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "Download")
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
            
            if (uri != null) {
                resolver.openOutputStream(uri)?.use { outputStream ->
                    file.inputStream().use { inputStream ->
                        inputStream.copyTo(outputStream)
                    }
                }
                file.delete()
            }
        } else {
            // Android 9 and below - Use MediaScannerConnection
            MediaScannerConnection.scanFile(
                applicationContext,
                arrayOf(filePath),
                arrayOf("image/jpeg")
            ) { _, _ ->
                // File scanned successfully
            }
        }
    }
}
