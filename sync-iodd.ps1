# sync-iodd.ps1

# Run with: powershell -ExecutionPolicy  Bypass -File .\sync-iodd.ps1"

# Function to check if Docker is installed and running
function Test-Docker {
    Write-Host "Checking Docker status..." -ForegroundColor Cyan

    # Check if Docker is installed
    if (-Not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Error: Docker is not installed. Please install Docker Desktop and try again." -ForegroundColor Red
        exit 1
    }

    # Check if Docker is responding
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}' 2>$null
        if ($null -eq $dockerVersion -or $dockerVersion -eq "") {
            Write-Host "❌ Error: Docker is installed but not responding. Please start Docker Desktop." -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "❌ Error: Docker is installed but unresponsive. Please check Docker." -ForegroundColor Red
        exit 1
    }

    # Check if Docker daemon is running by listing containers
    try {
        docker ps | Out-Null
    } catch {
        Write-Host "❌ Error: Docker daemon is not running. Please start Docker Desktop and try again." -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Docker is installed and running." -ForegroundColor Green
}

# Function to detect the IODD drive
function Get-IODDDrive {
    Write-Host "Scanning for connected drives..."

    # Get a list of mounted drives
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne$_.Root }

    # Array to store potential IODD drives
    $ioddDrives = @()

    foreach ($drive in $drives) {
        # Check for a recognizable IODD structure (marker file/folder)
        $ioddPath = "$($drive.Root)IODD_README.txt"
        $toolsPath = "$($drive.Root)serviceit_tools"                            # Change this to the correct folder
        
        if ((Test-Path -Path $ioddPath) -or (Test-Path -Path $toolsPath)) {
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
        # Prompt user to select a drive if multiple IODDs are found
        Write-Host "Multiple drives detected. Please select the correct IODD device:"
        for ($i = 0; $i -lt $ioddDrives.Count; $i++) {
            Write-Host "$($i + 1)) $($ioddDrives[$i])"
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

# Step 1: Ensure Docker is installed and running
Test-Docker

# Step 2: Detect the IODD drive
$ioddDrive = Get-IODDDrive

# Step 3: Validate that the drive exists
if (-Not (Test-Path $ioddDrive)) {
    Write-Host "Error: The detected IODD drive ($ioddDrive) is inaccessible. Please verify the drive and try again." -ForegroundColor Red
    exit 1
}

# Step 4: Start Docker container with the detected drive
Write-Host "Starting Docker container for sync..." -ForegroundColor Cyan
docker run -it --rm `
    --name iodd-updater `
    --privileged `
    -v "$ioddDrive`:/mnt/iodd" `  # Fixed path formatting
    iodd-updater

# Step 5: Confirm completion
Write-Host "IODD sync process complete!" -ForegroundColor Green
