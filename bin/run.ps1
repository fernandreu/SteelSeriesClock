. "$PSScriptRoot\install.ps1"

function Start-App {
    if (-not (Test-PythonInstallation)) {
        Start-PythonInstallation
    }

    & "$PSScriptRoot\..\dist\python.exe" "$PSScriptRoot\..\main.py"
}

if ($MyInvocation.InvocationName -ne '.') {
    Start-App
}
