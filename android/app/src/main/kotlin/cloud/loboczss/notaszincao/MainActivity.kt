package cloud.loboczss.notaszincao

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			"notas_zincao/gallery",
		).setMethodCallHandler { call, result ->
			when (call.method) {
				"saveImageToGallery" -> {
					val bytes = call.argument<ByteArray>("bytes")
					val fileName = call.argument<String>("fileName")
					val mimeType = call.argument<String>("mimeType")

					if (bytes == null || fileName.isNullOrBlank()) {
						result.error("INVALID_ARGS", "Bytes ou nome do arquivo ausentes.", null)
						return@setMethodCallHandler
					}

					try {
						saveImageToGallery(
							bytes = bytes,
							fileName = fileName,
							mimeType = mimeType ?: "image/jpeg",
						)
						result.success(true)
					} catch (error: Exception) {
						result.error("SAVE_FAILED", error.message, error.stackTraceToString())
					}
				}

				else -> result.notImplemented()
			}
		}
	}

	private fun saveImageToGallery(bytes: ByteArray, fileName: String, mimeType: String) {
		val resolver = applicationContext.contentResolver
		val values = ContentValues().apply {
			put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
			put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				put(
					MediaStore.MediaColumns.RELATIVE_PATH,
					Environment.DIRECTORY_PICTURES + "/Notas Zincao",
				)
			}
		}

		val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
			?: throw IOException("Nao foi possivel criar registro na galeria.")

		try {
			resolver.openOutputStream(uri)?.use { outputStream ->
				outputStream.write(bytes)
				outputStream.flush()
			} ?: throw IOException("Nao foi possivel abrir OutputStream da galeria.")
		} catch (error: Exception) {
			resolver.delete(uri, null, null)
			throw error
		}
	}
}
