extends Node

signal email_received(id: String)
signal email_read(id: String)

const EMAIL_DIR := "res://resources/emails/emails"
var emails: Dictionary = {}
var delivered: Array[String] = []
var read: Array[String] = []
var deleted: Array[String] = []

func _ready() -> void:
    load_emails()
    refresh_due_emails()

func load_emails() -> void:
    emails.clear()
    var d := DirAccess.open(EMAIL_DIR)
    if d == null:
        return
    d.list_dir_begin()
    var f := d.get_next()
    while f != "":
        if f.ends_with(".tres"):
            var e := load("%s/%s" % [EMAIL_DIR, f]) as EmailData
            if e and e.id != "":
                emails[e.id] = e
        f = d.get_next()
    d.list_dir_end()

func refresh_due_emails() -> void:
    for e: EmailData in emails.values():
        if e.id in delivered or e.id in deleted:
            continue
        if e.is_due(GameStateManager.current_day, GameStateManager.minute_of_day):
            delivered.append(e.id)
            email_received.emit(e.id)
            if UIManager:
                UIManager.show_notification("New email: %s" % e.subject, "info")

func get_email(id: String) -> EmailData:
    return emails.get(id, null)

func get_inbox(include_deleted: bool = false) -> Array[EmailData]:
    var out: Array[EmailData] = []
    for id in delivered:
        if (not include_deleted) and id in deleted:
            continue
        var e := get_email(id)
        if e:
            out.append(e)
    out.sort_custom(func(a: EmailData, b: EmailData) -> bool:
        return a.delivery_day > b.delivery_day or (a.delivery_day == b.delivery_day and a.delivery_minute > b.delivery_minute)
    )
    return out

func mark_as_read(id: String) -> void:
    if not id in read:
        read.append(id)
        email_read.emit(id)

func unread_count() -> int:
    var c := 0
    for id in delivered:
        if not id in read and not id in deleted:
            c += 1
    return c

func to_dict() -> Dictionary:
    return {"delivered": delivered, "read": read, "deleted": deleted}

func from_dict(data: Dictionary) -> void:
    delivered = data.get("delivered", []).duplicate()
    read = data.get("read", []).duplicate()
    deleted = data.get("deleted", []).duplicate()
