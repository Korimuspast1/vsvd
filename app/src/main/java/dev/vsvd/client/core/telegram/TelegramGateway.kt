package dev.vsvd.client.core.telegram

import dev.vsvd.client.core.model.ChatPreview
import dev.vsvd.client.core.model.ConnectionStatus
import kotlinx.coroutines.flow.StateFlow

/**
 * Boundary between the app and Telegram. The production implementation will use
 * TDLib locally on the device. VSVD's future Control Plane must not proxy chats,
 * messages, phone numbers, login codes, or auth keys.
 */
interface TelegramGateway {
    val connectionStatus: StateFlow<ConnectionStatus>
    val chats: StateFlow<List<ChatPreview>>

    suspend fun beginAuthorization()
    suspend fun submitPhone(phone: String)
    suspend fun submitCode(code: String)
    suspend fun logOut()
}
