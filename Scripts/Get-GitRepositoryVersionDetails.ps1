<#PSScriptInfo
.VERSION 1.0.0
.GUID e06d5fa2-ec5b-4e2e-aa53-2f1245952467
.AUTHOR Julian Pawlowski
.COMPANYNAME Workoho
#>

<#
.SYNOPSIS
    Get the nearest historical release and pre-release tags for the current tag in a Git repository.
.DESCRIPTION
    This script gets the nearest historical release and pre-release tags for the current tag in a Git repository.
    The script requires Git to be installed and in the PATH.
.PARAMETER CurrentTag
    The current tag to get the nearest historical release and pre-release tags for.
.OUTPUTS
    System.Collections.Hashtable
    An ordered hashtable with the following keys:
    - nearestReleaseTag: The nearestScripts release tag.
    - nearestPreReleaseTag: The nearest pre-release tag in case the current tag is a pre-release tag.
#>

#Requires -Version 7.2

[CmdletBinding()]
[OutputType([System.Collections.Hashtable])]
param(
    [Parameter(Mandatory = $true)]
    [string]$CurrentTag
)

try {
    $null = [semver]::new($CurrentTag -replace '^v')
}
catch {
    Write-Error "Invalid version tag: $CurrentTag" -ErrorAction Stop
    exit 1
}

try {
    $null = git --version
}
catch {
    Write-Error "Git is not installed or not in the PATH" -ErrorAction Stop
    exit 1
}

$tags = git tag --list "v*" --sort=-version:refname

if ($tags.Count -eq 0) {
    Write-Error "No version tags found in the repository" -ErrorAction Stop
    exit 1
}

if ($tags -notcontains $CurrentTag) {
    Write-Error "Current tag '$CurrentTag' not found in the repository" -ErrorAction Stop
    exit 1
}

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
            if (
                $currentIsPreRelease -and
                $null -eq $nearestPreReleaseTag
            ) {
                Write-Verbose "Found nearest pre-release tag for current pre-release: $tag"
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
    nearestReleaseTag    = $nearestReleaseTag
    nearestPreReleaseTag = $nearestPreReleaseTag
}
