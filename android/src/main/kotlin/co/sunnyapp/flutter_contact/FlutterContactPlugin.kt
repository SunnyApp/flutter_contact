@file:Suppress("UNCHECKED_CAST")

package co.sunnyapp.flutter_contact


import android.annotation.TargetApi
import android.content.ContentProviderOperation
import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.provider.ContactsContract
import co.sunnyapp.flutter_contact.tasks.GetContactTask
import co.sunnyapp.flutter_contact.tasks.GetContactsTask
import co.sunnyapp.flutter_contact.tasks.GetGroupsTask
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.*


const val flutterContactsChannelName = "github.com/sunnyapp/flutter_contact"
const val flutterContactsEventName = "github.com/sunnyapp/flutter_contact_events"

class FlutterContactPlugin(private val context: Context) : MethodCallHandler,
    EventChannel.StreamHandler {
  override fun onMethodCall(call: MethodCall, result: Result) {
    try {
      when (call.method) {
        "getContacts" -> this.getContacts(
            query = call.argument("query"),
            withThumbnails = call.argument<Any?>("withThumbnails") == true,
            photoHighResolution = call.argument<Any?>("photoHighResolution") == true,
            limit = call.argument("limit"),
            offset = call.argument("offset"),
            phoneQuery = call.argument("phoneQuery"),
            result = result)
        "getContact" -> this.getContact(
            identifier = ContactId(call.argument<String>("identifier")!!),
            withThumbnails = call.argument<Any?>("withThumbnails") == true,
            photoHighResolution = call.argument<Any?>("photoHighResolution") == true,
            result = result)
        "getGroups" -> this.getGroups(result = result)
        "addContact" -> {
          val c = Contact.fromMap(call.arguments as Map<String, *>)
          try {
            this.addContact(c, result)
          } catch (e: Throwable) {
            result.error("failed-add", "Failed to add the contact", "$e")
          }

        }
        "deleteContact" -> {
          val ct = Contact.fromMap(call.arguments as Map<String, *>)
          if (this.deleteContact(ct)) {
            result.success(null)
          } else {
            result.error("failed-delete", "Failed to delete the contact, make sure it has a valid identifier", null)
          }
        }
        "updateContact" -> {
          val ct1 = Contact.fromMap(call.arguments as Map<String, *>)
          try {
            this.updateContact(ct1, result)
          } catch (e: Throwable) {
            result.error("failed-update", "Failed to update the contact, make sure it has a valid identifier", null)
          }
        }
        else -> result.notImplemented()
      }
    } catch (e: Exception) {
      result.error("unknown-error", "Unknown error", "$e")
    }
  }

  @TargetApi(Build.VERSION_CODES.ECLAIR)
  private fun getContacts(query: String?, withThumbnails: Boolean, photoHighResolution: Boolean,
                          phoneQuery: String?, offset: Int?, limit: Int?,
                          result: Result) {
    GetContactsTask(result, resolver = context.contentResolver, withThumbnails = withThumbnails,
        photoHighResolution = photoHighResolution, offset = offset ?: 0, limit = limit ?: 30
    ).execute(query ?: phoneQuery)
  }


  @TargetApi(Build.VERSION_CODES.ECLAIR)
  private fun getContact(identifier: ContactId, withThumbnails: Boolean, photoHighResolution: Boolean, result: Result) {
    GetContactTask(result,
        resolver = context.contentResolver,
        withThumbnails = withThumbnails,
        highResolutionPhoto = photoHighResolution).execute(identifier)
  }

  @TargetApi(Build.VERSION_CODES.ECLAIR)
  private fun getGroups(result: Result) {
    GetGroupsTask(result, resolver = context.contentResolver).execute()
  }


  private fun addContact(contact: Contact, result: Result) {
    val ops = arrayListOf<ContentProviderOperation>()

    ops += ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
        .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
        .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
        .build()


    ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, contact.givenName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, contact.middleName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, contact.familyName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.PREFIX, contact.prefix)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, contact.suffix).build()


    ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
        .withValue(ContactsContract.CommonDataKinds.Note.NOTE, contact.note)
        .build()


    ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
        .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
        .withValue(ContactsContract.CommonDataKinds.Organization.COMPANY, contact.company)
        .withValue(ContactsContract.CommonDataKinds.Organization.TITLE, contact.jobTitle).withYieldAllowed(true)
        .build()

    //Phones
    for (phone in contact.phones) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value)
          .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, Item.stringToPhoneType(phone.label))
          .build()
    }

    //Emails
    for (email in contact.emails) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.value)
          .withValue(ContactsContract.CommonDataKinds.Email.TYPE, Item.stringToEmailType(email.label))
          .build()
    }

    //Postal addresses
    for (address in contact.postalAddresses) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.TYPE, address.label?.toPostalAddressType())
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.LABEL, address.label)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.STREET, address.street)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.CITY, address.city)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.REGION, address.region)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, address.country)
          .build()
    }

    val saveResult = context.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
    val contactId = saveResult.first().uri.lastPathSegment?.toLong()
        ?: error("Expected a valid id")
    getContact(ContactId("$contactId"), withThumbnails = true, photoHighResolution = true, result = result)
  }


  private fun deleteContact(contact: Contact): Boolean {
    val ops = ArrayList<ContentProviderOperation>()
    ops.add(ContentProviderOperation.newDelete(ContactsContract.RawContacts.CONTENT_URI)
        .withSelection(ContactsContract.RawContacts.CONTACT_ID + "=?", arrayOf(contact.identifier!!.value))
        .build())
    return try {
      context.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
      true
    } catch (e: Exception) {
      false
    }
  }

  private fun updateContact(contact: Contact, result: Result) {
    val ops = arrayListOf<ContentProviderOperation>()

    // Drop all details about contact except name
    ops += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
        .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE))
        .build()

    ops += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
        .withSelection("${ContactsContract.Data.CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE}=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE))
        .build()

    ops += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
        .withSelection("${ContactsContract.Data.CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE}=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE))
        .build()

    ops += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
        .withSelection("${ContactsContract.Data.CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE}=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)).build()

    ops += ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
        .withSelection("${ContactsContract.Data.CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE}=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE))
        .build()

    // Update data (name)
    ops += ContentProviderOperation.newUpdate(ContactsContract.Data.CONTENT_URI)
        .withSelection(ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
            arrayOf(contact.identifier?.value, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE))
        .withValue(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, contact.givenName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, contact.middleName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, contact.familyName)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.PREFIX, contact.prefix)
        .withValue(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, contact.suffix)
        .build()

    // Insert data back into contact
    ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
        .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.value)
        .withValue(ContactsContract.CommonDataKinds.Organization.TYPE, ContactsContract.CommonDataKinds.Organization.TYPE_WORK)
        .withValue(ContactsContract.CommonDataKinds.Organization.COMPANY, contact.company)
        .withValue(ContactsContract.CommonDataKinds.Organization.TITLE, contact.jobTitle)
        .build()

    ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
        .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
        .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.value)
        .withValue(ContactsContract.CommonDataKinds.Note.NOTE, contact.note)
        .build()

    for (phone in contact.phones) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.value)
          .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value)
          .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, Item.stringToPhoneType(phone.label))
          .build()
    }

    for (email in contact.emails) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.value)
          .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.value)
          .withValue(ContactsContract.CommonDataKinds.Email.TYPE, Item.stringToEmailType(email.label))
          .build()
    }

    for (address in contact.postalAddresses) {
      ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
          .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
          .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.value)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.TYPE, address.label.toPostalAddressType())
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.STREET, address.street)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.CITY, address.city)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.REGION, address.region)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
          .withValue(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, address.country)
          .build()
    }


    context.contentResolver.applyBatch(ContactsContract.AUTHORITY, ops)
    getContact(contact.identifier
        ?: error("Updated contact should have an id"), withThumbnails = true,
        photoHighResolution = true, result = result)

  }

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), flutterContactsChannelName)
      val events = EventChannel(registrar.messenger(), flutterContactsEventName)
      val plugin = FlutterContactPlugin(registrar.context())
      channel.setMethodCallHandler(plugin)
      events.setStreamHandler(plugin)
    }
  }

  var contentObserver: ContactsContentObserver? = null
  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    if (events != null) {
      val contentObserver = ContactsContentObserver(events, Handler(context.mainLooper))
      context.contentResolver.registerContentObserver(ContactsContract.Contacts.CONTENT_URI, true, contentObserver)
      this.contentObserver = contentObserver
    }
  }

  override fun onCancel(arguments: Any?) {

    when (val observer = contentObserver) {
      null -> {
      }
      else -> {
        context.contentResolver.unregisterContentObserver(observer)
        observer.close()
        this.contentObserver = null
      }
    }
  }
}

class ContactsContentObserver(private val sink: EventChannel.EventSink, handler: Handler) : ContentObserver(handler) {

  override fun deliverSelfNotifications(): Boolean {
    return true
  }

  override fun onChange(selfChange: Boolean) {
    sink.success(ContactsChangedEvent)
  }

  override fun onChange(selfChange: Boolean, uri: Uri?) {
    val event = when (uri) {
      null -> ContactsChangedEvent
      Uri.parse("content://com.android.contacts") -> ContactsChangedEvent
      ContactsContract.Contacts.CONTENT_URI -> ContactsChangedEvent
      else -> ContactChangedEvent(contactId = uri.lastPathSegment!!)
    }
    sink.success(event.toMap())
  }

  fun close() {
    sink.endOfStream()
  }
}
