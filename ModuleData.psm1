class DataManager {
    [string]$SettingsPath
    [psobject]$Settings

    DataManager([string]$path) {
        $this.SettingsPath = $path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.SettingsPath)) {
            throw "Config file not found at $($this.SettingsPath)."
        }

        try {
            $this.Settings = Get-Content -Path $this.SettingsPath -Raw | ConvertFrom-Json -Depth 7
        }
        catch {
            throw "Failed to parse settings file: $_."
        }
    }

    [void] SaveSettings() {
        $this.Settings | ConvertTo-Json -Depth 7 | Set-Content -Path $this.SettingsPath
    }
    
    [void] AddSetting($Key, $Value) {
        $this.Settings | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        $this.Save()
    }
}

function ModuleData($ModulePath) {

    $settingsPath = Join-Path -Path $ModulePath -ChildPath 'settings.json'

    if (-not (Test-Path -Path $settingsPath)) {
        @{} | ConvertTo-Json -Depth 7 | Set-Content -Path $settingsPath -Encoding UTF8
    }

    return [DataManager]::new($settingsPath)
}

Export-ModuleMember -Function ModuleData
