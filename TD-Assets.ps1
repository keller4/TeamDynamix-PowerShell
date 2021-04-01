### Assets

<#
.Synopsis
    Get an asset in TeamDynamix
.DESCRIPTION
    Get an asset in TeamDynamix. Specify the asset ID number
    or search using the text of the asset tag, serial number, supplier name,
    product model name, or manufacturer name.
.PARAMETER ID
    Asset ID to retrieve from TeamDynamix. Always returns full detail. No
    other search options return full detail without setting -Detail.
.PARAMETER SearchText
    Text to search for in assets. Searches the text of the asset tag, serial
    number, supplier name, product model name, or manufacturer name.
.PARAMETER SerialLike
    LIKE search for asset serial number and tag.
.PARAMETER Detail
    Return full detail for asset. Default searches return partial detail.
.PARAMETER Exact
    Return only the asset that exactly matches the name (SearchText) or the
    serial number (SerialLike). Searches that don't include SearchText or
    SerialLike will ignore this setting.
.PARAMETER SavedSearchID
    Retrieve assets with specific saved search ID.
.PARAMETER StatusIDs
    Retrieve assets with specific status IDs.
.PARAMETER ExternalIDs
    Retreive assets with specific external IDs.
.PARAMETER IsInService
    Retrieve only assets that are in/out of service.
.PARAMETER StatusIDsPast
    Retrieve only assets with specific past status IDs.
.PARAMETER SupplierIDs
    Retrieve assets with specified supplier IDs.
.PARAMETER ManufacturerIDs
    Retrieve assets with specified manufacturer IDs.
.PARAMETER LocationIDs
    Retrieve assets with specified location IDs.
.PARAMETER LocationLike
    Retrieve assets from locations with names like the one specified.
.PARAMETER RoomID
    Retrieve assets with specific room ID.
.PARAMETER RoomLike
    Retrieve assets from rooms with names like the one specified.
.PARAMETER ExactLocation
    When using LocationLike and RoomLike searches, only return results that
    match the query exactly.
.PARAMETER ParentIDs
    Retrieve assets with specified parent asset IDs.
.PARAMETER ContractIDs
    Retrieve assets with specified contract IDs.
.PARAMETER ExcludeContractIDs
    Retrieve assets with contract IDs not specified.
.PARAMETER TicketIDs
    Retrieve assets with specified ticket IDs.
.PARAMETER FormIDs
    Retrieve assets with specified form IDs.
.PARAMETER ExcludeTicketIDs
    Retrieve assets with ticket IDs not specified.
.PARAMETER ProductModelIDs
    Retrieve assets with specified product model IDs.
.PARAMETER MaintenanceScheduleIDs
    Retrieve assets with specified maintenance schedule IDs.
.PARAMETER UsingDepartmentIDs
    Retrieve assets with specified using-department IDs.
.PARAMETER RequestingDepartmentIDs
    Retrieve assets with specified requesting-department IDs.
.PARAMETER OwningDepartmentIDs
    Retrieve assets with specified owning-department IDs.
.PARAMETER OwningDepartmentIDsPast
    Retrieve assets with specified past owning-department IDs.
.PARAMETER UsingCustomerIDs
    Retrieve assets with specified using-customer IDs.
.PARAMETER RequestingCustomerIDs
    Retrieve assets with specified requesting-customer IDs.
.PARAMETER OwningCustomerIDs
    Retrieve assets with specified owning-customer IDs.
.PARAMETER OwningCustomerIDsPast
    Retrieve assets with specified past owning-customer IDs.
.PARAMETER Attributes
    Retrieve assets with specified custom attributes.
.PARAMETER PurchaseCostFrom
    Retrieve assets with minimum purchase cost.
.PARAMETER PurchaseCostTo
    Retrieve assets with maximum purchase cost.
.PARAMETER ContractProviderID
    Retrieve assets with specific contract provider ID.
.PARAMETER AcquisitionDateFrom
    Retreive assets acquired no earlier than specific date.
.PARAMETER AcquisitionDateTo
    Retrieve assets acquired no later than specific date.
.PARAMETER ExpectedReplacementDateFrom
    Retreive assets expected to be replaced no earlier than specific date.
.PARAMETER ExpectedReplacementDateTo
    Retreive assets expected to be replaced no later than specific date.
.PARAMETER ContractEndDateFrom
    Retreive assets with contracts ending no earlier than specific date.
.PARAMETER ContractEndDateTo
    Retreive assets with contracts ending no later than specific date.
.PARAMETER OnlyParentAssets
    Retrieve only assets that have child assets
.PARAMETER MaxResults
    Maximum number of assets to return. Default 50.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDAsset -AuthenticationToken $Authentication

    Retrieves all assets from TeamDynamix.
.EXAMPLE
    C:\>Get-TDAsset -ID 1752 -AuthenticationToken $Authentication

    Retrieves asset number 1752 from TeamDynamix with full detail.
.EXAMPLE
    C:\>Get-TDAsset -SearchText cisco -Detail -AuthenticationToken $Authentication

    Retrieves first 50 assets containing the text "cisco" from TeamDynamix,
    with full detail.
.EXAMPLE
    C:\>$TaG18Complete = @('TaG18 Complete','Yes')
    C:\>Get-TDAsset -Attributes $TaG18Complete

    Retrieves assets whose 'TaG18 Complete' status is 'Yes', with minimal
    detail.
.EXAMPLE
    C:\>Get-TDAsset -SearchText 'Team5Laptop1' -Exact -AuthenticationToken $Authentication

    Retrieves only assets whose name matches "Team5Laptop1", if any, from
    TeamDynamix, with minimal detail.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDVendors.Name
                HelpText    = 'Names of manufacturers'
                IDParameter = 'ManufacturerIDs'
                IDsMethod   = '$TDVendors'
            }
            @{
                Name        = 'SupplierNames'
                ValidateSet = $TDVendors.Name
                HelpText    = 'Names of suppliers'
                IDParameter = 'SupplierIDs'
                IDsMethod   = '$TDVendors'
            }
            @{
                Name        = 'ProductModelNames'
                ValidateSet = $TDProductModels.Name
                HelpText    = 'Names of product models'
                IDParameter = 'ProductModelIDs'
                IDsMethod   = '$TDProductModels'
            }
            @{
                Name        = 'StatusNames'
                ValidateSet = $TDAssetStatuses.Name
                HelpText    = 'Names of asset statuses'
                IDParameter = 'StatusIDs'
                IDsMethod   = '$TDAssetStatuses'
            }
            @{
                Name        = 'StatusNamesPast'
                ValidateSet = $TDAssetStatuses.Name
                HelpText    = 'Names of asset statuses'
                IDParameter = 'StatusIDsPast'
                IDsMethod   = '$TDAssetStatuses'
            }
            @{
                Name        = 'OwningDepartmentNames'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Names of owning departments'
                IDParameter = 'OwningDepartmentIDs'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'RequestingDepartmentNames'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Names of requesting departments'
                IDParameter = 'RequestDepartmentIDs'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'UsingDepartmentNames'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Names of using departments'
                IDParameter = 'UsingDepartmentIDs'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'OwningDepartmentPastNames'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Names of past owning departments'
                IDParameter = 'OwningDepartmentPastIDs'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'SavedSearchName'
                Type        = 'string'
                ValidateSet = $TDAssetSearches.Name
                HelpText    = 'Names of saved search'
                IDParameter = 'SavedSearchNameID'
                IDsMethod   = '$TDAssetSearches'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
                $Location = Get-TDLocation -NameLike $LocationLike -RoomLike $RoomLike -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            # Location specified
            else
            {
                $Location = Get-TDLocation -NameLike $LocationLike -Exact:$ExactLocation -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                    $Location = Get-TDLocation -ID $LocationIDs[0] -RoomLike $RoomLike -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
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
            SearchEndpoint   = "$AppID/assets/search"
            IDEndpoint       = "$AppID/assets/$ID"
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
}

<#
.Synopsis
    Get list of users/departments attached to an asset from TeamDynamix
.DESCRIPTION
    Get list of users/departments attached to an asset from TeamDynamix.
.PARAMETER ID
    ID of asset whose attached users/departments will be retrieved.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDAssetResource -ID 1055 -AuthenticationToken $Authentication

    Retrieves list of all users/departments attatched to asset ID 1055 from
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            IDEndpoint       = "$AppID/assets/$ID/users"
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
}

<#
.Synopsis
    Create an asset in TeamDynamix
.DESCRIPTION
    Create a new asset in TeamDynamix. Status ID and serial number are
    required. Get list of valid status IDs from Get-TDAssetStatus.
.PARAMETER SerialNumber
    Serial number of asset to add to TeamDynamix.
.PARAMETER StatusID
    Status ID for new asset in TeamDynamix. Get list of valid statuses from
    Get-AssetStatus.
.PARAMETER FormID
    Form ID for new asset in TeamDynamix. Get a list of valid forms from
    Get-TDAssetForm.
.PARAMETER LocationID
    Location ID for new asset in TeamDynamix.
.PARAMETER LocationRoomID
    Room ID for new asset in TeamDynamix.
.PARAMETER LocationName
    Location name for asset in TeamDynamix.
.PARAMETER LocationRoomName
    Room name for asset in TeamDynamix.
.PARAMETER ParentID
    Parent ID for new asset in TeamDynamix.
.PARAMETER ProductModelID
    Product model ID for new asset in TeamDynamix.
.PARAMETER MaintenanceScheduleID
    Maintenance schedule ID for new asset in TeamDynamix.
.PARAMETER OwningDepartmentID
    Owning department ID for new asset in TeamDynamix.
.PARAMETER PurchaseCost
    Purchase cost of new asset in TeamDynamix.
.PARAMETER Tag
    Asset tag number for new asset in TeamDynamix.
.PARAMETER RequestingCustomerID
    Requesting customer ID for new asset in TeamDynamix.
.PARAMETER OwningCustomerID
    Owning customer ID for new asset in TeamDynamix.
.PARAMETER RequestingDepartmentID
    Requesting department ID for new asset in TeamDynamix.
.PARAMETER Attributes
    Custom attributes for new asset in TeamDynamix. Format as hashtable.
.PARAMETER AcquisitionDate
    Purchase date of new asset in TeamDynamix.
.PARAMETER ExpectedReplacementDate
    Expected replacement date of new asset in TeamDynamix.
.PARAMETER ExternalID
    Local ID number for new asset in TeamDynamix.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDAsset -SerialNumber 1055 - StatusID 3042 -AuthenticationToken $Authentication

    Creates a new asset in TeamDynamix.
.EXAMPLE
    C:\>$Asset1 | New-TDAsset -AuthenticationToken $Authentication

    Using an object, create a new asset from the pipeline in TeamDynamix.
.EXAMPLE
    C:\>$ExceptionFiledID = (Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'ExceptionFiled').ID
    C:\>$ExceptionFiledYesID = ((Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'ExceptionFiled').Choices | Where-Object Name -eq 'Yes').ID
    C:\>New-TDAsset -SerialNumber 1055 - StatusID 3042 -Attributes @{ID=$ExceptionFiledID;Value=$ExceptionFiledYesID}

    Creates a new asset in TeamDynamix with a custom attribute.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDVendors.Name
				HelpText    = 'Name of supplier'
                IDParameter = 'SupplierID'
                IDsMethod   = '$TDVendors'
			}
			@{
				Name        = 'ProductModelName'
                Type        = 'string'
				ValidateSet = $TDProductModels.Name
				HelpText    = 'Name of product model'
                IDParameter = 'ProductModelID'
                IDsMethod   = '$TDProductModels'
			}
			@{
				Name        = 'StatusName'
                Type        = 'string'
				ValidateSet = $TDAssetStatuses.Name
                HelpText    = 'Names of asset statuses'
                IsMandatory = $true
                ParameterSetName = 'Name'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDAssetStatuses'
			}
			@{
				Name        = 'OwningDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
			@{
				Name        = 'RequestingDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Name of requesting department'
                IDParameter = 'RequestingDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
                $Location = Get-TDLocation -NameLike $LocationName -RoomLike $LocationRoomName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            # Location specified
            else
            {
                $Location = Get-TDLocation -NameLike $LocationName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                $Location = Get-TDLocation -ID $LocationID -RoomLike $LocationRoomName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                Endpoint   = "$AppID/assets"
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
}

<#
.Synopsis
    Modify an asset or assets in TeamDynamix
.DESCRIPTION
    Modify properties of a single asset or process bulk asset updates in
    TeamDynamix. Bulk updates handle up to 1,000 assets at a time. For bulk
    updates, use the CreateItems and UpdateItems parameters to specify if
    updates should create new items as necessary and/or update existing items.
    By default, both CreateItems and UpdateItems are set to create and/or
    update as necessary.
.PARAMETER ID
    ID number of the asset to modify in TeamDynamix.
.PARAMETER SerialNumber
    New serial number of asset in TeamDynamix.
.PARAMETER StatusID
    New status ID for asset in TeamDynamix. Get list of valid statuses from
    Get-TDAssetStatus.
.PARAMETER FormID
    New form ID for asset in TeamDynamix. Get list of valid forms from
    Get-TDAssetForm
.PARAMETER LocationID
    New location ID for asset in TeamDynamix.
.PARAMETER LocationRoomID
    New room ID for asset in TeamDynamix.
.PARAMETER LocationName
    New location name for asset in TeamDynamix.
.PARAMETER LocationRoomName
    New room name for asset in TeamDynamix.
.PARAMETER ParentID
    New parent ID for asset in TeamDynamix.
.PARAMETER ProductModelID
    New product model ID for asset in TeamDynamix.
.PARAMETER MaintenanceScheduleID
    New maintenance schedule ID for asset in TeamDynamix.
.PARAMETER OwningDepartmentID
    New owning department ID for asset in TeamDynamix.
.PARAMETER PurchaseCost
    New purchase cost of asset in TeamDynamix.
.PARAMETER Tag
    New asset tag number for asset in TeamDynamix.
.PARAMETER RequestingCustomerID
    New requesting customer ID for asset in TeamDynamix.
.PARAMETER OwningCustomerID
    New Owning customer ID for asset in TeamDynamix.
.PARAMETER RequestingDepartmentID
    New requesting department ID for asset in TeamDynamix.
.PARAMETER Attributes
    New custom attributes for asset in TeamDynamix. Format as hashtable.
.PARAMETER AcquisitionDate
    New purchase date of asset in TeamDynamix.
.PARAMETER ExpectedReplacementDate
    Expected replacement date of asset in TeamDynamix.
.PARAMETER ExternalID
    New local ID number for asset in TeamDynamix.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER RemoveAttributes
    Names of custom attributes that should be removed from the asset.
.PARAMETER Bulk
    Indicates that this will be a bulk update. Bulk updates require input data
    in form of an array of TeamDynamix.Api.Assets.Asset.
.PARAMETER Items
    Bulk asset update data. Maximum of 1,000 items at a time.
.PARAMETER CreateItems
    Create new items as part of bulk update.
.PARAMETER UpdateItems
    Update existing items as part of bulk update
.PARAMETER Passthru
    Return updated asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDAsset -ID 5504 - StatusID 3042 -AuthenticationToken $Authentication

    Set new status ID for asset ID 5504 in TeamDynamix.
.EXAMPLE
    C:\>$Asset1 | Set-TDAsset -AuthenticationToken $Authentication

    Using an object, modify existing asset from the pipeline in TeamDynamix.
.EXAMPLE
    C:\>$ExceptionFiledID = (Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'Exception Filed').ID
    C:\>$ExceptionFiledYesID = ((Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'Exception Filed').Choices | Where-Object Name -eq 'Yes').ID
    C:\>Set-TDAsset -ID 5504 -Attributes @{ID=$ExceptionFiledID;Value=$ExceptionFiledYesID}

    Adds or sets a custom attribute on an asset in TeamDynamix.
.EXAMPLE
    C:\>Set-TDAsset -ID 5504 -Attributes @(@('Encryption Status','Encrypted'),@('Exception Filed','Yes'))

    Adds or sets two custom attributes on an asset in TeamDynamix.
.EXAMPLE
    C:\>Set-TDAsset -ID 5504 -RemoveAttributes ('Encryption Status','Exception Filed')

    Removes two specified custom attributes to an asset in TeamDynamix.
.EXAMPLE
    C:\>Set-TDAsset -ID 5504 -Attributes @('Multi-Select','FirstChoice,ThirdChoice')

    Adds specified custom attribute that offers multiple choices to an asset in
    TeamDynamix. Use a comma-separated string for the choices.

.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDVendors.Name
				HelpText    = 'Name of supplier'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'SupplierID'
                IDsMethod   = '$TDApplications'
			}
			@{
				Name        = 'ProductModelName'
				ValidateSet = $TDProductModels.Name
				HelpText    = 'Name of product model'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'ProductModelID'
                IDsMethod   = '$TDProductModels'
			}
			@{
				Name        = 'StatusName'
				ValidateSet = $TDAssetStatuses.Name
				HelpText    = 'Name of asset statuse'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDAssetStatuses'
			}
			@{
				Name        = 'OwningDepartmentName'
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Names of owning departments'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
			@{
				Name        = 'RequestingDepartmentName'
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Names of requesting departments'
                ParameterSetName = 'Non-Bulk'
                IDParameter = 'RequestingDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
                $Location = Get-TDLocation -NameLike $LocationName -RoomLike $LocationRoomName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            # Location specified
            else
            {
                $Location = Get-TDLocation -NameLike $LocationName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                $Location = Get-TDLocation -ID $LocationID -RoomLike $LocationRoomName -Exact -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                        Endpoint   = "$AppID/assets/$ID"
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
}

<#
.Synopsis
    Get asset statuses from TeamDynamix
.DESCRIPTION
    Get asset statuses from TeamDynamix. Retrieve asset status by ID, search by
    text, or whether the asset status is active or out of service. Includes
    statuses such as "In Use" and "Retired".
.PARAMETER ID
    ID of the asset status to retrieve.
.PARAMETER SearchText
    Text to search for in the asset status. "Filter" may be used instead of
    "SearchText".
.PARAMETER IsActive
    Sets whether the asset status is active for the search.
.PARAMETER IsOutOfService
    Sets whether the asset status is out of service for the search.
.PARAMETER AppID
    Application ID for the asset status.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDAssetStatus -AuthenticationToken $Authentication

    Retrieves the list of all asset statuses from TeamDynamix.
.EXAMPLE
    C:\Get-TDAssetStatus -ID 2377 -AuthenticationToken $Authentication

    Retrieves asset status with ID 2377 from TeamDynamix.
.EXAMPLE
    C:\Get-TDAssetStatus -SearchText 'Use' -IsActive $false -IsOutOfService $true

    Retrieves asset statuses containing the word "Use", which are not active
    and which are out of service.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/assets/statuses"
            SearchEndpoint   = "$AppID/assets/statuses/search"
            IDEndpoint       = "$AppID/assets/statuses/$ID"
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
}

<#
.Synopsis
    Create a new asset status in TeamDynamix
.DESCRIPTION
    Creates a new asset status in TeamDynamix.
.PARAMETER Name
    Name of the new asset status to create.
.PARAMETER Description
    Description of the new asset status to create.
.PARAMETER Order
    The order of the new asset status in lists.
.PARAMETER IsActive
    Sets whether the asset status is active. Default: true.
.PARAMETER IsOutOfService
    Sets whether the asset status is out of service. Default: false.
.PARAMETER AppID
    Application ID for the asset status.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDAssetStatus -Name 'New Status' -Description 'New asset status' -AuthenticationToken $Authentication

    Creates a new active asset statuses in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/statuses"
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
}

<#
.Synopsis
    Modify an asset status in TeamDynamix
.DESCRIPTION
    Modifies an asset status in TeamDynamix.
.PARAMETER ID
    ID of the asset status to modify
.PARAMETER Name
    New name of the asset status.
.PARAMETER Description
    New description of the asset status.
.PARAMETER Order
    New order of the asset status in lists.
.PARAMETER IsActive
    Set whether the asset status is active.
.PARAMETER IsOutOfService
    Set whether the asset status is out of service.
.PARAMETER AppID
    Application ID for the asset status.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDAssetStatus -AuthenticationToken $Authentication

    Retrieves the list of all asset statuses from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/statuses/$ID"
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
}

<#
.Synopsis
    Get asset maintenance windows from TeamDynamix
.DESCRIPTION
    Gets a specific maintenance window or searches for matching windows
    from TeamDynamix. Get a list of all active maintenance windows, or use the
    -filter option to match on a substring from the schedule name. Maintenance
    windows are specific to the asset application.
.PARAMETER ID
    ID of maintenance window to get.
.PARAMETER NameLike
    Substring search filter. May also use "Filter" instead of "NameLike".
.PARAMETER IsActive
    Boolean to limit return set to active maintenance windows ($true), inactive
    maintenance windows ($false), or all ($null).
.PARAMETER AppID
    Application ID for the maintenance window.
.PARAMETER Exact
    Return only a single unambiguous match for NameLike searches. If search
    was ambiguous, that is, matched more than one location or room, return no
    result at all.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Get-TDMaintenanceWindow -ID 6331 -AuthenticationToken $Authentication

   Returns a maintenance window with ID 6331.
.EXAMPLE
   C:\>Get-TDMaintenanceWindow -AuthenticationToken $Authentication

   Returns a list of all active maintenance windows.
.EXAMPLE
   C:\>Get-TDMaintenanceWindow -IsActive $null -AuthenticationToken $Authentication

   Returns a list of all maintenance windows, including active and inactive
   windows.
.EXAMPLE
   C:\>Get-TDMaintenanceWindow -Filter Cisco -AuthenticationToken $Authentication -IsActive $false

   Returns list of inactive maintenance windows with the word, "Cisco" in
   the name in the of the schedule.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/cmdb/maintenancewindows"
            SearchEndpoint   = "$AppID/cmdb/maintenancewindows/search"
            IDEndpoint       = "$AppID/cmdb/maintenancewindows/$ID"
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
}

<#
.Synopsis
    Create a new maintenance window in TeamDynamix
.DESCRIPTION
    Creates a new maintenance window in TeamDynamix. Maintenance windows are
    specific to the asset application.
.PARAMETER Name
    Name of maintenance window.
.PARAMETER Description
    Description of maintenance window.
.PARAMETER TimeZoneID
    ID number of Time Zone.
.PARAMETER IsActive
    Set whether maintenance window is active or not. Default: true.
.PARAMETER AppID
    Application ID for the maintenance window.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDMaintenanceWindow -Name 'New maintenance window' -Description 'Maintenance window for assets' -AuthenticationToken $Authentication

   Creates a new active maintenance window named, "New maintenance window".
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/maintenancewindows"
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
}

<#
.Synopsis
    Modify a maintenance window in TeamDynamix
.DESCRIPTION
    Modifies a maintenance window in TeamDynamix.
.PARAMETER ID
    ID of mainteance window to modify in TeamDynamix.
.PARAMETER Name
    Name of maintenance window.
.PARAMETER Description
    Description of maintenance window.
.PARAMETER TimeZoneID
    ID number of Time Zone.
.PARAMETER IsActive
    Set whether maintenance windows is active or not.
.PARAMETER AppID
    Application ID for the maintenance window.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDMaintenanceWindow -Name 'New maintenance window' -Description 'Maintenance window for assets' -AuthenticationToken $Authentication

   Creates a new active maintenance window named, "New maintenance window".
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/maintenancewindows/$ID"
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
}

<#
.Synopsis
    Get asset vendor from TeamDynamix
.DESCRIPTION
    Gets a specific vendor or searches for matching vendors
    from TeamDynamix. Get a list of all active vendors, or use the -SearchText
    option to match on a substring from the vendors name, description, account
    number, or primary contact name. Or use the -NameLike option to match on a
    vendor name (optionally add -Exact to only match the vendor name exactly).
.PARAMETER ID
    Search for a specific vendor ID.
.PARAMETER SearchText
    Substring search filter on name, description, and primary contact name.
.PARAMETER NameLike
    Filter on vendor name only.
.PARAMETER IsActive
    Boolean to limit return set to active users ($true), or inactive users
    ($false).
.PARAMETER OnlyManufacturers
    Boolean to limit to vendors who are manufacturers, or not.
.PARAMETER OnlySuppliers
    Boolean to limit to vendors who are suppliers, or not.
.PARAMETER OnlyContractProviders
    Boolean to limit to vendors who are contract providers, or not.
.PARAMETER CustomAttributes
    Custom attributes to filter on.
.PARAMETER AppID
    Application ID for the vendor.
.PARAMETER Exact
    Return only a single unambiguous match for NameLike searches. If search
    was ambiguous, that is, matched more than one location or room, return no
    result at all.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Get-TDVendor -IsActive $Null -AuthenticationToken $Authentication

   Returns a list of all active vendors, including inactive vendors.
.EXAMPLE
   C:\>Get-TDVendor -AuthenticationToken $Authentication

   Returns a list of all active vendors.
.EXAMPLE
   C:\>Get-TDVendor -filter Cisco -AuthenticationToken $Authentication -IsActive $false

   Returns list of vendors with the word, "Cisco" in the name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/assets/vendors"
            SearchEndpoint   = "$AppID/assets/vendors/search"
            IDEndpoint       = "$AppID/assets/vendors/$ID"
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
}

<#
.Synopsis
    Get the list of all product models from TeamDynamix
.DESCRIPTION
    Get the list of all product models from TeamDynamix.
.PARAMETER ID
    Product model ID to retrieve from TeamDynamix.
.PARAMETER SearchText
    Substring search filter.
.PARAMETER ManufacturerID
    Filter product model based on manufacturer ID.
.PARAMETER ProductTypeID
    Filter product model based on product type ID.
.PARAMETER IsActive
    Boolean to limit return set to active configuration item types ($true),
    inactive configuration item types ($false), or all ($null). Default is all.
.PARAMETER Attributes
    Array of custom attributes to filter configuration items returned.
.PARAMETER AppID
    Application ID for the product type.
.PARAMETER Detail
    Return full detail for product model.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProductModel -AuthenticationToken $Authentication

    Retrieves the list of all active product models from TeamDynamix.
.EXAMPLE
    C:\>Get-TDProductModel -ID 5564 -AuthenticationToken $Authentication

    Retrieves product model ID 5564 from TeamDynamix.
.EXAMPLE
    C:\>$ExceptionFiledID = (Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'Exception Filed').ID
    C:\>$ExceptionFiledYesID = ((Get-TDCustomAttribute -ComponentID Asset | Where-Object Name -eq 'Exception Filed').Choices | Where-Object Name -eq 'Yes').ID
    C:\>Get-TDProductModel -ID 5504 -Attributes @($ExceptionFiledID,$ExceptionFiledYesID)

    Retrieves a product model using a custom attribute in TeamDynamix.
.EXAMPLE
    C:\>Get-TDProductModel -ID 5504 -Attributes @(@('Encryption Status','Encrypted'),@('Exception Filed','Yes'))

    Retrieves a product model using two custom attributes in TeamDynamix.
.EXAMPLE
    C:\>Get-TDProductModel -SearchText "Laptop" -Detail -AuthenticationToken $Authentication

    Retrieves the full detail for product models with a name like "Laptop" from
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDVendors.Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$ProductType'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/assets/models"
            SearchEndpoint   = "$AppID/assets/models/search"
            IDEndpoint       = "$AppID/assets/models/$ID"
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
        if ($Detail)
        {
            if ($Return)
            {
                $Return = $Return.ID | Get-TDProductModel -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Adds a comment to the asset feed for an asset in TeamDynamix
.DESCRIPTION
    Adds a comment to the asset feed for an asset in TeamDynamix.
.PARAMETER ID
    ID of asset whose feed will be updated.
.PARAMETER Comments
    Comment to be added to asset feed.
.PARAMETER Notify
    Email addresses of individuals to notify with the comment.
.PARAMETER IsPrivate
    Switch to indicate if the comment should be flagged as private. Default is
    "not private".
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDAssetComment -ID 1055 -Comment "Don't update this system without consult." -AuthenticationToken $Authentication

    Adds the comment to not update the system without consultation to asset
    ID 1055 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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

<#
.Synopsis
    Add a file attachment to an asset in TeamDynamix
.DESCRIPTION
    Add a file attachment to an asset in TeamDynamix. Returns
    information regarding the attachment of the form
    TeamDynamix.Api.Attachments.Attachment.
.PARAMETER ID
    ID number of the asset the attachment will be added to in TeamDynamix.
.PARAMETER FilePath
    The full path and filename of the file to be added as an attachment.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\> Add-TDAssetAttachment -ID 111 -FilePath C:\temp\1.jpg -AuthenticationToken $Authentication

    Attaches the file c:\temp\1.jpg to asset ID 111 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>function Add-TDAssetAttachment
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
}

<#
.Synopsis
    Adds a resource to an asset in TeamDynamix
.DESCRIPTION
    Adds a resource (user or group) to an assetin TeamDynamix.
.PARAMETER ID
    ID of asset to which the resource will be added.
.PARAMETER ResourceID
    Resource ID to be added to the asset.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDAssetResource -ID 1055 -ResourceID 5039 -AuthenticationToken $Authentication

    Adds resource 5039 to asset ID 1055in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/$ID/users/$ResourceID"
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
}

<#
.Synopsis
    Removes a resource from an asset in TeamDynamix
.DESCRIPTION
    Removes a resource (user or group) from an asset in TeamDynamix.
.PARAMETER ID
    ID of asset to be removed from the resource.
.PARAMETER ResourceID
    Resource ID from which the asset will be removed.
.PARAMETER AppID
    Application ID for the asset.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDAssetResource -ID 1055 -ResourceID 5039 -AuthenticationToken $Authentication

    Removes asset ID 1055 from resource ID 5039 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/$ID/users/$ResourceID"
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
}

<#
.Synopsis
    Gets list of custom attributes from TeamDynamix
.DESCRIPTION
    Gets a list of custom attributes for a specific component from TeamDynamix.
.PARAMETER ComponentID
    ID/Name of component whose custom attributes are to be retrieved.
.PARAMETER AssociatedTypeName
    Name of ticket type whose custom attributes are to be retrieved.
.PARAMETER AppID
    ID of application whose custom attributes are to be retrieved.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDCustomAttribute -ComponentID Person -AuthenticationToken $Authentication

    Retrieves all custom attributes for users from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
        if (($ComponentID -in $CustomAttributesTable.$Environment.Keys) -and ("AppID-$AppID" -in $CustomAttributesTable.$Environment.$ComponentID.Keys))
        {
            $Return = $CustomAttributesTable.$Environment.$ComponentID."AppID-$AppID"
        }
        else # Component ID has not been looked up, look it up and add it to the table
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
            $CustomAttributesTable.$Environment.$ComponentID += @{"AppID-$AppID" = $Return}
        }
        return $Return
    }
}

<#
.Synopsis
    Gets list of choices for specified custom attribute from TeamDynamix
.DESCRIPTION
    Gets list of choices for specified custom attribute from TeamDynamix.
.PARAMETER ID
    ID of the custom attributes whose choices are to be retrieved.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDCustomAttributeChoice -ID 1057 -AuthenticationToken $Authentication

    Retrieves valid choices for custom attributes ID 1057 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Add a choice to the specified custom attribute in TeamDynamix
.DESCRIPTION
    Add a choice to the specified custom attribute in TeamDynamix.
.PARAMETER ID
    ID of the custom attribute to add a new choice to.
.PARAMETER Name
    Name of the new choice.
.PARAMETER IsActive
    Sets whether the choice is active. Default: is active.
.PARAMETER Order
    Sets the order of the choice in the list. Choices are sorted by Order,
    then by name, in ascending order. Default: 0.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDCustomAttributeChoice -ID 365 -Name 'Choice 1' -AuthenticationToken $Authentication

    Adds a choice, "Choice 1" to custom attribute ID 365 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Removes a choice from the specified custom attribute in TeamDynamix
.DESCRIPTION
    Removes a choice from the specified custom attribute in TeamDynamix.
.PARAMETER ID
    ID of the custom attribute to remove the choice from.
.PARAMETER ChoiceID
    ID of the choice to remove.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDCustomAttributeChoice -ID 1057 -ChoiceID 67034 -AuthenticationToken $Authentication

    Removes choice 67034 from custom attribute ID 1057 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Edits a choice for the specified custom attribute in TeamDynamix
.DESCRIPTION
     Edits a choice for the specified custom attribute in TeamDynamix.
.PARAMETER ID
    ID of the custom attribute whose choice will be edited.
.PARAMETER ChoiceID
    ID of the choice to be edited
.PARAMETER Name
    Name of the new choice.
.PARAMETER IsActive
    Sets whether the choice is active. Default: is active.
.PARAMETER Order
    Sets the order of the choice in the list. Choices are sorted by Order,
    then by name, in ascending order. Default: 0.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDCustomAttributeChoice -ID 54465 -ChoiceID 3442 -IsActive $false -AuthenticationToken $Authentication

    Sets choice ID 3442 for custom attribute ID 54465 to inactive in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Get configuration item types from TeamDynamix
.DESCRIPTION
    Gets a specific configuration item type or searches for matching
    configuration item types from TeamDynamix. Get a list of all configuration
    item types, or use the -filter option to match on a substring from the type
    name.
.PARAMETER ID
    ID of configuration item type to get.
.PARAMETER SearchText
    Substring search filter.
.PARAMETER IsActive
    Boolean to limit return set to active configuration item types ($true),
    inactive configuration item types ($false), or all ($null).
.PARAMETER IsOrganizationallyDefined
    Boolean to limit return set to configuration item types that are
    organizationally defined.
.PARAMETER AppID
    Application ID for the configuration item type.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Get-TDConfigurationItemType -ID 6331 -AuthenticationToken $Authentication

   Returns a configuration item type with ID 6331.
.EXAMPLE
   C:\>Get-TDConfigurationItemType -AuthenticationToken $Authentication

   Returns a list of all active configuration item types.
.EXAMPLE
   C:\>Get-TDConfigurationItemType -IsActive $null -AuthenticationToken $Authentication

   Returns a list of all configuration item types, including active and
   inactive types.
.EXAMPLE
   C:\>Get-TDConfigurationItemType -Filter Grad -IsActive $false -AuthenticationToken $Authentication

   Returns list of inactive configuration item types with the word, "Grad" in
   the name in the of the configuration item type.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/cmdb/types"
            SearchEndpoint   = "$AppID/cmdb/types/search"
            IDEndpoint       = "$AppID/cmdb/types/$ID"
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
}

<#
.Synopsis
    Create a new configuration item type in TeamDynamix
.DESCRIPTION
    Creates a new configuration item type in TeamDynamix.
.PARAMETER Name
    Name of configuration item type.
.PARAMETER IsActive
    Set whether configuration item type is active or not. Default: true.
.PARAMETER AppID
    Application ID for the configuration item type.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDConfigurationItemType -Name 'New configuration item type' -AuthenticationToken $Authentication

   Creates a new active configuration item type named, "New configuration item
   type".
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/types"
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
}

<#
.Synopsis
    Modify a configuration item type in TeamDynamix
.DESCRIPTION
    Modifies a configuration item type in TeamDynamix.
.PARAMETER ID
    ID of configuration item type to modify in TeamDynamix.
.PARAMETER Name
    Name of configuration item type.
.PARAMETER IsActive
    Set whether configuration item type is active or not.
.PARAMETER AppID
    Application ID for the configuration item type.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Set-TDConfigurationItemType -ID 4531 -Name 'Modified configuration item type' -AuthenticationToken $Authentication

   Modifies configuration item type with ID 4531, to have a new name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/types/$ID"
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
}

<#
.Synopsis
    Gets a configuration item from TeamDynamix
.DESCRIPTION
    Gets the specified configuration item from TeamDynamix.
.PARAMETER ID
    ID of the configuration item to be retrieved.
.PARAMETER AppID
    Application ID for the configuration item.
.PARAMETER NameLike
    Filter configuration items by name.
.PARAMETER IsActive
    Boolean to limit return set to active configuration items ($true), or
    inactive configuation items ($false).
.PARAMETER TypeIDs
    List of configuration type IDs whose configuration items are to be
    retrieved.
.PARAMETER MaintenanceScheduleIDs
    List of maintenance schedule IDs whose configuration items are to be
    retrieved.
.PARAMETER CustomAttributes
    Array of custom attributes to filter configuration items returned.
.PARAMETER Exact
    Return only a single unambiguous match for NameLike searches. If search
    was ambiguous, that is, matched more than one location or room, return no
    result at all.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDConfigurationItem -AuthenticationToken $Authentication

    Retrieves all active configuration items from TeamDynamix.
.EXAMPLE
    C:\>Get-TDConfigurationItem -ID 1057 -AuthenticationToken $Authentication

    Retrieves configuration item with ID 1057 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDConfigurationItemTypes.Name
				HelpText    = 'Names of configuration item types'
                IDParameter = 'TypeIDs'
                IDsMethod   = '$TDConfigurationItemTypes'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            SearchEndpoint   = "$AppID/cmdb/search"
            IDEndpoint       = "$AppID/cmdb/$ID"
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
}

<#
.Synopsis
    Create a configuration item in TeamDynamix
.DESCRIPTION
    Create a new configuration item in TeamDynamix. Name and type ID are
    required. Get list of valid type IDs from Get-TDConfigurationItemType.
.PARAMETER Name
    Name of the configuration item.
.PARAMETER TypeID
    Type ID of the configuration item. See Get-TDConfigurationItemType for
    valid type IDs.
.PARAMETER FormID
    ID of form to use for the configuration item.
.PARAMETER AppID
    Application ID where the configuration item will be created.
.PARAMETER LocationID
    Location ID for new configuration item in TeamDynamix.
.PARAMETER LocationRoomID
    Room ID for new configuration item in TeamDynamix.
.PARAMETER OwningDepartmentID
    Owning department ID for new configuration item in TeamDynamix.
.PARAMETER OwnerUID
    Owner ID for new configuration item in TeamDynamix.
.PARAMETER OwningGroupID
    Owning group ID number for new configuration item in TeamDynamix.
.PARAMETER IsActive
    Set configuration item active/inactive in TeamDynamix.
.PARAMETER ExternalID
    Local ID number for new configuration item in TeamDynamix.
.PARAMETER ExternalSourceID
    Local ID number for source of new configuration item in TeamDynamix.
.PARAMETER Attributes
    Custom attributes for new configuration item in TeamDynamix. Format as
    hashtable.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDConfigurationItem -Name 'Configuration Item 1' -TypeID 3042 -AuthenticationToken $Authentication

    Creates a new asset in TeamDynamix.
.EXAMPLE
    C:\>$CI | New-TDConfigurationItem -AuthenticationToken $Authentication

    Using an object, create a new asset from the pipeline in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDConfigurationItemTypes.Name
				HelpText    = 'Name of configuration type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDConfigurationItemTypes'
			}
			@{
				Name        = 'FormName'
                Type        = 'string'
				ValidateSet = $TDForms.Name
				HelpText    = 'Name of form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms'
			}
			@{
				Name        = 'OwningDepartmentName'
                Type        = 'string'
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
			@{
				Name        = 'OwningGroupName'
                Type        = 'string'
				ValidateSet = $TDGroups.Name
				HelpText    = 'Name of owning group'
                IDParameter = 'OwningGroupID'
                IDsMethod   = '$TDGroups'
			}
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb"
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
}

<#
.Synopsis
    Edit a configuration item in TeamDynamix
.DESCRIPTION
    Edit a new configuration item in TeamDynamix. Name and type ID are
    required. Get list of valid type IDs from Get-TDConfigurationItemType.
.PARAMETER Name
    Name of the configuration item.
.PARAMETER TypeID
    Type ID of the configuration item. See Get-TDConfigurationItemType for
    valid type IDs.
.PARAMETER LocationID
    Location ID for new configuration item in TeamDynamix.
.PARAMETER LocationRoomID
    Room ID for new configuration item in TeamDynamix.
.PARAMETER OwningDepartmentID
    Owning department ID for new configuration item in TeamDynamix.
.PARAMETER OwnerID
    Owner ID for new configuration item in TeamDynamix.
.PARAMETER OwningGroupID
    Owning group ID number for new configuration item in TeamDynamix.
.PARAMETER IsActive
    Set configuration item active/inactive in TeamDynamix.
.PARAMETER ExternalID
    Local ID number for new configuration item in TeamDynamix.
.PARAMETER ExternalSourceID
    Local ID number for source of new configuration item in TeamDynamix.
.PARAMETER Attributes
    Custom attributes for new configuration item in TeamDynamix. Format as
    hashtable.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDConfigurationItem -Name 'Configuration Item 1' -TypeID 3042 -AuthenticationToken $Authentication

    Creates a new asset in TeamDynamix.
.EXAMPLE
    C:\>$CI | Set-TDConfigurationItem -AuthenticationToken $Authentication

    Using an object, create a new asset from the pipeline in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDAccounts.Name
				HelpText    = 'Name of owning department'
                IDParameter = 'OwningDepartmentID'
                IDsMethod   = '$TDAccounts'
			}
			@{
				Name        = 'OwningGroupName'
                Type        = 'string'
				ValidateSet = $TDGroups.Name
				HelpText    = 'Name of owning group'
                IDParameter = 'OwningGroupID'
                IDsMethod   = '$TDGroups'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/$ID"
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
}

<#
.Synopsis
    Gets list of active configuration relationship types from TeamDynamix
.DESCRIPTION
    Gets list of active configuration relationship types from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDConfigurationRelationshipType -AuthenticationToken $Authentication

    Retrieves list of active configuration relationship types from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            IDEndpoint       = "$AppID/cmdb/relationshiptypes"
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
}

<#
.Synopsis
    Gets list of relationships for a configuration item from TeamDynamix
.DESCRIPTION
    Gets list of relationships for a configuration item from TeamDynamix.
.PARAMETER ID
    ID of configuration item.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDConfigurationItemRelationship -ID 4056 -AuthenticationToken $Authentication

    Retrieves list of relationships for configuration item ID 4056 from
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            IDEndpoint       = "$AppID/cmdb/$ID/relationship"
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
}

<#
.Synopsis
    Removes relationship from a configuration item in TeamDynamix
.DESCRIPTION
    Removes relationship from a configuration item in TeamDynamix.
.PARAMETER ID
    ID of configuration item whose relationship is to be removed.
.PARAMETER RelationshipID
    Relationship ID to remove from the configuration item.
.PARAMETER AppID
    Application ID for the configuration item.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDConfigurationItemRelationship -ID 1055 -RelationshipID 5039 -AuthenticationToken $Authentication

    Removes relationship ID 5039 from configuration item ID 1055 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/$ID/relationships/$RelationshipID"
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
}

<#
.Synopsis
    Add a file attachment to an configuration item in TeamDynamix
.DESCRIPTION
    Add a file attachment to an configuration item in TeamDynamix. Returns
    information regarding the attachment of the form
    TeamDynamix.Api.Attachments.Attachment.
.PARAMETER ID
    ID number of the configuration item the attachment will be added to in
    TeamDynamix.
.PARAMETER FilePath
    The full path and filename of the file to be added as an attachment.
.PARAMETER AppID
    Application ID for the configuration item.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\> Add-TDConfigurationItemAttachment -ID 111 -FilePath C:\temp\1.jpg -AuthenticationToken $Authentication

    Attaches the file c:\temp\1.jpg to configuration item ID 111 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>function Add-TDConfigurationItemAttachment
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Adds a relationship between a configuration item and another item in
    TeamDynamix
.DESCRIPTION
    Adds a relationship between a configuration item and another item in
    TeamDynamix.
.PARAMETER ID
    ID of configuration item whose relationship will be updated.
.PARAMETER OtherItemID
    Other item to be added with a relationship to configuration item.
.PARAMETER TypeID
    Type ID of associated relationship type.
.PARAMETER isParent
    If true, the configuration item specified by ID will be the parent, if
    false, the other item specified by OtherItemID will be the parent.
.PARAMETER RemoveExisting
    If true, remove existing type ID and parent combinations. Default is false.
.PARAMETER AppID
    Application ID for the configuration item.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDConfigurationItemRelationship -ID 1055 -TypeID 9945 -OtherItemID 7010 -AuthenticationToken $Authentication

    Adds a relationship of type with ID 9945 between configuration item ID 9945
    and other item ID 1055 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        Write-ActivityHistory "Adding relationship for TeamDynamix asset ID $ID, of type $TypeID with comment, $Comment."
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/cmdb/$ID/relationships?typeId=$TypeID&otherItemId=$OtherItemID&isParent=$IsParent&removeExisting=$RemoveExisting" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
        if ($Return)
        {
            return [TeamDynamix_Api_Cmdb_ConfigurationItemRelationship]::new($Return)
        }
    }
}

<#
.Synopsis
    Create a product model in TeamDynamix
.DESCRIPTION
    Create a new product model in TeamDynamix. Name, product type ID, and
    manufacturer ID are required.
.PARAMETER Name
    Name of the product model.
.PARAMETER Description
    Description of the product model.
.PARAMETER IsActive
    Set configuration item active/inactive in TeamDynamix. Default is true.
.PARAMETER ManufacturerID
    Manufacturer ID for the product model.
.PARAMETER ProductTypeID
    Product type ID of the product model.
.PARAMETER PartNumber
    Part number for the product model.
.PARAMETER Attributes
    Custom attributes for new product model in TeamDynamix. Format as
    hashtable.
.PARAMETER AppID
    Application ID where the product model will be created.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDProductModel -Name 'Product Name 1' -ManufacturerID 3042 -ProductTypeID 7740 -AuthenticationToken $Authentication

    Creates a new product model in TeamDynamix.
.EXAMPLE
    C:\>$ProductModel | New-TDProductModel -AuthenticationToken $Authentication

    Using an object, create a new product model from the pipeline in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDVendors.Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$TDProductTypes'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/models"
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
}

<#
.Synopsis
    Edit a product model in TeamDynamix
.DESCRIPTION
    Edit a new product model in TeamDynamix.
.PARAMETER ID
    ID of product model to modify in TeamDynamix.
.PARAMETER Name
    Name of the product model item.
.PARAMETER Description
    Description of the product model.
.PARAMETER IsActive
    Set configuration item active/inactive in TeamDynamix. Default is true.
.PARAMETER ManufacturerID
    Manufacturer ID for the product model.
.PARAMETER ProductTypeID
    Product type ID of the product model.
.PARAMETER PartNumber
    Part number for the product model.
.PARAMETER Attributes
    Custom attributes for new configuration item in TeamDynamix. Format as
    hashtable.
.PARAMETER AppID
    Application ID where the product model will be created.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProductModel -ID 3462 -Name 'Product Name 2' -AuthenticationToken $Authentication

    Creates a new product model in TeamDynamix.
.EXAMPLE
    C:\>$ProductModel | Set-TDProductModel -AuthenticationToken $Authentication

    Using an object, create a new product model from the pipeline in
    TeamDynamix.
.EXAMPLE
    C:\>$OutOfSupportID = (Get-TDCustomAttribute -ComponentID ProductModel | Where-Object Name -eq 'OutOfSupport').ID
    C:\>$OutOfSupportYesID = ((Get-TDCustomAttribute -ComponentID ProductModel | Where-Object Name -eq 'OutOfSupport').Choices | Where-Object Name -eq 'Yes').ID
    C:\>Set-TDProductModel -ID 71292 -Attributes @{ID=$OutOfSupportID;Value=$OutOfSupportYesID}

    Set the OutOfSupport custom attribute to "Yes" for product model ID 71292.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = $TDVendors.Name
				HelpText    = 'Name of manufacturer'
                IDParameter = 'ManufacturerID'
                IDsMethod   = '$TDVendors'
			}
			@{
				Name        = 'ProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of product type'
                IDParameter = 'ProductTypeID'
                IDsMethod   = '$TDProductTypes'
			}
			@{
				Name        = 'AppName'
                Type        = 'string'
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/models/$ID"
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
}

<#
.Synopsis
    Get product types from TeamDynamix
.DESCRIPTION
    Get product types from TeamDynamix. By default, returns top-level types.
    Use ID parameter to specify an individual product type, or search for a
    product type. To return all types, use Get-TDProductType -IsTopLevel $null.
.PARAMETER ID
    Product type ID to retrieve from TeamDynamix.
.PARAMETER SearchText
    Substring search filter.
.PARAMETER IsActive
    Boolean to limit return set to active configuration item types ($true),
    inactive configuration item types ($false), or all ($null). Default is to
    show active configuration item types.
.PARAMETER IsTopLevel
    Boolean to limit return set to top-level product types ($true), child
    product types ($false), or all ($null). Default is $true.
.PARAMETER ParentProductTypeID
    Limit return set product types with the specified parent product type ID.
.PARAMETER AppID
    Application ID for the product type.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProductType -AuthenticationToken $Authentication

    Retrieves the list of all product types from TeamDynamix.
.EXAMPLE
    C:\>Get-TDProductType -ID 5564 -AuthenticationToken $Authentication

    Retrieves product type ID 5564 from TeamDynamix
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
			}
			@{
				Name        = 'ParentProductTypeName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of parent product type'
                IDParameter = 'ParentProductTypeID'
                IDsMethod   = '$TDProductTypes'
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
            AllEndpoint      = "$AppID/assets/models/types"
            SearchEndpoint   = "$AppID/assets/models/types/search"
            IDEndpoint       = "$AppID/assets/models/types/$ID"
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
}

<#
.Synopsis
    Internal function to obtain the list of product types.
.DESCRIPTION
    Internal service function to obtain the list of product types for the
    dynamic parameter on Get-TDProductType. Self-references in dynamic
    parameters produce an infinite loop.
.PARAMETER AppID
    Application ID for the product type.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProductTypeInt -AuthenticationToken $Authentication

    Retrieves the list of all active product types from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProductTypeInt
{
    [CmdletBinding()]
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

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        $Query = [TeamDynamix_Api_Assets_ProductTypeSearch]::new()
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/assets/models/types/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
        return $Return
    }
}

<#
.Synopsis
    Create a product type in TeamDynamix
.DESCRIPTION
    Create a new product type in TeamDynamix. Name and
    Order are required.
.PARAMETER Name
    Name of the product type.
.PARAMETER Description
    Description of the product type.
.PARAMETER IsActive
    Set product type active/inactive in TeamDynamix. Default is true.
.PARAMETER Order
    Order of the product type among its siblings.
.PARAMETER ParentID
    Parent ID of the product type. Set to 0 for a root-level type.
.PARAMETER AppID
    Application ID where the product model will be created.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDProductType -Name 'Product Name 1' -Order 3 -AuthenticationToken $Authentication

    Creates a new product type in TeamDynamix.
.EXAMPLE
    C:\>$ProductType | New-TDProductType -AuthenticationToken $Authentication

    Using an object, create a new product type from the pipeline in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
			}
			@{
				Name        = 'ParentName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of parent type'
                IDParameter = 'ParentID'
                IDsMethod   = '$TDProductTypes'
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
            Endpoint   = "$AppID/assets/models/types"
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
}

<#
.Synopsis
    Edits a product type in TeamDynamix
.DESCRIPTION
    Edits a product type in TeamDynamix.
.PARAMETER ID
    ID of the product type to edit.
.PARAMETER Name
    Name of the product type.
.PARAMETER Description
    Description of the product type.
.PARAMETER IsActive
    Set product type active/inactive in TeamDynamix. Default is true.
.PARAMETER Order
    Order of the product type among its siblings.
.PARAMETER ParentID
    Parent ID of the product type. Set to 0 for a root-level type.
.PARAMETER AppID
    Application ID where the product model will be created.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProductType -ID 5599 -Name 'Product Name 2' -AuthenticationToken $Authentication

    Edits a new product type in TeamDynamix.
.EXAMPLE
    C:\>$ProductType | Set-TDProductType -AuthenticationToken $Authentication

    Using an object, edits product type from the pipeline in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
			}
			@{
				Name        = 'ParentName'
                Type        = 'string'
				ValidateSet = $TDProductTypes.Name
				HelpText    = 'Name of parent type'
                IDParameter = 'ParentID'
                IDsMethod   = '$TDProductTypes'
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Create a new vendor in TeamDynamix
.DESCRIPTION
    Create a new vendor in TeamDynamix. The vendor name is required.
.PARAMETER Name
    Vendor name.
.PARAMETER Description
    Vendor description.
.PARAMETER IsActive
    Set whether the vendor is currently active.
.PARAMETER AccountNumber
    Vendor account number.
.PARAMETER IsContractProvider
    Set whether the vendor is a contract provider.
.PARAMETER IsManufacturer
    Set whether the vendor is a manufacturer.
.PARAMETER IsSupplier
    Set whether the vendor is a supplier.
.PARAMETER CompanyInformation
    Contact information for the vendor. Format as hashtable. See
    TeamDynamix.Api.Assets.ContactInformation for valid components.
.PARAMETER ContactName
    Name of the primary contact for the vendor.
.PARAMETER ContactTitle
    Title of the primary contact for the vendor.
.PARAMETER ContactDepartment
    Department of the primary contact for the vendor.
.PARAMETER ContactEmail
    Email for the primary contact for the vendor.
.PARAMETER PrimaryContactInformation
    Contact information for the primary contact for the vendor. Format as
    hashtable. See TeamDynamix.Api.Assets.ContactInformation for valid
    components.
.PARAMETER Attributes
    Custom attributes for new vendor in TeamDynamix. Format as hashtable.
.PARAMETER AppID
    Application ID where the vendor will be created.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDVendor -Name 'Vendor Name 1' -AuthenticationToken $Authentication

    Creates a new vendor in TeamDynamix.
.EXAMPLE
    C:\>$ProductType | New-TDVendor -AuthenticationToken $Authentication

    Using an object, create a new vendor from the pipeline in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/vendors"
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
}

<#
.Synopsis
    Edits a vendor in TeamDynamix
.DESCRIPTION
    Edits a vendor in TeamDynamix. The vendor name is required.
.PARAMETER ID
    Vendor ID in TeamDynamix.
.PARAMETER Name
    Vendor name.
.PARAMETER Description
    Vendor description.
.PARAMETER IsActive
    Set whether the vendor is currently active.
.PARAMETER AccountNumber
    Vendor account number.
.PARAMETER IsContractProvider
    Set whether the vendor is a contract provider.
.PARAMETER IsManufacturer
    Set whether the vendor is a manufacturer.
.PARAMETER IsSupplier
    Set whether the vendor is a supplier.
.PARAMETER CompanyInformation
    Contact information for the vendor. Format as hashtable. See
    TeamDynamix.Api.Assets.ContactInformation for valid components.
.PARAMETER ContactName
    Name of the primary contact for the vendor.
.PARAMETER ContactTitle
    Title of the primary contact for the vendor.
.PARAMETER ContactDepartment
    Department of the primary contact for the vendor.
.PARAMETER ContactEmail
    Email for the primary contact for the vendor.
.PARAMETER PrimaryContactInformation
    Contact information for the primary contact for the vendor. Format as
    hashtable. See TeamDynamix.Api.Assets.ContactInformation for valid
    components.
.PARAMETER Attributes
    Custom attributes for new vendor in TeamDynamix. Format as hashtable.
.PARAMETER AppID
    Application ID where the vendor will be created.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDVendor -ID 5400 -Name 'Updated Vendor Name' -AuthenticationToken $Authentication

    Updates the vendor name in TeamDynamix.
.EXAMPLE
    C:\>$ProductType | New-TDVendor -AuthenticationToken $Authentication

    Using an object, edits the vendor from the pipeline in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/assets/vendors/$ID"
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
}

<#
.Synopsis
    Get configuation item forms from TeamDynamix
.DESCRIPTION
    Gets all active configuation item forms from TeamDynamix.
.PARAMETER AppID
    Application ID for the configuration item form.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Get-TDAssetForm -AuthenticationToken $Authentication

   Returns a list of all active asset forms.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
				ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
				HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            AllEndpoint      = "$AppID/cmdb/forms"
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
}

<#
.Synopsis
    Create a new configuration relationship type in TeamDynamix
.DESCRIPTION
    Creates a new configuration relationship type in TeamDynamix.
.PARAMETER Description
    Description of configuration relationship type from the perspective
    of the parent configuration item.
.PARAMETER InverseDescription
    Description of configuration relationship type from the perspective
    of the child configuration item.
.PARAMETER IsOperationalDependency
    Set whether configuration relationship type constitutes an operational
    dependency.
.PARAMETER IsActive
    Set whether configuration relationship type is active or not. Default:
    true.
.PARAMETER AppID
    Application ID for the configuration relationship type.
.PARAMETER Passthru
    Return newly created asset as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDConfigurationRelationshipType -Description 'From parent' -InverseDescription 'From child' -AuthenticationToken $Authentication

   Creates a new active configuration relationship type.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/relationshiptypes"
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
}

<#
.Synopsis
    Modify a configuration relationship type in TeamDynamix
.DESCRIPTION
    Modifies a configuration relationship type in TeamDynamix.
.PARAMETER ID
    ID of configuration relationship type to modify in TeamDynamix.
.PARAMETER Description
    Description of configuration relationship type from the perspective
    of the parent configuration item.
.PARAMETER InverseDescription
    Description of configuration relationship type from the perspective
    of the child configuration item.
.PARAMETER IsOperationalDependency
    Set whether configuration relationship type constitutes an operational
    dependency.
.PARAMETER IsActive
    Set whether configuration relationship type is active or not. Default:
    true.
.PARAMETER AppID
    Application ID for the configuration relationship type.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Set-TDConfigurationRelationshipType -ID 4531 -Description 'Modified relationship type' -AuthenticationToken $Authentication

   Modifies configuration relationship type with ID 4531, to have a new name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDAssets').Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications'
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
            Endpoint   = "$AppID/cmdb/relationshiptypes/$ID"
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