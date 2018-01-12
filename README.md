# IisExpressFunctions.ps1

PowerShell utility functions to work with IIS Express relying on
appcmd.exe. I'm using Pester PowerShell PS Unit tests.

## Installing Pester

* Windows 10

        Install-Module Pester

* Other Operating Systems - Use <http://chocolatey.org>

        choco install pester

## Running PowerShell unit tests with Pester

It's possible to run them from command line but more convenient way is to use Visual Studio code
(ensure that PowerShell extension is installed). Special codelens "Run tests" and "Debug tests"
will appear in PowerShell source files.

PS Command line

    Set-Location test

    # Using dot source
    . .\IisExpressFunctions.Tests.ps1
    # Or
    Invoke-Pester