class DataManager {
    [string]$FilePath
    [psobject]$FileContent

    DataManager([string]$path) {
        $this.FilePath = $path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.FilePath)) {
            throw "Config file not found at $($this.FilePath)."
        }

        try {
            $this.FileContent = Get-Content -Path $this.FilePath -Raw | ConvertFrom-Json -Depth 7
        }
        catch {
            throw "Failed to parse file: $_."
        }
    }

    [void] Save() {
        $this.FileContent | ConvertTo-Json -Depth 7 | Set-Content -Path $this.FilePath
    }
    
    [void] Add($Key, $Value) {
        $this.FileContent | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        $this.Save()
    }
}

function ModuleData() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModulePath,

        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    if (-not $ModulePath) { throw "Missing module path." }
    if (-not $FileName) { throw "Missing file name." }

    $filePath = Join-Path -Path $ModulePath -ChildPath "$FileName.json"

    if (-not (Test-Path -Path $filePath)) {
        @{} | ConvertTo-Json -Depth 7 | Set-Content -Path $filePath -Encoding UTF8
    }

    return [DataManager]::new($filePath)
}

Export-ModuleMember -Function ModuleData
