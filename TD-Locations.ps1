### Locations

function Get-TDLocation
{
    [CmdletBinding(DefaultParameterSetName='Filter')]
    Param
    (
        # Location (building) ID to retrieve from TeamDynamix
        [Parameter(ParameterSetName='ID',
                   Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [int]
        $ID,

        # Substring search for location (building) name to retrieve from TeamDynamix
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false,
                   Position=0)]
        [alias('Filter')]
        [string]
        $NameLike,

        # Return only active locations
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Return only locations where room is required
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsRoomRequired,

        # Return only location that contains the specified room ID
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [int]
        $RoomID,

        # Substring search for room
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false,
                   Position=1)]
        [string]
        $RoomLike,

        # Return asset and ticket counts
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [switch]
        $ReturnItemCounts,

        # Return rooms contained in each location
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [switch]
        $ReturnRooms,

        # Custom attributes filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Filter')]
        [array]
        $Attributes,

        # Maximum results to return (default 50)
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [int]
        $MaxResults = 50,

        # Return full detail
        [Parameter(ParameterSetName='Filter',
                   Mandatory=$false)]
        [switch]
        $Detail,

        # Return only location/room that contains the exact name match
        [Parameter(ParameterSetName='Filter',
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
        $LocalIgnoreParameters = @('ID','Detail','Exact','RoomLike')
    }
    Process
    {
        # Warn on invalid combinations
        if ($ID -and $NameLike)
        {
            Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring NameLike, using ID'
            $NameLike = ''
        }
        if ($RoomID -and $RoomLike)
        {
            Write-ActivityHistory -MessageChannel 'Warning' -Message 'Ignoring RoomLike, using RoomID'
            $RoomLike = ''
        }

        $Return = $null
        if ($ID)
        {
            if ($RoomID)
            {
                # RoomID and ID specified, do an exact room lookup - returns full room detail
                $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$ID/rooms/$RoomID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            else
            {
                # ID specified, do an exact location lookup - returns full location detail
                $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        # No ID
        else
        {
            if (-not $Return)
            {
                # If Return, then location info already retrieved (location ID specified)
                #  Ignore Namelike (already specified ID), RoomID (already handled), ReturnItemCounts (only one), and ReturnRooms (they have been)
                #  Assuming that it's safe to ingore IsActive, IsRoomRequired, and Attributes since specific building and room were selected
                # If no return, no location info collected yet - retrieve it
                if (($NameLike -eq '')          -and
                    ($IsActive -eq $true)       -and
                    ($null -eq $IsRoomRequired) -and
                    ($RoomID -eq 0)             -and
                    (-not $ReturnItemCounts)    -and
                    (-not $ReturnRooms)         -and
                    ($null -eq $Attributes))
                {
                    # Retrieve all locations
                    $Return = Invoke-RESTCall -Uri "$BaseURI/locations" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    # Retrieve specified location(s)
                    $Query = [TeamDynamix_Api_Locations_LocationSearch]::new()
                    Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                    $Return = Invoke-RESTCall -Uri "$BaseURI/locations/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
                }

                # Check for unambiguous match on location name - return one or zero results - only needed for NameLike searches
                if ($NameLike -and $Exact)
                {
                    $Return = $Return | Where-Object Name -eq $NameLike
                }
            }
        }
        # If RoomID and NameLike are both set, return room information, not building information (treat like -ID and -RoomID)
        if ($RoomID -and $NameLike)
        {
            if ($Return)
            {
                $Return = Get-TDLocation -ID $Return.ID -RoomID $RoomID -AuthenticationToken $AuthenticationToken -Environment $Environment
                $Detail = $false
            }
        }
        if ($RoomLike)
        {
            if ($Return.Count -gt 1)
            {
                Write-ActivityHistory -MessageChannel Error -ThrowError -Message 'Ambiguous location, unable to look up room. Specify a single building to search.'
            }
            else
            {
                if ($Return -and ($Return.Rooms.Count -eq 0))
                {
                    # Get location with list of rooms
                    $Return = Get-TDLocation -ID $Return.ID -AuthenticationToken $AuthenticationToken -Environment $Environment
                    if ($Return.Rooms.Count -eq 0)
                    {
                        # No rooms in this location, don't return anything
                        $Return = $null
                    }
                }
                if ($Return)
                {
                    # Save location ID for later reference (necessary if -Detail is set)
                    $ID = $Return.ID
                    $Return = $Return.Rooms | Where-Object Name -like "*$RoomLike*"
                    # Return only exact room match (building match is already guaranteed since an unambiguous match was required to get here)
                    if ($Exact)
                    {
                        $Return = $Return | Where-Object Name -eq $RoomLike
                    }
                    # Limit count to MaxResults
                    if ($MaxResults)
                    {
                        $Return = $Return | Select-Object -First $MaxResults
                    }
                }
            }
        }
        if ($Return)
        {
            # Determine whether return is a room or a location
            #  Create an empty location object to compare with
            $TestLocationObject = [TeamDynamix_Api_Locations_Location]::new()
            #  Compare-Object will return nothing if there's no difference (the return was a location) - otherwise, it's a room
            $CompareToLocationObject = Compare-Object -ReferenceObject ($Return | Get-Member -MemberType NoteProperty,Property).Name  -DifferenceObject ($TestLocationObject | Get-Member -MemberType Property).Name

            if ($Detail)
            {
                if ($CompareToLocationObject)
                {
                    # Return full information on room(s)
                    $Return = $Return.ID | ForEach-Object {Get-TDLocation -ID $ID -RoomID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}
                }
                else
                {
                    # Return full information on building(s)
                    $Return = $Return.ID | Get-TDLocation -AuthenticationToken $AuthenticationToken -Environment $Environment
                }
            }

            # Build output based on object type
            if ($CompareToLocationObject)
            {
                $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Locations_LocationRoom]::new($_)})
            }
            else
            {
                $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Locations_Location]::new($_)})
            }
        }
        return $Return
    }
}

function Remove-TDRoom
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Room ID to delete from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $RoomID,

        # Location (building) ID for Room to delete from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

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
        if ($pscmdlet.ShouldProcess("Room: $RoomID, Location: $LocationID", 'Remove room from location'))
        {
            Write-ActivityHistory "Removing room ID $RoomID from location ID $LocationID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$LocationID/rooms/$RoomID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
    }
}

function New-TDLocation
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Location (building) name to create in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Location (building) description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Location (building) external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Active location
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Location (building) address
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address,

        # Location (building) city
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $City,

        # Location (building) state
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $State,

        # Location (building) postal code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PostalCode,

        # Location (building) country
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Country,

        # Are rooms required at this location
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsRoomRequired,

        # Modify custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Latitude of location (building)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[decimal]]
        $Latitude,

        # Longitude of location (building)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[decimal]]
        $Longitude,

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
        $TDLocation = [TeamDynamix_Api_Locations_Location]::new()
        Update-Object -InputObject $TDLocation -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("Location name: $Name", 'Create new location'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/locations" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDLocation -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Locations_Location]::new($Return)
            }
            return $Return
        }
    }
}

function Set-TDLocation
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Location (building) ID to modify in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Location (building) name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Location (building) description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Location (building) external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Active location
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # Location (building) address
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address,

        # Location (building) city
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $City,

        # Location (building) state
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $State,

        # Location (building) postal code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PostalCode,

        # Location (building) country
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Ccountry,

        # Are rooms required at this location
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsRoomRequired,

        # Modify custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Updated latitude of location (building)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[decimal]]
        $Latitude,

        # Updated longitude of location (building)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[decimal]]
        $Longitude,

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
        # Retrieve existing location
        try
        {
            $TDLocation = Get-TDLocation -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -ErrorRecord $_ -ThrowError -ErrorMessage "Unable to find location $ID."
        }
        Update-Object -InputObject $TDLocation -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("Location ID: $ID - Name: $($TDLocation.Name)", 'updating location'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TDLocation -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Locations_Location]::new($Return)
            }
            return $Return
        }
    }
}

function New-TDRoom
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Location (building) ID that contains the room to create in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Room name to create in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Room description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Building floor of room
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Floor,

        # Room capacity
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $Capacity,

        # Room external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Modify custom attributes
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
        $TDLocation = [TeamDynamix_Api_Locations_LocationRoom]::new()
        Update-Object -InputObject $TDLocation -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("Location name: $Name", 'Create new location'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$ID/rooms" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDLocation -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Locations_LocationRoom]::new($Return)
            }
            return $Return
        }
    }
}

function Set-TDRoom
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Location (building) ID that contains the room to update in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Room ID to update in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $RoomID,

        # Updated room name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Room description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Building floor of room
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Floor,

        # Room capacity
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $Capacity,

        # Room external ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Modify custom attributes
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
        $LocalIgnoreParameters = @('LocationID','RoomID')
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
        # Retrieve existing location
        try
        {
            $TDRoom = Get-TDLocation -ID $LocationID -RoomID $RoomID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -ErrorRecord $_ -ThrowError -ErrorMessage "Unable to find room $RoomID in location $LocationID"
        }
        Update-Object -InputObject $TDRoom -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess("Room ID: $RoomID - Name: $($TDRoom.Name), Location ID: $LocationID - Name: $($TDLocation.Name)", 'updating location'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/locations/$LocationID/rooms/$RoomID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $TDRoom -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Locations_LocationRoom]::new($Return)
            }
            return $Return
        }
    }
}