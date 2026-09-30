package dev.vsvd.client

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AccountCircle
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewmodel.CreationExtras
import dev.vsvd.client.core.model.ChatPreview
import dev.vsvd.client.core.model.ClientTab
import dev.vsvd.client.core.model.ConnectionStatus
import dev.vsvd.client.core.model.ProfileBadge
import dev.vsvd.client.core.plugins.InstalledPlugin
import dev.vsvd.client.core.plugins.PluginCapability
import dev.vsvd.client.ui.VsvdUiState
import dev.vsvd.client.ui.VsvdViewModel
import dev.vsvd.client.ui.theme.VsvdTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            VsvdTheme {
                val application = application as VsvdApplication
                val viewModel: VsvdViewModel = viewModel(
                    factory = VsvdViewModelFactory(application.telegramGateway),
                )
                VsvdApp(viewModel)
            }
        }
    }
}

private class VsvdViewModelFactory(
    private val telegramGateway: dev.vsvd.client.core.telegram.TelegramGateway,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T {
        if (modelClass.isAssignableFrom(VsvdViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return VsvdViewModel(telegramGateway) as T
        }
        error("Unknown ViewModel: ${modelClass.name}")
    }
}

@Composable
private fun VsvdApp(viewModel: VsvdViewModel) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    state.notice?.let { message ->
        AlertDialog(
            onDismissRequest = viewModel::dismissNotice,
            icon = { Icon(Icons.Outlined.Lock, contentDescription = null) },
            title = { Text("Безопасное подключение") },
            text = { Text(message) },
            confirmButton = {
                OutlinedButton(onClick = viewModel::dismissNotice) {
                    Text("Понятно")
                }
            },
        )
    }

    Scaffold(
        topBar = { VsvdTopBar() },
        bottomBar = {
            AppNavigation(selected = state.tab, onSelect = viewModel::selectTab)
        },
    ) { padding ->
        when (state.tab) {
            ClientTab.CHATS -> ChatsScreen(
                state = state,
                onConnect = viewModel::requestTelegramConnection,
                modifier = Modifier.padding(padding),
            )
            ClientTab.PLUGINS -> PluginsScreen(
                plugins = state.plugins,
                onToggle = viewModel::togglePlugin,
                modifier = Modifier.padding(padding),
            )
            ClientTab.PROFILE -> ProfileScreen(
                badges = state.badges,
                modifier = Modifier.padding(padding),
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun VsvdTopBar() {
    TopAppBar(
        title = {
            Column {
                Text("VSVD", fontWeight = FontWeight.Black, letterSpacing = MaterialTheme.typography.titleLarge.letterSpacing)
                Text(
                    text = "PRIVATE ANDROID CLIENT",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        },
        actions = {
            AssistChip(
                onClick = {},
                label = { Text("DEV") },
                leadingIcon = {
                    Icon(
                        Icons.Outlined.Security,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                    )
                },
            )
            Spacer(Modifier.width(8.dp))
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface,
        ),
    )
}

@Composable
private fun AppNavigation(selected: ClientTab, onSelect: (ClientTab) -> Unit) {
    NavigationBar {
        NavigationBarItem(
            selected = selected == ClientTab.CHATS,
            onClick = { onSelect(ClientTab.CHATS) },
            icon = { Icon(Icons.Outlined.ChatBubbleOutline, contentDescription = null) },
            label = { Text("Чаты") },
        )
        NavigationBarItem(
            selected = selected == ClientTab.PLUGINS,
            onClick = { onSelect(ClientTab.PLUGINS) },
            icon = { Icon(Icons.Outlined.Extension, contentDescription = null) },
            label = { Text("Плагины") },
        )
        NavigationBarItem(
            selected = selected == ClientTab.PROFILE,
            onClick = { onSelect(ClientTab.PROFILE) },
            icon = { Icon(Icons.Outlined.AccountCircle, contentDescription = null) },
            label = { Text("Профиль") },
        )
    }
}

@Composable
private fun ChatsScreen(
    state: VsvdUiState,
    onConnect: () -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            ConnectionCard(status = state.connection, onConnect = onConnect)
        }
        item {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text("Чаты", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                Spacer(Modifier.width(8.dp))
                PreviewMark()
            }
        }
        items(state.chats, key = { it.id }) { chat ->
            ChatCard(chat)
        }
        item {
            Text(
                "Предпросмотр не содержит настоящих сообщений. После подключения TDLib этот экран будет получать данные напрямую с Telegram на устройстве.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 2.dp, bottom = 16.dp),
            )
        }
    }
}

@Composable
private fun ConnectionCard(status: ConnectionStatus, onConnect: () -> Unit) {
    ElevatedCard(
        colors = CardDefaults.elevatedCardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant,
        ),
    ) {
        Column(Modifier.padding(18.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.18f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(
                        Icons.Outlined.Lock,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary,
                    )
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text("Telegram transport", fontWeight = FontWeight.Bold)
                    Text(
                        connectionText(status),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                StatusDot(status)
            }
            Spacer(Modifier.height(14.dp))
            Text(
                "VSVD не будет передавать чаты, номера телефонов, коды входа или ключи авторизации на свой сервер.",
                style = MaterialTheme.typography.bodySmall,
            )
            Spacer(Modifier.height(14.dp))
            OutlinedButton(onClick = onConnect, modifier = Modifier.fillMaxWidth()) {
                Text("Подготовить вход через Telegram")
            }
        }
    }
}

@Composable
private fun StatusDot(status: ConnectionStatus) {
    val color = when (status) {
        ConnectionStatus.CONNECTED -> Color(0xFF6DD58C)
        ConnectionStatus.FAILED -> MaterialTheme.colorScheme.error
        else -> MaterialTheme.colorScheme.outline
    }
    Box(modifier = Modifier.size(10.dp).clip(CircleShape).background(color))
}

private fun connectionText(status: ConnectionStatus): String = when (status) {
    ConnectionStatus.NOT_CONFIGURED -> "TDLib ещё не подключён"
    ConnectionStatus.WAITING_FOR_PHONE -> "Ожидается номер телефона"
    ConnectionStatus.WAITING_FOR_CODE -> "Ожидается код Telegram"
    ConnectionStatus.CONNECTED -> "Подключено локально"
    ConnectionStatus.FAILED -> "Не удалось подключиться"
}

@Composable
private fun ChatCard(chat: ChatPreview) {
    Surface(
        shape = RoundedCornerShape(18.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 13.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Avatar(chat.title)
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        chat.title,
                        fontWeight = FontWeight.SemiBold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f),
                    )
                    if (chat.isPinned) Text("⌁", color = MaterialTheme.colorScheme.primary)
                }
                Spacer(Modifier.height(3.dp))
                Text(
                    chat.lastMessage,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (chat.badges.isNotEmpty()) {
                    Spacer(Modifier.height(7.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                        chat.badges.forEach { badge -> BadgePill(badge, compact = true) }
                    }
                }
            }
            Spacer(Modifier.width(8.dp))
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    chat.timestamp,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                if (chat.unreadCount > 0) {
                    Spacer(Modifier.height(7.dp))
                    Box(
                        modifier = Modifier
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary)
                            .padding(horizontal = 7.dp, vertical = 2.dp),
                    ) {
                        Text(
                            chat.unreadCount.toString(),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onPrimary,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun Avatar(text: String) {
    val first = text.firstOrNull()?.uppercaseChar()?.toString() ?: "V"
    Box(
        modifier = Modifier
            .size(46.dp)
            .clip(CircleShape)
            .background(MaterialTheme.colorScheme.secondary.copy(alpha = 0.32f)),
        contentAlignment = Alignment.Center,
    ) {
        Text(first, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSecondaryContainer)
    }
}

@Composable
private fun PluginsScreen(
    plugins: List<InstalledPlugin>,
    onToggle: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Text("Плагины", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(4.dp))
            Text(
                "Изолированные расширения VSVD, без загрузки APK и произвольного кода.",
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        item { PluginSecurityCard() }
        items(plugins, key = { it.manifest.id }) { plugin ->
            PluginCard(plugin, onToggle)
        }
        item {
            Text(
                "Каталог, установка из .vsvd-plugin и подписи издателей появятся вместе с Control Plane после запуска Telegram-транспорта.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp),
            )
        }
    }
}

@Composable
private fun PluginSecurityCard() {
    ElevatedCard(
        colors = CardDefaults.elevatedCardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
    ) {
        Row(Modifier.padding(16.dp), verticalAlignment = Alignment.Top) {
            Icon(
                Icons.Outlined.Security,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
            )
            Spacer(Modifier.width(12.dp))
            Column {
                Text("Безопасная модель", fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(3.dp))
                Text(
                    "Каждый пакет будет проверяться подписью, версией и разрешениями. Доступ к TDLib, файлам аккаунта и логину Telegram запрещён всегда.",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }
    }
}

@Composable
private fun PluginCard(plugin: InstalledPlugin, onToggle: (String) -> Unit) {
    Surface(
        shape = RoundedCornerShape(18.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Box(
                    modifier = Modifier
                        .size(42.dp)
                        .clip(RoundedCornerShape(13.dp))
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.Extension, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                }
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Text(plugin.manifest.name, fontWeight = FontWeight.Bold)
                    Text(
                        "v${plugin.manifest.version} · ${plugin.source.name.lowercase()}",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Switch(
                    checked = plugin.enabled,
                    onCheckedChange = { onToggle(plugin.manifest.id) },
                    enabled = plugin.status == dev.vsvd.client.core.plugins.PluginStatus.READY,
                )
            }
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                plugin.manifest.declaredCapabilities.forEach { capability ->
                    CapabilityChip(capability)
                }
            }
        }
    }
}

@Composable
private fun CapabilityChip(capability: PluginCapability) {
    FilterChip(
        selected = false,
        onClick = {},
        label = {
            Text(
                when (capability) {
                    PluginCapability.THEME -> "Тема"
                    PluginCapability.MESSAGE_DECORATION -> "Оформление"
                    PluginCapability.CHAT_ACTION -> "Действия"
                    PluginCapability.LOCAL_AUTOMATION -> "Локально"
                    PluginCapability.NETWORK_REQUEST -> "Сеть"
                },
            )
        },
        enabled = false,
    )
}

@Composable
private fun ProfileScreen(badges: List<ProfileBadge>, modifier: Modifier = Modifier) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 14.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Surface(
                shape = RoundedCornerShape(22.dp),
                color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.65f),
                modifier = Modifier.fillMaxWidth(),
            ) {
                Column(Modifier.padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Avatar("VSVD")
                    Spacer(Modifier.height(10.dp))
                    Text("Ваш профиль", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text(
                        "Локальный предпросмотр",
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodySmall,
                    )
                    Spacer(Modifier.height(14.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        badges.forEach { BadgePill(it) }
                    }
                }
            }
        }
        item {
            Text("Кастомные бейджи", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
            Text(
                "Они будут отображаться в профиле, списках чатов и заголовках сообщений только внутри VSVD.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        items(badges, key = { it.id }) { badge -> BadgeDetailsCard(badge) }
        item { BadgeRulesCard() }
    }
}

@Composable
private fun BadgeDetailsCard(badge: ProfileBadge) {
    Surface(
        shape = RoundedCornerShape(18.dp),
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.55f),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = Modifier
                    .size(42.dp)
                    .clip(RoundedCornerShape(13.dp))
                    .background(Color(badge.backgroundArgb)),
                contentAlignment = Alignment.Center,
            ) {
                Text(badge.icon, color = Color(badge.textArgb), fontWeight = FontWeight.Bold)
            }
            Spacer(Modifier.width(12.dp))
            Column {
                Text(badge.label, fontWeight = FontWeight.Bold)
                Text(
                    "ID: ${badge.id} · выдан вручную",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}

@Composable
private fun BadgeRulesCard() {
    ElevatedCard {
        Column(Modifier.padding(16.dp)) {
            Text("Будущая админка", fontWeight = FontWeight.Bold)
            Spacer(Modifier.height(6.dp))
            Text(
                "После первого Telegram-релиза администратор будет создавать шаблоны, выдавать и отзывать бейджи, видеть журнал действий и управлять ролями. Сервер не сможет читать Telegram-переписку.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun BadgePill(badge: ProfileBadge, compact: Boolean = false) {
    Surface(
        color = Color(badge.backgroundArgb),
        shape = RoundedCornerShape(50),
    ) {
        Text(
            text = if (compact) "${badge.icon} ${badge.label}" else "${badge.icon} ${badge.label}",
            modifier = Modifier.padding(horizontal = if (compact) 7.dp else 9.dp, vertical = 4.dp),
            style = if (compact) MaterialTheme.typography.labelSmall else MaterialTheme.typography.labelMedium,
            color = Color(badge.textArgb),
            maxLines = 1,
        )
    }
}

@Composable
private fun PreviewMark() {
    Surface(
        color = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.15f),
        shape = RoundedCornerShape(50),
    ) {
        Text(
            "ПРЕДПРОСМОТР",
            modifier = Modifier.padding(horizontal = 7.dp, vertical = 3.dp),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.tertiary,
        )
    }
}
