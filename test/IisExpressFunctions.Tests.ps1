$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace '\.Tests\.', '.'
. "$here\..\src\$sut"

Describe "Invoke-IisExpressAppCmd" {
    BeforeEach {
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock Set-Location {}
    }

    Context "With text:bindings as parameters" {
        Mock Invoke-Expression {
            param ([string]$Command)
            
            return $Command;
        }

        It "Invokes appcmd.exe with parameters passed" {
            $siteIdentifier = "Site1"
            $objectType = [IisExpressObjectType]::Site
            $command = "list"
            $result = Invoke-IisExpressAppCmd $siteIdentifier `
                $objectType $command -Parameters @{ text = "bindings"; }

            $result | Should `
                -Be ".\appcmd $command $($objectType.ToString().ToUpper()) $(
                    )""$siteIdentifier"" /text:bindings"
        }
    }

    Context "Without Parameters" {
        Mock Invoke-Expression {
            param ([string]$Command)
            
            return $Command;
        }

        It "Invokes appcmd.exe with default /text:* param" {
            $siteIdentifier = "Site1"
            $objectType = [IisExpressObjectType]::Site
            $command = "list"
            $result = Invoke-IisExpressAppCmd $siteIdentifier `
                $objectType $command

            $result | Should `
                -Be ".\appcmd $command $($objectType.ToString().ToUpper()) $(
                    )""$siteIdentifier"" /text:*"
        }
    }

    Context "In-Existent Objects" {
        Mock Invoke-Expression {
            return $null;
        }

        It "Returns empty or null string" {
            $siteIdentifier = "Unknown1"
            $objectType = [IisExpressObjectType]::Site
            $command = "list"
            $result = Invoke-IisExpressAppCmd $siteIdentifier $objectType $command

            $result | Should -BeNullOrEmpty
        }
    }
}
Describe "Get-IisExpressAppUrl" {
    BeforeEach {
        Mock Push-Location {}
        Mock Pop-Location {}
        Mock Set-Location {}
    }

    Context "Single Binding" {
        It "Given -Binding '<Binding>', it returns '<Expected>'." -TestCases  @(
            @{ Binding = 'http/:8080:localhost'; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:8080:*'  ; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:80:localhost'  ; Expected = 'http://localhost' }
            @{ Binding = 'https/:443:localhost'   ; Expected = 'https://localhost' }
            @{ Binding = 'https/*:443:'  ; Expected = 'https://localhost' }
            ) `
        {
            param ($Binding, $Expected)

            Mock Invoke-IisExpressAppCmd { 
                return $Binding 
            }

            $result = Get-IisExpressSiteUrl "App1"

            $result | Should Be $Expected
        }
    }

    Context "Multiple Bindings" {
        It "Given -Binding '<Binding>', it returns '<Expected>'." -TestCases  @(
            @{ 
                Binding = 'http/:8080:localhost,*:8443:';
                Expected = 'http://localhost:8080' }
            @{
                Binding = 'http/:8080:*,https/*:8443:';
                Expected = 'http://localhost:8080' }
            @{
                Binding = 'http/:80:localhost,https/*:8443:';
                Expected = 'http://localhost' }
            @{
                Binding = 'https/:443:localhost,https/*:8443:';
                Expected = 'https://localhost' }) `
        {
            
            param ($Binding, $Expected)

            Mock Invoke-IisExpressAppCmd { 
                return $Binding 
            }

            $result = Get-IisExpressSiteUrl "App1"

            $result | Should Be $Expected
        }
    }

    Context "Multiple Bindings with HTTPS" {
        It "Given -Binding '<Binding>' and -PreferHttps '<PreferHttps>', $(
            )it returns '<Expected>'." `
            -TestCases  @(
            @{
                Binding = 'http/:80:localhost,https/*:8443:';
                PreferHttps = $true;
                Expected = 'https://localhost:8443' }
            @{ 
                Binding = 'https/:443:localhost,http/*:9001:';
                PreferHttps = $false;
                Expected = 'https://localhost' }
            @{ 
                Binding = 'https/:443:localhost,http/*:9001:';
                PreferHttps = $true;
                Expected = 'https://localhost' }
            ) `
        {

            param ($Binding, $PreferHttps, $Expected)

            Mock Invoke-IisExpressAppCmd { 
                return $Binding 
            }

            $result = if($PreferHttps) { 
                Get-IisExpressSiteUrl "App1" -PreferHttps
            } else {
                Get-IisExpressSiteUrl "App1"
            }

            $result | Should Be $Expected
        }
    }
}

Describe "Remove-IisExpressObject" {
    Context "Invalid Parameters" {
        It "Throws"{
            { Remove-IisExpressObject "" Site } | Should -Throw
            { Remove-IisExpressObject "Id1" Unknown } | Should -Throw
        }
    }

    Context "Valid Parameters" {
        BeforeAll {
            Mock Push-Location {}
            Mock Pop-Location {}
            Mock Set-Location {}
        }

        It "Given -Identifier '<Identifier>' and -ObjectType '<ObjectType>', $(
            )it generates '<Expected>' command" `
            -TestCases @(
            @{
                Identifier = 'WebSite1';
                ObjectType = [IisExpressObjectType]::Site;
                Expected = ".\appcmd delete SITE ""WebSite1"""
            }
            @{
                Identifier = 'WebSite1/App1';
                ObjectType = [IisExpressObjectType]::App;
                Expected = ".\appcmd delete APP ""WebSite1/App1"""
            }

            @{
                Identifier = 'AppPool1';
                ObjectType = [IisExpressObjectType]::AppPool;
                Expected = ".\appcmd delete APPPOOL ""AppPool1"""
            }) `
        {
            param ($Identifier, $ObjectType, $Expected)
            
            Mock Invoke-Expression {
                param ($Command)
                
                return $Command;
            }

            $result = Remove-IisExpressObject $Identifier $ObjectType

            $result | Should -Be $Expected
        }
    }
}

Describe "New-IisExpressObject" {
    Context "Invalid Parameters" {
        It "Throws"{
            { New-IisExpressObject Unknown } | Should -Throw
        }
    }

    Context "Valid Parameters" {
        BeforeAll {
            Mock Push-Location {}
            Mock Pop-Location {}
            Mock Set-Location {}
        }

        It "Given -ObjectType '<ObjectType>', it generates '<Expected>' command" `
            -TestCases @(
            @{
                ObjectType = [IisExpressObjectType]::Site;
                AdditionalParameters = [ordered]@{
                    name = "WebSite1"
                    bindings = "http/*:81:";
                    physicalPath = "C:\d";
                }
                Expected = ".\appcmd add SITE /name:WebSite1 /bindings:http/*:81: $(
                    )/physicalPath:C:\d"
            }
            @{
                ObjectType = [IisExpressObjectType]::App;
                AdditionalParameters = [ordered]@{ 
                    "site.name" = "WebSite1";
                    name = "app1";
                    physicalPath = "C:\d\app1"
                }
                Expected = ".\appcmd add APP /site.name:WebSite1 /name:app1 $(
                    )/physicalPath:C:\d\app1"
            }
            @{
                ObjectType = [IisExpressObjectType]::AppPool;
                AdditionalParameters = @{ 
                    "name" = "apppool1";
                }
                Expected = ".\appcmd add APPPOOL /name:apppool1"
            }) `
        {
            param ($ObjectType, $AdditionalParameters, $Expected)
            
            Mock Invoke-Expression {
                param ($Command)
                
                return $Command;
            }

            $result = New-IisExpressObject $ObjectType $AdditionalParameters

            $result | Should -Be $Expected
        }
    }
}

Describe "Test-IisExpressObject" {
    Context "Invalid Parameters" {
        It "Throws"{
            { Test-IisExpressObject "" Site } | Should -Throw
            { Test-IisExpressObject "Id1" Unknown } | Should -Throw
        }
    }

    Context "Valid Parameters" {
        BeforeAll {
            Mock Push-Location {}
            Mock Pop-Location {}
            Mock Set-Location {}
        }

        It "Given existing object, it returns `$true" {
            $existingSite = "WebSite1"
            $objectType = [IisExpressObjectType]::Site
            
            Mock Invoke-Expression {
                return "WebSite1 exists";
            }

            $result = Test-IisExpressObject $existingSite $objectType

            $result | Should -Be $true
        }

        It "Given in-existent object, it returns `$false" {
            $existingSite = "WebSite1"
            $objectType = [IisExpressObjectType]::Site
            
            Mock Invoke-Expression {
                return "";
            }

            $result = Test-IisExpressObject $existingSite $objectType

            $result | Should -Be $false
        }
    }
}