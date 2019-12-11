package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.ContentUris
import android.database.Cursor
import android.graphics.Bitmap
import android.os.Build
import android.provider.ContactsContract
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.time.OffsetDateTime

@SuppressLint("Recycle")
fun ContentResolver.queryContacts(query: String? = null, sortBy: String? = null,
                                  forCount: Boolean = false): Cursor? {

  var selectionArgs = when (forCount) {
    true -> arrayOf()
    false -> arrayOf(
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
  }
  var selection = selectionArgs.joinToString(separator = " OR ") { "${ContactsContract.Data.MIMETYPE}=?" }

  val projections = if (forCount) contactProjectionsIdOnly else contactProjections
  if (query != null) {
    selectionArgs = arrayOf("$query%")
    selection = "${ContactsContract.Contacts.DISPLAY_NAME_PRIMARY} LIKE ?"
  }

  val sortOrder = if (!forCount) null else when (sortBy) {
    null -> null
    "firstName" -> ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME + " ASC"
    "lastName" -> ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME + " ASC"
    else -> ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME + " ASC"
  }

  return query(ContactsContract.Data.CONTENT_URI, projections, selection, selectionArgs, sortOrder)
}

fun ContentResolver.findContactById(identifier: String): Cursor? {
  return query(ContactsContract.Data.CONTENT_URI, contactProjections, "${ContactsContract.Data.CONTACT_ID} = ?", arrayOf(identifier), null)
}

/**
 * Builds the list of contacts from the cursor
 * @param cursor
 * @return the list of contacts
 */
@RequiresApi(Build.VERSION_CODES.O)
fun Cursor?.toContactList(limit: Int, offset: Int): List<Contact> {
  val cursor = this ?: return emptyList()

  val contactsById = mutableMapOf<String, Contact>()

  if(offset > 0) {
    val skipped = mutableSetOf<String>()
    while(skipped.size < offset && cursor.moveToNext()) {
      val columnIndex = cursor.getColumnIndex(ContactsContract.Data.CONTACT_ID)
      skipped += cursor.getString(columnIndex)
    }
  }

  while (cursor.moveToNext() && contactsById.size <= limit) {
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

      ContactsContract.Data.CONTACT_LAST_UPDATED_TIMESTAMP -> {
        cursor.string(ContactsContract.Data.CONTACT_LAST_UPDATED_TIMESTAMP)?.also {
          contact.lastModified = OffsetDateTime.parse(it)
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

      ContactsContract.CommonDataKinds.StructuredPostal.CONTENT_ITEM_TYPE -> {
        val address = PostalAddress(cursor)
        contact.postalAddresses += address
      }

      ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE -> {
        contact.company = cursor.string(ContactsContract.CommonDataKinds.Organization.COMPANY)
        contact.jobTitle = cursor.string(ContactsContract.CommonDataKinds.Organization.TITLE)
      }
      else -> {
        println("Ignoring mime: $mimeType")
      }
    }

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

    /// Phone
    ContactsContract.CommonDataKinds.Phone.NUMBER,
    ContactsContract.CommonDataKinds.Phone.TYPE,
    ContactsContract.CommonDataKinds.Phone.LABEL,

    /// Email
    ContactsContract.CommonDataKinds.Email.DATA,
    ContactsContract.CommonDataKinds.Email.ADDRESS,
    ContactsContract.CommonDataKinds.Email.TYPE,
    ContactsContract.CommonDataKinds.Email.LABEL,

    /// URLs
    ContactsContract.CommonDataKinds.Website.DATA,
    ContactsContract.CommonDataKinds.Website.URL,
    ContactsContract.CommonDataKinds.Website.TYPE,
    ContactsContract.CommonDataKinds.Website.LABEL,

    ContactsContract.CommonDataKinds.GroupMembership.GROUP_SOURCE_ID,

    /// Events
    ContactsContract.CommonDataKinds.Event.TYPE,
    ContactsContract.CommonDataKinds.Event.LABEL,
    ContactsContract.CommonDataKinds.Event.START_DATE,

    /// Companies
    ContactsContract.CommonDataKinds.Organization.COMPANY,
    ContactsContract.CommonDataKinds.Organization.TITLE,

    /// Postal address
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

val contactProjectionsIdOnly: Array<String> = arrayOf(
    ContactsContract.Data.CONTACT_ID,
    ContactsContract.Profile.DISPLAY_NAME)

interface ResolverExtensions {
  val resolver: ContentResolver

  fun getAvatarDataForContactIfAvailable(identifier: Long, highRes: Boolean = true): ByteArray? {
    val contactUri = ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, identifier)
    val input = ContactsContract.Contacts.openContactPhotoInputStream(resolver, contactUri, highRes)
    input.use { input ->
      val stream = ByteArrayOutputStream()
      return try {
        val bitmap = android.graphics.BitmapFactory.decodeStream(input)
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)

        stream.toByteArray()

      } catch (e: Exception) {
        print("Unable to fetch contact image: $e")
        null
      } finally {
        stream.close()
      }
    }
  }

  fun Contact.setAvatarDataForContactIfAvailable(highRes: Boolean) {
    val identifier = identifier?.value?.toLongOrNull() ?: return
    val bytes = getAvatarDataForContactIfAvailable(identifier, highRes = highRes) ?: return
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
      val groupId = cursor.string(ContactsContract.Groups.SOURCE_ID) ?: continue

      if (groupId !in groupsById) {
        groupsById[groupId] = Group(identifier = groupId)
      }
      val group = groupsById[groupId]!!

      cursor.int(ContactsContract.Groups.FAVORITES)?.also { favorite ->
        if (favorite > 0) {
          group.name = "Favorites"
        }
      }

      cursor.string(ContactsContract.Groups.TITLE)?.also { name ->
        group.name = name
      }
    }

    resolver.queryContacts()
        .toContactList(100, 0)
        .forEach { contact ->
          for (groupId in contact.groups) {
            val group = groupsById[groupId] ?: continue
            contact.identifier?.let { group.contacts += it.value }
          }
        }
    return groupsById.values.toList()
  }
}