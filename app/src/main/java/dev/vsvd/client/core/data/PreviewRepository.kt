package dev.vsvd.client.core.data

import dev.vsvd.client.core.model.BadgeScope
import dev.vsvd.client.core.model.ChatPreview
import dev.vsvd.client.core.model.ConnectionStatus
import dev.vsvd.client.core.model.ProfileBadge
import dev.vsvd.client.core.plugins.InstalledPlugin
import dev.vsvd.client.core.plugins.PluginCapability
import dev.vsvd.client.core.plugins.PluginManifest
import dev.vsvd.client.core.plugins.PluginSource
import dev.vsvd.client.core.plugins.PluginStatus

/**
 * Temporary local presentation data. It must be replaced by a TDLib-backed
 * repository; it never represents Telegram account data.
 */
object PreviewRepository {
    val ownerBadges = listOf(
        ProfileBadge(
            id = "founder",
            label = "Основатель",
            icon = "✦",
            backgroundArgb = 0xFF234D79.toInt(),
            textArgb = 0xFFFFFFFF.toInt(),
            scope = BadgeScope.PROFILE,
        ),
        ProfileBadge(
            id = "early",
            label = "Ранний доступ",
            icon = "◆",
            backgroundArgb = 0xFF503E71.toInt(),
            textArgb = 0xFFFFFFFF.toInt(),
            scope = BadgeScope.PROFILE,
        ),
    )

    val chatPreview = listOf(
        ChatPreview(
            id = 1L,
            title = "VSVD: команда",
            lastMessage = "Макет интерфейса готов для подключения TDLib.",
            timestamp = "12:45",
            unreadCount = 2,
            isPinned = true,
            badges = listOf(ownerBadges.first()),
        ),
        ChatPreview(
            id = 2L,
            title = "Плагины",
            lastMessage = "Каталог будет доступен после запуска Control Plane.",
            timestamp = "вчера",
            badges = listOf(ownerBadges.last()),
        ),
    )

    val plugins = listOf(
        InstalledPlugin(
            manifest = PluginManifest(
                id = "vsvd.appearance.night-aurora",
                name = "Night Aurora",
                version = "0.1.0",
                minClientVersion = 1,
                declaredCapabilities = setOf(PluginCapability.THEME),
                publisherKeyId = "vsvd-bundled-1",
                signature = "bundled-preview",
            ),
            enabled = false,
            source = PluginSource.BUNDLED,
            status = PluginStatus.READY,
        ),
        InstalledPlugin(
            manifest = PluginManifest(
                id = "vsvd.tools.reply-actions",
                name = "Reply actions",
                version = "0.1.0",
                minClientVersion = 1,
                declaredCapabilities = setOf(PluginCapability.CHAT_ACTION),
                publisherKeyId = "vsvd-bundled-1",
                signature = "bundled-preview",
            ),
            enabled = false,
            source = PluginSource.BUNDLED,
            status = PluginStatus.READY,
        ),
    )

    const val transportMessage = "Для входа нужен модуль TDLib и собственные api_id/api_hash. " +
        "Ключи не хранятся в репозитории и не проходят через сервер VSVD."

    val initialConnectionStatus = ConnectionStatus.NOT_CONFIGURED
}
