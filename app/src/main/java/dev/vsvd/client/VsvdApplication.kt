package dev.vsvd.client

import android.app.Application
import dev.vsvd.client.core.telegram.PreviewTelegramGateway
import dev.vsvd.client.core.telegram.TelegramGateway

class VsvdApplication : Application() {
    /** Swap the preview gateway for TdlibTelegramGateway through DI at release time. */
    val telegramGateway: TelegramGateway by lazy { PreviewTelegramGateway() }
}
