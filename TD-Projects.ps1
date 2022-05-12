### Projects

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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

        # The ID of the associated service offering.
        [Parameter(Mandatory=$false)]
        [Int32]
        $ServiceOfferingID,

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting resources for project $ID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ID/resources" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Projects_Resource]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting resources for project $ProjectID, plan $PlanID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = [TeamDynamix_Api_Projects_Resource]::new($Return)
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting feed for project $ProjectID, plan $PlanID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting task feed for project $ProjectID, plan $PlanID, task $TaskID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/plans/$PlanID/tasks/$TaskID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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

        # The ID of the functional role to use when adding a time entry as part of the update.
        [Parameter(Mandatory=$false)]
        [Int32]
        $FunctionalRoleID,

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting risk statuses."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/risks/statuses" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Issues_IssueStatus]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting risk feed for project $ProjectID, risk $RiskID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/risks/$RiskID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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

        # The ID of the functional role associated with the time entry.
        [Parameter(Mandatory=$false)]
        [Int32]
        $FunctionalRoleID,

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting risk feed for project $ProjectID, issue $IssueID."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/$ProjectID/issues/$IssueID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
        Write-ActivityHistory "Getting issue statuses."
        $Return = Invoke-RESTCall -Uri "$BaseURI/projects/issues/statuses" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Issues_IssueStatus]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
function Add-TDProjectFile
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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBTQBw7dO5fdFMKC0kAVDoTSm
# d4OgggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDBg
# S/UzIR6A8kB5vCffNxSyc860MA0GCSqGSIb3DQEBAQUABIICAGKnz63VMbEPPcUo
# FIf0eoj7ke6HMrZC/Carmi4JwnQuUoY7oeUShpplLEdyQ2Oig5UVvgR9mOi8sSsL
# +FxcEQI4stlXuJzw5rIegsdw/W/LQY4NzXgD6ky5JV4YkrjZUMIAh45xa1Y5l4ii
# loYpYdZigZwFQMm870+b00Vh9wSqEM8cQ+/up274rB90bjMChVkX0kyV/EJ914dx
# ANOku8HPxPa1grd7VJuqc9Ir2drLbIHgxWMKmkrPUkZPLGNvf4E1JUZkWNs9d/zP
# Gyet8iwDda+U+m3jHNR1Ak6fh330xD0FNtiBlHiFxW/zF5CWt+IkLk0+/tVeQ7cL
# YjasrOHgpedqpYrQF7ITBUMYdJhvMzGAenx2FoGcl8arGLbThk2d5EPhiM0hmzov
# Z6Y4+j4EpYTBJa6t+RbutpbroTV0MAnxbSXf1oxMYVsiDHekVifMMef30q09lgcf
# /UuclDwVI0bQI44OzaODGgaXCtiE9Uw1swyxtWUaVmVdDRCf8pWDrA03ORbu3Mk1
# UyrDQELF/0tcI493TfG4eoa7d/VLJzyqynTxwyebt2NmGh8xTN6Bgw6cT6S/KP9E
# 1gAp1D7Y7hQlDOXashvllAXSQxxlOJrvqPR1T++Wf47MpYOgWZffYYzwGYKznb7i
# /tZwDDFj4+IYAo+E1LLiFhebl7Ni
# SIG # End signature block
