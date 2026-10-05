param(
    [string]$IsoPath = (Join-Path $PSScriptRoot '..\.cache\debian-13.7.0-amd64-netinst.iso'),
    [string]$PasswordFile = (Join-Path $PSScriptRoot '..\.local\template-password.txt'),
    [string]$PreseedTemplate = (Join-Path $PSScriptRoot 'templates\debian-preseed.cfg'),
    [string]$VmName = 'debian-ha-template'
)

$ErrorActionPreference = 'Stop'
$vboxManage = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'

function Invoke-VBox {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & $vboxManage @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "VBoxManage failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

if (-not (Test-Path -LiteralPath $vboxManage)) {
    throw "VBoxManage was not found at $vboxManage"
}

$IsoPath = (Resolve-Path -LiteralPath $IsoPath).Path
$PasswordFile = (Resolve-Path -LiteralPath $PasswordFile).Path
$PreseedTemplate = (Resolve-Path -LiteralPath $PreseedTemplate).Path

$registeredVms = & $vboxManage list vms
if ($registeredVms -match ('(?m)^"' + [regex]::Escape($VmName) + '"\s')) {
    throw "A VM named '$VmName' is already registered. No changes were made."
}

$systemProperties = & $vboxManage list systemproperties
$folderLine = $systemProperties | Where-Object { $_ -match '^Default machine folder:' }
if (-not $folderLine) {
    throw 'Could not determine the VirtualBox default machine folder.'
}

$machineFolder = ($folderLine -replace '^Default machine folder:\s*', '').Trim()
$vmFolder = Join-Path $machineFolder $VmName
$diskPath = Join-Path $vmFolder "$VmName.vdi"

Invoke-VBox createvm --name $VmName --ostype Debian_64 --register
Invoke-VBox modifyvm $VmName `
    --memory 1024 `
    --cpus 1 `
    --vram 16 `
    --graphicscontroller vmsvga `
    --firmware bios `
    --boot1 disk `
    --boot2 dvd `
    --boot3 none `
    --boot4 none `
    --audio-enabled off `
    --usb-ohci off `
    --usb-ehci off `
    --usb-xhci off `
    --nic1 nat `
    --cable-connected1 on `
    --nic2 hostonly `
    --host-only-adapter2 'VirtualBox Host-Only Ethernet Adapter' `
    --nic-promisc2 allow-vms `
    --cable-connected2 on

Invoke-VBox modifyvm $VmName --nat-pf1 'ssh,tcp,127.0.0.1,2222,,22'
Invoke-VBox storagectl $VmName --name 'SATA Controller' --add sata --controller IntelAhci
Invoke-VBox createmedium disk --filename $diskPath --size 12288 --format VDI
Invoke-VBox storageattach $VmName `
    --storagectl 'SATA Controller' `
    --port 0 `
    --device 0 `
    --type hdd `
    --medium $diskPath

Invoke-VBox unattended install $VmName `
    --iso=$IsoPath `
    --user=ansible `
    --password-file=$PasswordFile `
    --full-user-name='Ansible Administrator' `
    --locale=en_US `
    --country=MA `
    --time-zone=Africa/Casablanca `
    --hostname=debian-ha-template.lab.local `
    --package-selection-adjustment=minimal `
    --script-template=$PreseedTemplate `
    --no-install-additions `
    --start-vm=headless

Write-Output "Unattended installation started for $VmName."

