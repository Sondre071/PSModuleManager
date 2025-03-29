class SettingsManager {
    [string]$SettingsPath
    [psobject]$Data

    SettingsManager([string]$path) {
        $this.SettingsPath = $path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.SettingsPath)) {
            throw "Config file not found at $($this.SettingsPath)."
        }

        try {
            $this.Data = Get-Content -Path $this.SettingsPath -Raw | ConvertFrom-Json -Depth 7
        }
        catch {
            throw "Failed to parse settings file: $_."
        }
    }

    [void] Save() {
        $this.Data | ConvertTo-Json -Depth 7 | Set-Content -Path $this.SettingsPath
    }
    
    [void] Add($Key, $Value) {
        $this.Data | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        $this.Save()
    }
}

function ModuleSettings($ModulePath) {

    $settingsPath = Join-Path -Path $ModulePath -ChildPath 'settings.json'

    if (-not (Test-Path -Path $settingsPath)) {
        @{} | ConvertTo-Json -Depth 7 | Set-Content -Path $settingsPath -Encoding UTF8
    }

    return [SettingsManager]::new($settingsPath)
}

Export-ModuleMember -Function ModuleSettings
