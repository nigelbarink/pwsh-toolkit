Import-Module "$PSScriptRoot/../SampleModule/SampleModule.psd1"

$greeting = Get-Greeting -Name 'PowerShell'
Write-Output $greeting

$fullName = Format-Name -FirstName 'John' -LastName 'Doe'
Write-Output $fullName
