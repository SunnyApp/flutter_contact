package co.sunnyapp.flutter_contact.tasks

import android.annotation.TargetApi
import android.content.ContentResolver
import android.database.Cursor
import android.os.AsyncTask
import android.os.Build
import android.provider.ContactsContract.Groups
import co.sunnyapp.flutter_contact.Group
import co.sunnyapp.flutter_contact.StructList
import co.sunnyapp.flutter_contact.int
import co.sunnyapp.flutter_contact.string
import co.sunnyapp.flutter_contact.toMap
import io.flutter.plugin.common.MethodChannel

@TargetApi(Build.VERSION_CODES.CUPCAKE)
class GetGroupsTask(private val result: MethodChannel.Result,
                    private val resolver: ContentResolver) : AsyncTask<String, Void, Result<StructList>>() {

    @TargetApi(Build.VERSION_CODES.ECLAIR)
    override fun doInBackground(vararg params: String): Result<StructList> {
        return try {
            Result(resolver.listAllGroups()
                    ?.toGroupList()
                    ?.filter { group -> group.contacts.isNotEmpty() }
                    ?.map { it.toMap() }
                    ?: emptyList())
        } catch (e: Exception) {
            Result("group-load-failed", e)
        }
    }

    override fun onPostExecute(result: Result<StructList>) {
        this.result.send(result)
    }

    private fun ContentResolver.listAllGroups(): Cursor? {
        return query(Groups.CONTENT_URI, groupProjections, null, null, null)
    }

    /**
     * Builds the list of contacts from the cursor
     * @param cursor
     * @return the list of contacts
     */
    private fun Cursor.toGroupList(): List<Group> {
        val groupsById = mutableMapOf<String, Group>()
        val cursor = this
        while (cursor.moveToNext()) {
            val groupId = cursor.string(Groups.SOURCE_ID) ?: continue

            if (groupId !in groupsById) {
                groupsById[groupId] = Group(identifier = groupId)
            }
            val group = groupsById[groupId]!!

            cursor.int(Groups.FAVORITES)?.also { favorite ->
                if (favorite > 0) {
                    group.name = "Favorites"
                }
            }

            cursor.string(Groups.TITLE)?.also { name ->
                group.name = name
            }
        }

        resolver.queryContacts()
                .toContactList()
                .forEach { contact ->
                    for (groupId in contact.groups) {
                        val group = groupsById[groupId] ?: continue
                        contact.identifier?.let { group.contacts += it.value }
                    }
                }
        return groupsById.values.toList()
    }
}

val groupProjections: Array<String> = arrayOf(
        Groups.SOURCE_ID,
        Groups.ACCOUNT_TYPE,
        Groups.ACCOUNT_NAME,
        Groups.DELETED,
        Groups.FAVORITES,
        Groups.TITLE,
        Groups.NOTES)
