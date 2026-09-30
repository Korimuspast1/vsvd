package dev.vsvd.client.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.vsvd.client.core.data.PreviewRepository
import dev.vsvd.client.core.model.ChatPreview
import dev.vsvd.client.core.model.ClientTab
import dev.vsvd.client.core.model.ConnectionStatus
import dev.vsvd.client.core.model.ProfileBadge
import dev.vsvd.client.core.plugins.InstalledPlugin
import dev.vsvd.client.core.plugins.PluginStatus
import dev.vsvd.client.core.telegram.TelegramGateway
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class VsvdUiState(
    val tab: ClientTab = ClientTab.CHATS,
    val connection: ConnectionStatus = ConnectionStatus.NOT_CONFIGURED,
    val chats: List<ChatPreview> = emptyList(),
    val badges: List<ProfileBadge> = emptyList(),
    val plugins: List<InstalledPlugin> = emptyList(),
    val notice: String? = null,
)

class VsvdViewModel(
    private val telegramGateway: TelegramGateway,
) : ViewModel() {
    private val selectedTab = MutableStateFlow(ClientTab.CHATS)
    private val installedPlugins = MutableStateFlow(PreviewRepository.plugins)
    private val notice = MutableStateFlow<String?>(null)

    val state: StateFlow<VsvdUiState> = combine(
        selectedTab,
        telegramGateway.connectionStatus,
        telegramGateway.chats,
        installedPlugins,
        notice,
    ) { tab, connection, chats, plugins, currentNotice ->
        VsvdUiState(
            tab = tab,
            connection = connection,
            chats = chats,
            badges = PreviewRepository.ownerBadges,
            plugins = plugins,
            notice = currentNotice,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = VsvdUiState(
            badges = PreviewRepository.ownerBadges,
            plugins = PreviewRepository.plugins,
        ),
    )

    fun selectTab(tab: ClientTab) {
        selectedTab.value = tab
    }

    fun requestTelegramConnection() {
        viewModelScope.launch {
            telegramGateway.beginAuthorization()
            notice.value = PreviewRepository.transportMessage
        }
    }

    fun togglePlugin(pluginId: String) {
        installedPlugins.value = installedPlugins.value.map { plugin ->
            if (plugin.manifest.id == pluginId && plugin.status == PluginStatus.READY) {
                plugin.copy(enabled = !plugin.enabled)
            } else {
                plugin
            }
        }
    }

    fun dismissNotice() {
        notice.value = null
    }
}
