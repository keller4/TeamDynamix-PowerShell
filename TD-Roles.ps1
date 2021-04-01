### Roles

<#
.Synopsis
    Get a functional role from TeamDynamix
.DESCRIPTION
    Gets a specific functional role, or searches for matching functional roles
	from TeamDynamix. Functional roles are used to describe a user's job title
	(their function). Search using a substring of the desired functional role
	name.
.PARAMETER Name
    Substring search filter, no wildcards. Leave blank for all functional
    roles. May also use "Filter" instead of "Name".
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.PARAMETER MaxResults
    Limit return set to a number between 1 and 100.
.INPUTS
    String, or array of strings, containing UIDs.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Accounts.Account.
.EXAMPLE
   C:\>Get-TDFunctionalRole -AuthenticationToken $Authentication

   Returns a list of all functional roles.
.EXAMPLE
   C:\>Get-TDFunctionalRole -Name 'Admin' -AuthenticationToken $Authentication -MaxResults 2

   Returns functional role information on two accounts with "Admin" in the
   full name.
.EXAMPLE
   C:\>Get-TDFunctionalRole -Filter 'Admin' -AuthenticationToken $Authentication -MaxResults 2

   Returns functional role information on two accounts with "Admin" in the
   full name.
.EXAMPLE
   C:\>'Admin', 'Professor' | Get-TDFunctionalRole -AuthenticationToken $Authentication

   Returns full department information on functional roles specified in the
   pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Create a functional role in TeamDynamix
.DESCRIPTION
    Create a new functional role in TeamDynamix. Functional roles are used to
    describe a user's job title (their function).
.PARAMETER Name
    Name of the role to be created.
.PARAMETER StandardRate
    Standard rate for the role to be created.
.PARAMETER CostRate
    Cost rate for the role to be created.
.PARAMETER Comments
    Comments regarding the role to be created.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Object containing, at minimum, the name of the role.
.OUTPUTS
    Powershell object containing functional role properties as documented in
    TeamDynamix.Api.Roles.FunctionalRole.
.EXAMPLE
   C:\>New-TDFunctionalRole -Name 'Manager' -AuthenticationToken $Authentication

   Creates a new functional role named 'Manager', with StandardRate and CostRate of 0.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Update a functional role in TeamDynamix
.DESCRIPTION
    Update a functional role in TeamDynamix. Functional roles are used to
    describe a user's job title (their function).
.PARAMETER ID
    ID of the role to be updated.
.PARAMETER Name
    Name of the role to be updated.
.PARAMETER StandardRate
    Standard rate for the role to be updated.
.PARAMETER CostRate
    Cost rate for the role to be updated.
.PARAMETER Comments
    Comments regarding the role to be updated.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Object containing, at minimum, the name of the role.
.OUTPUTS
    Powershell object containing functional role properties as documented in
    TeamDynamix.Api.Roles.FunctionalRole.
.EXAMPLE
   C:\>Set-TDFunctionalRole -ID 2077 -Name 'Manager2' -AuthenticationToken $Authentication

   Updates functional role with ID 2077, to be named 'Manager2'.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Get a security role from TeamDynamix
.DESCRIPTION
    Gets a specific security role, or searches for matching security roles
	from TeamDynamix. Security roles are used to describe a user's access
	rights in TeamDynamix. Search using a substring of the desired security role
	name.
.PARAMETER ID
	UID of the security role to retrieve.
.PARAMETER NameLike
    Substring search filter, no wildcards. Leave blank for all security roles.
.PARAMETER AppID
    Application to search for security roles.
.PARAMETER LicenseTypeID
    License type ID number to search for security roles.
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
.INPUTS
    String, or array of strings, containing UIDs.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Accounts.Account.
.EXAMPLE
   C:\>Get-TDSecurityRole -AuthenticationToken $Authentication

   Returns a list of all security roles.
.EXAMPLE
   C:\>Get-TDSecurityRole -NameLike 'Admin' -AuthenticationToken $Authentication

   Returns security role information on accounts with "Admin" in the full name.
.EXAMPLE
   C:\>'Admin', 'Technician' | Get-TDSecurityRole -AuthenticationToken $Authentication

   Returns full department information on security roles specified in the
   pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
                ValidateSet = $TDApplications.Name
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
}

<#
.Synopsis
    Create a security role in TeamDynamix
.DESCRIPTION
    Create a new security role in TeamDynamix. Security roles are used to
    describe a user's access rights in TeamDynamix.
.PARAMETER Name
    Name of the role to be created.
.PARAMETER AppID
    Application ID for the role to be created.
.PARAMETER LicenseType
    License type for the role to be created.
.PARAMETER Permissions
    Permissions granted to users for the role to be created.
.PARAMETER UseDefaultPermissions
    Use default permissions from the license for the new role.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Object containing, at minimum, the name of the role.
.OUTPUTS
    Powershell object containing functional role properties as documented in
    TeamDynamix.Api.Roles.SecurityRole.
.EXAMPLE
   C:\>New-TDSecurityRole -Name 'Manager' -AuthenticationToken $Authentication

   Creates a new functional role named 'Manager', with StandardRate and CostRate of 0.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Update a security role in TeamDynamix
.DESCRIPTION
    Update a security role in TeamDynamix. Security roles are used to
    describe a user's access rights in TeamDynamix.
.PARAMETER ID
    ID of the role to be updated.
.PARAMETER Name
    Name of the role to be updated.
.PARAMETER LicenseType
    License type for the role to be updated.
.PARAMETER Permissions
    Permissions granted to users for the role to be updated.
.PARAMETER UseDefaultPermissions
    Use default permissions from the license for the updated role.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Object containing, at minimum, the name of the role.
.OUTPUTS
    Powershell object containing functional role properties as documented in
    TeamDynamix.Api.Roles.SecurityRole.
.EXAMPLE
   C:\>Set-TDSecurityRole -ID 'xxxxxxxx-yyyy-yyyy-yyyy-zzzzzzzzzzzz' -Name 'Manager2' -AuthenticationToken $Authentication

   Updates functional role with UID xxxxxxxx-yyyy-yyyy-yyyy-zzzzzzzzzzzz, to
   be named 'Manager2'.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Get list of security role permissions from TeamDynamix
.DESCRIPTION
    Get security role permissions from TeamDynamix for a specific application
    and license type. Use the "OnlyDefault" option to only show the default
    permissions.
.PARAMETER AppID
	Retrieve the security role permissions for the specified application. Default
    is all applications.
.PARAMETER LicenseType
    Retrieve the security role permissions for the specified license type. May
    be specified as either the name or number.
.PARAMETER OnlyDefault
    Only retrieve the default security role permissions.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    String, or array of strings, containing UIDs.
.OUTPUTS
    Powershell object containing security role permissions as documented in
    TeamDynamix.Api.Roles.Permission.
.EXAMPLE
   C:\>Get-TDSecurityRolePermissions -AuthenticationToken $Authentication

   Returns a list of all security role permissions.
.EXAMPLE
   C:\>Get-TDSecurityRolePermissions -AppID 556 -AuthenticationToken $Authentication

   Returns security role permissions for application with ID 556.
.EXAMPLE
   C:\>Get-TDSecurityRolePermissions -LicenseType Client -AuthenticationToken $Authentication

   Returns security role permissions for the "Client" license type.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Get a list of functional roles for a user from TeamDynamix
.DESCRIPTION
    Gets a list of functional roles of the specified user in TeamDynamix. User
    is specified by UID.
.PARAMETER UID
    User ID to examine for functional roles.
.PARAMETER Username
    Username to examine for functional roles. Specify username@domain.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    String, or array of strings, containing UIDs.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Users.UserGroup.
.EXAMPLE
   C:\>Get-TDUserFunctionalRole -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

   Returns a list of functional roles for user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.
.EXAMPLE
   C:\>Get-TDUserFunctionalRole -Username smith@domain -AuthenticationToken $Authentication

   Returns a list of functional roles for user smith@domain.
.EXAMPLE
   C:\>'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY' | Get-TDUserFunctionalRole -AuthenticationToken $Authentication

   Returns a list of functional roles for users XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   and YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY via the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>

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
}

<#
.Synopsis
    Removes a single user from a functional role in TeamDynamix
.DESCRIPTION
    Removes the specified user from the specified functional role in
    TeamDynamix. User is specified by UID. The funcional role is specified by the
    role's RoleID.
.PARAMETER UID
    User ID to be removed from the functional role.
.PARAMETER Username
    Username for the user to be added to the functional role. Username must
    be of the form user@domain.
.PARAMETER RoleID
    User will be removed from the functional role with this RoleID.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    PowerShell object with String containing UID and integer containing role
    ID.
.OUTPUTS
    Message indicating success.
.EXAMPLE
   C:\>Remove-TDUserFunctionalRole -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -RoleID 175 -AuthenticationToken $Authentication

   Removes user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from functional role 175.
.EXAMPLE
   C:\>Remove-TDUserFunctionalRole -Username smith@domain -RoleID 175 -AuthenticationToken $Authentication

   Removes user smith@domain from functional role 175. Note that the username
   must be unique. Best practice is to use username@domain to ensure
   uniqueness.
.EXAMPLE
   C:\>$RemoveUserFromFunctionalRole = @{$UID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';$RoleID=175}
   C:\>$RemoveUserFromFunctionalRole | Remove-TDUserFunctionalRole -AuthenticationToken $Authentication

   Removes user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from group 175 using the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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
}

<#
.Synopsis
    Adds a single user to a functional role in TeamDynamix
.DESCRIPTION
    Adds the specified user to the specified functional role in TeamDynamix.
    User is specified by UID. The functional role is specified by the RoleID.
.PARAMETER UID
    User ID for user to be added to functional role.
.PARAMETER Username
    Username for the user to be added to the functional role. Username must
    be of the form user@domain.
.PARAMETER RoleID
    Group ID for group user is to be added to.
.PARAMETER IsPrimary
    Set functional role as primary for the user.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    PowerShell object with String containing UID and integer containing role
    ID.
.OUTPUTS
    Message indicating success.
.EXAMPLE
   C:\>Add-TDFunctionalRole -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -RoleID 176 -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to functional role 176.
.EXAMPLE
   C:\>Add-TDFunctionalRole -Username smith@domain -RoleID 176 -AuthenticationToken $Authentication

   Adds user smith@domain to functional role 176. Note that the username must
   be unique. Best practice is to use username@domain to ensure uniqueness.
.EXAMPLE
   C:\>Add-TDFunctionalRole -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -RoleID 176 -IsPrimary -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to functional role 176 and
   makes group YYYY the primary group for the user.
.EXAMPLE
   C:\>$AddUserToFunctionalRole = @{$UID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';$RoleID=176}
   C:\>$AddUserToFunctionalRole | Remove-TDFunctionalRole -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to functional role 176
   using the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Add-TDUserFunctionalRole
{
    [CmdletBinding(DefaultParameterSetName='UID')]
    Param
    (
        # User ID to add to group
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Username to add to group
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
}