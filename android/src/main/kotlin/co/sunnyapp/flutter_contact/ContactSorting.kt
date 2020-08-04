package co.sunnyapp.flutter_contact

import android.provider.ContactsContract

data class ContactSortOrder(val name: String, val expression: String)

/// Helps resolve the mappings of options available for sorting
object ContactSorting {
    val firstName = ContactSortOrder("firstName", "UPPER(${ContactsContract.Contacts.DISPLAY_NAME}) ASC")
    val lastName = ContactSortOrder("lastName", "UPPER(${ContactsContract.CommonDataKinds.StructuredName.FAMILY_NAME}) ASC")
    val displayName = ContactSortOrder("displayName", "UPPER(${ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME_PRIMARY}) ASC")
    val defaultSort = firstName
    private val ordering = mapOf(
            firstName.name to firstName,
            lastName.name to lastName,
            displayName.name to displayName
    )

    operator fun get(name: Any?): ContactSortOrder {
        return ordering[name?.toString()] ?: defaultSort
    }
}