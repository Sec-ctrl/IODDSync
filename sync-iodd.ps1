# Function to check if WSL2 is installed and running        !!!WARNING SCRIPT WILL USE DEFAULT WSL DISTRO!!!

function Test-WSL {
    $defaultLine = wsl -l -v | Where-Object { $_ -match "\*" } | ForEach-Object { "MATCH: $_" }
    
    if (-not $defaultLine) {
        Write-Host "No default WSL distribution found." -ForegroundColor Yellow
        return exit 1
    }
    
    # Extract version number from the default line
    $version = wsl -l -v | Where-Object { $_ -match "\*" } | ForEach-Object { ($_ -split '\s+')[-1] }
    
    if ($version -eq "2") {
        Write-Host "The default WSL distribution is using WSL 2." -ForegroundColor Green
        return
    } else {
        Write-Host "The default WSL distribution is NOT using WSL 2." -ForegroundColor Red
        exit 1
    }
}




# Function to install missing dependencies in WSL
function Install-WSLDependencies {
    Write-Host "Checking WSL dependencies..." -ForegroundColor Cyan

    # Get the default WSL distribution
    $defaultDistro =  [string](wsl -l -v | Where-Object { $_ -match "\*" } | ForEach-Object { ($_ -split '\s+')[1] }) -replace "`0", ""
    if (-not $defaultDistro) {
        Write-Host "Error: No default WSL distribution found. Please install a Linux distro in WSL." -ForegroundColor Red
        exit 1
    }

    # Detect package manager
    $pkgManager = wsl -d $defaultDistro bash -c "if command -v apt > /dev/null; then echo apt;
    elif command -v apk > /dev/null; then echo apk;
    elif command -v dnf > /dev/null; then echo dnf;
    elif command -v yum > /dev/null; then echo yum;
    elif command -v pacman > /dev/null; then echo pacman;
    else echo unknown; fi" 2>$null

    if ($pkgManager -eq "unknown") {
        Write-Host "Error: Unsupported WSL distribution. Please install dependencies manually." -ForegroundColor Red
        exit 1
    }

    Write-Host "Detected package manager: $pkgManager" -ForegroundColor Yellow

    # Install required dependencies only if missing
    switch ($pkgManager) {
        "apt" {
            wsl -d $defaultDistro bash -c "sudo apt update && sudo apt install -y rsync openssh-client iputils-ping util-linux"
        }
        "apk" {
            wsl -d $defaultDistro bash -c "sudo apk add rsync openssh-client iputils"
        }
        "dnf" {
            wsl -d $defaultDistro bash -c "sudo dnf install -y rsync openssh-clients iputils util-linux"
        }
        "yum" {
            wsl -d $defaultDistro bash -c "sudo yum install -y rsync openssh-clients iputils util-linux"
        }
        "pacman" {
            wsl -d $defaultDistro bash -c "sudo pacman -Sy --noconfirm rsync openssh iputils util-linux"
        }
    }

    Write-Host "WSL dependencies check complete." -ForegroundColor Green
}

# Function to detect the IODD drive
function Get-IODDDrive {
    Write-Host "Scanning for connected drives..." -ForegroundColor Cyan

    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Root  }
    $ioddDrives = @()

    foreach ($drive in $drives) {
        $ioddPath = "$($drive.Root)Service IT Tools"
        if (Test-Path -Path $ioddPath) {
            $ioddDrives += $drive.Root
        }
    }

    if ($ioddDrives.Count -eq 0) {
        Write-Host "No IODD device detected. Please connect an IODD and try again." -ForegroundColor Red
        exit 1
    }
    elseif ($ioddDrives.Count -eq 1) {
        Write-Host "IODD detected on drive: $($ioddDrives[0])" -ForegroundColor Green
        return $ioddDrives[0]
    }
    else {
        Write-Host "Multiple drives detected. Please select the correct IODD device:"
        for ($i = 0; $i -lt $ioddDrives.Count; $i++) {
            Write-Host ("{0}) {1}" -f ($i + 1, $ioddDrives[$i]))
        }
        $selection = Read-Host "Enter the number of the correct drive (1-$($ioddDrives.Count))"
        if ($selection -match "^[0-9]+$" -and [int]$selection -ge 1 -and [int]$selection -le $ioddDrives.Count) {
            return $ioddDrives[[int]$selection - 1]
        }
        else {
            Write-Host "Invalid selection. Exiting." -ForegroundColor Red
            exit 1
        }
    }
}

# Main execution
Write-Host "Starting IODD sync process..." -ForegroundColor Cyan
Test-WSL
Install-WSLDependencies
$ioddDrive = Get-IODDDrive

if (-Not (Test-Path $ioddDrive)) {
    Write-Host "Error: The detected IODD drive ($ioddDrive) is inaccessible. Please verify the drive and try again." -ForegroundColor Red
    exit 1
}

# Convert Windows path to WSL path properly
$ioddDriveWSL = wsl wslpath -a "`"$ioddDrive`""

Write-Host "Mounting IODD drive in WSL2: $ioddDriveWSL" -ForegroundColor Cyan

# Verify if script exists before execution
if (-Not (wsl bash -c "test -f ~/iodd_sync.sh && echo exists")) {
    Write-Host "Error: iodd_sync.sh not found in home directory. Please place the script in WSL before proceeding." -ForegroundColor Red
    exit 1
}

wsl bash -c "chmod +x ~/iodd_sync.sh && ~/iodd_sync.sh $ioddDriveWSL"

Write-Host "IODD sync process complete" -ForegroundColor Green
