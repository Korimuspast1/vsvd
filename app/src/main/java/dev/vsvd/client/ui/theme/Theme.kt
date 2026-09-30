package dev.vsvd.client.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val NightColors = darkColorScheme(
    primary = Color(0xFF86D3FF),
    onPrimary = Color(0xFF00354D),
    secondary = Color(0xFFB8C8FF),
    onSecondary = Color(0xFF20305F),
    tertiary = Color(0xFFFFB8D1),
    background = Color(0xFF0E1116),
    onBackground = Color(0xFFE1E7EF),
    surface = Color(0xFF151A21),
    onSurface = Color(0xFFE1E7EF),
    surfaceVariant = Color(0xFF222B35),
    onSurfaceVariant = Color(0xFFC1CAD5),
    outline = Color(0xFF89939E),
    error = Color(0xFFFFB4AB),
)

private val DayColors = lightColorScheme(
    primary = Color(0xFF00658E),
    onPrimary = Color.White,
    secondary = Color(0xFF4E5F92),
    tertiary = Color(0xFF8D2C55),
    background = Color(0xFFF9F9FC),
    onBackground = Color(0xFF191C1F),
    surface = Color(0xFFF9F9FC),
    onSurface = Color(0xFF191C1F),
    surfaceVariant = Color(0xFFDEE3EB),
    onSurfaceVariant = Color(0xFF42474E),
)

@Composable
fun VsvdTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit,
) {
    MaterialTheme(
        colorScheme = if (darkTheme) NightColors else DayColors,
        content = content,
    )
}
