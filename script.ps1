# Verifier si le script est execute en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Ce script necessite des privileges administratifs. Veuillez executer le script en tant qu'administrateur."
    Exit
}

# Fonction pour telecharger un fichier
function Download-File {
    param (
        [string]$Url,
        [string]$Destination
    )

    Write-Host "Etape 1 : Telechargement du fichier depuis $Url..."
    $webClient = New-Object System.Net.WebClient
    $webClient.Encoding = [System.Text.Encoding]::UTF8  # Encodage UTF-8
    $webClient.DownloadFile($Url, $Destination)
}

# Fonction pour definir le fond d'ecran
function Set-Wallpaper {
    param (
        [string]$WallpaperPath
    )

    # Definir le chemin du fond d'ecran
    $RegKeyPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $RegKeyPath -Name Wallpaper -Value $WallpaperPath

    # Actualiser le bureau
    rundll32.exe user32.dll, UpdatePerUserSystemParameters, 1, True
}

# Fonction pour effectuer un nettoyage système
function Clean-System {
    Write-Host "Etape 2 : Nettoyage du système en cours..."

    # Supprimer les fichiers temporaires qui ne sont pas verrouillés
    Get-ChildItem -Path "$env:TEMP\*" | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
            Write-Host "Suppression de $($_.FullName)"
        } catch {
            Write-Host "Impossible de supprimer $($_.FullName): $($_.Exception.Message)"
        }
    }

    # Supprimer les fichiers temporaires de Windows qui ne sont pas verrouillés
    Get-ChildItem -Path "$env:SystemRoot\Temp\*" | ForEach-Object {
        try {
            Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
            Write-Host "Suppression de $($_.FullName)"
        } catch {
            Write-Host "Impossible de supprimer $($_.FullName): $($_.Exception.Message)"
        }
    }

    # Supprimer les fichiers du cache Windows Update s'ils existent
    $WindowsUpdateCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
    if (Test-Path -Path $WindowsUpdateCachePath -PathType Container) {
        Get-ChildItem -Path $WindowsUpdateCachePath | ForEach-Object {
            try {
                Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction Stop
                Write-Host "Suppression de $($_.FullName)"
            } catch {
                Write-Host "Impossible de supprimer $($_.FullName): $($_.Exception.Message)"
            }
        }
    }

    # Vider la corbeille
    Clear-RecycleBin -Force

    # Libérer de l'espace disque en supprimant les fichiers inutiles
    $CleanupManager = New-Object -ComObject "WScript.Shell"
    $CleanupManager.Run("cleanmgr.exe /sagerun:1")  # Exécutez la tâche de nettoyage personnalisée n°1

    Write-Host "Nettoyage du système terminé."
}


# Fonction pour installer les mises a jour Windows
function Install-WindowsUpdates {
    Write-Host "Etape 3 : Recherche de mises a jour Windows..."
    Start-Sleep -Seconds 3  # Pause de 3 secondes
    $Session = New-Object -ComObject Microsoft.Update.Session
    $Searcher = $Session.CreateUpdateSearcher()
    $SearchResult = $Searcher.Search("IsInstalled=0 and Type='Software'")

    if ($SearchResult.Updates.Count -gt 0) {
        Write-Host "Il y a $($SearchResult.Updates.Count) mise(s) a jour disponible(s)."
        Write-Host "Installation des mises a jour en cours..."
        Start-Sleep -Seconds 5  # Pause de 5 secondes

        # Creer une collection d'operations de mise a jour
        $UpdatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $SearchResult.Updates) {
            $UpdatesToInstall.Add($update)
        }

        # Creer un installateur de mise a jour
        $Installer = $Session.CreateUpdateInstaller()
        $Installer.Updates = $UpdatesToInstall

        # Installer les mises a jour
        $InstallResult = $Installer.Install()

        if ($InstallResult.ResultCode -eq 2) {
            Write-Host "Les mises a jour ont ete installees avec succes."
        } else {
            Write-Host "Echec de l'installation des mises a jour. Code d'erreur : $($InstallResult.ResultCode)"
        }
    } else {
        Write-Host "Aucune mise a jour Windows disponible."
    }
}

# Fonction pour installer les applications avec winget
function Install-Applications {
    Write-Host "Etape 4 : Installation des applications en cours..."
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

    Write-Host "Installation des applications terminee."
}

# Etape 1 : Telecharger le fond d'ecran
$WallpaperUrl = "https://raw.githubusercontent.com/jeremy99981/techrevive/main/sshlwtppwxob1.webp"
$WallpaperPath = "$env:USERPROFILE\Pictures\wallpaper.webp"
Download-File -Url $WallpaperUrl -Destination $WallpaperPath

# Etape 2 : Appliquer le fond d'ecran
Write-Host "Etape 2 : Application du fond d'ecran..."
Start-Sleep -Seconds 3  # Pause de 3 secondes
Set-Wallpaper -WallpaperPath $WallpaperPath

# Etape 3 : Nettoyer le systeme
Clean-System

# Etape 4 : Installer les mises a jour Windows
Install-WindowsUpdates

# Etape 5 : Installer les applications avec winget
Install-Applications

# Etape 6 : Scannow
sfc /scannow

# Etape 7 : Flush DNS
ipconfig/flushDNS

# Etape 8 : Clear Windows cache
wsreset.exe

Write-Host "Toutes les mises a jour Windows et les applications ont ete installees, le fond d'ecran a ete applique, et le systeme a ete nettoye avec succes."
