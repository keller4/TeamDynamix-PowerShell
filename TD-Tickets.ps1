### Tickets

function Get-TDTicket
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Ticket ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Search text
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [Parameter(Mandatory=$true,
                   ParameterSetName='EligibleAssignment')]
        [string]
        $SearchText,

        # Ticket classification type
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_Tickets_TicketClass]
        $TicketClassification = 9,

        # Number of tickets to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $MaxResults,

        # Parent ticket ID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ParentTicketID,

        # Status IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $StatusIDs,

        # Past status IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $PastStatusIDs,

        # Status class IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_Statuses_StatusClass[]]
        $StatusClassIDs,

        # Priority IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $PriorityIDs,

        # Urgency IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $UrgencyIDs,

        # Impact IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ImpactIDs,

        # Account/department IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $AccountIDs,

        # Ticket type IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $TypeIDs,

        # Ticket source IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $SourceIDs,

        # Return tickets with minimum age of update
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $UpdatedDateFrom,

        # Return tickets with maximum age of update
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $UpdatedDateTo,

        # Tickets ever updated by specific UID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $UpdatedByUid,

        # Return tickets with minimum age of last modification
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ModifiedDateFrom,

        # Return tickets with maximum age of last modification
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ModifiedDateTo,

        # Tickets last modified by specific UID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $ModifiedByUid,

        # Return ticket start of minimum age
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $StartDateFrom,

        # Return ticket start of maximum age
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $StartDateTo,

        # Return ticket end of minimum age
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $EndDateFrom,

        # Return ticket end of maximum age
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $EndDateTo,

        # Return tickets of minimum respoded date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $RespondedDateFrom,

        # Return tickets of maximum responded date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $RespondedDateTo,

        # Tickets responded-to by specific UID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $RespondedByUid,

        # Return tickets closed by minimum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ClosedDateFrom,

        # Return tickets closed by maximum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $ClosedDateTo,

        # Tickets closed by specific UID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $ClosedByUid,

        # Return tickets with minimum SLA respond-by date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $RespondByDateFrom,

        # Return tickets with maximum SLA respond-by date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $RespondByDateTo,

        # Return tickets with minimum SLA resolve-by date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $CloseByDateFrom,

        # Return tickets with maximum SLA resolve-by date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $CloseByDateTo,

        # Return tickets created by minimum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $CreatedDateFrom,

        # Return tickets created by maximum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [datetime]
        $CreatedDateTo,

        # Tickets created by specific UID to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $CreatedByUid,

        # Minimum age tickets to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $DaysOldFrom,

        # Maximum age tickets to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $DaysOldTo,

        # Responsibility UIDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $ResponsibilityUids,

        # Responsibility group IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ResponsibilityGroupIDs,

        # SLA IDs to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $SlaIDs,

        # SLA violation status
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $SlaViolationStatus,

        # SLA unmet deadlines
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_Tickets_UnmetConstraintSearchType]
        $SlaUnmetConstraints,

        # KB article IDs
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $KBArticleIDs,

        # Assignment status filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $AssignmentStatus,

        # Task conversion status
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $ConvertedToTask,

        # UID of the reviewing person
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[guid]]
        $ReviewerUid,

        # UID of the submitting person
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[guid]]
        $SubmitterUid,

        # UID of the submitting person or assigned person
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[guid]]
        $UserAccountsUid,

        # UID of responsible group
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[guid]]
        $UserGroupsUid,

        # UID of requestor
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $RequestorUids,

        # Name of requestor substring search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $RequestorNameSearch,

        # Email of requestor substring search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $RequestorEmailSearch,

        # Phone of requestor substring search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $RequestorPhoneSearch,

        # IDs of associated configuration items
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ConfigurationItemIDs,

        # IDs of associated configuration items to exclude
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ExcludeConfigurationItemIDs,

        # IDs of associated configuration items to exclude
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsOnHold,

        # Goes off hold at minimum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[datetime]]
        $GoesOffHoldFrom,

        # Goes off hold at maximum date
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[datetime]]
        $GoesOffHoldTo,

        # Location IDs
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $LocationIDs,

        # Location room IDs
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $LocationRoomIDs,

        # Modify location ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $LocationLike,

        # Modify location room ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $RoomLike,

        # Return only exact RoomLike and LocationLike matches
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $ExactLocation,

        # Associated service IDs
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int[]]
        $ServiceIDs,

        # Associated service IDs
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [array]
        $CustomAttributes,

        # Reference code
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $HasReferenceCode,

        # Retrieve full detail
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

        # Get list of eligible assignments for the ticketing application
        [Parameter(Mandatory=$true,
                   ParameterSetName='EligibleAssignment')]
        [switch]
        $EligibleAssignment,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                Name        = 'StatusNames'
                ValidateSet = $TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of statuses'
                IDParameter = 'StatusIDs'
                IDsMethod   = '$TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'StatusClassNames'
                ValidateSet = $TDTicketStatusClasses.Name
                HelpText    = 'Names of status classes'
                IDParameter = 'StatusClassIDs'
                IDsMethod   = '$TDTicketStatusClasses'
            }
            @{
                Name        = 'PastStatusNames'
                ValidateSet = $TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of past statuses'
                IDParameter = 'PastStatusIDs'
                IDsMethod   = '$TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'PriorityNames'
                ValidateSet = $TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of ticket priorities'
                IDParameter = 'PriorityIDs'
                IDsMethod   = '$TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'UrgencyNames'
                ValidateSet = $TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of ticket urgencies'
                IDParameter = 'UrgencyIDs'
                IDsMethod   = '$TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ImpactNames'
                ValidateSet = $TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of ticket impacts'
                IDParameter = 'ImpactIDs'
                IDsMethod   = '$TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AccountNames'
                ValidateSet = $TDAccounts.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of departments'
                IDParameter = 'AccountIDs'
                IDsMethod   = '$TDAccounts.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'TypeNames'
                ValidateSet = $TDTicketTypes.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of ticket types'
                IDParameter = 'TypeIDs'
                IDsMethod   = '$TDTicketTypes.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'SourceNames'
                ValidateSet = $TDTicketSources.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of ticket sources'
                IDParameter = 'SourceIDs'
                IDsMethod   = '$TDTicketSources.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ResponsibilityGroupNames'
                ValidateSet = $TDGroups.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Names of responsible groups'
                IDParameter = 'ResponsibilityGroupIDs'
                IDsMethod   = '$TDGroups.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        if (-not ($pscmdlet.ParameterSetName -eq 'EligibleAssignment'))
        {
            # Warn on invalid combinations
            if ($LocationIDs -and $LocationLike)
            {
                Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring LocationLike, using LocationIDs'
                $LocationLike = ''
            }
            if ($RoomIDs -and $RoomLike)
            {
                Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring RoomLike, using RoomIDs'
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
                    $Location = $TDBuildingsRooms.Get($LocationLike,$Environment)
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
                    TeamDynamix_Api_Locations_Location     {$LocationIDs     += $Location.ID}
                    TeamDynamix_Api_Locations_LocationRoom {$LocationRoomIDs += $Location.ID}
                }
            }

            $InvokeParams = [pscustomobject]@{
                # Configurable parameters
                SearchType       = 'TeamDynamix_Api_Tickets_TicketSearch'
                ReturnType       = 'TeamDynamix_Api_Tickets_Ticket'
                AllEndpoint      = $null
                SearchEndpoint   = '$AppID/tickets/search'
                IDEndpoint       = '$AppID/tickets/$ID'
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
                    $Return = $Return.ID | ForEach-Object {Get-TDTicket -ID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}
                }
            }
        }
        else
        {
            Write-ActivityHistory 'Retrieving TeamDynamix tickets eligible for assignment'
            $ContentType = 'application/json; charset=utf-8'
            $BaseURI = Get-URI -Environment $Environment
            if (-not $AuthenticationToken)
            {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
            }
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/resources?searchText=$SearchText" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            if ($Return)
            {
                $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_EligibleAssignment]::new($_)})
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketStatus
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Ticket status ID
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID',
                   Position=0)]
        [int]
        $ID,

        # Filter ticket status name, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter ticket status based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Filter ticket status based on whether it is the default status
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsDefault,

        # Filter ticket status based on status class
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_Statuses_StatusClass]
        $StatusClass,

        # Filter ticket status based on whether it requires the ticket to go off hold
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $RequiresGoesOffHold,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

        # Return only exact match to SearchText
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
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    Begin
    {
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {

        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Tickets_TicketStatusSearch'
            ReturnType       = 'TeamDynamix_Api_Tickets_TicketStatus'
            AllEndpoint      = '$AppID/tickets/statuses'
            SearchEndpoint   = '$AppID/tickets/statuses/search'
            IDEndpoint       = '$AppID/tickets/statuses/$ID'
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
            $Return = $Return | Where-Object Name -eq $SearchText
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function New-TDTicketStatus
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Name of the ticket status
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of the ticket status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Order of the ticket status when displayed in a list
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Order = 1,

        # Ticket status is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Ticket status class
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Statuses_StatusClass]
        $StatusClass,

        # Ticket requires a "Goes Off Hold" value
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $RequiresGoesOffHold,

        # Ticket is exempt from automatically updating based on "Reopening Completed/Cancelled Ticket Options" or "Completed Ticket Options"
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $DoNotReopen,

        # ID ticketing application
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
    }
    Process
    {
        $NewTicketStatus = [TeamDynamix_Api_Tickets_TicketStatus]::new()
        Update-Object -InputObject $NewTicketStatus -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($Name, 'Add new ticket status'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/statuses" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewTicketStatus -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Tickets_TicketStatus]::new($Return)
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

function Set-TDTicketStatus
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for ticket status
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Name of the ticket status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of the ticket status
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Order of the ticket status when displayed in a list
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Order,

        # Ticket status is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Ticket status class
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Statuses_StatusClass]
        $StatusClass,

        # Ticket requires a "Goes Off Hold" value
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $RequiresGoesOffHold,

        # Ticket is exempt from automatically updating based on "Reopening Completed/Cancelled Ticket Options" or "Completed Ticket Options"
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $DoNotReopen,

        # ID ticketing application
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $LocalIgnoreParameters = @('ID','AppID')
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
        # Retrieve existing ticket task
        try
        {
            $TicketStatus = Get-TDTicketStatus -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find ticket status ID, $ID"
        }
        # Update ticket task
        Update-Object -InputObject $TicketStatus -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($TicketStatus.Name, "Update ticket status"))
        {
            Write-ActivityHistory "Updating ticket status ID $ID, named $($TicketStatus.Name)."
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/statuses/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketStatus -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Tickets_TicketStatus]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
function Add-TDTicketAttachment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to add attachment in TeamDynamix
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

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("article ID: $ID, attachment name: $FileName", 'Add attachment to TeamDynamix ticket'))
        {
            Write-ActivityHistory "Adding $FileName attachment to ticket $ArticleID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/attachments" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Attachments_Attachment]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDTicket
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Ticket ID to modify in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Updated TypeID for ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TypeID,

        # Set form ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $FormID,

        # Updated title for ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        # Updated ticket description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Updated ticket department/account ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AccountID,

        # Updated source ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $SourceID,

        # Updated ticket status ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $StatusID,

        # Updated ticket impact ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ImpactID,

        # Updated urgency ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $UrgencyID,

        # Updated priority ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $PriorityID,

        # Set date ticket goes off hold
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $GoesOffHoldDate,

        # Updated requester UID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $RequestorUID,

        # Set estimated minutes to completion
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $EstimatedMinutes,

        # Set start date of ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $StartDate,

        # Set end date of ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # Updated UID of responsible person
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ResponsibleUID,

        # Updated ID of responsible group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ResponsibleGroupID,

        # Updated time budget
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $TimeBudget,

        # Updated expenses budget
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $ExpensesBudget,

        # Updated location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Updated location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Updated location name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationName,

        # Updated location room name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationRoomName,

        # Updated service ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ServiceID,

        # Updated service offering ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ServiceOfferingID,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Notify new responsible person/group (default false)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $NotifyNewResponsible = $false,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                Name        = 'StatusName'
                Type        = 'string'
                ValidateSet = $TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket status'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'PriorityName'
                Type        = 'string'
                ValidateSet = $TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket priority'
                IDParameter = 'PriorityID'
                IDsMethod   = '$TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'UrgencyName'
                Type        = 'string'
                ValidateSet = $TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket urgency'
                IDParameter = 'UrgencyID'
                IDsMethod   = '$TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ImpactNames'
                Type        = 'string'
                ValidateSet = $TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket impact'
                IDParameter = 'ImpactID'
                IDsMethod   = '$TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AccountName'
                Type        = 'string'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of department'
                IDParameter = 'AccountID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'TypeName'
                Type        = 'string'
                ValidateSet = $TDTicketTypes.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDTicketTypes.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'SourceName'
                Type        = 'string'
                ValidateSet = $TDTicketSources.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket source'
                IDParameter = 'SourceID'
                IDsMethod   = '$TDTicketSources.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ResponsibleGroupName'
                Type        = 'string'
                ValidateSet = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of responsible group'
                IDParameter = 'ResponsibleGroupID'
                IDsMethod   = '$TDGroups.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'FormName'
                Type        = 'string'
                ValidateSet = $TDForms.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

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
        #  Identify all parameters for command
        $CommandParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters

        #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class)
        $KeyTypeMembers = ([TeamDynamix_Api_Tickets_Ticket]::new() | Get-Member -MemberType Properties).Name
        $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
        $IgnoreParameters += $DynamicParameterDictionary.Values.Name
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
            # Re-call Set-TDTicket, this time with the LocationID and LocationRoomID instead of names
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
            #  Call Set-Ticket
            $Return = $RedoParametersObj | Set-TDTicket -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        # No location set by name
        else
        {
            #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

            try
            {
                $TDTicket = Get-TDTicket -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment
            }
            catch
            {
                Write-ActivityHistory -ErrorRecord $_ -ThrowError -ErrorMessage "Unable to find ticket $ID."
            }
            Update-Object -InputObject $TDTicket -ParameterList $CommandParameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($pscmdlet.ShouldProcess("Ticket ID: $ID", 'updating ticket'))
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$($ID)?notifyNewResponsible=$NotifyNewResponsible" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDTicket -Depth 10)
            }
            if ($Return)
            {
                $Return =  [TeamDynamix_Api_Tickets_Ticket]::new($Return)
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function New-TDTicket
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # TypeID for ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TypeID,

        # Title for ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        # Ticket department/account ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AccountID,

        # Ticket status ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $StatusID,

        # Priority ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $PriorityID,

        # Requester UID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $RequestorUID,

        # Set form ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $FormID,

        # Ticket description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

         # Source ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $SourceID,

        # Ticket impact ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ImpactID,

        # Urgency ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $UrgencyID,

        # Set date ticket goes off hold
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $GoesOffHoldDate,

        # Set estimated minutes to completion
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $EstimatedMinutes,

        # Set start date of ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $StartDate,

        # Set end date of ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # UID of responsible person
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ResponsibleUID,

        # ID of responsible group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ResponsibleGroupID,

        # Time budget
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $TimeBudget,

        # Expenses budget
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $ExpensesBudget,

        # Location ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Location room ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Location name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationName,

        # Location room name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LocationRoomName,

        # Service ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ServiceID,

        # Service offering ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ServiceOfferingID,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Notify responsible person/group (default false)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $NotifyResponsible = $false,

        # Notify reviewer (default false)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $EnableNotifyReviewer = $false,

        # Notify requestor (default false)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $NotifyRequestor = $false,

        # Requestor creation (default false)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $AllowRequestorCreation = $false,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                Name        = 'StatusName'
                Type        = 'string'
                ValidateSet = $TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket status'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'PriorityName'
                Type        = 'string'
                ValidateSet = $TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket priority'
                IDParameter = 'PriorityID'
                IDsMethod   = '$TDTicketPriorities.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'UrgencyName'
                Type        = 'string'
                ValidateSet = $TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket urgency'
                IDParameter = 'UrgencyID'
                IDsMethod   = '$TDTicketUrgencies.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ImpactNames'
                Type        = 'string'
                ValidateSet = $TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket impact'
                IDParameter = 'ImpactID'
                IDsMethod   = '$TDTicketImpacts.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AccountName'
                Type        = 'string'
                ValidateSet = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of department'
                IDParameter = 'AccountID'
                IDsMethod   = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'TypeName'
                Type        = 'string'
                ValidateSet = $TDTicketTypes.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDTicketTypes.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'SourceName'
                Type        = 'string'
                ValidateSet = $TDTicketSources.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket source'
                IDParameter = 'SourceID'
                IDsMethod   = '$TDTicketSources.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'ResponsibleGroupName'
                Type        = 'string'
                ValidateSet = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText    = 'Name of responsible group'
                IDParameter = 'ResponsibleGroupID'
                IDsMethod   = '$TDGroups.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name        = 'FormName'
                Type        = 'string'
                ValidateSet = $TDForms.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of ticket form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

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
        #  Identify all parameters for command
        $CommandParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters

        #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class)
        $KeyTypeMembers = ([TeamDynamix_Api_Tickets_Ticket]::new() | Get-Member -MemberType Properties).Name
        $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
        $IgnoreParameters += $DynamicParameterDictionary.Values.Name
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
            # Re-call New-TDTicket, this time with the LocationID and LocationRoomID instead of names
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
            #  Call New-TDTicket
            $Return = $RedoParametersObj | New-TDTicket -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        # No location set by name
        else
        {
            #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

            $TDTicket = [TeamDynamix_Api_Tickets_Ticket]::new()
            Update-Object -InputObject $TDTicket -ParameterList $CommandParameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($pscmdlet.ShouldProcess("Ticket Title: $Title", 'creating new ticket'))
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets?EnableNotifyReviewer=$EnableNotifyReviewer?NotifyRequestor=$NotifyRequestor?notifyResponsible=$NotifyResponsible?AllowRequestorCreation=$AllowRequestorCreation" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDTicket -Depth 10)
            }
            if ($Return)
            {
                $Return =  [TeamDynamix_Api_Tickets_Ticket]::new($Return)
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketType
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether type is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all TeamDynamix ticket types'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/types" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            return ($Return | ForEach-Object {[TeamDynamix_Api_Tickets_TicketType]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketSource
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether source is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all TeamDynamix ticket types'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/sources" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Tickets_TicketSource]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketImpact
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether impact is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all TeamDynamix ticket types'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/impacts" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_PriorityFactors_Impact]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketPriority
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether priority is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all TeamDynamix ticket types'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/priorities" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_PriorityFactors_Priority]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketUrgency
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether urgency is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all TeamDynamix ticket types'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/urgencies" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_PriorityFactors_Urgency]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketContact
{
    [CmdletBinding()]
    Param
    (
        # Ticket ID to retrieve contacts from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Include person responsible for the ticket
        [Parameter(Mandatory=$false)]
        [switch]
        $IncludeResponsible,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all contacts on a ticket'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/contacts" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_User]::new($_)})
        }
        if ($IncludeResponsible)
        {
            $ResponsibleEmail = (Get-TDTicket -ID $ID -AuthenticationToken $TDAuthentication -Environment $Environment).ResponsibleEmail
            if ($ResponsibleEmail)
            {
                $Return += Get-TDUser -Filter  $ResponsibleEmail -AuthenticationToken $TDAuthentication -Environment $Environment
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Remove-TDTicketContact
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to retrieve contacts from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # UID to remove from ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [guid]
        $UID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove UID: $UID", 'Remove contact from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting contact UID, $UID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/contacts/$UID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Add-TDTicketContact
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to retrieve contacts from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # UID to add to ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [guid]
        $UID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, add UID: $UID", 'Adding contact to TeamDynamix ticket'))
        {
            Write-ActivityHistory "Adding contact UID, $UID, to ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/contacts/$UID" -ContentType $ContentType -Method POST -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Update-TDTicket
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to update in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Ticket ID to update in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $NewStatusID,

        # Ticket ID to retrieve contacts from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Comments,

        # Users to notify about update
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [string[]]
        $Notify,

        # Set ticket to private if true, public if false
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [boolean]
        $IsPrivate = $true,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                Name        = 'NewStatusName'
                Type        = 'string'
                ValidateSet = $TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true).Name
                HelpText    = 'Name of new ticket status'
                IDParameter = 'NewStatusID'
                IDsMethod   = '$TDTicketStatuses.GetAll($TicketingAppID,$WorkingEnvironment,$true)'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

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
        #  Identify all parameters for command
        $CommandParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters

        #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class)
        $KeyTypeMembers = ([TeamDynamix_Api_Feed_TicketFeedEntry]::new() | Get-Member -MemberType Properties).Name
        $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
        $IgnoreParameters += $DynamicParameterDictionary.Values.Name

    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        $TicketUpdate = [TeamDynamix_Api_Feed_TicketFeedEntry]::new()
        Update-Object -InputObject $TicketUpdate -ParameterList $CommandParameters.Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, comment: $Comment", 'Updating TeamDynamix ticket'))
        {
            if ($Status)
            {
                $TicketUpdate.NewStatusID = ($TDTicketStatuses.GetAll($AppID,$Environment,$true) | Where-Object Name -eq $Status.Value).ID
            }
            else
            {
                $TicketUpdate.NewStatusID = $null
            }
            Write-ActivityHistory 'Updating ticket'
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/feed" -ContentType $ContentType -Method POST -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketUpdate -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
            }
        return $Return
        }
    }
    End
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDBlackoutWindow
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Blackout window ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter blackout window name text, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $NameLike,

        # Filter blackout window based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Set ID of application for blackout window
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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

    begin
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
        $LocalIgnoreParameters = @('ID','AppID','Exact')
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Search'
            {
                Write-ActivityHistory "Retrieving filtered list of blackout windows from TeamDynamix"
                if (($NameLike -eq '') -and ($IsActive -eq $true))
                {
                    $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/blackoutwindows" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    $Query = [TeamDynamix_Api_Cmdb_BlackoutWindowSearch]::new()
                    Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                    $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/blackoutwindows/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
                }
            }
            'ID'
            {
                Write-ActivityHistory "Retrieving a blackout window from TeamDynamix"
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/blackoutwindows/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Cmdb_BlackoutWindow]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function New-TDBlackoutWindow
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Name for blackout window
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # ID number of time zone
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TimeZoneID,

        # Filter blackout window based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Set ID of application for blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

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
        #  Identify all parameters for command
        $CommandParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters

        #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class), also include dynamic parameters
        $KeyTypeMembers = ([TeamDynamix_Api_Cmdb_BlackoutWindow]::new() | Get-Member -MemberType Properties).Name
        $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
        $IgnoreParameters += $DynamicParameterDictionary.Values.Name
    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        $NewBlackoutWindow = [TeamDynamix_Api_Cmdb_BlackoutWindow]::new()
        Update-Object -InputObject $NewBlackoutWindow -ParameterList $CommandParameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($Name, 'Add new blackout window'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/blackoutwindows" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewBlackoutWindow -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Cmdb_BlackoutWindow]::new($Return)
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

function Set-TDBlackoutWindow
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # ID for blackout window
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Name for blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Time zone ID for blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $TimeZoneID,

        # Set blackout window to be active or inactive
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Set ID of application for blackout window
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
                ValidateSet = $TDApplications.GetByAppClass('TDTickets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll([string]$Environment,$true)'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

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
        #  Identify all parameters for command
        $CommandParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters

        #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class), also include dynamic parameters
        $KeyTypeMembers = ([TeamDynamix_Api_Cmdb_BlackoutWindow]::new() | Get-Member -MemberType Properties).Name
        $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
        $IgnoreParameters += $DynamicParameterDictionary.Values.Name
    }
    Process
    {
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        # Retrieve existing blackout window
        try
        {
            $BlackoutWindow = Get-TDBlackoutWindow -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find blackout window ID, $ID"
        }
        # Update blackout window
        Update-Object -InputObject $BlackoutWindow -ParameterList $CommandParameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($BlackoutWindow.Name, "Update blackout window"))
        {
            Write-ActivityHistory "Updating blackout window ID $ID, named $($BlackoutWindow.Name)."
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/blackoutwindows/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $BlackoutWindow -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Cmdb_BlackoutWindow]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketAsset
{
    [CmdletBinding()]
    Param
    (
        # Ticket ID to retrieve assets from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving all assets on a ticket'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Cmdb_ConfigurationItem]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Remove-TDTicketAsset
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to remove asset from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Asset ID to remove from ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $AssetID,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove asset ID: $AssetID", 'Remove asset from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting asset ID, $AssetID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets/$AssetID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Add-TDTicketAsset
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to retrieve contacts from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Asset ID to add to ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $AssetID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, add asset ID: $AssetID", 'Adding contact to TeamDynamix ticket'))
        {
            Write-ActivityHistory "Adding asset ID, $AssetID, to ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets/$AssetID" -ContentType $ContentType -Method POST -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketTask
{
    [CmdletBinding(DefaultParameterSetName='AllTasks')]
    Param
    (
        # Ticket ID to retrieve tasks from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='AllTasks')]
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='SingleTask')]
        [int]
        $ID,

        # Ticket ID to retrieve tasks from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='SingleTask')]
        [int]
        $TaskID,

        # Filter tasks that can be assigned as a predecessor
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='AllTasks')]
        [System.Nullable[boolean]]
        $IsEligiblePredecessor = $null,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
            'AllTasks'
            {
                Write-ActivityHistory 'Retrieving all tasks on a ticket'
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks?isEligiblePredecessor=$IsEligiblePredecessor" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'SingleTask'
            {
                Write-ActivityHistory 'Retrieving a specific task on a ticket'
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Tickets_TicketTask]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketTaskFeed
{
    [CmdletBinding()]
    Param
    (
        # Ticket ID to retrieve tasks from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Ticket ID to retrieve tasks from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $TaskID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        Write-ActivityHistory 'Retrieving specific task feed on a ticket'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskId/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
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

function Remove-TDTicketTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID to remove task from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Task ID to remove from ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $TaskID,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove task ID: $TaskID", 'Remove task from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting task ID, $TaskID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function New-TDTicketTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID for task in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Title of task to add to ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $Title,

        # Description of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Start date of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $StartDate,

        # Title of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # Expected duration of task, in minutes, to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [system.nullable[int]]
        $CompleteWithinMinutes,

        # Estimated elapsed time, in minutes, for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $EstimatedMinutes = 0,

        # UID for user responsible for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $ResponsibleUID,

        # ID of group resonsible for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ResponsibleGroupID,

        # ID of predecessor of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $PredecessorID,

        # ID of predecessor of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Tickets_TicketTaskType]
        $TypeID = 1,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $LocalIgnoreParameters = @('ID','AppID')
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, add task title: $Title", 'Adding task to TeamDynamix ticket'))
        {
            $NewTicketTask = [TeamDynamix_Api_Tickets_TicketTask]::new()
            Update-Object -InputObject $NewTicketTask -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
            # Reformat object for upload to TD, include proper date format
            $NewTicketTaskTD = [TD_TeamDynamix_Api_Tickets_TicketTask]::new($NewTicketTask)
            if ($pscmdlet.ShouldProcess($Name, 'Add new ticket task'))
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewTicketTaskTD -Depth 10)
                if ($Return)
                {
                    $Return = [TeamDynamix_Api_Tickets_TicketTask]::new($Return)
                }
                Write-ActivityHistory ($Return | Out-String)
                if ($Passthru)
                {
                    Write-Output $Return
                }
            }
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDTicketTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID for task in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Task ID to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $TaskID,

        # Title of task to add to ticket
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        # Description of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Start date of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $StartDate,

        # Title of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # Expected duration of task, in minutes, to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [system.nullable[int]]
        $CompleteWithinMinutes,

        # Estimated elapsed time, in minutes, for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $EstimatedMinutes,

        # UID for user responsible for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $ResponsibleUID,

        # ID of group resonsible for task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ResponsibleGroupID,

        # ID of predecessor of task to add to ticket
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $PredecessorID,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $LocalIgnoreParameters = @('ID','TaskID','AppID')
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
        # Retrieve existing ticket task
        try
        {
            $TicketTask = Get-TDTicketTask -ID $ID -TaskID $TaskID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find ticket task ID $TaskID, for ticket ID $ID"
        }
        # Update ticket task
        Update-Object -InputObject $TicketTask -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $TicketTaskTD = [TD_TeamDynamix_Api_Tickets_TicketTask]::new($TicketTask)
        if ($pscmdlet.ShouldProcess($TicketTask.Title, "Modify ticket task"))
        {
            Write-ActivityHistory "Modifying ticket task ID $TaskId on ticket ID $ID, named $($TicketStatus.Name)."
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketTaskTD -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Tickets_TicketTask]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Update-TDTicketTask
{
    [CmdletBinding(DefaultParameterSetName='Comment',
                   SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID for task in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Task ID to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int]
        $TaskID,

        # Percentage compete
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Percent')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Comment')]
        [System.Nullable[int]]
        $PercentComplete,

        # Comments for task feed
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Comment')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Percent')]
        [string]
        $Comments,

        # Email addresses to notify
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Notify,

        # Indicates whether feed entry is private
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $IsPrivate,

        # Set ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $LocalIgnoreParameters = @('ID','TaskID','AppID')
    }
    Process
    {
        $TicketTask = [TeamDynamix_Api_Feed_TicketTaskFeedEntry]::new()
        # Update ticket task
        Update-Object -InputObject $TicketTask -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("ID $ID, Task ID $TaskID", "Update ticket task status"))
        {
            Write-ActivityHistory "Updating status of ticket task ID $TaskId on ticket ID $ID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskID/feed" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketTask -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Feed_ItemUpdate]::new($Return)
            }
            return $Return
        }
    }
}

function Get-TDTicketWorkflow
{
    [CmdletBinding()]
    Param
    (
        # Ticket ID to retrieve workflow from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/workflow" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = [TeamDynamix_Api_Tickets_TicketWorkflow]::new($Return)
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDTicketWorkflowActions
{
    [CmdletBinding()]
    Param
    (
        # Ticket ID to retrieve workflow from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Workflow step ID to retrieve actions from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [guid]
        $StepID,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/workflow/actions?stepId=$StepID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Approve-TDTicketWorkflowStep
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Step ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $StepID,

        # Approval action
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ActionID,

        # Comments
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Comments,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $TicketWorkflowStepApproveRequest = [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest]::new($StepID, $ActionID, $Comments)
        if ($pscmdlet.ShouldProcess("Ticket ID $ID, workflow step ID $StepID, approval $ActionID", "Perform selected action on workflow step on ticket"))
        {
            Write-ActivityHistory "Performing action $ActionID for workflow step ID $StepID on ticket ID $ID."
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/workflow/approve" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketWorkflowStepApproveRequest -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDTicketWorkflowStepAssignment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Step ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $StepID,

        # User ID to be assigned to the workflow step
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[guid]]
        $UserID = [guid]::Empty,

        # Group ID to be assigned to the workflow step
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $GroupID = $null,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        $TicketWorkflowStepReassignRequest = [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest]::new($StepID, $UserID, $GroupID)
        if ($pscmdlet.ShouldProcess("Ticket ID $ID, step ID, $StepID, user ID $UserID, group $GroupID", "Assign ticket workflow to user/group"))
        {
            Write-ActivityHistory "Assigning ticket $ID, workflow step ID $StepID, to user $UserID or group $GroupID."
            Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/workflow/reassign" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TicketWorkflowStepReassignRequest -Depth 10) | Out-Null
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDTicketWorkflow
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Ticket ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Workflow ID to assign
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $NewWorkflowID,

        # Remove existing workflow
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $AllowRemoveExisting,

        # ID of application for ticketing app
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID = $TicketingAppID,

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
        if ($pscmdlet.ShouldProcess("Ticket ID $ID, workflow ID $NewWorkflowID, remove existing workflow $AllowRemoveExisting", "Assign workflow to ticket"))
        {
            Write-ActivityHistory "Assign workflow $NewWorkflowID to ticket ID $ID. Remove existing workflow, $AllowRemoveExisting"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/workflow?newWorkflowId=$NewWorkflowId&allowRemoveExisting=$($AllowRemoveExisting.IsPresent)" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Tickets_Ticket]::new($Return)
            }
            return $Return
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+3KgSkv3nT2nPPSYnrh91/l/
# eMegggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFPxD
# ieyg/VF855dp1iLnKZMlTV9xMA0GCSqGSIb3DQEBAQUABIICAKmD/8LdY4BA6VOX
# HLOhq/MNP6pyg1dQp2l2z6gKjOlLtufzHfxb5wUSrhFbMpQ96KIk+94PCY/d8sXO
# zmrlAMhh/e/YTebr+e+XXfZzDIk3q+XLt7oUhUx9/KxTOV4diL9F4vrtTp73YzSH
# eBJAFadg39DH+Ti/1B5q0hcntP7xT8dM0BEccaJe8DtDVLOytHokcZ+ceJ/6U7y4
# qWlpMJrYHVb1b+OrME2nps6lYFQ5RIhkE8zQ2oLzCpAhxuAt+GQU5CsXXT94BmZk
# VZpY7EP4frZ3yX9IrinMYAjuw3YX782Fc6SFekxKZa3vFKqT9hysvg8yxQhleRws
# W3sCdZbi+sLd0NLw27klyc8+t4niqHF6vX/Vdp+mQGU2PrvJGW9AemQnyu/N7Vt0
# mlfD+Gi+LvV84Vcs7R2lwGZ36mzy80B3HKZO2xtbUXj2vTAe5At29SAIMoC7KR+Q
# 9yumRu39A/yErHzpvwVNLPBBwAYFE2OJMvMnpU+/fSWh4wPP1WzCcSrINPNt7MKl
# Ip+JuCy3g14osHfk7G1Mnsi1onkPTKOBkLZ2lG/DPBVnVoPnXJzORNJn8Ak/Ep6P
# kQii1/lgUsG/05VlV3bcNiOkF7WZYmqxGyvw8/6q6XGF8Ke1pndApxGkhZO7jltF
# 4DfAf2wo2QAceXN+r2t2qkfDs7QN
# SIG # End signature block
