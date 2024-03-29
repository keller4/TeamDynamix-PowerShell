﻿### Users and Groups

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

        # Don't invalidate the cached data
        [Parameter(Mandatory=$false,
                   ParameterSetName='PSCredential')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='CredentialPath')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='GUI')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Prompt')]
        [switch]
        $NoInvalidateCache,

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

    Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
            $Authenticated = $true
        }
        PSCredential
        {
            # Extract credentials from PSCredential object
            # Check for blank credentials and start an unauthenticated session if blanks are found
            if (($Credential.Username -eq '') -or ($Credential.GetNetworkCredential().Password -eq ''))
            {
                $Authenticated = $false
            }
            else
            {
                $Authenticated = $true
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
                $Authenticated        = $AuthenticationInfo.Authenticated
                $AuthenticationHeader = $AuthenticationInfo.Authentication
                $AuthenticationSite   = $AuthenticationInfo.Site
            }
            else
            {
                $AuthenticationInfo   = Set-TDAuthentication -Prompt -NoUpdate
                $Authenticated        = $AuthenticationInfo.Authenticated
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
            if ($Username -eq '')
            {
                $Authenticated = $false
            }
            else
            {
                $Authenticated = $true
            }
        }
    }
    if ($Authenticated -and -not $GUI)
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

    # Flush cached variables
    if (-not $NoInvalidateCache)
    {
        Clear-TDLocalCache
    }

    # Update or return authentication information
    if (-not $NoUpdate)
    {
        $script:TDAuthentication = $AuthenticationHeader
        $script:LastAuthentication = Get-Date
        $Return = $null
        $script:WorkingEnvironment = $Environment
    }
    # Return authentication information for everything but update, and always for Passthru
    if ($Passthru -or $NoUpdate)
    {
        $Return = [PSCustomObject]@{
            Authenticated  = $Authenticated
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

    Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
        [Parameter(Parametersetname='Fast',
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

        # Return only exact matches on account search
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [Parameter(Parametersetname='Fast',
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
                Name             = 'AppName'
                Type             = 'string'
                ValidateSet      = $TDApplications.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Return users who have been granted access to the application'
                ParameterSetName = 'Search'
                IDParameter      = 'AppID'
                IDsMethod        = '$TDApplications.GetAll([string]$Environment,$true)'
            }
            @{
                Name             = 'AccountNames'
                ValidateSet      = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Names of departments'
                ParameterSetName = 'Search'
                IDParameter      = 'AccountID'
                IDsMethod        = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'SecurityRoleName'
                Type             = 'string'
                ValidateSet      = $TDSecurityRoles.GetAll($WorkingEnvironment,$null).Name
                HelpText         = 'Name of security role'
                ParameterSetName = 'Search'
                IDParameter      = 'SecurityRoleID'
                IDsMethod        = '$TDSecurityRoles.GetAll($WorkingEnvironment,$null)'
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
        # Local modifications to return set
        if ($Return)
        {
            if ($Exact)
            {
                if (-not [string]::IsNullOrWhiteSpace($SearchText))
                {
                    $Return = $Return | Where-Object {$SearchText -in @($_.AlertEmail,$_.$AlternateEmail,$_.AuthenticationUserName,$_.FullName,$_.PrimaryEmail,$_.UserName)}
                }
            }
            if ($Detail)
            {
                if ($Return)
                {
                    $Return = Get-TDUser -UID $Return.UID -AuthenticationToken $AuthenticationToken -Environment $Environment
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

        # Parent account name filter
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $ParentAccountName,

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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        $TDDepartment = [TeamDynamix_Api_Accounts_Account]::new()
        Update-Object -InputObject $TDDepartment -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($TDDepartment | Out-String), 'Creating new department'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/accounts" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDDepartment -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Accounts_Account]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
				ValidateSet      = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
				HelpText         = 'Name of department to edit'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'ID'
                IDsMethod        = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        $TDGroup = [TeamDynamix_Api_Users_Group]::new()
        Update-Object -InputObject $TDGroup -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($TDGroup | Out-String), 'Creating new group'))
        {
            $Return = Invoke-RESTCall -Uri "$BaseURI/groups" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDGroup -Depth 10)
            if ($Return)
            {
                $Return = [TeamDynamix_Api_Users_Group]::new($Return)
            }
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
				ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
				HelpText         = 'Name of group to edit'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'ID'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID/groups" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Users_UserGroup]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
				ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
				HelpText         = 'Name of group'
                Mandatory        = $true
                ParameterSetName = 'Name'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
			}
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
		return $DynamicParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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

        # The salutation of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Salutation,

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

        # The nickname of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Nickname,

        # The organizational ID of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

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

        # The home phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomePhone,

        # The pager number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Pager,

        # The other phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $OtherPhone,

        # The mobile phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $MobilePhone,

        # The fax number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Fax,

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

        # Work country for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkCountry,

        # The ID of the default priority associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DefaultPriorityID,

        # The &quot;About Me&quot; information associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AboutMe,

        # The home address of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeAddress,

        # The home city of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeCity,

        # The home state abbreviation of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeState,

        # The home zip code of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeZip,

        # Home country for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeCountry,

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

        # The UID of the desktop to assign to the new user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $DesktopID,

        # Whether or not to link the desktop to the template.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $LinkDesktop,

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

        # The default bill rate of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $DefaultRate,

        # The cost rate of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $CostRate,

        # The number of workable hours in a work day for the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $WorkableHours,

        # Whether the user's capacity is managed, meaning they can have capacity and will appear on capacity/availability reports.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsCapacityManaged,

        # The date after which the user should start reporting time. This also governs capacity calculations.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $ReportTimeAfterDate,

        # The date after which the user is no longer available for scheduling and no longer required to log time.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # Whether the user should report time.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ShouldReportTime,

        # The UID of the person who the user reports to.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ReportsToUID,

        # The ID of the resource pool associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $ResourcePoolID,

        # The ID of the time zone associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $TZID,

        # The authentication username of the user, used for authenticating with non-TeamDynamix authentication types.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AuthenticationUserName,

        # The ID of the authentication provider the new user will use for authentication.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $AuthenticationProviderID = $TDConfig.DefaultAuthenticationProviderID,

        # The Instant Messenger (IM) provider associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $IMProvider,

        # The Instant Messenger (IM) username/handle associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $IMHandle,

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

        # Exclude users if this statement evaluates to true - only applies to inactive users that already exist
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExcludeOnMatch,

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
                Name             = 'UserRoleName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDConfig.UserRoles.Name
                HelpText         = 'User role name'
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
        #  Identify local parameters to be ignored
        #   Ignore LocationID and LocationRoomID because TeamDynamix_Api_Users_NewUser doesn't support it - set location after user is created
        $LocalIgnoreParameters = @('LocationID','LocationRoomID','UserRoleName')
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
        $TDUser = $false
        # Check to see if user exists
        # Include both active and inactive users.
        $TDUser = Get-TDUser -UserName $Username -IsActive $null -AuthenticationToken $AuthenticationToken -Environment $Environment
        if (-not $TDUser)
        {
            # User does not exist
            if ($pscmdlet.ShouldProcess($Username, 'Create new TeamDynamix user'))
            {
                Write-ActivityHistory 'New user'
                $Return = Invoke-RESTCall -Uri "$BaseURI/people" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $NewTDUser -Depth 10)
                if ($Return)
                {
                    $FixRequired = $false
                    $Return = [TeamDynamix_Api_Users_User]::new($Return)
                    # Fix applications and org applications, since the new user call doesn't support org applications
                    if ($OrgApplications)
                    {
                        $Return.Applications    = $NewTDUser.Applications
                        $Return.OrgApplications = $NewTDUser.OrgApplications
                        $FixRequired = $true
                    }

                    # Fix room and building, since the new user call doesn't support it
                    if ($LocationID -or $LocationRoomID)
                    {
                        $Return.LocationID     = $LocationID
                        $Return.LocationRoomID = $LocationRoomID
                        $FixRequired = $true
                    }
                    if ($FixRequired)
                    {
                        # Have Set-TDUser handle user role update
                        if ($UserRoleName)
                        {
                            $Return = $Return | Set-TDUser -UserRoleName $UserRoleName -OverrideEnterpriseRole -AuthenticationToken $AuthenticationToken -Environment $Environment -Passthru
                        }
                        else
                        {
                            $Return = $Return | Set-TDUser -OverrideEnterpriseRole -AuthenticationToken $AuthenticationToken -Environment $Environment -Passthru
                        }
                    }
                }
                if ($Passthru)
                {
                    Write-Output $Return
                }
            }
        }
        elseif (-not $TDUser.IsActive)
        {
            # User exists, but is inactive (disabled) - modify
            if ($pscmdlet.ShouldProcess($Username, 'Activate and update inactive TeamDynamix user'))
            {
                Write-ActivityHistory 'Reactivate user'
                #Ensure user is active
                $NewTDUser.IsActive = $true
                $Return = $NewTDUser | Set-TDUser -ExcludeOnMatch $ExcludeOnMatch -Passthru -AuthenticationToken $AuthenticationToken -Environment $Environment -Confirm:$false
                if ($Passthru)
                {
                    Write-Output $Return
                }
            }
        }
        else
        {
            # User exists and is active - do not modify
            Write-ActivityHistory -MessageChannel 'Warning' -Message "Active user $Username already exists in TeamDynamix"
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDUser
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # UID of user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [guid]
        $UID,

        # Username of user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Username,

        # Is user account active (enabled)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsActive,

        # The confidential status of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsConfidential,

        # The salutation of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Salutation,

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

        # The nickname of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Nickname,

        # The organizational ID of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExternalID,

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

        # The home phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomePhone,

        # The pager number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Pager,

        # The other phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $OtherPhone,

        # The mobile phone number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $MobilePhone,

        # The fax number of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Fax,

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

        # Work country for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $WorkCountry,

        # The ID of the default priority associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $DefaultPriorityID,

        # The &quot;About Me&quot; information associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AboutMe,

        # The home address of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeAddress,

        # The home city of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeCity,

        # The home state abbreviation of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeState,

        # The home zip code of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeZip,

        # Home country for user
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HomeCountry,

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

        # The default bill rate of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $DefaultRate,

        # The cost rate of the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $CostRate,

        # The number of workable hours in a work day for the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $WorkableHours,

        # Whether the user's capacity is managed, meaning they can have capacity and will appear on capacity/availability reports.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsCapacityManaged,

        # The date after which the user should start reporting time. This also governs capacity calculations.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $ReportTimeAfterDate,

        # The date after which the user is no longer available for scheduling and no longer required to log time.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [datetime]
        $EndDate,

        # Whether the user should report time.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ShouldReportTime,

        # The UID of the person who the user reports to.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ReportsToUID,

        # The ID of the resource pool associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $ResourcePoolID,

        # The ID of the time zone associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $TZID,

        # The authentication username of the user, used for authenticating with non-TeamDynamix authentication types.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AuthenticationUserName,

        # The ID of the authentication provider the new user will use for authentication.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int32]
        $AuthenticationProviderID = $TDConfig.DefaultAuthenticationProviderID,

        # The Instant Messenger (IM) provider associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $IMProvider,

        # The Instant Messenger (IM) username/handle associated with the user.
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $IMHandle,

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

        # Exclude users if this statement evaluates to true
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ExcludeOnMatch,

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
                ValidateSet      = $TDSecurityRoles.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'User security role name'
                IDParameter      = 'SecurityRoleID'
                IDsMethod        = '$TDSecurityRoles.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'UserRoleName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDConfig.UserRoles.Name
                HelpText         = 'User role name'
            }
            @{
                Name             = 'DefaultAccountName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDAccounts.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'User default account (department) name'
                IDParameter      = 'DefaultAccountID'
                IDsMethod        = '$TDAccounts.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'GroupNames'
                Mandatory        = $false
                Type             = 'string[]'
                ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'User group names'
                IDParameter      = 'GroupIDs'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'LocationName'
                Mandatory        = $false
                Type             = 'string'
                ValidateSet      = $TDBuildingsRooms.GetAll($true).Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'LocationID'
                IDsMethod        = '$TDBuildingsRooms.GetAll($true)'
            }
            @{
                Name             = 'TimeZoneName'
                Type             = 'string'
                ValidateSet      = $TDTimeZones.Name
                HelpText         = 'Name of time zone'
                IDParameter      = 'TZID'
                IDsMethod        = '$TDTimeZones'
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
        #  Identify local parameters to be ignored
        $LocalIgnoreParameters = @('Username')
        #  Extract relevant list of parameters from the current command
        $ChangeParameters = (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys | Where-Object {(($_ -notin $LocalIgnoreParameters) -and ($_ -notin $GlobalIgnoreParameters))}
        $LocalIgnoreParameters += @('RemoveAttributes','RemoveOrgApplications','ClearOrgApplications','OverrideEnterpriseRole','SecurityRoleName','UserRoleName','DefaultAccountName','GroupNames','LocationName','TimeZoneName')
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
        elseif (($Username -eq '') -and (($null -eq $UID) -or ($UID -eq '00000000-0000-0000-0000-000000000000')))
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "No username or UID specified."
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
            # Exclude users based on runtime match
            if (Invoke-Expression $ExcludeOnMatch)
            {
                # User excluded
                Write-ActivityHistory -MessageChannel 'Warning' -Message "User excluded from update: $($TDUser.UserName)."
            }
            else
            {
                # User not excluded, process normally
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
                # Set user role
                if ($UserRoleName)
                {
                    $TDUser.SetUserRole($UserRoleName,$AuthenticationToken,$Environment)
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
                        if ($_.ErrorDetails.Message -like '*Invalid Reports To UID*')
                        {
                            $TDUserTD.ReportsToUID = ''
                            Write-ActivityHistory 'Removed invalid "Reports To UID".'
                            # Re-do the change
                            $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDUserTD -Depth 10)
                        }
                        # If room or location (building) is incorrect, an error will be returned
                        #  Remove location/room information and continue
                        elseif ($_.ErrorDetails.Message -like '*Invalid location/room*')
                        {
                            $TDUserTD.LocationID = ''
                            $TDUserTD.LocationRoomID = ''
                            Write-ActivityHistory 'Removed invalid location/room.'
                            # Re-do the change
                            $Return = Invoke-RESTCall -Uri "$BaseURI/people/$UID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $TDUserTD -Depth 10)
                        }
                        else
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
            Invoke-RESTCall -Uri "$BaseURI/people/$UserID/isactive?status=$false" -ContentType $ContentType -Method Put -Headers $AuthenticationToken | Out-Null # No return is needed for this function
            if ($Passthru)
            {
                Write-Output (Get-TDUser -UID $UserID -AuthenticationToken $AuthenticationToken -Environment $Environment)
            }
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
            Invoke-RESTCall -Uri "$BaseURI/people/$UserID/isactive?status=$true" -ContentType $ContentType -Method Put -Headers $AuthenticationToken | Out-Null # No return is needed for this function
            if ($Passthru)
                {
                    Write-Output (Get-TDUser -UID $UserID -AuthenticationToken $AuthenticationToken -Environment $Environment)
                }
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
                ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Remove applications from this group'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'AppNames'
                Mandatory        = $true
                Type             = 'string[]'
                ValidateSet      = $TDApplications.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'AppIDs'
                IDsMethod        = '$TDApplications.GetAll([string]$Environment,$true)'
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
                ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Return applications assigned to this group'
                ParameterSetName = 'Name'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
                ValidateSet      = $TDGroups.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Remove applications from this group'
                IDParameter      = 'GroupID'
                IDsMethod        = '$TDGroups.GetAll($WorkingEnvironment,$true)'
            }
            @{
                Name             = 'AppNames'
                Mandatory        = $true
                Type             = 'string[]'
                ValidateSet      = $TDApplications.GetAll($WorkingEnvironment,$true).Name
                HelpText         = 'Remove these applications from specified group'
                IDParameter      = 'AppIDs'
                IDsMethod        = '$TDApplications.GetAll([string]$Environment,$true)'
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
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
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
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
    }
    Process
    {
        $GroupApplication = [TeamDynamix_Api_Users.GroupApplication]::new()
        $GroupApplication.AppID = $AppID
        return $UserApplication
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1kO1zPN3ieg5ym1WsN2K/u/E
# Gy6gggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEn9
# 6ecP8u//u+O2/URqoR7ggTGzMA0GCSqGSIb3DQEBAQUABIICAGzoG2+mdgpB8/6J
# 0TUDwCkwJIFrQMXPVecxEPylf0oadiZWdcDPyJzEbF+n8UZeClX1qpuCAe55p6vM
# GGAg2tJbZew3tzyhxi34CZ/ihMDuW0aNCW6hd+FwD+eJI2iS8Pz87fGAU2CS8sUc
# +aYPXTdKLcX0moLQhbYyPCiCbKFwyxHaJ/+J568htiCWDvsEsUTRh1AK3LY63736
# Ga6gNnUoncYxGcln/mFchSIzE24ZJh9nt8xnKDeB4SEDdiE45kzHbY0WObghfdXB
# zzOck/BjP+vX4JeCixMdwinaQrG4MzI9sogp9gB42vJmoDLPwG1LGWvMzOuwQqoc
# 6zlI01HXboqflAW6ND3B45rGaFdBFPWdsIDofFnYC8/gntyVNXs1k0agQP+asidF
# tZwtiHK1LwhZRLKyhZmUqFYT3M4uhMqylmIMj3qc6e+bjIa0Fm7GeMGESva7Jhe+
# paXmQkl7C2br71PLxU54Wj71i41oXzx3jOaq4UZgmlY+5/tlMrdUvWXX76m7+aTt
# 9HUEV+yrzWgr/m6VtzF6u3h37GwIiCsx0/LNVE/OxA8Tn0/WW2YJKASPsQBOsT4O
# 1p2g0g50U72B9BdahGErYnNQjnen+pfcIEIlxYbJJGX4E44l5vE70iatLt6/cCq6
# YTHsJVUlNBuaL3IkKjIIG2a2ipNn
# SIG # End signature block
