#!/usr/bin/env powershell

. $PSScriptRoot/helper.ps1

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Wget $args
}