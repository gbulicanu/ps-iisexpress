$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -Replace '\.Tests\.', '.'
. "$here\..\src\$sut"

Describe "Get-IisExpressAppUrl" {
    BeforeEach {
        Mock Push-Location {}
        Mock Pop-Location {}
    }

    Context "Single Binding" {
        It "Given -Binding '<Binding>', it returns '<Expected>'." -TestCases  @(
            @{ Binding = 'http/:8080:localhost'; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:8080:*'  ; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:80:localhost'  ; Expected = 'http://localhost' }
            @{ Binding = 'https/:443:localhost'   ; Expected = 'https://localhost' }
            @{ Binding = 'https/*:443:'  ; Expected = 'https://localhost' }
            ) {
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
            @{ Binding = 'http/:8080:localhost,*:8443:'; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:8080:*,https/*:8443:'  ; Expected = 'http://localhost:8080' }
            @{ Binding = 'http/:80:localhost,https/*:8443:'  ; Expected = 'http://localhost' }
            @{ Binding = 'https/:443:localhost,https/*:8443:'   ; Expected = 'https://localhost' }
            ) {
            param ($Binding, $Expected)

            Mock Invoke-IisExpressAppCmd { 
                return $Binding 
            }

            $result = Get-IisExpressSiteUrl "App1"

            $result | Should Be $Expected
        }
    }

    Context "Multiple Bindings with HTTPS" {
        It "Given -Binding '<Binding>' and -PreferHttps '<PreferHttps>', it returns '<Expected>'." -TestCases  @(
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
            ) {
            param ($Binding, $PreferHttps, $Expected)

            Mock Invoke-IisExpressAppCmd { 
                return $Binding 
            }

            $result = Get-IisExpressSiteUrl "App1" -PreferHttps $PreferHttps

            $result | Should Be $Expected
        }
    }
}