package dev.vsvd.client.core.model

/**
 * Data rendered by VSVD is deliberately separate from TDLib classes. It prevents
 * the UI and the plugin runtime from having access to raw Telegram objects.
 */
data class ChatPreview(
    val id: Long,
    val title: String,
    val lastMessage: String,
    val timestamp: String,
    val unreadCount: Int = 0,
    val isPinned: Boolean = false,
    val badges: List<ProfileBadge> = emptyList(),
)

data class ProfileBadge(
    val id: String,
    val label: String,
    val icon: String,
    /** Android packed ARGB color, matching Color(Int). */
    val backgroundArgb: Int,
    val textArgb: Int,
    val scope: BadgeScope,
    val validUntilEpochMillis: Long? = null,
)

enum class BadgeScope {
    PROFILE,
    CHAT_LIST,
    MESSAGE_HEADER,
}

enum class ConnectionStatus {
    NOT_CONFIGURED,
    WAITING_FOR_PHONE,
    WAITING_FOR_CODE,
    CONNECTED,
    FAILED,
}

enum class ClientTab {
    CHATS,
    PLUGINS,
    PROFILE,
}
