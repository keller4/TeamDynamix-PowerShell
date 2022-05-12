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
        $Search = [TeamDynamix_Api_Roles_FunctionalRoleSearch]::new($Name,$MaxResults,$ReturnItemCounts)
        $Return = Invoke-RESTCall -Uri "$BaseURI/functionalroles/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Search -Depth 10)
		if ($Return)
        {
            return [TeamDynamix_Api_Roles_FunctionalRole]::new($Return)
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
                ValidateSet = $TDApplications.GetAll($WorkingEnvironment,$true).Name
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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    End
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEHsjESkKjaG3Sq+owvUy1e3+
# 4oigggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFBQ7
# p1CCLc6QHRmEqkqpprl/5i3+MA0GCSqGSIb3DQEBAQUABIICADmcFfMt8DmEhmzq
# LBcAkhSK6oDRXmEBFqkQLk2uG3WeT3E1CC5knr+sejYvruwwPYa7KW57VNRV+h46
# 47LuJ+k15Lj+DCGrqYZHTnhFJ+RLJxENiheDilU1KPRr0ZW1LIWwlHSHmhG4Q3k/
# MuqdarO8zDz4+24b3rAMpEOFqgvtV/vuO26uFbh8hVQrXl1N/PFRn19iFobiiw7t
# mKEOovxN8WbhnV4v7dswtYKC+xUlkiDXDtK62QGk1z9nwXfiHAGDFpQ5GP/nM9Bs
# ybKKRc+r+bWXK3QZgRgT/WgTQDll1FSZIKjMnRrN9C0JOclu5rs8+u+N/RCiHxHq
# qC97bKBlWyzgs6rAbjAT/CjwjXB4M0B60TP9kQLI2Swp28NN+JlDJYrwy9A5BVEA
# AIv5G+OGNHgEenfyalLDlyik8ddDW7QYoFGAXA73c/8k6VCDfKm8PPRG1vG4ODTn
# JtASqzOGlzlUFIZT21PTw9eaQPFpk3rlIfAl/ok9BC3fYpoJpNg5ORAF8Y00iQfl
# 7Rv1OigkY8DH5kRz61XQTCNwa3UHKSFvo3XT0+nO4ao02gO614avXZP/D1TK9LdR
# vFpu5GtoExZNYJDSahdvCAE1IEUAwJ8auoYFtx6RXfc53YS5wpNxsczo1VOy4qxq
# YeMzqOd//Y0L1vr9j0wgcGn7hrpM
# SIG # End signature block
