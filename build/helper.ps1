#!/usr/bin/env powershell
#requires -version 4.0

function Invoke-Wget {
    <#
    .SYNOPSIS
        Wrapper around Invoke-WebRequest that tries to guess the filename based on Url
    .DESCRIPTION
        Tries to get a filename based on the Content-Disposition header or getting the leaf of the url.
        c.f. do_wget in media-suite_helper.sh
    .INPUTS
        None.
    .PARAMETER Uri
        Uri that to be passed to Invoke-WebRequest
    .PARAMETER OutFile
        File to download the Uri to
    .LINK
        https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
    .EXAMPLE
        Invoke-Wget -Uri "https://patchwork.ffmpeg.org/series/1111/mbox/"
    .EXAMPLE
        Invoke-Wget -Uri "http://gist.githubusercontent.com/1480c1/65512f45c343919299697aa778dc50b8/raw/0001-qtbase-mabs.patch"
    .EXAMPLE
        Invoke-Wget -Uri "https://raw.githubusercontent.com/PoshCode/PowerShellPracticeAndStyle/master/Best-Practices/TODO.md" -OutFile "todo.md"
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,
        [Parameter(Position = 1)]
        [Alias("o")]
        [string]$OutFile = ""
    )
    begin {
        if ($OutFile.Length -eq 0) {
            $Headers = (Invoke-WebRequest -Uri "$Uri").Headers
            if ($Headers.'Content-Disposition'.Length -ne 0) {
                $OutFile = [System.Net.Mime.ContentDisposition]::new($Headers.'Content-Disposition').FileName
            } else {
                $OutFile = Split-Path -Leaf "$Uri"
            }
        }
        # We should at least have a filename candidate by now.
    }
    process {
        Invoke-WebRequest -UseBasicParsing -Uri "$Uri" -OutFile "$OutFile"
        Test-Path -PathType Leaf "$OutFile"
    }
}

function Invoke-Bash {
    [CmdletBinding()]
    param (
        [char]$noMintty = 'n',
        [String]$Bash = "bash",
        [String]$LogFile,
        [String]$args
    )

    begin {

    }

    process {
        if ($args.Length -eq 0) {
            return $false
        }
        & "$Bash" -lc "$args"
    }

    end {

    }
}