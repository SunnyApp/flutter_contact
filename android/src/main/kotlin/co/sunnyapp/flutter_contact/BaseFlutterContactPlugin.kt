@file:Suppress("UNCHECKED_CAST", "NewApi", "MemberVisibilityCanBePrivate", "UnnecessaryVariable")

package co.sunnyapp.flutter_contact

import android.annotation.TargetApi
import android.content.ContentProviderOperation
import android.content.ContentResolver
import android.content.Context
import android.os.Build
import android.os.Handler
import android.provider.ContactsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.util.*

/**
 * Base class for the flutter_contact plugin.  There are two modes for this plugin: aggregate and raw.
 *
 * Aggregate deals with linked contacts, where there will be one record per group of linked contacts
 * Raw deals with the individual contacts.
 */
abstract class BaseFlutterContactPlugin : ContactExtensions, EventChannel.StreamHandler {
    lateinit var context: Context
    lateinit var contactForms: BaseFlutterContactForms

    var methodChannel: MethodChannel? = null
    var eventChannel: EventChannel? = null

    abstract override val mode: ContactMode

    override val resolver: ContentResolver
        get() = context.contentResolver

    abstract fun initInstance(applicationContext: Context, messenger: BinaryMessenger, registrar: PluginRegistry.Registrar?)

    fun unInitInstance() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        eventChannel?.setStreamHandler(null)
        eventChannel = null
    }

    @TargetApi(Build.VERSION_CODES.ECLAIR)
    protected fun getContacts(query: String?, withThumbnails: Boolean, photoHighResolution: Boolean,
                              sortBy: String? = null,
                              phoneQuery: Boolean?, offset: Int?, limit: Int?): StructList {

        val contacts = resolver.queryContacts(query, sortBy)
                ?.toContactList(mode, limit ?: 30, offset ?: 0)
                ?.onEach { contact ->
                    if (withThumbnails || photoHighResolution) {
                        contact.setAvatarDataForContactIfAvailable(photoHighResolution)
                    }
                } ?: emptyList()

        return contacts.map { it.toMap() }
    }

    protected fun getTotalContacts(query: String?, phoneQuery: Boolean?): Int {
        return resolver.queryContacts(query, null, forCount = true)
                ?.count ?: 0
    }

    protected fun getContactImage(identifier: Any?): ByteArray? {
        return getAvatarDataForContactIfAvailable(contactKeyOf(mode, identifier) ?: return null)
    }

    fun getContact(identifier: ContactKeys, withThumbnails: Boolean, photoHighResolution: Boolean): Struct {
        val contact = getContactRecord(identifier, withThumbnails, photoHighResolution)
        return contact.toMap()
    }

    fun getContactRecord(identifier: ContactKeys, withThumbnails: Boolean,
                         photoHighResolution: Boolean): Contact {
        resolver
                .findContactById(identifier)
                ?.use { cursor ->
                    val contactList = cursor.toContactList(mode, 1, 0)
                    val contact = contactList
                            .firstOrNull()
                            ?: methodError("getContact", "notFound",
                                    "Expected a single result for contact ${identifier}, " +
                                            "but instead found ${contactList.size}")

                    if (withThumbnails || photoHighResolution) {
                        contact.setAvatarDataForContactIfAvailable(photoHighResolution)
                    }
                    return contact
                }
                ?: methodError("getContact", "notFound", "Expected a single result for contact $identifier")
    }


    protected fun addContact(contact: Contact): Struct {
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
                    .withTypeAndLabel(ItemType.phone, phone.label)
                    .build()
        }

        //Emails
        for (email in contact.emails) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.value)
                    .withTypeAndLabel(ItemType.email, email.label)
                    .build()
        }

        //Postal addresses
        for (address in contact.postalAddresses) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withTypeAndLabel(ItemType.address, address.label)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.STREET, address.street)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.CITY, address.city)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.REGION, address.region)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, address.country)
                    .build()
        }

        for (date in contact.dates) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                    .withTypeAndLabel(ItemType.event, date.label)
                    .withValue(ContactsContract.CommonDataKinds.Event.START_DATE, date.toDateValue())
                    .build()
        }

        for (url in contact.urls) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, 0)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
                    .withTypeAndLabel(ItemType.url, url.label)
                    .withValue(ContactsContract.CommonDataKinds.Website.URL, url.value)
                    .build()
        }


        val saveResult = resolver.applyBatch(ContactsContract.AUTHORITY, ops)
        val contactId = saveResult.first().uri?.lastPathSegment?.toLong()
                ?: pluginError("invalidId", "Expected a valid id")

        return getContact(ContactKeys(contactId), withThumbnails = true, photoHighResolution = true)
    }

    protected fun deleteContact(contact: Contact): Boolean {
        val ops = ArrayList<ContentProviderOperation>()
        val contactUri = contact.keys!!.contactUri
        ops.add(ContentProviderOperation.newDelete(contactUri)
                .build())
        return try {
            resolver.applyBatch(ContactsContract.AUTHORITY, ops)
            true
        } catch (e: Exception) {
            false
        }
    }

    protected fun updateContact(contact: Contact): Struct {
        val ops = arrayListOf<ContentProviderOperation>()

        ops += listOf(ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE,
                ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE
        ).map {
            ContentProviderOperation.newDelete(ContactsContract.Data.CONTENT_URI)
                    .withSelection(ContactsContract.Data.RAW_CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                            arrayOf(contact.identifier?.toString(), it))
                    .build()

        }

        val names = listOfNotNull(contact.givenName, contact.familyName)
        val displayName = when {
            names.isEmpty() -> contact.displayName
            else -> names.joinToString(" ")
        }
        // Update data (name)
        ops += ContentProviderOperation.newUpdate(ContactsContract.Data.CONTENT_URI)
                .withSelection(ContactsContract.Data.RAW_CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                        arrayOf(contact.identifier?.toString(), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE))
                .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, displayName)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, contact.givenName)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME, contact.middleName)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME, contact.familyName)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.PREFIX, contact.prefix)
                .withValue(ContactsContract.CommonDataKinds.StructuredName.SUFFIX, contact.suffix)
                .build()

        // Insert data back into contact
        ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                .withValue(ContactsContract.CommonDataKinds.Organization.TYPE, ContactsContract.CommonDataKinds.Organization.TYPE_WORK)
                .withValue(ContactsContract.CommonDataKinds.Organization.COMPANY, contact.company)
                .withValue(ContactsContract.CommonDataKinds.Organization.TITLE, contact.jobTitle)
                .build()

        ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE)
                .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                .withValue(ContactsContract.CommonDataKinds.Note.NOTE, contact.note)
                .build()

        for (phone in contact.phones) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone.value)
                    .withTypeAndLabel(ItemType.phone, phone.label)
                    .build()
        }

        for (email in contact.emails) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                    .withValue(ContactsContract.CommonDataKinds.Email.ADDRESS, email.value)
                    .withTypeAndLabel(ItemType.email, email.label)
                    .build()
        }

        for (address in contact.postalAddresses) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                    .withTypeAndLabel(ItemType.address, address.label)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.STREET, address.street)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.CITY, address.city)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.REGION, address.region)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE, address.postcode)
                    .withValue(ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY, address.country)
                    .build()
        }



        for (date in contact.dates) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                    .withTypeAndLabel(ItemType.event, date.label)
                    .withValue(ContactsContract.CommonDataKinds.Event.START_DATE, date.toDateValue())
                    .build()
        }

        for (url in contact.urls) {
            ops += ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.Data.RAW_CONTACT_ID, contact.identifier?.toString())
                    .withTypeAndLabel(ItemType.url, url.label)
                    .withValue(ContactsContract.CommonDataKinds.Website.URL, url.value)
                    .build()
        }

        resolver.applyBatch(ContactsContract.AUTHORITY, ops)
        val updated = getContact(contact.keys
                ?: pluginError("invalidInput", "Updated contact should have an id"),
                withThumbnails = true,
                photoHighResolution = true)
        return updated
    }

    var contentObserver: ContactsContentObserver? = null
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events != null) {
            try {
                val contentObserver = ContactsContentObserver(events, Handler(context.mainLooper))
                resolver.registerContentObserver(ContactsContract.Contacts.CONTENT_URI, true, contentObserver)
                this.contentObserver = contentObserver
            } catch (e: SecurityException) {
                events.error("invalidPermissions", "No permissions for event.  Try" +
                        "starting the listener after you've requested permissions", null)
                events.endOfStream()
            }
        }
    }

    override fun onCancel(arguments: Any?) {

        when (val observer = contentObserver) {
            null -> {
            }
            else -> {
                resolver.unregisterContentObserver(observer)
                observer.close()
                this.contentObserver = null
            }
        }
    }
}