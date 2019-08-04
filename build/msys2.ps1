#!/usr/bin/env powershell

<#
.SYNOPSIS
    Downloads msys2
.DESCRIPTION
    written for mabs specific environment
#>
#requires -version 4.0
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$SuiteDir = $(Resolve-Path -Path "$PSScriptRoot/.."),
    [ValidateNotNullOrEmpty()]
    [string]$BuildDir = $(Resolve-Path -Path "$PSScriptRoot")
)

Set-Location $buildDir

if (Test-Path -PathType Leaf "$suiteDir/msys64/usr/bin/msys-2.0.dll") { exit 0 }

Write-Host "$("-"*79)"
Write-Host "- Download msys2 basic system`n"
Write-Host "$("-"*79)`n"

[string]$msysSFX = "$buildDir/msys2-base.sfx.exe"
. $PSScriptRoot/helper.ps1
$ProgressPreference = 'SilentlyContinue'

if (-not (
        Invoke-Wget -OutFile "$msysSFX" -Uri "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe")
    ) {
    Write-Host "$("-"*79)`n"
    Write-Host "- Download msys2 basic system failed,"
    Write-Host "- please download it manually from:"
    Write-Host "- http://repo.msys2.org/distrib/"
    Write-Host "- extract and put the msys2 folder into"
    Write-Host "- the root media-autobuid_suite folder"
    Write-Host "- and start the batch script again!"
    Write-Host "$("-"*79)`n"
    exit $false
}

Write-Host "$("-"*79)"
Write-Host "- unpacking msys2 basic system`n"
Write-Host "$("-"*79)`n"

Invoke-Expression -Command "$msysSFX x -y -o.."
Remove-Item -Force -ErrorAction Ignore $msysSFX
Test-Path -PathType Leaf "$suiteDir/msys64/usr/bin/msys-2.0.dll"
