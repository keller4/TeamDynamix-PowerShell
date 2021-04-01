### Reports

<#
.Synopsis
    Get a report from TeamDynamix
.DESCRIPTION
    Gets a specific report, or searches for matching reports, from TeamDynamix.
    Search by report ID or use the -OwnerUID, -SearchText, -ForAppID,
    -ForApplicationName, or -ReportSourceID options to locate reports.
    Use -WithData to retrieve report data (may only be used with ID search)
.PARAMETER ID
    ID of the report to be retrieved, or * for all ticket reports. Returns
    report detail. Use -WithData to return report data as well (cannot be used
    with *). Available on the pipeline.
.PARAMETER OwnerUID
    Retrieve reports owned by UID specified.
.PARAMETER SearchText
    Retrieve reports whose name contains the search text.
.PARAMETER ForAppID
    Retrieve reports for the specified application ID.
.PARAMETER ForApplicationName
    Retrieve reports whose application name contains the specified text.
.PARAMETER ReportSourceID
    Retrieve reports for the specified source ID.
.PARAMETER WithData
    Switch. For reports retrieved by ID, include the report data.
.PARAMETER DataSortExpression
    Optional sorting expression to use for the report's data. Default is to use
    the sort specified in the report.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    String, or array of strings, containing IDs.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Users.User.
.EXAMPLE
   C:\>Get-TDReport

   Returns a list of all ticket reports.
.EXAMPLE
   C:\>Get-TDReport -ForAppID (Get-TDApplication | Where-Object Name -like '*asset*').AppID

   Returns a list of all asset reports.
.EXAMPLE
   C:\>Get-TDReport -ID 7555 -WithData

   Returns full report data for report ID 7555.
.EXAMPLE
   C:\>'7555', '7557' | Get-TDReport -WithData

   Returns full report data for report IDs specified in the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Get a list of saved searches from TeamDynamix
.DESCRIPTION
    Gets all saved searches, visible to the user, from TeamDynamix.
.PARAMETER AppID
    Application ID for the search.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDSearch

    Returns a list of all saved searches for the first Ticket application.
.EXAMPLE
    C:\>Get-TDTicketSearch

    Returns a list of all saved searches for the first Ticket application.
.EXAMPLE
    C:\>Get-TDAssetSearch

    Returns a list of all saved searches for the first Asset application.
.EXAMPLE
   C:\>Get-TDSearch -AppID 7511 -AuthenticationToken $Authentication

   Returns a list of all saved searches visible to the user for application ID
   7511.
.EXAMPLE
   C:\>Get-TDSearch -AppName 'Tickets' -AuthenticationToken $Authentication

   Returns a list of all saved searches for the application named "Tickets".
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($TDApplications.Name | Where-Object Type -ne 'Standard')
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Get-TDSearch
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDSearch'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
            }
            'Get-TDAssetSearch'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Asset/CI')[0].Name
            }
            'Get-TDTicketSearch'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
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
            $AppID = ($TDApplications | Where-Object Name -eq $AppName.Value).AppID
        }
        # Get app type to use appropriate URI
        switch (($TDApplications | Where-Object AppID -eq $AppID).Type)
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

<#
.Synopsis
    Get a page from a saved search in TeamDynamix
.DESCRIPTION
    Gets a page from a saved search, with pagination options, in TeamDynamix.
.PARAMETER ID
    ID of the saved search.
.PARAMETER SearchText
    Search text to filter on. Overrides any search text in the saved search.
.PARAMETER OnlyMy
    Swtich to filter on tickets for which the current user is responsible.
.PARAMETER OnlyOpen
    Switch to filter for open tickets, that is, where the ticket status is one
    of "New", "In Process", or "On Hold".
.PARAMETER PageIndex
    Index of the page requested. Zero-based count.
.PARAMETER PageSize
    The number of assets requested per page.
.PARAMETER AppID
    Application ID for the search.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Search-TD -ID 3759 -PageIndex 0 -PageSize 20 -AuthenticationToken $Authentication

    Executes search ID 3759, returning the first page of results, containing 20
    assets from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($TDApplications.Name | Where-Object Type -ne 'Standard')
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Search-TD
        switch ($MyInvocation.InvocationName)
        {
            'Search-TD'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
            }
            'Search-TDAsset'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Asset/CI')[0].Name
            }
            'Search-TDTicket'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
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
            $AppID = ($TDApplications | Where-Object Name -eq $AppName.Value).AppID
        }
        # Get app type to use appropriate URI
        switch (($TDApplications | Where-Object AppID -eq $AppID).Type)
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

<#
.Synopsis
    Get the activity feed for an asset or ticket from TeamDynamix
.DESCRIPTION
    Get the activity feed for an asset or ticket from TeamDynamix.
.PARAMETER ID
    ID of whose feed will be retrieved.
.PARAMETER IgnoreUIDs
    UIDs of activity feed creators to ignore.
.PARAMETER AppID
    Application ID.
.PARAMETER DateFrom
    Last-updated date to filter on.
.PARAMETER DateTo
    Earliest-updated date to filter on.
.PARAMETER ReplyCount
    Number of replies per feed entry. Required for paged and date-limited
    query.
.PARAMETER ReturnCount
    Number of feed entries to return. Default is 25.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDAssetFeed -ID 1055 -AuthenticationToken $Authentication

    Retrieves the activity feed for asset ID 1055 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicketFeed -ID 3774 -AuthenticationToken $Authentication

    Retrieves the activity feed for ticket ID 3774 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDAssetfeed -DateFrom 11/30/2018 -DateTo 11/1/2018 -AuthenticationToken $Authentication

    Retrieves the activity feed for assets between November 1, 2018 and
    November 30, 2018 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDAssetfeed -ID 3374 -IgnoreUIDs @('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY') -AuthenticationToken $Authentication

    Retrieves the activity feed for asset ID 3374 from TeamDynamix, ignoring
    updates from users with UIDs 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX' and
    'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY'.

.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($TDApplications.Name | Where-Object Type -ne 'Standard')
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDFeed'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
            }
            'Get-TDAssetFeed'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Asset/CI')[0].Name
            }
            'Get-TDTicketFeed'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
            }
            'Get-TDProjectFeed'
            {
                $AppName.Value = 'Projects'
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
            $AppID = ($TDApplications | Where-Object Name -eq $AppName.Value).AppID
        }
        # Get app type to use appropriate URI
        if ($AppID -eq 0) # Occurs when the AppID isn't needed
        {
            $AppType = ($TDApplications | Where-Object Name -eq $AppName.Value).Type
            switch ($AppType)
            {
                'Ticketing' {$AppIDTypeURI = 'tickets'}
                'Asset/CI'  {$AppIDTypeURI = 'assets' }
            }
        }
        else
        {
            $AppType = ($TDApplications | Where-Object AppID -eq $AppID).Type
            switch ($AppType)
            {
                'Ticketing' {$AppIDTypeURI = "$AppID/tickets"}
                'Asset/CI'  {$AppIDTypeURI = "$AppID/assets" }
            }
        }
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving feed for TeamDynamix $AppType ID $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDTypeURI/$ID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
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
                Write-ActivityHistory "Retrieving paged feed for TeamDynamix $AppType ID $ID"
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
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDTypeURI/feed/?$PageQuery" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdatesPage]::new($_)})
                }
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Get asset or ticket forms from TeamDynamix
.DESCRIPTION
    Gets all active asset or ticket forms from TeamDynamix.
.PARAMETER IsActive
    Select forms based on whether they are active. Default ($null) returns
    all forms.
.PARAMETER AppID
    Application ID for the form.
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
.EXAMPLE
   C:\>Get-TDTicketForm -AuthenticationToken $Authentication

   Returns a list of all active ticket forms.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDForm
{
    [CmdletBinding()]
    [alias('Get-TDAssetForm','Get-TDTicketForm')]
    Param
    (
        # Select based on whether form is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($TDApplications.Name | Where-Object Type -ne 'Standard')
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDForm'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
            }
            'Get-TDAssetForm'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Asset/CI')[0].Name
            }
            'Get-TDTicketForm'
            {
                $AppName.Value = ($TDApplications | Where-Object Type -eq 'Ticketing')[0].Name
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
            $AppID = ($TDApplications | Where-Object Name -eq $AppName.Value).AppID
        }
        # Get app type to use appropriate URI
        switch (($TDApplications | Where-Object AppID -eq $AppID).Type)
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