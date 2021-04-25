### Roles

function Get-TDFunctionalRole
{
    [CmdletBinding()]
    Param
    (
        # Filter text, substring
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $Name,

        # Return item counts or not
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $ReturnItemCounts,

        # Maximum results to return
        [Parameter(Mandatory=$false)]
        [ValidateRange(1,100)]
        [int]
        $MaxResults = 0,

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
        $Search = [TeamDynamix_Api_Roles_FunctionalRoleSearch]::new($Name,$MaxResults,$ReturnItemCounts)
        $Return = Invoke-RESTCall -Uri "$BaseURI/functionalroles/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Search -Depth 10)
		if ($Return)
        {
            return [TeamDynamix_Api_Roles_FunctionalRole]::new($Return)
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDFunctionalRole
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Name of the role
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateLength(1,100)]
        [string]
        $Name,

        # Standard rate for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $StandardRate = 0.0,

        # Cost rate for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $CostRate = 0.0,

        # Comments regarding the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Comments,

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
        $NewRole = [TeamDynamix_Api_Roles_FunctionalRole]::new()
        Update-Object -InputObject $NewRole -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($Name, 'Add new functional role'))
        {
            Write-ActivityHistory "Adding new functional role, $Name"
            $Return = Invoke-RESTCall -Uri "$BaseURI/functionalroles" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewRole -Depth 10)
		    if ($Return)
            {
                return [TeamDynamix_Api_Roles_FunctionalRole]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDFunctionalRole
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # ID of the role
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $ID,

        # Name of the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(1,100)]
        [string]
        $Name,

        # Standard rate for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $StandardRate,

        # Cost rate for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $CostRate,

        # Comments regarding the role
        [Parameter(Mandatory=$false)]
        [string]
        $Comments,

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
        Write-ActivityHistory "Getting full record for functional role $ID on TeamDynamix."
        try
        {
            $Roles = Get-TDFunctionalRole -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find functional role ID $ID"
        }
        $UpdatedRole = $Roles | Where-Object ID -eq $ID
        if ($UpdatedRole)
        {
            Write-ActivityHistory 'Role exists. Setting properties.'
            Update-Object -InputObject $UpdatedRole -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($pscmdlet.ShouldProcess($UpdatedRole.Name, 'Update role'))
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/functionalroles/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $UpdatedRole -Depth 10)
		        if ($Return)
                {
                    return [TeamDynamix_Api_Roles_FunctionalRole]::new($Return)
                }
            }
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Role ID, $ID, not found on TeamDynamix"
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDSecurityRole
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # ID for the security role
        [Parameter(ParameterSetName='ID',
				   Mandatory=$true,
                   Position=0)]
		[guid]
        $ID,

		# Filter text, substring
        [Parameter(ParameterSetName='Search',
				   Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $NameLike,

        # Roles for license type to return
        [Parameter(ParameterSetName='Search',
         Mandatory=$false)]
        [TeamDynamix_Api_Roles_LicenseTypes]
        $LicenseTypeID,

        # Return only security role that contains the exact name match
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Exact,

        # Roles for application ID to return
        [Parameter(ParameterSetName='Search',
			       Mandatory=$false)]
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
        #List dynamic parameters
        $DynamicParameterList = @(
            @{
                Name        = 'AppName'
                Type        = 'string'
                ValidateSet = $TDApplications.GetByAppClass('TDAssets',$true).Name
                HelpText    = 'Name of application'
                IDParameter = 'AppID'
                IDsMethod   = '$TDApplications.GetAll($WorkingEnvironment,$true)'
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
            SearchType       = 'TeamDynamix_Api_Roles_SecurityRoleSearch'
            ReturnType       = 'TeamDynamix_Api_Roles_SecurityRole'
            AllEndpoint      = $null
            SearchEndpoint   = "securityroles/search"
            IDEndpoint       = "securityroles/$ID"
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
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function New-TDSecurityRole
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Name of the role
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateLength(1,100)]
        [string]
        $Name,

        # Permissions granted to the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Permissions,

        # Use default permissions from the license for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $UseDefaultPermissions,

        # Application ID for role
        [Parameter(Mandatory=$false)]
        [int]
        $AppID,

        # License type for role
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_Roles_LicenseTypes]
        $LicenseType,

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
        $NewRole = [TeamDynamix_Api_Roles_SecurityRole]::new()
        Update-Object -InputObject $NewRole -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -IgnoreList ([array]'UseDefaultPermissions' + $LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess($Name, 'Add new security role'))
        {
            Write-ActivityHistory "Adding new security role, $Name"
            $Return = Invoke-RESTCall -Uri "$BaseURI/securityroles?useDefaultPermissions=$($UseDefaultPermissions.IsPresent)" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewRole -Depth 10)
		    if ($Return)
            {
                return [TeamDynamix_Api_Roles_SecurityRole]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Set-TDSecurityRole
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # UID of the role
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [guid]
        $ID,

        # Name of the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateLength(1,100)]
        [string]
        $Name,

        # Permissions granted to the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Permissions,

        # Use default permissions from the license for the role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $UseDefaultPermissions,

        # License type to use for role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Roles_LicenseTypes]
        $LicenseType,

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
        Write-ActivityHistory "Getting full record for security role $ID on TeamDynamix."
        try
        {
            $UpdatedRole = [TeamDynamix_Api_Roles_SecurityRole]::new((Get-TDsecurityRole -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop))
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Security role, $UID, not found"
        }
        if ($UpdatedRole)
        {
            Write-ActivityHistory 'Role exists. Setting properties.'
            Update-Object -InputObject $NewRole -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -IgnoreList ([array]'UseDefaultPermissions' + $LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($pscmdlet.ShouldProcess($UpdatedRole.Name, 'Update role'))
            {
                Write-ActivityHistory "Updating role $UpdatedRole.Name"
                $Return = Invoke-RESTCall -Uri "$BaseURI/securityroles/$($ID)?useDefaultPermissions=$($UseDefaultPermissions.IsPresent)" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $UpdatedRole -Depth 10)
                if ($Return)
                {
                    return [TeamDynamix_Api_Roles_SecurityRole]::new($Return)
                }
            }
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Get-TDSecurityRolePermissions
{
    [CmdletBinding()]
    Param
    (
        # Application ID for the security role permissions list
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        [int]
        $AppID = 0,

		# Return only default permissions
        [Parameter(Mandatory=$false)]
        [switch]
        $OnlyDefault,

        # License type for role
        [Parameter(Mandatory=$false)]
        [TeamDynamix_Api_Roles_LicenseTypes]
        $LicenseType,

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
	    # Build query string
        $Query = ''
        if (-not [string]::IsNullOrEmpty($AppID))
        {
            $Query = "forAppID=$AppID"
        }
        if (-not [string]::IsNullOrEmpty($LicenseType))
        {
            if($Query)
            {
                $Query += '&'
            }
            $Query += "forLicenseType=$LicenseType"
        }
        if ($OnlyDefault)
        {
            if($Query)
            {
                $Query += '&'
            }
            $Query += "onlyDefault=$($OnlyDefault.IsPresent)"
        }
        Write-ActivityHistory "Retrieving security role permissions for application, $AppID, and license type, $LicenseType"
        $Return = Invoke-RESTCall -Uri "$BaseURI/securityroles/permissions?$Query" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
		if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_Roles_Permission]::new($_)})
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}


function Get-TDUserFunctionalRole
{
    [CmdletBinding(DefaultParameterSetName='Username')]
    Param
    (
        # User ID to examine
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Username to examine
        [Parameter(Mandatory=$true,
                   ParameterSetName='Username')]
        [ValidatePattern('^.*@.*\..*$')]
        [string]
        $Username,

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
            'Username'
            {
                $User = Get-TDUser -UserName $Username -AuthenticationToken $AuthenticationToken -Environment $Environment
                if ($User)
                {
                    $UserUID = $User.UID
                    $Return = ($UserUID | Get-TDUserFunctionalRole -AuthenticationToken $AuthenticationToken -Environment $Environment)
                }
                else
                {
                    Write-ActivityHistory -MessageChannel 'Error' -Message "Username, $Username, not found."
                }
            }
            'UID'
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/functionalroles" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_Roles_UserFunctionalRole]::new($_)})
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Remove-TDUserFunctionalRole
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   DefaultParameterSetName='UID')]
    Param
    (
        # User ID to remove from functional role
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Username to remove from group
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Username')]
        [ValidatePattern('^.*@.*\..*$')]
        [string]
        $Username,

        # Functional Role ID that user will be removed from
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $RoleID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
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
        if ($PSCmdlet.ParameterSetName -eq 'Username')
        {
            $UID = $null
            $TDUser = Get-TDUser -UserName $Username -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($TDUser)
            {
                $UID = $TDUser.UID
            }
            else # Get-TDUser came up empty
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "No user ID found for $Username."
                return
            }
        }
        if ($UID)
        {
            if ($pscmdlet.ShouldProcess($UID, "Remove user from functional role, $RoleID"))
            {
                Write-ActivityHistory "Removing user, $UID, from functional role, $RoleID, in TeamDynamix"
                $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/functionalroles/$RoleID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
                return $Return
            }
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Username, $Username, not found or matched more than one user."
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

function Add-TDUserFunctionalRole
{
    [CmdletBinding(DefaultParameterSetName='UID')]
    Param
    (
        # Add functional role to user UID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Add functional role to user name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Username')]
        [ValidatePattern('^.*@.*\..*$')]
        [string]
        $Username,

        # Functional role ID that user will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $RoleID,

        # Set role to be user's primary role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $IsPrimary,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
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
        if ($PSCmdlet.ParameterSetName -eq 'Username')
        {
            $UID = $null
            $TDUser = Get-TDUser -UserName $Username -AuthenticationToken $AuthenticationToken -Environment $Environment
            if ($TDUser)
            {
                $UID = $TDUser.UID
            }
            else # Get-TDUser came up empty
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "No user ID found for username $Username."
                return
            }
        }
        if ($UID)
        {
            Write-ActivityHistory "Adding user, $UID, to functional role, $RoleID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/functionalroles/$($GroupID)?isPrimary=$($IsPrimary.IsPresent)" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
            return $Return
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Username, $Username, not found."
        }
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}