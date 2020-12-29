package co.sunnyapp.flutter_contact

import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.*
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.ArrayList

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

fun Contact.applyToIntent(intent: Intent) {
    val data: ArrayList<ContentValues> = ArrayList()

    /// StructuredName not working
    //    val name = ContentValues()
    //    name.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, givenName)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, givenName)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, familyName)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.PREFIX, prefix)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, middleName)
    //    name.put(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, suffix)
    //    data.add(name)
    /// Name
    val name = if (displayName != null) displayName else listOfNotNull(prefix, givenName, middleName, familyName, suffix).joinToString(" ")

    /// Phones
    for (item in phones) {
        val phone = ContentValues()
        phone.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
        phone.put(ContactsContract.CommonDataKinds.Phone.NUMBER, item.value)
        phone.put(ContactsContract.CommonDataKinds.Phone.LABEL, item.label)
        phone.put(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(phone)
    }

    /// Emails
    for (item in emails) {
        val email = ContentValues()
        email.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
        email.put(ContactsContract.CommonDataKinds.Email.ADDRESS, item.value)
        email.put(ContactsContract.CommonDataKinds.Email.LABEL, item.label)
        email.put(ContactsContract.CommonDataKinds.Email.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(email)
    }

    /// Urls
    for (item in urls) {
        val url = ContentValues()
        url.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
        url.put(ContactsContract.CommonDataKinds.Website.URL, item.value)
        url.put(ContactsContract.CommonDataKinds.Website.LABEL, item.label)
        url.put(ContactsContract.CommonDataKinds.Website.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(url)
    }

    /// Social Profiles
    for (item in socialProfiles) {
        val profile = ContentValues()
        profile.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
        profile.put(ContactsContract.CommonDataKinds.Website.URL, item.value)
        profile.put(ContactsContract.CommonDataKinds.Website.LABEL, item.label)
        profile.put(ContactsContract.CommonDataKinds.Website.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(profile)
    }

    /// Addresses
    for (item in postalAddresses) {
        val address = ContentValues()
        address.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.STREET, item.street)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.CITY, item.city)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.REGION, item.region)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, item.postcode)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, item.country)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.LABEL, item.label)
        address.put(ContactsContract.CommonDataKinds.StructuredPostal.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(address)
    }

    /// Dates
    for (item in dates) {
        val event = ContentValues()
        event.put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE)
        event.put(ContactsContract.CommonDataKinds.Event.START_DATE, item.value)
        event.put(ContactsContract.CommonDataKinds.Event.LABEL, item.label)
        event.put(ContactsContract.CommonDataKinds.Event.TYPE, ContactsContract.CommonDataKinds.BaseTypes.TYPE_CUSTOM)
        data.add(event)
    }

    intent.apply {
        putExtra(ContactsContract.Intents.Insert.NAME, name)
        putExtra(ContactsContract.Intents.Insert.DATA, data)
        putExtra(ContactsContract.Intents.Insert.COMPANY, company)
        putExtra(ContactsContract.Intents.Insert.JOB_TITLE, jobTitle)
        putExtra(ContactsContract.Intents.Insert.NOTES, note)
    }
}