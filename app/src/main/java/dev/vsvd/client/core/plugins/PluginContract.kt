package dev.vsvd.client.core.plugins

/**
 * VSVD plugins are data packages interpreted by a restricted runtime, not Android
 * APKs and not arbitrary JVM/Dex code. This keeps a plugin from impersonating the
 * Telegram transport or reading a user's local account database.
 */
data class PluginManifest(
    val id: String,
    val name: String,
    val version: String,
    val minClientVersion: Int,
    val declaredCapabilities: Set<PluginCapability>,
    val publisherKeyId: String,
    val signature: String,
)

enum class PluginCapability {
    THEME,
    MESSAGE_DECORATION,
    CHAT_ACTION,
    LOCAL_AUTOMATION,
    NETWORK_REQUEST,
}

data class InstalledPlugin(
    val manifest: PluginManifest,
    val enabled: Boolean,
    val source: PluginSource,
    val status: PluginStatus,
)

enum class PluginSource { BUNDLED, LOCAL_FILE, VERIFIED_CATALOG }
enum class PluginStatus { READY, DISABLED, NEEDS_UPDATE, BLOCKED }

sealed interface PluginValidation {
    data object Accepted : PluginValidation
    data class Rejected(val reason: String) : PluginValidation
}

/**
 * Pure validation domain rule. Package extraction and Ed25519 checking happen in
 * the infrastructure module once the catalog service is introduced.
 */
class PluginPolicy(
    private val clientVersionCode: Int,
    private val permittedCapabilities: Set<PluginCapability>,
    private val trustedPublisherKeys: Set<String>,
) {
    fun validate(manifest: PluginManifest): PluginValidation = when {
        !ID_PATTERN.matches(manifest.id) -> PluginValidation.Rejected("Некорректный ID плагина")
        manifest.version.isBlank() -> PluginValidation.Rejected("Не указана версия плагина")
        manifest.minClientVersion > clientVersionCode -> PluginValidation.Rejected("Нужна более новая версия VSVD")
        manifest.publisherKeyId !in trustedPublisherKeys -> PluginValidation.Rejected("Издатель не доверен")
        !permittedCapabilities.containsAll(manifest.declaredCapabilities) -> {
            PluginValidation.Rejected("Запрошены запрещённые разрешения")
        }
        manifest.signature.isBlank() -> PluginValidation.Rejected("Нет подписи пакета")
        else -> PluginValidation.Accepted
    }

    private companion object {
        val ID_PATTERN = Regex("[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*")
    }
}
