### Projects

<#
.Synopsis
    Get a project in TeamDynamix.
.DESCRIPTION
    Get or search for a project in TeamDynamix.
.PARAMETER ID
    ID of the project.
.PARAMETER Name
    The project name to search on.
.PARAMETER NameLike
    The text to perform a LIKE search on the project name.
.PARAMETER IsGlobal
    Whether to return global projects.
.PARAMETER PriorityIDs
    The IDs of associated priorities to filter on.
.PARAMETER AccountIDs
    The IDs of associated accounts/departments to filter on.
.PARAMETER TypeIDs
    The IDs of associated types to filter on.
.PARAMETER ClassificationIDs
    The IDs of associated classifications to filter on.
.PARAMETER RiskIDs
    The IDs of associated risks to filter on.
.PARAMETER ProcessIDs
    The IDs of associated processes to filter on.
.PARAMETER GoalIDs
    The IDs of associated goals to filter on.
.PARAMETER SystemIDs
    The IDs of associated systems to filter on.
.PARAMETER PortfolioIDs
    The IDs of associated portfolios to filter on.
.PARAMETER RisksScoreFrom
    The minimum risks score to filter on.
.PARAMETER RisksScoreTo
    The maximum risks score to filter on.
.PARAMETER GoalsScoreFrom
    The minimum goals score to filter on.
.PARAMETER GoalsScoreTo
    The maximum goals score to filter on.
.PARAMETER ScorecardScoreFrom
    The minimum scorecard score to filter on.
.PARAMETER ScorecardScoreTo
    The maximum scorecard score to filter on.
.PARAMETER CompositeScoreFrom
    The minimum composite score to filter on.
.PARAMETER CompositeScoreTo
    The maximum composite score to filter on.
.PARAMETER CompositeScorePercentFrom
    The minimum composite score percentage to filter on.
.PARAMETER CompositeScorePercentTo
    The maximum composite score percentage to filter on.
.PARAMETER CreatedDateFrom
    The minimum created date to filter on.
.PARAMETER CreatedDateTo
    The maximum created date to filter on.
.PARAMETER StartsOperator
    The operator to use for TeamDynamix.Api.Projects.ProjectSearch.Starts filtering.
.PARAMETER Starts
    The start date filtering to apply, used in conjunction with the TeamDynamix.Api.Projects.ProjectSearch.StartsOperator.
.PARAMETER EndsOperator
    The operator to use for TeamDynamix.Api.Projects.ProjectSearch.Ends filtering.
.PARAMETER Ends
    The end date filtering to apply, used in conjunction with the TeamDynamix.Api.Projects.ProjectSearch.EndsOperator.
.PARAMETER EstimatedHoursFrom
    The minimum estimated hours to filter on.
.PARAMETER EstimatedHoursTo
    The maximum estimated hours to filter on.
.PARAMETER ManagerUID
    The UID of the project manager to filter on.
.PARAMETER ProjectIDs
    The project IDs to filter on.
.PARAMETER ProjectIDsExclude
    The project IDs to exclude from search results.
.PARAMETER PortfolioIDsExclude
    The portfolio IDs to exclude from search results.
.PARAMETER StatusLastUpdatedOperator
    The operator to use for TeamDynamix.Api.Projects.ProjectSearch.StatusLastUpdated filtering.
.PARAMETER StatusLastUpdated
    The last status update date filtering to apply, used in conjunction with the TeamDynamix.Api.Projects.ProjectSearch.StatusLastUpdatedOperator.
.PARAMETER StatusIDs
    The IDs of associated statuses to filter on.
.PARAMETER BudgetOperator
    The operator to use for TeamDynamix.Api.Projects.ProjectSearch.Budget filtering.
.PARAMETER Budget
    The budget filtering to apply, used in conjunction with the TeamDynamix.Api.Projects.ProjectSearch.BudgetOperator.
.PARAMETER PercentCompleteOperator
    The operator to use for TeamDynamix.Api.Projects.ProjectSearch.PercentComplete filtering.
.PARAMETER PercentComplete
    The percent complete filtering to apply, used in conjunction with the TeamDynamix.Api.Projects.ProjectSearch.PercentCompleteOperator.
.PARAMETER IsOpen
    The open status to filter on.
.PARAMETER IsActive
    The active status to filter on.
.PARAMETER SponsorName
    The name of the associated sponsor to filter on.
.PARAMETER SponsorEmail
    The email of the associated sponsor to filter on.
.PARAMETER SponsorUID
    The UID of the associated sponsor to filter on.
.PARAMETER ReportsToName
    The name of the &quot;reports to&quot; user to filter on.
.PARAMETER ReportsToUID
    The UID of the &quot;reports to&quot; user to filter on.
.PARAMETER CascadeReportsToUID
    Whether TeamDynamix.Api.Projects.ProjectSearch.ReportsToUID filtering should be cascaded.
.PARAMETER FunctionalRoleIDs
    The IDs of associated functional roles to filter on.
.PARAMETER ShowManagedByPlan
    Whether projects managed by plan should be returned.
.PARAMETER ShowManagedByProject
    Whether projects managed by project should be returned.
.PARAMETER ShowManagedBoth
    Whether both projects managed by plan and project should be returned.
.PARAMETER SelectedFieldIDs
    The IDs of associated selected fields to filter on.
.PARAMETER IsPrivate
    The private status to filter on.
.PARAMETER HasTimeOff
    Whether projects with time off time types should be returned.
.PARAMETER HasPortfolio
    Whether projects associated with a portfolio should be returned.
.PARAMETER ShouldEnforceProjectMembership
    Whether project membership should be enforced in the search results.
.PARAMETER CustomAttributes
    The custom attributes to filter on.
.PARAMETER IsPublic
    The public status to filter on.
.PARAMETER IsPublished
    The published status to filter on.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.PARAMETER Detail
    Return full detail for found projects.
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
    C:\>Get-TDProject -ID 55433

    Gets project with ID 55433.
.EXAMPLE
    C:\>Get-TDProject -NameLike "Big"

    Gets all projects with "Big" in their name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProject
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID number for the project
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [Int32]
        $ID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $Name,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $NameLike,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $IsGlobal,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $PriorityIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $AccountIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $TypeIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ClassificationIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $RiskIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ProcessIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $GoalIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $SystemIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $PortfolioIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $RisksScoreFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $RisksScoreTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $GoalsScoreFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $GoalsScoreTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $ScorecardScoreFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $ScorecardScoreTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $CompositeScoreFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $CompositeScoreTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $CompositeScorePercentFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $CompositeScorePercentTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[DateTime]]
        $CreatedDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[DateTime]]
        $CreatedDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $StartsOperator,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[DateTime]]
        $Starts,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $EndsOperator,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[DateTime]]
        $Ends,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $EstimatedHoursFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $EstimatedHoursTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Guid]]
        $ManagerUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ProjectIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ProjectIDsExclude,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $PortfolioIDsExclude,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $StatusLastUpdatedOperator,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[DateTime]]
        $StatusLastUpdated,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $StatusIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $BudgetOperator,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double]]
        $Budget,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $PercentCompleteOperator,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32]]
        $PercentComplete,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsOpen,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsActive,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $SponsorName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $SponsorEmail,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Guid]
        $SponsorUID = [guid]::Empty,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $ReportsToName,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Guid]]
        $ReportsToUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $CascadeReportsToUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $FunctionalRoleIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $ShowManagedByPlan,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $ShowManagedByProject,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $ShowManagedBoth,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $SelectedFieldIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsPrivate,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $HasTimeOff,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $HasPortfolio,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $ShouldEnforceProjectMembership,

        # The custom attributes to filter on.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $CustomAttributes,

        # A value indicating whether this project is public. This is null by default and can be set to true / false to filter.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsPublic,

        # A value indicating whether this project is published. This is null by default and can be set to true / false to filter.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsPublished,

        # Return full detail for found projects.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

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
        $LocalIgnoreParameters = @('ID','Detail','Exact')
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving project $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $ProjectSearch = [TeamDynamix_Api_Projects_ProjectSearch]::new()
                Update-Object -InputObject $ProjectSearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                # Reformat object for upload to TD, include proper date format
                $ProjectSearchTD = [TD_TeamDynamix_Api_Projects_ProjectSearch]::new($ProjectSearch)
                Write-ActivityHistory 'Retrieving matching TeamDynamix projects'
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $ProjectSearchTD -Depth 10)
            }
        }

        if ($Return)
        {
            # Get detail
            if ($Detail)
            {
                $Return = $Return.ID | Get-TDProject -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Projects_Project]::new($_)})
        }
    }
}

<#
.Synopsis
    Modify a project in TeamDynamix.
.DESCRIPTION
    Modify a project in TeamDynamix.
.PARAMETER ID
    ID number of the project in TeamDynamix.
.PARAMETER Name
    Name of the project in TeamDynamix.
.PARAMETER Budget
    Project budget in dollars.
.PARAMETER AccountID
    Project account ID number.
.PARAMETER SponsorUID
    Project sponsor ID number
.PARAMETER Description
    Project description.
.PARAMETER ExpensesBudget
    Project expenses budge in dollars.
.PARAMETER AllowProjectTime
    Allow project to keep time.
.PARAMETER ApproveTimeByReportsTo
    Project time approvals follow user Reports-To field.
.PARAMETER PriorityID
    Project priority ID number.
.PARAMETER IsActive
    Boolean to set project to be active or not.
.PARAMETER TimeBudget
    Project time budget.
.PARAMETER TypeID
    Project type ID number.
.PARAMETER IsPublic
    A value indicating whether this project is publicly viewable.
.PARAMETER IsPublished
    A value indicating whether this project is published to authenticated
    users.
.PARAMETER UpdateStartEnd
    Boolean to trigger project start/end update.
.PARAMETER ScheduleHoursByPlan
    Boolean to schedule hours by plan or not.
.PARAMETER AllocationEditMode
    The allocation edit mode which governs how resources are scheduled by
    resource pool managers from the Resource Management Console.
.PARAMETER UseRemainingHours
    A value indicating whether the project's tasks should be updated with
    remaining hours instead of percent complete.
.PARAMETER AlertOnEstimatedHoursExceeded
    A value indicating whether the project manager should be alerted
    periodically when plan estimated hours exceed project estimated hours.
.PARAMETER AlertOnAssignedHoursExceeded
    A value indicating whether the project manager should be alerted
    periodically when plan assigned hours exceed project estimated hours.
.PARAMETER ClassificationID
    Project classification ID number
.PARAMETER AddContact
    Boolean to set whether project should automatically add contacts.
.PARAMETER Requirements
    Project requirements description.
.PARAMETER EndDate
    End date of the project.
.PARAMETER StartDate
    Start date of the project.
.PARAMETER Attributes
    The custom attributes.
.PARAMETER ServiceID
    The ID of the associated service.
.PARAMETER RemoveAttributes
    Custom attributes to be removed.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProject -ID 2322 -Description 'Updated description'

    Updates the project description for specified project.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDProject
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ID,

        # Project name
        [Parameter(Mandatory=$false)]
        [String]
        $Name,

        # Project budget in dollars
        [Parameter(Mandatory=$false)]
        [Double]
        $Budget,

        # Project account ID number
        [Parameter(Mandatory=$false)]
        [Int32]
        $AccountID,

        # Project sponsor ID number
        [Parameter(Mandatory=$false)]
        [Guid]
        $SponsorUID = [guid]::Empty,

        # Project description
        [Parameter(Mandatory=$false)]
        [String]
        $Description,

        # Project expenses budget in dollars
        [Parameter(Mandatory=$false)]
        [Double]
        $ExpensesBudget,

        # Allow project to keep time
        [Parameter(Mandatory=$false)]
        [Boolean]
        $AllowProjectTime,

        # Project time approvals follow user Reports-To field
        [Parameter(Mandatory=$false)]
        [Boolean]
        $ApproveTimeByReportsTo,

        # Project priority ID
        [Parameter(Mandatory=$false)]
        [Int32]
        $PriorityID,

        # Is project active
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsActive,

        # Project time budget
        [Parameter(Mandatory=$false)]
        [Double]
        $TimeBudget,

        # Project type ID
        [Parameter(Mandatory=$false)]
        [Int32]
        $TypeID,

        # A value indicating whether this project is publicly viewable.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsPublic,

        # A value indicating whether this project is published to authenticated users.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsPublished,

        # Update project start/end
        [Parameter(Mandatory=$false)]
        [Boolean]
        $UpdateStartEnd,

        # Schedule hours by plan
        [Parameter(Mandatory=$false)]
        [Boolean]
        $ScheduleHoursByPlan,

        # The allocation edit mode which governs how resources are scheduled by resource pool managers from the Resource Management Console.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_ResourceAllocationEditMode]
        $AllocationEditMode,

        # A value indicating whether the project's tasks should be updated with remaining hours instead of percent complete.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $UseRemainingHours,

        # A value indicating whether the project manager should be alerted periodically when plan est. hours exceed project est. hours.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $AlertOnEstimatedHoursExceeded,

        # A value indicating whether the project manager should be alerted periodically when plan assigned hours exceed project est. hours.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $AlertOnAssignedHoursExceeded,

        # Project classification ID
        [Parameter(Mandatory=$false)]
        [Int32]
        $ClassificationID,

        # Project should add contacts automatically
        [Parameter(Mandatory=$false)]
        [Boolean]
        $AddContact,

        # Project requirements description
        [Parameter(Mandatory=$false)]
        [String]
        $Requirements,

        # End date of project
        [Parameter(Mandatory=$false)]
        [DateTime]
        $EndDate,

        # Start date of project
        [Parameter(Mandatory=$false)]
        [DateTime]
        $StartDate,

        # The custom attributes.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $Attributes,

        # The ID of the associated service.
        [Parameter(Mandatory=$false)]
        [Int32]
        $ServiceID,

        # Indicates that specified attributes should be removed
        [Parameter(Mandatory=$false)]
        [ValidateScript({
            $AttributeNames = (Get-TDCustomAttribute -ComponentID Projects -AuthenticationToken $TDAuthentication -Environment $Environment).Name
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
        $LocalIgnoreParameters = @('ID','RemoveAttributes')
        #  Extract relevant list of parameters from the current command
        $ChangeParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys | Where-Object {(($_ -notin $LocalIgnoreParameters) -and ($_ -notin $GlobalIgnoreParameters))}
    }
    Process
    {
        #  Compare parameters from current invocation to list of relevant parameters, throw error if none are present
        if (-not ($MyInvocation.BoundParameters.GetEnumerator() | Where-Object {$_.Key -in $ChangeParameters}))
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'No changes specified'
        }
        # Retrieve existing project
        Write-ActivityHistory "Getting full project record for $ID on TeamDynamix."
        try
        {
            $TDProject = Get-TDProject -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find project $ID"
        }
        Write-ActivityHistory 'Project exists. Setting properties.'
        Update-Object -InputObject $TDProject -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Remove attributes specified for removal
        if ($RemoveAttributes)
        {
            foreach ($RemoveAttribute in $RemoveAttributes)
            {
                $TDProject.RemoveCustomAttribute($RemoveAttribute)
            }
        }
        # Reformat object for upload to TD, include proper date format
        $TDProjectTD = [TD_TeamDynamix_Api_Projects_Project]::new($TDProject)
        if ($pscmdlet.ShouldProcess("$ID - $($TDProject | Out-String)", 'Update project properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            try
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDProjectTD -Depth 10 -Compress)
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Error setting project ID: $ID.`n$($TDProject | Out-String)"
            }
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Projects_Project]::new($Return)
            }
            Write-ActivityHistory ($Return | Out-String)
        }
        if ($Passthru)
        {
            Write-Output $Return
        }
    }
}

<#
.Synopsis
    Update a project in TeamDynamix.
.DESCRIPTION
    Update a project in TeamDynamix by adding a project feed entry.
.PARAMETER ID
    The ID number of the project
.PARAMETER Body
    The body of the feed entry.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDProject -ID 783421 -Body "Update entry 1"

    Add a project feed entry to specified project.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Update-TDProject
{
    [CmdletBinding()]
    Param
    (
        # Project ID
        [Parameter(Mandatory=$true)]
        [int]
        $ID,

        # The body of the feed entry
        [Parameter(Mandatory=$true)]
        [String]
        $Body,

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
        $LocalIgnoreParameters = @('ID')
    }
    Process
    {
        $FeedEntry = [TeamDynamix_Api_Feed_ItemUpdate]::new()
        Update-Object -InputObject $FeedEntry -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        Write-ActivityHistory 'Updating TeamDynamix project feed.'
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $FeedEntry -Depth 10)
        if ($Return)
        {
            $Return = [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
        }
        return $Return
    }
}

<#
.Synopsis
    Get resources for a project in TeamDynamix.
.DESCRIPTION
    Get resources (staff) for a project in TeamDynamix.
.PARAMETER ID
    Project ID number in TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectResources -ID 783421

    Get a list of resources for the specified project.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectResources
{
    [CmdletBinding()]
    Param
    (
        # Project ID
        [Parameter(Mandatory=$true)]
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
        Write-ActivityHistory "Getting resources for project $ID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ID/resources" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Projects_Resource]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Get project plans in TeamDynamix.
.DESCRIPTION
    Get a project plan or search for project plans in TeamDynamix. Search by
    name, or retrieve all plans the current user is a member of.
.PARAMETER PlanID
    Return this plan ID.
.PARAMETER NameLike
    The search text to filter on. If this is set, this will sort the results by
    their text relevancy.
.PARAMETER ProjectID
    The project ID that will be filtered on.
.PARAMETER IncludeEmpty
    A value indicating whether plans without tasks should be included.
.PARAMETER CurrentUser
    Return all plans the current user is a member of.
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
    C:\>Get-TDProjectPlan -ID 75500 -ProjectID 430711

    Returns the specified project plan for the specified project.
.EXAMPLE
    C:\>Get-TDProjectPlan -ProjectID 430711

    Returns all project plans for the specified project.
.EXAMPLE
    C:\>Get-TDProjectPlan -CurrentUser

    Returns all project plans the current user is a member of.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectPlan
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Plan ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [int]
        $PlanID,

        # The project ID that will be filtered on
        [Parameter(Mandatory=$true,
                   ParameterSetName='Search')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [Int32]
        $ProjectID,

        # The search text to filter on. If this is set, this will sort the results by their text relevancy.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $NameLike,

        # A value indicating whether plans without tasks should be included.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Boolean]
        $IncludeEmpty,

        # Set to return plans for the current user
        [Parameter(Mandatory=$false,
                   ParameterSetName='CurrentUser')]
        [switch]
        $CurrentUser,

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
        $LocalIgnoreParameters = @('ID','CurrentUser','Exact')
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving plan $PlanID for project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $PlanSearch = [TeamDynamix_Api_Plans_PlanSearch]::new()
                Update-Object -InputObject $PlanSearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                Write-ActivityHistory 'Retrieving matching TeamDynamix plans'
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $PlanSearch -Depth 10)
            }
            'CurrentUser'
            {
                Write-ActivityHistory "Retrieving plans the current user is a member of"
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/list" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Plans_Plan]::new($_)})
        }
    }
}

<#
.Synopsis
    Modify a project plan in TeamDynamix.
.DESCRIPTION
    Modify a project plan name or description in TeamDynamix.
.PARAMETER ProjectID
    Project ID number to be modified.
.PARAMETER PlanID
    Plan ID number to be modified.
.PARAMETER DraftID
    Plan draft ID number to be modified.
.PARAMETER Title
    New title of the project plan. Required.
.PARAMETER Description
    New description of the project plan
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProjectPlan -ProjectID 5591 -PlanID 71 -DraftID 5 -Title "New title" -Description "New Description."

    Sets the title and description text for the draft of the project plan
    specified.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDProjectPlan
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanID,

        # Plan draft ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $DraftID,

        # Title for plan
        [Parameter(Mandatory=$true)]
        [String]
        $Title,

        # Description of plan
        [Parameter(Mandatory=$false)]
        [String]
        $Description,

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
        $LocalIgnoreParameters = @()
    }
    Process
    {
        $PlanEdit = [TeamDynamix_Api_Plans.PlanEdit]::new()
        Update-Object -InputObject $PlanEdit -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        Write-ActivityHistory 'Updating TeamDynamix project $ProjectID, plan $PlanID, draft $DraftID.'
        if ($pscmdlet.ShouldProcess(($PlanEdit |Out-String), 'Editing project plan'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/drafts/$DraftID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $PlanEdit -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_PlanUpdates]::new($Return)
            }
            return $Return
        }
    }
}

<#
.Synopsis
    Gets resource for the user who has a project plan checked out from
    TeamDynamix.
.DESCRIPTION
    Gets resource for the user who has a project plan checked out from
    TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project plan.
.PARAMETER PlanID
    Plan ID number for the project plan.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectPlanCheckoutUser -ProjectID 5591 -PlanID 71

    Get the resources for the user who checked out the specified project plan.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectPlanCheckoutUser
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanID,

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
        Write-ActivityHistory "Getting resources for project $ProjectID, plan $PlanID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = [TeamDynamix_Api_Projects_Resource]::new($Return)
        }
        return $Return
    }
}

<#
.Synopsis
    Get the feed for a project plan in TeamDynamix.
.DESCRIPTION
    Get the feed for a project plan in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project plan.
.PARAMETER PlanID
    Plan ID number for the project plan.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectPlanFeed -ProjectID 5591 -PlanID 71

    Get the feed for the specified project plan.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectPlanFeed
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanID,

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
        Write-ActivityHistory "Getting feed for project $ProjectID, plan $PlanID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Get the tasks for a project plan in TeamDynamix.
.DESCRIPTION
    Get the tasks for a project plan in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project plan.
.PARAMETER PlanID
    Plan ID number for the project plan.
.PARAMETER TaskID
    Plan ID number for the project plan.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectPlanTask -ProjectID 5591 -PlanID 71

    Get all tasks for the specified project plan.
.EXAMPLE
    C:\>Get-TDProjectPlanTask -ProjectID 5591 -PlanID 71 -TaskID 77843

    Get specific task for the specified project plan.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectPlanTask
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Task')]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='Plan')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Task')]
        [Int32]
        $PlanID,

        # Task ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='Task')]
        [Int32]
        $TaskID,

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
        switch ($pscmdlet.ParameterSetName)
        {
            'Plan'
            {
                Write-ActivityHistory "Getting tasks for project $ProjectID, plan $PlanID."
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Plans_Task]::new($_)})
                }
            }
            'Task'
            {
                Write-ActivityHistory "Getting tasks for project $ProjectID, plan $PlanID, task $TaskID."
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks/$TaskID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = [TeamDynamix_Api_Plans_Task]::new($Return)
                }
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Modify a project plan task in TeamDynamix.
.DESCRIPTION
    Modify a project plan task in TeamDynamix.
.PARAMETER OutlineNumber
    The outline number of this task.
.PARAMETER Wbs
    The WBS (work breakdown structure) number.
.PARAMETER IsParent
    A value indicating whether this task is a parent task.
.PARAMETER IndentLevel
    The indentation level of this task.
.PARAMETER ParentID
    The ID of the task that is this task's parent or 0 if there is no parent.
.PARAMETER PlanID
    The ID of the TeamDynamix.Api.Plans.Plan containing this task.
.PARAMETER PlanName
    The name of the TeamDynamix.Api.Plans.Plan containing this task.
.PARAMETER IsFlagged
    A value indicating whether this task is flagged for further review.
.PARAMETER TicketID
    The ID of the source ticket that was converted to this task, or -1 when no such conversion was performed.
.PARAMETER TicketAppID
    The ID of the application containing the source ticket that was converted to this task, or -1 when no such conversion was performed.
.PARAMETER Field1
    The value for the custom column 'Field 1'.
.PARAMETER Field2
    The value for the custom column 'Field 2'.
.PARAMETER Field3
    The value for the custom column 'Field 3'.
.PARAMETER Field4
    The value for the custom column 'Field 4'.
.PARAMETER Field5
    The value for the custom column 'Field 5'.
.PARAMETER Field6
    The value for the custom column 'Field 6'.
.PARAMETER Field7
    The value for the custom column 'Field 7'.
.PARAMETER Field8
    The value for the custom column 'Field 8'.
.PARAMETER Field9
    The value for the custom column 'Field 9'.
.PARAMETER Field10
    The value for the custom column 'Field 10'.
.PARAMETER IsMilestone
    A value indicating whether this task is a milestone.
.PARAMETER IsConvertedFromTicket
    A value indicating whether the current task is converted from a ticket.
.PARAMETER HasExternalRelationships
    Gets a value indicating whether there are external relationships directly-involving this task (not any of its children).
.PARAMETER IsExternalRelationshipViolated
    A value indicating whether the task is in violation of one or more of its external relationships.
.PARAMETER CanShiftForward
    A value indicating whether this task can be shifted forward.
.PARAMETER ShiftForwardDate
    Gets the earliest date to which the task can be shifted forward.
.PARAMETER HasIssues
    Gets a value indicating whether any issues, regardless of status, are associated with this task.
.PARAMETER HasAttachments
    Gets a value indicating whether any file attachments are associated with this task.
.PARAMETER Priority
    The priority of the task. 0 = None, 1 = High, 2 = Medium / High, 3 = Medium, 4 = Medium / Low, 5 = Low
.PARAMETER IsStory
    A value indicating whether this task is a story.
.PARAMETER OpenIssuesCount
    The open issues count.
.PARAMETER IssuesCount
    The issues count.
.PARAMETER Predecessors
    Gets the relationships between predecessor tasks and this task. Do not use this property to set values. Use PredecessorsOutlineNumbersComplex i
.PARAMETER PredecessorsOutlineNumbersComplex
    A comma-separated list of the outline numbers of the task's predecessors, including any non-default relationship type or lag/lead values.
.PARAMETER Resources
    Gets the resources assigned to this task.
.PARAMETER ResourcesNamesAndPercents
    Gets a semicolon-separated list of the names/assignment percentages of the resources assigned to this task.
.PARAMETER IsCriticalPath
    A value indicating whether this task is on the critical path.
.PARAMETER StatusID
    The ID of the Custom Task Status.
.PARAMETER Status
    The status of the task. This is a progression status (in progress, overdue, etc) instead of a custom user-defined status.
.PARAMETER OrderInParent
    The order in parent for this task. The order in parent is the index of this task within its parent task. If no parent task is present, order in parent determines the task's order in the overall root-level hierarchy.
.PARAMETER Tags
    The tags associated with the task.
.PARAMETER ID
    The ID of the project plan task.
.PARAMETER Title
    The title of the item.
.PARAMETER Description
    The description of the item.
.PARAMETER StartDateUtc
    The start date of the item.
.PARAMETER EndDateUtc
    The end date of the item.
.PARAMETER Duration
    Gets the duration of the task in absolute days.
.PARAMETER DurationString
    Set this field to a duration for the task. (Ex: 3 days, 4 weeks, 2 months)
.PARAMETER CompletedDateUtc
    The date the item was completed.
.PARAMETER EstimatedHoursAtCompletion
    The estimated number of hours spent on the task once the task is completed.
.PARAMETER ProjectID
    The ID of the containing project.
.PARAMETER ProjectIDEncrypted
    The encrypted ID of the containing project.
.PARAMETER ProjectName
    The name of the containing project.
.PARAMETER CreatedUID
    The UID of the creator.
.PARAMETER CreatedFullName
    The full name of the creator.
.PARAMETER CreatedDate
    The date/time the item was created.
.PARAMETER EstimatedHours
    The estimated hours of the item.
.PARAMETER EstimatedHoursBaseline
    Gets the baselined estimated hours.
.PARAMETER ActualHours
    The accrued hours on the item.
.PARAMETER PercentComplete
.PARAMETER StartDateBaselineUtc
    The baselined start date.
.PARAMETER EndDateBaselineUtc
    The baselined end date.
.PARAMETER StoryPoints
    The story points for a task.
.PARAMETER ValuePoints
    The value points for a task.
.PARAMETER RemainingHours
    The remaining hours.
.PARAMETER PlanType
    The type of the associated plan.
.PARAMETER VarianceDays
    Gets the variance, in days, between the end date and the end date of the currently-active baseline.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProjectPlanTask

    ??
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDProjectPlanTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanID,

        # Task ID number
        [Parameter(Mandatory=$true)]
        [alias('TaskID')]
        [Int32]
        $ID,

        # Task ID number
        [Parameter(Mandatory=$false)]
        [String]
        $AppID,

        # The outline number of this task.
        [Parameter(Mandatory=$false)]
        [Int32]
        $OutlineNumber,

        # The WBS (work breakdown structure) number.
        [Parameter(Mandatory=$false)]
        [String]
        $Wbs,

        # A value indicating whether this task is a parent task.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsParent,

        # The indentation level of this task.
        [Parameter(Mandatory=$false)]
        [Int32]
        $IndentLevel,

        # The ID of the task that is this task's parent or 0 if there is no parent.
        [Parameter(Mandatory=$false)]
        [Int32]
        $ParentID,

        # The name of the TeamDynamix.Api.Plans.Plan containing this task.
        [Parameter(Mandatory=$false)]
        [String]
        $PlanName,

        # A value indicating whether this task is flagged for further review.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsFlagged,

        # The ID of the source ticket that was converted to this task, or -1 when no such conversion was performed.
        [Parameter(Mandatory=$false)]
        [Int32]
        $TicketID,

        # The ID of the application containing the source ticket that was converted to this task, or -1 when no such conversion was performed.
        [Parameter(Mandatory=$false)]
        [Int32]
        $TicketAppID,

        # The value for the custom column 'Field 1'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field1,

        # The value for the custom column 'Field 2'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field2,

        # The value for the custom column 'Field 3'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field3,

        # The value for the custom column 'Field 4'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field4,

        # The value for the custom column 'Field 5'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field5,

        # The value for the custom column 'Field 6'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field6,

        # The value for the custom column 'Field 7'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field7,

        # The value for the custom column 'Field 8'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field8,

        # The value for the custom column 'Field 9'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field9,

        # The value for the custom column 'Field 10'.
        [Parameter(Mandatory=$false)]
        [String]
        $Field10,

        # A value indicating whether this task is a milestone.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsMilestone,

        # A value indicating whether the current task is converted from a ticket.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsConvertedFromTicket,

        # Gets a value indicating whether there are external relationships directly-involving this task (not any of its children).
        [Parameter(Mandatory=$false)]
        [Boolean]
        $HasExternalRelationships,

        # A value indicating whether the task is in violation of one or more of its external relationships.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsExternalRelationshipViolated,

        # A value indicating whether this task can be shifted forward.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $CanShiftForward,

        # Gets the earliest date to which the task can be shifted forward.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $ShiftForwardDate,

        # Gets a value indicating whether any issues, regardless of status, are associated with this task.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $HasIssues,

        # Gets a value indicating whether any file attachments are associated with this task.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $HasAttachments,

        # The priority of the task. 0 = None, 1 = High, 2 = Medium / High, 3 = Medium, 4 = Medium / Low, 5 = Low
        [Parameter(Mandatory=$false)]
        [Int32]
        $Priority,

        # A value indicating whether this task is a story.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsStory,

        # The open issues count.
        [Parameter(Mandatory=$false)]
        [Int32]
        $OpenIssuesCount,

        # The issues count.
        [Parameter(Mandatory=$false)]
        [Int32]
        $IssuesCount,

        # Gets the relationships between predecessor tasks and this task. Do not use this property to set values. Use PredecessorsOutlineNumbersComplex i
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_Plans_TaskRelationship[]]
        $Predecessors,

        # A comma-separated list of the outline numbers of the task's predecessors, including any non-default relationship type or lag/lead values.
        [Parameter(Mandatory=$false)]
        [String]
        $PredecessorsOutlineNumbersComplex,

        # Gets the resources assigned to this task.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_Plans_TaskResource[]]
        $Resources,

        # Gets a semicolon-separated list of the names/assignment percentages of the resources assigned to this task.
        [Parameter(Mandatory=$false)]
        [String]
        $ResourcesNamesAndPercents,

        # A value indicating whether this task is on the critical path.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsCriticalPath,

        # The ID of the Custom Task Status.
        [Parameter(Mandatory=$false)]
        [Int32]
        $StatusID,

        # The status of the task. This is a progression status (in progress, overdue, etc) instead of a custom user-defined status.
        [Parameter(Mandatory=$false)]
        [String]
        $Status,

        # The order in parent for this task. The order in parent is the index of this task within its parent task. If no parent task is present, order in parent determines the task's order in the overall root-level hierarchy.
        [Parameter(Mandatory=$false)]
        [Int32]
        $OrderInParent,

        # The tags associated with the task.
        [Parameter(Mandatory=$false)]
        [String[]]
        $Tags,

        # The title of the item.
        [Parameter(Mandatory=$false)]
        [String]
        $Title,

        # The description of the item.
        [Parameter(Mandatory=$false)]
        [String]
        $Description,

        # The start date of the item.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $StartDateUtc,

        # The end date of the item.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $EndDateUtc,

        # Gets the duration of the task in absolute days.
        [Parameter(Mandatory=$false)]
        [Int32]
        $Duration,

        # Set this field to a duration for the task. (Ex: 3 days, 4 weeks, 2 months)
        [Parameter(Mandatory=$false)]
        [String]
        $DurationString,

        # The date the item was completed.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $CompletedDateUtc,

        # The estimated number of hours spent on the task once the task is completed.
        [Parameter(Mandatory=$false)]
        [Double]
        $EstimatedHoursAtCompletion,

        # The encrypted ID of the containing project.
        [Parameter(Mandatory=$false)]
        [String]
        $ProjectIDEncrypted,

        # The name of the containing project.
        [Parameter(Mandatory=$false)]
        [String]
        $ProjectName,

        # The UID of the creator.
        [Parameter(Mandatory=$false)]
        [String]
        $CreatedUID,

        # The full name of the creator.
        [Parameter(Mandatory=$false)]
        [String]
        $CreatedFullName,

        # The date/time the item was created.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $CreatedDate,

        # The estimated hours of the item.
        [Parameter(Mandatory=$false)]
        [Double]
        $EstimatedHours,

        # Gets the baselined estimated hours.
        [Parameter(Mandatory=$false)]
        [Double]
        $EstimatedHoursBaseline,

        # The accrued hours on the item.
        [Parameter(Mandatory=$false)]
        [Double]
        $ActualHours,

        [Parameter(Mandatory=$false)]
        [Double]
        $PercentComplete,

        # The baselined start date.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $StartDateBaselineUtc,

        # The baselined end date.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $EndDateBaselineUtc,

        # The story points for a task.
        [Parameter(Mandatory=$false)]
        [Double]
        $StoryPoints,

        # The value points for a task.
        [Parameter(Mandatory=$false)]
        [Double]
        $ValuePoints,

        # The remaining hours.
        [Parameter(Mandatory=$false)]
        [Double]
        $RemainingHours,

        # The type of the associated plan.
        [Parameter(Mandatory=$false)]
        [Int32]
        $PlanType,

        # Gets the variance, in days, between the end date and the end date of the currently-active baseline.
        [Parameter(Mandatory=$false)]
        [Int32]
        $VarianceDays,

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
        $LocalIgnoreParameters = @('AppID')
        #  Extract relevant list of parameters from the current command
        $ChangeParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys | Where-Object {(($_ -notin $LocalIgnoreParameters) -and ($_ -notin $GlobalIgnoreParameters))}
    }
    Process
    {
        #  Compare parameters from current invocation to list of relevant parameters, throw error if none are present
        if (-not ($MyInvocation.BoundParameters.GetEnumerator() | Where-Object {$_.Key -in $ChangeParameters}))
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'No changes specified'
        }
        # Retrieve existing project plan task
        Write-ActivityHistory "Getting full record for project $ProjectID, plan $PlanID, task $ID on TeamDynamix."
        try
        {
            $TDTask = Get-TDProjectPlanTask -ProjectID $ProjectID -PlanID $PlanID -TaskID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find project $ProjectID, plan $PlanID, task $ID"
        }
        Write-ActivityHistory 'Task exists. Setting properties.'
        Update-Object -InputObject $TDTask -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $TDTaskTD = [TD_TeamDynamix_Api_Projects_Project]::new($TDTask)
        # Build remaining components of body
        $AppIDObject = [TeamDynamix_Api_Plans_ApplicationIdentifier]::new($AppID)
        $Body = [TeamDynamix_Api_Plans_TaskChanges]::new($AppIDObject,$TDTaskTD)
        if ($pscmdlet.ShouldProcess("$ID - $($TDTask | Out-String)", 'Update project properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            try
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks/$ID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Body -Depth 10 -Compress)
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Error setting task ID: $ID.`n$($TDTask| Out-String)"
            }
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Plans_Task]::new($Return)
            }
            Write-ActivityHistory ($Return | Out-String)
        }
        if ($Passthru)
        {
            Write-Output $Return
        }
    }
}

<#
.Synopsis
    Get the feed for a project plan task in TeamDynamix.
.DESCRIPTION
    Get the feed for a project plan task in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project plan task.
.PARAMETER PlanID
    Plan ID number for the project plan task.
.PARAMETER TaskID
    Task ID number for the project plan task.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectPlanTaskFeed -ProjectID 5591 -PlanID 71 -TaskID 38871

    Get the feed for the specified project plan task.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectPlanTaskFeed
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Plan ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanID,

        # Task ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $TaskID,

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
        Write-ActivityHistory "Getting task feed for project $ProjectID, plan $PlanID, task $TaskID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks/$TaskID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Update a task in a project plan in TeamDynamix.
.DESCRIPTION
    Enter a comment into the feed for a task in a project plan in TeamDynamix.
.PARAMETER ProjectId
    The ID of the containing project.
.PARAMETER PlanId
    The ID of the containing plan.
.PARAMETER TaskId
    The ID of the task to update.
.PARAMETER Notify
    The people to notify.
.PARAMETER Comments
    The comments to include with the update.
.PARAMETER CompletedDate
    The completed date of the task.
.PARAMETER TimeTypeId
    The ID of the time type to use when adding a time entry as part of the update.
.PARAMETER HoursWorked
    The worked hours of the time entry to add as part of the update.
.PARAMETER DateWorked
    The date that the specified hours were worked when adding time.
.PARAMETER PercentComplete
    The percent complete of the task, on a 0 to 100 scale.
.PARAMETER RemainingHours
    The number of hours remaining on the task. This is only used if a project is set to update by remaining hours.
.PARAMETER IsPrivate
    A value indicating whether or not the update creates a private feed entry.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDProjectPlanTask -ProjectID 755519 -PlanID 1102 -TaskID -48882 -Comments "New comment"

    Enter the comment into the specified project plan task feed.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Update-TDProjectPlanTask
{
    [CmdletBinding()]
    Param
    (
        # The ID of the containing project.
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectId,

        # The ID of the containing plan.
        [Parameter(Mandatory=$true)]
        [Int32]
        $PlanId,

        # The ID of the task to update.
        [Parameter(Mandatory=$true)]
        [Int32]
        $TaskId,

        # The people to notify.
        [Parameter(Mandatory=$false)]
        [String[]]
        $Notify,

        # The comments to include with the update.
        [Parameter(Mandatory=$false)]
        [String]
        $Comments,

        # The completed date of the task.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $CompletedDate,

        # The ID of the time type to use when adding a time entry as part of the update.
        [Parameter(Mandatory=$false)]
        [Int32]
        $TimeTypeId,

        # The worked hours of the time entry to add as part of the update.
        [Parameter(Mandatory=$false)]
        [Double]
        $HoursWorked,

        # The date that the specified hours were worked when adding time.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $DateWorked,

        # The percent complete of the task, on a 0 to 100 scale.
        [Parameter(Mandatory=$false)]
        [Double]
        $PercentComplete,

        # The number of hours remaining on the task. This is only used if a project is set to update by remaining hours.
        [Parameter(Mandatory=$false)]
        [Double]
        $RemainingHours,

        # A value indicating whether or not the update creates a private feed entry.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsPrivate,

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
        $LocalIgnoreParameters = @()
    }
    Process
    {
        $TaskEntry = [TeamDynamix_Api_Plans_TaskUpdate]::new()
        Update-Object -InputObject $TaskEntry -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $TaskEntryTD = [TD_TeamDynamix_Api_Plans_TaskUpdate]::new($TaskEntry)
        Write-ActivityHistory 'Updating TeamDynamix project feed.'
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks/$TaskID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TaskEntryTD -Depth 10)
        if ($Return)
        {
            $Return = [TeamDynamix_Api_Plans_TaskUpdate]::new($Return)
        }
        return $Return
    }
}

<#
.Synopsis
    Get risk statuses from TeamDynamix.
.DESCRIPTION
    Get risk statuses from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectRiskStatuses

    Get a list of risk statuses.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectRiskStatuses
{
    [CmdletBinding()]
    Param
    (
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
        Write-ActivityHistory "Getting risk statuses."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/risks/statuses" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Issues_IssueStatus]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Get project risk in TeamDynamix.
.DESCRIPTION
    Get or search for project risks in TeamDynamix.
.PARAMETER ProjectID
    Project ID number in TeamDynamix.
.PARAMETER RiskID
    Project Risk ID number in TeamDynamix
.PARAMETER Probabilities
    The probabilities to filter on. Very Low is 0.05, Low is 0.1, Medium is
    0.2, High is 0.4, Very High is 0.8
.PARAMETER Impacts
    The impacts to filter on. Very Low is 0.05, Low is 0.1, Medium is 0.2, High
     is 0.4, Very High is 0.8
.PARAMETER Urgencies
    The urgencies to filter on. Very Low is 0.05, Low is 0.1, Medium is 0.2,
    High is 0.4, Very High is 0.8
.PARAMETER IsOpportunity
    The opportunity status to filter on.
.PARAMETER ResponseStrategyIDs
    The IDs of associated response strategies to filter on.
.PARAMETER MaxResults
    The maximum number of results to return, or <code>null</code> to have no restriction.
.PARAMETER ID
    The ID to filter on.
.PARAMETER ProjectIDs
    The project IDs to filter on.
.PARAMETER StatusIDs
    The status IDs to include.
.PARAMETER StatusIDsNot
    The status IDs to exclude.
.PARAMETER CategoryIDs
    The category IDs to filter on.
.PARAMETER ModifiedDateFrom
    The minimum last modified date to filter on.
.PARAMETER ModifiedDateTo
    The maximum last modified date to filter on.
.PARAMETER CreatedUID
    The UID of the creating user to filter on.
.PARAMETER CreatedDateFrom
    The minimum created date to filter on.
.PARAMETER CreatedDateTo
    The maximum created date to filter on.
.PARAMETER UpdatedFrom
    The minimum last update date to filter on.
.PARAMETER UpdatedTo
    The maximum last update date to filter on.
.PARAMETER UpdatedUID
    The UID of the updating user to filter on.
.PARAMETER ResponsibilityUID
    The UID of the responsible user to filter on.
.PARAMETER NameLike
    The text to perform a LIKE search on name.
.PARAMETER Exact
    Return only a single unambiguous match for NameLike searches. If search
    was ambiguous, that is, matched more than one location or room, return no
    result at all.
.PARAMETER CustomAttributes
    The custom attributes to filter on.
.PARAMETER Detail
    Return detailed information on the project risk. Used when searching.
    Requesting by project and risk ID will always return full data.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectRisk -ProjectID 34441 -RiskID 981

    Gets the specified project risk.
.EXAMPLE
    C:\>Get-TDProjectRisk -NameLike 'Main project risk'

    Gets all project risks with names containing the text specified.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectRisk
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [int]
        $ProjectID,

        # Risk ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [int]
        $RiskID,

        # The probabilities to filter on. Very Low is 0.05, Low is 0.1, Medium is 0.2, High is 0.4, Very High is 0.8
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double[]]]
        $Probabilities,

        # The impacts to filter on. Very Low is 0.05, Low is 0.1, Medium is 0.2, High is 0.4, Very High is 0.8
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double[]]]
        $Impacts,

        # The urgencies to filter on. Very Low is 0.05, Low is 0.1, Medium is 0.2, High is 0.4, Very High is 0.8
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Double[]]]
        $Urgencies,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Boolean]]
        $IsOpportunity,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32[]]]
        $ResponseStrategyIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32]]
        $MaxResults,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32]]
        $ID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32[]]]
        $ProjectIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32[]]]
        $StatusIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32[]]]
        $StatusIDsNot,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32[]]]
        $CategoryIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $ModifiedDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $ModifiedDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $CreatedUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $CreatedDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $CreatedDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $UpdatedFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $UpdatedTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $UpdatedUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $ResponsibilityUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $NameLike,

        # The custom attributes to filter on.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $CustomAttributes,

        # Return detailed information
        [Parameter(Mandatory=$false)]
        [switch]
        $Detail,

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
        $LocalIgnoreParameters = @('ProjectID','RiskID','Detail','Exact')
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving risk $RiskID for project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/risks/$RiskID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $RiskSearch = [TeamDynamix_Api_Issues_RiskSearch]::new()
                Update-Object -InputObject $RiskSearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                # Reformat object for upload to TD, include proper date format
                $RiskSearchTD = [TD_TeamDynamix_Api_Issues_RiskSearch]::new($RiskSearch)
                Write-ActivityHistory 'Retrieving matching TeamDynamix risks'
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/risks/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $RiskSearchTD -Depth 10)
            }
        }
        if ($Return)
        {
            if ($Detail)
            {
                $Return = $Return | ForEach-Object {Get-TDProjectRisk -ProjectID $_.ProjectID -RiskID $_.ID -AuthenticationToken $AuthenticationToken -Environment $Environment}
            }
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Issues_Risk]::new($_)})
        }
    }
}

<#
.Synopsis
    Modify a project risk in TeamDynamix.
.DESCRIPTION
    Modify a project risk in TeamDynamix.
.PARAMETER RiskID
    The risk ID.
.PARAMETER ProjectID
    The project ID.
.PARAMETER StatusID
    The status ID.
.PARAMETER Notify
    The email addresses to notify. This is an array of strings.
.PARAMETER Comments
    The comments.
.PARAMETER Attributes
    The custom attributes.
.PARAMETER IsPrivate
    A value indicating whether this update is private.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProjectRisk

    ??
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDProjectRisk
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # The risk ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $RiskID,

        # The project ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # The status ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $StatusID,

        # The email addresses to notify. This is an array of strings.
        [Parameter(Mandatory=$false)]
        [String[]]
        $Notify,

        # The comments.
        [Parameter(Mandatory=$true)]
        [String]
        $Comments,

        # The custom attributes.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $Attributes,

        # A value indicating whether this update is private.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsPrivate,

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
        $LocalIgnoreParameters = @()
    }
    Process
    {
        $TDRisk = [TeamDynamix_Api_Issues_RiskUpdate]::new()
        Update-Object -InputObject $TDRisk -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("Project $ProjectID, risk $RiskID - $($TDRisk | Out-String)", 'Update risk properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            try
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/risks/$RiskID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDRisk -Depth 10)
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Error setting risk ID $RiskID on project $ProjectID.`n$($TDRisk| Out-String)"
            }
            if ($Return)
            {
                return [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
            }
        }
    }
}

<#
.Synopsis
    Create a new project risk in TeamDynamix.
.DESCRIPTION
    Create a new project risk in TeamDynamix.
.PARAMETER IsOpportunity
    A value indicating whether this instance is a risk that represents an opportunity instead of a threat.
.PARAMETER Impact
    The impact of a risk or opportunity, should it occur with 0 meaning no impact and 1 meaning maximum possible impact.
.PARAMETER Probability
    The probability of a risk or opportunity coming to fruition 0 meaning no chance and 1 meaning guaranteed to happen.
.PARAMETER Urgency
    The urgency of a risk. This is autocalculated from Impact and Probability but can be manually adjusted as well.
.PARAMETER ResponseStrategyID
    The response strategy identifier used for marking how a risk will be responded to.
.PARAMETER Title
    The title.
.PARAMETER Description
    The description.
.PARAMETER IsRead
    Whether or not the current user has read the item.
.PARAMETER CategoryID
    The ID of the associated category.
.PARAMETER StatusID
    The ID of the associated status.
.PARAMETER ProjectID
    The ID of the associated project.
.PARAMETER ResponsibleUID
    The UID of the responsible user.
.PARAMETER Attributes
    The custom attribute collection for the issue.
.PARAMETER NotifyOnClosed
    Switch indicating that the creator should be notified when the issue is
    closed.
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
    C:\>New-TDProjectRisk -Title "Staff-related risk" -CategoryID 5 -StatusID 27 -ProjectID 55496

    Creates a new project risk called "Staff-related risk", with risk category
    ID 5, status ID 27, and for project ID 55496.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function New-TDProjectRisk
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Title for risk
        [Parameter(Mandatory=$true)]
        [String]
        $Title,

        # Risk category ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $CategoryID,

        # Risk status ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $StatusID,

        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # A value indicating whether this instance is a risk that represents an opportunity instead of a threat.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsOpportunity,

        # The impact of a risk or opportunity, should it occur with 0 meaning no impact and 1 meaning maximum possible impact.
        [Parameter(Mandatory=$false)]
        [System.Nullable[Double]]
        $Impact,

        # The probability of a risk or opportunity coming to fruition 0 meaning no chance and 1 meaning guaranteed to happen.
        [Parameter(Mandatory=$false)]
        [System.Nullable[Double]]
        $Probability,

        # The urgency of a risk. This is autocalculated from Impact and Probability but can be manually adjusted as well.
        [Parameter(Mandatory=$false)]
        [System.Nullable[Double]]
        $Urgency,

        # The response strategy identifier used for marking how a risk will be responded to.
        [Parameter(Mandatory=$false)]
        [System.Nullable[Int32]]
        $ResponseStrategyID,

        [Parameter(Mandatory=$false)]
        [String]
        $Description,

        [Parameter(Mandatory=$false)]
        [String]
        $ResponsibleUID,

        # Notify creator when the risk is closed
        [Parameter(Mandatory=$false)]
        [Switch]
        $NotifyOnClosed,

        # The custom attribute collection for the issue.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $Attributes,

        # Return newly created asset as an oject
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
        $LocalIgnoreParameters = @('NotifyOnClosed','Passthru')
    }
    Process
    {
        $NewRisk = [TeamDynamix_Api_Issues_Risk]::new()
        Update-Object -InputObject $NewRisk -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("title $Title on project $ProjectID", 'Add new risk'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/risks?NotifyOnClosed=$($NotifyOnClosed.IsPresent)" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewRisk -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Issues_Risk]::new($Return)
            }
            Write-ActivityHistory ($Return | Out-String)
            if ($Passthru)
            {
                Write-Output $Return
            }
        }
    }
    End
    {
    }
}

<#
.Synopsis
    Get the feed for a project risk in TeamDynamix.
.DESCRIPTION
    Get the feed for a project risk in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project risk.
.PARAMETER RiskID
    Risk ID number for the project risk.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectPlanRiskFeed -ProjectID 5591 -RiskID 38871

    Get the feed for the specified project risk.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectRiskFeed
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Risk ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $RiskID,

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
        Write-ActivityHistory "Getting risk feed for project $ProjectID, risk $RiskID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/risks/$RiskID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Adds a comment to a project risk feed in TeamDynamix
.DESCRIPTION
    Adds a comment to a project risk feed in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the feed be updated.
.PARAMETER RiskID
    Risk ID number for the feed be updated.
.PARAMETER Comments
    Comment to be added to risk feed.
.PARAMETER Notify
    Email addresses of individuals to notify with the comment.
.PARAMETER IsPrivate
    Switch to indicate if the comment should be flagged as private. Default is
    "not private".
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDProjectRisk -ProjectID 1055 -RiskID 40555 -Comments "Don't update this system without consult."

    Adds the comment to the specified project risk.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Update-TDProjectRisk
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ProjectID,

        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $RiskID,

        # Comment to add to risk feed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
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
        $LocalIgnoreParameters = @('ProjectID','RiskID')
    }
    Process
    {
        $Update = [TeamDynamix_Api_Feed_FeedEntry]::new()
        Update-Object -InputObject $Update -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        Write-ActivityHistory "Updating feed for TeamDynamix project $ProjectID, risk $RiskID, with comment, $Comment."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/risks/$RiskID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Update -Depth 10)
        if ($Return)
        {
            return [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
        }
    }
}

<#
.Synopsis
    Get a project issue in TeamDynamix.
.DESCRIPTION
    Get or search for project issues in TeamDynamix.
.PARAMETER ProjectID
    Project ID that holds the issue.
.PARAMETER IssueID
    The issue ID number to retrieve from the project.
.PARAMETER PriorityIDs
    The IDs of associated priorities to filter on.
.PARAMETER EndDateFrom
    The minimum end date to filter on.
.PARAMETER EndDateTo
    The maximum end date to filter on.
.PARAMETER StartDateFrom
    The minimum start date to filter on.
.PARAMETER StartDateTo
    The maximum start date to filter on.
.PARAMETER ParentIDs
    The IDs of associated parents to filter on.
.PARAMETER MaxResults
    The maximum number of results to return, or <code>null</code> to have no restriction.
.PARAMETER ID
    The ID to filter on.
.PARAMETER ProjectIDs
    The project IDs to filter on.
.PARAMETER StatusIDs
    The status IDs to include.
.PARAMETER StatusIDsNot
    The status IDs to exclude.
.PARAMETER CategoryIDs
    The category IDs to filter on.
.PARAMETER ModifiedDateFrom
    The minimum last modified date to filter on.
.PARAMETER ModifiedDateTo
    The maximum last modified date to filter on.
.PARAMETER CreatedUID
    The UID of the creating user to filter on.
.PARAMETER CreatedDateFrom
    The minimum created date to filter on.
.PARAMETER CreatedDateTo
    The maximum created date to filter on.
.PARAMETER UpdatedFrom
    The minimum last update date to filter on.
.PARAMETER UpdatedTo
    The maximum last update date to filter on.
.PARAMETER UpdatedUID
    The UID of the updating user to filter on.
.PARAMETER ResponsibilityUID
    The UID of the responsible user to filter on.
.PARAMETER NameLike
    The text to perform a LIKE search on name.
.PARAMETER CustomAttributes
    The custom attributes to filter on.
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
    C:\>Get-TDProjectIssue -ProjectID 34441 -IssueID 981

    Gets the specified project issue.
.EXAMPLE
    C:\>Get-TDProjectIssue -NameLike 'Top issue'

    Gets all project risks with names containing the text specified.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectIssue
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [Int32]
        $ProjectID,

        # Issue ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [Int32]
        $IssueID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $PriorityIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $EndDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $EndDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $StartDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $StartDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ParentIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[Int32]]
        $MaxResults,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $ProjectIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $StatusIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $StatusIDsNot,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Int32[]]
        $CategoryIDs,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $ModifiedDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $ModifiedDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $CreatedUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $CreatedDateFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $CreatedDateTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $UpdatedFrom,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [DateTime]
        $UpdatedTo,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $UpdatedUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $ResponsibilityUID,

        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [String]
        $NameLike,

        # The custom attributes to filter on.
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $CustomAttributes,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

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
        $LocalIgnoreParameters = @('ProjectID','IssueID','Detail','Exact')
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving issue $IssueID for project $ProjectID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/issues/$IssueID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $IssueSearch = [TeamDynamix_Api_Issues_IssueSearch]::new()
                Update-Object -InputObject $IssueSearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                # Reformat object for upload to TD, include proper date format
                $IssueSearchTD = [TD_TeamDynamix_Api_Issues_IssueSearch]::new($IssueSearch)
                Write-ActivityHistory 'Retrieving matching TeamDynamix issues'
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/issues/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $IssueSearchTD -Depth 10)
            }
        }
        if ($Return)
        {
            if ($Detail)
            {
                $Return = $Return | ForEach-Object {Get-TDProjectIssue -ProjectID $_.ProjectID -IssueID $_.ID -AuthenticationToken $AuthenticationToken -Environment $Environment}
            }
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Issues_Issue]::new($_)})
        }
    }
}

<#
.Synopsis
    Modify a project issue in TeamDynamix.
.DESCRIPTION
    Modify a project issue in TeamDynamix.
.PARAMETER IssueID
    The issue ID.
.PARAMETER TimeEntryDate
    The time entry date.
.PARAMETER HoursWorked
    The hours worked.
.PARAMETER TimeTypeID
    The time type ID.
.PARAMETER ParentID
    The parent Risk's identifier.
.PARAMETER ProjectID
    The project ID.
.PARAMETER StatusID
    The status ID.
.PARAMETER Notify
    The email addresses to notify. This is an array of strings.
.PARAMETER Comments
    The comments.
.PARAMETER Attributes
    The custom attributes.
.PARAMETER IsPrivate
    A value indicating whether this update is private.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDProjectIssue -ProjectID 55129 -IssueID 71129 -StatusID 6891 -Comments "Issue modified"

    Modifies the specified project issue with the specified comment and status ID.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDProjectIssue
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # The project ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # The issue ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $IssueID,

        # The status ID.
        [Parameter(Mandatory=$true)]
        [Int32]
        $StatusID,

        # The comments.
        [Parameter(Mandatory=$true)]
        [String]
        $Comments,

        # The time entry date.
        [Parameter(Mandatory=$false)]
        [DateTime]
        $TimeEntryDate,

        # The hours worked.
        [Parameter(Mandatory=$false)]
        [Double]
        $HoursWorked,

        # The time type ID.
        [Parameter(Mandatory=$false)]
        [Int32]
        $TimeTypeID,

        # The parent Risk's identifier.
        [Parameter(Mandatory=$false)]
        [Int32]
        $ParentID,

        # The email addresses to notify. This is an array of strings.
        [Parameter(Mandatory=$false)]
        [String[]]
        $Notify,

        # The custom attributes.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $Attributes,

        # A value indicating whether this update is private.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsPrivate,

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
        $LocalIgnoreParameters = @()
    }
    Process
    {
        $TDIssue = [TeamDynamix_Api_Issues_IssueUpdate]::new()
        Update-Object -InputObject $TDIssue -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $TDIssueTD = [TD_TeamDynamix_Api_Issues_IssueUpdate]::new($TDIssue)
        if ($pscmdlet.ShouldProcess("Project $ProjectID - $($TDIssue | Out-String)", 'Update issue properties'))
        {
            Write-ActivityHistory 'Updating TeamDynamix.'
            try
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/issues/$IssueID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDIssueTD -Depth 10)
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Error setting issue ID $IssueID on project $ProjectID.`n$($TDIssue| Out-String)"
            }
            if ($Return)
            {
                return [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
            }
        }
    }
    End
    {
    }
}

<#
.Synopsis
    Create a new project issue in TeamDynamix.
.DESCRIPTION
    Create a new project issue in TeamDynamix.
.PARAMETER EstimatedHours
    The estimated hours.
.PARAMETER StartDate
    The start date.
.PARAMETER EndDate
    The end date.
.PARAMETER PriorityID
    The ID of the associated priority.
.PARAMETER TaskID
    The ID of the associated task.
.PARAMETER Title
    The title.
.PARAMETER Description
    The description.
.PARAMETER CategoryID
    The ID of the associated category.
.PARAMETER StatusID
    The ID of the associated status.
.PARAMETER ProjectID
    The ID of the associated project.
.PARAMETER ResponsibleUID
    The UID of the responsible user.
.PARAMETER Attributes
    The custom attribute collection for the issue.
.PARAMETER NotifyOnClosed
    Switch indicating that the creator should be notified when the issue is
    closed.
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
    C:\>New-TDProjectIssue -PriorityID 5542 -Title "New issue" -CategoryID 10042 -StatusID 5577 -ProjectID 435278

    Creates a new project issue with specified parameters.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function New-TDProjectIssue
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        [Parameter(Mandatory=$true)]
        [String]
        $Title,

        [Parameter(Mandatory=$true)]
        [Int32]
        $PriorityID,

        [Parameter(Mandatory=$true)]
        [Int32]
        $CategoryID,

        [Parameter(Mandatory=$true)]
        [Int32]
        $StatusID,

        [Parameter(Mandatory=$false)]
        [String]
        $ResponsibleUID,

        [Parameter(Mandatory=$false)]
        [Double]
        $EstimatedHours,

        [Parameter(Mandatory=$false)]
        [DateTime]
        $StartDate,

        [Parameter(Mandatory=$false)]
        [DateTime]
        $EndDate,

        [Parameter(Mandatory=$false)]
        [Int32]
        $TaskID,

        [Parameter(Mandatory=$false)]
        [String]
        $Description,

        # The custom attribute collection for the issue.
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]
        $Attributes,

        # Notify creator when the risk is closed
        [Parameter(Mandatory=$false)]
        [Switch]
        $NotifyOnClosed,

        # Return newly created asset as an oject
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
        $LocalIgnoreParameters = @('NotifyOnClosed','Passthru')
    }
    Process
    {
        $NewIssue = [TeamDynamix_Api_Issues_Issue]::new()
        Update-Object -InputObject $NewIssue -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $NewIssueTD = [TD_TeamDynamix_Api_Issues_Issue]::new($NewIssue)
        if ($pscmdlet.ShouldProcess("title $Title on project $ProjectID", 'Add new issue'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/issues?NotifyOnClosed=$($NotifyOnClosed.IsPresent)" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewIssueTD -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Issues_Issue]::new($Return)
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
    Adds a comment to a project issue feed in TeamDynamix
.DESCRIPTION
    Adds a comment to a project issue feed in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the feed be updated.
.PARAMETER IssueID
    Risk ID number for the feed be updated.
.PARAMETER Comments
    Comment to be added to issue feed.
.PARAMETER Notify
    Email addresses of individuals to notify with the comment.
.PARAMETER IsPrivate
    Switch to indicate if the comment should be flagged as private. Default is
    "not private".
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDProjectIssue -ProjectID 1055 -IssueID 81109 -Comments "Updating is an issue."

    Adds the comment to the specified project issue.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Update-TDProjectIssue
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ProjectID,

        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $IssueID,

        # Comment to add to issue feed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
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
        $LocalIgnoreParameters = @('ProjectID','IssueID')
    }
    Process
    {
        $Update = [TeamDynamix_Api_Feed_FeedEntry]::new()
        Update-Object -InputObject $Update -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        Write-ActivityHistory "Updating feed for TeamDynamix project $ProjectID, risk $IssueID, with comment, $Comment."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/issues/$IssueID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Update -Depth 10)
        if ($Return)
        {
            return [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
        }
    }
}

<#
.Synopsis
    Get the feed for a project issue in TeamDynamix.
.DESCRIPTION
    Get the feed for a project issue in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project issue.
.PARAMETER IssueID
    Issue ID number for the project issue.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectIssueFeed -ProjectID 5591 -IssueID 38871

    Get the feed for the specified project issue.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectIssueFeed
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # Issue ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $IssueID,

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
        Write-ActivityHistory "Getting risk feed for project $ProjectID, issue $IssueID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/issues/$IssueID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Get issue statuses from TeamDynamix.
.DESCRIPTION
    Get issue statuses from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectIssueStatuses

    Get a list of issue statuses.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectIssueStatuses
{
    [CmdletBinding()]
    Param
    (
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
        Write-ActivityHistory "Getting issue statuses."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/issues/statuses" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Issues_IssueStatus]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Get the list of folders/files for a project in TeamDynamix.
.DESCRIPTION
    Get the list of folders, or list of files in a folder, for a project in
    TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project folders list.
.PARAMETER FolderID
    Folder ID number for the list of files in the project folder.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectFolder -ProjectID 5591

    Get the list of folders for the specified project.
.EXAMPLE
    C:\>Get-TDProjectFolder -ProjectID 5591 -Folder xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

    Get the list of files in the specified folder and project.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectFolder
{
    [CmdletBinding(DefaultParameterSetName='Folders')]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='Folders')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='Files')]
        [Int32]
        $ProjectID,

        # Folder ID number
        [Parameter(Mandatory=$true,
                   ParameterSetName='Files')]
        [guid]
        $FolderID,

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
        switch ($pscmdlet.ParameterSetName)
        {
            'Folders'
            {
                Write-ActivityHistory "Getting folders for project $ProjectID."
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/folders" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Briefcase_Folder]::new($_)})
                }
            }
            'Files'
            {
                Write-ActivityHistory "Getting files for project $ProjectID in folder $FolderID."
                $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/folders/$FolderID/files" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Briefcase_File]::new($_)})
                }
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Get a file for a project in TeamDynamix.
.DESCRIPTION
    Get a file for a project in TeamDynamix.
.PARAMETER ProjectID
    Project ID number for the project files list.
.PARAMETER FileID
    File ID number for the project files list.
.PARAMETER Content
    Retrieve the contents of the project file.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDProjectFile -ProjectID 5591 -FileID xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

    Get the specified file in the specified project.
.EXAMPLE
    C:\>Get-TDProjectFile -ProjectID 5591 -FileID xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -Content

    Get the contents of the specified file in the specified project.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDProjectFile
{
    [CmdletBinding()]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true)]
        [Int32]
        $ProjectID,

        # File ID number
        [Parameter(Mandatory=$true)]
        [guid]
        $FileID,

        # Retrieve file content
        [Parameter(Mandatory=$false)]
        [switch]
        $Content,

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
        if ($Content)
        {
            Write-ActivityHistory "Getting contents of file $FileID, for project $ProjectID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/files/$FileID/content" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        else
        {
            Write-ActivityHistory "Getting file information for $FileID, for project $ProjectID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/files/$FileID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            if ($Return)
            {
                $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Briefcase_File]::new($_)})
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Add a file to a project folder in TeamDynamix.
.DESCRIPTION
    Add a file to a project folder in TeamDynamix. Returns information
    regarding the file of the form TeamDynamix.Api.Briefcase.File.
.PARAMETER ProjectID
    ID number of the project the file will be added to in TeamDynamix.
.PARAMETER FolderID
    ID number of the project folder the file will be added to in TeamDynamix.
.PARAMETER FilePath
    The full path and filename of the file to be added as an attachment.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\> Add-TDProjectFile -ProjectID 111 -FolderID xxxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx -FilePath C:\temp\1.jpg

    Uploads the file c:\temp\1.jpg to the specified project and folder in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>function Add-TDProjectFile
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ProjectID,

        # Project ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $FolderID,

        # Full path and filename of attachment
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({Test-Path -PathType Leaf $_})]
        [string]
        $FilePath,

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
        $BoundaryText = [System.Guid]::NewGuid().ToString()
        $ContentType = "multipart/formdata; boundary=$BoundaryText"
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
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
        if ($pscmdlet.ShouldProcess("project $ProjectID, folder $FolderID, file name: $FileName", 'Upload file to'))
        {
            Write-ActivityHistory "Uploading $FileName to project $ProjectID, folder $FolderID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/folders/$FolderID/files" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                return [TeamDynamix_Api_Briefcase_File]::new($Return)
            }
        }
    }
}