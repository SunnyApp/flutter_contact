package co.sunnyapp.flutter_contact


import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry.Registrar


/**
 * class for the flutter_contact plugin.  There are two modes for this plugin: aggregate and raw.
 *
 * Aggregate deals with linked contacts, where there will be one record per group of linked contacts
 * Raw deals with the individual contacts.
 *
 * This class will register the method calls from both modes (aggregate and raw).
 */
open class FlutterContactPlugin : FlutterPlugin, ActivityAware {
    private var rawPlugin: FlutterRawContactPlugin? = null
    private var unifiedPlugin: FlutterAggregateContactPlugin? = null

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = FlutterContactPlugin()
            instance.initInstances(registrar.context(), registrar.messenger(), registrar)
        }
    }

    // --- FlutterPlugin implementation ---
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        initInstances(binding.applicationContext, binding.binaryMessenger, null)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unInitInstances()
    }

    // --- ActivityAware implementation ---
    override fun onDetachedFromActivity() {
        unbindActivity(rawPlugin?.contactForms)
        unbindActivity(unifiedPlugin?.contactForms)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        unbindActivity(rawPlugin?.contactForms)
        unbindActivity(unifiedPlugin?.contactForms)
    }

    override fun onReattachedToActivityForConfigChanges(@NonNull binding: ActivityPluginBinding) {
        bindToActivity(binding, rawPlugin?.contactForms)
        bindToActivity(binding, unifiedPlugin?.contactForms)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        bindToActivity(binding, rawPlugin?.contactForms)
        bindToActivity(binding, unifiedPlugin?.contactForms)
    }

    private fun initInstances(applicationContext: Context, binaryMessenger: BinaryMessenger, registrar: Registrar?) {
        rawPlugin = FlutterRawContactPlugin()
        rawPlugin!!.initInstance(applicationContext, binaryMessenger, registrar)

        unifiedPlugin = FlutterAggregateContactPlugin()
        unifiedPlugin!!.initInstance(applicationContext, binaryMessenger, registrar)
    }

    private fun unInitInstances() {
        rawPlugin?.unInitInstance()
        unifiedPlugin?.unInitInstance()
    }

    /**
     * bind the binding to the activity
     */
    private fun bindToActivity(binding: ActivityPluginBinding, contactForms: BaseFlutterContactForms?) {
        if (contactForms is FlutterContactForms) {
            contactForms.bindToActivity(binding)
        }
    }

    /**
     * unbind the binding from activity
     */
    private fun unbindActivity(contactForms: BaseFlutterContactForms?) {
        if (contactForms is FlutterContactForms) {
            contactForms.unbindActivity()
        }
    }
}

