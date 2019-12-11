@file:Suppress("ArrayInDataClass", "UNCHECKED_CAST", "EXPERIMENTAL_FEATURE_WARNING")

package co.sunnyapp.flutter_contact

import android.content.ContentUris
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import androidx.annotation.RequiresApi
import java.time.OffsetDateTime

typealias StructList = List<Struct>
typealias Struct = Map<String, Any>

data class ContactId(val value: String) {
  fun toUri(): Uri {
    return ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, value.toLong())
  }

  override fun toString(): String = value
}

data class Contact(
        var identifier: ContactId? = null,
        var displayName: String? = null,
        var givenName: String? = null,
        var middleName: String? = null,
        var familyName: String? = null,
        var prefix: String? = null,
        var suffix: String? = null,
        var company: String? = null,
        var jobTitle: String? = null,
        var lastModified: OffsetDateTime? = null,
        var note: String? = null,
        val emails: MutableList<Item> = mutableListOf(),
        val groups: MutableSet<String> = linkedSetOf(),
        val phones: MutableList<Item> = mutableListOf(),
        val socialProfiles: MutableList<Item> = mutableListOf(),
        val urls: MutableList<Item> = mutableListOf(),
        val dates: MutableList<Item> = mutableListOf(),
        val postalAddresses: MutableList<PostalAddress> = mutableListOf(),
        var avatar: ByteArray? = null
) {

  constructor(identifier: String): this(identifier = ContactId(identifier))

  fun toMap() = mutableMapOf(
      "identifier" to identifier?.value,
      "displayName" to displayName,
      "givenName" to givenName,
      "middleName" to middleName,
      "familyName" to familyName,
      "prefix" to prefix,
      "suffix" to suffix,
      "company" to company,
      "jobTitle" to jobTitle,
      "lastModified" to lastModified.toString(),
      "avatar" to avatar,
      "note" to note,
      "phones" to phones.toItemMap(),
      "emails" to emails.toItemMap(),
      "groups" to groups.toList(),
      "socialProfiles" to socialProfiles.toItemMap(),
      "urls" to urls.toItemMap(),
      "dates" to dates.toItemMap(),
      "postalAddresses" to postalAddresses.toAddressMap()
  ).filterValuesNotNull()

  companion object {

    @RequiresApi(Build.VERSION_CODES.O)
    fun fromMap(map: Map<String, *>): Contact {
      val contact = Contact(
          identifier = (map["identifier"] as String?)?.let{ContactId(it)},
          givenName = map["givenName"] as String?,
          middleName = map["middleName"] as String?,
          familyName = map["familyName"] as String?,
          prefix = map["prefix"] as String?,
          suffix = map["suffix"] as String?,
          lastModified = (map["lastModified"] as? String)?.toDate(),
          company = map["company"] as String?,
          jobTitle = map["jobTitle"] as String?,
          avatar = (map["avatar"] as? ByteArray?),
          note = map["note"] as String?,
          groups = (map["groups"] as Iterable<String>?).orEmpty().toMutableSet(),
          emails = (map["emails"] as? StructList?).toItemList(),
          phones = (map["phones"] as? StructList?).toItemList(),
          socialProfiles = (map["socialProfiles"] as? StructList?).toItemList(),
          dates = (map["dates"] as? StructList?).toItemList(),
          urls = (map["urls"] as? StructList?).toItemList(),
          postalAddresses = (map["postalAddresses"] as? StructList?).toPostalAddressList()
      )

      return contact
    }
  }
}

@RequiresApi(Build.VERSION_CODES.O)
fun String.toDate(): OffsetDateTime = OffsetDateTime.parse(this)
fun MutableList<ContactDate>.toContactDateMap() = map { it.toMap() }
fun MutableList<Item>.toItemMap() = map { it.toMap() }
fun MutableList<PostalAddress>.toAddressMap() = map { it.toMap() }
fun StructList?.toItemList(): MutableList<Item> = this?.map { Item.fromMap(it) }?.toMutableList()
    ?: mutableListOf()

fun StructList?.toContactDateList(): MutableList<ContactDate> = this?.map { ContactDate.fromMap(it) }?.toMutableList()
    ?: mutableListOf()

fun StructList?.toPostalAddressList(): MutableList<PostalAddress> = this
    ?.map { PostalAddress.fromMap(it) }
    ?.toMutableList() ?: mutableListOf()

fun <T> Iterable<T>?.orEmpty() = this ?: emptyList()

fun <T> Map<String, T?>.filterValuesNotNull(): Map<String, T> {
  return toList().filter { (_,v)-> v != null }.map { (k,v)-> k to v!! }.toMap()
}