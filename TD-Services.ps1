### Services

function Get-TDService
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Article ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID',
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # ID of application for client portal app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $ClientPortalID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )
    DynamicParam
    {
        #List dynamic parameters
        $DynamicParameterList = @(
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDClient',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($WorkingEnvironment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_ServiceCatalog_Service'
            AllEndpoint      = '$AppID/services'
            IDEndpoint       = '$AppID/services/$ID'
            AppID            = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-Get
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDServiceOffering
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # The ID of the service offering.
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [Int32]
        $ID,

        # The ID of the service offering.
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [Int32]
        $ServiceID,

        # The ID of the client portal application associated with the service offering.
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [Int32]
        $AppID = $ClientPortalID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )
    DynamicParam
    {
        #List dynamic parameters
        $DynamicParameterList = @(
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDClient',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ServiceName'
                Type        = 'string'
                ValidateSet = (Get-TDService).Name
                HelpText    = 'Name of parent service'
                IDParameter = 'ServiceID'
                IDsMethod   = 'Get-TDService'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        #Pre-check required parameter(s)
        if ($null -eq $DynamicParameterDictionary.ServiceName.Value -and $ServiceID -eq 0)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Must provide either the service name or ID.'
        }
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_ServiceCatalog_ServiceOffering'
            AllEndpoint      = $null
            IDEndpoint       = '$AppID/services/$ServiceID/offerings/$ID'
            AppID            = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-Get
        return $Return
    }
    End
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}