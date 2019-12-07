package co.sunnyapp.flutter_contact.tasks

import android.annotation.TargetApi
import android.content.ContentResolver
import android.os.AsyncTask
import android.os.Build
import co.sunnyapp.flutter_contact.StructList
import io.flutter.plugin.common.MethodChannel

@TargetApi(Build.VERSION_CODES.CUPCAKE)
class GetContactsTask(private val getContactResult: MethodChannel.Result,
                      override val resolver: ContentResolver,
                      private val withThumbnails: Boolean,
                      private val photoHighResolution: Boolean) : ContactTask, AsyncTask<String, Void, Result<StructList>>() {

    @TargetApi(Build.VERSION_CODES.ECLAIR)
    override fun doInBackground(vararg query: String): Result<StructList> {
        return try {
            val contacts = resolver.queryContacts(query.firstOrNull())
                    ?.toContactList()
                    ?.onEach { contact ->
                        if (withThumbnails) {
                            contact.setAvatarDataForContactIfAvailable(photoHighResolution)
                        }
                    } ?: emptyList()

            //Transform the list of contacts to a list of Map
            Result(contacts.map { it.toMap() })
        } catch (e: Exception) {
            Result("contact-load-failed", e)
        }
    }

    override fun onPostExecute(result: Result<StructList>) {
        getContactResult.send(result)
    }
}

