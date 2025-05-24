class ModuleManager {
    [string]$FilePath
    [psobject]$FileContent
    [string]$ScriptRoot

    ModuleManager([string]$path, [string]$scriptRoot) {
        $this.FilePath = $path
        $this.ScriptRoot = $scriptRoot
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
    
    [object] GetFile([string]$Path) {
        $content = Get-Content -Path (Join-Path -Path $this.ScriptRoot -ChildPath $Path) -Raw
        return $content
    }

    [void] SetFile([string]$Path, $Value) {
        $fullpath = Join-Path -Path $this.ScriptRoot -ChildPath $Path
        if (-not (Test-Path -Path $fullpath)) {
            New-Item -Path $fullPath -Force
        }
        Set-Content -Path $fullPath -Value $Value
    }

    [object] Get([string[]]$PathKeys, [switch]$Force) {

        if (-not ($PathKeys.Count -gt 1)) {
            if (-not $Force) { $this.ValidateProperty($PathKeys[0]) }
        }
        else {
            $this.ValidatePath($PathKeys, $Force)
        }

        $currentObj = $this.FileContent 

        foreach ($key in $PathKeys) {
            $currentObj = $currentObj.$key
        }

        return $currentObj
    }

    [void] Set([string[]]$PathKeys, $Value, [switch]$Force) {

        if (-not ($PathKeys.Count -gt 1)) {
            $key = $PathKeys[0]
            if (-not $this.FileContent.$key) {
                $this.FileContent | Add-Member -Membertype NoteProperty -Name $key -Value $Value -Force
            }
            $this.FileContent.$key = $Value
        }
        else {
            $pathKeysWithoutLast = $PathKeys[0..($PathKeys.Count - 2)]
            $this.ValidatePath($pathKeysWithoutLast, $Force)

            $currentObj = $this.FileContent

            for ($i = 0; $i -lt $PathKeys.Count - 1; $i++) {
                $currentObj = $currentObj.$($PathKeys[$i])
            }

            $finalKey = $PathKeys[-1]
            $currentObj.$finalKey = $Value
        }

        $this.Save()
    }

    [void] ValidateProperty([string]$Property) {
        if (-not ($this.FileContent.PSObject.Properties.Name -contains $Property)) {
            throw "Property $Property does not exist on $($this.FilePath)."
        }
    }
    
    [void] ValidatePath([string[]]$PathKeys, [switch]$Force) {
        $currentObj = $this.FileContent

        foreach ($key in $PathKeys) {
            if ($Force -and -not $currentObj.$key) {
                $currentObj | Add-Member -Membertype NoteProperty -Name $key -Value (@{}) -Force
            }
            elseif (-not ($currentObj.$key -is [hashtable] -or $currentObj.$key -is [psobject] -or $currentObj.$key -is [array])) {
                throw "Failed to parse key: $key as a hashtable, PSObject or array."
            }

            $currentObj = $currentObj.$key
        }
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

    return [ModuleManager]::new($filePath, $ScriptRoot)
}

Export-ModuleMember -Function PSModuleManager
