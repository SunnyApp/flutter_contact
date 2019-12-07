package co.sunnyapp.flutter_contact

sealed class ContactEvent {
    abstract fun toMap(): Struct
}

data class ContactChangedEvent(val contactId: String) : ContactEvent() {
    override fun toMap(): Struct {
        return mapOf("event" to "contact-changed",
                "contactId" to contactId)
    }
}

object ContactsChangedEvent : ContactEvent() {
    override fun toMap(): Struct {
        return mapOf("event" to "contacts-changed")
    }
}