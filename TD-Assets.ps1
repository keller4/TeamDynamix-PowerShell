### Assets

function Get-TDAsset
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Asset ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Search text
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [alias('Filter')]
        [string]
        $SearchText,

        # LIKE search for asset serial number and tag
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $SerialLike,

        # Return detailed information on asset
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

        # Return only exact matches on asset search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Exact,

        # Search ID to filter on
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $SavedSearchID,

        # Status IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $StatusIDs,

        # External IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ExternalIDs,

        # In/out of service status to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsInService,

        # Past status IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $StatusIDsPast,

        # Supplier IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $SupplierIDs,

        # Manufacturer IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ManufacturerIDs,

        # Location IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $LocationIDs,

        # Location name substring search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $LocationLike,

        # Room ID filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $RoomID,

        # Room name substring search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $RoomLike,

        # Return only exact RoomLike and LocationLike matches
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $ExactLocation,

        # Parent IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ParentIDs,

        # Contract IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ContractIDs,

        # Exclude contract IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ExcludeContractIDs,

        # Ticket IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $TicketIDs,

        # Form IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $FormIDs,

        # Exclude ticket IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ExcludeTicketIDs,

        # Product model IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ProductModelIDs,

        # Maintenance schedule IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $MaintenanceScheduleIDs,

        # Using department IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $UsingDepartmentIDs,

        # Requesting department IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $RequestingDepartmentIDs,

        # Owning department IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $OwningDepartmentIDs,

        # Past owning deparment IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $OwningDepartmentIDsPast,

        # Using customer IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $UsingCustomerIDs,

        # Requesting customer IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $RequestingCustomerIDs,

        # Owning customer IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $OwningCustomerIDs,

        # Past owning customer IDs filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $OwningCustomerIDsPast,

        # Custom attributes filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [alias('Attributes')]
        [array]
        $CustomAttributes,

        # Minimum purchase cost filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [double]
        $PurchaseCostFrom,

        # Maximum purchase cost filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [double]
        $PurchaseCostTo,

        # Contract provider ID filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ContractProviderID,

        # Oldest acquisition date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $AcquisitionDateFrom = (Get-Date 0),

        # Newest acquisition date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $AcquisitionDateTo = (Get-Date 0),

        # Oldest expected replacement date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ExpectedReplacementDateFrom = (Get-Date 0),

        # Newest acquisition date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ExpectedReplacementDateTo = (Get-Date 0),

        # Oldest contract end date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ContractEndDateFrom = (Get-Date 0),

        # Newest contract end date filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ContractEndDateTo = (Get-Date 0),

        # Only show parent assets filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [boolean]
        $OnlyParentAssets,

        # Number of assets to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $MaxResults = $null,

        # Set ID of application for asset
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
                Name        = 'ManufacturerNames'
                ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of manufacturers'
                IDParameter = 'ManufacturerIDs'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'SupplierNames'
                ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of suppliers'
                IDParameter = 'SupplierIDs'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ProductModelNames'
                ValidateSet = $TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of product models'
                IDParameter = 'ProductModelIDs'
                IDsMethod   = '$TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'StatusNames'
                ValidateSet = $TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of asset statuses'
                IDParameter = 'StatusIDs'
                IDsMethod   = '$TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'StatusNamesPast'
                ValidateSet = $TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of asset statuses'
                IDParameter = 'StatusIDsPast'
                IDsMethod   = '$TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'OwningDepartmentNames'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Names of owning departments'
                IDParameter = 'OwningDepartmentIDs'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'RequestingDepartmentNames'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Names of requesting departments'
                IDParameter = 'RequestDepartmentIDs'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'UsingDepartmentNames'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Names of using departments'
                IDParameter = 'UsingDepartmentIDs'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'OwningDepartmentPastNames'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Names of past owning departments'
                IDParameter = 'OwningDepartmentPastIDs'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'SavedSearchName'
                Type        = 'string'
                ValidateSet = $TDAssetSearches.GetAll($AssetCIAppID,$WorkingEnvironment).Name
                HelpText    = 'Names of saved search'
                IDParameter = 'SavedSearchNameID'
                IDsMethod   = '$TDAssetSearches.GetAll($AssetCIAppID,$WorkingEnvironment)'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
        # Warn on invalid combinations
        if ($LocationIDs -and $LocationLike)
        {
            Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring LocationLike, using LocationIDs'
            $LocationLike = ''
        }
        if ($RoomID -and $RoomLike)
        {
            Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring RoomLike, using RoomID'
            $RoomLike = ''
        }
        if ($ExactLocation -and -not ($RoomLike -or $LocationLike))
        {
            # If neither RoomLike nor NameLike is set, ExactLocation has no meaning
            $ExactLocation -eq $false
        }

        # Find location/room IDs for LocationLike and RoomLike
        if ($LocationLike)
        {
            # Location and room specified
            if ($RoomLike)
            {
                $Location = $TDBuildingsRooms.GetRoom($LocationLike,$RoomLike,$Environment)
            }
            # Location specified
            else
            {
                # Get from cache
                $Location = $TDBuildingsRooms.Get($LocationLike, $Environment)
            }
            if (-not $Location)
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Unable to find LocationLike or RoomLike location.'
            }
        }
        # Only room specified by name, requires location ID - rooms cannot be looked up by themselves
        elseif ($RoomLike)
        {
            if ($LocationIDs)
            {
                # Rooms can only be looked up within a single building
                if ($LocationIDs.Count -eq 1)
                {
                    $Location = $TDBuildingsRooms.GetRoom($LocationIDs[0],$RoomLike,$Environment)
                    if (-not $Location)
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find LocationLike or RoomLike location in location ID $LocationIDs."
                    }
                }
                else
                {
                    Write-ActivityHistory -MessageChannel 'Warning' -Message 'Unable to look up rooms in multiple locations.'
                }
            }
        }
        if ($Location)
        {
            switch ($Location[0].GetType().Name)
            {
                TeamDynamix_Api_Locations_Location     {$LocationIDs += $Location.ID}
                TeamDynamix_Api_Locations_LocationRoom {$RoomID       = $Location.ID}
            }
        }

        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Assets_AssetSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_Asset'
            AllEndpoint      = $null
            SearchEndpoint   = '$AppID/assets/search'
            IDEndpoint       = '$AppID/assets/$ID'
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

        # Local modifications to return set
        if ($Exact)
        {
            if (-not [string]::IsNullOrWhiteSpace($SearchText))
            {
                $Return = $Return | Where-Object Name -eq $SearchText
            }
            if (-not [string]::IsNullOrWhiteSpace($SerialLike))
            {
                $Return = $Return | Where-Object SerialNumber -eq $SerialLike
            }
        }
        if ($Detail)
        {
            if ($Return)
            {
                $Return = $Return.ID | Get-TDAsset -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDAssetResource
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # Get resources for this asset ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Set ID of application for asset
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ReturnType       = 'TeamDynamix_Api_ResourceItem'
            AllEndpoint      = $null
            SearchEndpoint   = $null
            IDEndpoint       = '$AppID/assets/$ID/users'
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

function New-TDAsset
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Set status ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='ID')]
        [int]
        $StatusID,

        # Set serial number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $SerialNumber,

        # Set asset name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set form ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $FormID,

        # Set supplier ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $SupplierID,

        # Set location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Set location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Set location name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationName,

        # Set location room name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationRoomName,

        # Set parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ParentID,

        # Set product model ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ProductModelID,

        # Set maintenance schedule ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $MaintenanceScheduleID,

        # Set owning department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $OwningDepartmentID,

        # Set purchase cost
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $PurchaseCost,

        # Set asset tag
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Tag,

        # Set requesting customer ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [guid]
        $RequestingCustomerID,

        # Set owning customer ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwningCustomerID,

        # Set requesting department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $RequestingDepartmentID,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Set acquisition date
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $AcquisitionDate,

        # Set expected replacement date
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $ExpectedReplacementDate,

        # Set external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return newly created asset as an oject
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $Passthru,

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
				Name        = 'SupplierName'
                Type        = 'string'
				ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of supplier'
                IDParameter = 'SupplierID'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'ProductModelName'
                Type        = 'string'
				ValidateSet = $TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of product model'
                IDParameter = 'ProductModelID'
                IDsMethod   = '$TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'StatusName'
                Type        = 'string'
				ValidateSet = $TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of asset statuses'
                IsMandatory = $true
                ParameterSetName = 'Name'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'OwningDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'RequestingDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of requesting department'
                IDParameter = 'RequestingDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
        # Ignore name when ID is provided, Names of "None" means that location has not been set and should also be ignored
        if (($LocationName     -eq 'None') -or ($LocationID      -and $LocationName))    {$LocationName     = ''}
        if (($LocationRoomName -eq 'None') -or ($LocationRoomID -and $LocationRoomName)) {$LocationRoomName = ''}

        # Find location/room IDs for LocationName and LocationRoomName
        $Location = $null
        if ($LocationName)
        {
            # Location and room specified
            if ($LocationRoomName)
            {
                $Location = $TDBuildingsRooms.GetRoom($LocationName,$LocationRoomName,$Environment)
            }
            # Location specified
            else
            {
                $Location = $TDBuildingsRooms.Get($LocationName,$Environment)
            }
            if (-not $Location)
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Unable to find LocationName or LocationRoomName location.'
            }
        }
        # Only room specified by name, requires location ID - rooms cannot be looked up by themselves
        elseif ($LocationRoomName)
        {
            if ($LocationID)
            {
                $Location = $TDBuildingsRooms.GetRoom($LocationID,$LocationRoomName,$Environment)
                if (-not $Location)
                {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find LocationName or LocationRoomName location in location ID $LocationID."
                }
            }
        }
        # A location was set by name
        if ($Location)
        {
            switch ($Location.GetType().Name)
            {
                TeamDynamix_Api_Locations_Location
                {
                    $LocationID     = $Location.ID
                    $LocationRoomID = 0
                }
                TeamDynamix_Api_Locations_LocationRoom
                {
                    $LocationRoomID = $Location.ID
                    if (-not $LocationID)
                    {
                        $LocationID = (Get-TDLocation -RoomID $Location.ID -AuthenticationToken $AuthenticationToken -Environment $Environment).ID
                    }
                }
            }
            # Re-call New-TDAsset, this time with the LocationID and LocationRoomID instead of names
            #  Get original calling parameters
            $RedoParametersDict = $MyInvocation.BoundParameters
            #  Remove location names from the dictionary
            $RedoParametersDict.Remove('LocationName')     | Out-Null
            $RedoParametersDict.Remove('LocationRoomName') | Out-Null
            #  Create a new object to hold the parameters
            $RedoParametersObj = New-Object psobject
            #  Add original calling parameters back
            $RedoParametersDict.GetEnumerator() | ForEach-Object {Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Name $_.Key -Value $_.Value}
            #  Add location IDs
            Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Force -Name 'LocationID'     -Value $LocationID
            Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Force -Name 'LocationRoomID' -Value $LocationRoomID
            #  Call New-TDAsset
            $Return = $RedoParametersObj | New-TDAsset -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        # No location set by name
        else
        {
            $InvokeParams = [pscustomobject]@{
                # Configurable parameters
                ObjectType = 'TeamDynamix_Api_Assets_Asset'
                Endpoint   = '$AppID/assets'
                Method     = 'Post'
                AppID      = $AppID
                DynamicParameterDictionary = $DynamicParameterDictionary
                DynamicParameterList       = $DynamicParameterList
                # Fixed parameters
                ParameterSetName    = $pscmdlet.ParameterSetName
                BoundParameters     = $MyInvocation.BoundParameters.Keys
                Environment         = $Environment
                AuthenticationToken = $AuthenticationToken
            }
            $Return = $InvokeParams | Invoke-New
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDAsset
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='Non-Bulk')]
    Param
    (
        # ID number of asset to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $ID,

        # Modify serial number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $SerialNumber,

        # Modify asset name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $Name,

        # Modify status ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $StatusID,

        # Modify form ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $FormID,

        # Modify supplier ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $SupplierID,

        # Modify location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $LocationID,

        # Modify location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $LocationRoomID,

        # Modify location by name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $LocationName,

        # Modify location room by name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $LocationRoomName,

        # Modify parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $ParentID,

        # Modify product model ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $ProductModelID,

        # Modify maintenance schedule ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $MaintenanceScheduleID,

        # Modify owning department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $OwningDepartmentID,

        # Modify purchase cost
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [double]
        $PurchaseCost,

        # Modify asset tag
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $Tag,

        # Modify requesting customer ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [guid]
        $RequestingCustomerID,

        # Modify owning customer ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [guid]
        $OwningCustomerID,

        # Modify requesting department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $RequestingDepartmentID,

        # Modify custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [array]
        $Attributes,

        # Modify acquisition date
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [datetime]
        $AcquisitionDate,

        # Modify expected replacement date
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [datetime]
        $ExpectedReplacementDate,

        # Modify external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [string]
        $ExternalID,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [int]
        $AppID = $AssetCIAppID,

        # Indicates that specified attributes should be removed
        [Parameter(Mandatory=$false,
                   ParameterSetName='Non-Bulk')]
        [ValidateScript({
            $AttributeNames = (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $TDAuthentication -Environment $Environment).Name
            $Return = $true
            foreach ($Attr in $_)
            {
                if ($Attr -notin $AttributeNames)
                {
                    $Return = $false
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "RemoveAttributes must be in this list:`n$($AttributeNames | Out-String)"
                    break
                }
            }
            return $Return
        })]
        [string[]]
        $RemoveAttributes,

        # Indicates that this will be a bulk update
        [Parameter(Mandatory=$true,
                   ParameterSetName='Bulk')]
        [switch]
        $Bulk,

        # Bulk asset update data
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='Bulk')]
        [ValidateCount(1,1000)]
        [psobject[]]
        $Items,

        # Create new items as part of bulk update
        [Parameter(Mandatory=$false,
                   ParameterSetName='Bulk')]
        [boolean]
        $CreateItems = $true,

        # Update existing items as part of bulk update
        [Parameter(Mandatory=$false,
                   ParameterSetName='Bulk')]
        [boolean]
        $UpdateItems = $true,

        # Return updated asset as an object
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-Bulk')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Bulk')]
        [switch]
        $Passthru,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ParameterSetName='Non-Bulk')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Bulk')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # Use TeamDynamix Preview API
        [Parameter(Mandatory=$false,
                   ParameterSetName='Non-Bulk')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Bulk')]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )
    DynamicParam
    {
        #List dynamic parameters
		$DynamicParameterList = @(
			@{
				Name        = 'SupplierName'
				ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of supplier'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'SupplierID'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'ProductModelName'
				ValidateSet = $TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of product model'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'ProductModelID'
                IDsMethod   = '$TDProductModels.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'StatusName'
				ValidateSet = $TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of asset statuse'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDAssetStatuses.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'OwningDepartmentName'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Names of owning departments'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'RequestingDepartmentName'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Names of requesting departments'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'RequestingDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        # Ignore name when ID is provided, Names of "None" means that location has not been set and should also be ignored
        if (($LocationName     -eq 'None') -or ($LocationID      -and $LocationName))    {$LocationName     = ''}
        if (($LocationRoomName -eq 'None') -or ($LocationRoomID -and $LocationRoomName)) {$LocationRoomName = ''}

        # Find location/room IDs for LocationName and LocationRoomName
        $Location = $null
        if ($LocationName)
        {
            # Location and room specified
            if ($LocationRoomName)
            {
                $Location = $TDBuildingsRooms.GetRoom($LocationName,$LocationRoomName,$Environment)
            }
            # Location specified
            else
            {
                $Location = $TDBuildingsRooms.Get($LocationName,$Environment)
            }
            if (-not $Location)
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Unable to find LocationName or LocationRoomName location.'
            }
        }
        # Only room specified by name, requires location ID - rooms cannot be looked up by themselves
        elseif ($LocationRoomName)
        {
            if ($LocationID)
            {
                $Location = $TDBuildingsRooms.GetRoom($LocationID,$LocationRoomName,$Environment)
                if (-not $Location)
                {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find LocationName or LocationRoomName location in location ID $LocationID."
                }
            }
        }
        # A location was set by name
        if ($Location)
        {
            switch ($Location.GetType().Name)
            {
                TeamDynamix_Api_Locations_Location
                {
                    $LocationID     = $Location.ID
                    $LocationRoomID = 0
                }
                TeamDynamix_Api_Locations_LocationRoom
                {
                    $LocationRoomID = $Location.ID
                    if (-not $LocationID)
                    {
                        $LocationID = (Get-TDLocation -RoomID $Location.ID -AuthenticationToken $AuthenticationToken -Environment $Environment).ID
                    }
                }
            }
            # Re-call Set-TDAsset, this time with the LocationID and LocationRoomID instead of names
            #  Get original calling parameters
            $RedoParametersDict = $MyInvocation.BoundParameters
            #  Remove location names from the dictionary
            $RedoParametersDict.Remove('LocationName')     | Out-Null
            $RedoParametersDict.Remove('LocationRoomName') | Out-Null
            #  Create a new object to hold the parameters
            $RedoParametersObj = New-Object psobject
            #  Add original calling parameters back
            $RedoParametersDict.GetEnumerator() | ForEach-Object {Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Name $_.Key -Value $_.Value}
            #  Add location IDs
            Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Force -Name 'LocationID'     -Value $LocationID
            Add-Member -InputObject $RedoParametersObj -MemberType NoteProperty -Force -Name 'LocationRoomID' -Value $LocationRoomID
            #  Call Set-TDAsset
            $Return = $RedoParametersObj | Set-TDAsset -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        # No location set by name
        else
        {
            switch ($pscmdlet.ParameterSetName)
            {
                'Non-Bulk'
                {
                    $InvokeParams = [pscustomobject]@{
                        # Configurable parameters
                        RetrievalCommand = "Get-TDAsset -ID $ID -AppID $AppID"
                        ObjectType = 'TeamDynamix_Api_Assets_Asset'
                        Endpoint   = '$AppID/assets/$ID'
                        Method     = 'Post'
                        AppID      = $AppID
                        DynamicParameterDictionary = $DynamicParameterDictionary
                        DynamicParameterList       = $DynamicParameterList
                        # Fixed parameters
                        ParameterSetName    = $pscmdlet.ParameterSetName
                        BoundParameters     = $MyInvocation.BoundParameters.Keys
                        Environment         = $Environment
                        AuthenticationToken = $AuthenticationToken
                    }
                    $Return = $InvokeParams | Invoke-New
                }
                'Bulk'
                {
                    #!!! Does not work presently
                    #$Import = @{Items=$Items;Settings=@{Mappings=$Mappings;CreateItems=$CreateItems;UpdateItems=$UpdateItems}}
                    if ($pscmdlet.ShouldProcess("Items start with: $($Items[0])`rCreate new items: $CreateItems`rUpdate items: $UpdateItems", 'Update asset properties in bulk'))
                    {
                        $ImportAsset = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/import" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Import -Depth 10 -Compress)
                        Write-ActivityHistory ($ImportAsset | Out-String)
                        if ($Passthru)
                        {
                            Write-Output $ImportAsset
                        }
                    }
                }
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDAssetStatus
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID for asset status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter asset status name text, substring
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter asset status based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Filter asset status based on whether it is out of service
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsOutOfService,

        # Set ID of application for asset status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return only exact matches on search
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            SearchType       = 'TeamDynamix_Api_Assets_AssetStatusSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_AssetStatus'
            AllEndpoint      = '$AppID/assets/statuses'
            SearchEndpoint   = '$AppID/assets/statuses/search'
            IDEndpoint       = '$AppID/assets/statuses/$ID'
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
        # Local modifications to return set
        if ($Return)
        {
            if ($Exact)
            {
                if (-not [string]::IsNullOrWhiteSpace($SearchText))
                {
                    $Return = $Return | Where-Object Name -eq $SearchText
                }
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDAssetStatus
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Name for asset status
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of asset status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Order of asset status in lists
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Order,

        # Filter asset status based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Filter asset status based on whether it is out of service
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsOutOfService,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Assets_AssetStatus'
            Endpoint   = '$AppID/assets/statuses'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDAssetStatus
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for asset status
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Name for asset status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of asset status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Order of asset status in lists
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Order,

        # Filter asset status based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Filter asset status based on whether it is out of service
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsOutOfService = $false,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDAssetStatus -ID $ID"
            ObjectType = 'TeamDynamix_Api_Assets_AssetStatus'
            Endpoint   = '$AppID/assets/statuses/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDMaintenanceWindow
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Maintenance window ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter maintenance window name text, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $NameLike,

        # Filter maintenance window based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for maintenance window
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

        # Return only maintenance window that contains the exact name match
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch'
            ReturnType       = 'TeamDynamix_Api_Cmdb_MaintenanceSchedule'
            AllEndpoint      = '$AppID/cmdb/maintenancewindows'
            SearchEndpoint   = '$AppID/cmdb/maintenancewindows/search'
            IDEndpoint       = '$AppID/cmdb/maintenancewindows/$ID'
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
        # Return only exact match
        if ($Exact)
        {
            $Return = $Return | Where-Object Name -eq $NameLike
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDMaintenanceWindow
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Name for maintenance window
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # ID number of time zone
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TimeZoneID,

        # Filter maintenance window based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application for maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
                Name        = 'TimeZoneName'
                Type        = 'string'
                ValidateSet = $TDTimeZones.Name
                HelpText    = 'Name of time zone'
                IDParameter = 'TimeZoneID'
                IDsMethod   = '$TDTimeZones'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Cmdb_MaintenanceSchedule'
            Endpoint   = '$AppID/cmdb/maintenancewindows'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDMaintenanceWindow
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for maintenance window
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Name for maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Time zone ID for maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TimeZoneID,

        # Set maintenance window to be active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Set ID of application for maintenance window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                Name        = 'TimeZoneName'
                Type        = 'string'
                ValidateSet = $TDTimeZones.Name
                HelpText    = 'Name of time zone'
                IDParameter = 'TimeZoneID'
                IDsMethod   = '$TDTimeZones'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDMaintenanceWindow -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Cmdb_MaintenanceSchedule'
            Endpoint   = '$AppID/cmdb/maintenancewindows/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDVendor
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Vendor ID
        [Parameter(ParameterSetName='ID',
                   Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
        $ID,

        # Filter vendor, substring includes name, description, and primary contact name
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter on name only
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [string]
        $NameLike,

        # Filter vendors based on whether or not they are a manufacturer
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $OnlyManufacturers = $null,

        # Filter vendors based on whether or not they are a supplier
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $OnlySuppliers = $null,

        # Filter vendors based on whether or not they are a contract provider
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $OnlyContractProviders = $null,

        # Filter vendors based on whether they are active or inactive
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive = $null,

        # Filter vendors based on custom attributes
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [array]
        $CustomAttributes,

        # Set ID of application for vendor
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

        # Return only exact match to NameLike
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Assets_VendorSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_Vendor'
            AllEndpoint      = '$AppID/assets/vendors'
            SearchEndpoint   = '$AppID/assets/vendors/search'
            IDEndpoint       = '$AppID/assets/vendors/$ID'
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
        # Return only exact match to NameLike
        if ($Exact)
        {
            $Return = $Return | Where-Object Name -eq $NameLike
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDProductModel
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID of product model
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter product model, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter product model based on manufacturer ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ManufacturerID,

        # Filter product model based on product type ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ProductTypeID,

        # Filter product model based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Filter based on custom attributes
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [array]
        $Attributes,

        # Set ID of application for asset
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

        # Return full detail on user
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Detail,

        # Return only exact matches on search
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
				Name        = 'ManufacturerName'
                Type        = 'string'
				ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            SearchType       = 'TeamDynamix_Api_Assets_ProductModelSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_ProductModel'
            AllEndpoint      = '$AppID/assets/models'
            SearchEndpoint   = '$AppID/assets/models/search'
            IDEndpoint       = '$AppID/assets/models/$ID'
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
        # Local modifications to return set
        if ($Return)
        {
            if ($Exact)
            {
                if (-not [string]::IsNullOrWhiteSpace($SearchText))
                {
                    $Return = $Return | Where-Object {$SearchText -eq $_.Name}
                }
            }
            if ($Detail)
            {
                if ($Return)
                {
                    $Return = $Return.ID | Get-TDProductModel -AuthenticationToken $AuthenticationToken -Environment $Environment
                }
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDAssetComment
{
    [CmdletBinding()]
    Param
    (
        # ID of asset whose feed will be updated
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Comment to add to asset feed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Comments,

        # Email addresses to notify
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [ValidatePattern('^.*@.*\..*$')]
        [string[]]
        $Notify,

        # Set if comment is private
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $IsPrivate,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        # Manage parameters
        #  Identify all parameters for command
        $Params = Get-Params -KeyType 'TeamDynamix_Api_Feed_FeedEntry'
    }
    Process
    {
        $Update = [TeamDynamix_Api_Feed_FeedEntry]::new()
        Update-Object -InputObject $Update -ParameterList $Params.Command -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $Params.Ignore -AuthenticationToken $AuthenticationToken -Environment $Environment
        Write-ActivityHistory "Updating feed for TeamDynamix asset ID $ID, with comment, $Comment."
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/$ID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Update -Depth 10)
        if ($Return)
        {
            return [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
        }
    }
}

{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Asset ID to add attachment in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Full path and filename of attachment
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path -PathType Leaf $_})]
        [string]
        $FilePath,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $BoundaryText = [System.Guid]::NewGuid().ToString()
        $ContentType = "multipart/formdata; boundary=$BoundaryText"
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        #Extract filename
        $FileName = $FilePath.Split("\")[$FilePath.Split("\").Count - 1]
        #Encode file
        $FileAsBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $Encoding = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
        $EncodedFile = $Encoding.GetString($FileAsBytes)
        #Assemble body
        $ContentInfo = (
            "Content-Disposition: form-data; name=`"$FileName`"; filename=`"$FileName`"",
            "Content-Type: application/octet-stream"
        ) -join "`r`n"
        $Body = (
            "--$BoundaryText",
            $ContentInfo,
            "",
            $EncodedFile,
            "--$BoundaryText--"
        ) -join "`r`n"
        if ($pscmdlet.ShouldProcess("asset ID: $ID, attachment name: $FileName", 'Add attachment to TeamDynamix asset'))
        {
            Write-ActivityHistory "Adding $FileName attachment to asset $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/$ID/attachments" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                return [TeamDynamix_Api_Attachments_Attachment]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDAssetAttachment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Asset ID to add attachment in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Full path and filename of attachment
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path -PathType Leaf $_})]
        [string]
        $FilePath,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
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
        $BoundaryText = [System.Guid]::NewGuid().ToString()
        $ContentType = "multipart/formdata; boundary=$BoundaryText"
        $BaseURI = Get-URI -Environment $Environment
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
    }
    Process
    {
        #Extract filename
        $FileName = $FilePath.Split("\")[$FilePath.Split("\").Count - 1]
        #Encode file
        $FileAsBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $Encoding = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
        $EncodedFile = $Encoding.GetString($FileAsBytes)
        #Assemble body
        $ContentInfo = (
            "Content-Disposition: form-data; name=`"$FileName`"; filename=`"$FileName`"",
            "Content-Type: application/octet-stream"
        ) -join "`r`n"
        $Body = (
            "--$BoundaryText",
            $ContentInfo,
            "",
            $EncodedFile,
            "--$BoundaryText--"
        ) -join "`r`n"
        if ($pscmdlet.ShouldProcess("asset ID: $ID, attachment name: $FileName", 'Add attachment to TeamDynamix asset'))
        {
            Write-ActivityHistory "Adding $FileName attachment to asset $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/$ID/attachments" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                return [TeamDynamix_Api_Attachments_Attachment]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDAssetResource
{
    [CmdletBinding()]
    Param
    (
        # ID of asset to be added to ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Ticket ID to which ticket will be added
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ResourceID,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = $null
            Endpoint   = '$AppID/assets/$ID/users/$ResourceID'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Remove-TDAssetResource
{
    [CmdletBinding()]
    Param
    (
        # ID of asset to be removed from resource
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Resource ID from which ticket will be removed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ResourceID,

        # Set ID of application for asset
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = $null
            Endpoint   = '$AppID/assets/$ID/users/$ResourceID'
            Method     = 'Delete'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDCustomAttribute
{
    [CmdletBinding()]
    Param
    (
        # Component whose custom attributes will be retrieved
        [Parameter(Mandatory=$true,
                   Position=0)]
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]
        $ComponentID,

        # ID number for application
        [Parameter(Mandatory=$false,
                   Position=1)]
        [int]
        $AppID = 0,

        # Name of ticket type whose custom attributes will be retrieved
        [Parameter(Mandatory=$false)]
        [string]
        $AssociatedTypeName,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        # Override AppID if AppName is set
        if ($DynamicParameterDictionary.AppName.Value)
        {
            $AppID = ($TDApplications | Where-Object Name -eq $DynamicParameterDictionary.AppName.Value).AppID
        }
        Write-ActivityHistory "Looking up ID for component $ComponentID in $AppID"
        # Check to see if Component ID for this AppID has already been looked up
        if (([int]$ComponentID -in $CustomAttributesCache.$Environment."AppID$AppID".Keys) -and ("AppID$AppID" -in $CustomAttributesCache.$Environment.Keys))
        {
            $Return = $CustomAttributesCache.$Environment."AppID$AppID".[int]$ComponentID
        }
        else # Component ID was not in cache, look it up and add it to the cache
        {
            if ($AssociatedTypeName -eq '')
            {
                $AssociatedTypeID = 0
            }
            else
            {
                $AssociatedTypeID = $Types[$AssociatedTypeName]
            }
            if ($AppID -eq 0)
            {
                $AppNameText = 'for all applications'
            }
            else
            {
                $AppNameText = "and application $($AppName.Value)"
            }
            Write-ActivityHistory "Retrieving custom attributes for component $ComponentID, associated type $AssociatedTypeName, $AppNameText"
            $Return = (Invoke-RESTCall -Uri "$BaseURI/attributes/custom?componentId=$([int]$ComponentID)&associatedTypeId=$AssociatedTypeID&appId=$AppID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken) | ForEach-Object {[TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($_)}
            # Add result to the Component lookup table
            #  Add AppID to cache if necessary
            if ("AppID$AppID" -notin $CustomAttributesCache.$Environment.Keys)
            {
                $CustomAttributesCache.$Environment += @{"AppID$AppID" = @{}}
            }
            $CustomAttributesCache.$Environment."AppID$AppID" += @{[int]$ComponentID = $Return}
        }
        #>
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDCustomAttributeChoice
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        #ID of custom attributes whose choices will be retrieved
        [Parameter(Mandatory=$true,
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
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_CustomAttributes_CustomAttributeChoice'
            AllEndpoint      = $null
            SearchEndpoint   = $null
            IDEndpoint       = "attributes/$ID/choices"
            AppID            = $AppID
            DynamicParameterDictionary = $null
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

function Add-TDCustomAttributeChoice
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        #ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        #ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Name,

        #ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [boolean]
        $IsActive = $true,

        #ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [int]
        $Order = 0,

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
    }
    Process
    {
        Write-ActivityHistory "Adding choice, $Name, to custom attribute with ID, $ID."
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            ObjectType = 'TeamDynamix_Api_CustomAttributes_CustomAttributeChoice'
            Endpoint   = "attributes/$ID/choices"
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Remove-TDCustomAttributeChoice
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        #ID of custom attributes whose choice will be removed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        #ID of choice to be removed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ChoiceID,

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
    }
    Process
    {
        Write-ActivityHistory "Removing choice, $ChoiceID, from custom attribute with ID, $ID."
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            ObjectType = $null
            Endpoint   = "attributes/$ID/choices/$ChoiceID"
            Method     = 'Delete'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDCustomAttributeChoice
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # ID of custom attributes the choices will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $ChoiceID,

        # Name of the custom attribute choice
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Custom attribute choice active status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Order custom attribute choice appears
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Order,

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
        # Manage parameters
        #  Identify all/ignore parameters for command
        $Params = Get-Params -KeyType 'TeamDynamix_Api_CustomAttributes_CustomAttributeChoice'
    }
    Process
    {
        # Retrieve existing choice
        try
        {
            $Choices = Get-TDCustomAttributeChoice -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find custom attribute ID, $ID"
        }
        $Choice = $Choices | Where-Object ID -eq $ChoiceID
        if (-not $Choice)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Invalid choice ID, $ChoiceID"
        }
        # Update choice
        Update-Object -InputObject $Choice -ParameterList $Params.Command -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $Params.Ignore -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($ChoiceID, "Update choice on custom attribute, $ID"))
        {
            Write-ActivityHistory "Updating choice ID, $ChoiceID, to custom attribute with ID, $ID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/attributes/$ID/choices/$ChoiceID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $Choice -Depth 10)
            if ($Return)
            {
                return [TeamDynamix_Api_CustomAttributes_CustomAttributeChoice]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDConfigurationItemType
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Configuration item type ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter configuration item type name text, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter configuration item type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Filter configuration item type based on whether it is organizationally defined
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsOrganizationallyDefined,

        # Set ID of application for configuration item type
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

        # Return only exact matches on search
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch'
            ReturnType       = 'TeamDynamix_Api_Cmdb_ConfigurationItemType'
            AllEndpoint      = '$AppID/cmdb/types'
            SearchEndpoint   = '$AppID/cmdb/types/search'
            IDEndpoint       = '$AppID/cmdb/types/$ID'
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
        # Local modifications to return set
        if ($Return)
        {
            if ($Exact)
            {
                if (-not [string]::IsNullOrWhiteSpace($SearchText))
                {
                    $Return = $Return | Where-Object Name -eq $SearchText
                }
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDConfigurationItemType
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Name for configuration item type
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Filter configuration item type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application for configuration item type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationItemType'
            Endpoint   = '$AppID/cmdb/types'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDConfigurationItemType
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for configuration item type
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Name for configuration item type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set configuration item type to be active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Set ID of application for configuration item type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDConfigurationItemType -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationItemType'
            Endpoint   = '$AppID/cmdb/types/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDConfigurationItem
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # ID of custom attributes whose choices will be retrieved
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

        # Filter configuration items by name
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [alias('Filter')]
        [string]
        $NameLike,

        # Filter configuration items by name
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Filter configuration items by type IDs
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int[]]
        $TypeIDs,

        # Filter configuration items by maintenance schedule IDs
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int[]]
        $MaintenanceScheduleIDs,

        # Filter configurations items based on custom attributes
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [array]
        $CustomAttributes,

        # Return only exact match to NameLike
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

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
				Name        = 'TypeNames'
				ValidateSet = $TDConfigurationItemTypes.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Names of configuration item types'
                IDParameter = 'TypeIDs'
                IDsMethod   = '$TDConfigurationItemTypes.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            SearchType       = 'TeamDynamix_Api_Cmdb_ConfigurationItemSearch'
            ReturnType       = 'TeamDynamix_Api_Cmdb_ConfigurationItem'
            AllEndpoint      = $null
            SearchEndpoint   = '$AppID/cmdb/search'
            IDEndpoint       = '$AppID/cmdb/$ID'
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
        # Return only exact match to NameLike
        if ($Exact)
        {
            $Return = $Return | Where-Object Name -eq $NameLike
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDConfigurationItem
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Set configuration item name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set configuration item type ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TypeID,

        # Set form ID for new configuration item in TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $FormID,

        # Set ID of application to create new configuration item in TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Set location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Set location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Set maintenance schedule ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $MaintenanceScheduleID,

        # Set owning department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $OwningDepartmentID,

        # Set owner ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwnerUID,

        # Set owning group ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $OwningGroupID,

        # Set configuration as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Set external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Set external source ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalSourceID,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
				Name        = 'TypeName'
                Type        = 'string'
				ValidateSet = $TDConfigurationItemTypes.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of configuration type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDConfigurationItemTypes.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'FormName'
                Type        = 'string'
				ValidateSet = $TDForms.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'OwningDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'OwningGroupName'
                Type        = 'string'
				ValidateSet = $TDGroups.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of owning group'
                IDParameter = 'OwningGroupID'
                IDsMethod   = '$TDGroups.GetAll($WorkingEnvironment,$true)'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationItem'
            Endpoint   = '$AppID/cmdb'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDConfigurationItem
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Set configuration item name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ID,

        # Set configuration item name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set configuration item type ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TypeID,

        # Set application ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Set location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Set location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Set maintenance schedule ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $MaintenanceScheduleID,

        # Set owning department ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $OwningDepartmentID,

        # Set owner ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwnerID,

        # Set owning group ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $OwningGroupID,

        # Set configuration as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Set external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Set external source ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalSourceID,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

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
				Name        = 'OwningDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'OwningGroupName'
                Type        = 'string'
				ValidateSet = $TDGroups.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of owning group'
                IDParameter = 'OwningGroupID'
                IDsMethod   = '$TDGroups.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDConfigurationItem -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationItem'
            Endpoint   = '$AppID/cmdb/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDConfigurationRelationshipType
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ReturnType       = 'TeamDynamix_Api_Cmdb_ConfigurationRelationshipType'
            AllEndpoint      = $null
            SearchEndpoint   = $null
            IDEndpoint       = '$AppID/cmdb/relationshiptypes'
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

function Get-TDConfigurationItemRelationship
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # Configuration item ID to retrieve relationships from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ReturnType       = 'TeamDynamix_Api_Cmdb_ConfigurationItemRelationship'
            AllEndpoint      = $null
            SearchEndpoint   = $null
            IDEndpoint       = '$AppID/cmdb/$ID/relationship'
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

function Remove-TDConfigurationItemRelationship
{
    [CmdletBinding()]
    Param
    (
        # ID of asset to be removed from ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Ticket ID from which ticket will be removed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $RelationshipID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
        Write-ActivityHistory "Removing TeamDynamix relationship ID $RelationshipID, from asset ID $ID."
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            RetrievalCommand = $null
            ObjectType = $null
            Endpoint   = '$AppID/cmdb/$ID/relationships/$RelationshipID'
            Method     = 'Delete'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDConfigurationItemAttachment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Asset ID to add attachment in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Full path and filename of attachment
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path -PathType Leaf $_})]
        [string]
        $FilePath,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $BoundaryText = [System.Guid]::NewGuid().ToString()
        $ContentType = "multipart/formdata; boundary=$BoundaryText"
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        #Extract filename
        $FileName = $FilePath.Split("\")[$FilePath.Split("\").Count - 1]
        #Encode file
        $FileAsBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $Encoding = [System.Text.Encoding]::GetEncoding("ISO-8859-1")
        $EncodedFile = $Encoding.GetString($FileAsBytes)
        #Assemble body
        $ContentInfo = (
            "Content-Disposition: form-data; name=`"$FileName`"; filename=`"$FileName`"",
            "Content-Type: application/octet-stream"
        ) -join "`r`n"
        $Body = (
            "--$BoundaryText",
            $ContentInfo,
            "",
            $EncodedFile,
            "--$BoundaryText--"
        ) -join "`r`n"
        if ($pscmdlet.ShouldProcess("configuration item ID: $ID, attachment name: $FileName", 'Add attachment to TeamDynamix configuration item'))
        {
            Write-ActivityHistory "Adding $FileName attachment to configuration item $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/cmdb/$ID/attachments" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                return [TeamDynamix_Api_Attachments_Attachment]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDConfigurationItemRelationship
{
    [CmdletBinding()]
    Param
    (
        # ID of asset whose relationship will be updated
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Item to add a relationship with configuration item
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $OtherItemID,

        # ID of relationship type to add to configuation item
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [int]
        $TypeID,

        # ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Set configuration to be parent in relationship
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $isParent = $true,

        # Remove existing relationships that match the Type ID and parent relationship
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $RemoveExisting = $false,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        Write-ActivityHistory "Adding relationship for TeamDynamix asset ID $ID, of type $TypeID with comment, $Comment."
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/cmdb/$ID/relationships?typeId=$TypeID&otherItemId=$OtherItemID&isParent=$IsParent&removeExisting=$RemoveExisting" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
        if ($Return)
        {
            return [TeamDynamix_Api_Cmdb_ConfigurationItemRelationship]::new($Return)
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDProductModel
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Set product model name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set product model manufacturer ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ManufacturerID,

        # Set product model product type ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ProductTypeID,

        # Set product model description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set product model manufacturer part number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PartNumber,

        # Set product model as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
				Name        = 'ManufacturerName'
                Type        = 'string'
				ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Assets_ProductModel'
            Endpoint   = '$AppID/assets/models'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDProductModel
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Product model ID to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Set product model name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set product model manufacturer ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ManufacturerID,

        # Set product model product type ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ProductTypeID,

        # Set product model description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set product model manufacturer part number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PartNumber,

        # Set product model as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
				Name        = 'ManufacturerName'
                Type        = 'string'
				ValidateSet = $TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true).Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors.GetAll($AssetCIAppID,$WorkingEnvironment,$true)'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDProductModel -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Assets_ProductModel'
            Endpoint   = '$AppID/assets/models/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDProductType
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID of product type
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter product type, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter product type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Return only top-level product types
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsTopLevel,

        # Filter product model based on the parent product type ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ParentProductTypeID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
			@{
				Name        = 'ParentProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of parent product type'
                IDParameter = 'ParentProductTypeID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
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
            SearchType       = 'TeamDynamix_Api_Assets_ProductTypeSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_ProductType'
            AllEndpoint      = '$AppID/assets/models/types'
            SearchEndpoint   = '$AppID/assets/models/types/search'
            IDEndpoint       = '$AppID/assets/models/types/$ID'
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

function Get-TDProductTypeInt # Used to retrieve list of product types, used for ParentProductTypeName in Get-TDProductType
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID of product type
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter product type, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter product type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Return only top-level product types
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsTopLevel,

        # Filter product model based on the parent product type ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ParentProductTypeID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Assets_ProductTypeSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_ProductType'
            AllEndpoint      = '$AppID/assets/models/types'
            SearchEndpoint   = '$AppID/assets/models/types/search'
            IDEndpoint       = '$AppID/assets/models/types/$ID'
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

function New-TDProductType
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Set product type name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set product type order
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order,

        # Set product type parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ParentID,

        # Set product type description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set product model as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
			@{
				Name        = 'ParentName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of parent type'
                IDParameter = 'ParentID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Assets_ProductType'
            Endpoint   = '$AppID/assets/models/types'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDProductType
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Product type ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Set product type name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Set product type order
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order,

        # Set product type parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ParentID,

        # Set product type description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set product type as active/inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Cascade active status to all child types
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $CascadeActiveStatus = $false,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
			@{
				Name        = 'ParentName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.GetAll($WorkingEnvironment,$true).Name
				HelpText    = 'Name of parent type'
                IDParameter = 'ParentID'
                IDsMethod   = '$TDProductTypes.GetAll($WorkingEnvironment,$true)'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        Write-ActivityHistory "Getting full product type record for $ID on TeamDynamix."
        try
        {
            $TDProductType = Get-TDProductType -ID $ID -AppID $AppID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find product type ID, $ID"
        }
        Write-ActivityHistory 'Product type exists. Setting properties.'
        Update-Object -InputObject $TDProductType -ParameterList $Params.Command -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $Params.Ignore -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("$ID - $($TDProductType.Name)", 'Update product type properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/models/types/$($ID)?cascadeActiveStatus=$CascadeActiveStatus" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TDProductType -Depth 10 -Compress)
            Write-ActivityHistory ($SetProductType | Out-String)
        }
        if ($Return)
        {
            return [TeamDynamix_Api_Assets_ProductType]::new($Return)
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDVendor
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # Vendor name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Vendor description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set whether vendor is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Vendor account number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AccountNumber,

        # Set whether vendor is a contract vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsContractProvider,

        # Set whether vendor is a manufacturer
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsManufacturer,

        # Set whether vendor is a supplier
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsSupplier,

        # Set vendor contact information
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Assets_ContactInformation]
        $CompanyInformation,

        # Set primary contact name for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactName,

        # Set primary contact title for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactTitle,

        # Set primary contact department for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactDepartment,

        # Set primary contact email for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactEmail,

        # Set primary contact information for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Assets_ContactInformation]
        $PrimaryContactInformation,

        # Filter vendors based on custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            ObjectType = 'TeamDynamix_Api_Assets_Vendor'
            Endpoint   = '$AppID/assets/vendors'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDVendor
{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # Vendor ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Vendor name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Vendor description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Set whether vendor is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Vendor account number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AccountNumber,

        # Set whether vendor is a contract vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsContractProvider,

        # Set whether vendor is a manufacturer
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsManufacturer,

        # Set whether vendor is a supplier
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsSupplier,

        # Set vendor contact information
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Assets_ContactInformation]
        $CompanyInformation,

        # Set primary contact name for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactName,

        # Set primary contact title for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactTitle,

        # Set primary contact department for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactDepartment,

        # Set primary contact email for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ContactEmail,

        # Set primary contact information for vendor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Assets_ContactInformation]
        $PrimaryContactInformation,

        # Filter vendors based on custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            RetrievalCommand = "Get-TDVendor -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Assets_Vendor'
            Endpoint   = '$AppID/assets/vendors/$ID'
            Method     = 'Put'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDConfigurationItemForm
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $AssetCIAppID,

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
				ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_Forms_Form'
            AllEndpoint      = '$AppID/cmdb/forms'
            SearchEndpoint   = $null
            IDEndpoint       = $null
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

function New-TDConfigurationRelationshipType
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Description of the relationship from the perspective of the parent CI
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Description of the relationship from the perspective of the child CI
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $InverseDescription,

        # Sets whether relationships of this type constitute an operational dependency
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsOperationalDependency,

        # Filter configuration item relationship type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application for configuration item relationship type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

        # Return updated asset as an object
        [Parameter(Mandatory=$false)]
        [switch]
        $Passthru,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationRelationshipType'
            Endpoint   = '$AppID/cmdb/relationshiptypes'
            Method     = 'Post'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDConfigurationRelationshipType
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for configuration item type
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Description of the relationship from the perspective of the parent CI
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Description of the relationship from the perspective of the child CI
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $InverseDescription,

        # Sets whether relationships of this type constitute an operational dependency
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsOperationalDependency,

        # Filter configuration item relationship type based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application for configuration item relationship type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $AssetCIAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($Environment,$true)'
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
            RetrievalCommand = "Get-TDConfigurationRelationshipType -ID $ID -AppID $AppID"
            ObjectType = 'TeamDynamix_Api_Cmdb_ConfigurationRelationshipType'
            Method     = 'Put'
            Endpoint   = '$AppID/cmdb/relationshiptypes/$ID'
            AppID      = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
}