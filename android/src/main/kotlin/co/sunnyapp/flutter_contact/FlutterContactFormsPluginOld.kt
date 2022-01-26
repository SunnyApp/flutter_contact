package co.sunnyapp.flutter_contact

import android.content.Intent
import io.flutter.plugin.common.PluginRegistry

/// Class that facilitates edit/add contacts for v1 embedding.
class FlutterContactFormsOld(plugin: BaseFlutterContactPlugin, private val registrar: PluginRegistry.Registrar) : BaseFlutterContactForms(plugin) {

    init {
        registrar.addActivityResultListener(this)
    }

    override fun startIntent(intent: Intent, request: Int) {
        if (registrar.activity() != null) {
            registrar.activity().startActivityForResult(intent, request)
        } else {
            registrar.context().startActivity(intent)
        }
    }
}
