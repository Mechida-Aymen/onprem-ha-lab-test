param(
    [string]$PrivateKey = "$env:USERPROFILE\.ssh\id_ed25519"
)

$ErrorActionPreference = 'Continue'
$vboxManage = 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe'
$ssh = 'C:\Windows\System32\OpenSSH\ssh.exe'
$scp = 'C:\Windows\System32\OpenSSH\scp.exe'

function Invoke-VBox {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & $vboxManage @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "VBoxManage failed with exit code ${LASTEXITCODE}: $($Arguments -join ' ')"
    }
}

function Invoke-Ssh {
    param(
        [int]$Port,
        [string]$Command
    )

    & $ssh `
        -o BatchMode=yes `
        -o StrictHostKeyChecking=no `
        -o UserKnownHostsFile=NUL `
        -o ConnectTimeout=5 `
        -i $PrivateKey `
        -p $Port `
        ansible@127.0.0.1 `
        $Command

    if ($LASTEXITCODE -ne 0) {
        throw "SSH command failed on temporary port $Port."
    }
}

function Wait-Ssh {
    param(
        [int]$Port,
        [int]$Attempts = 30
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        & $ssh `
            -o BatchMode=yes `
            -o StrictHostKeyChecking=no `
            -o UserKnownHostsFile=NUL `
            -o ConnectTimeout=3 `
            -i $PrivateKey `
            -p $Port `
            ansible@127.0.0.1 `
            true 2>$null

        if ($LASTEXITCODE -eq 0) {
            return
        }

        Start-Sleep -Seconds 4
    }

    throw "SSH did not become ready on temporary port $Port."
}

if (-not (Test-Path -LiteralPath $PrivateKey)) {
    throw "SSH private key not found: $PrivateKey"
}

$targets = @(
    @{ Name = 'web01'; Address = '192.168.56.11'; SshPort = 2201 },
    @{ Name = 'web02'; Address = '192.168.56.12'; SshPort = 2202 },
    @{ Name = 'db01';  Address = '192.168.56.31'; SshPort = 2231 },
    @{ Name = 'db02';  Address = '192.168.56.32'; SshPort = 2232 }
)

foreach ($target in $targets) {
    $name = $target.Name
    $port = $target.SshPort
    $networkFile = Join-Path $PSScriptRoot "..\bootstrap\network\$name.interfaces"

    Write-Output "Starting $name..."
    $currentState = & $vboxManage showvminfo $name --machinereadable |
        Select-String '^VMState='
    if ($currentState.ToString() -eq 'VMState="poweroff"') {
        Invoke-VBox startvm $name --type headless
    }
    elseif ($currentState.ToString() -eq 'VMState="running"') {
        Write-Output "$name is already running; resuming bootstrap."
    }
    else {
        throw "$name is in unsupported state $currentState."
    }
    Wait-Ssh -Port $port

    & $scp `
        -o BatchMode=yes `
        -o StrictHostKeyChecking=no `
        -o UserKnownHostsFile=NUL `
        -i $PrivateKey `
        -P $port `
        $networkFile `
        'ansible@127.0.0.1:/tmp/interfaces'

    if ($LASTEXITCODE -ne 0) {
        throw "Could not copy network configuration to $name."
    }

    $configure = "sudo install -o root -g root -m 0644 /tmp/interfaces /etc/network/interfaces; " +
        "sudo hostnamectl set-hostname $name; " +
        "sudo sed -i 's/^127\.0\.1\.1.*/127.0.1.1 $name/' /etc/hosts; " +
        "sudo rm -f /var/lib/dbus/machine-id; " +
        "sudo truncate -s 0 /etc/machine-id; " +
        "sudo systemd-machine-id-setup; " +
        "sudo rm -f /etc/ssh/ssh_host_*; " +
        "sudo ssh-keygen -A"

    Invoke-Ssh -Port $port -Command $configure
    & $ssh `
        -o BatchMode=yes `
        -o StrictHostKeyChecking=no `
        -o UserKnownHostsFile=NUL `
        -o ConnectTimeout=5 `
        -i $PrivateKey `
        -p $port `
        ansible@127.0.0.1 `
        'sudo reboot' 2>$null

    Start-Sleep -Seconds 8
    Wait-Ssh -Port $port

    $verify = "hostname | grep -Fx '$name'; " +
        "ip -4 -br addr show enp0s8 | grep -F '$($target.Address)/24'; " +
        "systemctl is-active --quiet ssh; " +
        "sudo -n true"

    Invoke-Ssh -Port $port -Command $verify
    & $ssh `
        -o BatchMode=yes `
        -o StrictHostKeyChecking=no `
        -o UserKnownHostsFile=NUL `
        -o ConnectTimeout=5 `
        -i $PrivateKey `
        -p $port `
        ansible@127.0.0.1 `
        'sudo poweroff' 2>$null

    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $state = & $vboxManage showvminfo $name --machinereadable |
            Select-String '^VMState='
        if ($state.ToString() -eq 'VMState="poweroff"') {
            break
        }
        Start-Sleep -Seconds 2
    }

    if ($state.ToString() -ne 'VMState="poweroff"') {
        throw "$name did not power off after configuration."
    }

    Write-Output "$name configured and verified."
}

Write-Output 'All four VMs were bootstrapped successfully.'

