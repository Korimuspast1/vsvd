package dev.vsvd.client.core.telegram

import dev.vsvd.client.core.data.PreviewRepository
import dev.vsvd.client.core.model.ChatPreview
import dev.vsvd.client.core.model.ConnectionStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Keeps the app buildable until the native TDLib artifact is deliberately added.
 * It never sends any value to Telegram and never pretends that sample chats are
 * a live account. See docs/TDLIB_INTEGRATION.md.
 */
class PreviewTelegramGateway : TelegramGateway {
    private val mutableStatus = MutableStateFlow(PreviewRepository.initialConnectionStatus)
    private val mutableChats = MutableStateFlow(PreviewRepository.chatPreview)

    override val connectionStatus: StateFlow<ConnectionStatus> = mutableStatus.asStateFlow()
    override val chats: StateFlow<List<ChatPreview>> = mutableChats.asStateFlow()

    override suspend fun beginAuthorization() {
        mutableStatus.value = ConnectionStatus.NOT_CONFIGURED
    }

    override suspend fun submitPhone(phone: String) = Unit

    override suspend fun submitCode(code: String) = Unit

    override suspend fun logOut() {
        mutableStatus.value = ConnectionStatus.NOT_CONFIGURED
    }
}
