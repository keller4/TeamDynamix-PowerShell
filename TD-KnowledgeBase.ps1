### KnowledgeBase

function Get-TDKBArticle
{
    [CmdletBinding(DefaultParameterSetName='ArticleID')]
    Param
    (
        # Article ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0,
                   ParameterSetName='ArticleID')]
        [Parameter(Mandatory=$true,
                   Position=0,
                   ParameterSetName='Related')]
        [int]
        $ID,

        # Retrieve related articles
        [Parameter(Mandatory=$true,
                   ParameterSetName='Related')]
        [switch]
        $Related,

        # Search text
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [string]
        $SearchText,

        # Article status
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]
        $Status,

        # Category ID of KB articles
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $CategoryID,

        # Author UID of KB articles
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [guid]
        $AuthorUID,

        # Return published articles
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsPublished,

        # Return public articles
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [System.Nullable[boolean]]
        $IsPublic,

        # Number of KB articles to return
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [int]
        $ReturnCount,

        # Include article bodies
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $IncludeArticleBodies,

        # Include shortcuts
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $IncludeShortcuts,

        # Filter based on custom attributes
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [array]
        $CustomAttributes,

        # Retrieve full detail
        [Parameter(Mandatory=$false,
                   ParameterSetName='Search')]
        [switch]
        $Detail,

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
                Name             = 'CategoryName'
                Type             = 'string'
                ValidateSet      = (Get-TDKBCategory).Name
                HelpText         = 'Category name'
                ParameterSetName = 'Search'
                IDParameter      = 'CategoryID'
                IDsMethod        = 'Get-TDKBCategory'
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
        $LocalIgnoreParameters = @('ID','Related','Detail','CategoryName')
    }
    Process
    {
        $KBSearch = [TeamDynamix_Api_KnowledgeBase_ArticleSearch]::new()
        switch ($PSCmdlet.ParameterSetName)
        {
            'ArticleID'
            {
                #If no search is specified on commandline, just return all KB articles
                if (-not $ID)
                {
                    Write-ActivityHistory 'Retrieving all TeamDynamix KnowledgeBase articles'
                    $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $KBSearch -Depth 10)
                }
                else
                {
                    Write-ActivityHistory "Retrieving KnowledgeBase article $ID"
                    $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
                }
            }
            'Search'
            {
                # Set CategoryID if CategoryName is present
                if ($DynamicParameterDictionary.CategoryName.Value) {$CategoryID = (Get-TDKBCategory -AuthenticationToken $AuthenticationToken -Environment $Environment | Where-Object Name -eq $DynamicParameterDictionary.CategoryName.Value).ID}
                Update-Object -InputObject $KBSearch -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
                Write-ActivityHistory 'Retrieving selected TeamDynamix KnowledgeBase articles'
                $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/search" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $KBSearch -Depth 10)
            }
            'Related'
            {
                Write-ActivityHistory 'Retrieving related TeamDynamix KnowledgeBase articles'
                $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/related" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
            }
        }
        if ($Detail)
        {
            if ($Return)
            {
                $Return = $Return.ID | ForEach-Object {Get-TDKBArticle -ID $_ -AuthenticationToken $AuthenticationToken -Environment $Environment}
            }
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_KnowledgeBase_Article]::new($_)})
        }
    }
}

function New-TDKBArticle
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   DefaultParameterSetName='OwnerUid')]
    Param
    (
        # Subject of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Subject,

        # Body of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Body,

        # Order of service among its siblings on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order = 1.0,

        # Category ID of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $CategoryID,

        # Summary of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Summary,

        # Article status
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]
        $Status,

        # Review date of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[datetime]]
        $ReviewDateUtc,

        # Determines whether the KB article is published on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $IsPublished,

        # Determines whether the KB article is public on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $IsPublic,

        # Determines whether the KB article groups are whitelisted or blacklisted on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $WhitelistGroups,

        # Determines whether the KB article inherits permissions from the parent category on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $InheritPermissions,

        # Determines whether the KB article on TeamDynamix should be notified of feedback
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $NotifyOwner,

        # The KB article's owner UID in TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwnerUid,

        # The KB article's owning group UID in TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[int]]
        $OwnerGroupID,

        # Tags for the KB article on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Tags,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # Use TeamDynamix Preview API
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID')]
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
        $KBArticle = [TeamDynamix_Api_KnowledgeBase_Article]::new()
        Update-Object -InputObject $KBArticle -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($KBArticle | Out-String), 'Creating KnowledgeBase article'))
        {
            Write-ActivityHistory 'Creating KnowledgeBase article'
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $KBArticle -Depth 10)
            if ($Return)
            {
                return [TeamDynamix_Api_KnowledgeBase_Article]::new($Return)
            }
        }
    }
}

function Remove-TDKBArticle
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # KB article to delete from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
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
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("article ID: $ID", 'Delete TeamDynamix KnowledgeBase article'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
    }
}

function Set-TDKBArticle
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   DefaultParameterSetName='OwnerUid')]
    Param
    (
        # Subject of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerUid',
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$true,
                   ParameterSetName='OwnerGroupID',
                   Position=0,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Subject of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Subject,

        # Body of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Body,

        # Order of service among its siblings on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order,

        # Category ID of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $CategoryID,

        # Summary of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Summary,

        # Article status
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]
        $Status,

        # Review date of new KB article to create on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[datetime]]
        $ReviewDateUtc,

        # Determines whether the KB article is published on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $IsPublished,

        # Determines whether the KB article is public on TeamDynamix (ignored)
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $IsPublic,

        # Determines whether the KB article groups are whitelisted or blacklisted on TeamDynamix (ignored)
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $WhitelistGroups,

        # Determines whether the KB article inherits permissions from the parent category on TeamDynamix (ignored)
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $InheritPermissions,

        # Determines whether the KB article on TeamDynamix should be notified of feedback
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [System.Nullable[boolean]]
        $NotifyOwner,

        # The KB article's owner UID in TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwnerUid,

        # The KB article's owning group ID in TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [guid]
        $OwningGroupID,

        # Tags for the KB article on TeamDynamix
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]
        $Tags,

        # Set custom attributes
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid',
                   ValueFromPipelineByPropertyName=$true)]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID',
                   ValueFromPipelineByPropertyName=$true)]
        [array]
        $Attributes,

        # TeamDynamix authentication token
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID')]
        [hashtable]
        $AuthenticationToken = $TDAuthentication,

        # TeamDynamix working environment
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerUid')]
        [Parameter(Mandatory=$false,
                   ParameterSetName='OwnerGroupID')]
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
        # Retrieve existing KB article
        try
        {
            $KBArticle = Get-TDKBArticle -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "KnowledgeBase article ID $KBArticle not found."
        }
        Update-Object -InputObject $KBArticle -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        # Reformat object for upload to TD, include proper date format
        $KBArticleTD = [TD_TeamDynamix_Api_KnowledgeBase_Article]::new($KBArticle)
        if ($pscmdlet.ShouldProcess(($KBArticle | Out-String), 'Creating KnowledgeBase article'))
        {
            Write-ActivityHistory 'Updating KnowledgeBase article'
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $KBArticleTD -Depth 10)
            if ($Return)
            {
                return [TeamDynamix_Api_KnowledgeBase_Article]::new($Return)
            }
        }
    }
}

function Add-TDKBAttachment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # KB article to get attachment in TeamDynamix
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
        if ($pscmdlet.ShouldProcess("article ID: $ID, attachment name: $FileName", 'Add attachment to TeamDynamix KnowledgeBase article'))
        {
            Write-ActivityHistory "Adding $FileName attachment to KB article $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/attachments" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body $Body
            if ($Return)
            {
                return [TeamDynamix_Api_Attachments_Attachment]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Add-TDKBArticleRelationship
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # KB article with relationship to be deleted
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
        $ID,

        # Related KB article
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
        $RelatedArticleID,

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
        if ($pscmdlet.ShouldProcess("article ID: $ID and related article ID $RelatedArticleID", 'Add TeamDynamix KnowledgeBase article relationship between'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/related/$RelatedArticleID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Remove-TDKBArticleRelationship
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # KB article with relationship to be deleted
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
        $ID,

        # Related KB article
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
        $RelatedArticleID,

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
        if ($pscmdlet.ShouldProcess("article ID: $ID and related article ID $RelatedArticleID", 'Delete TeamDynamix KnowledgeBase article relationship between'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/related/$RelatedArticleID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Get-TDKBCategory
{
    [CmdletBinding()]
    Param
    (
        # Article ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [int]
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
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }
    Process
    {
        if (-not $ID)
        {
            Write-ActivityHistory 'Retrieving all TeamDynamix KnowledgeBase categories'
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        else
        {
            Write-ActivityHistory "Retrieving KnowledgeBase category $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken
        }
        if ($Return)
        {
            return ($Return | ForEach-Object {[TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new($_)})
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function New-TDKBCategory
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Parent category ID for the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ParentID,

        # Order for the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order = 1.0,

        # Name of the category
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Indicates if the category is public
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsPublic,

        # Indicates if the groups assigned to the category are whitelisted or blacklisted
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $WhitelistGroups,

        # Indicates whether category permissions are inherited from the parent category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $InheritPermissions,

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
        $KBCategory = [TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new()
        Update-Object -InputObject $KBCategory -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($KBCategory | Out-String), 'Creating KnowledgeBase category'))
        {
            Write-ActivityHistory 'Creating KnowledgeBase category'
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories" -ContentType $ContentType -Method Post -Headers $AuthenticationToken -Body (ConvertTo-Json $KBCategory -Depth 10)
            if ($Return)
            {
                return [TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new($Return)
            }
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Remove-TDKBCategory
{
    [CmdletBinding(SupportsShouldProcess=$true,
                   ConfirmImpact='High')]
    Param
    (
        # KB article to delete from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true)]
        [int]
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
        $ContentType = 'application/json; charset=utf-8'
        $BaseURI = Get-URI -Environment $Environment
        if (-not $AuthenticationToken)
        {
                Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message 'Authentication required. Specify -AuthenticationToken value. See Get-Help Set-TDAuthentication for more assistance.'
        }
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("category ID: $ID", 'Delete TeamDynamix KnowledgeBase article category'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article category: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories/$ID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
    }
    end
    {
        Write-ActivityHistory "`nLeaving $($MyInvocation.MyCommand.Name)`n-----"
    }
}

function Set-TDKBCategory
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Category ID
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ID,

        # Parent category ID for the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [int]
        $ParentID,

        # Order for the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [double]
        $Order = 1.0,

        # Name of the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Name,

        # Description of the category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [string]
        $Description,

        # Indicates if the category is public
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $IsPublic,

        # Indicates if the groups assigned to the category are whitelisted or blacklisted
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $WhitelistGroups,

        # Indicates whether category permissions are inherited from the parent category
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [boolean]
        $InheritPermissions,

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
        # Retrieve existing KB article
        try
        {
            $KBCategory = Get-TDKBCategory -ID $ID -AuthenticationToken $AuthenticationToken -Environment $Environment -ErrorAction Stop
        }
        catch
        {
            Write-ActivityHistory -MessageChannel 'Error' -ThrowError -Message "KnowledgeBase category ID $KBCategory not found."
        }
        Update-Object -InputObject $KBCategory -ParameterList (Get-Command $MyInvocation.MyCommand.Name).Parameters.Keys -BoundParameterList $MyInvocation.BoundParameters.Keys -IgnoreList ($LocalIgnoreParameters + $GlobalIgnoreParameters) -AuthenticationToken $AuthenticationToken -Environment $Environment
        if ($pscmdlet.ShouldProcess(($KBCategory | Out-String), 'Creating KnowledgeBase article'))
        {
            Write-ActivityHistory 'Updating KnowledgeBase article'
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories/$ID" -ContentType $ContentType -Method Put -Headers $AuthenticationToken -Body (ConvertTo-Json $KBCategory -Depth 10)
            if ($Return)
            {
                return [TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new($Return)
            }
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJ8QMM4JqXJhSEbr24HR/fLqK
# G5ugggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFC5W
# woOTJnAxBSUvq0Bq7GKkUV45MA0GCSqGSIb3DQEBAQUABIICAJdKpEkxyQNdtqWT
# e6fJ2RUppjGuIwnEtf5m1Duq+aYreIx1QnThuRzTYR4/hc6Mv10sYLNZlRv7n3n/
# swAEIdtYJGiU4u2ttqwrEezth8YKy3Q8E2BH61UzwPTpWKDexU3QSP0fUMTFzZYF
# nQqhG6dhqhwqkRmZR3Q3g/BfK65tCNnDfTu7ZOjEIgSyoBDPeCkaStF9uW8P67Ey
# i+349At8ZziJzahPY842PERHAoNiV62p9VEs9DDyFo0vtl9aZH3kTJDDjM9sQF0k
# oksqqe+6UpKJ1mvkm24fqxYqo+8pp9hCsqo6MgxpgvmydjXT5aa+qXMv0LZhwg0r
# I6+XizFoIdey0Q/cg9xd3qs/y8yFCmmTheNj/66hJPwHIP10WXo5Vz1mXn70tI5h
# xaY9jZ06qmvw/dCOlydzvLwPnjEMnPzlM3SaZf5AL//AwI+KubfRfDVG59RRU6kf
# 7LxwRij7Vkukv5UyQCXzQHnn2J6Hz4YJFyqKJ+7IBEv23GRR0LxkDWF4lvgEeziJ
# d6mfop70GvwPrO9y9BgBT3cJdiZq4wF2+OZE20B7iP9BhJl4JW7VYfHi4Mrba0M6
# lrKIg5uFSQ8b9K+vDVcPZZPkAoCqq8G/Mz+IK2eLFtsbKPosR9xBqElTV3q5Ho+E
# g8qpB9EN5q0w4Fc+AVdK8+OJG17u
# SIG # End signature block
