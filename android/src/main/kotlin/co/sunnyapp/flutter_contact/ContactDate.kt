@file:Suppress("UNCHECKED_CAST")

package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.*

data class DateComponents(val month: Int? = 0, val year: Int? = 0, val day: Int? = 0) {
    companion object {
        fun fromMap(map: Map<String, Int>): DateComponents {
            return DateComponents(month = map["month"], year = map["year"], day = map["day"])
        }
    }
}

/***
 * Represents an object which has a label and a value
 * such as an email or a phone
 */
data class ContactDate(val label: String?, val date: DateComponents) {
    companion object {
        fun fromMap(map: Map<String, *>): ContactDate {
            return ContactDate(map["label"] as? String?, DateComponents.fromMap(map["date"] as Map<String, Int>))
        }
    }
}

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
            "date" to date.toMap())
}


/**
 * We are using the older java7 styles for compat with older phones
 */
@SuppressLint("SimpleDateFormat")
fun Date?.toIsoString(): String? {
    val date = this ?: return null
    val tz: TimeZone = TimeZone.getTimeZone("UTC")
    val df: DateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm'Z'") // Quoted "Z" to indicate UTC, no timezone offset
    df.timeZone = tz
    return df.format(date)
}