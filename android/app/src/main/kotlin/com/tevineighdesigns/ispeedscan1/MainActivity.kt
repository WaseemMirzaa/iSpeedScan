package com.tevineighdesigns.ispeedscan1

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.tevineighdesigns.ispeedscan1.fileprovider/file" // The method channel name

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register the plugin registrant receiver
        PluginRegistrantReceiver.registerWith(flutterEngine, context)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Make sure to call the method channel from FlutterEngine
        MethodChannel(flutterEngine!!.dartExecutor, CHANNEL).setMethodCallHandler { call, result ->
            // Check if the method being called is 'shareFile'
            if (call.method == "shareFile") {
                // Get the filePath argument passed from Flutter
                val filePath = call.argument<String>("filePath")

                if (filePath != null) {
                    // Call the function to share the file if the path is provided
                    shareFile(filePath)
                    result.success("File shared successfully")
                } else {
                    // If filePath is missing, return an error
                    result.error("INVALID_ARGUMENT", "File path is missing", null)
                }
            } else {
                // If the method is not recognized, indicate that it isn't implemented
                result.notImplemented()
            }
        }
    }

    private fun shareFile(filePath: String) {
        // Create a File object from the file path
        val file = File(filePath)

        // Get the URI for the file using FileProvider
        val uri: Uri = FileProvider.getUriForFile(
            this, "com.tevineighdesigns.ispeedscan1.fileprovider", file
        )

        // Extract the file name
        val fileName = file.name

        // Create an intent to share the file
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf" // MIME type for PDFs
            putExtra(Intent.EXTRA_STREAM, uri) // Attach the file URI
            putExtra(Intent.EXTRA_SUBJECT, fileName) // Set the subject as the file name
            putExtra(Intent.EXTRA_TEXT, "Here's the PDF: $fileName") // Optional message
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION) // Grant permission to read the URI
        }

        // Start the activity to choose the sharing app
        startActivity(Intent.createChooser(intent, "Share $fileName"))
    }
}
