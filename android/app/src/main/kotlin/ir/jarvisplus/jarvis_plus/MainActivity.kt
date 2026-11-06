package ir.jarvisplus.jarvis_plus

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    companion object {
        init {
            try {
                System.loadLibrary("omp")
            } catch (e: Throwable) {
                android.util.Log.w("MainActivity", "libomp load skipped: " + e.message)
            }
            try {
                System.loadLibrary("ggml-base")
            } catch (e: Throwable) {
                android.util.Log.w("MainActivity", "libggml-base load skipped: " + e.message)
            }
            try {
                System.loadLibrary("ggml-cpu")
            } catch (e: Throwable) {
                android.util.Log.w("MainActivity", "libggml-cpu load skipped: " + e.message)
            }
            try {
                System.loadLibrary("ggml")
            } catch (e: Throwable) {
                android.util.Log.w("MainActivity", "libggml load skipped: " + e.message)
            }
            try {
                System.loadLibrary("llama")
                android.util.Log.i("MainActivity", "libllama loaded successfully via System.loadLibrary")
            } catch (e: Throwable) {
                android.util.Log.e("MainActivity", "libllama load failed: " + e.message)
            }
        }
    }
}
