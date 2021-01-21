package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.database.Cursor
import android.os.Build
import android.provider.ContactsContract
import android.provider.ContactsContract.CommonDataKinds.StructuredPostal
import java.util.*

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
