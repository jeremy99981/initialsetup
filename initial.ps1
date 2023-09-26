# Vérifier si le script est exécuté en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script nécessite des privilèges administratifs. Veuillez exécuter le script en tant qu'administrateur."
    Exit
}

# Vérifier si le module PSWindowsUpdate est installé, sinon l'installer
$psWindowsUpdateInstalled = Get-Module -ListAvailable | Where-Object { $_.Name -eq 'PSWindowsUpdate' }

if (-not $psWindowsUpdateInstalled) {
    Write-Host "Le module PSWindowsUpdate n'est pas installé. Installation en cours..."
    Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Scope CurrentUser
    Import-Module PSWindowsUpdate
    Write-Host "Le module PSWindowsUpdate a été installé avec succès."
} else {
    Import-Module PSWindowsUpdate
    Write-Host "Le module PSWindowsUpdate est déjà installé."
}

# Fonction pour télécharger un fichier
function Download-File {
    param (
        [string]$Url,
        [string]$Destination
    )

    Write-Host "Étape 1 : Téléchargement du fichier depuis $Url..."
    $webClient = New-Object System.Net.WebClient
    $webClient.Encoding = [System.Text.Encoding]::UTF8  # Encodage UTF-8
    try {
        $webClient.DownloadFile($Url, $Destination)
        Write-Host "Téléchargement terminé."
    } catch {
        Write-Host "Erreur lors du téléchargement du fichier : $($_.Exception.Message)"
    }
}

# Fonction pour définir le fond d'écran
function Set-Wallpaper {
    param (
        [string]$WallpaperPath
    )

    # Définir le chemin du fond d'écran
    $RegKeyPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $RegKeyPath -Name Wallpaper -Value $WallpaperPath

    # Actualiser le bureau
    rundll32.exe user32.dll, UpdatePerUserSystemParameters, 1, True
}

# Fonction pour installer les mises à jour Windows
function Install-WindowsUpdates {
    Write-Host "Étape 2 : Installation des mises à jour Windows..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes

    # Vérifier les mises à jour avec PSWindowsUpdate
    $updates = Get-WUList

    if ($updates.Count -gt 0) {
        Write-Host "Il y a $($updates.Count) mise(s) à jour disponible(s)."
        Write-Host "Installation des mises à jour en cours..."
        Start-Sleep -Seconds 5  # Pause de 5 secondes

        # Installer les mises à jour
        Install-WindowsUpdate -AcceptAll -AutoReboot

        Write-Host "Les mises à jour ont été installées avec succès."
    } else {
        Write-Host "Aucune mise à jour Windows disponible."
    }
}

# Fonction pour installer les applications avec winget
function Install-Applications {
    Write-Host "Étape 3 : Installation des applications en cours..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes

    # Verifier si winget est present sur le PC
    $wingetInstalled = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $wingetInstalled) {
        Write-Host "winget n'est pas installe sur ce PC. Telechargement et installation de winget..."
        Start-Sleep -Seconds 3  # Pause de 3 secondes
        $wingetInstallerUrl = "https://aka.ms/winget"

        # Telecharger le programme d'installation de winget
        $wingetInstallerPath = "$env:TEMP\winget_installer.msi"
        Download-File -Url $wingetInstallerUrl -Destination $wingetInstallerPath

        # Installer winget
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $wingetInstallerPath, "/qn" -Wait

        # Supprimer le programme d'installation
        Remove-Item $wingetInstallerPath -Force

        Write-Host "winget a ete installe avec succes."
        Start-Sleep -Seconds 3  # Pause de 3 secondes
    }

    # Installer VLC Media Player
    Write-Host "Installation de VLC Media Player..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes
    winget install --id VideoLAN.VLC

    # Installer Mozilla Firefox
    Write-Host "Installation de Mozilla Firefox..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes
    winget install --id Mozilla.Firefox

    # Installer 7-Zip
    Write-Host "Installation de 7-Zip..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes
    winget install --id 7zip.7zip

    Write-Host "Installation des applications terminée."
}

# Etape 1 : Télécharger le fond d'écran
$WallpaperUrl = "https://raw.githubusercontent.com/jeremy99981/techrevive/main/sshlwtppwxob1.webp"
$WallpaperPath = "$env:USERPROFILE\Pictures\wallpaper.webp"
Download-File -Url $WallpaperUrl -Destination $WallpaperPath

# Etape 2 : Appliquer le fond d'écran
Write-Host "Étape 2 : Application du fond d'écran..."
Start-Sleep -Seconds 3  # Pause de 3 secondes
Set-Wallpaper -WallpaperPath $WallpaperPath

# Etape 3 : Installer les mises à jour Windows
Install-WindowsUpdates

# Etape 4 : Installer les applications avec winget
Install-Applications

Write-Host "Toutes les mises à jour Windows et les applications ont été installées, le fond d'écran a été appliqué, et le script s'est exécuté avec succès."