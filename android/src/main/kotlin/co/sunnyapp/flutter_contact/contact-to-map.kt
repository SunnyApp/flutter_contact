package co.sunnyapp.flutter_contact

fun Contact.toMap() = mutableMapOf(
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
        "dates" to dates.toContactDateMap(),
        "linkedContactIds" to linkedContactIds,
        "postalAddresses" to postalAddresses.toAddressMap()
).filterValuesNotNull()

fun DateComponents.toMap(): Map<String, Int> {
    val result = mutableMapOf<String, Int>()
    if (year != null) result["year"] = year
    if (month != null) result["month"] = month
    if (day != null) result["day"] = day
    return result
}

fun ContactDate.toMap(): Map<String, *> {
    return mutableMapOf(
            "label" to label,
            "value" to value,
            "date" to date?.toMap())
}

fun Item.toMap(): Map<String, String?> {
    return mutableMapOf(
            "label" to label,
            "value" to value)
}

fun PostalAddress.toMap() = mapOf(
        "label" to label,
        "street" to street,
        "city" to city,
        "postcode" to postcode,
        "region" to region,
        "country" to country)

fun MutableList<ContactDate>.toContactDateMap() = map { it.toMap() }
fun MutableList<Item>.toItemMap() = map { it.toMap() }
fun MutableList<PostalAddress>.toAddressMap() = map { it.toMap() }