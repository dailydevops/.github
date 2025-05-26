[CmdletBinding()]
param (
  [Parameter(Mandatory = $true)]
  [string]$WorkingDirectory
)

function Get-Packages {
  param (
  )
  Write-Host "Getting packages from Nuget"

  $resultData = @()
  $take = 100
  $skip = 0
  $repositoryUrl = 'https://github.com/dailydevops'

  do {
    $queryUrl = "https://azuresearch-usnc.nuget.org/query?q=netevolve&take=$($take)&skip=$($skip)&prerelease=true&semVerLevel=2.0.0"
    $response = Invoke-WebRequest -Uri $queryUrl
    if ($response.statuscode -ne 200) {
      Write-Error "Failed to get packages from $repositoryUrl"
      return
    }

    $data = ConvertFrom-Json $response.Content
    if ($data.totalHits -eq 0) {
      Write-Error "No packages found at $repositoryUrl"
      return
    }

    $skip += $data.data.Length
    $resultData += $data.data

  } while ($skip -lt $data.totalHits)

  $result = @'

<div align="center">
<table>
  <thead>
    <tr>
      <td><b>Package Name</b></td>
      <td style="width:200px"><b>Version</b></td>
    </tr>
  </thead>
  <tbody>

'@

  foreach ($package in ($resultData | Sort-Object -Property id)) {
    if (-Not $package.id.StartsWith("NetEvolve.")) {
      continue
    }

    $deprecated = "";
    if ($package.deprecation) {
      $deprecated += " ❌<b>DEPRECATED</b>"
    }

    $result += @"
    <tr>
      <td>
        <a href="https://www.nuget.org/packages/$($package.id)/"><b>$($package.title)</b></a>$($deprecated)<br/>
        <sup><a href="$($package.projectUrl)">$($package.projectUrl)</a></sup><br/>
        <p>$($package.description)</p>
      </td>
      <td>
        <a href="https://www.nuget.org/packages/$($package.id)/">
          <img src="https://img.shields.io/nuget/v/$($package.id)?logo=nuget&style=for-the-badge" alt="$($package.id) Version" />
        </a>
      </td>
    </tr>

"@
  }

  $result += @'
  </tbody>
</table>
</div>
'@

  return $result
}

function Update-Readme {
  param (
    [Parameter(Mandatory = $true)]
    [string] $workingDirectoy,
    [Parameter(Mandatory = $true)]
    [string] $packagesContent
  )
  Write-Host "Updating README files for $workingDirectoy"

  $tagStart = '<!-- packages:start -->'
  $tagStartLength = $tagStart.Length
  $tagEnd = '<!-- packages:end -->'

  $readmeFiles = Get-ChildItem -Path $workingDirectory -Filter 'README.*' -Recurse -Force

  foreach ($readmeFile in $readmeFiles) {
    Write-Host "Verifying $($readmeFile.FullName)"
    $readmeContent = Get-Content -Path $readmeFile.FullName -Raw

    $startIndex = $readmeContent.IndexOf($tagStart)
    if ($startIndex -eq -1) {
      continue
    }
    $startIndex += $tagStartLength
    $endIndex = $readmeContent.IndexOf($tagEnd, $startIndex)

    if ($endIndex -eq -1) {
      continue
    }

    $readmeContent = $readmeContent.Replace($readmeContent.Substring($startIndex, $endIndex - $startIndex), $packagesContent)

    Write-Host "Updating $($readmeFile.FullName)"
    Set-Content -Path $readmeFile.FullName -Value $readmeContent -NoNewline
  }
}

$packages = Get-Packages
if (![string]::IsNullOrWhiteSpace($packages)) {
  Update-Readme -workingDirectoy $WorkingDirectory -packagesContent $packages
}
