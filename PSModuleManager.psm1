function PSModuleManager() {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$InitialJSONContent
    )

    if (-not ($FilePath -match ".json$")) { throw "File must be of type JSON." }

    if (-not (Test-Path $FilePath)) {
        if ($InitialJSONContent -ne '') {
            $content = $InitialJSONContent | ConvertFrom-Json -Depth 7 | ConvertTo-Json -Depth 7 -Compress
            Set-Content -Path $filePath -Value $content -Encoding UTF8
        }
        else {
            throw 'No JSON provided to populate initial file.'
        }
    }

    $obj = (Get-Content -Path $FilePath) | ConvertFrom-Json -Depth 5 -AsHashTable

    if ($obj.PSObject.Properties.Name.Contains('Save')) {
        throw "JSON cannot contain a property named `'Save`' at root level."
    }

    $obj | Add-Member -Membertype NoteProperty -Name _savePath -Value $FilePath

    $obj | Add-Member -MemberType ScriptMethod -Name Save -Value {
        $json = ($this | Select-Object -ExcludeProperty _savePath | ConvertTo-Json -Depth 7)

        Set-Content -Path $this._savePath -Value $json
    }

    return $obj
}

Export-ModuleMember -Function PSModuleManager
