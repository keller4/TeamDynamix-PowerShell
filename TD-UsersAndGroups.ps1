### Users and Groups

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
        [Parameter(Mandatory=$false,
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
            # Force $GUI to $true, since the default parameter set will send us through this code path, even if $GUI isn't set to true
            $GUI = $true
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
                ValidateSet      = $TDBuildingRoomCache.Get().Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'LocationID'
                IDsMethod        = '$TDBuildingRoomCache.Get()'
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
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
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
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
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
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
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
            $IDsFromNamesUpdates | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
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

function New-TDGroupApplication
{
    [CmdletBinding()]
    param
    (
        # ID of the platform application.
        [Parameter(Mandatory=$true)]
        [int]
        $AppID
    )
    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        $GroupApplication = [TeamDynamix_Api_Users.GroupApplication]::new()
        $GroupApplication.AppID = $AppID
        return $UserApplication
    }
}