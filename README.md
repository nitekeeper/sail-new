# sail-new
<p align="center"> <strong>Laravel Sail Bootstrapper</strong><br> A clean, cross-platform Bash tool for creating Laravel projects with Docker — safely and correctly. </p> <p align="center"> <img src="https://img.shields.io/badge/Laravel-12.x-red?logo=laravel" /> <img src="https://img.shields.io/badge/Docker-required-blue?logo=docker" /> <img src="https://img.shields.io/badge/Bash-5%2B-black?logo=gnubash" /> <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20WSL-lightgrey" /> <img src="https://img.shields.io/badge/License-MIT-green" /> </p>


---

## What is sail-new?
`sail-new` is a production-grade Laravel project generator built on top of Laravel SaiIt solves common issues developers encounter:
- Root-owned files after Docker installs
- Broken local Sail symlinks
- System pollution via /usr/local/bin
- Permission headaches
- Manual Sail setup every time
Instead, it provides:
- UID/GID-safe Docker execution
- One-time global Sail wrapper
- Clean PATH handling
- Service validation
- Optional custom DB port
- Cross-platform compatibility
---
## Features
- Docker-based Laravel installation
- No root-owned files (host UID/GID respected)
- Smart Laravel Sail service validation
- One global `sail` wrapper (~/.local/bin)
- No per-project symlinks
- No sudo required
- Optional custom database port
- Linux, macOS, and WSL compatible
---
## Requirements
- Docker (running)
- Bash (5+ recommended)
- PHP installed locally
- Internet connection
---
## Installation
```
git clone https://github.com/yourusername/sail-new.git
cd sail-new
chmod +x sail-new.sh
source ./sail-new.sh
```
---
## Usage
```
sail-new
sail up -d
```

Access at: http://localhost

---
## ■ License
MIT License
