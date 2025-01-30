# 🚀 IODD Sync Tool

## 📌 Overview
The **IODD Sync Tool** is a powerful PowerShell and Bash script combo that automates the synchronization of data between a **WSL2 environment** and an **IODD (Industrial Optical Disk Drive) device**. It ensures dependencies are installed, detects the IODD drive, and provides an easy-to-use sync process.

## ✨ Features
✅ **Checks for WSL2 installation** and verifies the default WSL distribution.  
✅ **Automatically installs missing dependencies** based on the package manager.  
✅ **Detects connected IODD devices** and mounts them for data transfer.  
✅ **Offers multiple sync modes**, including test sync, full sync, and selective sync.  
✅ **Ensures connection to the source server** before initiating data synchronization.  
✅ **User-friendly menu for selective sync and exclusions**.

## 🛠 Prerequisites
Before running the script, ensure you have:
- 🖥 **Windows with WSL2 installed** and a default Linux distribution set up.
- 🔐 **A configured SSH connection** to the source sync repository.
- 📂 **An IODD device properly connected** to your system.
- 🔄 **Rsync and necessary networking tools** installed in WSL.

## 📥 Installation & Usage

### 1️⃣ Clone the repository
```sh
git clone https://github.com/your-repo/iodd-sync-tool.git
cd iodd-sync-tool
```

### 2️⃣ Run the PowerShell script
Open **PowerShell as Administrator** and execute:
```powershell
.\iodd_sync.ps1
```

### 3️⃣ Follow on-screen instructions
- The script will **check WSL2 status**.  
- It will **install required dependencies** if missing.  
- It will **detect your IODD drive**.  
- It will **run the iodd_sync.sh script in WSL** to start synchronization.  

## 🔄 Sync Options
When running `iodd_sync.sh`, you can choose from:
1️⃣ **🛠 Test Sync** (Dry run to check for errors without making changes)  
2️⃣ **🚀 Quick Full Update** (Complete sync and automatic verification)  
3️⃣ **📂 Selective Sync** (Manually select specific files/folders to sync)  
4️⃣ **🔍 Keep Specific Files/Folders** (Exclude selected items while syncing everything else)  
5️⃣ **❌ Exit** (Cancel operation)  

## 🛑 Troubleshooting
⚠ **No default WSL distribution found?** Install a Linux distro and set it as default.  
⚠ **IODD not detected?** Ensure it's connected and properly recognized by Windows.  
⚠ **Missing dependencies in WSL?** Run the script as Administrator.  
⚠ **Unable to reach sync server?** Check network connection and SSH credentials.  

## 📜 License
This project is licensed under the **MIT License**.

## 👨‍💻 Author
Developed by **Your Name/Company**. Contributions and feedback are always welcome! 💡

