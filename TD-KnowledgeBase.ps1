### KnowledgeBase

<#
.Synopsis
    Get a KnowledgeBase article in TeamDynamix
.DESCRIPTION
    Get a KnowledgeBase article in TeamDynamix. Specify the article ID number
    or search using the text of the article, the category ID, status,
    author ID, and whether or not the article is published or public.
.PARAMETER ID
    Article ID to retrieve from TeamDynamix.
.PARAMETER SearchText
    Text to search for in article.
.PARAMETER CategoryID
    Category ID number of articles to search for.
.PARAMETER Status
    Article status to retrieve.
.PARAMETER AuthorUID
    Articles written by specific author, specified by author's UID.
.PARAMETER IsPublished
    Retrieve only published or unpublished articles.
.PARAMETER IsPublic
    Retrieve only public or non-public articles.
.PARAMETER ReturnCount
    Maximum number of articles to return. Default 50.
.PARAMETER IncludeArticleBodies
    Set whether to include article bodies.
.PARAMETER IncludeShortcuts
    Set whether to include shortuts.
.PARAMETER CustomAttributes
    Retrieve articles with matching custom attributes.
.PARAMETER Related
    Set whether to include related articles.
.PARAMETER Detail
    Return full detail for article. Default searches return partial detail.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDKBArticle -AuthenticationToken $Authentication

    Retrieves all KB articles from TeamDynamix.
.EXAMPLE
    C:\>Get-TDKBArticle -ID 1752 -AuthenticationToken $Authentication

    Retrieves KB article number 1752 from TeamDynamix.
.EXAMPLE
    C:\>Get-TDKBArticle -SearchText vpn -AuthenticationToken $Authentication

    Retrieves first 50 KB articles containing the text "vpn" from TeamDynamix.
.EXAMPLE
    C:\>Get-TDKBArticle -SearchText vpn -IncludeArticleBodies -AuthenticationToken $Authentication

    Retrieves full detail of first 50 KB articles containing the text "vpn"
    from TeamDynamix.
.EXAMPLE
    C:\>Get-TDKBArticle -ID 1752 -Related -AuthenticationToken $Authentication

    Retrieves articles related to article number 1752 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Create a new KnowledgeBase article on TeamDynamix
.DESCRIPTION
    Create a new KnowledgeBase article on TeamDynamix. Accepts articles as
    objects on the pipeline.
.PARAMETER Subject
    The subject of the new KB article to create on TeamDynamix.
.PARAMETER Body
    The body of the new KB article to create on TeamDynamix.
.PARAMETER Status
    Article status to retrieve.
.PARAMETER Order
    The order of the service among its siblings (default 1.0).
.PARAMETER CategoryID
    Category ID number of articles to search for.
.PARAMETER Summary
    Summary of the new KB articles to create on TeamDynamix.
.PARAMETER ReviewDateUtc
    Review date of new KB article to create on TeamDynamix.
.PARAMETER IsPublished
    Determines whether the KB article is published on TeamDynamix.
.PARAMETER IsPublic
    Determines whether the KB article is public on TeamDynamix.
.PARAMETER WhitelistGroups
    Determines whether the KB article groups are whitelisted or blacklisted on
    TeamDynamix.
.PARAMETER InheritPermissions
    Determines whether the KB article inherits permissions from the parent
    category on TeamDynamix.
.PARAMETER NotifyOwner
    Determines whether the KB article on TeamDynamix should be notified of
    feedback.
.PARAMETER OwnerUID
    The KB article's owner UID in TeamDynamix. Only one of OwnerUID or
    OwningGroupID is allowed, but one or the other is required.
.PARAMETER OwningGroupID
    The KB article's owning group ID in TeamDynamix. Only one of OwnerUID or
    OwningGroupID is allowed, but one or the other is required.
.PARAMETER Tags
    Tags for the KB article on TeamDynamix to facilitate search.
.PARAMETER Attributes
    Custom attributes for the KB article.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDKBArticle -Subject Testing -Body 'This is a test' -Status 1 -OwningGroupID 755 -AuthenticationToken $Authentication

    Creates a new KnowledgeBase article.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Delete a KnowledgeBase article from TeamDynamix
.DESCRIPTION
    Delete a KnowledgeBase article from TeamDynamix using the article ID.
.PARAMETER ID
    ID number of the KB article to be deleted from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDKBArticle -ID 7 -AuthenticationToken $Authentication

    Deletes KnowledgeBase article with ID number 7 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Edit an existing KnowledgeBase article on TeamDynamix
.DESCRIPTION
    Updates an existing KnowledgeBase article on TeamDynamix. Accepts articles
    as objects on the pipeline.
    Note that permission inheritance, public status, and whitelist/blacklist
    options are ignored by the TeamDynamix API at this time.
.PARAMETER Subject
    The new subject of the KB article on TeamDynamix.
.PARAMETER Body
    The new body of the KB article on TeamDynamix.
.PARAMETER Status
    Article status to retrieve.
.PARAMETER Order
    The order of the service among its siblings (default 1.0).
.PARAMETER CategoryID
    The new category ID number of the KB article on TeamDynamix.
.PARAMETER Summary
    Summary of the new KB articles to create on TeamDynamix.
.PARAMETER ReviewDateUtc
    The new review date of the KB article on TeamDynamix.
.PARAMETER IsPublished
    Determines whether the KB article is published on TeamDynamix.
.PARAMETER IsPublic
    Determines whether the KB article is public on TeamDynamix. Ignored.
.PARAMETER WhitelistGroups
    Determines whether the KB article groups are whitelisted or blacklisted on TeamDynamix. Ignored.
.PARAMETER InheritPermissions
    Determines whether the KB article inherits permissions from the parent category on TeamDynamix. Ignored.
.PARAMETER NotifyOwner
    Determines whether the KB article on TeamDynamix should be notified of feedback.
.PARAMETER OwnerUID
    The KB article's owner UID in TeamDynamix. Only one of either OwnerUID or
    OwningGroupID is allowed.
.PARAMETER OwningGroupID
    The KB article's owning group ID in TeamDynamix. Only one of either
    OwnerUID or OwningGroupID is allowed.
.PARAMETER Tags
    Updated tags for the KB article on TeamDynamix to facilitate search.
.PARAMETER Attributes
    Custom attributes for the KB article.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDKBArticle 111 -Subject "This is a new subject" -AuthenticationToken $Authentication

    Changes the subject of KnowledgeBase article ID 111 to "This is a new
    subject."
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Add a file attachment to a KnowledgeBase article in TeamDynamix
.DESCRIPTION
    Add a file attachment to a KnowledgeBase article in TeamDynamix. Returns
    information regarding the attachment of the form
    TeamDynamix.Api.Attachments.Attachment.
.PARAMETER ID
    ID number of the KB article the attachment will be added to in TeamDynamix.
.PARAMETER FilePath
    The full path and filename of the file to be added as an attachment.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\> Add-TDKBAttachment -ID 111 -FilePath C:\temp\1.jpg -AuthenticationToken $Authentication

    Attaches the file c:\temp\1.jpg to KnowledgeBase article ID 111 in
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>function Add-TDKBAttachment
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

<#
.Synopsis
    Add a relationship between two KnowledgeBase articles from TeamDynamix
.DESCRIPTION
    Add a relationship between two KnowledgeBase articles from TeamDynamix
    using the article IDs.
.PARAMETER ID
    ID number of the KB article with the relationship to be added to
    TeamDynamix.
.PARAMETER RelatedArticleID
    ID number of the related KB article.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Add-TDKBArticleRelationship -ID 7 -RelatedArticleID 24 -AuthenticationToken $Authentication

    Adds a relationship between KnowledgeBase article with ID number 7 and
    article 24 in TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Delete a relationship between two KnowledgeBase articles from TeamDynamix
.DESCRIPTION
    Delete a relationship between two KnowledgeBase articles from TeamDynamix
    using the article IDs.
.PARAMETER ID
    ID number of the KB article with the relationship to be deleted from
    TeamDynamix.
.PARAMETER RelatedArticleID
    ID number of the related KB article.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDKBArticleRelationship -ID 7 -RelatedArticleID 24 -AuthenticationToken $Authentication

    Deletes the relationship that KnowledgeBase article with ID number 7 has
    with article 24 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Get a KnowledgeBase category in TeamDynamix
.DESCRIPTION
    Get a KnowledgeBase category in TeamDynamix.
.PARAMETER ID
    Category to retrieve from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDKBCategory -AuthenticationToken $Authentication

    Retrieves all KB article categories from TeamDynamix.
.EXAMPLE
    C:\>Get-TDKBCategory -ID 1752 -AuthenticationToken $Authentication

    Retrieves KB article category number 1752 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Create a new KnowledgeBase category on TeamDynamix
.DESCRIPTION
    Create a new KnowledgeBase category on TeamDynamix. Accepts categories as
    objects on the pipeline.
.PARAMETER ParentID
    The parent article ID of the new category to create on TeamDynamix.
.PARAMETER Order
    The order of the category among its siblings (default 1.0).
.PARAMETER Name
    The name of the new category to create on TeamDynamix.
.PARAMETER Description
    The description of the new category to create on TeamDynamix.
.PARAMETER IsPublic
    Indicates whether the category is public or private.
.PARAMETER WhitelistGroups
    Indicates whether groups assigned to the category are whitelisted or
    blacklisted from accessing the category in the Knowlege Base.
.PARAMETER InheritPermissions
    Indicates whether permissions for the category are inherited from the
    parent category.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>New-TDKBCategory -Order 1 -Name 'Test category' -AuthenticationToken $Authentication

    Creates a new KnowledgeBase article category.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Delete a Knowledge Base category from TeamDynamix
.DESCRIPTION
    Delete a Knowledge Base category from TeamDynamix using the category ID.
.PARAMETER ID
    ID number of the KB category to be deleted from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDKBCategory -ID 7 -AuthenticationToken $Authentication

    Deletes KnowledgeBase article category with ID number 7 from TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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

<#
.Synopsis
    Edit an existing Knowledge Base category on TeamDynamix
.DESCRIPTION
    Edit a Knowledge Base category on TeamDynamix. Accepts categories as
    objects on the pipeline.
.PARAMETER ParentID
    The parent article ID of the category to edit on TeamDynamix.
.PARAMETER Order
    The order of the category among its siblings (default 1.0).
.PARAMETER Name
    The name of the category to edit on TeamDynamix.
.PARAMETER Description
    The description of the category to edit on TeamDynamix.
.PARAMETER IsPublic
    Indicates whether the category is public or private.
.PARAMETER WhitelistGroups
    Indicates whether groups assigned to the category are whitelisted or
    blacklisted from accessing the category in the Knowlege Base.
.PARAMETER InheritPermissions
    Indicates whether permissions for the category are inherited from the
    parent category.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Set-TDKBCategory -ID 111 -Description "This is a new category" -AuthenticationToken $Authentication

    Changes the description of Knowledge Base article category ID 111 to "This
    is a new category."
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
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