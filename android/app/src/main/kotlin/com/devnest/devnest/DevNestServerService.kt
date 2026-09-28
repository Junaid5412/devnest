package com.devnest.devnest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.IOException

class DevNestServerService : Service() {
    private val CHANNEL_ID = "DevNestServiceChannel"
    private val NOTIFICATION_ID = 1
    
    private val processes = mutableListOf<Process>()

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DevNest Server Running")
            .setContentText("Nginx, PHP, and MariaDB are live.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // The binaries are downloaded into getFilesDir() by Flutter's getApplicationSupportDirectory()
        val basePath = filesDir.absolutePath
        
        // Spawn Nginx
        startProcess("$basePath/bin/nginx", listOf())
        
        // Spawn PHP-FPM
        startProcess("$basePath/bin/php", listOf("-S", "127.0.0.1:8080", "-t", "$basePath/www"))
        
        // Spawn MariaDB (mysqld)
        startProcess("$basePath/bin/mariadb", listOf("--datadir=$basePath/data"))

        return START_STICKY
    }

    private fun startProcess(executable: String, args: List<String>) {
        val execFile = File(executable)
        if (!execFile.exists()) {
            Log.e("DevNestService", "Executable not found: $executable")
            return
        }
        
        try {
            val command = mutableListOf(executable)
            command.addAll(args)
            
            val processBuilder = ProcessBuilder(command)
            processBuilder.directory(filesDir)
            processBuilder.redirectErrorStream(true) // merge stderr and stdout
            
            val process = processBuilder.start()
            processes.add(process)
            
            Log.i("DevNestService", "Started process: $executable")
            
            // Optional: Read process output in a separate thread
            Thread {
                process.inputStream.bufferedReader().use { reader ->
                    var line: String?
                    while (reader.readLine().also { line = it } != null) {
                        Log.d("DevNestService", "[$executable] $line")
                    }
                }
            }.start()
            
        } catch (e: IOException) {
            Log.e("DevNestService", "Failed to start $executable: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i("DevNestService", "Stopping all processes...")
        for (process in processes) {
            process.destroy()
        }
        processes.clear()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null 
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
