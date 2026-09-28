package com.devnest.devnest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class DevNestServerService : Service() {
    private val CHANNEL_ID = "DevNestServiceChannel"
    private val NOTIFICATION_ID = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DevNest Server Running")
            .setContentText("Nginx, PHP, and MariaDB are running in the background.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // TODO: Spawn actual processes for Nginx, PHP, MariaDB here using ProcessBuilder.
        // For Phase 1, we just simulate the service running.
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        // TODO: Kill Nginx, PHP, MariaDB processes here.
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null // We don't provide binding, just start/stop
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "DevNest Foreground Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager: NotificationManager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
