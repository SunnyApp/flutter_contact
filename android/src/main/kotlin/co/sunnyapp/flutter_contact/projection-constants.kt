package co.sunnyapp.flutter_contact

import android.content.ContentResolver
import android.net.Uri
import android.provider.ContactsContract.*

typealias GetLookupUri = (ContentResolver, ContactKeys) -> Uri

/**
 * This enum provides most of the implementation variations between working with Contact vs RawContact
 */
enum class ContactMode(val contentUri: Uri,
                       val contactIdRef: String,
                       val contentType: String,
                       val lookupUri: GetLookupUri,
                       val photoRef: String,
                       val nameRef: String,
                       val projections: Array<String>,
                       val projectionsIdsOnly: Array<String>) {


    UNIFIED(
            contentUri = Contacts.CONTENT_URI,
            contentType = Contacts.CONTENT_ITEM_TYPE,
            contactIdRef = Data.CONTACT_ID,
            lookupUri = { resolver, keys ->
                Contacts.getLookupUri(resolver, keys.contactUri)
            },
            nameRef = CommonDataKinds.StructuredName.DISPLAY_NAME,
            photoRef = Contacts.Photo.CONTENT_DIRECTORY,
            projections = contactProjections,
            projectionsIdsOnly = contactProjectionsIdOnly),
    SINGLE(contentUri = RawContacts.CONTENT_URI,
            contentType = RawContacts.CONTENT_ITEM_TYPE,
            contactIdRef = Data.RAW_CONTACT_ID,
            lookupUri = { resolver, keys ->
                RawContacts.getContactLookupUri(resolver, keys.contactUri)
            },
            nameRef = CommonDataKinds.StructuredName.DISPLAY_NAME,
            photoRef = RawContacts.DisplayPhoto.CONTENT_DIRECTORY,
            projections = contactProjections,
            projectionsIdsOnly = contactProjectionsIdOnly);

}

val groupProjections: Array<String> = arrayOf(
        Groups.SOURCE_ID,
        Groups.ACCOUNT_TYPE,
        Groups.ACCOUNT_NAME,
        Groups.DELETED,
        Groups.FAVORITES,
        Groups.TITLE,
        Groups.NOTES)


private val contactProjectionsIdOnly: Array<String> = arrayOf(
        Data.CONTACT_ID,
        Profile.DISPLAY_NAME)

private val contactProjections: Array<String> = arrayOf(

        Data.CONTACT_LAST_UPDATED_TIMESTAMP,
        Profile.DISPLAY_NAME,
        Data.MIMETYPE,
        CommonDataKinds.StructuredName.DISPLAY_NAME,
        CommonDataKinds.StructuredName.GIVEN_NAME,
        CommonDataKinds.StructuredName.MIDDLE_NAME,
        CommonDataKinds.StructuredName.FAMILY_NAME,
        CommonDataKinds.StructuredName.PREFIX,
        CommonDataKinds.StructuredName.SUFFIX,
        CommonDataKinds.Identity.RAW_CONTACT_ID,
        CommonDataKinds.Identity.CONTACT_ID,
        CommonDataKinds.Identity.LOOKUP_KEY,
        CommonDataKinds.Note.NOTE,

        /// Phone
        CommonDataKinds.Phone.NUMBER,
        CommonDataKinds.Phone.TYPE,
        CommonDataKinds.Phone.LABEL,

        /// Email
        CommonDataKinds.Email.DATA,
        CommonDataKinds.Email.ADDRESS,
        CommonDataKinds.Email.TYPE,
        CommonDataKinds.Email.LABEL,

        /// URLs
        CommonDataKinds.Website.DATA,
        CommonDataKinds.Website.URL,
        CommonDataKinds.Website.TYPE,
        CommonDataKinds.Website.LABEL,

        CommonDataKinds.GroupMembership.GROUP_SOURCE_ID,

        /// Events
        CommonDataKinds.Event.TYPE,
        CommonDataKinds.Event.LABEL,
        CommonDataKinds.Event.START_DATE,

        /// Companies
        CommonDataKinds.Organization.COMPANY,
        CommonDataKinds.Organization.TITLE,

        /// Postal address
        CommonDataKinds.StructuredPostal.FORMATTED_ADDRESS,
        CommonDataKinds.StructuredPostal.TYPE,
        CommonDataKinds.StructuredPostal.LABEL,
        CommonDataKinds.StructuredPostal.STREET,
        CommonDataKinds.StructuredPostal.POBOX,
        CommonDataKinds.StructuredPostal.NEIGHBORHOOD,
        CommonDataKinds.StructuredPostal.CITY,
        CommonDataKinds.StructuredPostal.REGION,
        CommonDataKinds.StructuredPostal.POSTCODE,
        CommonDataKinds.StructuredPostal.COUNTRY,

        Data.DATA1,
        Data.DATA2,
        Data.DATA3)