### Services

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
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}