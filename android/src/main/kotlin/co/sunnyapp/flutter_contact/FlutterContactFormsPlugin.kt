package co.sunnyapp.flutter_contact

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/// Class that facilitates edit/add contacts
class FlutterContactForms(private val plugin: FlutterContactPlugin, private val registrar: PluginRegistry.Registrar) : PluginRegistry.ActivityResultListener {
    init {
        registrar.addActivityResultListener(this)
    }

    var result: Result? = null
    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?): Boolean {
        val success = when (requestCode) {
            REQUEST_OPEN_EXISTING_CONTACT, REQUEST_OPEN_CONTACT_FORM -> when (val uri = intent?.data) {
                null -> {
                    result?.success(mapOf("success" to false, "code" to ErrorCodes.FORM_OPERATION_CANCELED))
                    false
                }
                else -> when (val contactIdString = uri.lastPathSegment) {
                    null -> {
                        result?.success(mapOf("success" to false, "code" to ErrorCodes.FORM_OPERATION_CANCELED))
                        false
                    }
                    else -> {
                        result?.success(mapOf(
                                "success" to true,
                                "contact" to plugin.getContact(ContactKeys(plugin.mode, contactIdString.toLong()),
                                        withThumbnails = false, photoHighResolution = false)))
                        true
                    }
                }
            }
            else -> {
                result?.success(ErrorCodes.FORM_COULD_NOT_BE_OPENED)
                false
            }
        }
        result = null
        return success
    }

    fun openContactEditForm(result: Result, contactId: ContactKeys) {
        this.result = result
        try {
            val lookupUri = contactId.mode.lookupUri(plugin.resolver, contactId)
//            val contact = plugin.getContactRecord(contactId, withThumbnails = false, photoHighResolution = false)
            val intent = Intent(Intent.ACTION_EDIT)
            intent.setDataAndTypeAndNormalize(lookupUri, ContactsContract.Contacts.CONTENT_ITEM_TYPE)
            intent.putExtra("finishActivityOnSaveCompleted", true)
            startIntent(intent, REQUEST_OPEN_EXISTING_CONTACT)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Unable to open form", e.toString())
            this.result = null
        }
    }

    fun openContactInsertForm(result: Result, mode: ContactMode, contact: Contact) {
        try {
            this.result = result
            val intent = Intent(Intent.ACTION_INSERT, mode.contentUri)
            contact.applyToIntent(intent)
            intent.putExtra("finishActivityOnSaveCompleted", true)
            startIntent(intent, REQUEST_OPEN_CONTACT_FORM)
        } catch (e: MethodCallException) {
            result.error(e.code, "Error with ${e.method}: ${e.error}", e.error)
            this.result = null
        } catch (e: Exception) {
            result.error(ErrorCodes.UNKNOWN_ERROR, "Problem opening contact form", "$e")
            this.result = null
        }
    }

    private fun startIntent(intent: Intent, request: Int) {
        if (registrar.activity() != null) {
            registrar.activity().startActivityForResult(intent, request)
        } else {
            registrar.context().startActivity(intent)
        }
    }


    companion object {
        const val REQUEST_OPEN_CONTACT_FORM = 52941
        const val REQUEST_OPEN_EXISTING_CONTACT = 52942
    }

}

/// For now, only copies basic properties
fun Contact.applyToIntent(intent: Intent) {
    intent.apply {
        putExtra(ContactsContract.Intents.Insert.EMAIL, emails.firstOrNull()?.value)
        putExtra(ContactsContract.Intents.Insert.PHONE, phones.firstOrNull()?.value)
        putExtra(ContactsContract.Intents.Insert.COMPANY, company)
        putExtra(ContactsContract.Intents.Insert.NAME, displayName)
    }
}