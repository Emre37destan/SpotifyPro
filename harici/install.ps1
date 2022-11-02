$PSDefaultParameterValues['Stop-Process:ErrorAction'] = 'SilentlyContinue'
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$tsl_check = [Net.ServicePointManager]::SecurityProtocol
if (!($tsl_check -match '^tls12$' )) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

Write-Host "*****************"
Write-Host "Gelistirici: " -NoNewline
Write-Host "@KralDev" -ForegroundColor DarkYellow
Write-Host "*****************"`n

$SpotifyDirectory = "$env:APPDATA\Spotify"
$SpotifyExecutable = "$SpotifyDirectory\Spotify.exe"
$Podcasts_off = $false

Stop-Process -Name Spotify
Stop-Process -Name SpotifyWebHelper

if ($PSVersionTable.PSVersion.Major -ge 7) {
    Import-Module Appx -UseWindowsPowerShell
}

$win_os = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
$win11 = $win_os -match "\windows 11\b"
$win10 = $win_os -match "\windows 10\b"
$win8_1 = $win_os -match "\windows 8.1\b"
$win8 = $win_os -match "\windows 8\b"

if ($win11 -or $win10 -or $win8_1 -or $win8) {
    if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
        Write-Host "Spotify uygulamanın desteklenmeyen surumu algilandi."`n
        $ch = Read-Host -Prompt "Spotify uygulamayi kaldirmak istiyor musunuz? (Y/N)"
        if ($ch -eq 'y') {
            Write-Host "Spotify Kaldiriliyor..."`n
            Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
        } else {
            Write-Host 'Kapatiliyor...'`n
            Pause 
            exit
        }
    }
}

Push-Location -LiteralPath $env:TEMP
try {
    New-Item -Type Directory -Name "SpotifyPro-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" `
    | Convert-Path `
    | Set-Location
} catch {
    Write-Output ''
    Pause
    exit
}

Write-Host "SpotifyPro'nun en son surumu indiriliyor..."`n

$webClient = New-Object -TypeName System.Net.WebClient
try {
    $webClient.DownloadFile('https://github.com/Emre37destan/SpotifyPro/releases/latest/download/SpotifyPro.zip', "$PWD\SpotifyPro.zip")
} catch {
    Write-Output ''
    Start-Sleep
}

Expand-Archive -Force -LiteralPath "$PWD\SpotifyPro.zip" -DestinationPath $PWD
Remove-Item -LiteralPath "$PWD\SpotifyPro.zip"

$spotifyInstalled = (Test-Path -LiteralPath $SpotifyExecutable)
if (-not $spotifyInstalled) {
    
    try {
        $webClient.DownloadFile('https://download.scdn.co/SpotifySetup.exe', "$PWD\SpotifySetup.exe")
    } catch {
        Write-Output ''
        Pause
        exit
    }
    mkdir $SpotifyDirectory | Out-Null

    $version_client_check = (get-item $PWD\SpotifySetup.exe).VersionInfo.ProductVersion
    $version_client = $version_client_check -split '.\w\w\w\w\w\w\w\w\w'
   
    Write-Host "Spotify indiriliyor & yukleniyor" -NoNewline
    Write-Host  $version_client -ForegroundColor Green
    Write-Host "Lutfen Bekleyin..."`n
    
    Start-Process -FilePath $PWD\SpotifySetup.exe; wait-process -name SpotifySetup

    Stop-Process -Name Spotify
    Stop-Process -Name SpotifyWebHelper
    Stop-Process -Name SpotifyFullSetup

    $ErrorActionPreference = 'SilentlyContinue'

    if (test-path "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files\") {
        get-childitem -path "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files\" -Recurse -Force -Filter  "SpotifyFullSetup*" | remove-item  -Force
    }
    if (test-path $env:LOCALAPPDATA\Microsoft\Windows\INetCache\) {
        get-childitem -path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\" -Recurse -Force -Filter  "SpotifyFullSetup*" | remove-item  -Force
    }
}

if (!(test-path $SpotifyDirectory/_chrome_elf.dll)) {
    Move-Item $SpotifyDirectory\chrome_elf.dll $SpotifyDirectory\_chrome_elf.dll
}

Write-Host 'Spotify Pro Yapiliyor...'`n
$patchFiles = "$PWD\chrome_elf.dll"
Copy-Item -LiteralPath $patchFiles -Destination "$SpotifyDirectory"

$tempDirectory = $PWD
Pop-Location

Start-Sleep -Milliseconds 200
Remove-Item -Recurse -LiteralPath $tempDirectory 

do {
    $ch = Read-Host -Prompt "Podcast'leri kapatmak istiyor musunuz? (Y/N)"
    Write-Host ""
    if (!($ch -eq 'n' -or $ch -eq 'y')) {
    
        Write-Host "Hata, Yanlis Deger," -ForegroundColor Red -NoNewline
        Write-Host "Tekrar Denensin Mi (Y/N)" -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host "3" -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host ".2" -NoNewline
        Start-Sleep -Milliseconds 1000
        Write-Host ".1"
        Start-Sleep -Milliseconds 1000     
        Clear-Host
    }
}
while ($ch -notmatch '^y$|^n$')
if ($ch -eq 'y') { $Podcasts_off = $true }

$xpui_spa_patch = "$env:APPDATA\Spotify\Apps\xpui.spa"
$xpui_js_patch = "$env:APPDATA\Spotify\Apps\xpui\xpui.js"

If (Test-Path $xpui_js_patch) {
    Write-Host "Pro Yapilacak Dosyalar Bulundu"`n 

    $xpui_js = Get-Content $xpui_js_patch -Raw
    
    If (!($xpui_js -match 'KralDev Tarafindan Yapildi')) {
        Copy-Item $xpui_js_patch "$xpui_js_patch.bak"
        
        $new_js = $xpui_js `
            -replace 'adsEnabled:!0', 'adsEnabled:!1' `
            -replace "allSponsorships", "" `
            -replace '(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===', '$1"premium"===$2$3"free"===' `
            -replace '(Sol kenar cubugunda "Sizin Icin Yapildi" giris noktasini goster,default:)(!1)', '$1!0' `
            -replace '(Yeni cipli Arama deneyimini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Sanatci sayfasinda Begenilen Sarkilar bolumunu etkinlestir",default:)(!1)', '$1!0' `
            -replace '(ClientX te kullanicilari engelleme ozelligini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Quicksilver uygulama ici mesajlasma modunu etkinlestir",default:)(!0)', '$1!1' `
            -replace '(Bu etkinlestirildiginde musteriler parcalarin sarki sozleri olup olmadigini kontrol edecek",default:)(!1)', '$1!0' `
            -replace '(Web Player ve DesktopX te yeni calma listesi olusturma akisini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Son kullanicilar icin Enhance Playlist UI ve islevselligini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Sanatci sayfalarinda yogun bir disografi rafini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Yeni tam ekran sarki sozleri sayfasini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Prod icin Oynatma Listesi Izinleri akislarini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Begenilen Sarkilari Gelistirme Kullanici arayuzune & islevselligini etkinlestir",default:)(!1)', '$1!0'
        if ($Podcasts_off) {
            $new_js = $new_js `
                -replace '(return this\.queryParameters=(.),)', '$2.types=["album","playlist","artist","station"];$1' `
                -replace ',this[.]enableShows=[a-z]', ""
        }

        Set-Content -Path $xpui_js_patch -Force -Value $new_js
        add-content -Path $xpui_js_patch -Value '// KralDev Tarafindan Yapildi' -passthru | Out-Null
        $contentjs = [System.IO.File]::ReadAllText($xpui_js_patch)
        $contentjs = $contentjs.Trim()
        [System.IO.File]::WriteAllText($xpui_js_patch, $contentjs)
    } else {
        Write-Host "Spotify Zaten Pro"`n 
    }
}

If (Test-Path $xpui_spa_patch) {
    Add-Type -Assembly 'System.IO.Compression.FileSystem'

    $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
    $entry = $zip.GetEntry('xpui.js')
    $reader = New-Object System.IO.StreamReader($entry.Open())
    $patched_by_spotx = $reader.ReadToEnd()
    $reader.Close()
 

    If (!($patched_by_spotx -match 'KralDev Tarafindan Yapildi')) {
        $zip.Dispose()
        Copy-Item $xpui_spa_patch $env:APPDATA\Spotify\Apps\xpui.bak 

        Add-Type -Assembly 'System.IO.Compression.FileSystem'
        $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
    
        $entry_xpui = $zip.GetEntry('xpui.js')

        $reader = New-Object System.IO.StreamReader($entry_xpui.Open())
        $xpuiContents = $reader.ReadToEnd()
        $reader.Close()

        $xpuiContents = $xpuiContents `
            -replace 'adsEnabled:!0', 'adsEnabled:!1' `
            -replace "allSponsorships", "" `
            -replace '(return|.=.=>)"free"===(.+?)(return|.=.=>)"premium"===', '$1"premium"===$2$3"free"===' `
            -replace '(Sol kenar cubugunda "Sizin Icin Yapildi" giris noktasini goster,default:)(!1)', '$1!0' `
            -replace '(Yeni cipli Arama deneyimini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Sanatci sayfasinda Begenilen Sarkilar bolumunu etkinlestir",default:)(!1)', '$1!0' `
            -replace '(ClientX te kullanicilari engelleme ozelligini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Quicksilver uygulama ici mesajlasma modunu etkinlestir",default:)(!0)', '$1!1' `
            -replace '(Bu etkinlestirildiginde musteriler parcalarin sarki sozleri olup olmadigini kontrol edecek",default:)(!1)', '$1!0' `
            -replace '(Web Player ve DesktopX te yeni calma listesi olusturma akisini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Son kullanicilar icin Enhance Playlist UI ve islevselligini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Sanatci sayfalarinda yogun bir disografi rafini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Yeni tam ekran sarki sozleri sayfasini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Prod icin Oynatma Listesi Izinleri akislarini etkinlestir",default:)(!1)', '$1!0' `
            -replace '(Begenilen Sarkilari Gelistirme Kullanici arayuzune & islevselligini etkinlestir",default:)(!1)', '$1!0'
        if ($Podcasts_off) {
            $xpuiContents = $xpuiContents `
                -replace '(return this\.queryParameters=(.),)', '$2.types=["album","playlist","artist","station"];$1' -replace ',this[.]enableShows=[a-z]', ""
        }

        $writer = New-Object System.IO.StreamWriter($entry_xpui.Open())
        $writer.BaseStream.SetLength(0)
        $writer.Write($xpuiContents)
        $writer.Write([System.Environment]::NewLine + '// KralDev Tarafindan Yapildi')
        $writer.Close()

        $entry_vendor_xpui = $zip.GetEntry('vendor~xpui.js')

        $reader = New-Object System.IO.StreamReader($entry_vendor_xpui.Open())
        $xpuiContents_vendor = $reader.ReadToEnd()
        $reader.Close()

        $xpuiContents_vendor = $xpuiContents_vendor `
            -replace "prototype\.bindClient=function\(\w+\)\{", '${0}return;'

        $writer = New-Object System.IO.StreamWriter($entry_vendor_xpui.Open())
        $writer.BaseStream.SetLength(0)
        $writer.Write($xpuiContents_vendor)
        $writer.Close()

        $zip.Entries | Where-Object FullName -like '*.css' | ForEach-Object {
            $readercss = New-Object System.IO.StreamReader($_.Open())
            $xpuiContents_css = $readercss.ReadToEnd()
            $readercss.Close()

            $xpuiContents_css = $xpuiContents_css `
                -replace "}\[dir=ltr\]\s?([.a-zA-Z\d[_]+?,\[dir=ltr\])", '}[dir=str] $1' `
                -replace "}\[dir=ltr\]\s?", "} " `
                -replace "html\[dir=ltr\]", "html" `
                -replace ",\s?\[dir=rtl\].+?(\{.+?\})", '$1' `
                -replace "[\w\-\.]+\[dir=rtl\].+?\{.+?\}", "" `
                -replace "\}\[lang=ar\].+?\{.+?\}", "}" `
                -replace "\}\[dir=rtl\].+?\{.+?\}", "}" `
                -replace "\}html\[dir=rtl\].+?\{.+?\}", "}" `
                -replace "\}html\[lang=ar\].+?\{.+?\}", "}" `
                -replace "\[lang=ar\].+?\{.+?\}", "" `
                -replace "html\[dir=rtl\].+?\{.+?\}", "" `
                -replace "html\[lang=ar\].+?\{.+?\}", "" `
                -replace "\[dir=rtl\].+?\{.+?\}", "" `
                -replace "\[dir=str\]", "[dir=ltr]" `
                -replace "[/]\*([^*]|[\r\n]|(\*([^/]|[\r\n])))*\*[/]", "" `
                -replace "[/][/]#\s.*", "" `
                -replace "\r?\n(?!\(1|\d)", ""
            
            $writer = New-Object System.IO.StreamWriter($_.Open())
            $writer.BaseStream.SetLength(0)
            $writer.Write($xpuiContents_css)
            $writer.Close()
        }
        $zip.Dispose()
    } else {
        $zip.Dispose()
        Write-Host "Spotify Zaten Pro"`n
    }
}

$ErrorActionPreference = 'SilentlyContinue' 

if (Test-Path "$env:USERPROFILE\Desktop") {  
    $desktop_folder = "$env:USERPROFILE\Desktop"
}

$regedit_desktop_folder = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\"
$regedit_desktop = $regedit_desktop_folder.'{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}'
 
if (!(Test-Path "$env:USERPROFILE\Desktop")) {
    $desktop_folder = $regedit_desktop
}

$ErrorActionPreference = 'SilentlyContinue' 

If (!(Test-Path $env:USERPROFILE\Desktop\Spotify.lnk)) {
    $source = "$env:APPDATA\Spotify\Spotify.exe"
    $target = "$desktop_folder\Spotify.lnk"
    $WorkingDir = "$env:APPDATA\Spotify"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($target)
    $Shortcut.WorkingDirectory = $WorkingDir
    $Shortcut.TargetPath = $source
    $Shortcut.Save()      
}

Write-Host "Yukleme Tamamlandi"`n -ForegroundColor Green
exit
