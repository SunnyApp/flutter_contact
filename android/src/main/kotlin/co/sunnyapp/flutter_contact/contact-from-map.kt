@file:Suppress("UNCHECKED_CAST")

package co.sunnyapp.flutter_contact

import org.joda.time.format.DateTimeFormatter
import org.joda.time.format.ISODateTimeFormat
import java.util.*

typealias StructList = List<Struct>
typealias Struct = Map<String, Any>


val isoDateParser: DateTimeFormatter = ISODateTimeFormat.dateOptionalTimeParser()
fun String.toDate(): Date = isoDateParser.parseDateTime(this).toDate()
fun String.toDateComponents() = DateComponents.tryParse(this)

fun StructList?.toItemList(): MutableList<Item> = this.orEmpty().map { Item.fromMap(it) }.toMutableList()

fun StructList?.toContactDateList(): MutableList<ContactDate> = this
        .orEmpty()
        .map { ContactDate.fromMap(it) }
        .toMutableList()

fun StructList?.toPostalAddressList(): MutableList<PostalAddress> = this
        .orEmpty()
        .map { PostalAddress.fromMap(it) }
        .toMutableList()

fun Contact.Companion.fromMap(mode: ContactMode, map: Map<String, *>): Contact {
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
            dates = (map["dates"] as? StructList?).toContactDateList(),
            urls = (map["urls"] as? StructList?).toItemList(),
            postalAddresses = (map["postalAddresses"] as? StructList?).toPostalAddressList()
    )

    return contact
}

fun DateComponents.Companion.fromMap(map: Map<String, Int>?): DateComponents? {
    return map?.let {
        DateComponents(month = it["month"], year = it["year"], day = it["day"])
    }
}

fun ContactDate.Companion.fromMap(map: Map<String, *>): ContactDate {
    val date = DateComponents.fromMap(map["date"] as Map<String, Int>)
            ?: map["value"]?.toString()?.toDateComponents()
    return ContactDate(label = map["label"] as? String?,
            date = date,
            value = date?.formatted() ?: map["value"] as? String
            ?: error("Invalid date - must provide either a map of year/month/day as a map, or a key of 'value'"))
}

fun Item.Companion.fromMap(map: Map<String, *>): Item {
    return Item(map["label"] as? String?, map["value"] as? String?)
}

fun PostalAddress.Companion.fromMap(map: Map<String, *>): PostalAddress {
    return PostalAddress(map["label"] as? String?,
            map["street"] as? String?,
            map["city"] as? String?,
            map["postcode"] as? String?,
            map["region"] as? String?,
            map["country"] as? String?)
}