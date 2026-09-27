extends Node

func register_signal(data: SignalData) -> void:
    SignalDatabase.register_signal(data)

func register_item(data: ItemData) -> void:
    if data:
        ResourceSaver.save(data, "user://mods_registered/item_%s.tres" % data.id)

func register_email(data: EmailData) -> void:
    if data and data.id != "":
        EmailManager.emails[data.id] = data

func register_upgrade(data: UpgradeData) -> void:
    if data:
        ResourceSaver.save(data, "user://mods_registered/upgrade_%s.tres" % data.id)

func register_achievement(data: AchievementData) -> void:
    if data and data.id != "":
        AchievementManager.achievements[data.id] = data
