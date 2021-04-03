### Service

#region Public functions
function Get-TDTimeZoneInformation
{
    [CmdletBinding()]
    Param
    (
        # Sort by GMT Offset switch
        [Parameter(Mandatory=$false)]
        [switch]
        $SortByGMTOffset
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    [array]$TDTimeZones = $()
    foreach ($TimeZone in $TimeZoneIDReference.GetEnumerator())
    {
        # Separate time zone information using a regular expression
        $TimeZone.Value -match '(.*)\s?\(GMT(([+-][01][0-9]:[0-9]0|[\s\w]*))?\)' | Out-Null
        $TZProperties = @{
            ID                    = $TimeZone.Name
            Name                  = $Matches[1]
            'Standard GMT Offset' = $Matches[2]}
        # GMT shows no offset, set it to zero
        if ($TZProperties.'Standard GMT Offset' -notmatch '^[+-]')
        {
            $TZProperties.'Standard GMT Offset' = '0'
        }
        $TimeZoneObject = New-Object -TypeName psobject -Property $TZProperties
        $TDTimeZones += $TimeZoneObject
    }
    if ($SortByGMTOffset)
    {
        $SortTZ  = $TDTimeZones | Where-Object {$_.'Standard GMT Offset' -like '-*'} | Sort-Object 'Standard GMT Offset' -Descending
        $SortTZ += $TDTimeZones | Where-Object {$_.'Standard GMT Offset' -like '0'}
        $SortTZ += $TDTimeZones | Where-Object {$_.'Standard GMT Offset' -like '+*'} | Sort-Object 'Standard GMT Offset'
        $TDTimeZones = $SortTZ
    }
    return $TDTimeZones
}

function Get-TDApplication
{
    [CmdletBinding()]
    Param
    (
        # Filter based on whether application is active
        [Parameter(Mandatory=$false)]
        [System.Nullable[boolean]]
        $IsActive = $true,

        # Return all applications, including duplicates
        [Parameter(Mandatory=$false)]
        [switch]
        $WithDuplicates,

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

        $Return = Invoke-RESTCall -Uri "$BaseURI/applications" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Apps_OrgApplication]::new($_)})
            if (-not $WithDuplicates)
            {
                # Remove apps with duplicated names, to make each application name unique
                #  Duplicates occur in asset and ticketing applications - remove the lower-numbered application for each
                $DeduplicatedReturn = $Return
                $Duplicates = $Return | Group-Object Name | Where-Object Count -gt 1
                if ($Duplicates)
                {
                    foreach ($Duplicate in $Duplicates)
                    {
                        # Find the lowest ID number in the set of apps with the same name and remove it
                        $RemoveID = ($Duplicate.Group.AppID | Measure-Object -Minimum).Minimum
                        $DeduplicatedReturn = $DeduplicatedReturn | Where-Object AppID -ne $RemoveID
                    }
                    # Return the deduplicated list
                    $Return = $DeduplicatedReturn
                }
            }
            if ($null -eq $IsActive)
            {
                return $Return
            }
            else
            {
                return ($Return | Where-Object {$_.Active -eq $IsActive})
            }
        }
    }
}

function Get-TDLicenseType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Name in [TeamDynamix_Api_Roles_LicenseTypes].GetEnumValues())
    {
        $Properties = @{
            Name = $Name.ToString()
            ID   = $Name.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDAttributeComponent
{
    [CmdletBinding()]
    [alias('Get-TDCustomAttributeComponent')]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDTicketClass
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Tickets_TicketClass].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDUserType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Users_UserType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDKBArticleStatus
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_KnowledgeBase_ArticleStatus].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDTicketStatusClass
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Statuses_StatusClass].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDAttachmentType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Attachments_AttachmentType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDFeedItemType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Feed_FeedItemType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDFeedUpdateType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Feed_UpdateType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDBulkOperationResultType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_BulkOperations_ItemResultType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDBackingItemType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Cmdb_BackingItemType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDServiceCatalogRequestType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_ServiceCatalog_RequestComponent].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDTicketTaskType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Tickets_TicketTaskType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function Get-TDConflictType
{
    [CmdletBinding()]
    [array]$Return = @()
    foreach ($Entry in [TeamDynamix_Api_Tickets_ConflictType].GetEnumValues())
    {
        $Properties = @{
            Name = $Entry.ToString()
            ID   = $Entry.Value__
        }
        $Return += New-Object -TypeName psobject -Property $Properties
    }
    Write-Output $Return
}

function New-TDUserApplication
{
    [CmdletBinding()]
    Param
    (
        # The ID of the specific security role that the user has within the application.
        [Parameter(Mandatory=$true)]
        [System.Nullable[Guid]]
        $SecurityRoleId,

        # Gets whether the user is marked as an administrator of the application.
        [Parameter(Mandatory=$false)]
        [Boolean]
        $IsAdministrator = $false,

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
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }
    Process
    {
        $UserApplication = [TeamDynamix_Api_Apps_UserApplication]::new()
        # Verify the specified security role exists
        $SecurityRole = Get-TDSecurityRole -ID $SecurityRoleId -AuthenticationToken $AuthenticationToken -Environment $WorkingEnvironment
        if ($SecurityRole)
        {
            $UserApplication.SecurityRoleId   = $SecurityRoleId
            $UserApplication.IsAdministrator  = $IsAdministrator
            $UserApplication.ID               = $SecurityRole.AppID
            $UserApplication.SecurityRoleName = $SecurityRole.Name
            $UserApplication.Name             = ($TDApplications | Where-Object {$_.AppID -eq (Get-TDSecurityRole -ID $SecurityRoleID -AuthenticationToken $AuthenticationToken -Environment $WorkingEnvironment).AppID}).Name
            return $UserApplication
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Unable to find security role $SecurityRoleID"
        }
    }
}

function ConvertFrom-TDWebAPIToClass
{
    [CmdletBinding(DefaultParameterSetName='URL')]
    Param
    (
        # URL of web page
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='URL',
                   Position=0)]
        [ValidateScript({
            if ($_ -eq ([uri]$_).AbsoluteUri)
            {
                $true
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Not a valid URL. Be sure to include the http[s]://'
            }
        })]
        [string]
        $URL,

        # Input data to be converted
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=0)]
        [string]
        $InputText,

        # Name of the function
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=1)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='URL',
                   Position=1)]
        $ClassName,

        # Specify attribute component for custom attributes
        [Parameter(Mandatory=$false,
                   ParameterSetName='Text',
                   Position=2)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='URL',
                   Position=2)]
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]
        $AttributeComponent,

        # Include TD_ class definition
        [Parameter(Mandatory=$false,
                   ParameterSetName='Text')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='URL')]
        [switch]
        $IncludeTD_Class
    )

    Begin
    {
        $ConstructorBlock1 = @"
    # Default constructor
    $ClassName ()
    {
    }

    # Constructor from object (such as a return from REST API)
    $ClassName ([psobject]`$$($ClassName.Split('_')[-1]))
    {
        foreach (`$Parameter in ([$ClassName]::new() | Get-Member -MemberType Property))
        {
            if (`$Parameter.Definition -notmatch '^datetime')
            {
                `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name)
            }
            else
            {
                if (`$Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if (`$null -ne `$this.`$(`$Parameter.Name))
                    {
                        `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name) | ForEach-Object {`$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    $ClassName(
"@
        $ConstructorBlock2 = @"
    {
        foreach (`$Parameter in ([$ClassName]::new() | Get-Member -MemberType Property))
        {
            if (`$Parameter.Definition -notmatch '^datetime')
            {
                `$this.`$(`$Parameter.Name) = (Get-Variable -Name `$Parameter.Name).Value
            }
            else
            {
                if (`$Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if (`$null -ne `$this.`$(`$Parameter.Name))
                    {
                        `$this.`$(`$Parameter.Name) = (Get-Variable -Name `$Parameter.Name).Value | ForEach-Object {`$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    `$this.`$(`$Parameter.Name) = (Get-Variable -Name `$Parameter.Name).Value | Get-Date
                }
            }
        }
    }
"@
        $ConstructorBlockTD_ = @"
    # Constructor from object (such as a return from REST API)
    TD_$ClassName ([psobject]`$$($ClassName.Split('_')[-1]))
    {
        foreach (`$Parameter in ([$ClassName]::new() | Get-Member -MemberType Property))
        {
            if (`$Parameter.Definition -notmatch '^datetime')
            {
                `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name)
            }
            else
            {
                if (`$Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if (`$null -ne `$this.`$(`$Parameter.Name))
                    {
                        `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name) | ForEach-Object {`$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    `$this.`$(`$Parameter.Name) = `$$($ClassName.Split('_')[-1]).`$(`$Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
"@
        # Do a late-replace of XXXCustomAttributesParameterNameXXX with the name of the custom attributes parameter (indeterminate at this time)
        $ConstructorBlockCustomAttributes = @"
    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]`$Attributes)
    {
        foreach (`$CustomAttribute in `$Attributes)
        {
            # Check to see if attribute is already present
            `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object ID -eq `$CustomAttribute.ID
            if (-not `$FoundAttribute)
            {
                # Add attribute
                `$this.XXXCustomAttributesParameterNameXXX += `$CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]`$Attributes,
        [boolean]`$Overwrite)
    {
        foreach (`$CustomAttribute in `$Attributes)
        {
            # Check to see if attribute is already present
            `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object ID -eq `$CustomAttribute.ID
            # Remove if Overwrite is set and the attribute is present
            if (`$FoundAttribute -and `$Overwrite)
            {
                `$this.RemoveCustomAttribute(`$CustomAttribute.ID)
            }
            if ((-not `$FoundAttribute) -or `$Overwrite)
            {
                # Add attribute
                `$this.XXXCustomAttributesParameterNameXXX += `$CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [int] `$AttributeID,
        [Int] `$AttributeValue)
    {
        # Check to see if attribute is already present on the asset
        `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object ID -eq `$AttributeID
        if (-not `$FoundAttribute)
        {
            # Add attribute
            `$this.XXXCustomAttributesParameterNameXXX += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new(`$AttributeID,`$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
        }
    }

    [void] AddCustomAttribute (
        [int]    `$AttributeID,
        [Int]    `$AttributeValue,
        [boolean]`$Overwrite)
    {
        # Check to see if attribute is already present
        `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object ID -eq `$AttributeID
        # Remove if Overwrite is set and the attribute is present
        if (`$FoundAttribute -and `$Overwrite)
        {
            `$this.RemoveCustomAttribute(`$AttributeID)
        }
        if ((-not `$FoundAttribute) -or `$Overwrite)
        {
            # Add attribute
            `$this.XXXCustomAttributesParameterNameXXX += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new(`$AttributeID,`$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   `$AttributeName,
        [string]   `$AttributeValue,
        [hashtable]`$TDAuthentication,
        [EnvironmentChoices]`$Environment)
    {
        # Check to see if attribute is already present
        `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object Name -eq `$AttributeName
        if (-not `$FoundAttribute)
        {
            # Add attribute
            `$this.XXXCustomAttributesParameterNameXXX += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new(`$AttributeName,`$AttributeValue,`'$AttributeComponent`',`$TDAuthentication,`$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   `$AttributeName,
        [string]   `$AttributeValue,
        [boolean]  `$Overwrite,
        [hashtable]`$TDAuthentication,
        [EnvironmentChoices]`$Environment)
    {
        # Check to see if attribute is already present
        `$FoundAttribute = `$this.XXXCustomAttributesParameterNameXXX | Where-Object Name -eq `$AttributeName
        # Remove if Overwrite is set and the attribute is present
        if (`$FoundAttribute -and `$Overwrite)
        {
            `$this.RemoveCustomAttribute(`$FoundAttribute.ID)
        }
        if ((-not `$FoundAttribute) -or `$Overwrite)
        {
            # Add attribute
            `$this.XXXCustomAttributesParameterNameXXX += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new(`$AttributeName,`$AttributeValue,`'$AttributeComponent`',`$TDAuthentication,`$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute `$(`$FoundAttribute.Name) is already present on `$this.Name."
        }
    }

    [void] RemoveCustomAttribute (
        [int] `$AttributeID)
    {
        `$UpdatedAttributeList = `$this.XXXCustomAttributesParameterNameXXX | Where-Object ID -ne `$AttributeID
        `$this.XXXCustomAttributesParameterNameXXX = `$UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] `$AttributeName)
    {
        `$UpdatedAttributeList = `$this.XXXCustomAttributesParameterNameXXX | Where-Object Name -ne `$AttributeName
        `$this.XXXCustomAttributesParameterNameXXX = `$UpdatedAttributeList
    }
"@
    }
    Process
    {
        $GenerateTD_Class = $false
        $GenerateCustomAttributesMethods = $false

        switch ($pscmdlet.ParameterSetName)
        {
            'URL'
            {
                $ClassParameterMembers = Get-URLTableData -URL $URL
            }
            'Text'
            {
                $ClassParameterMembers = Get-URLTableData -InputText $InputText
            }
        }
        # Check for special generation requirements, such as custom attributes or editable/required datetime objects
        foreach ($ClassParameter in $ClassParameterMembers)
        {
            # Set to add custom attribute methods if one of the parameters is a custom attribute
            if ($ClassParameter.Type -like '*TeamDynamix_Api_CustomAttributes_CustomAttribute*')
            {
                if (-not $AttributeComponent)
                {
                    Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Unable to proceed. Please specify the AttributeComponent parameter.'
                }
                $GenerateCustomAttributesMethods = $true
                $CustomAttributesParameterName = $ClassParameter.Name
            }
            # Check to see if there are required or editable parameters with a datetime type, which requires generation of TD_ class
            if ($ClassParameter.Required -or $ClassParameter.Editable)
            {
                # Set to generate TD_ class if a required or editable parameter is a datetime type
                if($ClassParameter.Type -like '*datetime*')
                {
                    $GenerateTD_Class = $true
                }
            }
        }
        # Set type pad width. Only pad to a maximum of ten characters. Padding gets hard to read much further out.
        $TypePadLength = ($ClassParameterMembers.Type | Where-Object {$_.Length -le 10} | Measure-Object -Maximum -Property Length).Maximum
        # Write main class description
        Write-Output "class $ClassName"
        Write-Output '{'
        foreach ($Parameter in $ClassParameterMembers)
        {
            Write-Output "`t$($Parameter.Type.PadRight($TypePadLength))`$$($Parameter.Name)"
        }
        Write-Output ''
        Write-Output $ConstructorBlock1
        for ($i = 0; $i -lt ($ClassParameterMembers.Count - 1); $i++)
        {
            Write-Output "`t`t$($ClassParameterMembers[$i].Type.PadRight($TypePadLength))`$$($ClassParameterMembers[$i].Name),"
        }
        Write-Output "`t`t$($ClassParameterMembers[$i].Type.PadRight($TypePadLength))`$$($ClassParameterMembers[$i].Name))"
        Write-Output $ConstructorBlock2
        $EditableParameters = $ClassParameterMembers | Where-Object Editable -eq $true
        if ($EditableParameters)
        {
            # Set parameter pad width
            $PadLength = ($EditableParameters.Name | Measure-Object -Maximum -Property Length).Maximum
            Write-Output ''
            Write-Output "`t# Convenience constructor for editable parameters"
            Write-Output "`t$ClassName("
            for ($i = 0; $i -lt ($EditableParameters.Count - 1); $i++)
            {
                if ($EditableParameters[$i].Editable)
                {
                    Write-Output "`t`t$($EditableParameters[$i].Type.PadRight($TypePadLength))`$$($EditableParameters[$i].Name),"
                }
            }
            Write-Output "`t`t$($EditableParameters[$i].Type.PadRight($TypePadLength))`$$($EditableParameters[$i].Name))"
            Write-Output "`t{"
            foreach ($Parameter in $EditableParameters)
            {
                if ($Parameter.Type -notmatch 'datetime')
                {
                    Write-Output "`t`t`$this.$($Parameter.Name.PadRight($PadLength)) = `$$($Parameter.Name)"
                }
                else
                {
                    Write-Output "`t`t`$this.$($Parameter.Name.PadRight($PadLength)) = `$$($Parameter.Name.PadRight($PadLength)) | Get-Date"
                }
            }
            Write-Output "`t}"
            if ($GenerateCustomAttributesMethods)
            {
                Write-Output ''
                Write-Output $ConstructorBlockCustomAttributes.Replace('XXXCustomAttributesParameterNameXXX',$CustomAttributesParameterName)
            }
        }
        Write-Output '}'
        if ($GenerateTD_Class -or $IncludeTD_Class)
        {
            # Rewrite datetime types to strings for TD_ class, since TD requires specific date format
            foreach ($Parameter in $ClassParameterMembers)
            {
                if (($Parameter.Type -eq '[DateTime]') -or ($Parameter.Type -eq '[System.Nullable[DateTime]]'))
                {
                    $Parameter.Type = '[String]'
                }
                if (($Parameter.Type -eq '[DateTime[]]') -or ($Parameter.Type -eq '[System.Nullable[DateTime[]]]'))
                {
                    $Parameter.Type = '[String[]]'
                }
            }
            # Set new type pad width because types have changed. Only pad to a maximum of ten characters. Padding gets hard to read much further out.
            $TypePadLength = ($ClassParameterMembers.Type | Where-Object {$_.Length -le 10} | Measure-Object -Maximum -Property Length).Maximum
            # Write TD_ class description
            Write-Output ''
            Write-Output "class TD_$ClassName"
            Write-Output '{'
            foreach ($Parameter in $ClassParameterMembers)
            {
                Write-Output "`t$($Parameter.Type.PadRight($TypePadLength))`$$($Parameter.Name)"
            }
            Write-Output ''
            Write-Output $ConstructorBlockTD_
            Write-Output '}'
        }
    }
}

function ConvertFrom-TDWebAPIToEnum
{
    [CmdletBinding(DefaultParameterSetName='URL')]
    Param
    (
        # Input data to be converted
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=0)]
        $InputText,

        # URL of web page
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='URL',
                   Position=0)]
        [ValidateScript({
            if ($_ -eq ([uri]$_).AbsoluteUri)
            {
                $true
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Not a valid URL. Be sure to include the http[s]://'
            }
        })]
        [string]
        $URL,

        # Name of the enum
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=1)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='URL',
                   Position=1)]
        [string]
        $EnumName
        )

    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'URL'
            {
                $EnumMembers = Get-URLTableData -URL $URL
            }
            'Text'
            {
                $EnumMembers = Get-URLTableData -InputText $InputText
            }
        }
        $PadLength = ($EnumMembers.Name | Measure-Object -Maximum -Property Length).Maximum
        Write-Output "enum $EnumName {"
        for ($i = 0; $i -lt ($EnumMembers.Count - 1); $i++)
        {
            Write-Output "`t$($EnumMembers[$i].Name.PadRight($PadLength)) = $($EnumMembers[$i].Value)"
        }
        Write-Output "`t$($EnumMembers[$i].Name.PadRight($PadLength)) = $($EnumMembers[$i].Value)}"
    }
}

function ConvertFrom-TDWebAPIToFunction
{
    [CmdletBinding(DefaultParameterSetName='URL')]
    Param
    (
        # URL of web page
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='URL',
                   Position=0)]
        [ValidateScript({
            if ($_ -eq ([uri]$_).AbsoluteUri)
            {
                $true
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Not a valid URL. Be sure to include the http[s]://'
            }
        })]
        [string]
        $URL,

        # Input data to be converted
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=0)]
        [string]
        $InputText,

        # Name of the function
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=1)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='URL',
                   Position=1)]
        $FunctionName,

        # Include all parameters, not just the writeable ones
        [Parameter(Mandatory=$false,
                   ParameterSetName='Text')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='URL')]
        [switch]
        $IncludeAll
        )

    Begin
    {
        $Block1 = @"
<#
.Synopsis
    ?? in TeamDynamix.
.DESCRIPTION
    ?? in TeamDynamix.
"@
        $Block2 = @"
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>$FunctionName

    ??
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function $FunctionName
{
    [CmdletBinding(XXXShouldProcessXXX)]
    Param
    (
"@
    $Block3 = @"
        # TeamDynamix authentication token
        [Parameter(Mandatory=`$false)]
        [hashtable]
        `$AuthenticationToken = `$TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=`$false)]
        [EnvironmentChoices]
        `$Environment
    )
    Begin
    {
        Write-ActivityHistory "-----``nIn $($MyInvocation.MyCommand.Name)"
        `$ContentType = 'application/json; charset=utf-8'
        `$BaseURI = Get-URI -Environment `$Environment
        if (-not `$AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
        # Manage parameters
        #  Identify local parameters to be ignored
        `$LocalIgnoreParameters = @()
    }
    Process
    {
    }
    End
    {
        Write-ActivityHistory "Leaving $($MyInvocation.MyCommand.Name)``n-----"
    }
}
"@
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'URL'
            {
                $FunctionParameterMembers = Get-URLTableData -URL $URL
            }
            'Text'
            {
                $FunctionParameterMembers = Get-URLTableData -InputText $InputText
            }
        }
        # Write help text
        Write-Output $Block1
        foreach ($Parameter in ($FunctionParameterMembers | Where-Object {$_.Editable -eq $true -or $_.Required -eq $true -or $IncludeAll}))
        {
            Write-Output ".PARAMETER $($Parameter.Name)"
            if ($Parameter.Summary)
            {
                Write-Output "    $($Parameter.Summary.Replace('Gets or sets ','').Substring(0,1).ToUpper())$($Parameter.Summary.Replace('Gets or sets ','').Substring(1))"
            }
        }
        # Write function definition and parameters
        #  For New- and Set- functions, add the SupportsShouldProcess directive to Parameter definition
        if ($FunctionName.Split('-')[0] -in 'New','Set')
        {
            Write-Output $Block2.Replace('XXXShouldProcessXXX','SupportsShouldProcess=$true')
        }
        else
        {
            Write-Output $Block2.Replace('XXXShouldProcessXXX','')
        }
        foreach ($Parameter in ($FunctionParameterMembers | Where-Object {$_.Editable -eq $true -or $_.Required -eq $true -or $IncludeAll}))
        {
            if ($Parameter.Summary)
            {
                Write-Output "`t`t# $($Parameter.Summary.Replace('Gets or sets ','').Substring(0,1).ToUpper())$($Parameter.Summary.Replace('Gets or sets ','').Substring(1))"
            }
            else
            {
                Write-Output "`t`t#"
            }
            if ($Parameter.Required)
            {
                Write-Output "`t`t[Parameter(Mandatory=`$true)]"
            }
            else
            {
                Write-Output "`t`t[Parameter(Mandatory=`$false)]"
            }
            Write-Output "`t`t$($Parameter.Type)"
            if ($Parameter.Type.Trim() -eq '[Guid]')
            {
                Write-Output "`t`t`$$($Parameter.Name) = [guid]::Empty,"
            }
            else
            {
                Write-Output "`t`t`$$($Parameter.Name),"
            }
            Write-Output ""
        }
        # Finish function framework
        Write-Output $Block3
    }
}

function Compare-TDAPIDefinitions
{
    [CmdletBinding(DefaultParameterSetName='All')]
    [Alias()]
    [OutputType([int])]
    Param
    (
        # URL of API to compare
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='URL',
                   Position=0)]
        [uri]
        $APIURL,

        # Process all APIs
        [Parameter(Mandatory=$false,
                   ParameterSetName='All')]
        [switch]
        $All
    )

    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'All'
            {
                # Get list of classes and enums in the module
                $APINames = (Get-Module TeamDynamix).ImplementingAssembly.DefinedTypes | Where-Object {$_.IsPublic -eq $true -and $_.Name -notmatch '^TD_'} |Select-Object -ExpandProperty Name | ForEach-Object {$_.Replace('_','.')}
                Write-ActivityHistory ($APINames | Out-String)
                # Call this function for each class and enum
                $APINames | ForEach-Object { "$script:DefaultTDBaseURI)/TDWebApi/Home/type/$_" } | Compare-TDAPIDefinitions
            }
            'URL'
            {
                Write-ActivityHistory $APIURL
                $APIURLChangedOrDeprecated = $false
                # Adjust the URL to find the preview site
                $PreviewAPIURL = $APIURL.ToString().Replace('teamdynamix.com/TDWebApi','teamdynamixpreview.com/TDWebApi')
                try
                {
                    # Get info from the current site
                    $CurrentDefinition = Get-URLTableData -URL $APIURL -ErrorAction Stop
                }
                catch
                {
                    if ($_.Exception.Message -like '*Status code 404*')
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -Message "$APIURL returned 404 not found."
                    }
                    elseif ($_.Exception.Message -like '*Status code 302*')
                    {
                        $APIURLChangedOrDeprecated = $true
                    }
                    else
                    {
                        Write-ActivityHistory -ErrorRecord $_ -ErrorMessage "Getting data for $APIURL."
                    }
                }
                try
                {
                    # Get info from the preview site
                    $PreviewDefinition = Get-URLTableData -URL $PreviewAPIURL -ErrorAction Stop
                }
                catch
                {
                    if ($_.Exception.Message -like '*Status code 404*')
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -Message "$PreviewAPIURL returned 404 not found."
                    }
                    elseif ($_.Exception.Message -like '*Status code 302*')
                    {
                        $APIURLChangedOrDeprecated = $true
                    }
                    else
                    {
                        Write-ActivityHistory -ErrorRecord $_ -ErrorMessage "Getting data for $PreviewAPIURL."
                    }
                }
                # Additions are items that are in the preview, but not in the current, deletions are in the current, but not in the preview
                #  Currently, only testing by name.
                $Additions = $PreviewDefinition | Where-Object {$CurrentDefinition.Name -notcontains $_.Name}
                $Deletions = $CurrentDefinition | Where-Object {$PreviewDefinition.Name -notcontains $_.Name}
                if ($APIURLChangedOrDeprecated -eq $true)
                {
                    $Deletions = 'API changed or deleted.'
                }
                if ($Additions -or $Deletions)
                {
                    [pscustomobject]@{
                        API       = $APIURL.ToString().split('/')[-1].Replace('.','_')
                        Additions = $Additions
                        Deletions = $Deletions
                    }
                }
            }
        }
    }
}

function Get-TDOpenTicketActivity
{
    [CmdletBinding(DefaultParameterSetName='DateRange')]
    Param
    (
        # Technician name
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^\w+\.\d+$')]
        [string[]]
        $TechnicianName,

        # Client name
        [Parameter(Mandatory=$false)]
        [ValidatePattern('^\w+\.\d+$')]
        [string[]]
        $ClientName,

        # Days to include in the report
        [Parameter(Mandatory=$true,
                   ParameterSetName='Interval')]
        [int]
        $ReportInterval,

        # Starting date for tickets to include in the report
        [Parameter(Mandatory=$false,
                   ParameterSetName='DateRange')]
        [ValidateScript({
            ($_ -lt (Get-Date))})]
        [datetime]
        $ReportFrom,

        # Ending date for tickets to include in the report
        [Parameter(Mandatory=$false,
                   ParameterSetName='DateRange')]
        [datetime]
        $ReportTo = (Get-Date),

        # Sections to include in the report
        [Parameter(Mandatory=$false)]
        [ValidateSet('Ticket Counts','Recent Activity','Historical Activity','All')]
        [string[]]
        $ReportSection = 'All',

        # Adds special section for tickets with no update during the reporting period
        [Parameter(Mandatory=$false)]
        [switch]
        $NoUpdate,

        # Output file name
        [Parameter(Mandatory=$false)]
        [string]
        $OutputFileName,

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
                Name        = 'UnitName'
                ValidateSet = $TDAccounts.Name
                HelpText    = 'Name of unit(s)'
            }
            @{
                Name        = 'GroupName'
                ValidateSet = $TDGroups.Name
                HelpText    = 'Name of support group(s)'
            }
		)
		$DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    Begin
    {
        # Create convenience variables for dynamic parameters
        $UnitName  = $DynamicParameterDictionary.UnitName.Value
        $GroupName = $DynamicParameterDictionary.GroupName.Value

        # List of open status names
        $OpenStatuses = (Get-TDTicketStatus -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object StatusClass -in @('New','InProcess','OnHold')).Name

        # List of closed status names
        $ClosedStatuses = (Get-TDTicketStatus -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object StatusClass -in @('Cancelled','Completed')).Name

        function Format-TicketOutputReport
        {
            Param
            (
                # Selection from tickets
                [Parameter(Mandatory=$true,
                           Position=0)]
                $TicketSelection,

                # Selection from feed
                [Parameter(Mandatory=$true,
                           Position=1)]
                $FeedSelection
            )
            # Pretty format for tickets and comments
            $TicketSelection | Sort-Object -Property CreatedDate -Descending | ForEach-Object {Write-Output "<H2>$($_.Title)</H2>`r`n<H3>`r`n`tTicket ID: $($_.ID)<BR>`r`n`tOpened: $(Get-Date -Date $_.CreatedDate -Format "M/d/yyyy h:mm tt")<BR>`r`n`tRequestor: $($_.RequestorName)<BR>`r`n`tStatus: $($_.StatusName)`r`n</H3>`r`n<H3>Request</H3>`r`n<BLOCKQUOTE>$($_.Description)</BLOCKQUOTE><H3>Updates</H3>"; ($FeedSelection | Where-Object Name -eq $_.ID).Group | Sort-Object -Property CreatedDate -Descending | ForEach-Object {Write-Output "<H4>`r`n`t$(Get-Date -Date $_.CreatedDate -Format "M/d/yyyy h:mm tt")<BR>`r`n`t$($_.CreatedFullName)`r`n</H4>`r`n<BLOCKQUOTE>$($_.Body)`r`n</BLOCKQUOTE>`r`n"}; Write-Output "<HR>`r`n"}
        }
        function Format-TicketFeedCommenterCounts
        {
            Param
            (
                # Selection from feed
                [Parameter(Mandatory=$false)]
                $FeedSelection
            )
            if ($FeedSelection) {
                # List commenters, from most frequent to least
                $CommenterTable = $FeedSelection | Select-Object -ExpandProperty Group | Group-Object -Property CreatedFullName | Sort-Object -Property Count -Descending
                if ($CommenterTable.Name -ne '') {
                    Write-Output "<H3>`r`n`tTicket commenters`r`n</H3>`r`n"
                    Write-Output "<table>`r`n"
                    Write-Output "<tr><th>Name</th><th>Comment Count</th></tr>`r`n"
                    $CommenterTable | ForEach-Object {Write-Output "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>$($_.Name)`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$($_.Count)`r`n`t</td>`r`n</tr>`r`n"}
                    Write-Output "</table>`r`n"
                }
            }
            else {
                # No comments
                Write-Output "<H3>`r`n`tTicket commenters`r`n</H3>`r`n"
                Write-Output "No comments`r`n"
            }
        }
        function Format-TicketRequestorCounts
        {
            Param
            (
                # Selection from tickets
                [Parameter(Mandatory=$false)]
                $TicketSelection
            )
            if ($TicketSelection) {
                # List requestors, from most frequent to least
                $RequestorTable = $TicketSelection | Group-Object -Property RequestorName | Sort-Object -Property Count -Descending
                if ($CommenterTable.Name -ne '') {
                    Write-Output "<H3>Ticket requestors</H3>"
                    Write-Output "<table>"
                    Write-Output "<tr><th>Name</th><th>Request Count</th></tr>`r`n"
                    $RequestorTable | ForEach-Object {Write-Output "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>$($_.Name)`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$($_.Count)`r`n`t</td>`r`n</tr>`r`n"}
                    Write-Output "</table>`r`n"
                }
            }
            else {
                # No new requests
                Write-Output "<H3>`r`n`tTicket requestors`r`n</H3>`r`n"
                Write-Output "No requests`r`n"
            }
        }
        function Format-TicketNoUpdate
        {
            Param
            (
                # Selection from tickets
                [Parameter(Mandatory=$true)]
                $TicketSelection
            )
            # Build table of clickable stale tickets
            $TicketAppURI = Get-URI -Environment $Environment -Portal
            Write-Output "<table class=`"paddedTable`">`r`n"
            Write-Output "<tr><th>ID</th><th>Last update</th><th>Title</th></tr>`r`n"
            $TicketSelection | Sort-Object -Property ModifiedDate | ForEach-Object {Write-Output "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left><a href=`"$TicketAppURI/Apps/$TicketingAppID/Tickets/TicketDet?TicketID=$($_.ID)`" target=`"_blank`">$($_.ID)</a></td><td><P ALIGN=Left>$(Get-Date -Date $_.ModifiedDate -Format "MM/dd/yyyy h:mm tt")`r`n</td>`r`n`t<td>`r`n`t`t<P ALIGN=Left>$($_.Title)`r`n`t</td>`r`n</tr>`r`n"}
            Write-Output "</table>`r`n"
        }
    }
    Process
    {
        # Check to see if a unit, group, technician, or client has been specified.
        if (-not $UnitName -and -not $GroupName -and -not $TechnicianName -and -not $ClientName) {
            throw 'Please specify a unit, group, technician, or client to report on.'
        }

        # Initialize report sections
        $ReportHeader     = ''
        $ReportCounts     = ''
        $ReportRecent     = ''
        $ReportHistorical = ''

        # Initialize collections
        $TicketIDs = @()
        $ReportNameList = @()
        $ReportSections = @()

        # Count report parts for progress bar
        $PartsCount = 3 + $TechnicianName.Count + $ClientName.Count
        if ($UnitName)  {$PartsCount ++}
        if ($GroupName) {$PartsCount ++}
        $PercentComplete = 0

        # Set report dates (skip back through weekends)
        if ($ReportInterval) {
            $ReportFrom = Get-WeekdayDate ([datetime]::Today).AddDays(-$ReportInterval)
            $ReportTo = Get-Date -Format "M/d/yyyy h:mm tt"
        }
        # Set format of dates (date only if starting at midnight, otherwise include the time)
        if ($ReportFrom.TimeOfDay -eq 0) {$ReportFromString = $ReportFrom.ToShortDateString()}
        else {$ReportFromString = Get-Date -Date $ReportFrom -Format "M/d/yyyy h:mm tt"}
        if ($ReportTo.TimeOfDay -eq 0 -or $ReportTo.Date -eq (Get-Date).Date) {$ReportToString = $ReportTo.ToShortDateString()}
        else {$ReportToString = Get-Date -Date $ReportTo -Format "M/d/yyyy h:mm tt"}

        if ($TechnicianName) {
            $UserIDs = @()
            foreach ($User in $TechnicianName) {
                # Get user information
                Write-Progress -ID 101 -Activity "Technician: $User" -Status 'Retrieving user information' -PercentComplete ($PercentComplete += + (100 / $PartsCount / 3))
                $TDUser       = Get-TDUser -UserName "$User@osu.edu" -AuthenticationToken $AuthenticationToken -Environment $Environment
                $UserIDs     += $TDUser.UID

                # Add to report name
                $ReportNameList += $User

                # Get open tickets
                Write-Progress -ID 101 -Activity "Technician: $User" -Status 'Retrieving open tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / 3))
                $TicketIDs += (Get-TDTicket -UpdatedByUid $TDUser.UID -StatusClassNames New,InProcess,OnHold -CreatedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

                # Get tickets that closed during the review interval
                Write-Progress -ID 101 -Activity "Technician: $User" -Status 'Retrieving closed tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / 3))
                $TicketIDs += (Get-TDTicket -UpdatedByUid $TDUser.UID -ClosedDateFrom $ReportFrom -ClosedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID
            }

            # Set default report sections
            if ($ReportSection -eq 'All') {$ReportSections += @('Ticket Counts','Recent activity')}
            else {$ReportSections = $ReportSection}
        }
        if ($ClientName) {
            $UserIDs = @()
            foreach ($User in $ClientName) {
                # Get user information
                Write-Progress -ID 101 -Activity "Client: $User" -Status 'Retrieving user information' -PercentComplete ($PercentComplete += (100 / $PartsCount / ($Clients.Count + 2)))
                $TDUser       = Get-TDUser -UserName "$User@osu.edu" -AuthenticationToken $AuthenticationToken -Environment $Environment
                $UserIDs     += $TDUser.UID

                # Add to report name
                $ReportNameList += $User
            }
            # Get open tickets
            Write-Progress -ID 101 -Activity "Client(s)" -Status 'Retrieving open tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / ($Clients.Count + 2)))
            $TicketIDs += (Get-TDTicket -RequestorUids $UserIDs -StatusClassNames New,InProcess,OnHold -CreatedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Get tickets that closed during the review interval
            Write-Progress -ID 101 -Activity "Client(s)" -Status 'Retrieving closed tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / ($Clients.Count + 2)))
            $TicketIDs += (Get-TDTicket -RequestorUids $UserIDs -ClosedDateFrom $ReportFrom -ClosedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Set default report sections
            if ($ReportSection -eq 'All') {$ReportSections += @('Ticket Counts','Recent activity','Historical activity')}
            else {$ReportSections = $ReportSection}
        }
        if ($UnitName) {
            # Set report name
            $ReportNameList += $UnitName

            # Get open tickets
            Write-Progress -ID 101 -Activity "Unit(s)" -Status 'Retrieving open tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / 2))
            $TicketIDs += (Get-TDTicket -AccountNames $UnitName -StatusClassNames New,InProcess,OnHold -CreatedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Get tickets that closed during the review interval
            Write-Progress -ID 101 -Activity "Unit(s)" -Status 'Retrieving closed tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / 2))
            $TicketIDs += (Get-TDTicket -AccountNames $UnitName -ClosedDateFrom $ReportFrom -ClosedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Set default report sections
            if ($ReportSection -eq 'All') {$ReportSections += @('Ticket Counts','Recent activity','Historical activity')}
            else {$ReportSections = $ReportSection}
        }
        if ($GroupName) {
            # Set report name
            $ReportNameList += $GroupName

            # Get open tickets
            Write-Progress -ID 101 -Activity "Group(s)" -Status 'Retrieving open tickets' -PercentComplete ($PercentComplete += (100 / $PartsCount / 2))
            $TicketIDs += (Get-TDTicket -ResponsibilityGroupNames $GroupName -StatusClassNames New,InProcess,OnHold -CreatedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Get tickets that closed during the review interval
            Write-Progress -ID 101 -Activity "Group(s)" -Status 'Retrieving open tickets' -PercentComplete ($PercentComplete + (100 / $PartsCount / 2))
            $TicketIDs += (Get-TDTicket -ResponsibilityGroupNames $GroupName -ClosedDateFrom $ReportFrom -ClosedDateTo $ReportTo -AuthenticationToken $AuthenticationToken -Environment $Environment).ID

            # Set default report sections
            if ($ReportSection -eq 'All') {$ReportSections += @('Ticket Counts','Recent activity','Historical activity')}
            else {$ReportSections = $ReportSection}

            # Add counts by unit, counts by tech
        }

        # Assemble report name
        $ReportName = $ReportNameList -join ', '

        # Eliminate ticket duplicates and get detailed ticket information
        $Tickets = $TicketIDs | Select-Object -Unique | ForEach-Object {Write-Progress -ID 101 -Activity 'Ticket data' -Status "Retrieving detailed ticket data for ID $_" -PercentComplete ($PercentComplete += (100 / $PartsCount/ $TicketIDs.Count)); Get-TDTicket -ID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}

        # Get feed information for open tickets
        if ($Tickets.ID)
        {
            $TicketsFeed = $Tickets.ID | ForEach-Object {Write-Progress -ID 101 -Activity 'Ticket feed' -Status "Retrieving ticket feed data for ID $_" -PercentComplete ($PercentComplete += (100 / $PartsCount / $Tickets.Count)); Get-TDTicketFeed -ID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}
            $TicketsFeedReviewDate = $TicketsFeed | Where-Object {$_.CreatedDate -gt $ReportFrom -and $_.CreatedDate -lt $ReportTo} | Group-Object -Property ItemID
        }

        # Set output file if none is set
        if ($OutputFileName -eq '') {
            # Watch for file name too long - use a shorter name if necessary
            if (("$ReportName.html").Length -le 255) {$OutputFileName = Join-Path ([System.IO.Path]::GetTempPath()) "$ReportName.html"}
            else {$OutputFileName = Join-Path ([System.IO.Path]::GetTempPath()) "Open Ticket Activity - $(Get-Date -Format "M-d-yyyy").html"}
        }
        Write-Progress -ID 101 -Activity "Building report" -Status 'Compiling report data' -PercentComplete 95
        # Populate report header
        $ReportHeader  = "<html>`r`n"
        $ReportHeader += "<head>`r`n"
        $ReportHeader += "<style>`r`n"
        $ReportHeader += "`t.paddedTable td`r`n"
        $ReportHeader += "`t{padding:0 15px 0 0}`r`n"
        $ReportHeader += "</style>`r`n"
        $ReportHeader += "</head>`r`n"
        $ReportHeader += "<body>`r`n"
        $ReportHeader += "<H1>Ticket info for $ReportName between $ReportFromString and $ReportToString</H1>`r`n"
        $ReportHeader += "<H2>Navigation</H2>`r`n"
        $ReportHeader += "<nav>`r`n"
        if ($ReportSections -contains 'Ticket Counts') {$ReportHeader += '<a href="#Counts">Ticket Counts</a>'}
        if ($NoUpdate) {
            if ($ReportHeader.EndsWith('</a>')) {$ReportHeader += ' | '}
            $ReportHeader += '<a href="#NoUpdate">Stale Tickets</a>'
        }
        if ($ReportSections -contains 'Recent Activity') {
            if ($ReportHeader.EndsWith('</a>')) {$ReportHeader += ' | '}
            $ReportHeader += '<a href="#Recent">Recent Activity</a>'
        }
        if ($ReportSections -contains 'Historical Activity') {
            if ($ReportHeader.EndsWith('</a>')) {$ReportHeader += ' | '}
            $ReportHeader += '<a href="#Open">All Open Tickets</a>'
        }
        $ReportHeader += "`r`n</nav>`r`n"
        $ReportHeader += "<HR><HR>`r`n"

        # Populate report footer
        $ReportFooter  = "</body>`r`n"
        $ReportFooter += "</html>`r`n"

        # Populate report sections
        switch ($ReportSections | Select-Object -Unique) {
            {$_ -contains 'Ticket Counts'} {
                # Report for ticket counts
                $ReportCounts  = "<a name=`"Counts`"></a>`r`n"
                $ReportCounts += "<H1>Ticket counts between $ReportFromString and $ReportToString</H1>`r`n"
                $ReportCounts += "<table>`r`n"
                $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>New tickets created:`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(($Tickets | Where-Object {$_.CreatedDate -gt $ReportFrom -and $_.CreatedDate -lt $ReportTo}).Count)`r`n`t</td>`r`n</tr>`r`n"
                $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Tickets closed:     `r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(($Tickets | Where-Object StatusName  -in $ClosedStatuses).Count)`r`n`t</td>`r`n</tr>`r`n"
                if ($TechnicianName) {$ReportCounts += "<tr><td><P ALIGN=Left>Updates by technician:</td><td><P ALIGN=Right>$(($TicketsFeedReviewDate | Select-Object -ExpandProperty Group | Where-Object CreatedUID -in $UserIDs).Count)</td></tr>`r`n"}
                if (($UnitName -or $GroupName) -and (($Tickets | Where-Object StatusName -in $ClosedStatuses).Count -ne 0)) {
                    $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Average days to close:`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>{0:N2}`r`n`t</td>`r`n</tr>`r`n" -f ($Tickets | Where-Object StatusName -in $ClosedStatuses | ForEach-Object {($_.CompletedDate - $_.CreatedDate).Days} | Measure-Object -Average).Average
                    $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Median days to close: `r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(Get-Median ($Tickets | Where-Object StatusName -in $ClosedStatuses | ForEach-Object {($_.CompletedDate - $_.CreatedDate).Days}))`r`n`t</td>`r`n</tr>`r`n"
                }
                $ReportCounts +=     "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Tickets remaining open:`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(($Tickets     | Where-Object StatusName -in $OpenStatuses).Count)`r`n`t</td>`r`n</tr>`r`n"
                if ($TechnicianName -and -not ($UnitName -or $GroupName -or $ClientName)) {
                    $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Ticket updates posted: `r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(($TicketsFeed | Where-Object CreatedUID -in $UserIDs     ).Count)`r`n`t</td>`r`n</tr>`r`n"
                }
                elseif ($UnitName -or $GroupName) {
                    $ReportCounts += "<tr>`r`n`t<td>`r`n`t`t<P ALIGN=Left>Ticket updates posted:`r`n`t</td>`r`n`t<td>`r`n`t`t<P ALIGN=Right>$(($TicketsFeed | Where-Object {$_.CreatedDate -gt $ReportFrom -and $_.CreatedDate -lt $ReportTo}).Count)`r`n`t</td>`r`n</tr>`r`n"
                }
                $ReportCounts += "</table>`r`n"
                if ($UnitName -or $GroupName) {
                    $ReportCounts += "<HR>`r`n"
                    $ReportCounts += Format-TicketRequestorCounts -TicketSelection $Tickets
                }

                if ($UnitName -or $GroupName) {
                    $ReportCounts += "<HR>`r`n"
                    $ReportCounts += Format-TicketFeedCommenterCounts -FeedSelection $TicketsFeedReviewDate
                }
                $ReportCounts += "<HR><HR>`r`n"
            }
            {$_ -contains 'Recent activity'} {
                # Report for activity on open tickets since specified date
                $ReportRecent  = "<a name=`"Recent`"></a>`r`n"
                $ReportRecent += "<H1>Tickets with activity between $ReportFromString and $ReportToString</H1>`r`n"
                if ($TicketsFeedReviewDate.Count -eq 0) {
                    $ReportRecent += "No new activity`r`n"
                }
                else {
                    $ReportRecent += Format-TicketOutputReport -TicketSelection ($Tickets | Where-Object ID -in $TicketsFeedReviewDate.Name) -FeedSelection ($TicketsFeed | Group-Object -Property ItemID)
                }
                $ReportRecent += "<HR>`r`n"
            }
            {$_ -contains 'Historical activity'} {
                # Report for open tickets
                $ReportHistorical  = "<a name=`"Open`"></a>`r`n"
                $ReportHistorical += "<H1>Tickets open between $ReportFromString and $ReportToString</H1>`r`n"
                if ($Tickets.Count -eq 0) {
                    $ReportHistorical += "No tickets open between specified date and report date.`r`n"
                }
                else {
                    $ReportHistorical += Format-TicketOutputReport -TicketSelection $Tickets -FeedSelection ($TicketsFeed | Group-Object -Property ItemID)
                }
                $ReportHistorical += "<HR>`r`n"
            }
        }
        if ($NoUpdate) {
            # Report for open tickets
            $ReportNoUpdate  = "<a name=`"NoUpdate`"></a>`r`n"
            $ReportNoUpdate += "<H1>Tickets with no updates between $ReportFromString and $ReportToString</H1>`r`n"
            # Select tickets with no updates in the reporting period
            $StaleTickets = $Tickets | Where-Object ModifiedDate -lt $ReportFrom
            if ($StaleTickets.Count -eq 0) {
                    $ReportNoUpdate += "No stale tickets.`r`n"
            }
            else {
                $ReportNoUpdate += Format-TicketNoUpdate -TicketSelection $StaleTickets
            }
            $ReportNoUpdate += "<HR><HR>`r`n"
        }

        # Assemble report
        $ReportHeader     | Out-File $OutputFileName
        $ReportCounts     | Out-File $OutputFileName -Append
        $ReportNoUpdate   | Out-File $OutputFileName -Append
        $ReportRecent     | Out-File $OutputFileName -Append
        $ReportHistorical | Out-File $OutputFileName -Append
        $ReportFooter     | Out-File $OutputFileName -Append
    }
    End
    {
        return $OutputFileName
    }
}

function Get-TDTicketActivityCounts
{
    [CmdletBinding(DefaultParameterSetName='Date')]
    Param
    (
        # Use GUI to pick dates
        [Parameter(Mandatory=$true,
                   ParameterSetName='GUI')]
        [switch]
        $GUI,

        # Starting date to get ticket counts
        [Parameter(Mandatory=$false,
                   ParameterSetName='Date')]
        [datetime]
        $StartDate,

        # Number of days for ticket counts
        [Parameter(Mandatory=$false,
                   ParameterSetName='Date')]
        [int]
        $Days = 1,

        # Starting date for comparison
        [Parameter(Mandatory=$false,
                   ParameterSetName='Date')]
        [datetime]
        $CompareDate,

        # Do not output pretty report format
        [Parameter(Mandatory=$false)]
        [switch]
        $NoReport,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    if ($GUI) {
        # Use GUI to get dates for start, end, and comparison
        Write-Host 'Select a date range to review'
        $DateRange = Get-CalendarDateGUI -MaxDates 30
        # Starts at midnight of selected day
        $StartDate = $DateRange.Start
        # Ends at midnight of day after the end of the selection (only includes data through the end of the selection)
        $EndDate = ($DateRange.End).AddDays(1)
        # Start date for comparison - must be before $StartDate - will calculate end comparison date based on $StartDate and $EndDate difference
        do {
            Write-Host 'Select a prior date for start of comparison data'
            $CompareDate = (Get-CalendarDateGUI -MaxDates 1).Start
        }
        until ($CompareDate -lt $StartDate)
    }
    else {
        # Use command line or defaults to get dates for start, end, and comparison
        if ($StartDate -gt [datetime]::Today) {
            throw 'Specify a starting date in the past'
        }
        if (-not $StartDate) {$StartDate = Get-WeekdayDate ([datetime]::Today.AddDays(-1))}
        if (-not $CompareDate) {$CompareDate = $StartDate.AddDays(-7)}
        if ($CompareDate -ge $StartDate) {
            throw 'Specify a date prior to the start for comparison data'
        }
        $EndDate = $StartDate.AddDays($Days)
    }

    # Set date string for review interval
    if ($StartDate -eq ($EndDate).AddDays(-1))
    {
        # One day
        $DateString = $StartDate.ToShortDateString()
    }
    else
    {
        # Date range
        $DateString = "from $($StartDate.ToShortDateString()) to $($EndDate.AddDays(-1).ToShortDateString())"
    }

    # Set date string for history
    if ((($StartDate - $CompareDate).Days % 7) -eq 0)
    {
        $WeeksAgo = ($StartDate - $CompareDate).Days / 7
        if ($WeeksAgo -eq 1)
        {
            $DateStringHistory = "1 week ago"
        }
        else
        {
            $DateStringHistory = "$WeeksAgo weeks prior"
        }
    }
    else
    {
        $DateStringHistory = "$(($StartDate - $CompareDate).Days) days prior"
    }

    # Retrieve tickets for specified dates
    $Tickets = [PSCustomObject]@{
        StartDate     = $StartDate
        EndDate       = $EndDate
        CompareDate   = $CompareDate
        Opened        = Get-TDTicket -CreatedDateFrom $StartDate   -CreatedDateTo $EndDate                                 -AuthenticationToken $AuthenticationToken -Environment $Environment
        Closed        = Get-TDTicket -ClosedDateFrom  $StartDate   -ClosedDateTo  $EndDate                                 -AuthenticationToken $AuthenticationToken -Environment $Environment
        OpenedCompare = Get-TDTicket -CreatedDateFrom $CompareDate -CreatedDateTo ($CompareDate + ($EndDate - $StartDate)) -AuthenticationToken $AuthenticationToken -Environment $Environment
    }

    if ($NoReport) {return $Tickets}
    else {
        # Write text to output
        Write-Output "Tickets Opened $DateString"
        Write-Output "`tTotal: $($Tickets.Opened.Count)"
        Write-Output "`tCompare to $($Tickets.OpenedCompare.Count) from $DateStringHistory"
        $Tickets.Opened | Group-Object ResponsibleGroupName | Sort-Object -Descending Count | Select-Object Count,@{Name="Support Team";Expression={$_.Name}} | Out-String
        Write-Output "Tickets Closed $DateString"
        Write-Output "`tTotal: $($Tickets.Closed.Count)"
        Write-Output "`tTickets opened and closed $($DateString): $(($Tickets.Opened | Where-Object {($_.CreatedDate).DayOfYear -eq ($_.CompletedDate).DayOfYear}).Count)"
        $Tickets.Closed | Group-Object ResponsibleGroupName | Sort-Object -Descending Count | Select-Object Count,@{Name="Support Team";Expression={$_.Name}} | Out-String

        # Get appropriate URI for the user portal so that selected tickets can be retrieved from the GridView
        $BaseURI = Get-URI -Environment $Environment -Portal
        # Pop up grid view of opened tickets for more detailed review
        $Tickets.Opened.ID | Get-TDTicket | Select-Object ID, Title, ResponsibleGroupName, Description | Out-GridView -OutputMode Multiple | ForEach-Object {Start-Process "$BaseURI/Apps/$TicketingAppID/Tickets/TicketDet?TicketID=$($_.ID)"}
    }
}

function Get-TDAssetConsistency
{
    [CmdletBinding()]
    Param
    (
        # Return assets with blank serial number
        [Parameter(Mandatory=$false)]
        [switch]
        $SerialNumberBlank,

        # Return assets with duplicate serial number
        [Parameter(Mandatory=$false)]
        [switch]
        $SerialNumberDuplicate,

        # Return assets with duplicate names
        [Parameter(Mandatory=$false)]
        [switch]
        $NameDuplicate,

        # Return assets with duplicate MAC addresses
        [Parameter(Mandatory=$false)]
        [switch]
        $MACDuplicate,

        # Return assets with inconsistent TaG18 data
        [Parameter(Mandatory=$false)]
        [switch]
        $TaG18,

        # Add not checked in days?

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
        $Assets = (Get-TDReport -ID $TDConfig.TDAllAssetReportID -WithData -AuthenticationToken $AuthenticationToken -Environment $Environment).DataRows
        $ValidEncryptionStrings = @(
                                  'All Partitions Encrypted'
                                  'C: 1'
                                  'True'
                                  )
        $IgnoreStatuses = @(
                          'Disposed'
                          'Lost'
                          'Retired'
                          'Waiting for Surplus'
                          )
    }

    process
    {
        # If no test is specified, run all tests
        if (-not ($SerialNumberBlank -or $SerialNumberDuplicate -or $NameDuplicate -or $MACDuplicate -or $TaG18))
        {
            $SerialNumberBlank     = $true
            $SerialNumberDuplicate = $true
            $NameDuplicate         = $true
            $MACDuplicate          = $true
            $TaG18                 = $true
        }
        $Return = New-Object -TypeName PSObject
        if ($SerialNumberBlank)
        {
            Write-ActivityHistory "Getting assets with blank serial number"
            $BlankSNAssets = $Assets | Where-Object StatusName -notin $IgnoreStatuses | Group-Object SerialNumber |  Where-Object Name -eq ''
            $Return | Add-Member -MemberType NoteProperty -Name BlankSN -Value $BlankSNAssets
        }

        if ($SerialNumberDuplicate)
        {
            Write-ActivityHistory "Getting assets with duplicate serial number"
            $DuplicateSNAssets = $Assets | Where-Object StatusName -notin $IgnoreStatuses | Group-Object SerialNumber | Where-Object Count -gt 1 | Where-Object Name -ne ''
            $Return | Add-Member -MemberType NoteProperty -Name DuplicateSN -Value $DuplicateSNAssets
        }

        if ($NameDuplicate)
        {
            Write-ActivityHistory "Getting assets with duplicate name"
            $DuplicateNameAssets = $Assets | Where-Object StatusName -notin $IgnoreStatuses | Group-Object Name | Where-Object Count -gt 1
            $Return | Add-Member -MemberType NoteProperty -Name DuplicateName -Value $DuplicateNameAssets
        }

        if ($MACDuplicate)
        {
            Write-ActivityHistory "Getting assets with duplicate MAC address"
            $MACFieldIDs = (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object  name -like 'MAC*').ID
            [System.Collections.ArrayList]$Collection = @()
            [System.Collections.ArrayList]$CollectionNames = @()
            foreach ($Asset in $Assets)
            {
                foreach ($MACFieldID in $MACFieldIDs)
                {
                    if ($null -ne $Asset.$MACFieldID)
                    {
                        if ($Asset.$MACFieldID -in $CollectionNames)
                        {
                            $GroupMatch = $Collection | Where-Object Name -eq $Asset.$MACFieldID
                            $GroupMatch.Group += $Asset
                            ++$GroupMatch.Count
                        }
                        else
                        {
                            $Collection += [pscustomobject]@{
                                Count = 1
                                Name  = $Asset.$MACFieldID
                                Group = @($Asset)
                            }
                            $CollectionNames.Add($Asset.$MACFieldID) | Out-Null
                        }
                    }
                }
            }
            $DuplicateMACAssets = $Collection | Where-Object Count -gt 1
            $Return | Add-Member -MemberType NoteProperty -Name DuplicateMAC -Value $DuplicateMACAssets
        }

        if ($TaG18)
        {
            Write-ActivityHistory "Getting assets with inconsistent TaG18 information"
            # Get ID of custom attribute for 'TaG18 Complete' and Value for 'Yes'
            $TaG18CompleteID        =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'TaG18 Complete'           ).ID
            $EncryptionStatusID     =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Encryption Status'        ).ID
            $LastCheckInID          =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Last Check-In'            ).ID
            $OrganizationalUnitID   =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Organizational Unit'      ).ID
            $DataClassificationID   =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Data Classification'      ).ID
            $AVConsoleCurrentID     =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Antivirus Console Current').ID
            $BackupConsoleCurrentID =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'Backup Console Current'   ).ID
            $DLPConsoleCurrentID    =  (Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq 'DLP Console Current'      ).ID

            # Retrieve all assets marked as 'TaG18 Complete'
            $TaG18CompleteAssets = $Assets | Where-Object StatusName -notin $IgnoreStatuses | Where-Object $TaG18CompleteID -eq 'Yes'

            # Set up and clear arrays to hold entries for each type of inconsistency
            $MissingOSUTag             = @()
            $MissingSerialNumber       = @()
            $MissingOwner              = @()
            $MissingDepartment         = @()
            $MissingBuilding           = @()
            $MissingRoom               = @()
            $NotEncrypted              = @()
            $NotCheckedIn              = @()
            $NotInAD                   = @()
            $MissingDataClassification = @()
            $NotCurrentAntivirus       = @()
            $NotCurrentBackup          = @()
            $NotCurrentDLP             = @()

            # Check each asset
            foreach ($TaG18ReviewAsset in $TaG18CompleteAssets)
            {
                if (-not $TaG18ReviewAsset.SerialNumber)
                {
                    $MissingSerialNumber += $TaG18ReviewAsset
                }
                if (-not $TaG18ReviewAsset.Tag)
                {
                    $MissingOSUTag += $TaG18ReviewAsset
                }
                if ((-not $TaG18ReviewAsset.OwningCustomerName) -or ($TaG18ReviewAsset.OwningCustomerName -eq 'None'))
                {
                    $MissingOwner += $TaG18ReviewAsset
                }
                if ((-not $TaG18ReviewAsset.OwningDepartmentName) -or ($TaG18ReviewAsset.OwningDepartmentName -eq 'None'))
                {
                    $MissingDepartment += $TaG18ReviewAsset
                }
                if ((-not $TaG18ReviewAsset.LocationName) -or ($TaG18ReviewAsset.LocationName -eq 'None'))
                {
                    $MissingBuilding += $TaG18ReviewAsset
                }
                if ((-not $TaG18ReviewAsset.LocationRoomName) -or ($TaG18ReviewAsset.LocationRoomName -eq 'None'))
                {
                    $MissingRoom += $TaG18ReviewAsset
                }
                if (-not ($TaG18ReviewAsset.$EncryptionStatusID -match (($ValidEncryptionStrings | ForEach-Object {$_}) -join '|')))
                {
                    $NotEncrypted += $TaG18ReviewAsset
                }
                if (-not $TaG18ReviewAsset.$LastCheckInID)
                {
                    $NotCheckedIn += $TaG18ReviewAsset
                }
                if ((-not $TaG18ReviewAsset.$OrganizationalUnitID) -or ($TaG18ReviewAsset.OrganizationalUnitID -like 'Not in *'))
                {
                    $NotInAD += $TaG18ReviewAsset
                }
                if (-not $TaG18ReviewAsset.$DataClassificationID)
                {
                    $MissingDataClassification += $TaG18ReviewAsset
                }
                if ($TaG18ReviewAsset.$AVConsoleCurrentID -ne 'Yes')
                {
                    $NotCurrentAntivirus += $TaG18ReviewAsset
                }
                if ($TaG18ReviewAsset.$BackupConsoleCurrentID -ne 'Yes')
                {
                    $NotCurrentBackup += $TaG18ReviewAsset
                }
                if ($TaG18ReviewAsset.$DLPConsoleCurrentID -ne 'Yes')
                {
                    $NotCurrentDLP += $TaG18ReviewAsset
                }
            }
            # Create an object from all of the data to return
            $TaG18Review = New-Object -TypeName PSObject
            $Tag18Review | Add-Member -MemberType NoteProperty -Name 'MissingOSUTag'             -Value $MissingOSUTag             -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'MissingOwner'              -Value $MissingOwner              -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'MissingDepartment'         -Value $MissingDepartment         -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'MissingBuilding'           -Value $MissingBuilding           -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'MissingRoom'               -Value $MissingRoom               -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotEncrypted'              -Value $NotEncrypted              -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotCheckedIn'              -Value $NotCheckedIn              -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotInAD'                   -Value $NotInAD                   -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'MissingDataClassification' -Value $MissingDataClassification -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotCurrentAntivirus'       -Value $NotCurrentAntivirus       -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotCurrentBackup'          -Value $NotCurrentBackup          -PassThru |
                           Add-Member -MemberType NoteProperty -Name 'NotCurrentDLP'             -Value $NotCurrentDLP
            $Return | Add-Member -MemberType NoteProperty -Name TaG18Inconsistent -Value $TaG18Review
        }
        $Return
    }
}

function Restore-AssetErasedDataError
{
    [CmdletBinding()]
    Param
    (
        # Feed entry object
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [psobject[]]
        $FeedEntry
    )

    Begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        $AllAssetAttributes = Get-TDCustomAttribute -ComponentID Asset -AuthenticationToken $AuthenticationToken -Environment $Environment
    }
    Process
    {
        # Machine name is in ItemTitle, find matching machine
        foreach ($Entry in $FeedEntry)
        {
            $AssetFound = $false
            $AssetSearch = Get-TDAsset -SearchText $Entry.ItemTitle -AuthenticationToken $AuthenticationToken -Environment $Environment
            foreach ($Asset in $AssetSearch)
            {
                if ($Asset.Name -match $Entry.ItemTitle)
                {
                    $AssetFound = $true
                    # Get asset with full detail
                    $Asset = Get-TDAsset -ID $Asset.ID -AuthenticationToken $AuthenticationToken -Environment $Environment
                    break
                }
            }
            if ($AssetFound)
            {
                Write-Host $Asset.Name
                $Changes = @()
                $BodyLines = $Entry.body -split '<br/>'
                foreach ($BodyLine in $BodyLines)
                {
                    $IsChange = $BodyLine -match '^Changed (.*) from "(.*)" to "(.*)"\.$'
                    if ($IsChange)
                    {
                        if ($Matches.Count -ne 4)
                        {
                            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Bad match'
                        }
                        $Attribute     = $Matches[1]
                        $OriginalValue = $Matches[2]
                        # Current value is $Matches[3], in case that's interesting
                        if ($Matches[3] -eq 'Nothing')
                        {
                            Write-Host "`tFix $Attribute by replacing with $OriginalValue"
                            $Changes += @{$Attribute = $OriginalValue}
                        }
                    }
                }
                $ModifiedAttributes = @()
                foreach ($Change in $Changes)
                {
                    # Check to see if the change is to a property or an attribute
                    if ($Change.Keys[0] -in $Asset.psobject.Properties.Name) # Property
                    {
                        $Asset.$($Change.Keys[0]) = $Change.Values[0]
                    }
                    else # Attribute
                    {
                        $ChangeAttribute = $AllAssetAttributes | Where-Object Name -Match $Change.Keys[0]
                        if ($ChangeAttribute.Choices)
                        {
                            $ChangeAttributeChoice = $ChangeAttribute.Choices | Where-Object Name -Match $Change.Values[0]
                            $ModifiedAttributes += @{ID=$ChangeAttribute.ID; Value=$ChangeAttributeChoice.ID}
                        }
                        else
                        {
                            $ModifiedAttributes += @{ID=$ChangeAttribute.ID; Value=$Change.Values[0]}
                        }
                    }
                }
                $AddAttributes = @()
                # Check list of attributes currently in TD asset to see if it is being replaced
                foreach ($Attribute in $Asset.Attributes)
                {
                    if ($Attribute.ID -notin $ModifiedAttributes.ID) # Not being replaced, add it to the list
                    {
                        $AddAttributes += $Attribute
                    }
                }
                # Add existing attributes to new attributes
                $AddAttributes += $ModifiedAttributes
                # Replace existing attributes on asset with new ones
                $Asset.Attributes = $AddAttributes
                Write-ActivityHistory ($Asset | Out-String)
                Write-ActivityHistory ($asset.Attributes | ConvertTo-Json -Depth 10)
                return $Asset
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Asset, $($Entry.ItemTitle), not found."
            }
            Write-Host ""
        }
    }
}

function Get-TDDataConnector
{
    Param
    (
        # Return active connectors
        [Parameter(Mandatory=$false)]
        [system.nullable[boolean]]
        $IsActive
    )
    DynamicParam
    {
        #List dynamic parameters
        $DynamicParameterList = @(
            @{
                Name        = 'Name'
                ValidateSet = $TDConfig.DataConnectors.Name
                Type        = 'string'
                HelpText    = 'Name of data connector'
            }
        )
        $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList
        return $DynamicParameterDictionary
    }

    process
    {
        if ($DynamicParameterDictionary.Name.Value)
        {
            # Only named connector
            $Connectors = $TDConfig.DataConnectors | Where-Object Name -eq $DynamicParameterDictionary.Name.Value
        }
        else
        {
            # No name, all connectors
            $Connectors = $TDConfig.DataConnectors
        }
        # If IsActive is set, only return connectors with specified IsActive state
        if ($null -ne $IsActive)
        {
            $Connectors = $Connectors | Where-Object IsActive -eq $IsActive
        }
        # Add AppClass
        foreach ($Connector in $Connectors)
        {
            $Connector.AppClass = ($TDApplications | Where-Object Name -eq $Connector.Application).AppClass
        }
        # Convert to an object on return - helps with formatting
        return $Connectors | ForEach-Object {[pscustomobject]$_}
    }
}
#endregion

#region Private functions
# Functions necessary to parse JSON output from .NET serializer to PowerShell Objects
function ParseItem
{
    [CmdletBinding()]
    Param
    (
        # Item to be parsed
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        $JsonItem
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    if ($JsonItem.PSObject.TypeNames -match "Array")
    {
        return ParseJsonArray($JsonItem)
    }
    elseif ($JsonItem.PSObject.TypeNames -match "Dictionary")
    {
        return ParseJsonObject([HashTable]$JsonItem)
    }
    else
    {
        return $JsonItem
    }
}

function ParseJsonObject
{
    [CmdletBinding()]
    Param
    (
        # JSON object to be parsed into a Powershell object
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        $JsonObject
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    $result = New-Object -TypeName PSCustomObject
    foreach ($Key in $JsonObject.Keys)
    {
        $Item = $JsonObject[$Key]
        if ($Item)
        {
            $ParsedItem = ParseItem $Item
        }
        else
        {
            $ParsedItem = $null
        }
        $Result | Add-Member -MemberType NoteProperty -Name $Key -Value $ParsedItem
    }
    return $Result
}

function ParseJsonArray
{
    [CmdletBinding()]
    Param
    (
        # Array to be parsed
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [array]$JsonArray
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    $Result = @()
    $ProgressCount = 0
    foreach ($JsonItem in $JsonArray)
    {
        $ProgressCount++
        Write-Progress -Activity 'Converting JSON result into PowerShell object' -PercentComplete ($ProgressCount / $JsonArray.Count * 100)
        $Parsed = New-Object psobject -Property $JsonItem
        $Result += $Parsed
    }
    return $Result
}

function ParseJsonString
{
    [CmdletBinding()]
    Param
    (
        # JSON string to be parsed
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [string]$JsonString
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions")
    $JsonSerializer = New-Object -TypeName System.Web.Script.Serialization.JavaScriptSerializer
    $JsonSerializer.MaxJsonLength = [System.Int32]::MaxValue

    ParseItem($JsonSerializer.DeserializeObject($JsonString))
}

<#
.Synopsis
   Requests a REST API call.
.DESCRIPTION
   Requests a REST API call. This function ensures that if a call receives an
   error, it will be retried until it is successful or receives a fatal error.
   The hint regarding the number of calls assists in optimizing the backoff
   algorithm.
.PARAMETER URI
    The REST API endpoint.
.PARAMETER ContentType
    The REST API content type.
.PARAMETER Headers
    The REST API headers.
.PARAMETER Body
    The REST API body.
.EXAMPLE
   C:\>Invoke-RESTCall -URI 'https://rest.domain.com/endpoint/json' -ContentType 'charset=utf-8' -Headers @{User='username';Password='password'} -Body (ConvertTo-Json @{data='input'} -Depth 10)

   Requests a REST API call which has a maximum number of 60 calls per minute
   permitted.
#>
function Invoke-RESTCall
{
    [CmdletBinding()]
    Param
    (
        # REST API endpoint
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $URI,

        # REST API content type
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ContentType,

        # REST API method
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [ValidateSet('GET','POST','PATCH','PUT','DELETE')]
        [string]
        $Method,

        # REST API headers
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
        [psobject]
        $Headers = $null,

        # REST API body
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=4)]
        [psobject]
        $Body = $null
    )

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
        # Force TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    process
    {
        Write-ActivityHistory "Calling REST API $URI, using method $Method"
        Write-ActivityHistory (Get-PSCallStack | Out-String)
        $Retries = 0
        do
        {
            if ($Retries -gt 0)
            {
                Write-ActivityHistory "Retry. Try number $Retries"
            }
            try
            {
                $Return = Invoke-RestMethod -Uri $URI -ContentType $ContentType -Method $Method -Headers $Headers -Body $Body -ErrorAction Stop
                $Retry = $false
            }
            catch
            {
                if (($_.Exception.GetType().Fullname -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or ($_.Exception.GetType().Fullname -eq 'System.Net.WebException'))
                {
                    # Too many requests
                    if ($_.Exception.Response.StatusCode.Value__ -eq '429')
                    {
                        # Extract rate limit reset time and current time from exception and wait until that time (plus 2 seconds to allow for small mayhem)
                        $RateLimitResetTime   = $_.Exception.Response.Headers.GetValues('X-RateLimit-Reset') | Get-Date
                        $APIEndpointTime      = $_.Exception.Response.Headers.GetValues('Date')              | Get-Date
                        $WaitTime = (New-TimeSpan -Start ($APIEndpointTime) -End ($RateLimitResetTime).AddSeconds(2)).TotalSeconds
                        Write-ActivityHistory "Waiting $WaitTime seconds to make next TD request. Waiting until $RateLimitResetTime"
                        # Wait time should never be more than 60 seconds - cap it at 60 seconds in case of unforseen date calculation error
                        if ($WaitTime -gt 60)
                        {
                            $WaitTime = 60
                            Write-ActivityHistory "Wait time adjusted to $WaitTime"
                        }
                        # Wait time should never be negative, and small numbers are dangerous - set to one second to avoid an error on Start-Sleep
                        # Small, and even negative, values could occur when reset is very close to current time
                        if ($WaitTime -lt 1)
                        {
                            $WaitTime = 1
                            Write-ActivityHistory "Wait time adjusted to $WaitTime"
                        }
                        Start-Sleep -Seconds $WaitTime
                        $Retry = $true
                    }
                    # Unauthorized
                    elseif ($_.Exception.Response.StatusCode.Value__ -eq '401')
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'TeamDynamix authentication token is invalid or has expired. Tokens expire 24 hours.'
                        $Retry = $false
                    }
                    # Not found
                    elseif ($_.Exception.Response.StatusCode.Value__ -eq '404')
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -Message 'Item not found in TeamDynamix.'
                        $Retry = $false
                    }
                    # Bad request
                    elseif ($_.Exception.Response.StatusCode.Value__ -eq '400')
                    {
                        Write-ActivityHistory -ErrorRecord $_ -ErrorMessage 'TeamDynamix has rejected the request.'
                        $Retry = $false
                    }
                    # Fobidden
                    elseif ($_.Exception.Response.StatusCode.Value__ -eq '403')
                    {
                        if ($_.Exception.Message -eq $script:TDLoginFailureText)
                        {
                            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message $script:TDLoginFailureText
                        }
                        else
                        {
                            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message $_.Exception.Message
                        }
                        $Retry = $false
                    }
                    # Other error
                    else
                    {
                        Write-ActivityHistory -ErrorRecord $_ -ErrorMessage "Fatal $($_.Exception.GetType().Fullname) calling URI, $URI, with method $Method. - $_.Exception.Message"
                        $Retry = $false
                    }
                }
                elseif ($_.Exception.GetType().Fullname -eq 'System.Net.Http.HttpRequestException')
                {
                    Write-ActivityHistory -MessageChannel 'Verbose' -Message $_.Exception.InnerException.Message
                    $Retry = $true
                }
                else
                {
                    $Retry = $false
                    Write-ActivityHistory -ErrorRecord $_ -ThrowError -ErrorMessage "Fatal unknown error calling URI, $URI, with method $Method."
                }
            }
            $Retries++
        }
        while ($Retry -and ($Retries -lt 10))
        if ($Retries -ge 10)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'API call failed due to excessive retries.'
        }

        # If returned data is larger than 4MB PowerShell's default JSON
        # serializer/deserializer will return a string rather than an object.
        if (($Return -and $Return.GetType().Name -eq 'string') -and ($Return.Length -gt 4096))
        {
            Write-ActivityHistory 'A large result was returned, requiring special processing. Stand by.'
            if ($PSVersionTable.PSVersion.Major -ge 7)
            {
                $Return = ConvertFrom-Json -AsHashtable -InputObject $Return
            }
            else
            {
                # No AsHashtable option prior to PowerShell Core
                $Return = ParseJsonString($Return)
            }
            Write-ActivityHistory 'Processing complete.'
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}
function New-SimplePassword
{
    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    $lower = 'abcdefghijklmnopqrstuvwxyz'
    $upper = $lower.ToUpper()
    $numbers = '0123456789'

    $a = (Get-Random -Count 5 -InputObject $lower.ToCharArray()) -join ''
    $b = (Get-Random -Count 5 -InputObject $upper.ToCharArray()) -join ''
    $c = (Get-Random -Count 5 -InputObject $numbers.ToCharArray()) -join ''

    $pool = $a + $b + $c
    $i = Get-Random -Count 14 -InputObject (0..14)
    $password = $pool[$i] -join ''

    return $password
}

<#
.Synopsis
   Update the properties of an object
.DESCRIPTION
   Update the properties of an object using the command-line and default
   parameters, ignoring parameters as directed. This is a service routine,
   intended to reduce the volume of code and ease maintenance.
.PARAMETER InputObject
    Object to be updated.
.PARAMETER ParameterList
    List of properties in the invoking function.
.PARAMETER BoundParameterList
    List of bound properties from the invoking function.
.PARAMETER IgnoreList
    A list of properties in the ParameterList that should be ignored, usually
    because there is no corresponding property in the InputObject.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
   C:\>Update-Object -InputObject $NewAsset -ParameterList $Parameters -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters)

   Return the NewAsset object, updated by "Parameters", ignoring the local and global ignore parameters.
#>
function Update-Object
{
    [CmdletBinding()]
    Param
    (
        # Object to be updated
        [Parameter(Mandatory=$true,
                   Position=0)]
        $InputObject,

        # Full list of properties for the invoking function
        [Parameter(Mandatory=$true,
                   Position=1)]
        $ParameterList,

        # List of bound properties from the invoking function
        [Parameter(Mandatory=$true,
                   Position=1)]
        $BoundParameterList,

        # Properties to be ignored in the update
        [Parameter(Mandatory=$true,
                   Position=2)]
        $IgnoreList,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false)]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    Write-ActivityHistory "-----"
    Write-ActivityHistory "In $($MyInvocation.MyCommand.Name)"
    Write-ActivityHistory (Get-PSCallStack | Out-String)
    $IgnoreList += @('Attributes','CustomAttributes','OrgApplications')
    foreach ($Parameter in $ParameterList)
    {
        # Set parameter values
        # Ignore items from ignore list
        if ($Parameter -notin $IgnoreList)
        {
            # Only update items that are on the bound parameter list, or which are not either null or empty
            if (($Parameter -in $BoundParameterList) -or (-not (($null -eq (Get-Variable -Name $Parameter).Value) -or ((Get-Variable -Name $Parameter).Value -eq ''))))
            {
                Write-ActivityHistory "$($Parameter): $((Get-Variable -Name $Parameter).Value)"
                $InputObject.$Parameter = (Get-Variable -Name $Parameter).Value
            }
        }
    }
    # Check if there is there an OrgApplications parameter
    # Special handling for OrgApplications is required since the input is an array and an array can't be assigned to the object
    if ($ParameterList -contains 'OrgApplications')
    {
        # Replaces existing OrgApplications list with updated items, if none, current list is cleared
        if ($null -ne $OrgApplications)
        {
            $InputObject.OrgApplications = @()
            foreach ($OrgApplication in $OrgApplications)
            {
                $InputObject.OrgApplications += $OrgApplication
            }
        }
        # If OrgApplications is set to null, remove all OrgApplications
        #  Must return an empty array to clear all items
        else
        {
            $InputObject.OrgApplications = @()
        }
    }
    # Check if there is there an Attributes parameter
    # Special handling for Attributes is largely to cover input checking and handling of names of the attributes instead of ID numbers
    if (($ParameterList -contains 'Attributes') -or ($ParameterList -contains 'CustomAttributes'))
    {
        # Some functions refer to Attributes as CustomAttributes, but they never appear together
        if ($ParameterList -contains 'CustomAttributes')
        {
            $Attributes = $CustomAttributes
        }
        # Check if Attributes parameter is populated
        if ($Attributes.Count -gt 0)
        {
            # Check to see if the attributes are already in TD format
            if ($Attributes.GetType().Name -eq 'TeamDynamix_Api_CustomAttributes_CustomAttribute[]')
            {
                # No special action required, attributes are already properly formatted. This usually happens when passing an object back from TD.
                $InputObject.AddCustomAttribute($Attributes,$true)
            }
            else # Not in TD format
            {
                # Verify that input is either a hashtable, an array of paired strings, or an array of an array of paired strings or paired ID number and string
                $AttributesTypeName = ($Attributes | Get-Member).TypeName[0]
                switch ($AttributesTypeName)
                {
                    'System.Collections.Hashtable'
                    {
                        # Add hashtable directly, overwriting existing attributes
                        $InputObject.AddCustomAttribute($Attributes,$true)
                    }
                    'System.String'
                    {
                        if ($Attributes.Count -eq 2)
                        {
                            $InputObject.AddCustomAttribute($Attributes[0],$Attributes[1],$true,$AuthenticationToken,$Environment)
                        }
                        else
                        {
                            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Input string should be a paired attribute name and value.'
                        }
                    }
                    'System.Object[]'
                    {
                        #  Check for attribute value (attributeset[1]) being a string of integers when there are choices
                        foreach ($AttributeSet in $Attributes)
                        {
                            if ((($AttributeSet | Get-Member).TypeName[0] -eq 'System.String') -and ($AttributeSet.Count -eq 2))
                            {
                                $InputObject.AddCustomAttribute($AttributeSet[0],$AttributeSet[1],$true,$AuthenticationToken,$Environment)
                            }
                            elseif ((($AttributeSet | Get-Member).TypeName[0] -eq 'System.Int32') -and ($AttributeSet.Count -eq 2))
                            {
                                $InputObject.AddCustomAttribute($AttributeSet[0],$AttributeSet[1],$true)
                            }
                            else
                            {
                                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Input string should be sets of paired attribute names and values, or ID numbers and values.'
                            }
                        }
                    }
                    'System.Int32'
                    {
                        if ($Attributes.Count -eq 2)
                        {
                            $InputObject.AddCustomAttribute($Attributes[0],$Attributes[1],$true)
                        }
                        else
                        {
                            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Input string should be a paired attribute ID and value.'
                        }
                    }
                    default
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Bad custom attributes submitted. Ensure that the input is either a paired attribute name and value, or a hashtable containing the attribute ID and value ID.'
                    }
                }
            }
        }
    }
}

<#
.Synopsis
    Extract TeamDynamix API data
.DESCRIPTION
    Extract TeamDynamix API data from text in a file or a web page. Returns an
    object containing the parameter properties.
.PARAMETER URL
    URL of the web page.
.PARAMETER TableNumber
    The number of the table on the web page. Count starts at one (default).
.PARAMETER InputText
    The text to be input. Be sure to use the -Raw option on Get-Content.
.NOTES
    Has serious compatibility issues. Does not work reliably on Windows Server,
    probably due to reliance on Internet Explorer to parse the HTML.
    Very sensitive to input data. URL input assumes column heads of Name,
    Editable, Required, Type, and Summary.
.EXAMPLE
   C:\>Get-URLTableData -URL https://some.page

   Gets data from the first table on specified web page.
.EXAMPLE
   C:\>Get-URLTableData -InputText (Get-Content C:\file.txt -Raw)

   Gets data from the first table on specified web page.
#>
function Get-URLTableData
{
    [CmdletBinding(DefaultParameterSetName='URL')]
    Param
    (
        # URL of web page
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='URL',
                   Position=0)]
        [ValidateScript({
            if ($_ -eq ([uri]$_).AbsoluteUri)
            {
                $true
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Not a valid URL. Be sure to include the http[s]://'
            }
        })]
        [string]
        $URL,

        # Table number on web page
        [Parameter(Mandatory=$false,
                   ParameterSetName='URL',
                   Position=1)]
        [int]
        $TableNumber = 1,

        # Table number on web page
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   Position=0)]
        [string]
        $InputText
    )

    begin
    {
        <#
        .Synopsis
            Extract HTML table data from a web page
        .DESCRIPTION
            This function will extract HTML table data from simple web pages.
            Returns a hashtable of the tables, named "Table1", "Table2", ...
            "TableN".
        .PARAMETER URL
            The URL of the web page containing the table.
        .EXAMPLE
            C:\>Get-HTMLTableData -URL https://www.url.org/webpage

            Extracts HTML table data from the URL specified. Returns
        .EXAMPLE
        Another example of how to use this cmdlet
        #>
        function Get-HTMLTableData
        {
            [CmdletBinding()]
            param
            (
                # Web page from Invoke-WebRequest
                [Parameter(Mandatory=$true,
                        ValueFromPipeline=$true,
                        Position=0)]
                [Microsoft.PowerShell.Commands.HtmlWebResponseObject]
                $WebPage
            )

            begin
            {
                # Tables Regular Expressions
                $TableRegex = [regex]::new('(?s)<table.*?>.*?<\/table>')
                $RowRegex   = [regex]::new('(?s)<tr.*?>.*?<\/tr>')
                $DataRegex  = [regex]::new('(?s)<t[hd].*?>(?<Text>.*?)<\/t[hd]>')

                # HTML tags to ignore (remove from table data)
                $Ignore = @(
                    '<\/?a.*?>',
                    '<\/?span.*?>',
                    '<\/?[ibu]>',
                    '<\/?H[1-4]>',
                    '<\/em>'
                )
            }
            process
            {
                $HeaderList = @()
                $TablesData = @{}
                [System.Collections.ArrayList]$RowData = @()
                $TableCount = 0

                #Extract tables
                $Tables = $TableRegex.Matches($WebPage.Content)

                foreach ($Table in $Tables)
                {
                    $TableCount++
                    $TableData = @()

                    # Extract rows from table
                    $Rows = $RowRegex.matches($Table)

                    # Extract data from rows
                    foreach ($Row in $Rows)
                    {
                        $CurrentRowData = @()
                        $DataEntries = $DataRegex.matches($Row)
                        foreach ($DataEntry in $DataEntries)
                        {
                            # Check for table headers (start off with '<th')
                            if ($DataEntry -like '<th*')
                            {
                                $HeaderList += ($DataEntry.Groups | Where-Object Name -eq 'Text').Value.Trim()
                            }
                            else
                            {
                                $Text = ($DataEntry.Groups | Where-Object Name -eq 'Text').Value.Trim()
                                # Remove extraneous HTML tags from data text
                                foreach ($IgnoreREx in $Ignore)
                                {
                                    $Text = $Text -replace $IgnoreREx, ''
                                }
                                $CurrentRowData += $Text.Trim()
                            }
                        }
                        if ($CurrentRowData)
                        {
                            $RowData.Add($CurrentRowData) | Out-Null
                        }
                    }

                    # Mate up row headers and data - do after collecting data in case headers aren't the first row listed
                    foreach ($Column in $RowData)
                    {
                        $RowText = @{}
                        for ($i = 0; $i -lt $HeaderList.Count; $i++)
                        {
                            $RowText += @{$HeaderList[$i] = $Column[$i]}
                        }
                        $TableData += ([pscustomobject]$RowText)
                    }
                    $TablesData."Table$TableCount" = $TableData
                }
                return $TablesData
            }
        }
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            'URL'
            {
                # Download web page
                $Page = Invoke-WebRequest -Uri $URL -MaximumRedirection 0 -ErrorAction SilentlyContinue

                # Handle errors
                #  Page does not exist
                if ($Page.StatusCode -eq 404)
                {
                    Write-Error -Message "Status code 404 - $URL not found."
                }
                #  Page is being redirected, used when component has been renamed or deprecated
                elseif ($Page.StatusCode -eq 302)
                {
                    Write-Error -Message  "Status code 302 - $URL redirected."
                }
                #  Other error has occurred
                elseif ($Page.StatusCode -ne 200)
                {
                    Write-Error -Message  "Unable to load page due to server error, status code $($Page.StatusCode)"
                }

                # Extract table(s) from web page
                $Tables = Get-HTMLTableData -WebPage $Page

                # Select desired table from the hashtable returned by Get-HTMLTableData
                $Table = $Tables."Table$TableNumber"

                # If web page is for an enum, there will be a "Value" property
                if ('Value' -notin ($Table | Get-Member -MemberType NoteProperty).Name)
                {
                    # Add Editable and Required properties
                    if ('Editable?' -in ($Table | Get-Member -MemberType NoteProperty).Name)
                    {
                        $Table | Add-Member -MemberType AliasProperty -Name Editable -Value Editable?
                    }
                    else
                    {
                        $Table | Add-Member -MemberType NoteProperty -Name Editable -Value $null
                    }
                    if ('Required?' -in ($Table | Get-Member -MemberType NoteProperty).Name)
                    {
                        $Table | Add-Member -MemberType AliasProperty -Name Required -Value Required?
                    }
                    else
                    {
                        $Table | Add-Member -MemberType NoteProperty -Name Required -Value $null
                    }

                    # Clean up data for non-enum entries
                    foreach ($Entry in $Table)
                    {
                        if ($Entry.Editable)
                        {
                            $Entry.Editable = $true
                        }
                        else
                        {
                            $Entry.Editable = $false
                        }

                        if ($Entry.Required)
                        {
                            $Entry.Required = $true
                        }
                        else
                        {
                            $Entry.Required = $false
                        }

                        if ($Entry.Type -match '\w+\.\w+(\.\w+)*')
                        {
                            $Entry.Type = $Entry.Type.Replace('.','_')
                        }
                        switch -Regex ($Entry.Type)
                        {
                            'Nullable\(of'
                            {
                                $Entry.Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                if ($Matches.Type -ne '[string]') # Strings are inherently nullable, and the system.nullable syntax is forbidden
                                {
                                    $Entry.Type = "[System.Nullable[$($Matches.Type)]]"
                                }
                                break
                            }
                            'List\(of|IEnumerable\(of'
                            {
                                $Entry.Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                $Entry.Type = "[$($Matches.Type)[]]"
                                break
                            }
                            default
                            {
                                $Entry.Type = "[$($Entry.Type)]"
                            }
                        }
                    }
                }
                return $Table

                <# Parse method requires Internet Explorer, not reliable (works great if it works, but it doesn't most of the time)
                # Parse table
                if ($Page.ParsedHtml.IHTMLDocument3_getElementsByTagName('table'))
                {
                    $Table = $Page.ParsedHtml.IHTMLDocument3_getElementsByTagName('table')[$TableNumber]
                    # Extract rows from table
                    $Rows = $Table.Rows
                    # Obtain column headers
                    try
                    {
                        $Headers = $Rows.Item(0).Children | Select-Object -ExpandProperty InnerText | ForEach-Object {$_.Trim('?',' ')}
                    }
                    catch
                    {
                        Write-ActivityHistory -MessageChannel 'Error' -Message "$URL problem identifying headers"
                    }
                    # Extract data from table
                    # Iterate through elements (rows), skipping header row
                    for ($i=1; $i -lt ($Rows | Measure-Object).Count; $i++)
                    {
                        # Create hashtable to hold data
                        $APIData=[ordered]@{}
                        # Iterate through API element components (columns)
                        for ($j=0; $j -lt $Headers.count; $j++)
                        {
                            # Add data element name and value (column name and row value) to hashtable
                            if ($Rows.Item($i).Children[$j].InnerText)
                            {
                                $APIData.Add($Headers[$j],$Rows.Item($i).Children[$j].InnerText.Trim())
                            }
                            else
                            {
                                $APIData.Add($Headers[$j],'')
                            }
                        }
                        # If page is for an enum, there will be a "Value" header
                        if ($Headers -notcontains 'Value')
                        {
                            # Clean up data for non-enum pages
                            if ($APIData.Editable)
                            {
                                $APIData.Editable = $true
                            }
                            else
                            {
                                $APIData.Editable = $false
                            }
                            if ($APIData.Required)
                            {
                                $APIData.Required = $true
                            }
                            else
                            {
                                $APIData.Required = $false
                            }
                            if ($APIData.Type -match '\w+\.\w+(\.\w+)*')
                            {
                                $APIData.Type = $APIData.Type.Replace('.','_')
                            }
                            switch -Regex ($APIData.Type)
                            {
                                'Nullable\(of'
                                {
                                    $APIData.Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                    if ($Matches.Type -ne '[string]') # Strings are inherently nullable, and the system.nullable syntax is forbidden
                                    {
                                        $APIData.Type = "[System.Nullable[$($Matches.Type)]]"
                                    }
                                    break
                                }
                                'List\(of|IEnumerable\(of'
                                {
                                    $APIData.Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                    $APIData.Type = "[$($Matches.Type)[]]"
                                    break
                                }
                                default
                                {
                                    $APIData.Type = "[$($APIData.Type)]"
                                }
                            }
                        }
                    [pscustomobject]$APIData
                    }
                }
                #>
            }
            'Text'
            {
                # Regular expression explanation (functions and classes)
                #  First capture group is the parameter, which is the first word on the line
                #  Second capture group is whether the parameter is editable (but avoids text saying "editable?", which occurs on the column head), this text is optional
                #  Third capture group is whether the parameter is required, optional
                #  Fourth capture group is the type, which falls between tabs, since the data is tab-separated
                #  Fifth capture group is the description, which is everything else to the end of the line
                #  All groups are named, to ease selection
                $ParameterMatch = $InputText | Select-String -Pattern '(?<Ignore>Name\t+(Editable\?|Type|Required\?))|(?<Parameter>\w+)\t+(?<Editable>This field is editable through the web API\.)?\t?(?<Required>This field is required.)?\t?(?<Type>.*)\t+(?<Summary>.*)' -AllMatches
                # Check to see if the page was an enum, and not a function or a class
                if ($ParameterMatch.Matches[0].Value.Split("`t") -contains 'Value')
                {
                    # Page is for an enum, change to alternate pattern
                    $ParameterMatch = $InputText | Select-String -Pattern '(?<Ignore>Name\t+Value\t+Summary)|(?<Name>\w+)\t+(?<Value>.*)\t+(?<Description>.*)' -AllMatches
                    foreach ($Match in $ParameterMatch.Matches)
                    {
                        # Select from capture groups
                        $Name        = ($Match.Groups | Where-Object Name -eq 'Name'       ).Value
                        $Value       = ($Match.Groups | Where-Object Name -eq 'Value'      ).Value
                        $Description = ($Match.Groups | Where-Object Name -eq 'Description').Value
                        if (($Match.Groups | Where-Object Name -eq 'Ignore').Value -eq '')
                        {
                            [pscustomobject]@{
                                Name        = $Name
                                Value       = $Value
                                Description = $Description
                            }
                        }
                    }
                }
                else # Page is for a function or class, use the current regex pattern result
                {
                    foreach ($Match in $ParameterMatch.Matches)
                    {
                        # Select from capture groups
                        $Parameter = ($Match.Groups | Where-Object Name -eq 'Parameter').Value
                        $Editable  = ($Match.Groups | Where-Object Name -eq 'Editable' ).Value
                        $Required  = ($Match.Groups | Where-Object Name -eq 'Required' ).Value
                        $Type      = ($Match.Groups | Where-Object Name -eq 'Type'     ).Value
                        $Summary   = ($Match.Groups | Where-Object Name -eq 'Summary'  ).Value
                        if ($Editable)
                        {
                            $Editable = $true
                        }
                        else
                        {
                            $Editable = $false
                        }
                        if ($Required)
                        {
                            $Required = $true
                        }
                        else
                        {
                            $Required = $false
                        }
                        if ($Type -match '\w+\.\w+(\.\w+)*')
                        {
                            $Type = $Type.Replace('.','_')
                        }
                        switch -Regex ($Type)
                        {
                            'Nullable\(of'
                            {
                                $Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                if ($Matches.Type -ne '[string]') # Strings are inherently nullable, and the system.nullable syntax is forbidden
                                {
                                    $Type = "[System.Nullable[$($Matches.Type)]]"
                                }
                                break
                            }
                            'List\(of|IEnumerable\(of'
                            {
                                $Type -match '^((?<Nullable>Nullable\(Of )|(?<List>List\(Of )|(?<IEnumberable>IEnumerable\(Of ))?(?<Type>.*?)\)?$' | Out-Null
                                $Type = "[$($Matches.Type)[]]"
                                break
                            }
                            default
                            {
                                $Type = "[$Type]"
                            }
                        }
                        if (($Match.Groups | Where-Object Name -eq 'Ignore').Value -eq '')
                        {
                            [pscustomobject]@{
                                Name     = $Parameter
                                Editable = $Editable
                                Required = $Required
                                Type     = $Type
                                Summary  = $Summary
                            }
                        }
                    }
                }
            }
        }
    }
}

<#
.Synopsis
    Produces output on the desired channel.
.DESCRIPTION
    Centralized output routine which produces output on the desired channel.
    Also keeps history of recent output activity. Set the
    $InformationPreference variable to 'Continue' to show recent activity when
    an error is reported.
.PARAMETER Message
    Text message to be output.
.PARAMETER ErrorMessage
    Text message to be output when reporting an error.
.PARAMETER MessageChannel
    The channel to deliver the message on. Defaults to the Verbose channel.
.PARAMETER ErrorRecord
    Error record to be delivered. Always goes to the Error channel.
.PARAMETER ThrowError
    Switch indicating that the error should be thrown (Stop Error), rather than
    just reported (Continue Error).
.EXAMPLE
   C:\>Write-ActivityHistory -Message 'Updating assets'

   Sends the desired message to the Verbose channel.
.EXAMPLE
   C:\>Write-ActivityHistory -Message 'Updating assets' -MessageChannel Debug

   Sends the desired message to the Verbose channel.
.EXAMPLE
   C:\>Write-ActivityHistory -ErrorMessage 'Updating assets' -ErrorRecord $ER -Throw

   Sends the desired message and the most recent activity to the Information
   channel, and throws the specified error record.
#>
function Write-ActivityHistory
{
    [CmdletBinding(DefaultParameterSetName='Text')]
    Param
    (
        # Message
        [Parameter(Mandatory=$true,
                   ParameterSetName='Text',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $Message,

        # Error
        [Parameter(Mandatory=$true,
                   ParameterSetName='Error',
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord,

        # Error message text
        [Parameter(Mandatory=$false,
                   ParameterSetName='Error',
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]
        $ErrorMessage,

        # Message channel (applies only to text messages, not errors)
        [Parameter(Mandatory=$false,
                   ParameterSetName='Text',
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('Verbose','Debug','Output','Information','Error','Warning')]
        [string]
        $MessageChannel = 'Verbose',

        # Throw error
        [Parameter(Mandatory=$false,
                   ParameterSetName='Text',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='Error',
                   ValueFromPipelineByPropertyName=$true)]
        [switch]
        $ThrowError
    )
    Begin
    {
        # Number of messages and errors to keep in activity history, older ones are dequeued to $null
        if ($MaxActivityHistoryDefault)
        {
            $MaxActivityHistoryEntries = $MaxActivityHistoryDefault
        }
        else
        {
            $MaxActivityHistoryEntries = 20
        }
    }
    Process
    {
        switch ($pscmdlet.ParameterSetName)
        {
            Text
            {
                # Add current message to activity history queue
                $ActivityHistory.Enqueue($Message)
                # Remove old messages when queue has more items than MaxActivityHistoryEntries
                while ($ActivityHistory.Count -gt $MaxActivityHistoryEntries)
                {
                    $ActivityHistory.Dequeue() | Out-Null
                }
                # Send message to specified channel
                switch ($MessageChannel)
                {
                    Verbose
                    {
                        Write-Verbose $Message
                        break
                    }
                    Debug
                    {
                        Write-Debug $Message
                        break
                    }
                    Output
                    {
                        Write-Output $Message
                        break
                    }
                    Information
                    {
                        Write-Information -MessageData $Message
                        break
                    }
                    Warning
                    {
                        Write-Warning $Message
                        break
                    }
                    Error
                    {
                        Write-Information -MessageData "An error occurred at $(Get-Date -Format G). Recent activity follows."
                        # When an error occurs, write the recent ActivityHistory to the Information channel (one entry per line)
                        $ActivityHistory | ForEach-Object {Write-Information -MessageData $_}
                        # Errors may be written to the Error channel (Continue), or thrown (Stop)
                        if ($ThrowError)
                        {
                            throw $Message
                        }
                        else
                        {
                            Write-Error -Message $Message
                        }
                        break
                    }
                }
            }
            Error
            {
                Write-Information -MessageData "An error occurred at $(Get-Date -Format G). Recent activity follows."
                # When an error occurs, write the recent ActivityHistory to the Information channel (one entry per line)
                $ActivityHistory | ForEach-Object {Write-Information -MessageData $_}
                if ($ErrorMessage)
                {
                    $ActivityHistory.Enqueue($ErrorMessage)
                    Write-Information $ErrorMessage
                }
                $ActivityHistory.Enqueue($ErrorRecord)
                # Remove old entries from ActivityHistory queue
                while ($ActivityHistory.Count -gt $MaxActivityHistoryEntries)
                {
                    $ActivityHistory.Dequeue() | Out-Null
                }
                # Errors may be written to the Error channel (Continue), or thrown (Stop)
                if ($ThrowError)
                {
                    throw $ErrorRecord
                }
                else
                {
                    Write-Error -ErrorRecord $ErrorRecord
                }
            }
        }
    }
    End
    {
    }
}

<#
.Synopsis
    Return a new parameter for a dynamic parameter dictionary
.DESCRIPTION
    Create a new parameter for addition to a dynamic parameter dictionary. Used
    for adding dynamic parameters to a function.
.PARAMETER Name
    Name of the dynamic parameter.
.PARAMETER ValidateSet
    The set of valid options for the dynamic parameter. Use an array of
    strings.
.PARAMETER ValidateScript
    Script block to validate the dynamic parameter.
.PARAMETER ValidateRange
    Range of valid options for the dynamic parameter. Specify as an array with
    two members. The first is the minimum value and the second is the maximum.
.PARAMETER ValidatePattern
    Regex pattern to validate the dynamic parameter. Specify as a string.
.PARAMETER ValidateNotNull
    Set to $true to ensure that the dynamic parameter is not null.
.PARAMETER ValidateNotNullOrEmpty
    Set to $true to ensure that the dynamic parameter is not null or empty.
.PARAMETER HelpText
    The help text to accompany the dynamic parameter.
.PARAMETER Type
    The variable type of the dynamic parameter. Specify as a string. The
    default type is 'string[]'.
.PARAMETER ParameterSetName
    The parameter set name for the dynamic parameter.
.PARAMETER Position
    The position for the dynamic parameter.
.PARAMETER ValueFromPipeline
    Set to $true to draw the dynamic paramter's value from the pipeline.
.PARAMETER ValueFromPipelineByPropertyName
    Set to $true to draw the dynamic paramter's value from the pipeline by
    name.
.PARAMETER IsMandadory
    Boolean to set whether the dynamic parameter is mandatory.
.PARAMETER Value
    The default value of the dynamic parameter.
.PARAMETER DontShow
    Set to $true to hide the parameter.
.EXAMPLE
    C:\>$DynamicParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
    C:\>$DynamicParameterDictionary.Add('ManufacturerNames', (New-RuntimeDefinedParameter -Name 'ManufacturerNames' -ValidateSet @('Apple','Dell') -HelpText 'Names of manufacturers'))

   Creates a dynamic parameter dictionary and adds a new parameter named
   "ManufacturerNames" to it.
#>
function New-RuntimeDefinedParameter
{
    [CmdletBinding()]
    param
    (
        # Name of the dynamic parameter
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Array of valid options
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $ValidateSet,

        # Script to validate options
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [scriptblock]
        $ValidateScript,

        # Range of valid options
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [psobject]
        $ValidateRange,

        # Regex pattern for valid options
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ValidatePattern,

        # Parameter may not be null options
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ValidateNotNull = $false,

        # Parameter may not be null or empty
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ValidateNotNullOrEmpty = $false,

        # Help text
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $HelpText,

        # Dynamic parameter type (single string or string array)
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            # Test making a type, suppress any error via try/catch, return success or failure
            try
            {
                $TestValue = [System.Type]$_
            }
            catch {}
            if ($TestValue) {return $true}
            else {return $false}
            })]
        [string]
        $Type = 'string[]',

        # Parameter set name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ParameterSetName,

        # Positional of positional parameter
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $Position,

        # Take value from pipeline
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ValueFromPipeline = $false,

        # Take value from pipeline by property name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $ValueFromPipelineByPropertyName = $false,

        # Parameter is mandatory
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsMandadory = $false,

        # Default value for parameter
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [psobject]
        $Value,

        # Aliases for the parameter name
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Alias,

        # Parameter is hidden
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $DontShow = $false
    )
    DynamicParam
    {
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $DynamicParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $NRDPAttribute = New-Object System.Management.Automation.ParameterAttribute
            $NRDPAttribute.HelpMessage = 'Kind of range. Valid choices are Negative, NonNegative, Positive, and NonPositive.'
            $NRDPAttribute.ValueFromPipelineByPropertyName = $true
            $NRDPAttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $NRDPAttributeCollection.Add($NRDPAttribute)
            $NRDPParam = New-Object System.Management.Automation.RuntimeDefinedParameter('ValidateRangeKind', [System.Management.Automation.ValidateRangeKind], $NRDPAttributeCollection)
            $DynamicParameterDictionary.Add('ValidateRangeKind',$NRDPParam)
            return $DynamicParameterDictionary
        }
    }

    process
    {
        # Build parameter attributes
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        if ($IsMandadory)                     {$Attributes.Mandatory                       = $IsMandadory                    }
        if ($HelpText)                        {$Attributes.HelpMessage                     = $HelpText                       }
        if ($ValueFromPipeline)               {$Attributes.ValueFromPipeline               = $ValueFromPipeline              }
        if ($ValueFromPipelineByPropertyName) {$Attributes.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName}
        if ($ParameterSetName)                {$Attributes.ParameterSetName                = $ParameterSetName               }
        if ($Position)                        {$Attributes.Position                        = $Position                       }
        if ($DontShow)                        {$Attributes.Dontshow                        = $DontShow                       }
        # Create collection to hold attributes
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        # Add attributes to collection
        $AttributeCollection.Add($Attributes)
        # Validation set
        if ($ValidateSet) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateSet)
        }
        # Validation script
        if ($ValidateScript) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateScript = New-Object System.Management.Automation.ValidateScriptAttribute($ValidateScript)
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateScript)
        }
        # Validation range
        if ($ValidateRange) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateRange = New-Object System.Management.Automation.ValidateRangeAttribute($ValidateRange)
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateRange)
        }
        # Validation range kind
        if ($ValidateRangeKind) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateRangeKind = New-Object System.Management.Automation.ValidateRangeAttribute($ValidateRangeKind)
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateRangeKind)
        }
        # Validation pattern
        if ($ValidatePattern) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidatePattern = New-Object System.Management.Automation.ValidatePatternAttribute($ValidatePattern)
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidatePattern)
        }
        # Validation not null
        if ($ValidateNotNull) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateNotNull = New-Object System.Management.Automation.ValidateNotNullAttribute
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateNotNull)
        }
        # Validation not null or empty
        if ($ValidateNotNullOrEmpty) {
            # Create validation attribute for the dynamic parameter
            $ParameterValidateNotNullOrEmpty = New-Object System.Management.Automation.ValidateNotNullOrEmptyAttribute
            # Add validation to collection
            $AttributeCollection.Add($ParameterValidateNotNullOrEmpty)
        }
        # Create RuntimeDefinedParameter object from name, type and attributes collection
        $RuntimeDefinedParameter = New-Object -Type System.Management.Automation.RuntimeDefinedParameter($Name, [System.Type]$Type, $AttributeCollection)
        # Set default value
        if ($Value) {
            $RuntimeDefinedParameter.Value = $Value
        }
        # Aliases for parameter
        if ($Alias) {
            # Create alias name for the dynamic parameter
            $ParameterAlias = New-Object System.Management.Automation.AliasAttribute($Alias)
            # Add alias(es) to collection
            $AttributeCollection.Add($ParameterAlias)
        }
        return $RuntimeDefinedParameter
    }
}

<#
.Synopsis
    Return a new dynamic parameter dictionary
.DESCRIPTION
    Create a new dynamic parameter dictionary. Used for adding dynamic
    parameters to a function.
.PARAMETER ParameterList
    Name of the dynamic parameter.
.EXAMPLE
    C:\>$DynamicParameterList = @(
            @{
                Name        = 'AppName'
                ValidateSet = $TDApplications.Name
                HelpText    = 'Names of application'
            }
        )
    $DynamicParameterDictionary = New-DynamicParameterDictionary -ParameterList $DynamicParameterList

   Creates a dynamic parameter dictionary with the AppName parameter in it.
#>
function New-DynamicParameterDictionary
{
    [CmdletBinding()]
    param
    (
        # List of dynamic parameters
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [array]
        $Parameterlist
    )

    process
    {
        $DynamicParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        # Add dynamic parameters
        $ParameterList | ForEach-Object {$DynamicParameterDictionary.Add($_.Name, ([pscustomobject]$_ | New-RuntimeDefinedParameter))}
        return $DynamicParameterDictionary
    }
}

<#
.Synopsis
    Convert Name (dynamic) parameters to ID parameters
.DESCRIPTION
    Return a hashtable of ID parameters with updated values based on their
    corresponding Name (dynamic) parameters.
.PARAMETER DynamicParameterDictionary
    The dynamic parameter dictionary object.
.PARAMETER DynamicParameterList
    The definitions of the dynamic parameters. Definitions may contain any
    valid parameter used to define a function parameter. See
    New-RuntimeDefinedParameter for a complete list. May contain an IDParameter
    and an IDsMethod if the parameter is a name that is standing in for an ID.
    The name of the ID parameter to be updated is in IDParameter, and the
    method for converting from a name to an ID is in IDsMethod. IDsMethod may
    be a variable or a function and must return objects with parameters for
    Name and ID (or AppID if the Name is "AppName").
.EXAMPLE
    C:\>Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList

   Returns a hashtable with ID parameters and new values.
#>
function Get-IDsFromNames
{
    [CmdletBinding()]
    param
    (
        # Dynamic parameter dictionary
        [Parameter(Mandatory=$true,
                   Position=0)]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]
        $DynamicParameterDictionary,

        # Dynamic parameter definitions
        [Parameter(Mandatory=$true,
                   Position=1)]
        [psobject]
        $DynamicParameterList
    )

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        $Return = @{}
        # Step through dynamic parameters from DynamicParameterDictionary
        foreach ($DynamicParameter in $DynamicParameterDictionary.GetEnumerator())
        {
            # Check to see if the dynamic parameter has a value set
            if (-not [string]::IsNullOrWhiteSpace($DynamicParameter.Value.Value))
            {
                # Locate definition of the current dynamic parameter
                #  Will need to extract the IDParameter and IDsMethod
                foreach ($Entry in $DynamicParameterList)
                {
                    if ($Entry.Name -eq $DynamicParameter.Key)
                    {
                        $IDParameter = $Entry.IDParameter
                        $IDsMethod   = $Entry.IDsMethod
                        break
                    }
                }
                # Store results in an array, since input might be an array
                $DynamicParameterValue = @()
                # Step through each value on the dynamic parameter (if parameter is an array, there may be several)
                foreach ($DynamicParameterValueItem in $DynamicParameter.Value.Value)
                {
	                # Use IDsMethod to look up object containing ID
                    $DynamicParameterValueObject = Invoke-Expression $IDsMethod | Where-Object Name -eq $DynamicParameterValueItem
                    #
                    if ($DynamicParameter.Key -eq 'AppName')
                    {
                        $DynamicParameterValue += $DynamicParameterValueObject.AppID
                    }
                    else
                    {
                        $DynamicParameterValue += $DynamicParameterValueObject.ID
                    }
                }
                $Return += @{"$IDParameter" = "$DynamicParameterValue"}
            }
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

<#
.Synopsis
    Get command and ignore parameters for a function and a type
.DESCRIPTION
    Internal function.
    Return a hashtable of command parameter names and parameter names that may
    be safely ignored for the calling command and its key type. These lists
    will be used by the calling command to update the object of the key type.
.PARAMETER KeyType
    The name of the key type.
.EXAMPLE
    C:\> Get-Params -KeyType 'TeamDynamix_Api_Tickets_TicketSearch'

   Returns a hashtable with the parameter names for the calling function and
   the parameters in the calling function that are not properties of the type
   [TeamDynamix_Api_Tickets_TicketSearch], which may be ignored when updating.
#>
function Get-Params
{
    param
    (
        # Key type for function
        [Parameter(Mandatory=$false,
                   Position=0)]
        [string]
        $KeyType,

        # Name of the command
        [Parameter(Mandatory=$false,
                   Position=1)]
        [string]
        $CommandName
    )

    begin
    {
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
    }

    process
    {
        # Get parameters for command
        if ($CommandName)
        {
            $CommandParameters = (Get-Command $CommandName).Parameters
        }
        else
        {
            $CommandParameters = (Get-Command (Get-PSCallStack)[1].Command).Parameters
        }

        # Get parameters to ignore (none if there's no key type)
        if ($KeyType)
        {
            #  Identify local parameters to be ignored (parameters in the command that aren't in the primary function class)
            $KeyTypeMembers = (New-Object -TypeName $KeyType | Get-Member -MemberType Properties).Name
            $IgnoreParameters  = $CommandParameters.Keys  | Where-Object {$_ -notin $KeyTypeMembers}
            $IgnoreParameters += ($CommandParameters.GetEnumerator() | Where-Object {$_.Value.IsDynamic -eq $true}).Key
        }
        else
        {
            $IgnoreParameters = $null
        }

        return @{Command = $CommandParameters.Keys
                 Ignore = $IgnoreParameters}
    }
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

<#
.Synopsis
    Builds the appropriate URI for contacting TeamDynamix.
.DESCRIPTION
    Convenience function for building the appropriate URI for contacting
    TeamDynamix.
.PARAMETER Preview
    Return Preview URI.
.PARAMETER Sandbox
    Return Sandbox URI.
.PARAMETER Portal
    Return portal URI instead of the API URI
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-URI {
    [CmdletBinding()]
    param
    (
        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment,

        # Return portal URI, instead of the API URI
        [Parameter(Mandatory=$false)]
        [switch]
        $Portal
    )
    switch ($Environment)
    {
        Production {
            if ($Portal)
            {
                $BaseURI = "$($TDConfig.DefaultTDPortalBaseURI)$($TDConfig.DefaultTDPortalTargetURI)"
            }
            else
            {
                $BaseURI = "$($script:DefaultTDBaseURI)$script:DefaultTDTargetURI"
            }
        }
        Preview {
            if ($Portal)
            {
                $BaseURI = "$($TDConfig.DefaultTDPortalPreviewBaseURI)$($TDConfig.DefaultTDPortalTargetURI)"
            }
            else
            {
                $BaseURI = "$($script:DefaultTDPreviewBaseURI)$script:DefaultTDTargetURI"
            }
        }
        Sandbox {
            if ($Portal)
            {
                $BaseURI = "$($TDConfig.DefaultTDPortalBaseURI)$($TDConfig.DefaultTDPortalSandboxTargetURI)"
            }
            else
            {
                $BaseURI = "$($script:DefaultTDBaseURI)$script:DefaultTDSandboxTargetURI"
            }
        }
    }
    return $BaseURI
}

<#
.Synopsis
    Perform a GET from a REST API.
.DESCRIPTION
    Perform a GET from the TeamDynamix REST API. Includes all the associated
    functions necessary to handle setting the base URI, explicit parameters as
    well as dynamic parameters, and will search by ID/Name or text-based search
    as appropriate. Returns data of the specified type. Convenience function.
.PARAMETER ParameterSetName
    Determines whether to perform a search by text or ID/Name. Allowed values
    are ID, Name (which is treated as an ID, since it is convered to an ID),
    and Search. If ID or Name are used, a search using the IDEndpoint is
    requested. If Search is used, the AllEndpoint is used if Search is empty,
    and the SearchEndpoint is used if the Search has text.
.PARAMETER BoundParameters
    Bound parameters for calling function.
.PARAMETER DynamicParameterDictionary
    Dynamic parameters for calling function. Will be converted to variables.
.PARAMETER SearchType
    Key (core) object type for the calling function. Used to create a new
    search object.
.PARAMETER ReturnType
    Return object type. Used to create the return object.
.PARAMETER AllEndpoint
    The API endpoint used to retrieve all objects, if present.
.PARAMETER SearchEndpoint
    The API endpoint used to search for objects, if present.
.PARAMETER IDEndpoint
    The API endpoint used to search for a specific ID, if present.
.PARAMETER AppID
    The platform application that is associated with the calling function.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>$InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = 'TeamDynamix_Api_Assets_AssetStatusSearch'
            ReturnType       = 'TeamDynamix_Api_Assets_AssetStatus'
            AllEndpoint      = "$AppID/assets/statuses"
            SearchEndpoint   = "$AppID/assets/statuses/search"
            IDEndpoint       = "$AppID/assets/statuses/$ID"
            AppID            = $AppID
            DynamicParameterDictionary = $DynamicParameterDictionary
            # Fixed parameters
            ParameterSetName    = $pscmdlet.ParameterSetName
            BoundParameters     = $MyInvocation.BoundParameters.Keys
            Environment         = $Environment
            AuthenticationToken = $AuthenticationToken
        }
        $Return = $InvokeParams | Invoke-Get

    Returns the result of an Invoke-RESTCall, using the appropriate endpoint
    based on the ParameterSetName.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Invoke-Get {
    [CmdletBinding()]
    param
    (
        # Set codepath for search or ID/Name
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet('ID','Name','Search')]
        [string]
        $ParameterSetName,

        # Bound parameters
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $BoundParameters,

        # Dynamic parameter dictionary
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]
        $DynamicParameterDictionary,

        # Dynamic parameter definitions
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [psobject]
        $DynamicParameterList,

        # Key (core) object type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $SearchType,

        # Return object type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $ReturnType,

        # Endpoint to get all entries
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $AllEndpoint,

        # Endpoint to search
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $SearchEndpoint,

        # Endpoint to search
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $IDEndpoint,

        # Application ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $AppID,

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

    $ContentType = 'application/json; charset=utf-8'
    $BaseURI = Get-URI -Environment $Environment
    $Params = Get-Params -KeyType $SearchType -Command (Get-PSCallStack)[1].Command
    #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
    if ($DynamicParameterDictionary)
    {
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
    }
    switch -regex ($ParameterSetName)
    {
        'ID|Name'
        {
            # Return ID number, if one is present, else pull the first variable name from the endpoint, or failing that, just list the endpoint
            Write-ActivityHistory ("Retrieving ID {0}" -f $(if ($ID) {$ID} elseif ($IDEndpoint -match '\$(\w[\w-]+)') {(Get-Variable $Matches[1]).Value} else {$IDEndpoint}))
            # Use this URI syntax to allow for late binding of the variable name in the IDEndpoint spec (required for dynamic variables)
            $Return = Invoke-RESTCall -Uri ("{0}/{1}" -f $BaseURI,(Invoke-Expression "`"$IDEndpoint`"")) -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        'Search'
        {
            # If no search is specified on commandline, just return all
            #   Parameters in the ignore list (except the dynamic parameters list) can be ignored
            if ($AllEndpoint -and (-not ($BoundParameters | Where-Object {$_ -notin $Params.Ignore})) -and (-not ($BoundParameters | Where-Object {$_ -in $DynamicParameterDictionary.Keys})))
            {
                Write-ActivityHistory 'Retrieving all TeamDynamix items'
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AllEndpoint" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
            else
            {
                $Search = Invoke-Expression "[$SearchType]::new()"
                Update-Object -InputObject $Search -ParameterList $Params.Command -BoundParameterList $BoundParameters -IgnoreList $Params.Ignore -AuthenticationToken $AuthenticationToken -Environment $WorkingEnvironment
                # Reformat object for upload to TD if needed, include proper date format
                if (([System.AppDomain]::CurrentDomain.GetAssemblies()| Where-Object Location -eq $null).GetTypes().Name | Where-Object {$_ -eq "TD_$SearchType"})
                {
                    $SearchTD = Invoke-Expression "[TD_$SearchType]::new(`$Search)"
                }
                else
                {
                    # No reformat needed
                    $SearchTD = $Search
                }
                Write-ActivityHistory 'Retrieving matching TeamDynamix items'
                $Return = Invoke-RESTCall -Uri "$BaseURI/$SearchEndpoint" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $SearchTD -Depth 10)
            }
        }
    }

    if ($Return)
    {
        # If returned data is larger than 4MB PowerShell's default JSON
        # serializer/deserializer will return a string rather than an object.
        # Use .NET call to increase maximum length.
        if ($Return.GetType().Name -eq 'string')
        {
            Write-ActivityHistory 'A large result was returned, requiring special processing. Stand by.'
            $Return = ParseJsonString($Return)
            Write-ActivityHistory 'Processing complete.'
        }
        # Convert returned item to correct type
        $Return = ($Return | ForEach-Object {Invoke-Expression "[$ReturnType]::new(`$_)"})
    }
    return $Return
}

function Invoke-New {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        # Set codepath for Set instead of New
        #  Command used to retrieve item to modify
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [string]
        $RetrievalCommand,

        # Bound parameters
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [string[]]
        $BoundParameters,

        # Dynamic parameter dictionary
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [System.Management.Automation.RuntimeDefinedParameterDictionary]
        $DynamicParameterDictionary,

        # Dynamic parameter definitions
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [psobject]
        $DynamicParameterList,

        # Set/New object type
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [string]
        $ObjectType,

        # Endpoint for set/new
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [string]
        $Endpoint,

        # REST Method
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [ValidateSet('Get','Put','Post','Delete','Patch')]
        [string]
        $Method,

        # Application ID
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [int]
        $AppID,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Set')]
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='New')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false)]
        [EnvironmentChoices]
        $Environment = $WorkingEnvironment
    )

    $ContentType = 'application/json; charset=utf-8'
    $BaseURI = Get-URI -Environment $Environment
    $Params = Get-Params -KeyType $ObjectType -Command (Get-PSCallStack)[1].Command
    #  Set ID parameters from their corresponding Name (dynamic) parameters (in begin block if none are gathered from the pipeline, otherwise in process block)
    if ($DynamicParameterDictionary)
    {
        $IDsFromNamesUpdates = Get-IDsFromNames -DynamicParameterDictionary $DynamicParameterDictionary -DynamicParameterList $DynamicParameterList
        $IDsFromNamesUpdates.GetEnumerator() | ForEach-Object {Set-Variable -Name $_.Name -Value $_.Value}
    }
    # Test for Set or New
    if ($RetrievalCommand)
    {
        # Set
        Write-ActivityHistory "Getting full TeamDynamix object record via $RetrievalCommand"
        try
        {
            $Object = Invoke-Expression "$RetrievalCommand -AuthenticationToken `$AuthenticationToken -Environment `$Environment -ErrorAction Stop"
            if (-not $Object)
            {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find source object on TeamDynamix to modify."
            }
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to find source object on TeamDynamix to modify."
        }
        $ShouldProcessText1 = "$Endpoint - $($Object | Out-String)"
        $ShouldProcessText2 = 'Update TeamDynamix item'
    }
    else
    {
        # New
        #  Create object only if $ObjectType is present
        if ($ObjectType)
        {
            $Object = Invoke-Expression "[$ObjectType]::new()"
        }
            $ShouldProcessText1 = $BoundParameters | Out-String
            $ShouldProcessText2 = 'Add new TeamDynamix item'
    }
    Write-ActivityHistory 'Preparing object for update/creation.'
    Update-Object -InputObject $Object -ParameterList $Params.Command -BoundParameterList $BoundParameters -IgnoreList $Params.Ignore -AuthenticationToken $AuthenticationToken -Environment $WorkingEnvironment
    # Special cases for Set
    if ($RetrievalCommand)
    {
        # Remove attributes specified for removal
        if ($BoundParameters.Keys -contains 'RemoveAttributes')
        {
            foreach ($RemoveAttribute in $RemoveAttributes)
            {
                $Object.RemoveCustomAttribute($RemoveAttribute)
            }
        }
    }
    # Reformat object for upload to TD if needed, include proper date format
    if (([System.AppDomain]::CurrentDomain.GetAssemblies()| Where-Object Location -eq $null).GetTypes().Name | Where-Object {$_ -eq "TD_$ObjectType"})
    {
        $ObjectTD = Invoke-Expression "[TD_$ObjectType]::new(`$Object)"
    }
    else
    {
        # No reformat needed
        $ObjectTD = $Object
    }
    # Update TeamDynamix with Set/New data
    if ($pscmdlet.ShouldProcess($ShouldProcessText1, $ShouldProcessText2))
    {
        Write-ActivityHistory 'Updating TeamDynamix.'
        try
        {
            if ($ObjectType)
            {
                # The Invoke-Expression allows for late evaluation of the $Endpoint variable, otherwise the variable name (not the value) is passed to Invoke-RESTCall
                $Return = Invoke-RESTCall -Uri $(Invoke-Expression "Write-Output $BaseURI/$Endpoint") -ContentType $ContentType -Method $Method -Headers $AuthenticationToken -Body (ConvertTo-Json $ObjectTD -Depth 10)
            }
            else
            {
                $Return = Invoke-RESTCall -Uri $(Invoke-Expression "Write-Output $BaseURI/$Endpoint") -ContentType $ContentType -Method $Method -Headers $AuthenticationToken
            }
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Error setting $Endpoint.`n$TDAsset"
        }
        if ($Return)
        {
            $Return = Invoke-Expression "[$ObjectType]::new(`$Return)"
        }
        Write-ActivityHistory ($Return | Out-String)
        if ($Passthru)
        {
            Write-Output $Return
        }
    }
}

function Get-WeekdayDate ([datetime]$Date)
{
    # Back up date, by whole days, until it's not on a weekend
    if     ($Date.DayOfWeek -eq 'Saturday') {$Return = $Date.AddDays(-1)}
    elseif ($Date.DayOfWeek -eq 'Sunday'  ) {$Return = $Date.AddDays(-2)}
    else   {$Return = $Date}
    return $Return
}

function Get-Median ([array]$List)
{
    $List = $List | Sort-Object
    if (($List.Count % 2) -eq 0) {
        $Return = ($List[$List.Count / 2] + $List[($List.Count / 2) - 1]) / 2
    }
    else {
        $Return = $List[($List.Count - 1) / 2]
    }
    return $Return
}

function Get-CalendarDateGUI
{
    Param
    (
        # Maximum days to select
        [Parameter(Mandatory=$false,
                Position=0)]
        [int]$MaxDates = 1
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $Form = New-Object Windows.Forms.Form -Property @{
        StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
        Size          = New-Object Drawing.Size 243, 240
        Text          = 'Select a Date'
        Topmost       = $true
    }

    $Calendar = New-Object Windows.Forms.MonthCalendar -Property @{
        ShowTodayCircle   = $false
        MaxDate = [datetime]::Today
        MaxSelectionCount = $MaxDates
    }
    $Form.Controls.Add($Calendar)

    $OkButton = New-Object Windows.Forms.Button -Property @{
        Location     = New-Object Drawing.Point 38, 175
        Size         = New-Object Drawing.Size 75, 23
        Text         = 'OK'
        DialogResult = [Windows.Forms.DialogResult]::OK
    }
    $Form.AcceptButton = $OkButton
    $Form.Controls.Add($OkButton)
    $Form.ShowDialog() | Out-Null
    return $Calendar.SelectionRange
}

function New-Logfile ([string]$FullPath)
{
    # Assume success
    $Return = $true

    if (-not (Test-Path -PathType Leaf $FullPath))
    {
        $Path = Split-Path $FullPath

        # If path isn't specified, assume current directory - necessary for Resolve-Path in the next step
        if (-not $Path)
        {
            $Path = '.'
        }

        # Log file directory
        #  Check to see if log file directory needs to be created
        if (-not (Resolve-Path $Path -ErrorAction SilentlyContinue))
        {
            #  Create path, if fails, return error
            try
            {
                New-Item -ItemType Directory -Path $Path -ErrorAction Stop | Out-Null
            }
            catch
            {
                $Return = $false
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to create log file path, $Path."
            }
        }
        # Create log file
        try
        {
            New-Item -ItemType File -Path $FullPath | Out-Null
        }
        catch
        {
            $Return = $false
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "Unable to create log file, $FullPath."
        }
    }
    return $Return
}

<#
.Synopsis
    Get serial number from an asset drawn from the management consoles
.DESCRIPTION
    Internal function.
    Return the serial number of an asset. Assets are loaded from the management
    consoles.
.PARAMETER Asset
    The asset from the management console.
.PARAMETER InputType
    The managment console the asset was imported from.
.EXAMPLE
    C:\> Get-AssetSerialNumber -Asset $Asset -InputType $InputType

   Returns the serial number of the asset $Asset from the management console
   $InputType.
#>
function Get-AssetSerialNumber
{
    [CmdletBinding()]
    Param
    (
        # Asset
        [Parameter(Mandatory=$true)]
        [pscustomobject]
        $Asset,

        # Serial number location(s)
        [Parameter(Mandatory=$true)]
        [string[]]
        $SNLocation,

        # Bad serial numbers - ignore
        [Parameter(Mandatory=$true)]
        [string[]]
        $BadSerialNumbers
    )

    $SerialNumber = $null
    # Loop through all known locations for serial numbers until we find a valid one
    foreach ($SNDescription in $SNLocation)
    {
        $SN = Invoke-Expression -Command $SNDescription
        if ($SN -and -not ($SN -in $BadSerialNumbers))
        {
            # Found a good one, stop looking
            $SerialNumber = $SN
            break
        }
    }
    return $SerialNumber
}

<#
.Synopsis
    Get the model ID for an asset drawn from the management consoles
.DESCRIPTION
    Internal function.
    Return product model ID for an asset. Assets are loaded from the management
    consoles.
.PARAMETER Asset
    The asset from the management console.
.PARAMETER ProductNameLocation
    The location of the product name as a string. Use $Asset to refer to the
    asset.
.PARAMETER ProductPartLocation
    The location of the product part as a string. Use $Asset to refer to the
    asset.
.EXAMPLE
    C:\> Get-AssetProductModelID -Asset $Asset -ProductNameLocation '$Asset.productname' -ProductPartLocation '$Asset.productname'

   Returns the product model ID of the asset $Asset, locating the name and part
   as specified.
#>
function Get-AssetProductModelID
{
    [CmdletBinding()]
    Param
    (
        # Asset
        [Parameter(Mandatory=$true)]
        [pscustomobject]
        $Asset,

        # Product name, as reported by connector
        [Parameter(Mandatory=$true)]
        [string]
        $ProductNameLocation,

        # Product part, as reported by connector
        [Parameter(Mandatory=$true)]
        [string]
        $ProductPartLocation
    )

    if ($ProductNameLocation)
    {
        $ProductName = Invoke-Expression -Command $ProductNameLocation
    }
    if ($ProductPartLocation)
    {
        $ProductPart = Invoke-Expression -Command $ProductPartLocation
    }
    $ProductModelID = $null
    if ($ProductName)
    {
        $ProductModelID = ($ProductModels | Where-Object Name -eq $ProductName).ID
        # If model not found, check part number, but not if the product name is blank
        if (-not $ProductModelID)
        {
            # Switch to search the product part, using the part (for input types that have one), or the name for those that don't
            if ($ProductPart)
            {
                $ProductModelID = ($ProductModels | Where-Object PartNumber -eq $ProductPart).ID
            }
            else
            {
                $ProductModelID = ($ProductModels | Where-Object PartNumber -eq $ProductName).ID
            }
        }
        # If product model is found more than once, show an error
        if ($ProductModelID.Count -gt 1)
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Duplicate product model: $ProductModelID."
            $ProductModelID = $null
        }
    }
    return $ProductModelID
}

function Get-OrgAppsByRoleName {
    [CmdletBinding()]
    param (
        # Set ID of application for asset status
        [Parameter(Mandatory=$true,
                   Position=0,
                   ValueFromPipeline=$true)]
        [string]
        $UserRoleName,

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
    }
    process
    {
        foreach ($OrgAppConfig in ($TDConfig.UserRoles | Where-Object Name -eq $UserRoleName).OrgApplications)
        {
            # Pull security role name from configuration by user role name
            $AppSecurityRoleName = $OrgAppConfig.SecurityRole
            if ($AppSecurityRoleName)
            {
                # Get security role ID
                $AppSecurityID = (Get-TDSecurityRole -AppName $OrgAppConfig.Name -AuthenticationToken $TDAuthentication -Environment $WorkingEnvironment | Where-Object Name -eq $AppSecurityRoleName).ID
                # Determine if role is an app administrator
                if ($OrgAppConfig.SecurityRole)
                {
                    $IsAdministrator = $true
                }
                else
                {
                    $IsAdministrator = $false
                }
                # Create application object based on the role
                return (New-TDUserApplication -SecurityRoleId $AppSecurityID -IsAdministrator $IsAdministrator -AuthenticationToken $TDAuthentication -Environment $WorkingEnvironment)
            }
        }
    }

    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}
#endregion