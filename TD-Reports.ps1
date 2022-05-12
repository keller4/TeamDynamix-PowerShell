### Reports

function Get-TDReport
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # ID of report to return
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
        $ID,

        # Return report data
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false)]
        [switch]
        $WithData,

        # Search report sorting expression
        [Parameter(ParameterSetName='ID',
                   Mandatory=$false)]
        [string]
        $DataSortExpression = '',

        # Search text, substring of report name
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [ValidateLength(1,50)]
        [string]
        $SearchText,

        # Search report owner UID
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [guid]
        $OwnerUID,

        # Search report application ID number
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int]
        $ForAppID,

        # Search report application name substring
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [ValidateLength(1,50)]
        [string]
        $ForApplicationName,

        # Search report source ID number
        [Parameter(ParameterSetName='Search',
                   Mandatory=$false)]
        [int]
        $ReportSourceID,

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
        $LocalIgnoreParameters = @('ID','WithData','DataSortExpression')
    }

    process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'ID'
            {
                if ($ID -ne '')
                {
                    $Result = Invoke-RESTCall -Uri "$BaseURI/reports/$($ID)?withData=$($WithData.IsPresent)&dataSortExpression=$DataSortExpression" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
                else
                {
                    $Result = Invoke-RESTCall -Uri "$BaseURI/reports" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
            }
            'Search'
            {
                $Query = [TeamDynamix_Api_Reporting_ReportSearch]::new()
                Update-Object -InputObject $Query -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                $Result = Invoke-RESTCall -Uri "$BaseURI/reports/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $Query -Depth 10)
            }
        }
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Reporting_ReportInfo]::new($_)})
        }
        return $Result
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDSearch
{
    [CmdletBinding(DefaultParameterSetName='Name')]
    [alias('Get-TDAssetSearch','Get-TDTicketSearch')]
    [OutputType([System.Management.Automation.PSCustomObject])]
    Param
    (
        # Set ID of application for configuration item
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID')]
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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $Attributes.ParameterSetName = 'Name'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll($true) | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Get-TDSearch
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDSearch'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetSearch'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketSearch'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }

    process
    {
        # Get ID for application if name is supplied
        if ($PSCmdlet.ParameterSetName -eq 'Name')
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
            }
            'Asset/CI'
            {
                $AppType = 'assets'
            }
        }
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/searches" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_SavedSearches_SavedSearch]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Search-TD
{
    [CmdletBinding(DefaultParameterSetName='AppName')]
    [alias('Search-TDAsset','Search-TDTicket')]
    Param
    (
        # Search ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='AppName')]

        [int]
        $ID,

        # Text to search for
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [string]
        $SearchText,

        # Set product type order
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [int]
        $PageIndex,

        # Set product type parent ID
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppID')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='AppName')]
        [int]
        $PageSize = 5,

        # Set ID of application to create new product model in
        [Parameter(Mandatory=$true,
                   ParameterSetName='AppID')]
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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $Attributes.ParameterSetName = 'AppName'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll($true) | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        #  Return first Tickets application for Search-TD
        switch ($MyInvocation.InvocationName)
        {
            'Search-TD'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Search-TDAsset'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Search-TDTicket'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Filter on tickets for which the current user is responsible.'
        $Attributes.DontShow = ($MyInvocation.InvocationName -eq 'Search-TDAsset')
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $OnlyMy = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("OnlyMy", [switch], $AttributeCollection)
        $ParameterDictionary.Add("OnlyMy", $OnlyMy)

        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Filter for only open tickets (status of "New", "In Process", or "On Hold").'
        $Attributes.DontShow = ($MyInvocation.InvocationName -eq 'Search-TDAsset')
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $OnlyOpen = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("OnlyOpen", [switch], $AttributeCollection)
        $ParameterDictionary.Add("OnlyOpen", $OnlyOpen)

        return $ParameterDictionary
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
    }
    Process
    {
        $RequestPage = [TeamDynamix_Api_RequestPage]::new($PageIndex,$PageSize)
        # Get ID for application if name is supplied
        if ($PSCmdlet.ParameterSetName -eq 'AppName')
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
                $SearchOptions = [TeamDynamix_Api_Tickets_TicketSavedSearchOptions]::new($SearchText,$OnlyMy.Value,$OnlyOpen.Value,$RequestPage)
            }
            'Asset/CI'
            {
                $AppType = 'assets'
                $SearchOptions = [TeamDynamix_Api_Assets_AssetSavedSearchOptions]::new($SearchText,$RequestPage)
            }
        }
        Write-ActivityHistory "Getting page $PageIndex for saved search $ID from TeamDynamix."
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/searches/$ID/results" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $SearchOptions -Depth 10)
        if ($Return)
        {
            #$Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
        }
        Write-ActivityHistory ($SearchOptions | Out-String)
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDFeed
{
    [CmdletBinding(DefaultParameterSetName='Page')]
    [alias('Get-TDAssetFeed','Get-TDTicketFeed','Get-TDProjectFeed')]
    Param
    (
        # Get feed for this ID
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ParameterSetName='ID',
                   Position=0)]
        [int]
        $ID,

        # Last-updated date to filter on
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [datetime]
        $DateFrom,

        # Earliest-updated date to filter on
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [datetime]
        $DateTo,

        # Number of replies per feed entry
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [ValidateRange(0,100)]
        [int]
        $ReplyCount = 0,

        # Number of feed entries to return
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Page')]
        [ValidateRange(1,100)]
        [int]
        $ReturnCount = 25,

        # Set UIDs of creators to ignore
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [guid[]]
        $IgnoreUIDs,

        # Set ID of application
        [Parameter(Mandatory=$false,
                   ParameterSetName='ID')]
        [int]
        $AppID = 0,

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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose custom attributes will be retrieved'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll($true) | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDFeed'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetFeed'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketFeed'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDProjectFeed'
            {
                $AppName.Value = 'Projects / Workspaces'
            }
        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
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
    }
    Process
    {
        # Get ID from name if AppID is not supplied (AppID defaults to 0)
        if ($AppID -eq 0)
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        $AppClass = $TDApplications.Get($AppID,$Environment).AppClass
        switch ($AppClass)
        {
            'TDTickets'  {$AppIDClassURI = "$AppID/tickets"}
            'TDAssets'   {$AppIDClassURI = "$AppID/assets" }
            'TDProjects' {$AppIDClassURI = 'projects' }
        }
        switch ($pscmdlet.ParameterSetName)
        {
            'ID'
            {
                Write-ActivityHistory "Retrieving feed for TeamDynamix $AppClass ID $ID"
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDClassURI/$ID/feed" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    if ($IgnoreUIDs)
                    {
                        $Return = $Return | Where-Object CreatedUID -notin $IgnoreUIDs
                    }
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdate]::new($_)})
                }
            }
            'Page'
            {
                # Paged feed search is date-based.
                Write-ActivityHistory "Retrieving paged feed for TeamDynamix $AppClass ID $ID"
                # Build page query string
                $PageQuery = ''
                if ($DateFrom)
                {
                    $PageQuery = "DateFrom=$($DateFrom | Get-Date -Format o)"
                }
                if ($DateTo)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "DateTo=$($DateTo | Get-Date -Format o)"
                }
                if ($ReplyCount)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "ReplyCount=$ReplyCount"
                }
                if ($ReturnCount)
                {
                    if($PageQuery)
                    {
                        $PageQuery += '&'
                    }
                    $PageQuery += "ReturnCount=$ReturnCount"
                }
                $Return = Invoke-RESTCall -Uri "$BaseURI/$AppIDClassURI/feed/?$PageQuery" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                if ($Return)
                {
                    $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Feed_ItemUpdatesPage]::new($_)})
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

function Get-TDFeedItem
{
    [CmdletBinding(DefaultParameterSetName='ID')]
    Param
    (
        # The ID of the service offering.
        [Parameter(Mandatory=$true,
                   ParameterSetName='ID')]
        [Int32]
        $ID,

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
    }
    Process
    {
        $InvokeParams = [pscustomobject]@{
            # Configurable parameters
            SearchType       = $null
            ReturnType       = 'TeamDynamix_Api_Feed_ItemUpdate'
            AllEndpoint      = $null
            IDEndpoint       = 'feed/$ID'
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
    End
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDForm
{
    [CmdletBinding()]
    [alias('Get-TDAssetForm','Get-TDTicketForm')]
    Param
    (
        # Select based on whether form is active
        [Parameter(Mandatory=$false)]
        [system.nullable[boolean]]
        $IsActive,

        # Set ID of application for configuration item
        [Parameter(Mandatory=$false)]
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
        $ParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $Attributes = New-Object System.Management.Automation.ParameterAttribute
        $Attributes.Mandatory = $false
        $Attributes.HelpMessage = 'Name of application whose forms will be retrieved'
        $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $AttributeCollection.Add($Attributes)
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute(($TDApplications.GetAll($true) | Where-Object Type -ne 'Standard').Name)
        $AttributeCollection.Add($ValidateSet)
        $AppName = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("AppName", [string], $AttributeCollection)
        # Specify a default value if none is provided, based on which function name is used
        #  Use first entry in TDApplications that matches the appropriate type
        switch ($MyInvocation.InvocationName)
        {
            'Get-TDForm'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }
            'Get-TDAssetForm'
            {
                $AppName.Value = $TDConfig.DefaultAssetCIsApp
            }
            'Get-TDTicketForm'
            {
                $AppName.Value = $TDConfig.DefaultTicketingApp
            }

        }
        $ParameterDictionary.Add("AppName", $AppName)
        return $ParameterDictionary
    }

    begin
    {
        Write-ActivityHistory "`n-----`nIn $($MyInvocation.MyCommand.Name)"
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }

    process
    {
        # Get ID for application if AppID is not supplied
        if (-not $AppID)
        {
            $AppID = $TDApplications.Get($AppName.Value,$Environment).AppID
        }
        # Get app type to use appropriate URI
        switch ($TDApplications.Get($AppID,$Environment).Type)
        {
            'Ticketing'
            {
                $AppType = 'tickets'
            }
            'Asset/CI'
            {
                $AppType = 'assets'
            }
        }
        $Return = Invoke-RESTCall -Uri "$BaseURI/$AppID/$AppType/forms" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        if ($Return)
        {
            if ($null -ne $IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            $Return = ($Return | ForEach-Object {[TeamDynamix_Api_Forms_Form]::new($_)})
        }
        return $Return
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU97LMxGpEtRvJG0NjPufhholE
# yl2gggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNdg
# j1UJlAhtHcIlNgD/w0VVkNSBMA0GCSqGSIb3DQEBAQUABIICAMDNHqVTq62jd5OI
# 4cbyyfWJnYpu2QnGZkbu9zCwtzZMc37kMlRMCu8+zUNaNsfi7uhw2036SqN6m5zb
# yiRW4paL0CCCT3GXqVGVgb96dcKJz9Zw0UMhtTOTAfGzu5PE9myBWxjyo17kfV+w
# /CCYEIQKxnVpQzhvZ4ZAKjC1RQfd5G2QPajloJ3yORTUmGs97tmslfnCmnQXD4e5
# yw6WxlrVeeP/PbD/xvXmLc8QzW/vTGIGa9UuJYfIi09LDzkr1p8h2BrUQmGaCMWu
# pqZ3s3/t1cjPbZ5rx9OYFJvSp/actmPyOfXsm3paWxCViffTFhrWJVq7htrMTjgp
# kpD98Fs98W7OubjGB87DgwKp7iwAet4d0j8NfLEzC/Dj4NdpzG+G2GcgbwRZH/ET
# XTTcSpoI+gaqUnK1V6j6wXxTi2Z9u5tTln26dCrGWqOUUOrFY86XvriWAvJZmSN+
# 5h6iCIN6g5kYX8jP8a78yoW61jN7fDmBvSQCSZ25j5CiaLDtIDPv9e554v1grpHj
# NoaUUiTKZWbtAxt6OTNib5DI8aYi/BHO1Beg/b4/Q9wIheYD0Up9a2/aMlDyEm4t
# N0uJSoKZ/1K+P9uFvi2HPHBT8/lqzwInmFN2/5QTZ+CTZ9D4iHnSetYzEotosgEO
# mDogysrXniSPJX0RmvSa9B62tai0
# SIG # End signature block
