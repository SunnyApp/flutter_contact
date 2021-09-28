@file:Suppress("UNCHECKED_CAST", "NewApi", "MemberVisibilityCanBePrivate")

package co.sunnyapp.flutter_contact


import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.*
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result


const val flutterRawContactsChannelName = "github.com/sunnyapp/flutter_single_contact"
const val flutterRawContactsEventName = "github.com/sunnyapp/flutter_single_contact_events"

/**
 * Instance of plugin that deals with non-unified single contacts
 */
class FlutterRawContactPlugin : BaseFlutterContactPlugin(), MethodCallHandler {

    override val mode = ContactMode.SINGLE

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
                            identifier = ContactKeys(call.argument<String>("identifier")!!),
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
                            val keys = contactKeyOf(mode, contactId)
                                    ?: badParameter("openEditForm", "identifier")
                            contactForms.openContactEditForm(result, keys)
                        }
                    }
                }
                "openContactInsertForm" -> {
                    val contactFromArgs = Contact.fromMap(mode, call.arguments as? Map<String, *>
                            ?: emptyMap<String, Any?>())
                    contactForms.openContactInsertForm(result, mode, contactFromArgs)
                }
                "openContactPicker" -> {
                    contactForms.openContactPicker(result, mode)
                }
                "insertOrUpdateContactViaPicker" -> {
                    val contactFromArgs = Contact.fromMap(mode, call.arguments as? Map<String, *>
                            ?: emptyMap<String, Any?>())
                    println(contactFromArgs.toMap())
                    contactForms.insertOrUpdateContactViaPicker(result, mode, contactFromArgs)
                }
                else -> result.notImplemented()
            }

        } catch (e: Exception) {
            result.error("unknownError", "Unknown error", "$e")
        }
    }

    override fun initInstance(applicationContext: Context, messenger: BinaryMessenger, registrar: PluginRegistry.Registrar?) {
        methodChannel = MethodChannel(messenger, flutterRawContactsChannelName)
        eventChannel = EventChannel(messenger, flutterRawContactsEventName)
        methodChannel!!.setMethodCallHandler(this)
        eventChannel!!.setStreamHandler(this)
        context = applicationContext
        contactForms = if (registrar == null) {
            // initializing the instance with v2 embedding
            FlutterContactForms(this, context)
        } else {
            // initializing the instance with v1 embedding
            FlutterContactFormsOld(this, registrar)
        }
    }
}
