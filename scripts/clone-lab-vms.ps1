param(
    [string]$SourceVm = 'debian-ha-template'
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

$sourceInfo = & $vboxManage showvminfo $SourceVm --machinereadable
if ($LASTEXITCODE -ne 0) {
    throw "Source VM '$SourceVm' does not exist."
}
if ($sourceInfo -notcontains 'VMState="poweroff"') {
    throw "Source VM '$SourceVm' must be powered off before cloning."
}

$targets = @(
    @{ Name = 'web01'; Memory = 768; SshPort = 2201 },
    @{ Name = 'web02'; Memory = 768; SshPort = 2202 },
    @{ Name = 'db01';  Memory = 1024; SshPort = 2231 },
    @{ Name = 'db02';  Memory = 1024; SshPort = 2232 }
)

foreach ($target in $targets) {
    $registeredVms = & $vboxManage list vms
    $registeredVmText = $registeredVms -join "`n"
    if ($registeredVmText -notmatch ('(?m)^"' + [regex]::Escape($target.Name) + '"\s')) {
        Write-Output "Creating full clone $($target.Name)..."
        Invoke-VBox clonevm $SourceVm --name $target.Name --mode machine --register
    }
    else {
        Write-Output "Resuming configuration for existing clone $($target.Name)..."
    }

    Invoke-VBox modifyvm $target.Name --memory $target.Memory
    $targetInfo = & $vboxManage showvminfo $target.Name --machinereadable
    if ($targetInfo -match 'Forwarding\(0\)="ssh,') {
        Invoke-VBox modifyvm $target.Name --nat-pf1 delete ssh
    }
    Invoke-VBox modifyvm $target.Name --nat-pf1 "ssh,tcp,127.0.0.1,$($target.SshPort),,22"
}

Write-Output 'All four lab VMs were cloned and registered.'

