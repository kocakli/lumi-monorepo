package lumi.android

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.style.TextAlign
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontFamily
import androidx.glance.text.Text
import androidx.glance.text.TextAlign as GlanceTextAlign
import androidx.glance.text.TextStyle
import androidx.compose.ui.graphics.Color

/// Mirror of apps/lumi-ios/LumiWidget/LumiWidget.swift — hourly rotating
/// positivity message on the home screen. Pure Kotlin / Glance because
/// Skip Fuse does not yet bridge WidgetKit / Glance.
///
/// V1: ships with a fallback pool baked in (no IPC with the running app
/// yet); WidgetDataService → SharedPreferences bridge to feed live moderated
/// messages will land in v2 along with WorkManager hourly refresh.
class LumiGlanceWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            LumiWidgetContent(context)
        }
    }
}

class LumiGlanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = LumiGlanceWidget()
}

@Composable
private fun LumiWidgetContent(context: Context) {
    // Pool — kept in sync with iOS LumiWidget.swift fallbackMessages.
    // V2: replace with SharedPreferences.read("widget_messages") so the
    // app pushes the user's current moderated feed.
    val pool = listOf(
        "Even the smallest star shines in the darkest night.",
        "The world is better because you chose to be kind today.",
        "Breathe in calm, breathe out worry. This moment is yours.",
        "You are doing better than you think.",
        "The kindness you show others always finds its way back.",
        "In the quiet moments, remember: you are enough.",
        "Your smile has the power to change someone's entire day.",
        "Courage is not the absence of fear. It is taking the next step anyway.",
        "Today, give yourself permission to rest. You have earned it.",
        "A single act of kindness throws out roots in all directions.",
        "Somewhere in the world, someone is grateful that you exist.",
        "Let the soft things in life catch you when you fall."
    )

    // Hour-of-day index → consistent rotation across all widget instances
    // for a given hour. matches iOS: change every hour, no ad-hoc shuffles.
    val hourIndex = ((System.currentTimeMillis() / 3_600_000L) % pool.size.toLong()).toInt()
    val message = pool[hourIndex]

    val cream = Color(0xFFFAF9F6)
    val ink = Color(0xFF635C61)

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(cream)
            .padding(16.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = "“$message”",
            style = TextStyle(
                color = ColorProvider(ink),
                fontSize = 14.sp,
                fontFamily = FontFamily.Serif,
                textAlign = GlanceTextAlign.Center
            )
        )
    }
}
