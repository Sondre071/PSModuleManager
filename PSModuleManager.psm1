class ModuleManager {
    [string]$FilePath
    [pscustomobject]$FileContent

    ModuleManager([string]$Path) {
        $this.FilePath = $Path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.FilePath)) {
            throw "No file found at path: `'$($this.FilePath)`'."
        }

        try {
            $this.FileContent = Get-Content -Path $this.FilePath -Raw | ConvertFrom-Json -Depth 7

            Write-Debug "Loaded file path: $($this.FilePath)"
            Write-Debug "Loaded content: $($this.FileContent)"
        }
        catch {
            throw "Failed to parse file: $_."
        }
    }

    [void] Save() {
        $this.FileContent | ConvertTo-Json -Depth 7 | Set-Content -Path $this.FilePath

        Write-Debug "Saved to file path: `'$($this.FilePath).`'"
        Write-Debug "Saved content: `'$($this.FileContent)`'."
    }
}

function PSModuleManager() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$InitialJSONContent
    )

    if (-not ($FilePath -match ".json$")) { throw "File must be of type JSON." }

    if (-not (Test-Path $FilePath)) {
        if ($InitialJSONContent.GetType().Name -eq 'string') {
            $content = $InitialJSONContent | ConvertFrom-Json -Depth 7 | ConvertTo-Json -Depth 7 -Compress
            Set-Content -Path $filePath -Value $content -Encoding UTF8
        }
        else {
            throw 'Invalid file path. No JSON provided as initial file content.'
        }
    }

    $currentFile = Split-Path $PSCommandPath -Leaf
    Write-Debug "Initializing $currentFile"

    return [ModuleManager]::new($FilePath)
}

Export-ModuleMember -Function PSModuleManager
