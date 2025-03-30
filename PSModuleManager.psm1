class ModuleManager {
    [string]$FilePath
    [psobject]$FileContent

    ModuleManager([string]$path) {
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
    
    [void] Set([string[]]$PathKeys, $Value) {

        if (-not $PathKeys -or $PathKeys.Count -lt 1) { throw "PSModuleManager: Set() requires a non-empty path-array." }
        $currentObject = $this.FileContent

        for ($i = 0; $i -lt $PathKeys.Count - 1; $i++) {
            $key = $PathKeys[$i]

            if (-not $currentObject.$Key) {
                $currentObject | Add-Member -Membertype NoteProperty -Name $key -Value (@{}) -Force
            }

            if (-not ($currentObject.$key -is [hashtable] -or $currentObject.$key -is [psobject])) {
                throw "Error: key $key is not a hashtable or PSObject."
            }

            $currentObject = $currentObject.$key
        }

        $finalKey = $PathKeys[-1]
        $currentObject | Add-Member -MemberType NoteProperty -Name $finalKey -Value $Value -Force

        $this.Save()
    }

    [void] Get([string[]]$PathKeys) {

        if (-not $PathKeys -or $PathKeys.Count -lt 1) { throw "PSModuleManager: Get() requires a non-empty path-array." }
        $currentObject = $this.FileContent

        # Work in progress

    }

}

function PSModuleManager() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,

        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    if (-not $ScriptRoot) { throw "Missing script root." }
    if (-not $FileName) { throw "Missing file name." }

    $filePath = Join-Path -Path $ScriptRoot -ChildPath "$FileName.json"

    if (-not (Test-Path -Path $filePath)) {
        @{} | ConvertTo-Json -Depth 7 | Set-Content -Path $filePath -Encoding UTF8
    }

    return [ModuleManager]::new($filePath)
}

Export-ModuleMember -Function PSModuleManager
