package co.sunnyapp.flutter_contact

data class Group(
    val identifier: String,
    var name: String? = null,
    var description: String? = null,
    val contacts: MutableSet<String> = linkedSetOf())


fun Group.toMap() = mapOf(
    "identifier" to identifier,
    "description" to description,
    "name" to name,
    "contacts" to contacts.toList())