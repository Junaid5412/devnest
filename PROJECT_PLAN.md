# DevNest - Android Local Web Development & Server Environment

## Project Overview

**App Name:** DevNest  
**Platform:** Android first  
**Frontend:** Flutter (Dart, Material 3, Dark/Light Theme, Responsive)  
**Native Layer:** Kotlin + Android NDK where required (JNI, Android Services)  
**Supported Architecture:** ARM64-v8a initially (Possible future: armeabi-v7a, x86_64)  
**Minimum Android:** Android 10 recommended  

**Main principle:** "Your Development Server in Your Pocket."

The application should **NOT** require the Android device to be rooted.

## Core Server Components
- Nginx (Primary web server, optional Apache)
- PHP & PHP-FPM (Multiple versions, extensions management, php.ini)
- MariaDB (MySQL-compatible, phpMyAdmin integration)
- Node.js (npm, npx, custom ports)
- Composer
- Git (Clone, Init, Pull, Push, Commit, Branches)
- Optional Linux userspace layer (PRoot, Debian/Ubuntu rootfs)

## Features & Requirements

### 1. Modern Server-Control Dashboard
- Display statuses for: Web Server, PHP, Database, Node.js
- System metrics: CPU Usage, RAM Usage, Storage Usage, Device IP, Localhost Address
- Controls: START ALL, STOP ALL, RESTART ALL
- Individual service controls (Start, Stop, Restart, Logs, Configuration)

### 2. Project Management
- **Project Types:** PHP, Laravel, WordPress, Node.js, Static Website, Custom
- **Multiple Sites Management (Must)**: Virtual hosts, custom ports, document root selection.
- **One-Click Installations:**
  - **Laravel:** Auto-create project, DB, `.env`, generate key, Composer install. Actions: Serve, Artisan, Migrate, etc.
  - **WordPress:** Auto-download, create DB, configure `wp-config.php`, configure Nginx.
- **Project Card Actions:** Start, Stop, Restart, Open, Files, Terminal, Database, Configuration, Logs, Backup, Delete.

### 3. Database Manager (MariaDB)
- Start/Stop/Restart MariaDB
- Database list, Create/Delete DB
- Create users, Change passwords
- Import/Export/Backup/Restore
- One-click phpMyAdmin installation & auto-configuration

### 4. File & Code Management
- **Built-in File Manager:** Create, Rename, Move, Copy, Delete, Compress, Extract, Search, Upload/Export.
- **Built-in Code Editor:** Support for PHP, HTML, CSS, JS, JSON, XML, YAML, ENV, TXT, LOG, CONF with syntax highlighting.

### 5. Developer Tools
- **Terminal Emulator:** Multiple sessions, command history, shortcuts, custom font size, dark background, full-screen. Commands: `php`, `node`, `npm`, `composer`, `git`, `mysql`.
- **Logs Section:** Centralized logs with search, filter, copy, clear, export, live viewing.
- **Configuration Editing:** Advanced users can edit `nginx.conf`, Virtual Hosts, `php.ini`, PHP-FPM, MariaDB configs. Backup before saving, Validate, Reset to default.

### 6. Network & Security
- Default binding to 127.0.0.1 / localhost.
- Optional "Allow LAN Access" with security warning.
- Central port manager with conflict detection.
- Local HTTPS (Generate dev certificates).
- No root required. Secure credential storage (Android Keystore). Protect project files from unauthorized apps.

### 7. Component Architecture
- DevNest Component Repository for downloading/updating runtimes independently.
- UI: Installed, Available, Updates.
- Packages must be signed/checksummed and downloaded over secure connections.
- Core app (APK) should be small, prompting user to download components on first launch (e.g., Nginx, PHP, MariaDB).

## Recommended Internal Architecture
```text
DevNest/
├── bin/
├── config/
├── data/
├── logs/
├── packages/
├── projects/
│   ├── wordpress/
│   ├── laravel/
│   ├── node/
│   └── php/
├── runtime/
├── tmp/
└── backups/
```

### Process Flow
Flutter UI -> Platform Channels / FFI -> Android Kotlin Service -> Process Manager -> (Nginx, PHP, MariaDB, Node.js, Git)

## Phased Build Approach

**Phase 1: Core Foundation**
- Flutter UI & Native service manager
- Nginx, PHP, PHP-FPM, MariaDB
- Project manager, File manager, Logs, Localhost access
- Goal: Create a PHP project and open it on localhost.

**Phase 2: Expanded Ecosystem**
- Node.js, npm, Composer, Git, Terminal
- Laravel support, WordPress installer
- Database manager, Multiple projects, Virtual hosts

**Phase 3: Advanced Features**
- Multiple PHP versions, Extension manager, Node version manager
- SSL, Backups, Restore, LAN access, Advanced configuration
- Improved code editor, DevNest Package Manager

## Long-Term Vision
"DevNest — Your Development Server in Your Pocket."
Evolve into a complete Android development environment for PHP, Laravel, WordPress, Node.js, Frontend, and Database testing.
