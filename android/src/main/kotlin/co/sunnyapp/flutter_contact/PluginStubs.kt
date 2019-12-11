package co.sunnyapp.flutter_contact

import android.os.AsyncTask
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


fun <T> asyncTask(callback: MethodChannel.Result, block: () -> T) {
  val task = object : AsyncTask<Any?, Void, MethodResult<T>>() {
    override fun doInBackground(vararg params: Any?): MethodResult<T> {
      return try {
        MethodResult(block())
      } catch (e: MethodCallException) {
        MethodResult(errorCode = e.code, exception = e, errorMessage = e.error)
      } catch (e: Exception) {
        MethodResult(errorCode = "unknown", exception = e, errorMessage = "$e")
      }
    }

    override fun onPostExecute(result: MethodResult<T>) {
      callback.send(result)
    }
  }
  task.execute(null)
}

fun <T> MethodChannel.Result.send(result: MethodResult<T>) {
  when (result.errorCode) {
    null -> this.success(result.value)
    else -> this.error(result.errorCode, result.errorMessage
        ?: "${result.exception}", result.exception?.toString())
  }
}

operator fun <T> MethodCall.get(name: String): T {
  return this.argument<T>(name) ?: badParameter(method, name)
}

open class MethodCallException(val method: String, code: String, error: String? = null)
  : PluginException(code, "in method $method: ${error ?: ""}")

open class PluginException(val code: String, val error: String? = null)
  : Exception("$code: ${error ?: ""}")

class BadParametersException(method: String, val name: String)
  : MethodCallException(method = method,
    code = "invalidParameters",
    error = "Invalid type for parameter $name")

fun pluginError(code: String, message: String? = null): Nothing {
  throw PluginException(code = code, error = message)
}

fun methodError(method: String, code: String, message: String? = null): Nothing {
  throw MethodCallException(method = method, code = code, error = message)
}

fun badParameter(method: String, parameter: String): Nothing {
  throw BadParametersException(method = method, name = parameter)
}

data class MethodResult<T> internal constructor(val value: T?,
                                                val errorCode: String?,
                                                val errorMessage: String?,
                                                val exception: Throwable?) {
  constructor(result: T) : this(value = result, errorCode = null, exception = null, errorMessage = null)
  constructor(errorCode: String, exception: Throwable, errorMessage: String? = null) : this(value = null,
      errorCode = errorCode,
      errorMessage = errorMessage,
      exception = exception)
}
