[CmdletBinding()]
param (
  [Parameter(Mandatory = $true)]
  [string]$WorkingDirectory
)

function Get-Packages {
  param (
  )
  Write-Host "Getting packages from Nuget"

  $repositoryUrl = 'https://github.com/dailydevops'
  $queryUrl = 'https://api-v2v3search-0.nuget.org/query?q=NetEvolve'
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

  $result = @'

<table>
  <thead>
    <tr>
      <td><b>Package Name</b></td>
      <td><b>Repository</b></td>
      <td><b>Details</b></td>
    </tr>
  </thead>
  <tbody>

'@

  foreach ($package in ($data.data | Sort-Object -Property id)) {
    if (-Not $package.projectUrl.StartsWith($repositoryUrl)) {
      continue
    }

    $description = $package.description;

    $result += @"
    <tr>
      <td><a href="https://www.nuget.org/packages/$($package.id)/"><b>$($package.title)</b></a></td>
      <td><a href="$($package.projectUrl)">$($package.projectUrl)</a></td>
      <td>
        <a href="https://www.nuget.org/packages/$($package.id)/">
          <img src="https://img.shields.io/nuget/dt/$($package.id)?logo=nuget" alt="$($package.id) Downloads" />
          <img src="https://img.shields.io/nuget/v/$($package.id)?logo=nuget" alt="$($package.id) Version" />
        </a>
      </td>
    </tr>
    <tr>
      <td colspan=3>$($description)</td>
    </tr>

"@
  }

  $result += @'
  </tbody>
</table>

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
