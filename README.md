# IisExpressFunctions.ps1

PowerShell utility functions to work with IIS Express relying on
appcmd.exe. I'm using Pester PowerShell Unit tests.

[![Build status](https://ci.appveyor.com/api/projects/status/ipk4ue9vb0jdnd9v/branch/master?svg=true)](https://ci.appveyor.com/project/gbfsoft/ps-iisexpress/branch/master)

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