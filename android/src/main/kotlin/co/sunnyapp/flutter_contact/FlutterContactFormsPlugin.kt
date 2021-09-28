package co.sunnyapp.flutter_contact

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding


/// Class that facilitates edit/add contacts for v2 embedding.
class FlutterContactForms(plugin: BaseFlutterContactPlugin, private val context: Context) : BaseFlutterContactForms(plugin) {
    private var activityPluginBinding: ActivityPluginBinding? = null

    fun bindToActivity(activityPluginBinding: ActivityPluginBinding) {
        this.activityPluginBinding = activityPluginBinding
        activityPluginBinding.addActivityResultListener(this)
    }

    fun unbindActivity() {
        this.activityPluginBinding?.removeActivityResultListener(this)
        this.activityPluginBinding = null
    }

    override fun startIntent(intent: Intent, request: Int) {
        if (this.activityPluginBinding != null) {
            try {
                this.activityPluginBinding!!.activity.startActivityForResult(intent, request)
            } catch (e: Exception) {
                e.printStackTrace()
                result?.success(ErrorCodes.FORM_COULD_NOT_BE_OPENED)
            }
        } else {
            context.startActivity(intent)
        }
    }
}
