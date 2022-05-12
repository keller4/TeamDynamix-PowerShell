### Time

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
        if ($Return)
        {
            if ($Detail)
            {
                $Return = $Return.ID | Get-TDAsset -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Time_TimeEntry]::new($_)})
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUthYR0XW7LNRCX6MREZOidr8c
# QRKgggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
# 9w0BAQsFADAaMRgwFgYDVQQDEw9BU0MgUEtJIE9mZmxpbmUwHhcNMTcwNTA4MTcx
# NDA5WhcNMjcwNTA4MTcyNDA5WjBYMRMwEQYKCZImiZPyLGQBGRYDZWR1MRowGAYK
# CZImiZPyLGQBGRYKb2hpby1zdGF0ZTETMBEGCgmSJomT8ixkARkWA2FzYzEQMA4G
# A1UEAxMHQVNDLVBLSTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOF4
# 1t2KTcMPjn/gtqYCaWsRjqTvsL0AjDvZDeTUqc4rABZw5rbZFLMRKeuFMmCKeCEb
# wtNDSv2GVCvZnRJuUPVowSyT1+0rHNYnzyTrJDiZTm/WzurPOSlaqGuJovb2mJLk
# 4351McVNwN7T9io8Tpi4pov1kFfJqHH7MY6H4Sa/6xuy2Al0/8+c3QubJc1Fl4Ew
# XJGMLIvmYIkik1pRr3eT52JP2uu7yyyU+JMRwhvbMEnhuhVGwi5aKTg1G3z6AoOn
# bdWl+AMfxwaNtl0Hhz4NWQIgo/ieiXUqC1DZqKj4vauBlSLxE66CSJnLDD3IMmss
# NJlFi2Q0NAw4HulTpLsCAwEAAaOCAZwwggGYMBAGCSsGAQQBgjcVAQQDAgEBMCMG
# CSsGAQQBgjcVAgQWBBTeaCQAfNtGUFhb0QBZ02IBaUIJzTAdBgNVHQ4EFgQULgSe
# hPTwfxn4sIe7oPMkGIyw97YwgZIGA1UdIASBijCBhzCBhAYGKwYBBAFkMHowOgYI
# KwYBBQUHAgIwLh4sAEwAZQBnAGEAbAAgAFAAbwBsAGkAYwB5ACAAUwB0AGEAdABl
# AG0AZQBuAHQwPAYIKwYBBQUHAgEWMGh0dHA6Ly9jZXJ0ZW5yb2xsLmFzYy5vaGlv
# LXN0YXRlLmVkdS9wa2kvY3BzLnR4dDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMA
# QTALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBSmmXUH
# 2YrKB5bSFEUMk0oNSezdUTBRBgNVHR8ESjBIMEagRKBChkBodHRwOi8vY2VydGVu
# cm9sbC5hc2Mub2hpby1zdGF0ZS5lZHUvcGtpL0FTQyUyMFBLSSUyME9mZmxpbmUu
# Y3JsMA0GCSqGSIb3DQEBCwUAA4IBAQAifGwk/QoUSRvJ/ecvyk6MymoQgZByKSsn
# 1BNkJ3R7RjUE75/1cFVhRylPH3ADe8wRzjwJF1BgJsa1p2TCVHpIoxOWV4EwWwqU
# k3ufAGfxhMd7D5AAxOon0UKUIgcW9LCq+R7GfcbBsFxc9IL6GQVRTISTOkfzsqqP
# 4tUe5joCIGfO2qcx2uhnavVF+4nq2OrQEMqM/gOWD+YhmMh/QrlpMOOSBdhpKBk4
# lF2/3+dqD0dVuX7/s6xnUoYwDyp1rw/ExOy6kT8dNSVIjXVXEd2/bhqD6UqYYly4
# KrwQTTbeHQif7Q8E0ecf+FOhrBmZCwYhXeSmnTPT7vMmfvU4aOEyMIIGZjCCBU6g
# AwIBAgITegAA4Q+dSse+55kspAABAADhDzANBgkqhkiG9w0BAQsFADBYMRMwEQYK
# CZImiZPyLGQBGRYDZWR1MRowGAYKCZImiZPyLGQBGRYKb2hpby1zdGF0ZTETMBEG
# CgmSJomT8ixkARkWA2FzYzEQMA4GA1UEAxMHQVNDLVBLSTAeFw0yMjA0MTcxNDI5
# MjFaFw0yMzA0MTcxNDI5MjFaMIGUMRMwEQYKCZImiZPyLGQBGRYDZWR1MRowGAYK
# CZImiZPyLGQBGRYKb2hpby1zdGF0ZTETMBEGCgmSJomT8ixkARkWA2FzYzEXMBUG
# A1UECxMOQWRtaW5pc3RyYXRvcnMxEjAQBgNVBAMTCWtlbGxlci40YTEfMB0GCSqG
# SIb3DQEJARYQa2VsbGVyLjRAb3N1LmVkdTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBANJyDgYNySplxbw/CyHHvLSAa0IGnMKoelKIqh2uBz7eA8osQRiZ
# 5+H9IZGSjjUz6o6xFdqLSL+zgzjVrqs/wXZDcHJyOvUSYLJXQ9/FipmOM0TNHMts
# vUNrSqIu2kyEQnvkNX9bTcfziDpuzQW1KiK9M54EoERX61BIUgCrn3fUB5R/v12n
# t+/aXI6cIm6fJDOCD/k5XQKyXC6BWcAmOZCCr2YRmFVyW/bHez9HXhBZ44WQBgJ8
# jS53rBFxlSNmDiB1qn5O5xJMX/aoEf0GRgI89q99jmLrcDEk/YMfqq7Pr1atRh0P
# Atk7C0f38aj9LNqJpZ9dH+gHqd2TMuXW2zu45RjX+sZ2J96xCl6SVrdSqVuDSCnq
# AMtAIOzgoDjH+263xmuRiyi5iWVkYh5sIQJ0M/nVJWWfa4Fi9+qGRpUCaI4GtHy3
# 23jlU8EFi+ebnPqNY1EdXzvhtF5FXnoguMH/oGnWsCm51JTB7WePShEJloL7i2OZ
# 65QE8U8zuXCxDo3CJpl6fbpd+ntCSxBZnrRhnsxLoD5CMCOEfbvJEM6+hsYwgxEI
# 5SBbM+AUbslp4HPWR6BNZIiLSHH3GoTpxs1DC3PajdeWlgigwb+2vsxjw55xQFvL
# oMGRY8haLpzetIbj5XDkaPxuUCRRNuiTEPXOCYUMjh85yAU256c+e02FAgMBAAGj
# ggHqMIIB5jA7BgkrBgEEAYI3FQcELjAsBiQrBgEEAYI3FQiHps4T49FzgumVIoT0
# jhjIwUl6gofXTITr6w0CAWQCAQ0wEwYDVR0lBAwwCgYIKwYBBQUHAwMwCwYDVR0P
# BAQDAgeAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFIO5
# hudGmrID2txhbFUlhuoo1tuaMB8GA1UdIwQYMBaAFC4EnoT08H8Z+LCHu6DzJBiM
# sPe2MEUGA1UdHwQ+MDwwOqA4oDaGNGh0dHA6Ly9jZXJ0ZW5yb2xsLmFzYy5vaGlv
# LXN0YXRlLmVkdS9wa2kvQVNDLVBLSS5jcmwwgacGCCsGAQUFBwEBBIGaMIGXMF0G
# CCsGAQUFBzAChlFodHRwOi8vY2VydGVucm9sbC5hc2Mub2hpby1zdGF0ZS5lZHUv
# cGtpL1BLSS1DQS5hc2Mub2hpby1zdGF0ZS5lZHVfQVNDLVBLSSgxKS5jcnQwNgYI
# KwYBBQUHMAGGKmh0dHBzOi8vY2VydGVucm9sbC5hc2Mub2hpby1zdGF0ZS5lZHUv
# b2NzcDA3BgNVHREEMDAuoCwGCisGAQQBgjcUAgOgHgwca2VsbGVyLjRhQGFzYy5v
# aGlvLXN0YXRlLmVkdTANBgkqhkiG9w0BAQsFAAOCAQEAVbwyi6GWGTsBKQ4X51zF
# AX6IOmtiBYxyklQa6GrZM1blyBbNVlTQKq09io6VJZrLFi161d0VgZlae1VWQYy9
# EoGL2o5syNH/dyUyCTMSAAws5K3lNUwzqytD/LNXVqoR2o0kXpxa0ryCq6/3LQAm
# h33AUNIdbfX6gJ96UKtv/GiwAt1yJPgdED45nf/c6iR/o5tQNRUVbrs/au4yLqQL
# gfjhCzVnF36WnnLWQWCOGM96dq8evKMA/U5UuM8/8MQvV/CMUP0HCoTofmyrlPNb
# 3xr2E175XhiKIwPuIL1otnNZB30+ZIYKxkZniS/sUbghzFAfNOytPowH0vni82FX
# ZTGCAxAwggMMAgEBMG8wWDETMBEGCgmSJomT8ixkARkWA2VkdTEaMBgGCgmSJomT
# 8ixkARkWCm9oaW8tc3RhdGUxEzARBgoJkiaJk/IsZAEZFgNhc2MxEDAOBgNVBAMT
# B0FTQy1QS0kCE3oAAOEPnUrHvueZLKQAAQAA4Q8wCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPkd
# Ez2CfHrLFGhCqGV/ENKr2cqAMA0GCSqGSIb3DQEBAQUABIICACmiprjDZqB8+QjR
# OguTtApvOhUwNiDmyxjizZQ/KTvYhoH7icx2f4ZGie3tm2GtypQVEIOZ99ya/68Z
# YkcPq0XfLJhcotCW/0nKp8zNaBCR3xLPBJZYuvVK5Ejsix/4Zv2WkuIgko93wjLL
# 5mcPNL8T5mbJ6XRowTSfxsez5oFGBsVWRHUcevMV8rPWLFoNZu8TUeLxkjgtggRo
# gWSsj0a3cIG5iMp7ZAUXIncenEMtOeuz3pTH4QlNkaqr/S7YKotPwXBgpTOZZK74
# DqhAEYpxUnOmI8HlR4lIP9jR8rRmfSjjcGQubLPbB+q86kaewMPSPAOSgwbWkAyS
# tmSqnanpMdCcjb/SShiCM8bBq8AB4Wf09vxsfZK5D2IVraSgYqNXAiaXpmqdGRgx
# WAXue/cQM2bY2bJ/7pAIcphtbGm9XcQ29pktVu873Xi0SEaSVUnJoP5U+fQd9KWY
# fDjbA5GUhshAUGYuA5SkjBjougtB4txbgSmg1m+bTcCdIdwBmgUbghVuj724eGwD
# 8QMx3wjhOg96A4f5t9D9EgLynKjNWa2dmPIZC5o1aNVcfgzX7/l18MEia1z4vHAt
# tNMOTSseLVk0abjJrRQyhYH8oSDjarGrJlPWlM6g45AayNlU5szKQIvN5FH74iwv
# vmcKWiiPSsM0jmiam6UJUh9O8cFV
# SIG # End signature block
