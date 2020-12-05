@file:Suppress("MoveVariableDeclarationIntoWhen")

package co.sunnyapp.flutter_contact

import android.database.Cursor
import android.location.Address
import android.provider.ContactsContract.CommonDataKinds.*

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 */
data class Item(val label: String?, val value: String?) {

  companion object {



    fun stringToPhoneType(label: String?): Int {
      if (label != null) {
        return when (label) {
          "home" -> Phone.TYPE_HOME
          "work" -> Phone.TYPE_WORK
          "mobile" -> Phone.TYPE_MOBILE
          "fax work" -> Phone.TYPE_FAX_WORK
          "fax home" -> Phone.TYPE_FAX_HOME
          "main" -> Phone.TYPE_MAIN
          "company" -> Phone.TYPE_COMPANY_MAIN
          "pager" -> Phone.TYPE_PAGER
          else -> Phone.TYPE_OTHER
        }
      }
      return Phone.TYPE_OTHER
    }

    fun stringToEmailType(label: String?): Int {
      if (label != null) {
        return when (label) {
          "home" -> Email.TYPE_HOME
          "work" -> Email.TYPE_WORK
          "mobile" -> Email.TYPE_MOBILE
          else -> Email.TYPE_OTHER
        }
      }
      return Email.TYPE_OTHER
    }
  }
}

fun Cursor.getPhoneLabel(): String {
  val type = getInt(getColumnIndex(Phone.TYPE))
  return when (type) {
    Phone.TYPE_HOME -> "home"
    Phone.TYPE_WORK -> "work"
    Phone.TYPE_MOBILE -> "mobile"
    Phone.TYPE_FAX_WORK -> "fax work"
    Phone.TYPE_FAX_HOME -> "fax home"
    Phone.TYPE_MAIN -> "main"
    Phone.TYPE_COMPANY_MAIN -> "company"
    Phone.TYPE_PAGER -> "pager"
    else -> string(Phone.LABEL)?.toLowerCase() ?: "other"
  }
}

fun Cursor.getEmailLabel(): String {
  val type = getInt(getColumnIndex(Email.TYPE))

  return when (type) {
    Email.TYPE_HOME -> "home"
    Email.TYPE_WORK -> "work"
    Email.TYPE_MOBILE -> "mobile"
    else -> string(Email.LABEL)?.toLowerCase() ?: "other"
  }
}

fun Cursor.getAddressLabel(): String {
  val type = getInt(getColumnIndex(StructuredPostal.TYPE))

  return when (type) {
    StructuredPostal.TYPE_HOME -> "home"
    StructuredPostal.TYPE_WORK -> "work"
    else -> string(StructuredPostal.LABEL)?.toLowerCase() ?: "other"
  }
}

fun Cursor.getEventLabel(): String? {
  val type = getInt(getColumnIndex(Event.TYPE))
  return when (type) {
    Event.TYPE_ANNIVERSARY -> "anniversary"
    Event.TYPE_BIRTHDAY -> "birthday"
    else -> string(Event.LABEL)?.toLowerCase() ?: "other"
  }
}

fun Cursor.getWebsiteLabel(): String? {
  val type = getInt(getColumnIndex(Website.TYPE))
  return when (type) {
    Website.TYPE_BLOG -> "blog"
    Website.TYPE_FTP -> "ftp"
    Website.TYPE_HOME -> "home"
    Website.TYPE_HOMEPAGE -> "homepage"
    Website.TYPE_PROFILE -> "profile"
    Website.TYPE_WORK -> "work"
    else -> string(Website.LABEL)?.toLowerCase() ?: "other"
  }
}