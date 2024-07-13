[CmdletBinding()]
[OutputType([System.Collections.Hashtable])]
param(
    [Parameter(Mandatory = $true)]
    [string]$CurrentTag
)

$tags = git tag --list "v*" --sort=-version:refname
$nearestReleaseTag = $null
$nearestPreReleaseTag = $null
$reachedCurrentTag = $false
$currentIsPreRelease = $false

foreach ($tag in $tags) {
    try {
        [semver]$version = $tag -replace '^v'
    }
    catch { continue }

    if ($CurrentTag -eq $tag) {
        Write-Verbose "Reached current tag: $tag - Starting to collect version details"
        $reachedCurrentTag = $true
        $currentIsPreRelease = $null -ne $version.PreReleaseLabel
    }
    elseif ($reachedCurrentTag -eq $true) {
        try {
            [semver]$version = $tag -replace '^v'
        }
        catch { continue }

        if ($version.PreReleaseLabel) {
            if ($null -eq $nearestPreReleaseTag) {
                Write-Verbose "Found nearest pre-release tag: $tag"
                $nearestPreReleaseTag = $tag
            }
        }
        else {
            Write-Verbose "Found nearest release tag: $tag"
            $nearestReleaseTag = $tag
            # Only go back to the latest release tag
            break
        }
    }
}

return [ordered]@{
    nearestReleaseTag     = $nearestReleaseTag
    nearestPreReleaseTag  = $nearestPreReleaseTag
    previousPreReleaseTag = $previousPreReleaseTag
}
