enum Platform {
    x86
    x64
}

function Get-DefaultDistFolder {
    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../dist'))
}

function Test-PythonInstallation {
    [OutputType([Bool])]
    param(
        [Parameter()]
        [String] $DistFolder = $null
    )

    if ([string]::IsNullOrWhiteSpace($DistFolder)) {
        $DistFolder = Get-DefaultDistFolder
    }

    if (-not (Test-Path -Path $DistFolder -PathType Container)) {
        return $false
    }

    $exePath = Join-Path $DistFolder 'python.exe'
    return (Test-Path -Path $exePath -PathType Leaf)
}

function Start-PythonDownload {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Version,

        [Parameter(Mandatory = $true)]
        [Platform] $Platform,

        [Parameter(Mandatory = $true)]
        [String] $DistFolder
    )

    Write-Host "Downloading Python $Version to: $DistFolder" -ForegroundColor Green

    if ($Platform -eq [Platform]::x86) {
        $platformString = 'win32'
    } else {
        $platformString = 'amd64'
    }

    $uri = "https://www.python.org/ftp/python/$Version/python-$Version-embed-$platformString.zip"
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.IO.Path]::GetRandomFileName()).zip"

    try {
        Invoke-WebRequest -Uri $uri -OutFile $tempPath
        Expand-Archive -Path $tempPath -DestinationPath $DistFolder
    } finally {
        Remove-Item -Path $tempPath -Force -ErrorAction Ignore
    }
}

function Update-PthFile {
    param(
        [Parameter(Mandatory = $true)]
        [String] $Version,

        [Parameter(Mandatory = $true)]
        [String] $DistFolder
    )

    Write-Host 'Updating ._pth file' -ForegroundColor Green

    $parts = $Version.Split('.')
    $path = Join-Path $DistFolder "python$($parts[0])$($parts[1])._pth"
    $content = Get-Content -Path $path
    $content = $content.Replace('#import', 'import')

    # File has to be written back with the same encoding, i.e. UTF-8 no BOM. Other methods might not produce that result
    [System.IO.File]::WriteAllLines($path, $content)
}

function Start-PipInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $DistFolder
    )

    Write-Host 'Installing pip' -ForegroundColor Green

    $uri = 'https://bootstrap.pypa.io/get-pip.py'
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "$([System.IO.Path]::GetRandomFileName()).py"
    $exePath = Join-Path $DistFolder 'python.exe'

    try {
        Invoke-WebRequest -Uri $uri -OutFile $tempPath
        Start-Process -FilePath $exePath -ArgumentList $tempPath -Wait -NoNewWindow
    } finally {
        Remove-Item -Path $tempPath -Force -ErrorAction Ignore
    }
}

function Start-PackageInstallation {
    param(
        [Parameter(Mandatory = $true)]
        [String] $DistFolder
    )

    Write-Host 'Installing Python packages' -ForegroundColor Green
    $exePath = Join-Path $DistFolder 'Scripts/pip.exe'
    $requierementsPath = Join-Path $PSScriptRoot '../requirements.txt'
    Start-Process -FilePath $exePath -ArgumentList 'install','-r',$requierementsPath -Wait -NoNewWindow
}

function Start-PythonInstallation {
    param(
        [Parameter()]
        [String] $Version = '3.8.7',

        [Parameter()]
        [Platform] $Platform = [Platform]::x64
    )

    $distFolder = Get-DefaultDistFolder
    if (Test-PythonInstallation -DistFolder $distFolder) {
        Write-Host "There is a Python distribution already in '$distFolder'. Skipping Python/Pip installation" -ForegroundColor Yellow
    } else {
        Start-PythonDownload -Version $Version -Platform $Platform -DistFolder $distFolder
        Update-PthFile -Version $Version -DistFolder $distFolder
        Start-PipInstallation -DistFolder $distFolder
    }

    Start-PackageInstallation -DistFolder $distFolder
    Write-Host 'Installation completed' -ForegroundColor Green
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-PythonInstallation
}
