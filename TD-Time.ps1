### Time

<#
.Synopsis
    Get a time entry in TeamDynamix.
.DESCRIPTION
    Get a time entry in TeamDynamix. Specify the time entry ID number or search
    using the minutes, date, rate, type, workspace, plan, task, ticket,
    application, status, person, component, time off, billability, or if it is
    limited. Results will only include time for the current user unless the
    current user has the Analysis application or is an organization's Web API
    User.
.PARAMETER MinutesFrom
    The minimum number of minutes a time entry can have to be returned. Can be
    negative. Optional. When omitted or null this is not used for filtering.
.PARAMETER MinutesTo
    The maximum number of minutes a time entry can have to be returned. Can be
    negative. Optional. When omitted or null this is not used for filtering.
.PARAMETER EntryDateFrom
    The minimum date the time entry can have to be returned. Optional. When
    omitted or null this is not used for filtering.
.PARAMETER EntryDateTo
    The maximum date the time entry can have to be returned. Optional. When
    omitted or null this is not used for filtering.
.PARAMETER CreatedDateFrom
    The minimum date the time entry can have been created by to be returned.
    Optional. When omitted or null this is not used for filtering.
.PARAMETER CreatedDateTo
    The maximum date the time entry can have been created by to be returned.
    Optional. When omitted or null this is not used for filtering.
.PARAMETER StatusDateFrom
    The minimum status date the time entry can have to be returned. Status
    date is updated when a time entry is submitted, approved, rejected, etc.
    Optional. When omitted or null this is not used for filtering.
.PARAMETER StatusDateTo
    The maximum status date the time entry can have to be returned. Status date
    is updated when a time entry is submitted, approved, rejected, etc.
    Optional. When omitted or null this is not used for filtering.
.PARAMETER BillRateFrom
    The minimum billable rate a time entry can have to be returned. Optional.
    When omitted or null this is not used for filtering.
.PARAMETER BillRateTo
    The maximum billable rate a time entry can have to be returned. Optional.
    When omitted or null this is not used for filtering.
.PARAMETER CostRateFrom
    The minimum cost rate a time entry can have to be returned. Optional. When
    omitted or null this is not used for filtering.
.PARAMETER CostRateTo
    The maximum cost rate a time entry can have to be returned. Optional. When
    omitted or null this is not used for filtering.
.PARAMETER TimeTypeIDs
    The list of time type identifiers. If this is empty or null, no filtering
    will occur, otherwise, only items that use one of the specfified time
    types will be returned.
.PARAMETER ProjectOrWorkspaceIDs
    The list of project, request, or workspace identifiers. If this is empty or
    null, no filtering will occur, otherwise, only items that use one of the
    specfified time types will be returned.
.PARAMETER PlanIDs
    The list of plan identifiers. If this is empty or null, no filtering will
    occur, otherwise, only items that use one of the specfified time types will
    be returned.
.PARAMETER TaskIDs
    The list of task identifiers. If this is empty or null, no filtering will
    occur, otherwise, only items that use one of the specfified time types will
    be returned.
.PARAMETER IssueIDs
    The list of issue identifiers. If this is empty or null, no filtering will
    occur, otherwise, only items that use one of the specfified time types will
    be returned.
.PARAMETER TicketIDs
    The list of ticket identifiers. If this is empty or null, no filtering will
    occur, otherwise, only items that use one of the specfified time types will
    be returned.
.PARAMETER TicketTaskIDs
    The list of ticket task identifiers. If this is empty or null, no filtering
    will occur, otherwise, only items that use one of the specfified time types
    will be returned.
.PARAMETER ApplicationIDs
    The list of application identifiers, typically used with ticketing
    applications. If this is empty or null, no filtering will occur, otherwise,
    only items that use one of the specfified time types will be returned.
.PARAMETER StatusIDs
    The list of status identifiers. If this is empty or null, no filtering will
    occur, otherwise, only items that use one of the specfified time types will
    be returned.
.PARAMETER PersonUIDs
    The list of person unique identifiers. If this is empty or null, no
    filtering will occur, otherwise, only items that use one of the specfified
    time types will be returned.
.PARAMETER Components
    The list of components, allowing results to be focused down to tickets,
    issues, etc. If this is empty or null, no filtering will occur, otherwise,
    only items that use one of the specfified time types will be returned.
.PARAMETER IsTimeOff
    A value indicating whether only time off entries (true), only non-time off
    entries (false), or all entries should be returned. Defaults to all
    entries.
.PARAMETER IsBillable
    A value indicating whether only billable entries (true), only non-billable
    entries (false), or all entries should be returned. Defaults to all
    entries.
.PARAMETER IsLimited
    A value indicating whether only limited entries (true), only non-limited
    entries (false), or all entries should be returned. Defaults to all
    entries.
.PARAMETER MaxResults
	The maximum number of results to be returned. Defaults to 1000.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTime

    Returns all time entries.
.EXAMPLE
    C:\>Get-TDTime -ID 77553

    Returns time entry with ID 77553.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTime
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # The time entry ID to return.
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        Position=0,
        ParameterSetName='TimeEntryID')]
        [int]
        $ID,

        # The minimum number of minutes a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Int32]]
		$MinutesFrom,

		# The maximum number of minutes a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Int32]]
		$MinutesTo,

		# The minimum date the time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$EntryDateFrom,

		# The maximum date the time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$EntryDateTo,

		# The minimum date the time entry can have been created by to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$CreatedDateFrom,

		# The maximum date the time entry can have been created by to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$CreatedDateTo,

		# The minimum status date the time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$StatusDateFrom,

		# The maximum status date the time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[DateTime]]
		$StatusDateTo,

		# The minimum billable rate a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Double]]
		$BillRateFrom,

		# The maximum billable rate a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Double]]
		$BillRateTo,

		# The minimum cost rate a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Double]]
		$CostRateFrom,

		# The maximum cost rate a time entry can have to be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Double]]
		$CostRateTo,

		# The list of time type identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$TimeTypeIDs,

		# The list of project, request, or workspace identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$ProjectOrWorkspaceIDs,

		# The list of plan identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$PlanIDs,

		# The list of task identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$TaskIDs,

		# The list of issue identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$IssueIDs,

		# The list of ticket identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$TicketIDs,

		# The list of ticket task identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$TicketTaskIDs,

		# The list of application identifiers, typically used with ticketing applications.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$ApplicationIDs,

		# The list of status identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Int32[]]
		$StatusIDs,

		# The list of person unique identifiers.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[Guid[]]
		$PersonUIDs = [guid]::Empty,

		# The list of components, allowing results to be focused down to tickets, issues, etc.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[TeamDynamix_Api_Time_TimeEntryComponent[]]
		$Components,

		# A value indicating whether only time off entries (true), only non-time off entries (false), or all entries should be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Boolean]]
		$IsTimeOff,

		# A value indicating whether only billable entries (true), only non-billable entries (false), or all entries should be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Boolean]]
		$IsBillable,

		# A value indicating whether only limited entries (true), only non-limited entries (false), or all entries should be returned.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Boolean]]
		$IsLimited,

		# The maximum number of results to be returned. Defaults to 1000.
		[Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
		[System.Nullable[Int32]]
        $MaxResults,

        # Include full detail for time entries
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
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
	Begin
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
        $LocalIgnoreParameters = @('ID','Detail')
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'TimeEntryID'
            {
                Write-ActivityHistory "Retrieving time entry $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $TimeEntrySearch = [TeamDynamix_Api_Time_TimeSearch]::new()
                Update-Object -InputObject $TimeEntrySearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                # Reformat object for upload to TD, include proper date format
                $TimeEntrySearchTD = [TD_TeamDynamix_Api_Time_TimeSearch]::new($TimeEntrySearch)
                Write-ActivityHistory 'Retrieving matching TeamDynamix time entries'
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TimeEntrySearchTD -Depth 10)
            }
        }
        if ($Detail)
        {
            if ($Return)
            {
                $Return = $Return.ID | Get-TDAsset -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_Time_TimeEntry]::new($_)})
        }
    }
}

<#
.Synopsis
    Get time types from TeamDynamix.
.DESCRIPTION
    Get time types from TeamDynamix. Use ID parameter to specify an
    specific time type, or search using ticket, ticket task, request,
    project, issue, plan task, or workspace.
.PARAMETER ID
    Time type ID to retrieve from TeamDynamix.
.PARAMETER UID
    UID of user to filter time types.
.PARAMETER StartDate
    Start date limiting search for user time types.
.PARAMETER EndDate
    End date limiting search for user time types.
.PARAMETER TicketID
    Search for time types that are available or applied to ticket ID.
.PARAMETER TaskID
    Search for time types that are available or applied to task ID. Requires
    ticket and application ID or project and plan ID.
.PARAMETER AppID
    Search for time types in application. Requires ticket ID.
.PARAMETER ProjectID
    Search for time types that are available or applied to project ID.
.PARAMETER TimeOff
    Search for time types that are available to a project ID that can be
    applied as time off.
.PARAMETER IssueID
    Search for time types that are available or applied to issue ID. Requires
    project ID.
.PARAMETER PlanID
    Search for time types that are available or applied to plan ID. Requires
    Project ID and task ID.
.PARAMETER RequestID
    Search for time types that are available or applied to request ID.
.PARAMETER WorkspaceID
    Search for time types that are available or applied to workspace ID.
.PARAMETER All
    Return all available active time types.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTimeType -AuthenticationToken $Authentication

    Retrieves the list of all available active time types from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTimeType -ID 5564 -AuthenticationToken $Authentication

    Retrieves time type ID 5564 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTimeType
{
    [CmdletBinding(DefaultParameterSetName='All')]
    Param
    (
        # ID of time type
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='UID')]
        [int]
        $ID,

        # Filter time type by UID and date
        [Parameter(Mandatory=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Filter time type by UID and date
        [Parameter(Mandatory=$true,
                   ParameterSetName='UID')]
        [System.Nullable[datetime]]
        $StartDate,

        # Filter time type by UID and date
        [Parameter(Mandatory=$true,
                   ParameterSetName='UID')]
        [System.Nullable[datetime]]
        $EndDate,

        # Filter time type on ticket or task ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='TicketID')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='TicketTaskID')]
        [int]
        $TicketID,

        # Filter time type on ticket task ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='TicketTaskID')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='PlanTaskID')]
        [int]
        $TaskID,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ParameterSetName='TicketID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='TicketTaskID')]
        [int]
        $AppID = $TicketingAppID,

        # Filter time type on project or issue ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='ProjectID')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='IssueID')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='TimeOff')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='PlanTaskID')]
        [int]
        $ProjectID,

        # Find time types available to a specific project that can be applied as time off
        [Parameter(Mandatory=$true,
                   ParameterSetName='TimeOff')]
        [switch]
        $TimeOff,

        # Filter time type on issue ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='IssueID')]
        [int]
        $IssueID,

        # Filter time type on plan ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='PlanTaskID')]
        [int]
        $PlanID,

        # Filter time type on request ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='RequestID')]
        [int]
        $RequestID,

        # Filter time type on workspace ID
        [Parameter(Mandatory=$true,
                   ParameterSetName='WorkspaceID')]
        [int]
        $WorkspaceID,

        # Find all active time types
        [Parameter(Mandatory=$false,
                   ParameterSetName='All')]
        [switch]
        $All,

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
        switch ($PSCmdlet.ParameterSetName)
        {
            'All'
            {
                Write-ActivityHistory 'Retrieving all available active time types'
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'ID'
            {
                Write-ActivityHistory "Retrieving time type $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'UID'
            {
                Write-ActivityHistory "Retrieving time type $ID, for user $UID, starting at date $StartDate, and ending at $EndDate"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/$ID/limits/$UID?startDate=$StartDate&endDate=$EndDate" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'TicketID'
            {
                Write-ActivityHistory "Retrieving time types for ticket $TicketID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/app/$AppID/ticket/$TicketID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'TicketTaskID'
            {
                Write-ActivityHistory "Retrieving time types for task $TaskID on ticket $TicketID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/app/$AppID/ticket/$TicketID/task/$TaskID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'ProjectID'
            {
                Write-ActivityHistory "Retrieving time types for project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/project/$ProjectID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'IssueID'
            {
                Write-ActivityHistory "Retrieving time types for issue $IssueID on project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/project/$ProjectID/issue/$IssueID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'PlanTaskID'
            {
                Write-ActivityHistory "Retrieving time types for task $TaskID on plan $PlanID on project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/project/$ProjectID/plan/$PlanID/task/$TaskID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'RequestID'
            {
                Write-ActivityHistory "Retrieving time types for request $RequestID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/request/$RequestID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'WorkspaceID'
            {
                Write-ActivityHistory "Retrieving time types for workspace $WorkspaceID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/workspace/$WorkspaceID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'TimeOff'
            {
                Write-ActivityHistory "Retrieving time off types for project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/component/timeoff/project/$ProjectID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_Time_TimeType]::new($_)})
        }
    }
}

<#
.Synopsis
    Set a time entry in TeamDynamix.
.DESCRIPTION
    Modify an existing time entry in TeamDynamix. If the time entry is on a
    ticket, specify the application ID and ticket ID. If the time entry is on
    an issue, task, or project, specify the project. If the time entry is on an
    issue or task, specify the plan ID.
.PARAMETER TimeID
    The ID of the time entry. This should be zero or negative when performing an add.
.PARAMETER ItemID
    The ID of the item the time entry is entered against.
.PARAMETER Uid
    The unique identifier of the user who created the time entry.
.PARAMETER TimeTypeID
    The ID of the associated time type.
.PARAMETER AppID
    The ID of the associated application. This should be zero except when working with ticketing applications.
.PARAMETER Component
    The type of module the ItemID corresponds with.
.PARAMETER TicketID
    The ticket identifier. This is useful if the time entry is on a ticket or ticket task. Note that Component, AppID, and ItemID should still be set.
.PARAMETER Minutes
    The minutes logged for the time entry.
.PARAMETER Description
    The description of the time entry.
.PARAMETER ProjectID
    The project identifier. This is used when the time is on an issue, project, or task.
.PARAMETER PlanID
    The plan identifier. This is used when the time is on an issue, or task.
.PARAMETER TimeDate
    The date the time entry should be recorded for.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDTime -TimeID 7601 -ItemID 4452 -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -TimeTypeID 943 -AppID 0

    ??
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDTime
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   DefaultParameterSetName='Default')]
    Param
    (
        # The ID of the time entry. This should be zero or negative when performing an add.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [Int32]
        [alias('ID')]
        $TimeID,

        # The ID of the item the time entry is entered against.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [Int32]
        $ItemID,

        # The unique identifier of the user who created the time entry.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [String]
        $UID,

        # The ID of the associated time type.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [Int32]
        $TimeTypeID,

        # The ID of the associated application. This should be zero except when working with ticketing applications.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Ticket')]
        [Int32]
        $AppID = 0,

        # The type of module the ItemID corresponds with.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [TeamDynamix_Api_Time_TimeEntryComponent]
        $Component,

        # The ticket identifier. This is useful if the time entry is on a ticket or ticket task. Note that Component, AppID, and ItemID should still be set.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Int32]
        $TicketID,

        # The minutes logged for the time entry.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [Double]
        $Minutes,

        # The description of the time entry.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Default')]
        [String]
        $Description,

        # The project identifier. This is used when the time is on an issue, project, or task.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Default')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Int32]
        $ProjectID,

        # The plan identifier. This is used when the time is on an issue, or task.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Int32]
        $PlanID,

        # The date the time entry should be recorded for.
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Ticket')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Default')]
        [DateTime]
        $TimeDate,

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
        Write-ActivityHistory "Getting full time entry for $TimeID on TeamDynamix."
        try
        {
            $TDTime = Get-TDTime -ID $TimeID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find time entry $TimeID"
        }
        Write-ActivityHistory 'Setting properties on time entry.'
        Update-Object -InputObject $TDTime -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        $TDTimeTD = [TD_TeamDynamix_Api_Time_TimeEntry]::new($TDTime)
        if ($pscmdlet.ShouldProcess("$TimeID - $($TDTime.Description)", 'Update time entry properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            $Return = Invoke-RESTCall -Uri "$BaseURI/time/$TimeID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TDTimeTD -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Time_TimeEntry]::new($Return)
            }
            Write-ActivityHistory ($Return | Out-String)
            if ($Passthru)
            {
                Write-Output $Return
            }
        }
    }
}

<#
.Synopsis
    Removes a time entry in TeamDynamix
.DESCRIPTION
    Removes a time entry or time entries in a list, specified by ID, in
    TeamDynamix.
.PARAMETER ID
    ID of the time entry to be removed.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDTime -ID 1057 -AuthenticationToken $Authentication

    Removes time entry ID 1057 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Remove-TDTime
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        #ID time entry to be removed
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int[]]
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
        if ($pscmdlet.ShouldProcess($ChoiceID, "Remove time entry $ID"))
        {
            Write-ActivityHistory "Removing time entry $ID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/time/delete" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $ID -Depth 10)
            return [TeamDynamix_Api_Time_BulkOperationResults]::new($Return)
        }
    }
}

<#
.Synopsis
    Get locked days in TeamDynamix.
.DESCRIPTION
    Get locked days within a time period in TeamDynamix. Time entry is not
    allowed during locked days.
.PARAMETER StartDate
    Start date to search for locked days.
.PARAMETER EndDate
    End date to search for locked days.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTimeLockedDays -StartDate 11-25-2018 -EndDate 12-25-2019 -AuthenticationToken $Authentication

    Returns locked days between November 25, 2018 and December 25, 2019 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTimeLockedDays
{
    [CmdletBinding()]
    Param
    (
        # Starting search date
        [Parameter(Mandatory=$false,
                   Position=0)]
        [datetime]
        $StartDate,

        # Ending search date
        [Parameter(Mandatory=$false,
                   Position=1)]
        [datetime]
        $EndDate,

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
        $DateQuery = ''
        if ($StartDate)
        {
            $DateQuery += "startDate=$($StartDate | Get-Date -Format o)"
        }
        if ($EndDate)
        {
            if ($DateQuery)
            {
                $DateQuery += '&'
            }
            $DateQuery += "endDate=$($EndDate | Get-Date -Format o)"
        }
        if ($DateQuery -ne '')
        {
            $DateQuery = '?' + $DateQuery
        }
        Write-ActivityHistory "Getting locked days."
        return Invoke-RESTCall -Uri "$BaseURI/time/locked$DateQuery" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
    }
}

<#
.Synopsis
    Get week's time report (weekly timesheet) in TeamDynamix.
.DESCRIPTION
    Get week's time report (weekly timesheet) in TeamDynamix. By default, get
    report for current user. Specify UID to get report for a specific user.
.PARAMETER ReportDate
    Start date to search for locked days.
.PARAMETER UID
    End date to search for locked days.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTimeReport -ReportDate 11-25-2018 -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Returns weekly timesheet for specified user for November 25, 2018.
.EXAMPLE
    C:\>Get-TDTimeReport -ReportDate 11-25-2018 -AuthenticationToken $Authentication

    Returns weekly timesheet for the current user for November 25, 2018.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTimeReport
{
    [CmdletBinding()]
    Param
    (
        # Date for report
        [Parameter(Mandatory=$true,
                   Position=0)]
        [datetime]
        $ReportDate,

        # UID for report
        [Parameter(Mandatory=$false,
                   Position=1)]
        [guid]
        $UID,

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
        if ($UID)
        {
            Write-ActivityHistory "Retrieving timesheet for user $UID, for date $ReportDate."
            $Return = Invoke-RESTCall -Uri "$BaseURI/time/report/$($ReportDate | Get-Date -Format o)/$UID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        else
        {
            Write-ActivityHistory "Retrieving timesheet for the current user for date $ReportDate."
            $Return = Invoke-RESTCall -Uri "$BaseURI/time/report/$($ReportDate | Get-Date -Format o)" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        if ($Return)
        {
            return [TeamDynamix_Api_Time_TimeReport]::new($Return)
        }
    }
}

<#
.Synopsis
    Get time limits for a time type in TeamDynamix.
.DESCRIPTION
    Get time limits for a time type for a specific user within a date range in
    TeamDynamix.
.PARAMETER ID
    Get limits for this time type ID.
.PARAMETER UID
    Get limits for user with this ID.
.PARAMETER StartDate
    Start date to search for limits.
.PARAMETER EndDate
    End date to search for limits.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTimeTypeLimits -ID 7503 -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -StartDate 11-25-2018 -EndDate 12-25-2019 -AuthenticationToken $Authentication

    Returns time type limits for specified user between November 25, 2018 and
    December 25, 2019 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTimeTypeLimits
{
    [CmdletBinding()]
    Param
    (
        # ID of time type
        [Parameter(Mandatory=$true,
                   Position=0)]
        [int]
        $ID,

        # Filter time type limits by UID
        [Parameter(Mandatory=$true,
                   Position=1)]
        [guid]
        $UID,

        # Starting search date
        [Parameter(Mandatory=$false,
                   Position=2)]
        [datetime]
        $StartDate,

        # Ending search date
        [Parameter(Mandatory=$false,
                   Position=3)]
        [datetime]
        $EndDate,

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
        $DateQuery = ''
        if ($StartDate)
        {
            $DateQuery += "startDate=$($StartDate | Get-Date -Format o)"
        }
        if ($EndDate)
        {
            if ($DateQuery)
            {
                $DateQuery += '&'
            }
            $DateQuery += "endDate=$($EndDate | Get-Date -Format o)"
        }
        if ($DateQuery -ne '')
        {
            $DateQuery = '?' + $DateQuery
        }
        Write-ActivityHistory "Getting time type limits."
        $Return = Invoke-RESTCall -Uri "$BaseURI/time/types/$ID/limits/$UID$DateQuery" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_Time_TimeTypeLimit]::new($_)})
        }
    }
}