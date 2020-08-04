package co.sunnyapp.flutter_contact

import android.content.ContentResolver
import android.database.ContentObserver
import android.database.Cursor
import android.net.Uri
import android.os.Handler
import android.provider.ContactsContract
import io.flutter.plugin.common.EventChannel
import java.io.ByteArrayInputStream
import java.io.InputStream


class ContactsContentObserver(private val sink: EventChannel.EventSink, handler: Handler) : ContentObserver(handler) {
    override fun deliverSelfNotifications(): Boolean {
        return true
    }

    override fun onChange(selfChange: Boolean) {
        sink.success(ContactsChangedEvent)
    }

    override fun onChange(selfChange: Boolean, uri: Uri?) {
        val event = when (uri) {
            null -> ContactsChangedEvent
            Uri.parse("content://com.android.contacts") -> ContactsChangedEvent
            ContactsContract.Contacts.CONTENT_URI -> ContactsChangedEvent
            else -> ContactChangedEvent(contactId = uri.lastPathSegment!!)
        }
        sink.success(event.toMap())
    }

    fun close() {
        sink.endOfStream()
    }
}

object ErrorCodes {
    const val FORM_OPERATION_CANCELED = "formOperationCancelled"
    const val FORM_COULD_NOT_BE_OPENED = "formCouldNotBeOpened"
    const val NOT_FOUND = "notFound"
    const val UNKNOWN_ERROR = "unknownError"
    const val INVALID_PARAMETER = "invalidParameter"
}

fun ContentResolver.listAllGroups(): Cursor? {
    return query(ContactsContract.Groups.CONTENT_URI, groupProjections, null, null, null)
}

fun Cursor.toInputStream(): InputStream? {
    return getBlob(0)?.let {
        return ByteArrayInputStream(it)
    }
}

