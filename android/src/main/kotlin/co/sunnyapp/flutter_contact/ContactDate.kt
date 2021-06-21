@file:Suppress("UNCHECKED_CAST")

package co.sunnyapp.flutter_contact

import android.annotation.SuppressLint
import org.joda.time.DateTime
import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.*

/**
 * Represents a date that may be missing components, such as year.
 *
 * see parsing options at the bottom of this file
 */
data class DateComponents(val month: Int? = null, val year: Int? = null, val day: Int? = null) {
    override fun toString() = formatted()
    fun formatted() = listOfNotNull(year, month, day).joinToString("-") { "$it".padStart(2, '0') }

    companion object
}

/***
 * Represents a date object.  In android, a date can be typed in by the user arbitrarily, so we
 * attempt to parse out date components, but also provide the original value
 */
data class ContactDate(val label: String?, val value: String, val date: DateComponents?) {
    companion object

    /**
     * Returns the date components value first, followed by the original value
     */
    fun toDateValue() = date?.formatted() ?: value
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

/**
 * Attempts to parse date components, eg:
 * 12-28
 * 2009-12-22
 *
 */
fun DateComponents.Companion.tryParse(input: String): DateComponents? {
    val fromDateTime = try {
        fromDateTime(isoDateParser.parseDateTime(input.trim()))
    } catch (e: Exception) {
        null
    }

    if (fromDateTime != null) return fromDateTime

    val fromParts = try {
        val parts = input.split("-")
                .flatMap { it.split("/") }
                .filter { !it.isBlank() }
                .map { it.trimStart('0') }
                .map { it.toInt() }

        when (parts.size) {
            3 -> DateComponents(year = parts[0], month = parts[1], day = parts[2])
            1 -> DateComponents(year = parts[0])
            2 -> when {
                parts[0] > 1000 -> DateComponents(year = parts[0], month = parts[1])
                else -> DateComponents(month = parts[0], day = parts[1])
            }
            else -> null
        }
    } catch (e: Exception) {
        null
    }

    if (fromParts != null) return fromParts

    return null
}

fun DateComponents.Companion.fromDateTime(date: DateTime): DateComponents {
    return DateComponents(month = date.monthOfYear, year = date.year, day = date.dayOfMonth)
}