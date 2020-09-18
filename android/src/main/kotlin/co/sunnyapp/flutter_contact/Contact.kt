@file:Suppress("ArrayInDataClass", "UNCHECKED_CAST", "EXPERIMENTAL_FEATURE_WARNING", "UnnecessaryVariable")

package co.sunnyapp.flutter_contact

import android.content.ContentUris
import android.net.Uri
import android.provider.ContactsContract
import co.sunnyapp.flutter_contact.ContactMode.*
import org.joda.time.format.DateTimeFormat
import org.joda.time.format.DateTimeFormatter
import java.util.Date
import java.util.LinkedHashSet

typealias StructList = List<Struct>
typealias Struct = Map<String, Any>

data class ContactId(val value: String) {
    fun toUri(): Uri {
        return ContentUris.withAppendedId(ContactsContract.Contacts.CONTENT_URI, value.toLong())
    }

    override fun toString(): String = value
}

fun contactKeyOf(mode: ContactMode, value: Any?): ContactKeys? {
    return when (value) {
        is String -> ContactKeys(mode = mode, identifier = value.toLong())
        is Number -> ContactKeys(mode = mode, identifier = value.toLong())
        is Map<*, *> -> {
            var keys = ContactKeys(mode = mode)
            value.forEach { (name, key) ->
                when (name) {
                    "id", "identifier" -> keys = keys.withIdentifier(key.toLongOrNull())
                    "lookupKey" -> keys = keys.copy(lookupKey = key?.toString())
                    "singleContactId" -> keys = keys.copy(singleContactId = key.toLongOrNull())
                    "unifiedContactId" -> keys = keys.copy(unifiedContactId = key.toLongOrNull())
                    else -> {
                        // Ignored
                    }
                }
            }
            keys.checkValid()
        }
        else -> null
    }
}


data class ContactKeys(
        val mode: ContactMode,
        val unifiedContactId: Long? = null,
        val singleContactId: Long? = null,
        val lookupKey: String? = null) {

    constructor(mode: ContactMode, identifier: Long) : this(
            mode = mode,
            unifiedContactId = if (mode == UNIFIED) identifier else null,
            singleContactId = if (mode == SINGLE) identifier else null)

    private val keyList = listOf(unifiedContactId, singleContactId, lookupKey)

    val contactUri: Uri get() = ContentUris.withAppendedId(mode.contentUri, identifier!!)
    val photoUri: Uri get() = Uri.withAppendedPath(contactUri, mode.photoRef)

    val identifier
        get() = when (mode) {
            SINGLE -> singleContactId
            UNIFIED -> unifiedContactId
        }

    fun withIdentifier(identifier: Any?): ContactKeys {
        return when (mode) {
            SINGLE -> copy(singleContactId = identifier.toLongOrNull())
            UNIFIED -> copy(unifiedContactId = identifier.toLongOrNull())
        }
    }

    fun checkValid(): ContactKeys? {
        return when {
            keyList.filterNotNull().isEmpty() -> null
            else -> this
        }
    }

    fun toQuery(): String {
        val clauses = LinkedHashSet<String>()
        identifier?.let { clauses += "${mode.contactIdRef} = ?" }
        lookupKey?.let { clauses += "${ContactsContract.Contacts.LOOKUP_KEY} = ?" }
        return clauses.joinToString(" OR ")
    }

    val params get() = arrayOf(identifier?.toString(), lookupKey)
            .filterNotNull()
            .toTypedArray()

    companion object {
        fun empty(mode: ContactMode) = ContactKeys(mode)
    }
}

data class Contact(
        var keys: ContactKeys? = null,
        var displayName: String? = null,
        var givenName: String? = null,
        var middleName: String? = null,
        var familyName: String? = null,
        var prefix: String? = null,
        var suffix: String? = null,
        var company: String? = null,
        var jobTitle: String? = null,
        var lastModified: Date? = null,
        var note: String? = null,
        val emails: MutableList<Item> = mutableListOf(),
        val groups: MutableSet<String> = linkedSetOf(),
        val phones: MutableList<Item> = mutableListOf(),
        val socialProfiles: MutableList<Item> = mutableListOf(),
        val urls: MutableList<Item> = mutableListOf(),
        val dates: MutableList<Item> = mutableListOf(),

        val postalAddresses: MutableList<PostalAddress> = mutableListOf(),
        /// read-only
        val linkedContactIds: MutableList<String> = mutableListOf(),

        var avatar: ByteArray? = null
) {

    constructor(mode: ContactMode, identifier: String) : this(
            keys = ContactKeys(
                    mode = mode,
                    identifier = identifier.toLong()))

    var identifier: Long?
        get() = keys?.identifier
        set(value) {
            keys = keys!!.withIdentifier(value)
        }

    var unifiedContactId: Long?
        get() = keys?.unifiedContactId
        set(value) {
            keys = keys!!.copy(unifiedContactId = value)
        }


    var singleContactId: Long?
        get() = keys?.singleContactId
        set(value) {
            if(value != null && keys?.mode == UNIFIED) {
                if("$value" !in linkedContactIds) {
                    linkedContactIds += "$value"
                }
            }
            keys = keys!!.copy(singleContactId = value)
        }

    var lookupKey: String?
        get() = keys?.lookupKey
        set(value) {
            keys = keys!!.copy(lookupKey = value)
        }


    fun toMap() = mutableMapOf(
            "identifier" to identifier?.toString(),
            "displayName" to displayName,
            "givenName" to givenName,
            "middleName" to middleName,
            "familyName" to familyName,
            "prefix" to prefix,
            "suffix" to suffix,
            "company" to company,
            "jobTitle" to jobTitle,
            "lastModified" to lastModified?.toIsoString(),
            "avatar" to avatar,
            "note" to note,
            "phones" to phones.toItemMap(),
            "emails" to emails.toItemMap(),
            "groups" to groups.toList(),
            "unifiedContactId" to unifiedContactId?.toString(),
            "singleContactId" to singleContactId?.toString(),
            "otherKeys" to mapOf("lookupKey" to keys?.lookupKey).filterValuesNotNull(),
            "socialProfiles" to socialProfiles.toItemMap(),
            "urls" to urls.toItemMap(),
            "dates" to dates.toItemMap(),
            "linkedContactIds" to linkedContactIds,
            "postalAddresses" to postalAddresses.toAddressMap()
    ).filterValuesNotNull()

    companion object {

        fun fromMap(mode: ContactMode, map: Map<String, *>): Contact {
            val contact = Contact(
                    keys = contactKeyOf(mode = mode,
                            value = mapOf(
                                    "unifiedContactId" to map["unifiedContactId"],
                                    "singleContactId" to map["singleContactId"],
                                    "lookupKey" to (map["otherKeys"].orEmptyMap()["lookupKey"] as String?),
                                    "identifier" to map["identifier"])),

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
                    linkedContactIds = map["linkedContactIds"].orEmptyList<String>().toMutableList(),
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

fun Any?.toLongOrNull(): Long? = when (this) {
    is Number -> this.toLong()
    is String -> this.toLong()
    else -> null
}

fun <E> Any?.orEmptyList(): List<E> = this as? List<E> ?: emptyList()
fun Any?.orEmptyMap(): Map<String, Any?> = this as? Map<String, Any?> ?: emptyMap()

val isoDateParser: DateTimeFormatter = DateTimeFormat.fullDateTime()
fun String.toDate(): Date = isoDateParser.parseDateTime(this).toDate()
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
    return toList().filter { (_, v) -> v != null }.map { (k, v) -> k to v!! }.toMap()
}
