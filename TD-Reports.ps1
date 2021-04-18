### Reports

function Get-TDReport
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # ID of report to return
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Return report data
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false)]
        [switch]
        $WithData,

        # Search report sorting expression
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false)]
        [string]
        $DataSortExpression = '',

        # Search text, substring of report name
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [ValidateLength(1,50)]
        [string]
        $SearchText,

        # Search report owner UID
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [guid]
        $OwnerUID,

        # Search report application ID number
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int]
        $ForAppID,

        # Search report application name substring
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [ValidateLength(1,50)]
        [string]
        $ForApplicationName,

        # Search report source ID number
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int]
        $ReportSourceID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
        # Manage parameters
        #  Identify local parameters to be ignored
        $LocalIgnoreParameters = @('ID','WithData','DataSortExpression')
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'ID'
            {
                if ($ID -ne '')
                {
                    $Result = Invoke-RESTCall -Uri "$BaseURI/reports/$($ID)?withData=$($WithData.IsPresent)&dataSortExpression=$DataSortExpression" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    $Result = Invoke-RESTCall -Uri "$BaseURI/reports" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
            }
            'Search'
            {
                $Query = [TeamDynamix_Api_Reporting_ReportSearch]::new()
                Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                $Result = Invoke-RESTCall -Uri "$BaseURI/reports/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
            }
        }
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Reporting_ReportInfo]::new($_)})
        }
        return $Result
    }
}

function Get-TDSearch
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    [alias('Get-TDAssetSearch','Get-TDTicketSearch')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $AppID,

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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $Attributes.ParameterSetName = 'Name'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll() | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Get-TDSearch
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDSearch'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetSearch'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketSearch'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }

    process
    {
        # Get ID for application if name is supplied
        if ($PSCmdlet.ParameterSetName -eq 'Name')
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
            }
            'Asset/CI'
            {
                $AppType = 'assets'
            }
        }
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/searches" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_SavedSearches_SavedSearch]::new($_)})
        }
        return $Return
    }
}

function Search-TD
{
    [CmdletBinding(DefaultParameterSetName='AppName')]
    [alias('Search-TDAsset','Search-TDTicket')]
    Param
    (
        # Search ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='AppName')]

        [int]
        $ID,

        # Text to search for
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [string]
        $SearchText,

        # Set product type order
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [int]
        $PageIndex,

        # Set product type parent ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [int]
        $PageSize = 5,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$true,
                   ParameterSetName='AppID')]
        [int]
        $AppID,

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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $Attributes.ParameterSetName = 'AppName'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll() | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Search-TD
        switch ($MyInvocation.InvocationName)
        {
            'Search-TD'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Search-TDAsset'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Search-TDTicket'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Filter on tickets for which the current user is responsible.'
        $Attributes.DontShow = ($MyInvocation.InvocationName -eq 'Search-TDAsset')
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $OnlyMy = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("OnlyMy", [switch], $AttributeCollection)
        $ParameterDictionary.Add("OnlyMy", $OnlyMy)

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Filter for only open tickets (status of "New", "In Process", or "On Hold").'
        $Attributes.DontShow = ($MyInvocation.InvocationName -eq 'Search-TDAsset')
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $OnlyOpen = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("OnlyOpen", [switch], $AttributeCollection)
        $ParameterDictionary.Add("OnlyOpen", $OnlyOpen)

        return $ParameterDictionary
    }

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
        $RequestPage = [TeamDynamix_Api_RequestPage]::new($PageIndex,$PageSize)
        # Get ID for application if name is supplied
        if ($PSCmdlet.ParameterSetName -eq 'AppName')
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
                $SearchOptions = [TeamDynamix_Api_Tickets_TicketSavedSearchOptions]::new($SearchText,$OnlyMy.Value,$OnlyOpen.Value,$RequestPage)
            }
            'Asset/CI'
            {
                $AppType = 'assets'
                $SearchOptions = [TeamDynamix_Api_Assets_AssetSavedSearchOptions]::new($SearchText,$RequestPage)
            }
        }
        Write-ActivityHistory "Getting page $PageIndex for saved search $ID from TeamDynamix."
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/searches/$ID/results" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $SearchOptions -Depth 10)
        if ($Return)
        {
            #$Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        Write-ActivityHistory ($SearchOptions | Out-String)
    return $Return
    }
}

function Get-TDFeed
{
    [CmdletBinding(DefaultParameterSetName='Page')]
    [alias('Get-TDAssetFeed','Get-TDTicketFeed','Get-TDProjectFeed')]
    Param
    (
        # Get feed for this ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID',
                   Position=0)]
        [int]
        $ID,

        # Last-updated date to filter on
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [datetime]
        $DateFrom,

        # Earliest-updated date to filter on
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [datetime]
        $DateTo,

        # Number of replies per feed entry
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [int]
        $ReplyCount = 0,

        # Number of feed entries to return
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [int]
        $ReturnCount = 25,

        # Set UIDs of creators to ignore
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [guid[]]
        $IgnoreUIDs,

        # Set ID of application
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [int]
        $AppID = 0,

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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll() | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDFeed'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetFeed'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketFeed'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDProjectFeed'
            {
                $AppName.Value = 'Projects / Workspaces'
            }
        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
    }

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
        # Get ID from name if AppID is not supplied (AppID defaults to 0)
        if ($AppID -eq 0)
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        $AppClass = $TDApplications.Get($AppID,$Environment).AppClass
        switch ($AppClass)
        {
            'TDTickets'  {$AppIDClassURI = "$AppID/tickets"}
            'TDAssets'   {$AppIDClassURI = "$AppID/assets" }
            'TDProjects' {$AppIDClassURI = 'projects' }
        }
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving feed for TeamDynamix $AppClass ID $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDClassURI/$ID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    if ($IgnoreUIDs)
                    {
                        $Return = $Return | Where-Object CreatedUID -notin $IgnoreUIDs
                    }
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
                }
            }
            'Page'
            {
                # Paged feed search is date-based.
                Write-ActivityHistory "Retrieving paged feed for TeamDynamix $AppClass ID $ID"
                # Build page query string
                $PageQuery = ''
                if ($DateFrom)
                {
                    $PageQuery = "DateFrom=$($DateFrom | Get-Date -Format o)"
                }
                if ($DateTo)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "DateTo=$($DateTo | Get-Date -Format o)"
                }
                if ($ReplyCount)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "ReplyCount=$ReplyCount"
                }
                if ($ReturnCount)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "ReturnCount=$ReturnCount"
                }
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDClassURI/feed/?$PageQuery" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdatesPage]::new($_)})
                }
            }
        }
        return $Return
    }
}

function Get-TDForm
{
    [CmdletBinding()]
    [alias('Get-TDAssetForm','Get-TDTicketForm')]
    Param
    (
        # Select based on whether form is active
        [Parameter(Mandatory=$false)]
        [system.nullable[boolean]]
        $IsActive,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
        [int]
        $AppID,

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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose forms will be retrieved'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll() | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDForm'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetForm'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketForm'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }

    process
    {
        # Get ID for application if name is supplied
        if ($AppName.Value)
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
            }
            'Asset/CI'
            {
                $AppType = 'assets'
            }
        }
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/forms" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Forms_Form]::new($_)})
        }
        return $Return
    }
}