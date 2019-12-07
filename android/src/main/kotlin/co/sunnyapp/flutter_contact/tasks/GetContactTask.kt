package co.sunnyapp.flutter_contact.tasks

import android.annotation.TargetApi
import android.content.ContentResolver
import android.os.AsyncTask
import android.os.Build
import co.sunnyapp.flutter_contact.ContactId
import co.sunnyapp.flutter_contact.Struct
import io.flutter.plugin.common.MethodChannel

@TargetApi(Build.VERSION_CODES.CUPCAKE)
class GetContactTask(private val getContactResult: MethodChannel.Result,
                     override val resolver: ContentResolver,
                     private val withThumbnails: Boolean,
                     private val highResolutionPhoto: Boolean) : AsyncTask<ContactId, Void, Result<Struct>>(), ContactTask {

    @TargetApi(Build.VERSION_CODES.ECLAIR)
    override fun doInBackground(vararg identifier: ContactId): Result<Struct> = try {
        val contactList = resolver.findContactById(identifier.first().value)?.toContactList()
        val contact = contactList
                ?.singleOrNull()
                ?: error("Expected a single result for contact ${identifier.first()}, " +
                        "but instead found ${contactList?.size ?: 0}")

        if (withThumbnails) contact.setAvatarDataForContactIfAvailable(highResolutionPhoto)
        Result(contact.toMap())
    } catch (e: Exception) {
        Result("contact-load-failed", e)
    }

    override fun onPostExecute(result: Result<Struct>) {
        getContactResult.send(result)
    }
}
