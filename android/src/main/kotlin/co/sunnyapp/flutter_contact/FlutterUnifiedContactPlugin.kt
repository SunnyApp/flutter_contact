@file:Suppress("UNCHECKED_CAST", "NewApi", "MemberVisibilityCanBePrivate")

package co.sunnyapp.flutter_contact


import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


const val flutterContactsChannelName = "github.com/sunnyapp/flutter_unified_contact"
const val flutterContactsEventName = "github.com/sunnyapp/flutter_unified_contact_events"

/**
 * The variant that operates on Aggregate contacts vs raw contacts
 */
class FlutterAggregateContactPlugin(override val registrar: Registrar) : FlutterContactPlugin(),
        MethodCallHandler {

    override val contactForms = FlutterContactForms(this, registrar)

    override val mode = ContactMode.UNIFIED

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getContacts" -> asyncTask(result) {
                    this.getContacts(
                            query = call.argument("query"),
                            withThumbnails = call.argument<Any?>("withThumbnails") == true,
                            photoHighResolution = call.argument<Any?>("photoHighResolution") == true,
                            limit = call.argument("limit"),
                            offset = call.argument("offset"),
                            sortBy = call.argument("sortBy"),
                            phoneQuery = call.argument("phoneQuery"))
                }
                "getTotalContacts" -> asyncTask(result) {
                    this.getTotalContacts(
                            query = call.argument("query"),
                            phoneQuery = call.argument("phoneQuery"))
                }
                "getContactImage" -> asyncTask(result) {
                    this.getContactImage(call.argument("identifier"))
                }
                "getContact" -> asyncTask(result) {
                    this.getContact(
                            identifier = contactKeyOf(mode, call.argument("identifier")) ?: badParameter("getContact", "identifier"),
                            withThumbnails = call.argument<Any?>("withThumbnails") == true,
                            photoHighResolution = call.argument<Any?>("photoHighResolution") == true)
                }
                "getGroups" -> asyncTask(result) {
                    resolver.listAllGroups()
                            ?.toGroupList()
                            ?.filter { group -> group.contacts.isNotEmpty() }
                            ?.map { it.toMap() }
                            ?: emptyList()
                }
                "addContact" -> asyncTask(result) {
                    val c = Contact.fromMap(mode, call.arguments as Map<String, *>)
                    this.addContact(c)
                }
                "deleteContact" -> asyncTask(result) {
                    val ct = Contact.fromMap(mode, call.arguments as Map<String, *>)
                    this.deleteContact(ct)
                }
                "updateContact" -> asyncTask(result) {
                    val ct1 = Contact.fromMap(mode, call.arguments as Map<String, *>)
                    this.updateContact(ct1)
                }
                "openContactEditForm" -> {
                    when (val contactId = call.argument<Any?>("identifier")) {
                        null -> result.error(ErrorCodes.INVALID_PARAMETER, "Missing parameter: identifier", null)
                        else -> {
                            val keys = contactKeyOf(mode, contactId) ?: badParameter("openEditForm", "identifier")
                            contactForms.openContactEditForm(result, keys)
                        }
                    }
                }
                "openContactInsertForm" -> {
                    val contactFromArgs = Contact.fromMap(mode, call.arguments as? Map<String, *>
                            ?: emptyMap<String, Any?>())
                    contactForms.openContactInsertForm(result, mode, contactFromArgs)
                }
                else -> result.notImplemented()
            }

        } catch (e: Exception) {
            result.error("unknownError", "Unknown error", "$e")
        }
    }

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), flutterContactsChannelName)
            val events = EventChannel(registrar.messenger(), flutterContactsEventName)
            val plugin = FlutterAggregateContactPlugin(registrar)
            channel.setMethodCallHandler(plugin)
            events.setStreamHandler(plugin)

        }
    }
}

