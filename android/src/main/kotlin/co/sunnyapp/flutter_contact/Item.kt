@file:Suppress("MoveVariableDeclarationIntoWhen")
@file:SuppressLint("DefaultLocale")

package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import android.content.ContentProviderOperation
import android.database.Cursor
import android.provider.ContactsContract.CommonDataKinds.*

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 */
data class Item(val label: String?, val value: String?) {
    companion object
}


sealed class ItemType(val otherType: Int, val labelField: String, val typeField: String) {
    abstract fun calculateTypeInt(type: String?): Int
    abstract fun calculateTypeValue(type: Int): String?
    fun getTypeValue(cursor: Cursor): String {
        val type = cursor.getInt(cursor.getColumnIndex(typeField))
        val fromTypeInt = if (type == otherType) null else calculateTypeValue(type)
        val fromLabelField = cursor.string(labelField)
        return fromTypeInt ?: fromLabelField?.toLowerCase() ?: "other"
    }

    companion object {
        val email = EmailType()
        val event = EventType()
        val url = UrlType()
        val address = AddressType()
        val phone = PhoneType()
    }
}

class EmailType : ItemType(otherType = Email.TYPE_CUSTOM, labelField = Email.LABEL, typeField = Email.TYPE) {
    override fun calculateTypeInt(type: String?): Int {
        return when (type?.toLowerCase()) {
            "home" -> Email.TYPE_HOME
            "work" -> Email.TYPE_WORK
            "mobile" -> Email.TYPE_MOBILE
            else -> Email.TYPE_CUSTOM
        }
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        Email.TYPE_HOME -> "home"
        Email.TYPE_WORK -> "work"
        Email.TYPE_MOBILE -> "mobile"
        else -> null
    }
}

class PhoneType : ItemType(otherType = Phone.TYPE_CUSTOM, labelField = Phone.LABEL, typeField = Phone.TYPE) {
    override fun calculateTypeInt(type: String?) = when (type?.toLowerCase()) {
        "home" -> Phone.TYPE_HOME
        "work" -> Phone.TYPE_WORK
        "mobile" -> Phone.TYPE_MOBILE
        "fax work" -> Phone.TYPE_FAX_WORK
        "fax home" -> Phone.TYPE_FAX_HOME
        "main" -> Phone.TYPE_MAIN
        "company" -> Phone.TYPE_COMPANY_MAIN
        "pager" -> Phone.TYPE_PAGER
        else -> Phone.TYPE_CUSTOM
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        Phone.TYPE_HOME -> "home"
        Phone.TYPE_WORK -> "work"
        Phone.TYPE_MOBILE -> "mobile"
        Phone.TYPE_FAX_WORK -> "fax work"
        Phone.TYPE_FAX_HOME -> "fax home"
        Phone.TYPE_MAIN -> "main"
        Phone.TYPE_COMPANY_MAIN -> "company"
        Phone.TYPE_PAGER -> "pager"
        else -> null
    }
}

class UrlType : ItemType(otherType = Website.TYPE_CUSTOM, labelField = Website.LABEL, typeField = Website.TYPE) {
    override fun calculateTypeInt(type: String?) = when (type?.toLowerCase()) {
        "work" -> Website.TYPE_WORK
        "blog" -> Website.TYPE_BLOG
        "home" -> Website.TYPE_HOME
        "website" -> Website.TYPE_HOMEPAGE
        "homepage" -> Website.TYPE_HOMEPAGE
        "ftp" -> Website.TYPE_FTP
        "profile" -> Website.TYPE_PROFILE
        else -> Website.TYPE_CUSTOM
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        Website.TYPE_BLOG -> "blog"
        Website.TYPE_FTP -> "ftp"
        Website.TYPE_HOME -> "home"
        Website.TYPE_HOMEPAGE -> "homepage"
        Website.TYPE_PROFILE -> "profile"
        Website.TYPE_WORK -> "work"
        else -> null
    }

}

class EventType : ItemType(otherType = Event.TYPE_CUSTOM, labelField = Event.LABEL, typeField = Event.TYPE) {
    override fun calculateTypeInt(type: String?) = when (type?.toLowerCase()) {
        "anniversary" -> Event.TYPE_ANNIVERSARY
        "birthday" -> Event.TYPE_ANNIVERSARY
        else -> Event.TYPE_CUSTOM
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        Event.TYPE_ANNIVERSARY -> "anniversary"
        Event.TYPE_BIRTHDAY -> "birthday"
        else -> null
    }
}

class AddressType : ItemType(otherType = StructuredPostal.TYPE_CUSTOM, labelField = StructuredPostal.LABEL, typeField = StructuredPostal.TYPE) {
    override fun calculateTypeInt(type: String?) = when (type?.toLowerCase()) {
        "home" -> StructuredPostal.TYPE_HOME
        "work" -> StructuredPostal.TYPE_WORK
        else -> StructuredPostal.TYPE_CUSTOM
    }

    override fun calculateTypeValue(type: Int) = when (type) {
        StructuredPostal.TYPE_HOME -> "home"
        StructuredPostal.TYPE_WORK -> "work"
        else -> null
    }
}

fun ContentProviderOperation.Builder.withTypeAndLabel(type: ItemType, labelString: String?): ContentProviderOperation.Builder {
    val label = labelString ?: return this
    return when (val typeInt = type.calculateTypeInt(label)) {
        type.otherType -> withValue(type.typeField, typeInt)
                .withValue(type.labelField, label)
        else -> withValue(type.typeField, typeInt)
    }
}

fun Cursor.getPhoneLabel() = ItemType.phone.getTypeValue(this)
fun Cursor.getEmailLabel() = ItemType.email.getTypeValue(this)
fun Cursor.getEventLabel() = ItemType.event.getTypeValue(this)
fun Cursor.getUrlLabel() = ItemType.url.getTypeValue(this)
fun Cursor.getAddressLabel() = ItemType.address.getTypeValue(this)