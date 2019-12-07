package co.sunnyapp.flutter_contact.tasks

import android.content.ContentResolver
import android.database.Cursor
import android.provider.ContactsContract
import co.sunnyapp.flutter_contact.*
import io.flutter.plugin.common.MethodChannel

data class Result<T> internal constructor(val value: T?,
                                          val errorCode: String?,
                                          val errorMessage: String?,
                                          val exception: Throwable?) {
    constructor(result: T) : this(value = result, errorCode = null, exception = null, errorMessage = null)
    constructor(errorCode: String, exception: Throwable, errorMessage: String? = null) : this(value = null,
            errorCode = errorCode,
            errorMessage = errorMessage,
            exception = exception)
}

fun ContentResolver.queryContacts(query: String? = null): Cursor? {
    var selectionArgs = arrayOf(
            ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE,
            ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE
    )
    var selection = selectionArgs.joinToString(separator = " OR ") { "${ContactsContract.Data.MIMETYPE}=?" }

    if (query != null) {
        selectionArgs = arrayOf("$query%")
        selection = "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} LIKE ?"
    }
    return query(ContactsContract.Data.CONTENT_URI, contactProjections, selection, selectionArgs, null)
}

fun ContentResolver.findContactById(identifier: String): Cursor? {
    return query(ContactsContract.Data.CONTENT_URI, contactProjections, "${ContactsContract.Data.CONTACT_ID} = ?", arrayOf(identifier), null)
}

/**
 * Builds the list of contacts from the cursor
 * @param cursor
 * @return the list of contacts
 */
fun Cursor?.toContactList(): List<Contact> {
    val cursor = this ?: return emptyList()

    val contactsById = mutableMapOf<String, Contact>()

    while (cursor.moveToNext()) {
        val columnIndex = cursor.getColumnIndex(ContactsContract.Data.CONTACT_ID)
        val contactId = cursor.getString(columnIndex)

        if (contactId !in contactsById) {
            contactsById[contactId] = Contact(contactId)
        }
        val contact = contactsById[contactId]!!

        val mimeType = cursor.string(ContactsContract.Data.MIMETYPE)
        contact.displayName = cursor.string(ContactsContract.Contacts.DISPLAY_NAME)

        //NAMES
        when (mimeType) {
            ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE -> {
                contact.givenName = cursor.string(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME)
                contact.middleName = cursor.string(ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME)
                contact.familyName = cursor.string(ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME)
                contact.prefix = cursor.string(ContactsContract.CommonDataKinds.StructuredName.PREFIX)
                contact.suffix = cursor.string(ContactsContract.CommonDataKinds.StructuredName.SUFFIX)
            }
            ContactsContract.CommonDataKinds.Note.CONTENT_ITEM_TYPE -> contact.note = cursor.string(ContactsContract.CommonDataKinds.Note.NOTE)
            ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE -> {
                cursor.string(ContactsContract.CommonDataKinds.Phone.NUMBER)?.also { phone ->
                    contact.phones += Item(label = cursor.getPhoneLabel(), value = phone)
                }
            }
            ContactsContract.CommonDataKinds.Email.CONTENT_ITEM_TYPE -> {
                cursor.string(ContactsContract.CommonDataKinds.Email.ADDRESS)?.also { email ->
                    contact.emails += Item(label = cursor.getEmailLabel(), value = email)
                }
            }
            ContactsContract.CommonDataKinds.Event.CONTENT_ITEM_TYPE -> {
                cursor.string(ContactsContract.CommonDataKinds.Event.START_DATE)?.also { eventDate ->
                    contact.dates += Item(label = cursor.getEventLabel(), value = eventDate)
                }
            }

            ContactsContract.CommonDataKinds.Website.CONTENT_ITEM_TYPE -> {
                cursor.string(ContactsContract.CommonDataKinds.Website.URL)?.also { url ->
                    contact.urls += Item(label = cursor.getWebsiteLabel(), value = url)
                }
            }

            ContactsContract.CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE -> {
                cursor.string(ContactsContract.CommonDataKinds.GroupMembership.GROUP_SOURCE_ID)?.also { groupId ->
                    contact.groups += groupId
                }
            }

            ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE -> {
                contact.company = cursor.string(ContactsContract.CommonDataKinds.Organization.COMPANY)
                contact.jobTitle = cursor.string(ContactsContract.CommonDataKinds.Organization.TITLE)
            }
            ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE -> contact.postalAddresses += PostalAddress(cursor)
        }

        //ADDRESSES
        //ORG
        //MAILS
        //PHONES
        // NOTE
        //ADDRESSES
        //ORG
        //MAILS
        //PHONES
        // NOTE
    }
    return contactsById.values.toList()
}

val contactProjections: Array<String> = arrayOf(
        ContactsContract.Data.CONTACT_ID,
        ContactsContract.Data.CONTACT_LAST_UPDATED_TIMESTAMP,
        ContactsContract.Profile.DISPLAY_NAME,
        ContactsContract.Contacts.Data.MIMETYPE,
        ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME,
        ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME,
        ContactsContract.CommonDataKinds.StructuredName.MIDDLE_NAME,
        ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME,
        ContactsContract.CommonDataKinds.StructuredName.PREFIX,
        ContactsContract.CommonDataKinds.StructuredName.SUFFIX,
        ContactsContract.CommonDataKinds.Note.NOTE,
        ContactsContract.CommonDataKinds.Phone.NUMBER,
        ContactsContract.CommonDataKinds.Phone.TYPE,
        ContactsContract.CommonDataKinds.Phone.LABEL,
        ContactsContract.CommonDataKinds.Email.DATA,
        ContactsContract.CommonDataKinds.Email.ADDRESS,
        ContactsContract.CommonDataKinds.Email.TYPE,
        ContactsContract.CommonDataKinds.Email.LABEL,

        ContactsContract.CommonDataKinds.Website.DATA,
        ContactsContract.CommonDataKinds.Website.URL,
        ContactsContract.CommonDataKinds.Website.TYPE,
        ContactsContract.CommonDataKinds.Website.LABEL,

        ContactsContract.CommonDataKinds.GroupMembership.GROUP_SOURCE_ID,

        ContactsContract.CommonDataKinds.Event.TYPE,
        ContactsContract.CommonDataKinds.Event.LABEL,
        ContactsContract.CommonDataKinds.Event.START_DATE,
        ContactsContract.CommonDataKinds.Organization.COMPANY,
        ContactsContract.CommonDataKinds.Organization.TITLE,
        ContactsContract.CommonDataKinds.StructuredPostal.FORMATTED_ADDRESS,
        ContactsContract.CommonDataKinds.StructuredPostal.TYPE,
        ContactsContract.CommonDataKinds.StructuredPostal.LABEL,
        ContactsContract.CommonDataKinds.StructuredPostal.STREET,
        ContactsContract.CommonDataKinds.StructuredPostal.POBOX,
        ContactsContract.CommonDataKinds.StructuredPostal.NEIGHBORHOOD,
        ContactsContract.CommonDataKinds.StructuredPostal.CITY,
        ContactsContract.CommonDataKinds.StructuredPostal.REGION,
        ContactsContract.CommonDataKinds.StructuredPostal.POSTCODE,
        ContactsContract.CommonDataKinds.StructuredPostal.COUNTRY,
        ContactsContract.Data.DATA1,
        ContactsContract.Data.DATA2,
        ContactsContract.Data.DATA3)

/// Uses a TaskResult to send an error or success
fun <T : Any> MethodChannel.Result.send(result: Result<T>) {
    when (result.errorCode) {
        null -> this.success(result.value)
        else -> this.error(result.errorCode, result.errorMessage ?: "${result.exception}", result.exception?.toString())
    }
}