class ModuleManager {
    [string]$FilePath
    [psobject]$FileContent

    ModuleManager([string]$path) {
        $this.FilePath = $path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.FilePath)) {
            throw "Failed to find config file at $($this.FilePath)."
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
    

    [psobject] Get([string[]]$PathKeys) {

        if (-not $PathKeys -or $PathKeys.Count -lt 1) { throw "An array of valid path keys not provided." }
        $currentObject = $this.FileContent

        for ($i = 0; $i -lt $PathKeys.Count - 1; $i++) {
            $key = $PathKeys[$i]

            if (-not $currentObject.$Key) {
                $currentObject | Add-Member -Membertype NoteProperty -Name $key -Value (@{}) -Force
            }

            if (-not ($currentObject.$key -is [hashtable] -or $currentObject.$key -is [psobject])) {
                throw "Failed to parse key: $key as a hashtable or PSObject."
            }

            $currentObject = $currentObject.$key
        }

        $finalKey = $PathKeys[-1]

        return $currentObject.$finalKey

    }

    [void] Set([string[]]$PathKeys, $Value) {

        if (-not $PathKeys -or $PathKeys.Count -lt 1) { throw "An array of valid path keys not provided." }
        $currentObject = $this.FileContent

        for ($i = 0; $i -lt $PathKeys.Count - 1; $i++) {
            $key = $PathKeys[$i]

            if (-not $currentObject.$Key) {
                $currentObject | Add-Member -Membertype NoteProperty -Name $key -Value (@{}) -Force
            }

            if (-not ($currentObject.$key -is [hashtable] -or $currentObject.$key -is [psobject])) {
                throw "Failed to parse key: $key as a hashtable or PSObject."
            }

            $currentObject = $currentObject.$key
        }

        $finalKey = $PathKeys[-1]
        $currentObject | Add-Member -MemberType NoteProperty -Name $finalKey -Value $Value -Force

        $this.Save()
    }
}

function PSModuleManager() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptRoot,

        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    if (-not $ScriptRoot) { throw "PSScriptRoot not provided." }
    if (-not $FileName) { throw "File name not provided." }

    $filePath = Join-Path -Path $ScriptRoot -ChildPath "$FileName.json"

    if (-not (Test-Path -Path $filePath)) {
        @{} | ConvertTo-Json -Depth 7 | Set-Content -Path $filePath -Encoding UTF8
    }

    return [ModuleManager]::new($filePath)
}

Export-ModuleMember -Function PSModuleManager
