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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
        Write-ActivityHistory "-----`nIn $($MyInvocation.MyCommand.Name)"
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
        if ($pscmdlet.ShouldProcess("article ID: $ID and related article ID $RelatedArticleID", 'Add TeamDynamix KnowledgeBase article relationship between'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/related/$RelatedArticleID" -ContentType $ContentType -Method Post -Headers $AuthenticationToken
            return $Return
        }
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
        if ($pscmdlet.ShouldProcess("article ID: $ID and related article ID $RelatedArticleID", 'Delete TeamDynamix KnowledgeBase article relationship between'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/$ID/related/$RelatedArticleID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
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
        if ($pscmdlet.ShouldProcess("category ID: $ID", 'Delete TeamDynamix KnowledgeBase article category'))
        {
            Write-ActivityHistory "Deleting TeamDynamix KnowledgeBase article category: $ID"
            $Return = Invoke-RESTCall -Uri "$BaseURI/knowledgebase/categories/$ID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
            return $Return
        }
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
}