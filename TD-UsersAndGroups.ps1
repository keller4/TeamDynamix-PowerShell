### Users and Groups

<#
.Synopsis
    Authenticate with TeamDynamix
.DESCRIPTION
    Authenticate with TeamDynamix using BEID or username. Sets the credentials
    for other commands to use, unless the NoUpdate option is set. If NoUpdate
    Passthru is set, returns site selection (production, sandbox, or preview),
    and a hashtable suitable for use in the header of an Invoke-RESTMethod
    call. Alias: Update-TDAuthentication.
.PARAMETER Credential
    Use PowerShell credential object (Get-Credential) for authentication.
.PARAMETER CredentialPath
    Path to stored PowerShell credential object (Get-Credential) to be used for
    authentication.
.PARAMETER GUI
    Use GUI to authenticate.
.PARAMETER NoUpdate
    Does not update credentials for the module and returns credentials to the
    command line.
.PARAMETER Passthru
    Return authentication and site information, even if NoUpdate switch is not
    used.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    No inputs on the pipeline
.OUTPUTS
    Returns a hashtable with one key: "Authorization" and value of "Bearer"
    followed by the JSON bearer web token. This hashtable is formatted
    correctly for use as a header in an Invoke-RESTMethod call to
    TeamDynamix APIs. Also returns site selection information.
.EXAMPLE
    C:\> $Credential = Get-Credential
    C:\> $Authentication = Set-TDAuthentication -Credential $Credential -NoUpdate
    C:\> $People = Invoke-RestMethod -Uri "https://api.teamdynamix.com/TDWebApi/api/people/lookup" -ContentType $ContentType -Method Get -Headers $Authentication.Authentication

    Authenticates using supplied credentials, and returns a list of user
    accounts on the system.
.EXAMPLE
    C:\> $Credential = Get-Credential
    C:\> $Authentication = Set-TDAuthentication -Credential $Credential -Passthru
    C:\> $People = Invoke-RestMethod -Uri "https://api.teamdynamix.com/TDWebApi/api/people/lookup" -ContentType $ContentType -Method Get -Headers $Authentication.Authentication

    Authenticates using supplied credentials, updates the authentication
    information for other commands to use and returns a list of user accounts
    on the system.
.EXAMPLE
    C:\> $Credential = Get-Credential
    C:\> Update-TDAuthentication -Credential $Credential

    Renews the authentication for the current PowerShell session. Useful when
    leaving a window open for more than 24 hours, which is the lifetime of
    an authentication.
.EXAMPLE
    C:\> $Credential = Get-Credential
    C:\> $CredentialObject = @{'Username' = $Credential.UserName;'Password' = (ConvertFrom-SecureString $Credential.Password)}
    C:\> $CredentialObject | Export-Clixml path\filename
    C:\> Update-TDAuthentication -CredentialPath path\filename

    Creates a file containing credentials which are retrieved later to renew
    the authentication for the current PowerShell session.
.EXAMPLE
    C:\> Update-TDAuthentication -Credential (Get-Secret -Name 'TDCredential')

    Renews the authentication for the current PowerShell session using
    credentials obtained from the vault created by the
    Mirosoft.PowerShell.SecretManagement module.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDAuthentication
{
    [CmdletBinding(DefaultParameterSetName='GUI')]
    [alias('Update-TDAuthentication')]
    [OutputType([hashtable])]
    Param
    (
        # Login via Get-Credential
        [Parameter(Mandatory=$true,
                   ParameterSetName='PSCredential')]
        [pscredential]
        $Credential,

        # Load credentials from a file
        [Parameter(Mandatory=$true,
                   ParameterSetName='CredentialPath')]
        [string]
        $CredentialPath,

        # Get credentials from a GUI form
        [Parameter(Mandatory=$true,
                   ParameterSetName='GUI')]
        [switch]
        $GUI,

        # Get credentials from command line
        [Parameter(Mandatory=$true,
                   ParameterSetName='Prompt')]
        [switch]
        $Prompt,

        # Update existing credentials for module instead of returning them to the command line
        [Parameter(Mandatory=$false,
                   ParameterSetName='PSCredential')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='CredentialPath')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='GUI')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Prompt')]
        [switch]
        $NoUpdate,

        # Return authentication information, even if Update switch is used (which would normally consume the authentication info)
        [Parameter(Mandatory=$false,
                   ParameterSetName='PSCredential')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='CredentialPath')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='GUI')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Prompt')]
        [switch]
        $Passthru,

        # Use TeamDynamix Preview site
        [Parameter(Mandatory=$false,
                   ParameterSetName='PSCredential')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='CredentialPath')]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    $ContentType = 'application/json; charset=utf-8'
    $BaseURI = Get-URI -Environment $Environment

    # Build body for web token request
    switch ($PSCmdlet.ParameterSetName)
    {
        CredentialPath
        {
            # Load credentials from a file
            if (Test-Path -PathType Leaf $CredentialPath)
            {
                try
                {
                    $CredentialObject = Import-Clixml $CredentialPath
                }
                catch
                {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'XML file failed to load: invalid credential format.'
                }
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Cannot find credential file. Provide a valid path to a .xml credential file, including the file name.'
            }
            if ($CredentialObject.Username -and $CredentialObject.Password)
            {
                try
                {
                    $Credential = New-Object System.Management.Automation.PsCredential ($CredentialObject.Username, (ConvertTo-SecureString $CredentialObject.Password))
                }
                catch
                {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Unable to create a credential object: invalid credential format.'
                }
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'XML file did not contain a username and password: invalid credential format.'
            }
            # Set site
            $AuthenticationSite = $Environment
        }
        PSCredential
        {
            # Extract credentials from PSCredential object
            if (($Credential.Username -eq '') -or ($Credential.GetNetworkCredential().Password -eq ''))
            {
                throw 'Blank username/password not allowed.'
            }
            # Set site
            $AuthenticationSite = $Environment
        }
        GUI
        {
            # Fall back to Prompt if $ModuleGUI = $false
            if ($ModuleGUI)
            {
                $AuthenticationInfo   = Get-TDGUILogin
                $AuthenticationHeader = $AuthenticationInfo.Authentication
                $AuthenticationSite   = $AuthenticationInfo.Site
            }
            else
            {
                $AuthenticationInfo   = Set-TDAuthentication -Prompt -NoUpdate
                $AuthenticationHeader = $AuthenticationInfo.Authentication
                $AuthenticationSite   = $AuthenticationInfo.Site
            }
        }
        Prompt
        {
            $Username   = Read-Host "Enter username"
            $Password   = Read-Host "Enter password" -AsSecureString
            $Credential = New-Object System.Management.Automation.PsCredential ($Username, $Password)
            $SiteSelect = Read-Host -Prompt 'Select login site: (P)roduction, (S)andbox, or p(R)eview. (Default is Production.)'
            switch ($SiteSelect)
            {
                P       {$AuthenticationSite = 'Production'}
                S       {$AuthenticationSite = 'Sandbox'}
                R       {$AuthenticationSite = 'Preview'}
                Default {$AuthenticationSite = 'Production'}
            }
        }
    }
    if (-not $GUI)
    {
        # Check to see if username contains a BEID, if so, move it to the BEID for proper processing
        if ($Credential.Username -match '^[A-Fa-f0-9]{8}-([A-Fa-f0-9]{4}-){3}[A-Fa-f0-9]{12}$')
        {
            $BEID = $true
        }
        else
        {
            $BEID = $false
        }

        # Retreive authentication token from TeamDynamix
        try
        {
            #  BEID/Web services key
            if ($BEID)
            {
                $AuthenticationBody = [TeamDynamix_Api_Auth_AdminTokenParameters]::new($Credential.Username,$Credential.GetNetworkCredential().Password)
                # Request web token
                $JSONWebToken = Invoke-RESTCall -Uri "$BaseURI/auth/loginadmin" -ContentType $ContentType -Method Post -Body ($AuthenticationBody | ConvertTo-Json -Depth 10)
            }
            # Username/password
            else
            {
                $AuthenticationBody = [TeamDynamix_Api_Auth_LoginParameters]::new($Credential.Username,$Credential.GetNetworkCredential().Password)
                # Request web token
                $JSONWebToken = Invoke-RESTCall -Uri "$BaseURI/auth/login" -ContentType $ContentType -Method Post -Body ($AuthenticationBody | ConvertTo-Json -Depth 10)
            }
        }
        catch
        {
            if ($_.Exception.Message -eq $script:TDLoginFailureText)
            {
                throw $script:TDLoginFailureText
            }
            else
            {
                throw 'Unable to authenticate to TeamDynamix. Unknown error.'
            }
        }

        # Build hashtable for use as header
        $AuthenticationHeader = @{"Authorization" = ("Bearer $JSONWebToken")}
    }

    # Update or return authentication information
    if (-not $NoUpdate)
    {
        $script:TDAuthentication = $AuthenticationHeader
        $script:LastAuthentication = Get-Date
        $Return = $null
    }
    # Return authentication information for everything but update, and always for Passthru
    if ($Passthru -or $NoUpdate)
    {
        $Return = [PSCustomObject]@{
            Authentication = $AuthenticationHeader
            Site           = $AuthenticationSite
            }
    }
    if ($Return)
    {
        return $Return
    }
}

<#
.Synopsis
   Returns the current authentication credential used for TeamDynamix
.DESCRIPTION
   Returns the current authentication credential used for TeamDynamix. All
   cmdlets will use this credential by default.
.EXAMPLE
   C:\>Get-TDAuthentication

   Return the current authentication credential used for TeamDynamix.
#>
function Get-TDAuthentication
{
    if ($TDAuthentication)
    {
        # Construct the age-of-last-authentication string
        $AuthenticationAge = (Get-Date) - $LastAuthentication
        if ($AuthenticationAge.Days -gt 0)
        {
            if ($AuthenticationAge.Days -eq 1)
            {
                $AuthenticationDays = '1 day'
            }
            else
            {
                $AuthenticationDays = "$($AuthenticationAge.Days) days"
            }
        }
        else
        {
            $AuthenticationDays = ''
        }
        if ($AuthenticationAge.Hours -gt 0)
        {
            if ($AuthenticationAge.Hours -eq 1)
            {
                $AuthenticationHours = '1 hour'
            }
            else
            {
                $AuthenticationHours = "$($AuthenticationAge.Hours) hours"
            }
        }
        else
        {
            $AuthenticationHours = ''
        }
        if ($AuthenticationAge.Minutes -gt 0)
        {
            if ($AuthenticationAge.Minutes -eq 1)
            {
                $AuthenticationMinutes = '1 minute'
            }
            else
            {
                $AuthenticationMinutes = "$($AuthenticationAge.Minutes) minutes"
            }
        }
        else
        {
            $AuthenticationMinutes = ''
        }
        $AuthenticationAgeString = ''
        if ($AuthenticationDays)
        {
            $AuthenticationAgeString += $AuthenticationDays
            if ($AuthenticationHours -or $AuthenticationMinutes)
            {
                $AuthenticationAgeString += ', '
            }
        }
        if ($AuthenticationHours)
        {
            $AuthenticationAgeString += $AuthenticationHours
            if ($AuthenticationMinutes)
            {
                $AuthenticationAgeString += ', '
            }
        }
        if ($AuthenticationMinutes)
        {
            $AuthenticationAgeString += $AuthenticationMinutes
        }
        if ($AuthenticationAgeString -eq '')
        {
            $AuthenticationAgeString = 'Less than one minute'
        }

        $Return = @{
            ($TDAuthentication.Keys[0] | Out-String).Trim() = ($TDAuthentication[$TDAuthentication.Keys[0]] | Out-String).Trim()
            Created = $LastAuthentication
            Age     = $AuthenticationAgeString
            Site    = $WorkingEnvironment
        }
    }
    Write-Output $Return
}

<#
.Synopsis
    Get current authenticated user in TeamDynamix
.DESCRIPTION
    Get the current authenticated user in TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.OUTPUTS
    Returns a TeamDynamix user as documented in TeamDynamix.Api.Users.User.
.EXAMPLE
    C:\> Get-TDCurrentUser -AuthenticationToken $Authentication

    Returns the user information for the current logged in user.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDCurrentUser
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

    Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    $ContentType = 'application/json; charset=utf-8'
    $BaseURI = Get-URI -Environment $Environment
    if (-not $AuthenticationToken)
    {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
    }

    $Return = [TeamDynamix_Api_Users_User]::new((Invoke-RESTCall -Uri "$BaseURI/auth/getuser" -ContentType $ContentType -Method Get -Headers $AuthenticationToken))
    return $Return
}

<#
.Synopsis
    Get a user account from TeamDynamix
.DESCRIPTION
    Gets a specific user, or searches for matching users, from TeamDynamix.
    Search by UID or use the -filter option to match on a substring from:
        Full name
        Username (for TeamDynamix users)
        External ID
        Alternate ID
    Searching by UID returns full detail on the account. Searching with Filter
    returns less detail on the account. Use the -IsEmployee and -IsActive
    options to restrict results to employees and active user acounts.
    Use the -Fast switch to return minimal account detail on up to 100
    accounts at a time (default 50). Much faster for multiple queries.
.PARAMETER UID
    UID of the user to be retrieved. Returns full account detail. Available on
    the pipeline.
.PARAMETER SearchText
    Substring search filter, or leave blank for all accounts. Returns limited
    account detail.
.PARAMETER UserName
    Return users with the exactly specified username. No partial matches.
.PARAMETER IsActive
    Boolean to limit return set to active users ($true), or inactive users
    ($false), or all users ($null). Default is active users.
.PARAMETER IsConfidential
    Boolean to limit return set to users flagged as confidential ($true) or
    not confidential ($false), or all users ($null). Default is
    non-confidential users.
.PARAMETER IsEmployee
    Boolean to limit return set to employees ($true), or non-employees
    ($false).
.PARAMETER AppName
    Return users who have been granted access to the application.
.PARAMETER AccountIDs
    Return users who are in one of the specified account IDs.
.PARAMETER ReferenceID
    Return users holding one of the specified reference IDs.
.PARAMETER ExternalID
    Return users with the specified external ID.
.PARAMETER AlternateID
    Return users with the specified alternate ID.
.PARAMETER UserName
    Return users with the exactly specified username. No partial matches.
.PARAMETER SecurityRoleID
    Return users holding the specified Security Role ID.
.PARAMETER Detail
    Return full detail for user.
.PARAMETER Fast
    Use with -Filter to return minimal detail on up to 100 accounts at a time
    (default 50 at a time). Much faster for multiple queries.
.PARAMETER MaxResults
    Limit return set to a number between 1 and 100.
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
    TeamDynamix.Api.Users.User.
.EXAMPLE
   C:\>Get-TDUser -AuthenticationToken $Authentication

   Returns a list of all active users, with abbreviated user property
   information.
.EXAMPLE
   C:\>Get-TDUser -filter smith -AuthenticationToken $Authentication -MaxResults 2

   Returns full user information on two active users with "smith" in the full
   name, the username, or the external/internal ID.
.EXAMPLE
   C:\>Get-TDUser -filter smith -AuthenticationToken $Authentication -IsActive $false

   Returns full user information on inactive users with "smith" in the full
   name, the username, or the external/internal ID.
.EXAMPLE
   C:\>Get-TDUser -filter smith -AuthenticationToken $Authentication -IsActive $null

   Returns full user information on all users with "smith" in the full name,
   the username, or the external/internal ID.
.EXAMPLE
   C:\>Get-TDUser -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX $Authentication

   Returns full user information on user with specified UID.
.EXAMPLE
   C:\>'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY' | Get-TDUser $Authentication

   Returns full user information on users with UIDs specified in the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDUser
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # UID of user to return
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [guid]
        $UID,

        # Filter text, substring
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false,
                   Position=0)]
        [Parameter(ParameterSetName='Fast',
                   Mandatory=$false,
                   Position=0)]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Return users with the exactly specified username
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [string]
        $UserName,

        # Return full detail on user
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [switch]
        $Detail,

        # Return active users
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive = $false,

        # Return active users
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsConfidential = $false,

        # Return employees
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsEmployee,

        # Return users in the specified accounts
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int[]]
        $AccountIDs,

        # Return users with specified reference IDs
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int[]]
        $ReferenceID,

        # Return users with specified external ID
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [string]
        $ExternalID,

        # Return users with specified Alternate ID
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [string]
        $AlternateID,

        # Return users holding specified Security Role ID
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [guid]
        $SecurityRoleID,

        # Return faster, but with less account detail
        [Parameter(Parametersetname='Fast',
                   Mandatory=$false)]
        [switch]
        $Fast,

        # Maximum results to return
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [Parameter(Parametersetname='Fast',
                   Mandatory=$false)]
        [ValidateRange(1,100)]
        [int]
        $MaxResults,

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
                Name             = 'AppName'
                Type             = 'string'
                ValidateSet      = $TDApplications.Name
                HelpText         = 'Return users who have been granted access to the application'
                ParameterSetName = 'Search'
                IDParameter      = 'AppID'
                IDsMethod        = '$TDApplications'
            }
            @{
                Name             = 'AccountNames'
                ValidateSet      = $TDAccounts.Name
                HelpText         = 'Names of departments'
                ParameterSetName = 'Search'
                IDParameter      = 'AccountID'
                IDsMethod        = '$TDAccounts'
            }
            @{
                Name             = 'SecurityRoleName'
                Type             = 'string'
                ValidateSet      = $TDSecurityRoles.Name
                HelpText         = 'Name of security role'
                ParameterSetName = 'Search'
                IDParameter      = 'SecurityRoleID'
                IDsMethod        = '$TDSecurityRoles'
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
    }

    Process
    {
        if (-not ($pscmdlet.ParameterSetName -eq 'Fast'))
        {
            $InvokeParams = [pscustomobject]@{
                # Configurable parameters
                SearchType       = 'TeamDynamix_Api_Users_UserSearch'
                ReturnType       = 'TeamDynamix_Api_Users_User'
                AllEndpoint      = $null
                SearchEndpoint   = "people/search"
                IDEndpoint       = "people/$UID"
                AppID            = $null
                DynamicParameterDictionary = $DynamicParameterDictionary
                DynamicParameterList       = $DynamicParameterList
                # Fixed parameters
                ParameterSetName    = $pscmdlet.ParameterSetName
                BoundParameters     = $MyInvocation.BoundParameters.Keys
                Environment         = $Environment
                AuthenticationToken = $AuthenticationToken
            }
            $Return = $InvokeParams | Invoke-Get
        }
        else
        {
            # Fast
            if (-not $MaxResults)
            {
                $MaxResults = 50
            }
            $Return = Invoke-RESTCall -Uri "$BaseURI/people/lookup?searchText=$SearchText&maxResults=$MaxResults" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            if ($Return)
            {
                $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_User]::new($_)})
            }
        }
        if ($Detail)
        {
            $Return = Get-TDUser -UID $Return.UID -AuthenticationToken $AuthenticationToken -Environment $Environment
        }
        return $Return
    }
}

<#
.Synopsis
    Get a department (account) from TeamDynamix
.DESCRIPTION
    Gets a specific department, or searches for matching departments from
    TeamDynamix. Note that departments are also called accounts, and should
    not be confused with users. Search using a substring of the desired
    department.
.PARAMETER ID
    ID of department to retrieve.
.PARAMETER SearchText
    Substring search filter. Default returns all accounts.
.PARAMETER ManagerUIDs
    Filter on the specified UIDs of department managers.
.PARAMETER CustomAttributes
    Filter on the specified custom attributes.
.PARAMETER IsActive
    Filter on Active status. Default uses $Null to return all.
.PARAMETER MaxResults
    Sets maximum number of records to return.
.PARAMETER Detail
    Return full detail for departments. Default searches return partial detail.
.PARAMETER Exact
    Return only the department that exactly matches the name (SearchText).
    Searches that don't include SearchText will ignore this setting.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.PARAMETER MaxResults
    Limit return set to specified number.
.PARAMETER ParentAccountID
    Filter on the department's parent department's ID number.
.PARAMETER ParentAccountName
    Filter on the department's parent department's name.
.INPUTS
    String, or array of strings, containing UIDs.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Accounts.Account.
.EXAMPLE
   C:\>Get-TDDepartment -Filter * -AuthenticationToken $Authentication

   Returns a list of all departments, with abbreviated user property
   information.
.EXAMPLE
   C:\>Get-TDDepartment -Filter Studies -AuthenticationToken $Authentication -MaxResults 2

   Returns full department information on two accounts with "studies" in the
   full name.
.EXAMPLE
   C:\>'com', 'studies' | Get-TDDepartment -AuthenticationToken $Authentication

   Returns full department information on accounts with names specified in the
   pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDDepartment
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    [Alias('Get-TDAccount')]
    Param
    (
        # Department ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Filter text, substring
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='Search')]
        [ValidateLength(1,50)]
        [alias('Filter')]
        [string]
        $SearchText,

        # Department managers filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid[]]
        $ManagerUIDs,

        # Custom attributes filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [array]
        $CustomAttributes,

        # Active status filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Maximum records to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [ValidateRange(0,[int32]::MaxValue)]
        [System.Nullable[int]]
        $MaxResults,

        # Parent account ID filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[int]]
        $ParentAccountID,

        # Return detailed information on account
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

        # Return only exact matches on account search
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
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
                Name             = 'ParentAccountName'
                Type             = 'string'
                ValidateSet      = $TDAccounts.Name
                HelpText         = 'Name of parent department'
                ParameterSetName = 'Search'
                IDParameter      = 'ParentAccountID'
                IDsMethod        = '$TDAccounts'
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
    }

    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'ID'
            {
                if ($ID)
                {
                    $Return = Invoke-RESTCall -Uri "$BaseURI/accounts/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    $Return = Invoke-RESTCall -Uri "$BaseURI/accounts" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
            }
            'Search'
            {
                $Query = [TeamDynamix_Api_Accounts_AccountSearch]::new($SearchText,$ManagerUIDs,$CustomAttributes,$IsActive,$MaxResults,$ParentAccountID,$ParentAccountName)
                $Return = Invoke-RESTCall -Uri "$BaseURI/accounts/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
            }
        }
        # Local modifications to return set

        if ($Return)
        {
            if ($Exact)
            {
                if (-not [string]::IsNullOrWhiteSpace($SearchText))
                {
                    $Return = $Return | Where-Object Name -eq $SearchText
                }
            }
            if ($Detail)
            {
                if ($Return)
                {
                    $Return = $Return.ID | Get-TDDepartment -AuthenticationToken $AuthenticationToken -Environment $Environment
                }
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Accounts_Account]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Creates a new department (account) in TeamDynamix
.DESCRIPTION
    Creates a new department (account) in TeamDynamix. Also accepts an object
    on the pipeline that contains all the department information.
.PARAMETER Name
    Name of the department.
.PARAMETER ParentID
    ID of the parent department, to which this department belongs. Default is
    no parent (null).
.PARAMETER IsActive
    Is the department active.
.PARAMETER Address1
    First address line for the deparment.
.PARAMETER Address2
    Second address line for the deparment.
.PARAMETER Address3
    Third address line for the deparment.
.PARAMETER Address4
    Fourth address line for the deparment.
.PARAMETER ExternalID
    External ID of the department.
.PARAMETER City
    City of the department.
.PARAMETER StateName
    State (as in, mailing address) of the department.
.PARAMETER StateAbbr
    State (as in, mailing address) abbreviation of the department.
.PARAMETER PostalCode
    Postal code of the department.
.PARAMETER Country
    Country of the department.
.PARAMETER Phone
    Phone number for the department.
.PARAMETER Fax
    Fax number for the department.
.PARAMETER URL
    URL for the department.
.PARAMETER Notes
    Notes for the department.
.PARAMETER Code
    Code for the department.
.PARAMETER IndustryID
    IndustryID for the department.
.PARAMETER ManagerUID
    UID of the manager for the department.
.PARAMETER Attributes
    Custom attributes associated with the department.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDDepartment -Name 'Psychobotany' -AuthenticationToken $Authentication

    Creates a new department named, "Psychobotany" in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function New-TDDepartment
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Department name to create in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Department parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $ParentID = $null,

        # Active department
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Department address line 1
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address1,

        # Department address line 2
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address2,

        # Department address line 3
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address3,

        # Department address line 4
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address4,

        # Department city
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $City,

        # Department state name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $StateName,

        # Department state abbreviation
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $StateAbbr,

        # Department postal code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PostalCode,

        # Department country
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Country,

        # Department phone number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Phone,

        # Department fax number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Fax,

        # Department URL
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $URL,

        # Department notes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Notes,

        # Department code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Code,

        # Department industry ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $IndustryID,

        # UID of department manager
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $ManagerUID = [guid]::Empty,

        # Custom attributes for department
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
        $LocalIgnoreParameters = @()
    }
    Process
    {
        $TDDepartment = [TeamDynamix_Api_Accounts_Account]::new()
        Update-Object -InputObject $TDDepartment -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($TDDepartment | Out-String), 'Creating new department'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/accounts" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDDepartment -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Accounts_Account]::new($_)
            }
            return $Return
        }
    }
}

<#
.Synopsis
    Edits department (account) in TeamDynamix
.DESCRIPTION
    Edits a department (account) in TeamDynamix. Also accepts an object
    on the pipeline that contains all the department information.
.PARAMETER ID
    ID of the department to be edited in TeamDynamix.
.PARAMETER Name
    New name for the department.
.PARAMETER ParentID
    ID of the parent department, to which this department belongs. Default is
    no parent (null).
.PARAMETER IsActive
    Is the department active.
.PARAMETER Address1
    First address line for the deparment.
.PARAMETER Address2
    Second address line for the deparment.
.PARAMETER Address3
    Third address line for the deparment.
.PARAMETER Address4
    Fourth address line for the deparment.
.PARAMETER ExternalID
    External ID of the department.
.PARAMETER City
    City of the department.
.PARAMETER StateName
    State (as in, mailing address) of the department.
.PARAMETER StateAbbr
    State (as in, mailing address) abbreviation of the department.
.PARAMETER PostalCode
    Postal code of the department.
.PARAMETER Country
    Country of the department.
.PARAMETER Phone
    Phone number for the department.
.PARAMETER Fax
    Fax number for the department.
.PARAMETER URL
    URL for the department.
.PARAMETER Notes
    Notes for the department.
.PARAMETER Code
    Code for the department.
.PARAMETER IndustryID
    IndustryID for the department.
.PARAMETER Domain
    Domain for the department.
.PARAMETER ManagerUID
    UID of the manager for the department.
.PARAMETER Attributes
    Custom attributes associated with the department.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDDepartment -ID 4432 -Name 'Psychobotany' -AuthenticationToken $Authentication

    Changes the name of department ID 4432 to 'Psychobotany' in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDDepartment
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='ID')]
    Param
    (
        # Department ID to edit in TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID',
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Department name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Department parent ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $ParentID,

        # Active department
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Department address line 1
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address1,

        # Department address line 2
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address2,

        # Department address line 3
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address3,

        # Department address line 4
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Address4,

        # Department city
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $City,

        # Department state name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $StateName,

        # Department state abbreviation
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $StateAbbr,

        # Department postal code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PostalCode,

        # Department country
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Country,

        # Department phone number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Phone,

        # Department fax number
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Fax,

        # Department URL
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $URL,

        # Department notes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Notes,

        # Department code
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Code,

        # Department industry ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $IndustryID,

        # UID of department manager
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $ManagerUID = [guid]::Empty,

        # Custom attributes for department
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
    DynamicParam
    {
        #List dynamic parameters
		$DynamicParameterList = @(
			@{
				Name             = 'DepartmentName'
                Type             = 'string'
				ValidateSet      = $TDAccounts.Name
				HelpText         = 'Name of department to edit'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'ID'
                IDsMethod        = '$TDAccounts'
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
            RetrievalCommand = "Get-TDDepartment -ID `$ID"
            ObjectType = 'TeamDynamix_Api_Accounts_Account'
            Endpoint   = "accounts/`$ID"
            Method     = 'Put'
            AppID      = $null
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
}

<#
.Synopsis
    Get a group from TeamDynamix
.DESCRIPTION
    Gets a specific group, or searches for matching groups from
    TeamDynamix. Search using a substring of the desired group.
    Because the search uses a substring, be aware that the function may
    return more than one result.
    Use the -IsActive parameter to limit search to active or inactive groups.
.PARAMETER ID
    ID of the group to retrieve from TeamDynamix.
.PARAMETER NameLike
    Substring search filter, or omit parameter for all groups. Alias: "Filter".
.PARAMETER HasAppID
    Application to filter on. If specified, will only include groups
    with at least one active member who has been granted access to this
    application.
.PARAMETER HasSystemAppName
    System application to filter on. If specified, will only include groups
    with at least one active member who has been granted access to this
    application.
.PARAMETER AssociatedAppID
    The ID of an associated application to filter on. If specified, will only
    include groups that have an application association with the specified
    plaform application.
.PARAMETER IsActive
    Restrict search to active or inactive groups. By default, all groups are
    searched.
.PARAMETER Detail
    Return full detail for groups. Default searches return partial detail.
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
   C:\>Get-TDGroup -AuthenticationToken $Authentication

   Returns a list of all groups.
.EXAMPLE
   C:\>Get-TDGroup -IsActive $true -AuthenticationToken $Authentication

   Returns a list of all groups.
.EXAMPLE
   C:\>Get-TDGroup -Filter Studies -AuthenticationToken $Authentication

   Returns full group information on groups with "studies" in the name.
.EXAMPLE
   C:\>'com', 'studies' | Get-TDGroup -AuthenticationToken $Authentication

   Returns full group information on groups with "com" or "studies" in
   the name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDGroup
{
    [CmdletBinding(DefaultParameterSetName='Search')]
    Param
    (
        # Department ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='ID')]
        [int]
        $ID,

        # Search text, substring
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='Search')]
        [ValidateScript({$_.length -le 50})]
        [alias('Filter')]
        [string]
        $NameLike,

        # Search inactive groups
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsActive,

        # Search app ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[int]]
        $HasAppID,

        # Search system app name
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $HasSystemAppName,

        # Search associated app ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[int]]
        $AssociatedAppID,

        # Return detailed information on group
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
        switch ($PSCmdlet.ParameterSetName)
        {
            'ID'
            {
                $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            'Search'
            {
                $Query = [TeamDynamix_Api_Users_GroupSearch]::new()
                Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                $Return = Invoke-RESTCall -Uri "$BaseURI/groups/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
            }
        }
        if ($Return)
        {
            # Return only exact match to NameLike
            if ($Exact)
            {
                $Return = $Return | Where-Object Name -eq $NameLike
            }
            if ($Detail)
            {
                if ($Return)
                {
                    $Return = $Return.ID | ForEach-Object {Get-TDGroup -ID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}
                }
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_Group]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Creates a new group in TeamDynamix
.DESCRIPTION
    Creates a new group in TeamDynamix. Also accepts an object
    on the pipeline that contains all the group information.
.PARAMETER Name
    Name of the group.
.PARAMETER IsActive
    Is the group active.
.PARAMETER Description
    Description of the group.
.PARAMETER ExternalID
    External ID of the group.
.PARAMETER PlatformApplications
    Platform applications for group. Use New-TDGroupApplication to create the
    items to add.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDGroup -Name 'Psychobotany Support' -AuthenticationToken $Authentication

    Creates a new group named, "Psychobotany Support", in TeamDynamix.
.EXAMPLE
    C:\>$GroupApplication1 = New-TDGroupApplication -AppID 243
    C:\>$GroupApplication2 = New-TDGroupApplication -AppID 529
    C:\>New-TDGroup -Name 'Psychobotany Support' -PlatformApplications @($GroupApplication1, $GroupApplication2) -AuthenticationToken $Authentication

    Creates a new group named, "Psychobotany Support", with platform applications 243 and 529 assigned in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function New-TDGroup
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Group name to create in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Active group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Description of group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # External ID of group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Applications assigned to group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Users_GroupApplication[]]
        $PlatformApplications,

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
        $TDGroup = [TeamDynamix_Api_Users_Group]::new()
        Update-Object -InputObject $TDGroup -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($TDGroup | Out-String), 'Creating new group'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/groups" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDGroup -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Users_Group]::new($_)
            }
            return $Return
        }
    }
}

<#
.Synopsis
    Edits group in TeamDynamix
.DESCRIPTION
    Edits a user group in TeamDynamix. Also accepts an object
    on the pipeline that contains all the group information.
.PARAMETER ID
    ID of the group to be edited in TeamDynamix.
.PARAMETER Name
    Name of the group.
.PARAMETER IsActive
    Is the group active.
.PARAMETER Description
    Description of the group.
.PARAMETER ExternalID
    External ID of the group.
.PARAMETER PlatformApplications
    Platform applications for group. Use New-TDGroupApplication to create the
    items to add.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDGroup -ID 3528 -Name 'Psychobotany Support' -AuthenticationToken $Authentication

    Changes the name of group ID 4432 to "Psychobotany Support" in TeamDynamix.
.EXAMPLE
    C:\>$GroupApplication1 = New-TDGroupApplication -AppID 243
    C:\>$GroupApplication2 = New-TDGroupApplication -AppID 529
    C:\>Set-TDGroup -ID 3528 -PlatformApplications @($GroupApplication1, $GroupApplication2) -AuthenticationToken $Authentication

    Sets the platform applications, ID 243 and 529, for group ID 3528.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDGroup
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='ID')]
    Param
    (
        # Group ID to edit in TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID',
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Group name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Active group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Description of group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # External ID of group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

        # Applications assigned to group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Users_GroupApplication[]]
        $PlatformApplications,

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
				Name             = 'GroupName'
                Type             = 'string'
				ValidateSet      = $TDGroups.Name
				HelpText         = 'Name of group to edit'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'ID'
                IDsMethod        = '$TDGroups'
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
            RetrievalCommand = "Get-TDGroup -ID `$ID"
            ObjectType = 'TeamDynamix_Api_Users_Group'
            Endpoint   = "groups/`$ID"
            Method     = 'Put'
            AppID      = $null
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-New
        return $Return
    }
}

<#
.Synopsis
    Get a list of groups for a user from TeamDynamix
.DESCRIPTION
    Gets a the group membership of the specified user in TeamDynamix. User is
    specified by UID.
.PARAMETER UID
    User ID to examine for group membership.
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
   C:\>Get-TDUserGroupMember -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

   Returns a list of groups for user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.
.EXAMPLE
   C:\>'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY' | Get-TDUserGroupMember -AuthenticationToken $Authentication

   Returns a list of groups for user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>

function Get-TDUserGroupMember
{
    [CmdletBinding()]
    Param
    (
        # User ID to examine
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
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
        $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/groups" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_UserGroup]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Removes user, or users, from a group in TeamDynamix
.DESCRIPTION
    Removes the user(s) from the specified group in TeamDynamix. Users
    are specified by UID. The group is specified by the group's GroupID.
.PARAMETER UID
    User ID to be removed from group.
.PARAMETER UIDs
    User IDs to be removed from group.
.PARAMETER GroupID
    User(s) are to be removed from the group with this GroupID.
.PARAMETER Bulk
    Remove users from group in bulk.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    PowerShell object with String containing UID and integer containing group
    ID.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Users.UserGroup.
.EXAMPLE
   C:\>Remove-TDGroupMember -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -GroupID YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY -AuthenticationToken $Authentication

   Removes user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from group YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY.
.EXAMPLE
   C:\>$RemoveUserFromGroup = @{$UID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';$GID='YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY'}
   C:\>$RemoveUserFromGroup | Remove-TDGroupMember -AuthenticationToken $Authentication

   Removes user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from group YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY using the pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Remove-TDGroupMember
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # User ID to remove from group
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='Non-bulk')]
        [guid]
        $UID,

        # User IDs to remove from group
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='Bulk')]
        [guid[]]
        $UIDs,

        # Group ID that user will be removed from
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='Non-bulk')]
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='Bulk')]
        [int]
        $GroupID,

        # Remove users from group in bulk
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [switch]
        $Bulk,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # Use TeamDynamix Preview API
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [EnvironmentChoices]
        $Environment
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
            'Non-bulk'
            {
                if ($pscmdlet.ShouldProcess($UID, "Remove user from group, $GroupID"))
                {
                    Write-ActivityHistory "Removing user, $UID, from group, $GroupID, in TeamDynamix"
                    $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/groups/$GroupID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
                }
            }
            'Bulk'
            {
                if ($pscmdlet.ShouldProcess($UIDs, "Remove user from group, $GroupID"))
                {
                    Write-ActivityHistory "Removing users, $UIDs, from group, $GroupID, in TeamDynamix"
                    $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$GroupID/members" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken -Body (ConvertTo-Json $UIDs -Depth 10)
                }
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Adds a user, or users, to a group in TeamDynamix
.DESCRIPTION
    Adds the specified user(s) to the specified group in TeamDynamix.
    Users are specified by UID. The group is specified by the group's GroupID.
.PARAMETER UID
    User ID for user to be added to group.
.PARAMETER UIDs
    User IDs for users to be added to group, in bulk. Existing group members
    are not modified.
.PARAMETER GroupID
    Group ID for group user is to be added to.
.PARAMETER Bulk
    Perform add as bulk addition for multiple User IDs at once.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded..INPUTS
    String, or array of strings, containing UIDs.
.INPUTS
    PowerShell object with String containing UID and integer containing group
    ID.
.OUTPUTS
    Message indicating success.
.EXAMPLE
   C:\>Add-TDGroupMember -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -GroupID YYYY -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to group YYYY.
.EXAMPLE
   C:\>Add-TDGroupMember -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -GroupID YYYY -IsPrimary -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to group YYYY and makes
   group YYYY the primary group for the user.
.EXAMPLE
   C:\>$AddUserToGroup = @{$UID='XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX';$GID='YYYY'}
   C:\>$AddUserToGroup | Remove-TDGroupMember -AuthenticationToken $Authentication

   Adds user XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to group YYYY using the
   pipeline.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Add-TDGroupMember
{
    [CmdletBinding()]
    Param
    (
        # User ID to add to group
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='Non-bulk')]
        [guid]
        $UID,

        # User IDs to add to group (bulk processing)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0,
                   ParameterSetName='Bulk')]
        [guid[]]
        $UIDs,

        # Group ID that user will be added to
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1,
                   ParameterSetName='Non-bulk')]
        [int]
        $GroupID,

        # Set group to be user's primary group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [switch]
        $IsPrimary,

        # Set user to be notified with the group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [switch]
        $IsNotified,

        # Set user to be a manager of the group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [switch]
        $IsManager,

        # Set user to be a manager of the group
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [switch]
        $Bulk,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # Use TeamDynamix Preview API
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Bulk')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Non-bulk')]
        [EnvironmentChoices]
        $Environment
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
            'Non-bulk'
            {
                Write-ActivityHistory "Adding user, $UID, to group, $GroupID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/groups/$($GroupID)?isPrimary=$($IsPrimary.IsPresent)&isNotified=$($IsNotified.IsPresent)&isManager=$($IsManager.IsPresent)" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
            }
            'Bulk'
            {
                Write-ActivityHistory "Bulk adding users, $UIDs, to group, $GroupID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$($GroupID)/members?isPrimary=$($IsPrimary.IsPresent)&isNotified=$($IsNotified.IsPresent)&isManager=$($IsManager.IsPresent)" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $UIDs -Depth 10)
            }
        }
        return $Return
    }
}

<#
.Synopsis
    Get list of members of a group from TeamDynamix
.DESCRIPTION
    Gets a list of members belonging to a group from TeamDynamix. The group
    is identified by the group ID number.
.PARAMETER GroupID
    The group ID number, used to identify the group.
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
    TeamDynamix.Api.Users.GroupMember.
.EXAMPLE
   C:\>Get-TDGroupMember -GroupID 1234 -AuthenticationToken $Authentication

   Returns a list of all members in group ID 1234.
.EXAMPLE
   C:\>$Groups = Get-TDGroup -Filter MyGroupNames -AuthenticationToken $Authentication
   C:\>$Groups | Get-TDGroupMember -AuthenticationToken $Authentication

   Returns list of all members in all groups with 'MyGroupNames' in the name.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDGroupMember
{
    [CmdletBinding()]
    Param
    (
        # Group ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID',
                   Position=0)]
        [Alias("ID")]
        [int]$GroupID,

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
				Name             = 'GroupName'
                Type             = 'string'
				ValidateSet      = $TDGroups.Name
				HelpText         = 'Name of group'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_Users_GroupMember'
            AllEndpoint      = $null
            SearchEndpoint   = $null
            IDEndpoint       = 'groups/$GroupID/members'
            AppID            = $null
            DynamicParameterDictionary = $DynamicParameterDictionary
            DynamicParameterList       = $DynamicParameterList
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-Get
        return $Return
    }
}

<#
.Synopsis
    Create a new user account in TeamDynamix
.DESCRIPTION
    Create a new user account in TeamDynamix. Accepts information about the
    new user via pipeline or commandline. If user already exists and account is
    active, no action is taken. If user already exists and account is inactive,
    account is reactivated and updated with any additional information
    supplied.
.PARAMETER Username
    Username of the new user account.
.PARAMETER Password
    Password for user account. Required.
.PARAMETER FirstName
    First name for user account. Required.
.PARAMETER MiddleName
    Middle name for user account.
.PARAMETER LastName
    Last name for user account. Required.
.PARAMETER PrimaryEmail
    Primary email address for user account. Required.
.PARAMETER AlertEmail
    Alert email address for user acccount. Required.
.PARAMETER AlternateEmail
    Alternate email address for user account.
.PARAMETER AlternateID
    Employee ID (alternate ID) for user account.
.PARAMETER SecurityRoleID
    Security role (specified by ID number) for user account.
.PARAMETER Applications
    Applications list for user account.
.PARAMETER OrgApplications
    New organizationally-defined applications for user account. Use
    New-TDUserApplication to create the individual applications. For more than
    one, specify as an array.
.PARAMETER PrimaryClientPortalApplicationID
    Client portal application for user account. Leave blank to use the default.
.PARAMETER DefaultAccountID
    Department (also known as "account", specified by ID number) for
    user account.
.PARAMETER GroupIDs
    List of groups (specified by ID number) for user account.
.PARAMETER Company
    Company name for user account. Required.
.PARAMETER Title
    Title for user account.
.PARAMETER WorkPhone
    Work phone number for user account.
.PARAMETER PrimaryPhone
    Primary phone location (work, home, mobile, etc...) for user account.
.PARAMETER WorkAddress
    Work address for user account.
.PARAMETER WorkCity
    Work city for user account.
.PARAMETER WorkState
    Work state for user account.
.PARAMETER WorkZip
    Work zip for user account.
.PARAMETER LocationID
    Location (building) ID for user account.
.PARAMETER LocationRoomID
    Room ID for user account.
.PARAMETER TypeName
    Account type name.
.PARAMETER IsEmployee
    Employee status for user account.
.PARAMETER Attributes
    New custom attributes for user account. Replaces existing custom
    attributes. Specify as an array.
.PARAMETER IsActive
    Specify whether the user is active or not. Default is active.
.PARAMETER IsConfidential
    Specify whether the user is confidential or not. Default is not
    confidential.
.PARAMETER Passthru
    Return newly created user object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Settings may be passed down the pipeline by name.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Users.User.
.EXAMPLE
    C:\>$ApplicationList = @('MyWork','TDAssets','TDChat','TDCommunity','TDKnowledgeBase','TDNews','TDNext','TDPeople','TDQuestions','TDRequests','TDTicketRequests','TDTickets')
    C:\>$SecurityRoleIDTechnician  = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'
    C:\>$TicketsApp = New-TDUserApplication -SecurityRoleID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -IsAdministrator $true
    C:\>$AssetCIApp = New-TDUserApplication -SecurityRoleID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -IsAdministrator $true
    C:\>'user1','user2','user3','user4' |
     ConvertFrom-ADtoTDUser -AuthenticationToken $Authentication -ADDomainName $ADDomainName -ADCredentials $ADCredential |
     New-TDUser -SecurityRoleID $SecurityRoleIDTechnician -Applications $ApplicationList -OrgApplications @($TicketsApp,$AssetCIApp) -AuthenticationToken $Authentication

     Takes user1, user2, user3, and user 4, looks them up in the AD, converts
     their information to TD format, then creates new technician accounts on
     TeamDynamix, with the desired list of applications and org applications.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function New-TDUser
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Username of new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Username,

        # Password of new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Password,

        # First name of new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $FirstName,

        # Middle name of new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $MiddleName,

        # Last name of new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LastName,

        # Primary email for new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PrimaryEmail,

        # Alert email (typically same as primary email) address for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlertEmail,

        # Alternate email for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlternateEmail,

        # Alternate ID (Employee ID) for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlternateID,

        # Security role ID (from TeamDynamix) for new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $SecurityRoleID,

        # Applications for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Applications,

        # Applications for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array[]]
        $OrgApplications,

        # Client portal application for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $PrimaryClientPortalApplicationID,

        # Default account ID (department ID from TeamDynamix) for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $DefaultAccountID,

        # Group IDs (from TeamDynamix) for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int[]]
        $GroupIDs,

        # Company name (OSU unit name) for new user
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Company,

        # Work title for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        # Work phone number for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkPhone,

        # Primary phone (work, home, etc...) for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PrimaryPhone,

        # Work address for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkAddress,

        # Work city for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkCity,

        # Work state for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkState,

        # Work postal code for new user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkZip,

        # Location (building) ID for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Room ID for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Is user an employee
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsEmployee = $true,

        # User type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Users_UserType]
        $TypeID = 'User',

        # Is user account active
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive = $true,

        # Is user account active
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsConfidential,

        # Custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Return an object
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
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
        #   Ignore LocationID and LocationRoomID because TeamDynamix_Api_Users_NewUser doesn't support it - set location after user is created
        $LocalIgnoreParameters = @('LocationID','LocationRoomID')
    }
    Process
    {
        Write-ActivityHistory "Adding user $UserName"

        if ($Password -eq '')
        {
            $Password = New-SimplePassword
        }
        $NewTDUser = [TeamDynamix_Api_Users_NewUser]::new()
        Update-Object -InputObject $NewTDUser -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        $ExistUser = $false
        # Check to see if user exists
        # Include both active and inactive users.
        $ExistUser = Get-TDUser -UserName $Username -IsActive $null -AuthenticationToken $AuthenticationToken -Environment $Environment
        if (-not $ExistUser)
        {
            if ($pscmdlet.ShouldProcess($Username, 'Create new TeamDynamix user'))
            {
                Write-ActivityHistory 'New user'
                $Return = Invoke-RESTCall -Uri "$BaseURI/people" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewTDUser -Depth 10)
                if ($Return)
                {
                    $Return = [TeamDynamix_Api_Users_User]::new($Return)
                    # Fix room and building, since the new user call doesn't support it
                    if ($LocationID -or $LocationRoomID)
                    {
                        $Return.LocationID     = $LocationID
                        $Return.LocationRoomID = $LocationRoomID
                        $Return = $Return | Set-TDUser -AuthenticationToken $AuthenticationToken -Environment $Environment -Passthru
                    }
                }
                if ($Passthru)
                {
                    Write-Output $Return
                }
            }
        }
        elseif (-not $ExistUser.IsActive)
        {
            if ($pscmdlet.ShouldProcess($Username, 'Activate and update inactive TeamDynamix user'))
            {
                Write-ActivityHistory 'Reactivate user'
                #Ensure user is active
                $NewTDUser.IsActive = $true
                $Return = $NewTDUser | Set-TDUser -Passthru -AuthenticationToken $AuthenticationToken -Environment $Environment -Confirm:$false
                if ($Passthru)
                {
                    Write-Output $Return
                }
            }
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Active user $Username already exists in TeamDynamix"
        }
    }
}

<#
.Synopsis
    Sets properties of an existing user account in TeamDynamix.
.DESCRIPTION
    Sets properties of an existing user account in TeamDynamix. Specify user
    by username or UID. Note that username is found via Get-TDUser and is a
    substring search. Some queries may return multiple results. In such cases
    use the UID to ensure a unique selection.
.PARAMETER UID
    User ID (UID) of the user account to change. Only used to select account.
    Not writeable.
.PARAMETER Username
    Username of the user account to change. Only used to select account. Not
    writeable.
.PARAMETER IsActive
    Sets whether the account is active or inactive.
.PARAMETER FirstName
    New first name for user account.
.PARAMETER MiddleName
    New middle name for user account.
.PARAMETER LastName
    New last name for user account.
.PARAMETER PrimaryEmail
    New primary email address for user account.
.PARAMETER AlertEmail
    New alert email address for user acccount.
.PARAMETER AlternateEmail
    Alternate email address for user account.
.PARAMETER AlternateID
    New employee ID (alternate ID) for user account.
.PARAMETER SecurityRoleID
    New security role (specified by ID number) for user account.
.PARAMETER Applications
    New applications list for user account.
.PARAMETER OrgApplications
    New organizationally-defined applications for user account. Use
    New-TDUserApplication to create the individual applications. For more than
    one, specify as an array.
.PARAMETER PrimaryClientPortalApplicationID
    Client portal application for user account. Use null to specify the
    systemwide default.
.PARAMETER DefaultAccountID
    New department (also known as "account", specified by ID number) for
    user account.
.PARAMETER GroupIDs
    New list of groups (specified by ID number) for user account.
.PARAMETER Company
    New company name for user account.
.PARAMETER Title
    New title for user account.
.PARAMETER WorkPhone
    New work phone number for user account.
.PARAMETER PrimaryPhone
    New primary phone location (work, home, mobile, etc...) for user account.
.PARAMETER WorkAddress
    New work address for user account.
.PARAMETER WorkCity
    New work city for user account.
.PARAMETER WorkState
    New work state for user account.
.PARAMETER WorkZip
    New work zip for user account.
.PARAMETER LocationID
    Location (building) ID for user account.
.PARAMETER LocationRoomID
    Room ID for user account.
.PARAMETER TypeName
    Account type name.
.PARAMETER IsEmployee
    New employee status for user account.
.PARAMETER Attributes
    New custom attributes for user account. Replaces existing custom
    attributes. Specify as an array.
.PARAMETER RemoveAttributes
    Names of custom attributes that should be removed from the user.
.PARAMETER RemoveOrgApplications
    Names of org applications that should be removed from the user.
.PARAMETER ClearOrgApplications
    Removes all org applications from the user.
.PARAMETER OverrideEnterpriseRole
    Replace security role, applications, and org applications on an account
    with an enterprise security role. Ordinarily, enterprise role holders are
    exempt from such changes.
.PARAMETER Passthru
    Return updated user as an object.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.INPUTS
    Settings may be passed down the pipeline by name.
.OUTPUTS
    Powershell object containing user account properties as documented in
    TeamDynamix.Api.Users.User.
.EXAMPLE
    C:\>Set-TDUser -Username smith -FirstName Jane -AuthenticationToken $Authentication

    Changes the first name on user account for "Smith" to "Jane".
.EXAMPLE
    C:\>Set-TDUser -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -FirstName Jane -AuthenticationToken $Authentication

    Changes the first name on user account with
    UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX to "Jane".
.EXAMPLE
    C:\>$UserApp = New-TDUserApplication -SecurityRoleID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -IsAdministrator $true
    C:\>Set-TDUser -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -OrgApplications $UserApp

    Creates a user application object and adds that application to the
    specified user.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDUser
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='UID')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # UID of user
        [Parameter(ParameterSetName='UID',
                   Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [guid]
        $UID,

        # Username of user
        [Parameter(Mandatory=$true,
                   ParameterSetName='Username',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='UID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Username,

        # Is user account active (enabled)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $IsActive,

        # First name of user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $FirstName,

        # Middle name of user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $MiddleName,

        # Last name of user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $LastName,

        # Primary email for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PrimaryEmail,

        # Alert email (typically same as primary email) address for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlertEmail,

        # Alternate email for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlternateEmail,

        # Alternate ID (Employee ID) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AlternateID,

        # Security role ID (from TeamDynamix) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $SecurityRoleID,

        # Applications for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Applications,

        # Organizationally-defined applications for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array[]]
        $OrgApplications,

        # Client portal application for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $PrimaryClientPortalApplicationID,

        # Default account ID (department ID from TeamDynamix) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $DefaultAccountID,

        # Group IDs (from TeamDynamix) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int[]]
        $GroupIDs,

        # Company name (OSU unit name) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Company,

        # Work title for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Title,

        # Work phone number for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkPhone,

        # Primary phone (work, home, etc...) for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $PrimaryPhone,

        # Work address for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkAddress,

        # Work city for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkCity,

        # Work state for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkState,

        # Work postal code for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkZip,

        # Location (building) ID for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationID,

        # Room ID for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $LocationRoomID,

        # Is user an employee
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsEmployee,

        # User type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_Users_UserType]
        $TypeID,

        # Custom attributes
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # Indicates that specified attributes should be removed
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            $AttributeNames = (Get-TDCustomAttribute -ComponentID Person -AuthenticationToken $TDAuthentication -Environment $Environment).Name
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

        # Specified org applications should be removed
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $RemoveOrgApplications,

        # Remove all org applications
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ClearOrgApplications,

        # Replace security role, applications, and org applications on accounts with an enterprise role
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $OverrideEnterpriseRole,

        # Return updated user as an object
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
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
    DynamicParam
    {
        #List dynamic parameters
        $DynamicParameterList = @(
            @{
                Name             = 'SecurityRoleName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDSecurityRoles.Name
                HelpText         = 'User security role name'
                IDParameter      = 'SecurityRoleID'
                IDsMethod        = '$TDSecurityRoles'
            }
            @{
                Name             = 'DefaultAccountName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDAccounts.Name
                HelpText         = 'User default account (department) name'
                IDParameter      = 'DefaultAccountID'
                IDsMethod        = '$TDAccounts'
            }
            @{
                Name             = 'GroupNames'
                Mandatory        = $false
                Type             = 'string[]'
                ValidateSet      = $TDGroups.Name
                HelpText         = 'User group names'
                IDParameter      = 'GroupIDs'
                IDsMethod        = '$TDGroups'
            }
            @{
                Name             = 'LocationName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $BuildingRoomCache.Get().Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'LocationID'
                IDsMethod        = '$BuildingRoomCache.Get()'
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
        #  Identify local parameters to be ignored
        $LocalIgnoreParameters = @('Username')
        #  Extract relevant list of parameters from the current command
        $ChangeParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys | Where-Object {(($_ -notin $LocalIgnoreParameters) -and ($_ -notin $GlobalIgnoreParameters))}
        $LocalIgnoreParameters += @('RemoveAttributes','RemoveOrgApplications','ClearOrgApplications','OverrideEnterpriseRole','SecurityRoleName','DefaultAccountName','GroupNames','LocationName')
    }
    Process
    {

        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        if ($DynamicParameterDictionary)
        {
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
        }
        # Make sure we have the UID so we can get the full user record
        if (($Username -ne '') -and (($null -eq $UID) -or ($UID -eq '00000000-0000-0000-0000-000000000000')))
        {
            Write-ActivityHistory "Looking up username, $Username, on TeamDynamix."
            if ($Username -notlike '*@*')
            {
                $Username = "$Username@$($TDConfig.DefaultEmailDomain)"
            }
            try
            {
                $TDUser = Get-TDUser -UserName $Username -IsActive $null -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "$Username not found, unable to update entry"
            }
            if ($TDUser)
            {
                $UID = $TDUser.UID
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "No user found in TD with username, $Username."
            }
        }
        # Only set the entry if there was a match for the username (or the UID was specified on the command line)
        if ($UID)
        {
            #  Compare parameters from current invocation to list of relevant parameters, throw error if none are present
            if (-not ($MyInvocation.BoundParameters.GetEnumerator() | Where-Object {$_.Key -in $ChangeParameters}))
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'No changes specified'
            }
            Write-ActivityHistory "Getting full user record for $UID on TeamDynamix."
            try
            {
                $TDUser = Get-TDUser -UID $UID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
            }
            catch
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find user ID, $UID"
            }
            if ((-not $TDUser.IsActive) -and (-not $Isactive)) # Warn on case where user is inactive and will remain inactive
            {
                Write-ActivityHistory -MessageChannel 'Warning' -Message "Inactive user, $($TDUser.UserName), updated. User remains inactive."
            }
            if ($TDUser.SecurityRoleName -like 'Enterprise*')
            {
                # Protect security role, applications, and org applications for users holding an enterprise role, unless OverrideEnterpriseRole is set
                if (-not $OverrideEnterpriseRole)
                {
                    $SecurityRoleID  = $TDUser.SecurityRoleID
                    $Applications    = $TDUser.Applications
                    $OrgApplications = $TDUser.OrgApplications
                    Write-ActivityHistory -MessageChannel 'Warning' -Message "Enterprise user $($TDUser.Username) retains current security role. To change, use -OverrideEnterpriseRole."
                }
            }
            Write-ActivityHistory 'Setting properties on user.'
            Update-Object -InputObject $TDUser -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
            # Blank room ID if changing location ID
            #  LocationRoomID must be in the LocationID, which won't be true if the LocationID changes with no corresponding LocationRoomID update
            if ($LocationID -and -not $LocationRoomID)
            {
                $TDUser.LocationRoomID = $null
            }
            # Remove attributes specified for removal
            if ($RemoveAttributes)
            {
                foreach ($RemoveAttribute in $RemoveAttributes)
                {
                    $TDUser.RemoveCustomAttribute($RemoveAttribute)
                }
            }
            # Remove org applications specified for removal
            if ($RemoveOrgApplications)
            {
                foreach ($RemoveOrgApplication in $RemoveOrgApplications)
                {
                    $TDUser.RemoveOrgApplication($RemoveOrgApplication)
                }
            }
            # Remove all org applications
            if ($ClearOrgApplications)
            {
                foreach ($Name in $TDUser.OrgApplications.SecurityRoleName)
                {
                    $TDUser.RemoveOrgApplication($Name)
                }
            }
            $TDUserTD = [TD_TeamDynamix_Api_Users_User]::new($TDUser)
            if ($pscmdlet.ShouldProcess("$UID - $($TDUser.UserName)", 'Update user properties'))
            {
                Write-ActivityHistory "Updating TeamDynamix user $UID - $($TDUser.UserName)."
                try
                {
                    $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDUserTD -Depth 10) -ErrorAction Stop
                }
                catch
                {
                    # TeamDynamix will not allow a ReportsToUID that points to a disabled user
                    #  If the existing record has a disabled ReportsToUID, it must be removed prior to pushing the changes
                    if ($_.Exception.Message -like "*Invalid Reports To UID*")
                    {
                        $TDUserTD.ReportsToUID = ''
                        Write-ActivityHistory 'Removed invalid "Reports To UID".'
                        # Re-do the change
                    }
                    # If room or location (building) is incorrect, an error will be returned
                    #  Remove location/room information and continue
                    if ($_.Exception.Message -like "*Invalid location/room*")
                    {
                        $TDUserTD.LocationID = ''
                        $TDUserTD.LocationRoomID = ''
                        Write-ActivityHistory 'Removed invalid location/room.'
                        # Re-do the change
                        $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDUserTD -Depth 10)
                    }else
                    {
                        Write-ActivityHistory -ErrorRecord $_
                    }
                }
                if ($Return)
                {
                    $Return = [TeamDynamix_Api_Users_User]::new($Return)
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
    Disable a user in TeamDynamix
.DESCRIPTION
    Disable a user in TeamDynamix. Note that user accounts cannot be deleted.
    Specify user by name or UID. Note that disabling a user by name uses
    the filter function of Get-TDUser, which is a substring search, and may
    return more results than desired. The disable function will only work
    when the username is unique.
.PARAMETER Username
    Username of the user to be disabled. Username should be of the form
    user@host.
.PARAMETER UID
    UID of the user to be disabled.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Disable-TDUser -Username name@host.edu -AuthenticationToken $Authentication

    Disables the user account for name@host.edu in TeamDynamix.
.EXAMPLE
    C:\>Disable-TDUser -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Disables the user account with UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX in TeamDynamix.
.EXAMPLE
    C:\>'user1@host.edu', 'user2@host.edu' | Disable-TDUser -AuthenticationToken $Authentication

    Disables user1@host.edu and user2@host.edu in TeamDynamix
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
    Pipeline not working.
#>
function Disable-TDUser
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='Username')]
    Param
    (
        # Username to disable in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Username',
                   Position=0)]
        [string]
        $Username,

        # UserID to disable in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Return updated user as an object
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
    }
    Process
    {
        if ($pscmdlet.ShouldProcess(((Get-Variable -Name $PSCmdlet.ParameterSetName).Value), 'Disable TeamDynamix user'))
        {
            if ($pscmdlet.ParameterSetName -eq 'Username')
            {
                $UserID = $null
                $TDUser = Get-TDUser -UserName $Username -IsActive $null -AuthenticationToken $AuthenticationToken -Environment $Environment
                if ($TDUser) # User already exists
                {
                    $UserID = $TDUser.UID
                }
                else # Get-TDUser came up empty
                {
                    Write-ActivityHistory -MessageChannel 'Error' -Message 'No user ID found.'
                    return
                }
            }
            else # UID specified on the command line
            {
                $UserID = $UID
            }
            if (-not $UserID) # Get-TDUser found something, but not a matching user
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message 'No matching user ID found.'
                return
            }
            Write-ActivityHistory "Disabling UID $UserID"
            Invoke-RESTCall -Uri "$BaseURI/people/$UserID/isactive?status=$false" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
            if ($Passthru)
            {
                Write-Output (Get-TDUser -UID $UserID -AuthenticationToken $AuthenticationToken -Environment $Environment)
            }
        }
    }
}

<#
.Synopsis
    Enable a user in TeamDynamix
.DESCRIPTION
    Enable a user in TeamDynamix. Specify user by name or UID. Note that
    enabling a user by name uses the filter function of Get-TDUser, which is a
    substring search, and may return more results than desired. The enable
    function will only work when the username is unique.
.PARAMETER Username
    Username of the user to be enabled. Username should be of the form
    user@host.
.PARAMETER UID
    UID of the user to be enabled. Available on the pipeline by name.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Enable-TDUser -Username name@host.edu -AuthenticationToken $Authentication

    Enables the user account for name@host.edu in TeamDynamix.
.EXAMPLE
    C:\>Enable-TDUser -UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Enables the user account with UID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX in TeamDynamix.
.EXAMPLE
    C:\>'user1@host.edu', 'user2@host.edu' | Enable-TDUser -AuthenticationToken $Authentication

    Enables user1@host.edu and user2@host.edu in TeamDynamix
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
    Pipeline not working.
#>
function Enable-TDUser
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High',
                   DefaultParameterSetName='Username')]
    Param
    (
        # Username to enable in TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Username',
                   Position=0)]
        [string]
        $Username,

        # UserID to enable from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='UID')]
        [guid]
        $UID,

        # Return updated user as an object
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
    }
    Process
    {
        if ($pscmdlet.ShouldProcess(((Get-Variable -Name $PSCmdlet.ParameterSetName).Value), 'Enable TeamDynamix user'))
        {
            if ($pscmdlet.ParameterSetName -eq 'Username')
            {
                $UserID = $null
                $TDUser = Get-TDUser -UserName $Username -AuthenticationToken $AuthenticationToken -Environment $Environment
                if ($TDUser) # User exists
                {
                    $UserID = $TDUser.UID
                }
                else # Get-TDUser came up empty
                {
                    Write-ActivityHistory -MessageChannel 'Error' -Message 'No user ID found.'
                    return
                }
            }
            else # UID specified on the command line
            {
                $UserID = $UID
            }
            if (-not $UserID) # Get-TDUser found something, but not a matching user
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message 'No matching user ID found.'
                return
            }
            Write-ActivityHistory "Enabling UID $UserID"
            Invoke-RESTCall -Uri "$BaseURI/people/$UserID/isactive?status=$true" -ContentType $ContentType -Method Put -Headers $AuthenticationToken
            if ($Passthru)
                {
                    Write-Output (Get-TDUser -UID $UserID -AuthenticationToken $AuthenticationToken -Environment $Environment)
                }
        }
    }
}

<#
.Synopsis
    Perform bulk user updates in TeamDynamix.
.DESCRIPTION
    Perform bulk user updates in TeamDynamix. Update users' desktop template
    list, accounts (departments), active status, applications list, org
    applications list, security role, or group memberships. Note that these
    updates can only be made once every 2 minutes, so be sure to collect the
    updates together. Only one type of update may be performed at any given
    time.
.PARAMETER UIDs
    User IDs to modify.
.PARAMETER TemplateDesktopID
    Desktop ID to apply for the users.
.PARAMETER IsDefault
    Switch to indicate that the specified desktop is to be the default.
.PARAMETER AccountIDs
    Account (department) IDs to add the users to.
.PARAMETER ReplaceExistingAccounts
    Switch to indicate that the specified accounts (departments) should replace
    the users' existing accounts (departments).
.PARAMETER IsActive
    Set whether the users' accounts are active ($true), or not ($false).
.PARAMETER ApplicationNames
    Names of applications to add to the users.
.PARAMETER ReplaceExistingApplications
    Switch to indicate that the specified applications should replace the
    users' existing applications.
.PARAMETER OrgApplications
    Names of org applications to add to the users.
.PARAMETER ReplaceExistingOrgApplications
    Switch to indicate that the specified org applications should replace the
    users' existing org applications.
.PARAMETER SecurityRoleID
    Security role to apply to the users.
.PARAMETER GroupIDs
    Group IDs to add to the users.
.PARAMETER RemoveOtherGroups
    Switch to indicate that the specified groups should replace the users'
    existing group memberships.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY' | Set-TDBulkUser -IsActive $false -AuthenticationToken $Authentication

    Sets the specified users as inactive.
.EXAMPLE
    C:\>$TicketsApp = New-TDUserApplication -SecurityRoleID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -IsAdministrator $true
    C:\>$AssetCIApp = New-TDUserApplication -SecurityRoleID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -IsAdministrator $true
    C:\> 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX', 'YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY' | Set-TDBulkUser -OrgApplications @($TicketsApp,$AssetCIApp) -ReplaceExistingOrgApplications -AuthenticationToken $Authentication

    Replaces the current org applications for the specified user with the
    specified org applications.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Set-TDBulkUser
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # User IDs to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='DesktopTemplate')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='Account')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ActiveStatus')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='Applications')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='OrgApplications')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='SecurityRole')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='Groups')]
        [guid[]]
        $UIDs,

        # Desktop template to apply
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='DesktopTemplate')]
        [guid]
        $TemplateDesktopID,

        # Template is default
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='DesktopTemplate')]
        [boolean]
        $IsDefault = $false,

        # Account (department) IDs to add
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Account')]
        [int32[]]
        $AccountIDs,

        # Remove existing accounts (departments) and replace
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Account')]
        [switch]
        $ReplaceExistingAccounts,

        # Active status
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='ActiveStatus')]
        [boolean]
        $IsActive,

        # Applications to add
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Applications')]
        [string[]]
        $ApplicationNames,

        # Remove existing accounts and replace
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Applications')]
        [switch]
        $ReplaceExistingApplications,

        # Applications to add
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='OrgApplications')]
        [TeamDynamix_Api_Apps_UserApplication[]]
        $OrgApplications,

        # Remove existing accounts and replace
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='OrgApplications')]
        [switch]
        $ReplaceExistingOrgApplications,

        # Security role to apply
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='SecurityRole')]
        [guid]
        $SecurityRoleID,

        # Groups to add
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Groups')]
        [int32[]]
        $GroupIDs,

        # Remove existing accounts and replace
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Groups')]
        [switch]
        $RemoveOtherGroups,

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
        Write-ActivityHistory "-----`nIn ConvertFrom-TDWebAPIToFunction"
        $ContentType = 'application/json; charset=utf-8'
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
        $BaseURI = Get-URI -Environment $Environment
    }
    Process
    {
        Write-ActivityHistory 'Setting properties for TD bulk request.'
        switch ($PSCmdlet.ParameterSetName)
        {
            Account
            {
                $RESTEndpoint = 'people/bulk/changeacctdepts'
                $Body = [TeamDynamix_Api_Users_UserAccountsBulkManagementParameters]::new($UIDs,$AccountIDs,$ReplaceExistingAccounts.IsPresent)
            }
            ActiveStatus
            {
                $RESTEndpoint = "people/bulk/changeactivestatus?isActive=$IsActive"
                $Body = $UIDs
            }
            Applications
            {
                $RESTEndpoint = 'people/bulk/changeapplications'
                $Body = [TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters]::new($UIDs,$ApplicationNames,$ReplaceExistingApplications.IsPresent)
            }
            DesktopTemplate
            {
                $RESTEndpoint = "people/bulk/applydesktop/$($TemplateDesktopId)?isDefault=$IsDefault"
                $Body = $UIDs
            }
            Groups
            {
                $RESTEndpoint = 'people/bulk/managegroups'
                $Body = [TeamDynamix_Api_Users_UserGroupsBulkManagementParameters]::new($UIDs,$GroupIDs,$RemoveOtherGroups.IsPresent)
            }
            OrgApplications
            {
                $RESTEndpoint = 'people/bulk/changeorgapplications'
                $Body = [TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters]::new($UIDs,$OrgApplications,$ReplaceExistingOrgApplications.IsPresent)
            }
            SecurityRole
            {
                $RESTEndpoint = "people/bulk/applydesktop/$SecurityRoleID"
                $Body = $UIDs
            }
        }
        if ($pscmdlet.ShouldProcess(($Body | Out-String), "Updating $($PSCmdlet.ParameterSetName)"))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/$RESTEndpoint" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Body -Depth 10)
            return $Return
        }
    }
}

<#
.Synopsis
    Adds a collection of platform application to a group in TeamDynamix.
.DESCRIPTION
    Adds a collection of platform application to a group in TeamDynamix.
    Existing application associations are not affected.
.PARAMETER GroupID
    The group ID number, used to identify the group.
.PARAMETER AppIDs
    The application IDs to add to the group.
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
    TeamDynamix.Api.Users.GroupMember.
.EXAMPLE
   C:\>Add-TDGroupApplication -GroupID 559 -AppIDs @(17922,17932) -AuthenticationToken $Authentication

   Associates applications with IDs 17922 and 17932 with group ID 559.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Add-TDGroupApplication
{
    [CmdletBinding()]
    Param
    (
        # Group ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias("ID")]
        [int]$GroupID,

        # Application ID numbers
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int[]]$AppIDs,

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
                Name             = 'GroupName'
                Mandatory        = $true
                Type             = 'string'
                ValidateSet      = $TDGroups.Name
                HelpText         = 'Remove applications from this group'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups'
            }
            @{
                Name             = 'AppNames'
                Mandatory        = $true
                Type             = 'string[]'
                ValidateSet      = $TDApplications.Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'AppIDs'
                IDsMethod        = '$TDApplications'
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
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        if ($DynamicParameterDictionary)
        {
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
        }
    }

    Process
    {
        Write-ActivityHistory -MessageChannel 'Verbose' -Message "Adding applications $AppIDs to group $GroupID"
        $Applications = @{AppIds = [array]$AppIDs}
        $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$GroupID/applications" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body ($Applications | ConvertTo-Json -Depth 10 -Compress)
        if (-not $Return)
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message 'Add applications to group failed.'
        }
        return $Return
    }
}

<#
.Synopsis
    Gets the list of platform application associated with a group in
    TeamDynamix.
.DESCRIPTION
    Gets the list of platform application associated with a group in
    TeamDynamix.
.PARAMETER GroupID
    The group ID number, used to identify the group.
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
    TeamDynamix.Api.Users.GroupMember.
.EXAMPLE
   C:\>Get-TDGroupApplication -AuthenticationToken $Authentication

   Returns a list of all platform applications assigned to group ID 1234.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDGroupApplication
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # Group ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID',
                   Position=0)]
        [Alias("ID")]
        [int]$GroupID,

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
                Name             = 'GroupName'
                Mandatory        = $true
                Type             = 'string'
                ValidateSet      = $TDGroups.Name
                HelpText         = 'Return applications assigned to this group'
                ParameterSetName = 'Name'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups'
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
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        if ($DynamicParameterDictionary)
        {
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
        }
    }

    Process
    {
        $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$GroupID/applications" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_GroupApplication]::new($_)})
        }
        return $Return
    }
}

<#
.Synopsis
    Removes a collection of platform applications from a group in TeamDynamix.
.DESCRIPTION
    Removes a collection of platform applications from a group in TeamDynamix.
.PARAMETER GroupID
    The group ID number, used to identify the group.
.PARAMETER AppIDs
    The application IDs to remove from the group.
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
    TeamDynamix.Api.Users.GroupMember.
.EXAMPLE
    C:\>Remove-TDGroupApplication -GroupID 559 -AppIDs @(17922,17932) -AuthenticationToken $Authentication

    Removes applications with IDs 17922 and 17932 from group ID 559.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Remove-TDGroupApplication
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # Group ID number
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias("ID")]
        [int]$GroupID,

        # Application ID numbers
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [int[]]$AppIDs,

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
                Name             = 'GroupName'
                Mandatory        = $true
                Type             = 'string'
                ValidateSet      = $TDGroups.Name
                HelpText         = 'Remove applications from this group'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups'
            }
            @{
                Name             = 'AppNames'
                Mandatory        = $true
                Type             = 'string[]'
                ValidateSet      = $TDApplications.Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'AppIDs'
                IDsMethod        = '$TDApplications'
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
        #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
        if ($DynamicParameterDictionary)
        {
            $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
            $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
        }
    }

    Process
    {
        Write-ActivityHistory -MessageChannel 'Verbose' -Message "Removing applications $AppIDs from group $GroupID"
        $Applications = @{AppIds = [array]$AppIDs}
        if ($pscmdlet.ShouldProcess($GroupID, "Removing applications $AppIDs"))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/groups/$GroupID/applications" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken -Body ($Applications | ConvertTo-Json -Depth 10 -Compress)
            if (-not $Return)
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message 'Remove applications from group failed.'
            }
            return $Return
        }
    }
}