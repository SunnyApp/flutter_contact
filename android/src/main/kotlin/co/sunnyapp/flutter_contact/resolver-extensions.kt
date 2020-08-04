@file:Suppress("NAME_SHADOWING", "FunctionName")

package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.database.Cursor
import android.graphics.Bitmap
import android.os.Build
import android.provider.ContactsContract
import android.provider.ContactsContract.*
import androidx.annotation.RequiresApi
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream

interface ContactExtensions {

    val resolver: ContentResolver
    val mode: ContactMode

    fun ContactKeys(id: Any) = contactKeyOf(mode = mode, value = id)
            ?: badParameter("{}", "identifier")

    @SuppressLint("Recycle")
    fun ContentResolver.queryContacts(query: String? = null, sortBy: String? = null,
                                      forCount: Boolean = false): Cursor? {

        var selectionArgs = when (forCount) {
            true -> arrayOf()
            false -> arrayOf(
                    CommonDataKinds.Note.CONTENT_ITEM_TYPE,
                    CommonDataKinds.Email.CONTENT_ITEM_TYPE,
                    CommonDataKinds.Website.CONTENT_ITEM_TYPE,
                    CommonDataKinds.Event.CONTENT_ITEM_TYPE,
                    CommonDataKinds.Phone.CONTENT_ITEM_TYPE,
                    CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE,
                    CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE,
                    CommonDataKinds.Organization.CONTENT_ITEM_TYPE,
                    CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE
            )
        }
        var selection = selectionArgs.joinToString(separator = " OR ") { "${Data.MIMETYPE}=?" }

        val projections = if (forCount) mode.projectionsIdsOnly else mode.projections
        if (query != null) {
            selectionArgs = arrayOf("$query%")
            selection = "${Data.DISPLAY_NAME_PRIMARY} LIKE ?"
        }

        val sortOrder = if (forCount) null else ContactSorting[sortBy]

        return query(Data.CONTENT_URI, projections, selection, selectionArgs, sortOrder?.expression)
    }

    fun ContentResolver.findContactById(keys: ContactKeys): Cursor? {
        return query(Data.CONTENT_URI, mode.projections, keys.toQuery(), keys.params, null)
    }

    /**
     * Builds the list of contacts from the cursor
     * @param cursor
     * @return the list of contacts
     */
    fun Cursor?.toContactList(limit: Int, offset: Int): List<Contact> {
        val cursor = this ?: return emptyList()

        val contactsById = mutableMapOf<String, Contact>()

        if (offset > 0) {
            val skipped = mutableSetOf<String>()
            while (skipped.size < offset && cursor.moveToNext()) {
                val columnIndex = cursor.getColumnIndex(mode.contactIdRef)
                skipped += cursor.getString(columnIndex)
            }
        }

        while (cursor.moveToNext() && contactsById.size <= limit) {
            val columnIndex = cursor.getColumnIndex(mode.contactIdRef)
            val contactId = cursor.getString(columnIndex)

            if (contactId !in contactsById) {
                contactsById[contactId] = Contact(keys = ContactKeys(contactId.toLong()))
            }
            val contact = contactsById[contactId]!!

            cursor.long(CommonDataKinds.Identity.RAW_CONTACT_ID)?.also {
                contact.rawContactId = it
            }
            cursor.long(CommonDataKinds.Identity.CONTACT_ID)?.also {
                contact.aggregateContactId = it
            }
            cursor.string(CommonDataKinds.Identity.LOOKUP_KEY)?.also {
                contact.lookupKey = it
            }

            val mimeType = cursor.string(Data.MIMETYPE)
            contact.displayName = contact.displayName
                    ?: cursor.string(CommonDataKinds.Nickname.DISPLAY_NAME)

            //NAMES
            when (mimeType) {
                CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE -> {
                    contact.givenName = cursor.string(CommonDataKinds.StructuredName.GIVEN_NAME)
                    contact.middleName = cursor.string(CommonDataKinds.StructuredName.MIDDLE_NAME)
                    contact.familyName = cursor.string(CommonDataKinds.StructuredName.FAMILY_NAME)
                    contact.prefix = cursor.string(CommonDataKinds.StructuredName.PREFIX)
                    contact.suffix = cursor.string(CommonDataKinds.StructuredName.SUFFIX)
                    contact.displayName = cursor.string(mode.nameRef)
                            ?: contact.displayName
                }
                CommonDataKinds.Note.CONTENT_ITEM_TYPE -> contact.note = cursor.string(CommonDataKinds.Note.NOTE)
                CommonDataKinds.Phone.CONTENT_ITEM_TYPE -> {
                    cursor.string(CommonDataKinds.Phone.NUMBER)?.also { phone ->
                        contact.phones += Item(label = cursor.getPhoneLabel(), value = phone)
                    }
                }

                Data.CONTACT_LAST_UPDATED_TIMESTAMP -> {
                    cursor.string(Data.CONTACT_LAST_UPDATED_TIMESTAMP)?.also {
                        contact.lastModified = it.toDate()
                    }
                }

                CommonDataKinds.Email.CONTENT_ITEM_TYPE -> {
                    cursor.string(CommonDataKinds.Email.ADDRESS)?.also { email ->
                        contact.emails += Item(label = cursor.getEmailLabel(), value = email)
                    }
                }
                CommonDataKinds.Event.CONTENT_ITEM_TYPE -> {
                    cursor.string(CommonDataKinds.Event.START_DATE)?.also { eventDate ->
                        contact.dates += Item(label = cursor.getEventLabel(), value = eventDate)
                    }
                }

                CommonDataKinds.Website.CONTENT_ITEM_TYPE -> {
                    cursor.string(CommonDataKinds.Website.URL)?.also { url ->
                        contact.urls += Item(label = cursor.getWebsiteLabel(), value = url)
                    }
                }

                CommonDataKinds.GroupMembership.CONTENT_ITEM_TYPE -> {
                    cursor.string(CommonDataKinds.GroupMembership.GROUP_SOURCE_ID)?.also { groupId ->
                        contact.groups += groupId
                    }
                }

                CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE -> {
                    val address = PostalAddress(cursor)
                    contact.postalAddresses += address
                }

                CommonDataKinds.Organization.CONTENT_ITEM_TYPE -> {
                    contact.company = cursor.string(CommonDataKinds.Organization.COMPANY)
                    contact.jobTitle = cursor.string(CommonDataKinds.Organization.TITLE)
                }
                else -> {
                    println("Ignoring mime: $mimeType")
                }
            }

        }
        if (!isClosed) {
            close();
        }
        return contactsById.values.toList()
    }


    fun getAvatarDataForContactIfAvailable(contactKeys: ContactKeys, highRes: Boolean = true): ByteArray? {
        val stream = resolver.openContactPhotoInputStream(contactKeys, highRes) ?: return null
        return stream.use { input ->
            val stream = ByteArrayOutputStream()

            val bitmap = android.graphics.BitmapFactory.decodeStream(input)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

            stream.toByteArray()
        }
    }

    fun Contact.setAvatarDataForContactIfAvailable(highRes: Boolean) {
        val keys = keys?.checkValid() ?: return
        val bytes = getAvatarDataForContactIfAvailable(keys, highRes = highRes) ?: return
        this.avatar = bytes
    }

    /**
     * Builds the list of contacts from the cursor
     * @param cursor
     * @return the list of contacts
     */
    @SuppressLint("NewApi")
    fun Cursor.toGroupList(): List<Group> {
        val groupsById = mutableMapOf<String, Group>()
        val cursor = this
        while (cursor.moveToNext()) {
            val groupId = cursor.string(Groups.SOURCE_ID) ?: continue

            if (groupId !in groupsById) {
                groupsById[groupId] = Group(identifier = groupId)
            }
            val group = groupsById[groupId]!!

            cursor.int(Groups.FAVORITES)?.also { favorite ->
                if (favorite > 0) {
                    group.name = "Favorites"
                }
            }

            cursor.string(Groups.TITLE)?.also { name ->
                group.name = name
            }
        }

        if (!isClosed) {
            close()
        }
        resolver.queryContacts()
                .toContactList(100, 0)
                .forEach { contact ->
                    for (groupId in contact.groups) {
                        val group = groupsById[groupId] ?: continue
                        contact.identifier?.let { group.contacts += it.toString() }
                    }
                }
        return groupsById.values.toList()
    }
}

/**
 * Copied from ContactsContract and adapted for RawContact
 */
fun ContentResolver.openContactPhotoInputStream(key: ContactKeys, preferHighres: Boolean): InputStream? {

    if (key.mode == ContactMode.AGGREGATE) return Contacts.openContactPhotoInputStream(this, key.contactUri, preferHighres)

    if (preferHighres) {
        try {
            return openAssetFileDescriptor(key.photoUri, "r")?.createInputStream()
        } catch (e: IOException) {
            // continue to the next block
        }
    }

    // FIND a data record where mimetype=PHOTO that matches the ID
    return query(Data.CONTENT_URI, arrayOf(Data.DATA15), "(${key.toQuery()}) AND ${Data.MIMETYPE} = ?",
            arrayOf(key.identifier.toString(), CommonDataKinds.Photo.CONTENT_ITEM_TYPE), null)
            ?.use { cursor ->
                when (cursor.moveToNext()) {
                    false -> null
                    true -> cursor.toInputStream()
                }
            }
}

