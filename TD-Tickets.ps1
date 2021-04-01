### Tickets

<#
.Synopsis
    Get a ticket in TeamDynamix
.DESCRIPTION
    Get a ticket in TeamDynamix. Specify the ticket ID number
    or search using the text of the article, status,
    responsible person's UID, and the parent ticket ID.
.PARAMETER ID
    Ticket ID to retrieve from TeamDynamix. Use "*" to retrieve all articles.
.PARAMETER SearchText
    Text to search for in tickets.
.PARAMETER TicketClassificiation
    Classification type for tickets to search for.
.PARAMETER ParentTicketID
    Search for tickets with specified parent ID.
.PARAMETER StatusIDs
    Retrieve only tickets with specified status ID.
.PARAMETER PastStatusIDs
    Retrieve tickets with specified past status IDs.
.PARAMETER StatusClassIDs
    Retrieve only tickets with the specified status class IDs.
.PARAMETER PriorityIDs
    Retrieve only tickets with the specified priority IDs.
.PARAMETER UrgencyIDs
    Retrieve only tickets with the specified urgency IDs.
.PARAMETER ImpactIDs
    Retrieve only tickets with the specified impact IDs.
.PARAMETER AccountIDs
    Retrieve only tickets with the specified acccount (department) IDs.
.PARAMETER TypeIDs
    Retrieve only tickets with the specified type IDs.
.PARAMETER SourceIDs
    Retrieve only tickets with the specified source IDs.
.PARAMETER UpdatedDateFrom
    Retrieve only tickets updated more recently than the specified date.
.PARAMETER UpdatedDateTo
    Retrieve only tickets updated before the specified date.
.PARAMETER UpdatedByUid
    Retrieve only tickets updated by the user with the specified UID.
.PARAMETER ModifiedDateFrom
    Retrieve only tickets modified more recently than the specified date.
.PARAMETER ModifiedDateTo
    Retrieve only tickets modified before the specified date.
.PARAMETER ModifiedByUid
    Retrieve only tickets modified by the user with the specified UID.
.PARAMETER StartDateFrom
    Retrieve only tickets whose start date is after the specified date.
.PARAMETER StartDateTo
    Retrieve only tickets whose start date is before the specified date
.PARAMETER EndDateFrom
    Retrieve only tickets whose end date is after the specified date.
.PARAMETER EndDateTo
    Retrieve only tickets whose end date is before the specified date.
.PARAMETER RespondedDateFrom
    Retrieve only tickets whose responded date is after the specified date.
.PARAMETER RespondedDateTo
    Retrieve only tickets whose responded date is before the specified date.
.PARAMETER RespondedByUid
    Retrieve only tickets where the responding user has the specified UID.
.PARAMETER ClosedDateFrom
    Retrieve only tickets whose closed date is after the specified date.
.PARAMETER ClosedDateTo
    Retrieve only tickets whose closed date is before the specified date.
.PARAMETER ClosedByUid
    Retrieve only tickets closed by the user with the specified UID.
.PARAMETER RespondByDateFrom
    Retrieve only tickets whose respond by date is after the specified date.
.PARAMETER RespondByDateTo
    Retrieve only tickets whose respond by date is before the specified date.
.PARAMETER CloseByDateFrom
    Retrieve only tickets whose close by date is after the specified date.
.PARAMETER CloseByDateTo
    Retrieve only tickets whose close by date is before the specified date.
.PARAMETER CreatedDateFrom
    Retrieve only tickets whose created date is after the specified date.
.PARAMETER CreatedDateTo
    Retrieve only tickets whose created date is before the specified date.
.PARAMETER CreatedByUid
    Retrieve only tickets created by the user with the specified UID.
.PARAMETER DaysOldFrom
    Retrieve only tickets whose age is more than the specified number of days.
.PARAMETER DaysOldTo
    Retrieve only tickets whose age is less than the specified number of days.
.PARAMETER ResponsibilityUids
    Retrieve only tickets for the specified UID of the responsible user.
.PARAMETER SlaIDs
    Retrieve only tickets with the specified Service Level Agreement IDs.
.PARAMETER SlaViolationStatus
    Retrieve only tickets with the specified Service Level Agreement violation
    status.
.PARAMETER SlaUnmetConstraints
    Retrieve only tickets with the specified Service Level Agreement unmet
    constraints.
.PARAMETER KBArticleIDs
    Retrieve only tickets with the specified Knowledge Base article IDs.
.PARAMETER AssignmentStatus
    Retrieve only tickets with the specified assignment status
.PARAMETER ConvertedToTask
    Retrieve only tickets that have been converted to tasks.
.PARAMETER ReviewerUid
    Retrieve only tickets reviewed by the user with the specified UID.
.PARAMETER SubmitterUid
    Retrieve only tickets submitted by the user with the specified UID.
.PARAMETER UserAccountsUid
    Retrieve only tickets from users in the specified department UID.
.PARAMETER UserGroupsUid
    Retrieve only tickets from users in the specified group UID.
.PARAMETER UserGroupName
    Retrieve only tickets from users the specified group name.
.PARAMETER RequestorUids
    Retrieve only tickets requested by users with the specified UIDs.
.PARAMETER RequestorNameSearch
    Retrieve only tickets requested by users with the specified names.
.PARAMETER RequestorEmailSearch
    Retrieve only tickets requested by users with the specified email address.
.PARAMETER RequestorPhoneSearch
    Retrieve only tickets requested by users with the specified phone number.
.PARAMETER ConfigurationItemIDs
    Retrieve only tickets with the specified Configuration Item IDs.
.PARAMETER ExcludeConfigurationItemIDs
    Do not retrieve any tickets with the specified Configuration Item IDs.
.PARAMETER IsOnHold
    Retrieve only tickets on hold.
.PARAMETER GoesOffHoldFrom
    Retrieve only tickets that go off hold after the specified date.
.PARAMETER GoesOffHoldTo
    Retrieve only tickets that go off hold before the specified date.
.PARAMETER LocationIDs
    Retrieve only tickets with the specified building IDs.
.PARAMETER LocationRoomIDs
    Retrieve only tickets with the specified room IDs.
.PARAMETER ServiceIDs
    Retrieve only tickets with the specified service IDs.
.PARAMETER CustomAttributes
    Retrieve only tickets with the specified custom attributes.
.PARAMETER HasReferenceCode
    Retrieve only tickets with a reference code.
.PARAMETER MaxResults
    Maximum number of tickets to return. Default 50.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER EligibleAssignment
    Retrieve names of resources eligible for assignment for the ticketing
    application.
.PARAMETER Detail
    Return full detail for ticket. Default searches return partial detail.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicket -AuthenticationToken $Authentication

    Retrieves all tickets from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicket -TicketID 1752 -AuthenticationToken $Authentication

    Retrieves ticket number 1752 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicket -SearchText vpn -AuthenticationToken $Authentication

    Retrieves first 50 tickets containing the text "vpn" from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicket -SearchText smith -EligibleAssignment -AuthenticationToken $Authentication

    Retrieves up to five resources named smith eligible for assignment for the
    ticketing application.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDTicketStatuses.Name
                HelpText    = 'Names of statuses'
                IDParameter = 'StatusIDs'
                IDsMethod   = '$TDApplications'
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
                ValidateSet = $TDTicketStatuses.Name
                HelpText    = 'Names of past statuses'
                IDParameter = 'PastStatusIDs'
                IDsMethod   = '$TDTicketStatuses'
            }
            @{
                Name        = 'PriorityNames'
                ValidateSet = $TDTicketPriorities.Name
                HelpText    = 'Names of ticket priorities'
                IDParameter = 'PriorityIDs'
                IDsMethod   = '$TDTicketPriorities'
            }
            @{
                Name        = 'UrgencyNames'
                ValidateSet = $TDTicketUrgencies.Name
                HelpText    = 'Names of ticket urgencies'
                IDParameter = 'UrgencyIDs'
                IDsMethod   = '$TDTicketUrgencies'
            }
            @{
                Name        = 'ImpactNames'
                ValidateSet = $TDTicketImpacts.Name
                HelpText    = 'Names of ticket impacts'
                IDParameter = 'ImpactIDs'
                IDsMethod   = '$TDTicketImpacts'
            }
            @{
                Name        = 'AccountNames'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Names of departments'
                IDParameter = 'AccountIDs'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'TypeNames'
                ValidateSet = $TDTicketTypes.Name
                HelpText    = 'Names of ticket types'
                IDParameter = 'TypeIDs'
                IDsMethod   = '$TDTicketTypes'
            }
            @{
                Name        = 'SourceNames'
                ValidateSet = $TDTicketSources.Name
                HelpText    = 'Names of ticket sources'
                IDParameter = 'SourceIDs'
                IDsMethod   = '$TDTicketSources'
            }
            @{
                Name        = 'ResponsibilityGroupNames'
                ValidateSet = $TDGroups.Name
                HelpText    = 'Names of responsible groups'
                IDParameter = 'ResponsibilityGroupIDs'
                IDsMethod   = '$TDGroups'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
                    $Location = Get-TDLocation -NameLike $LocationLike -RoomLike $RoomLike -Exact:$ExactLocation -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                        $Location = Get-TDLocation -ID $LocationIDs[0] -RoomLike $RoomLike -Exact:$ExactLocation -AuthenticationToken $AuthenticationToken -Environment $Environment
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
                SearchEndpoint   = "$AppID/tickets/search"
                IDEndpoint       = "$AppID/tickets/$ID"
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
}

<#
.Synopsis
    Get list of ticket statuses from TeamDynamix
.DESCRIPTION
    Get list of ticket statuses from TeamDynamix. Returns list of active ticket
    statuses by default.
.PARAMETER ID
    ID of ticket status type to get.
.PARAMETER Filter
    Substring description search filter.
.PARAMETER IsActive
    Boolean to limit return set to active ticket statuses ($true), inactive
    ticket statuses ($false), or all ($null). Default: $true.
.PARAMETER IsDefault
    Boolean to limit return set to default ticket status ($true), non-default
    ticket statuses ($false). or all ($null).
.PARAMETER StatusClass
    Filter return set to specified status class name.
.PARAMETER RequiresGoesOffHold
    Boolean to limit return set to ticket statuses requiring ticket to go off
    hold ($true), ticket statuses that do not require the ticket to go off hold
    ($false). or all ($null).
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketStatus -AuthenticationToken $Authentication

    Retrieves list of all ticket statuses from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketStatus
{
    [CmdletBinding(DefaultParameterSetName='Filter')]
    Param
    (
        # Ticket status ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter ticket status name, substring
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Filter ticket status based on whether it is active or inactive
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Filter ticket status based on whether it is the default status
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [System.Nullable[boolean]]
        $IsDefault,

        # Filter ticket status based on status class
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [TeamDynamix_Api_Statuses_StatusClass]
        $StatusClass,

        # Filter ticket status based on whether it requires the ticket to go off hold
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [System.Nullable[boolean]]
        $RequiresGoesOffHold,

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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
        switch ($PSCmdlet.ParameterSetName)
        {
            'Filter'
            {
                Write-ActivityHistory "Retrieving filtered list ticket statuses from TeamDynamix"
                if (($SearchText -eq '') -and ($IsActive -eq $true))
                {
                    $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/statuses" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    $Query = [TeamDynamix_Api_Tickets_TicketStatusSearch]::new()
                    Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                    $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/statuses/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
                }
            }
            'ID'
            {
                Write-ActivityHistory "Retrieving a ticket status from TeamDynamix"
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/statuses/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Tickets_TicketStatus]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Create a new ticket status in TeamDynamix
.DESCRIPTION
    Creates a new ticket status in TeamDynamix.
.PARAMETER Name
    Name of the ticket status.
.PARAMETER Description
    Description of ticket status.
.PARAMETER Order
    The order of the ticket status when displayed in a list (default 1.0).
.PARAMETER StatusClass
    Status class name of the ticket status.
.PARAMETER IsActive
    Set whether ticket status is active or not. Default: true.
.PARAMETER AppID
    Application ID for the ticketing application.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDTicketStatus -Name 'Slow Test' -Description 'Test status for slow items' -Order 1 -StatusClass 'New' -AuthenticationToken $Authentication

   Creates a new active ticket status.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Modify a ticket status in TeamDynamix
.DESCRIPTION
    Modify ticket status in TeamDynamix.
.PARAMETER ID
    ID of the ticket status to be modified.
.PARAMETER Name
    Name of the ticket status.
.PARAMETER Description
    Description of ticket status.
.PARAMETER Order
    The order of the ticket status when displayed in a list (default 1.0).
.PARAMETER StatusClass
    Status class name of the ticket status.
.PARAMETER IsActive
    Set whether ticket status is active or not. Default: true.
.PARAMETER AppID
    Application ID for the ticketing application.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Set-TDTicketStatus -ID 87775 -Name 'Slow Test' -Description 'Test status for slow items' -Order 1 -StatusClass 'New' -AuthenticationToken $Authentication

   Modifies ticket status with ID 87775.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
}

<#
.Synopsis
    Add a file attachment to a ticket in TeamDynamix
.DESCRIPTION
    Add a file attachment to a ticket in TeamDynamix. Returns
    information regarding the attachment of the form
    TeamDynamix.Api.Attachments.Attachment.
.PARAMETER ID
    ID number of the ticket the attachment will be added to in TeamDynamix.
.PARAMETER FilePath
    The full path and filename of the file to be added as an attachment.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\> Add-TDTicketAttachment -ID 111 -FilePath C:\temp\1.jpg -AuthenticationToken $Authentication

    Attaches the file c:\temp\1.jpg to ticket ID 111 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>function Add-TDTicketAttachment
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
}

<#
.Synopsis
    Modifies a ticket in TeamDynamix
.DESCRIPTION
    Modifies a ticket in TeamDynamix. Also accepts an object
    on the pipeline that contains all the ticket information.
.PARAMETER ID
    Ticket ID to modify in TeamDynamix.
.PARAMETER TypeID
    Ticket type ID.
.PARAMETER FormID
    Form type ID. Use "0" to apply the default form for the classification.
.PARAMETER Title
    Ticket title.
.PARAMETER Description
    Ticket description.
.PARAMETER AccountID
    Department ID assigned to the ticket.
.PARAMETER SourceID
    Ticket source ID.
.PARAMETER StatusID
    Ticket status ID.
.PARAMETER ImpactID
    Ticket impact ID.
.PARAMETER UrgencyID
    Ticket urgency ID.
.PARAMETER PriorityID
    Ticket priority ID.
.PARAMETER GoesOffHoldDate
    Date ticket goes off hold.
.PARAMETER RequestorUID
    ID of ticket requestor.
.PARAMETER EstimatedMinutes
    Estimated minutes to completion of the ticket.
.PARAMETER StartDate
    Ticket start date.
.PARAMETER EndDate
    Ticket end date.
.PARAMETER ResponsibleUID
    UID of person responsible for ticket.
.PARAMETER ResponsibleGroupID
    UID of group responsible for ticket.
.PARAMETER TimeBudget
    Time budget for ticket.
.PARAMETER ExpensesBudget
    Expenses budget for ticket.
.PARAMETER LocationID
    ID of building for ticket.
.PARAMETER LocationRoomID
    ID of room for ticket.
.PARAMETER LocationName
    Location name for ticket in TeamDynamix.
.PARAMETER LocationRoomName
    Room name for ticket in TeamDynamix.
.PARAMETER ServiceID
    ID of associated service.
.PARAMETER Attributes
    Custom attributes.
.PARAMETER NotifyNewResponsible
    Boolean to determine if the responsible resource is notified of the change.
    $true indicates they will be notified, $false indicates no notification.
    Default is no notification.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDTicket -ID 9934 -Description 'Test ticket' -AuthenticationToken $Authentication

    Modifies description of ticket ID 9934 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDTicketStatuses.Name
                HelpText    = 'Name of ticket status'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDTicketStatuses'
            }
            @{
                Name        = 'PriorityName'
                Type        = 'string'
                ValidateSet = $TDTicketPriorities.Name
                HelpText    = 'Name of ticket priority'
                IDParameter = 'PriorityID'
                IDsMethod   = '$TDTicketPriorities'
            }
            @{
                Name        = 'UrgencyName'
                Type        = 'string'
                ValidateSet = $TDTicketUrgencies.Name
                HelpText    = 'Name of ticket urgency'
                IDParameter = 'UrgencyID'
                IDsMethod   = '$TDTicketUrgencies'
            }
            @{
                Name        = 'ImpactNames'
                Type        = 'string'
                ValidateSet = $TDTicketImpacts.Name
                HelpText    = 'Name of ticket impact'
                IDParameter = 'ImpactID'
                IDsMethod   = '$TDTicketImpacts'
            }
            @{
                Name        = 'AccountName'
                Type        = 'string'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Name of department'
                IDParameter = 'AccountID'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'TypeName'
                Type        = 'string'
                ValidateSet = $TDTicketTypes.Name
                HelpText    = 'Name of ticket type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDTicketTypes'
            }
            @{
                Name        = 'SourceName'
                Type        = 'string'
                ValidateSet = $TDTicketSources.Name
                HelpText    = 'Name of ticket source'
                IDParameter = 'SourceID'
                IDsMethod   = '$TDTicketSources'
            }
            @{
                Name        = 'ResponsibleGroupName'
                Type        = 'string'
                ValidateSet = $TDGroups.Name
                HelpText    = 'Name of responsible group'
                IDParameter = 'ResponsibleGroupID'
                IDsMethod   = '$TDGroups'
            }
            @{
                Name        = 'FormName'
                Type        = 'string'
                ValidateSet = $TDForms.Name
                HelpText    = 'Name of ticket form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Creates a ticket in TeamDynamix
.DESCRIPTION
    Creates a ticket in TeamDynamix. Also accepts an object
    on the pipeline that contains all the ticket information.
.PARAMETER TypeID
    Ticket type ID.
.PARAMETER FormID
    Form type ID. Use "0" to apply the default form for the classification.
.PARAMETER Title
    Ticket title.
.PARAMETER Description
    Ticket description.
.PARAMETER AccountID
    Department ID assigned to the ticket.
.PARAMETER SourceID
    Ticket source ID.
.PARAMETER StatusID
    Ticket status ID.
.PARAMETER ImpactID
    Ticket impact ID.
.PARAMETER UrgencyID
    Ticket urgency ID.
.PARAMETER PriorityID
    Ticket priority ID.
.PARAMETER GoesOffHoldDate
    Date ticket goes off hold.
.PARAMETER RequestorUID
    ID of ticket requestor.
.PARAMETER EstimatedMinutes
    Estimated minutes to completion of the ticket.
.PARAMETER StartDate
    Ticket start date.
.PARAMETER EndDate
    Ticket end date.
.PARAMETER ResponsibleUID
    UID of person responsible for ticket.
.PARAMETER ResponsibleGroupID
    UID of group responsible for ticket.
.PARAMETER TimeBudget
    Time budget for ticket.
.PARAMETER ExpensesBudget
    Expenses budget for ticket.
.PARAMETER LocationID
    ID of building for ticket.
.PARAMETER LocationRoomID
    ID of room for ticket.
.PARAMETER LocationName
    Location name for ticket.
.PARAMETER LocationRoomName
    Room name for ticket.
.PARAMETER ServiceID
    ID of associated service.
.PARAMETER Attributes
    Custom attributes.
.PARAMETER NotifyResponsible
    Boolean to determine if the responsible resource is notified of the ticket.
    $true indicates they will be notified, $false indicates no notification.
    Default is no notification.
.PARAMETER EnableNotifyReviewer
    Boolean to determine if the reviewer is notified of the ticket.
    $true indicates they will be notified, $false indicates no notification.
    Default is no notification.
.PARAMETER NotifyRequestor
    Boolean to determine if the requestor is notified of the ticket.
    $true indicates they will be notified, $false indicates no notification.
    Default is no notification.
.PARAMETER AllowRequestorCreation
    Boolean to determine if the requestor should be created if an existing
    person with matching information cannot be found. $true indicates they will
    be created, $false indicates they will not be created.
    Default is no creation.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDTicket -Type 20750 -Title 'New ticket' -AccountID 33502 -StatusID 12005 -PriorityID 2944 -RequestorUID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Creates new ticket in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDTicketStatuses.Name
                HelpText    = 'Name of ticket status'
                IDParameter = 'StatusID'
                IDsMethod   = '$TDTicketStatuses'
            }
            @{
                Name        = 'PriorityName'
                Type        = 'string'
                ValidateSet = $TDTicketPriorities.Name
                HelpText    = 'Name of ticket priority'
                IDParameter = 'PriorityID'
                IDsMethod   = '$TDTicketPriorities'
            }
            @{
                Name        = 'UrgencyName'
                Type        = 'string'
                ValidateSet = $TDTicketUrgencies.Name
                HelpText    = 'Name of ticket urgency'
                IDParameter = 'UrgencyID'
                IDsMethod   = '$TDTicketUrgencies'
            }
            @{
                Name        = 'ImpactNames'
                Type        = 'string'
                ValidateSet = $TDTicketImpacts.Name
                HelpText    = 'Name of ticket impact'
                IDParameter = 'ImpactID'
                IDsMethod   = '$TDTicketImpacts'
            }
            @{
                Name        = 'AccountName'
                Type        = 'string'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Name of department'
                IDParameter = 'AccountID'
                IDsMethod   = '$TDAccounts'
            }
            @{
                Name        = 'TypeName'
                Type        = 'string'
                ValidateSet = $TDTicketTypes.Name
                HelpText    = 'Name of ticket type'
                IDParameter = 'TypeID'
                IDsMethod   = '$TDTicketTypes'
            }
            @{
                Name        = 'SourceName'
                Type        = 'string'
                ValidateSet = $TDTicketSources.Name
                HelpText    = 'Name of ticket source'
                IDParameter = 'SourceID'
                IDsMethod   = '$TDTicketSources'
            }
            @{
                Name        = 'ResponsibleGroupName'
                Type        = 'string'
                ValidateSet = $TDGroups.Name
                HelpText    = 'Name of responsible group'
                IDParameter = 'ResponsibleGroupID'
                IDsMethod   = '$TDGroups'
            }
            @{
                Name        = 'FormName'
                Type        = 'string'
                ValidateSet = $TDForms.Name
                HelpText    = 'Name of ticket form'
                IDParameter = 'FormID'
                IDsMethod   = '$TDForms'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
            $Return = $RedoParametersObj | Net-TDTicket -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        # No location set by name
        else
        {
            #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Get list of active ticket types from TeamDynamix
.DESCRIPTION
    Get list of active ticket types from TeamDynamix
.PARAMETER IsActive
    Select types based on whether they are active. Default ($null) returns
    all types.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketType -AuthenticationToken $Authentication

    Retrieves list of all active ticket types from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketType
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether type is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
}

<#
.Synopsis
    Get list of active ticket sources from TeamDynamix
.DESCRIPTION
    Get list of active ticket sources from TeamDynamix, such as email, phone,
    web, etc...
.PARAMETER IsActive
    Select sources based on whether they are active. Default ($null) returns
    all sources.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketType -AuthenticationToken $Authentication

    Retrieves list of all active ticket types from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketSource
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether source is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
}

<#
.Synopsis
    Get list of active ticket impacts from TeamDynamix
.DESCRIPTION
    Get list of active ticket impacts from TeamDynamix, such as "affects user",
    "affects group", "affects department", and "affects organization".
.PARAMETER IsActive
    Select impacts based on whether they are active. Default ($null) returns
    all impacts.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketImpact -AuthenticationToken $Authentication

    Retrieves list of all active ticket impacts from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketImpact
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether impact is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
}

<#
.Synopsis
    Get list of active ticket priorities from TeamDynamix
.DESCRIPTION
    Get list of active ticket priorities from TeamDynamix, such as low, medium,
    high, and emergency.
.PARAMETER IsActive
    Select priorities based on whether they are active. Default ($null) returns
    all priorities.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketPriority -AuthenticationToken $Authentication

    Retrieves list of all active ticket priorities from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketPriority
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether priority is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
}

<#
.Synopsis
    Get list of active ticket urgencies from TeamDynamix
.DESCRIPTION
    Get list of active ticket urgencies from TeamDynamix, such as routine,
    normal, expedited, and emergency.
.PARAMETER IsActive
    Select urgencies based on whether they are active. Default ($null) returns
    all urgencies.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketUrgency -AuthenticationToken $Authentication

    Retrieves list of all active ticket urgencies from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDTicketUrgency
{
    [CmdletBinding()]
    Param
    (
        # Select based on whether urgency is active
        [Parameter(Mandatory=$false)]
        [boolean]
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
}

<#
.Synopsis
    Get list of contacts on a ticket from TeamDynamix
.DESCRIPTION
    Get list of contacts on a ticket from TeamDynamix. Note that the list of
    contacts does not include the individual currently responsible for the
    ticket.
.PARAMETER ID
    Ticket ID whose contacts will be retrieved from TeamDynamix.
.PARAMETER IncludeResponsible
    Includes the person responsible for the ticket.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketContact -ID 99432 -AuthenticationToken $Authentication

    Retrieves list of all contacts on a ticket ID 99432 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicketContact -ID 99432 -IncludeResponsible -AuthenticationToken $Authentication

    Retrieves list of all contacts on a ticket ID 99432 from TeamDynamix,
    including the user responsible for the ticket.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Removes a contact from a ticket in TeamDynamix
.DESCRIPTION
    Removes a contact from a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID whose contact will be removed in TeamDynamix.
.PARAMETER UID
    UID of contact to be removed from the ticket in TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDTicketContact -ID 99432 -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Removes contact with UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from ticket
    ID 99432 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove UID: $UID", 'Remove contact from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting contact UID, $UID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/contacts/$UID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
}

<#
.Synopsis
    Adds a contact to a ticket in TeamDynamix
.DESCRIPTION
    Adds a contact to a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID whose contact will be added in TeamDynamix.
.PARAMETER UID
    UID of contact to be added to the ticket in TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDTicketContact -ID 99432 -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Adds contact with UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to ticket
    ID 99432 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, add UID: $UID", 'Adding contact to TeamDynamix ticket'))
        {
            Write-ActivityHistory "Adding contact UID, $UID, to ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/contacts/$UID" -ContentType $ContentType -Method POST -Headers $AuthenticationToken
            return $Return
        }
    }
}

<#
.Synopsis
    Updates a ticket in TeamDynamix
.DESCRIPTION
    Post an update to a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID to be updated in TeamDynamix.
.PARAMETER NewStatusID
    Updated ticket status ID.
.PARAMETER Comments
    Updated ticket comments.
.PARAMETER Notify
    Individuals to notify.
.PARAMETER IsPrivate
    Set feed entry to private or not.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDTicket -ID 99432 -Comments 'Working on problem' -Notify keller.4@osu.edu, seconduser@domain -NewStatusName 'In Process' -IsPrivate $false -AuthenticationToken $Authentication

    Updates ticket ID 99432 from TeamDynamix and notifies two users.
.EXAMPLE
    C:\>Update-TDTicket -ID 99432 -Comments 'Working on problem' -Notify (Get-TDTicketContacts 99432 -Environment Sandbox -IncludeResponsible).AlertEmail -NewStatusName 'In Process' -IsPrivate $false -AuthenticationToken $Authentication

    Updates ticket ID 99432 from TeamDynamix and notify the contacts and the
    person responsible for the ticket.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDTicketStatuses.Name
                HelpText    = 'Name of new ticket status'
                IDParameter = 'NewStatusID'
                IDsMethod   = '$TDTicketStatuses'
            }
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

        $TicketUpdate = [TeamDynamix_Api_Feed_TicketFeedEntry]::new()
        Update-Object -InputObject $TicketUpdate -ParameterList $CommandParameters.Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList $IgnoreParameters -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, comment: $Comment", 'Updating TeamDynamix ticket'))
        {
            if ($Status)
            {
                $TicketUpdate.NewStatusID = ($TDTicketStatuses | Where-Object Name -eq $Status.Value).ID
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
    }
}

<#
.Synopsis
    Get blackout windows from TeamDynamix
.DESCRIPTION
    Gets a specific blackout window or searches for matching windows
    from TeamDynamix. Get a list of all active blackout windows, or use the
    -NameLike option to match on a substring from the window name. Blackout
    windows specify periods when blackout activities may not take place.
    Blackout windows are specific to each ticketing application.
.PARAMETER ID
    ID of blackout window to get.
.PARAMETER NameLike
    Substring search filter.
.PARAMETER IsActive
    Boolean to limit return set to active blackout windows ($true), inactive
    blackout windows ($false), or all ($null).
.PARAMETER AppID
    Application ID for the blackout window.
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
   C:\>Get-TDBlackoutWindow -ID 6331 -AuthenticationToken $Authentication

   Returns a blackout window with ID 6331.
.EXAMPLE
   C:\>Get-TDBlackoutWindow -AuthenticationToken $Authentication

   Returns a list of all active blackout windows.
.EXAMPLE
   C:\>Get-TDBlackoutWindow -IsActive $null -AuthenticationToken $Authentication

   Returns a list of all blackout windows, including active and inactive
   windows.
.EXAMPLE
   C:\>Get-TDBlackoutWindow -Filter Grad -IsActive $false -AuthenticationToken $Authentication

   Returns list of inactive blackout windows with the word, "Grad" in
   the name in the of the blackout window.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
}

<#
.Synopsis
    Create a new blackout window in TeamDynamix
.DESCRIPTION
    Creates a new blackout window in TeamDynamix. Blackout windows are specific
    to the ticketing application.
.PARAMETER Name
    Name of blackout window.
.PARAMETER Description
    Description of blackout window.
.PARAMETER TimeZoneID
    ID number of Time Zone.
.PARAMETER TimeZoneName
    Name of Time Zone.
.PARAMETER IsActive
    Set whether blackout window is active or not. Default: true.
.PARAMETER AppID
    Application ID for the blackout window.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>New-TDBlackoutWindow -Name 'New blackout window' -Description 'Blackout window for assets' -AuthenticationToken $Authentication

   Creates a new active blackout window named, "New blackout window".
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Modify a blackout window in TeamDynamix
.DESCRIPTION
    Modifies a blackout window in TeamDynamix.
.PARAMETER ID
    ID of blackout window to modify in TeamDynamix.
.PARAMETER Name
    Name of blackout window.
.PARAMETER Description
    Description of blackout window.
.PARAMETER TimeZoneID
    ID number of Time Zone.
.PARAMETER TimeZoneName
    Name of Time Zone.
.PARAMETER IsActive
    Set whether blackout windows is active or not.
.PARAMETER AppID
    Application ID for the blackout window.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Set-TDBlackoutWindow -ID 5531 -Name 'Modified blackout window' -Description 'Changed window' -AuthenticationToken $Authentication

   Modifies blackout window with ID, 5531, to have a new name and description.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = ($TDApplications | Where-Object AppClass -eq 'TDTickets').Name
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
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -AppID $AppID
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}

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
}

<#
.Synopsis
    Get list of assets on a ticket from TeamDynamix
.DESCRIPTION
    Get list of assets on a ticket from TeamDynamix.
.PARAMETER ID
    Ticket ID whose assets will be retrieved from TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketAsset -ID 99432 -AuthenticationToken $Authentication

    Retrieves list of all contacts on a ticket ID 99432 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory 'Retrieving all assets on a ticket'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Cmdb_ConfigurationItem]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Removes an asset from a ticket in TeamDynamix
.DESCRIPTION
    Removes an asset from a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID whose assets will be removed in TeamDynamix.
.PARAMETER AssetID
    Asset ID of asset to be removed from the ticket in TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDTicketAsset -ID 99432 -AssetID 55421 -AuthenticationToken $Authentication

    Removes asset with Asset ID 55421 from ticket ID 99432 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove asset ID: $AssetID", 'Remove asset from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting asset ID, $AssetID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets/$AssetID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
}

<#
.Synopsis
    Adds an asset to a ticket in TeamDynamix
.DESCRIPTION
    Adds an asset to a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID whose asset will be added in TeamDynamix.
.PARAMETER AssetID
    Asset ID of asset to be added to the ticket in TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDTicketAsset -ID 99432 -AssetID 55421 -AuthenticationToken $Authentication

    Adds asset with ID 55421 to ticket wth ID 99432 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, add asset ID: $AssetID", 'Adding contact to TeamDynamix ticket'))
        {
            Write-ActivityHistory "Adding asset ID, $AssetID, to ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/assets/$AssetID" -ContentType $ContentType -Method POST -Headers $AuthenticationToken
            return $Return
        }
    }
}

<#
.Synopsis
    Get list of tasks on a ticket from TeamDynamix
.DESCRIPTION
    Get list of tasks on a ticket from TeamDynamix.
.PARAMETER ID
    Ticket ID whose tasks will be retrieved from TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketTask -ID 99432 -AuthenticationToken $Authentication

    Retrieves list of all tasks on a ticket ID 99432 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDTicketTask -ID 99432 -TaskID 3398 -AuthenticationToken $Authentication

    Retrieves task ID 3398 on ticket ID 99432 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Get the feed on a ticket task from TeamDynamix
.DESCRIPTION
    et the feed on a ticket task from TeamDynamix.
.PARAMETER ID
    Ticket ID whose task feed will be retrieved from TeamDynamix.
.PARAMETER TaskID
    Task ID whose feed will be retrieved from TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDTicketTaskFeed -ID 99432 -TaskID 3398 -AuthenticationToken $Authentication

    Retrieves the feed for task ID 3398 on ticket ID 99432 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory 'Retrieving specific task feed on a ticket'
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskId/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Removes a task from a ticket in TeamDynamix
.DESCRIPTION
    Removes a task from a ticket in TeamDynamix.
.PARAMETER ID
    Ticket ID whose task will be removed in TeamDynamix.
.PARAMETER TaskID
    Task ID of task to be removed from the ticket in TeamDynamix.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDTicketTask -ID 99432 -AssetID 55421 -AuthenticationToken $Authentication

    Removes task with task ID 55421 from ticket ID 99432 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        if ($pscmdlet.ShouldProcess("ticket ID: $ID, remove task ID: $TaskID", 'Remove task from TeamDynamix ticket'))
        {
            Write-ActivityHistory "Deleting task ID, $TaskID, from ticket ID, $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/tickets/$ID/tasks/$TaskID" -ContentType $ContentType -Method DELETE -Headers $AuthenticationToken
            return $Return
        }
    }
}

<#
.Synopsis
    Adds a task to a ticket in TeamDynamix
.DESCRIPTION
    Adds a task to a ticket in TeamDynamix.
.PARAMETER ID
    ID of ticket that task will be added to.
.PARAMETER Title
    Title of ticket task.
.PARAMETER Description
    Description of ticket task.
.PARAMETER StartDate
    Start date of ticket task.
.PARAMETER EndDate
    End date of ticket task.
.PARAMETER CompleteWithinMinutes
    Expected duration of task, in minutes. Value is in operational minutes, so
    operational hours, weekends, and days off are all taken into account.
.PARAMETER EstimatedMinutes
    Estimated minutes elapsed on the task. Maintenance activities do not
    require this.
.PARAMETER ResponsibleUID
    UID of the user responsible for the task.
.PARAMETER ResponsibleGroupID
    ID of the group responsible for the task.
.PARAMETER PredecessorID
    ID of the predecessor for the task.
.PARAMETER TypeID
    Type of ticket task. Types include: regular task, scheduled maintenance,
    workflow, or other. Default is regular task.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDTicketTask -ID 99432 -Title 'First task' -ResponsibleUID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Creates new task with title "First task" on ticket wth ID 99432 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
}

<#
.Synopsis
    Update a ticket task with new values in TeamDynamix
.DESCRIPTION
    Update a ticket task with new values in TeamDynamix.
.PARAMETER ID
    ID of ticket whose task will be modified.
.PARAMETER TaskID
    Task ID of task to be modified in TeamDynamix.
.PARAMETER Title
    Title of ticket task.
.PARAMETER Description
    Description of ticket task.
.PARAMETER StartDate
    Start date of ticket task.
.PARAMETER EndDate
    End date of ticket task.
.PARAMETER CompleteWithinMinutes
    Expected duration of task, in minutes. Value is in operational minutes, so
    operational hours, weekends, and days off are all taken into account.
.PARAMETER EstimatedMinutes
    Estimated minutes elapsed on the task. Maintenance activities do not
    require this.
.PARAMETER ResponsibleUID
    UID of the user responsible for the task.
.PARAMETER ResponsibleGroupID
    ID of the group responsible for the task.
.PARAMETER PredecessorID
    ID of the predecessor for the task.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDTicketTask -ID 99432 -TaskID 27744 -Title 'First task' -ResponsibleUID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Changes task with ID 27744 to title "First task" on ticket wth ID 99432 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
}

<#
.Synopsis
    Update a ticket task status in TeamDynamix
.DESCRIPTION
    Update a ticket task status in TeamDynamix.
.PARAMETER ID
    ID of ticket whose task status will be updated.
.PARAMETER TaskID
    Task ID of task to be updated in TeamDynamix.
.PARAMETER PercentComplete
    Percent complete of the ticket task.
.PARAMETER Comments
    Comment for the feed entry.
.PARAMETER Notify
    Email addresses to notify.
.PARAMETER IsPrivate
    Indicates whether the feed entry is private.
.PARAMETER AppID
    Application ID for the ticketing app.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Update-TDTicketTask -ID 99432 -Task ID 27744 -Comment 'Task comment' -AuthenticationToken $Authentication

    Updates status of task 27744 with comment "Task comment" on ticket wth ID 99432
    in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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