package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.database.Cursor
import android.os.Build
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal

@TargetApi(Build.VERSION_CODES.ECLAIR)
data class PostalAddress(
        val label: String? = null,
        val street: String? = null,
        val city: String? = null,
        val postcode: String? = null,
        val region: String? = null,
        val country: String? = null) {

    constructor(cursor: Cursor) : this(
            label = cursor.getAddressLabel(),
            street = cursor.string(StructuredPostal.STREET),
            city = cursor.string(StructuredPostal.CITY),
            postcode = cursor.string(StructuredPostal.POSTCODE),
            region = cursor.string(StructuredPostal.REGION),
            country = cursor.string(StructuredPostal.COUNTRY)
    )

    companion object {

        fun fromMap(map: Map<String, *>): PostalAddress {
            return PostalAddress(map["label"] as? String?,
                    map["street"] as? String?,
                    map["city"] as? String?,
                    map["postcode"] as? String?,
                    map["region"] as? String?,
                    map["country"] as? String?)
        }
    }
}

fun String?.toEventType(): Int {
    val label = this;

    if (label != null) {
        return when (label) {
            "birthday" -> ContactsContract.CommonDataKinds.Event.TYPE_BIRTHDAY
            "anniversary" -> ContactsContract.CommonDataKinds.Event.TYPE_ANNIVERSARY
            else -> ContactsContract.CommonDataKinds.Event.TYPE_OTHER
        }
    }
    return ContactsContract.CommonDataKinds.Event.TYPE_OTHER

}



fun String?.toPostalAddressType(): Int {
    val label = this;
    if (label != null) {
        return when (label) {
            "home" -> StructuredPostal.TYPE_HOME
            "work" -> StructuredPostal.TYPE_WORK
            else -> StructuredPostal.TYPE_OTHER
        }
    }
    return StructuredPostal.TYPE_OTHER
}

fun Cursor.string(index: String): String? {
    return getString(getColumnIndex(index))
}

fun Cursor.long(index: String): Long? {
    return getLong(getColumnIndex(index))
}

fun Cursor.int(index: String): Int? {
    return getInt(getColumnIndex(index))
}

fun Cursor.getLabel(): String {
    val cursor = this;
    when (cursor.getInt(cursor.getColumnIndex(StructuredPostal.TYPE))) {
        StructuredPostal.TYPE_HOME -> return "home"
        StructuredPostal.TYPE_WORK -> return "work"
        StructuredPostal.TYPE_CUSTOM -> {
            val label = cursor.getString(cursor.getColumnIndex(StructuredPostal.LABEL))
            return label ?: ""
        }
    }
    return "other"
}

fun PostalAddress.toMap() = mapOf(
        "label" to label,
        "street" to street,
        "city" to city,
        "postcode" to postcode,
        "region" to region,
        "country" to country)

@SuppressLint("DefaultLocale")
fun String?.toUrlType(): Int {
    val label = this;

    if (label != null) {
        return when (label.toLowerCase()) {
            "work" -> ContactsContract.CommonDataKinds.Website.TYPE_WORK
            "blog" -> ContactsContract.CommonDataKinds.Website.TYPE_BLOG
            "home" -> ContactsContract.CommonDataKinds.Website.TYPE_HOME
            "website" -> ContactsContract.CommonDataKinds.Website.TYPE_HOMEPAGE
            "homepage" -> ContactsContract.CommonDataKinds.Website.TYPE_HOMEPAGE
            "ftp" -> ContactsContract.CommonDataKinds.Website.TYPE_FTP
            "profile" -> ContactsContract.CommonDataKinds.Website.TYPE_PROFILE
            else -> ContactsContract.CommonDataKinds.Website.TYPE_OTHER
        }
    }
    return ContactsContract.CommonDataKinds.Event.TYPE_OTHER

}