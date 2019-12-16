# Get-ChildItem . -Filter *.md | Foreach-Object { ./Add-Permalink-Path.ps1 -filePath $_.FullName }
param([string]$filePath)

[int] $lineNumber = 1
[string] $textToAdd = "`npermalink:`t/:categories/:year/:month/:day/:title/"

$fileContent = Get-Content $filePath
$fileContent[$lineNumber-1] += $textToAdd
$fileContent | Set-Content $filePath
