package co.sunnyapp.flutter_contact.tasks

import android.content.ContentResolver
import android.content.ContentUris
import android.graphics.Bitmap
import android.provider.ContactsContract.*
import co.sunnyapp.flutter_contact.Contact
import java.io.ByteArrayOutputStream

interface ContactTask {
    val resolver: ContentResolver

    fun Contact.setAvatarDataForContactIfAvailable(highRes:Boolean) {
        val contact = this;
        val contactUri = ContentUris.withAppendedId(Contacts.CONTENT_URI, contact.identifier!!.value.toLong())
        val input = Contacts.openContactPhotoInputStream(resolver, contactUri, highRes)
        input.use { input ->
            try {
                val bitmap = android.graphics.BitmapFactory.decodeStream(input)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                contact.avatar = stream.toByteArray()
                stream.close()
            } catch (e: Exception) {
                print("Unable to fetch contact image: $e")
            }
        }
    }
}