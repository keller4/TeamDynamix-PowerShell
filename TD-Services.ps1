### Services

<#
.Synopsis
    Get a Service Catalog service in TeamDynamix
.DESCRIPTION
    Get a Service Catalog service in TeamDynamix. Specify the service ID number
    or get a list of all services.
.PARAMETER ID
    Article ID to retrieve from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDService -AuthenticationToken $Authentication

    Retrieves all services from the Service Catalog in TeamDynamix.
.EXAMPLE
    C:\>Get-TDService -ID 1752 -AuthenticationToken $Authentication

    Retrieves Service Catalog service ID 1752 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDService
{
    [CmdletBinding()]
    Param
    (
        # Article ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }
    Process
    {
        #If no ID is specified on commandline, just return all services
        if (-not $ID)
        {
            Write-ActivityHistory 'Retrieving all TeamDynamix Service Catalog services'
            $Return = Invoke-RESTCall -Uri "$BaseURI/services" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        else
        {
            Write-ActivityHistory "Retrieving KnowledgeBase article $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/services/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_ServiceCatalog_Service]::new($_)})
        }
    }
}