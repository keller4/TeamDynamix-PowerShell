﻿param(
    # Authentication - either a path to XML credential file or a PSCredential object (obtained via Get-Credential)
    [Parameter(Mandatory=$false,
               Position=0)]
    $Credential,

    # Specify TeamDynamix environment during setup
    [Parameter(Mandatory=$false,
               Position=1)]
    [string]
    $WorkingEnvironment = 'Production',

    # Allow setup with no login
    [Parameter(Mandatory=$false,
               Position=2)]
    [switch]
    $NoLogin
)

# Operational note on maintaining help documentation
#  Requires PlatyPS module to update
#   Import-Module PlatyPS
#  Help files are stored as markdown files in .\Docs
#  When new modules are created or their help is updated in comment-based help, issue the following command
#   Update-MarkdownHelpModule -OutputFolder .\docs\
#  When new commands are added, issue the following command to create new MarkDown help files:
#   New-MarkdownHelp -Command "New-CommandName" -OutputFolder .\docs\
#  Issue the following commands to update XML help file
#   New-ExternalHelp -Path .\Docs -OutputPath .\en-US\ -Force

# Operational note on code signing
#  When code is modified, issue the following commands to update the code-signing:
<#
    $Certificate = (Get-ChildItem cert:\\CurrentUser\\My -codesign)
    Get-ChildItem *.ps* -Recurse | Set-AuthenticodeSignature -Certificate $Certificate -TimestampServer http://timestamp.comodoca.com?td=sha256
#>

Write-Progress -ID 100 -Activity 'Loading module' -Status 'Setting up environment' -PercentComplete 33

# Update/create configuration file
#  If Configuration.psd1 is present, extract its settings
#   If existing Configuration.psd1 file is the current version, take no action
#   Otherwise create a new, default Configuration.psd1 file and move old settings into it
#  If Configuration file is not present, create a new, default Configuration.psd1 file
. $PSScriptRoot\Configuration.ps1
$UpdatedConfiguration = Update-ConfigurationFile
if ($UpdatedConfiguration)
{
    Write-Host 'Configuration file updated. Check settings.'
}

# Import configuration and check validity
$TDConfig = Import-PowerShellDataFile $PSScriptRoot\Configuration.psd1
if (($TDConfig.UserRoles | Where-Object Default -eq $true).Name.Count -ne 1) {throw 'In Configuration.psd1, there must be one, and only one, default user role.'}
if ($TDConfig.MaxActivityHistoryDefault -lt 1) {throw 'In Configuration.psd1, MaxActivityHistoryDefault should be 1 or higher.'}
#  Test for blanks and nulls in required settings
$RequiredSettings = @(
    'LogFileDirDefault'
    'DefaultEmailDomain'
    'UsernameRegex'
    'DefaultAssetCIsApp'
    'DefaultTicketingApp'
    'DefaultPortalApp'
    'DefaultTDBaseURI'
    'DefaultTDPreviewBaseURI'
    )
foreach ($RequiredSetting in $RequiredSettings)
{
    if ([string]::IsNullOrEmpty($TDConfig.$RequiredSetting)) {throw "In Configuration.psd1, $RequiredSetting must not be blank or null."}
}

#region Reference and control variables
# Check to see if GUI is supported (currently only supported on Windows, and cross-platform support began with version 6)
if (($PSVersionTable.OS -like '*Windows*') -or ($PSVersionTable.PSVersion.Major -le 5))
{
    $script:ModuleGUI = $true
}
else
{
    $script:ModuleGUI = $false
}

# Hashtable of custom attributes by component ID - populate as requests are made, separate results from production, sandbox, and preview
$script:CustomAttributesCache = @{
    Production = @{}
    Sandbox    = @{}
    Preview    = @{}
}

# Last authentication date/time, update at login
[datetime]$script:LastAuthentication = 0

# Recent activity queue
$script:ActivityHistory = New-Object -TypeName System.Collections.Queue
$InformationPreference = 'Continue'

# Undocumented TeamDynamix time zone IDs
$script:TimeZoneIDReference = [ordered]@{
    1  = 'Alaska(GMT-09:00)'
    2  = 'Eastern Time - US and Canada(GMT-05:00)'
    3  = 'Hawaii(GMT-10:00)'
    4  = 'Central Time - US and Canada(GMT-06:00)'
    5  = 'Mountain Time - US and Canada(GMT-07:00)'
    6  = 'Pacific Time - US and Canada(GMT-08:00)'
    7  = 'GMT - Europe (GMT)'
    8  = 'Central European - Europe(GMT+01:00)'
    9  = 'Arabia Standard Time - Qatar(GMT+03:00)'
    10 = 'Arizona Time(GMT-07:00)'
    11 = 'Indiana East(GMT-05:00)'
    12 = 'Atlantic Time(GMT-04:00)'
    13 = 'Western Europe Time - London(GMT)'
    14 = 'Eastern Europe Time(GMT+02:00)'
    15 = 'Western Australia(GMT+08:00)'
    16 = 'Northern Territory(GMT+09:30)'
    17 = 'South Australia(GMT+09:30)'
    18 = 'New South Wales(GMT+10:00)'
    19 = 'Victoria(GMT+10:00)'
    20 = 'Queensland(GMT+10:00)'
    21 = 'ACT(GMT+10:00)'
    22 = 'Tasmania(GMT+10:00)'
    25 = 'Saskatchewan(GMT-06:00)'
    29 = 'Newfoundland(GMT-03:30)'
    43 = 'Gulf Standard Time(GMT+04:00)'
    44 = 'Pakistan Time(GMT+05:00)'
    62 = 'Afghanistan Time(GMT+04:30)'
}

# TeamDynamix API target
$script:DefaultTDSandboxTargetURI       = '/SBTDWebApi/api'
$script:DefaultTDTargetURI              = '/TDWebApi/api'
$script:DefaultTDPortalSandboxTargetURI = '/SBTDNext'
$script:DefaultTDPortalTargetURI        = '/TDNext'

# Activity reporting queue depth
$script:MaxActivityHistoryDefault = $TDConfig.MaxActivityHistoryDefault

# PowerShell and TeamDynamix standard parameters to be ignored (use carefully, parameters inside TD's API that match these names will never be updated)
$script:GlobalIgnoreParameters = @(
    'AuthenticationToken'
    'Environment'
    'Passthru'
    'Verbose'
    'Debug'
    'ErrorAction'
    'WarningAction'
    'InformationAction'
    'ErrorVariable'
    'WarningVariable'
    'InformationVariable'
    'OutVariable'
    'OutBuffer'
    'PipelineVariable'
    'WhatIf'
    'Confirm'
    )

# TeamDynamix login error text (must match what is returned by TD API when password fails)
$script:TDLoginFailureText = 'Invalid username/password for TeamDynamix.'

#  Used to locate the default Active Directory connector identified by $TDConfig.DefaultADConnectorFinder
$script:DefaultADConnectorFinder = '$TDConfig.DataConnectors | Where-Object {$_.Name -eq $TDConfig.DefaultADConnector -and $_.Application -eq "People" -and $_.IsActive -eq $true}'
#endregion

#region Enum specifications - may need to be updated for changes to TeamDynamix APIs
# TeamDynamix working environment choices
enum EnvironmentChoices {
    Production
    Sandbox
    Preview}

# License types, as described in TeamDynamix.Api.Roles.LicenseTypes[]
enum TeamDynamix_Api_Roles_LicenseTypes {
    None                        = 0
    Enterprise                  = 1
    ProjectManager              = 2
    Technician                  = 3
    TeamMember                  = 4
    StudentTechnician           = 5
    Client                      = 6
    ClientWithReporting         = 7
    ProjectManagerWithReporting = 8
    TechnicianWithReporting     = 9
    TeamMemberWithReporting     = 10
}

# Component IDs, as described in TeamDynamix.Api.CustomAttributes.CustomAttributeComponent[]
enum TeamDynamix_Api_CustomAttributes_CustomAttributeComponent {
    Project              = 1
    Issue                = 3
    FileCabinetFile      = 8
    Ticket               = 9
    Account              = 14
    KnowledgeBaseArticle = 26
    Asset                = 27
    Vendor               = 28
    Contract             = 29
    ProductModel         = 30
    Person               = 31
    Service              = 47
    ConfigurationItem    = 63
    Location             = 71
    Risk                 = 72
    LocationRoom         = 80
    ServiceOffering      = 87
}

# Ticket classification of tickets to find, as described in TeamDynamix.Api.Tickets.TicketClass[]
enum TeamDynamix_Api_Tickets_TicketClass {
    None           = 0
    Ticket         = 9
    Incident       = 32
    Problem        = 33
    Change         = 34
    Release        = 35
    TicketTemplate = 36
    ServiceRequest = 46
    MajorIncident  = 77
}

# User types, as described in TeamDynamix.Api.Users.UserType[]
enum TeamDynamix_Api_Users_UserType {
    None                = 0
    User                = 1
    Customer            = 2
    ResourcePlaceholder = 8
    ServiceAccount      = 9
}

# KnowledgeBase article status, as described in TeamDynamix.Api.KnowledgeBase.ArticleStatus[]
enum TeamDynamix_Api_KnowledgeBase_ArticleStatus {
    None         = 0
    NotSubmitted = 1
    Submitted    = 2
    Approved     = 3
    Rejected     = 4
    Archived     = 5
}

# KnowledgeBase article status, as described in TeamDynamix.Api.KnowledgeBase.DraftStatus[]
enum TeamDynamix_Api_KnowledgeBase_DraftStatus {
    Pending  = 1
    Rejected = 2
}

# Ticket status, as described in TeamDynamix.Api.Statuses.StatusClass[]
enum TeamDynamix_Api_Statuses_StatusClass {
    None      = 0
    New       = 1
    InProcess = 2
    Completed = 3
    Cancelled = 4
    OnHold    = 5
    Requested = 6
}

# Attachment types, as described in TeamDynamix.Api.Attachments.AttachmentType[]
enum TeamDynamix_Api_Attachments_AttachmentType {
    None              = 0
    Project           = 1
    Issue             = 3
    Announcement      = 7
    Ticket            = 9
    Forums            = 13
    Knowledgebase     = 26
    Asset             = 27
    Contract          = 29
    Service           = 47
    CalendarEvent     = 57
    Expense           = 62
    ConfigurationItem = 63
    Location          = 71
    Risk              = 72
    PortfolioIssue    = 83
    PortfolioRisk     = 84
}

# Feed item types, as described in TeamDynamix.Api.Feed.FeedItemType[]
enum TeamDynamix_Api_Feed_FeedItemType {
    None                 = 0
    Project              = 1
    ProjectRequest       = 1
    Task                 = 2
    Issue                = 3
    Link                 = 4
    Contact              = 6
    Announcement         = 7
    Ticket               = 9
    File                 = 15
    UserStatus           = 24
    TicketTask           = 25
    MaintenanceActivity  = 25
    KnowledgeBaseArticle = 26
    Asset                = 27
    Plan                 = 43
    Workspace            = 45
    Service              = 47
    CalendarEvent        = 57
    Expense              = 62
    ConfigurationItem    = 63
    Risk                 = 72
    PortfolioIssue       = 83
    PortfolioRisk        = 84
}

# Feed update types, as described in TeamDynamix.Api.Feed.UpdateType[]
enum TeamDynamix_Api_Feed_UpdateType {
    None         = 0
    Comment      = 1
    StatusChange = 2
    Edit         = 3
    Created      = 4
    MyWorkChange = 5
    Merge        = 6
    MovedComment = 7
}

# Bulk operations result types, as described in TeamDynamix.Api.BulkOperations.ItemResultType[]
enum TeamDynamix_Api_BulkOperations_ItemResultType {
    Skipped = 0
    Created = 1
    Updated = 2
}

# Types that a Configuration Item can describe, as described in TeamDynamix.Api.Cmdb.BackingItemType
enum TeamDynamix_Api_Cmdb_BackingItemType {
    ConfigurationItem = 63
    Asset             = 27
    Service           = 47
}

# Types of requests that can be made from a service, as described in TeamDynamix.Api.ServiceCatalog.RequestComponent
enum TeamDynamix_Api_ServiceCatalog_RequestComponent {
    None    = 0
    Project = 1
    Link    = 4
    Ticket  = 9
}

# Types of items that can be backended by ticket tasks
enum TeamDynamix_Api_Tickets_TicketTaskType {
    None                = 0
    TicketTask          = 1
    MaintenanceActivity = 2
    WorkflowTask        = 3
}

# Types of conflicts that can be detected for scheduled maintenance activity for a CI
enum TeamDynamix_Api_Tickets_ConflictType {
    None                          = 0
    OutsideMaintenanceWindow      = 1
    DuringBlackoutWindow          = 2
    ExistingActivity              = 4
    OutsideChildMaintenanceWindow = 8
    ExistingChildActivity         = 16
    ExistingParentActivity        = 32
}

# Indicates which types of unmet constraints to filter on for search
enum TeamDynamix_Api_Tickets_UnmetConstraintSearchType {
    None       = 0
    Response   = 1
    Resolution = 2
}

# Specifies the type of item with which a time or expense entry is associated
enum TeamDynamix_Api_Time_TimeEntryComponent {
    ProjectTime        = 1
    TaskTime           = 2
    IssueTime          = 3
    TicketTime         = 9
    TimeOff            = 17
    PortfolioTime      = 23
    TicketTaskTime     = 25
    WorkspaceTime      = 45
    PortfolioIssueTime = 83
}

# Specifies the approval status of a time/expense entry or report
enum TeamDynamix_Api_Time_TimeStatus {
    NoStatus  = 0
    Submitted = 1
    Rejected  = 2
    Approved  = 3
}

# A list of error codes to help the user understand item errors for time API operations
enum TeamDynamix_Api_Time_TimeApiErrorCode {
    Unknown                         = 0
    ServerError                     = 1
    InvalidTimeEntryID              = 10
    InvalidModuleType               = 11
    InvalidProjectID                = 12
    InvalidPlanID                   = 13
    InvalidItemID                   = 14
    InvalidAppID                    = 15
    UserNotFound                    = 20
    TimeEntryNotFound               = 21
    TimeAccountNotFound             = 22
    TaskNotFound                    = 23
    IssueNotFound                   = 24
    TicketNotFound                  = 25
    TicketTaskNotFound              = 26
    TicketConvertedToTask           = 27
    ProjectNotFound                 = 28
    UserDoesNotHaveApplication      = 30
    UserIsNotOnProject              = 31
    CannotAddTimeForOthers          = 32
    CannotViewTimeEntry             = 33
    UserInvalid                     = 34
    TimeReportAlreadyApproved       = 40
    TimeReportAlreadySubmitted      = 41
    TimeEntryOccursOnLockedDate     = 42
    TimeAccountLimitExceeded        = 43
    LimitedTimeCannotBeNegative     = 44
    CannotChangeProperty            = 50
    MaxOperationsPerRequestExceeded = 51
    NoOperationsSpecified           = 52
    ProjectNotActive                = 53
    ProjectTimeEntryNotAllowed      = 54
    LimitedTimeTypesUnavailable     = 55
    CannotDeleteTimeEntry           = 56
    InvalidTimeDate                 = 57
    InvalidTicketID                 = 58
    PortfolioNotFound               = 59
    PortfolioNotActive              = 60
}

# Different modes of editing resource allocations
enum TeamDynamix_Api_ResourceAllocationEditMode {
    AllowRequest    = 1
    AllowDirectEdit = 2
    DoNotAllowEdit  = 3
}

# Options for health of a project
enum TeamDynamix_Api_Projects_HealthChoice {
    None   = 0
    Green  = 1
    Yellow = 2
    Red    = 3
    OnHold = 4
}

# Types of relationships between tasks
enum TeamDynamix_Api_Plans_RelationshipType {
    EndToStart   = 0
    EndToEnd     = 1
    StartToEnd   = 2
    StartToStart = 3
}

# Ways in which a workflow progresses in response to actions taken
enum TeamDynamix_Api_WorkflowEngine_WorkflowAdvancement {
    None     = 0
    Approve  = 1
    Reject   = 2
    Complete = 3
    Neutral  = 4
    Skip     = 5}

# Statuses of a workflow
enum TeamDynamix_Api_WorkflowEngine_WorkflowStatus {
    None     = 0
    Approved = 1
    Rejected = 2}

# Describes the different date units that are used to calculate the end dates of contracts with sliding date models, as described in TeamDynamix.Api.Assets.SlidingContractDateUnit
enum TeamDynamix_Api_Assets_SlidingContractDateUnit {
    None  = 0
    Day   = 1
    Week  = 2
    Month = 3
    Year  = 4}

# Represents the different types of contracts that can be created, as described in TeamDynamix.Api.Assets.ContractType
enum TeamDynamix_Api_Assets_ContractType {
    None              = 0
    Warranty          = 1
    ServiceContract   = 2
    SupportContract   = 3
    UpgradeProtection = 4}

# Describes the different types of SLA deadline start basis options to be applied to a ticket, as described in TeamDynamix.Api.Tickets.SlaStartBasis
enum TeamDynamix_Api_Tickets_SlaStartBasis {
    CurrentDateTime        = 0
    TicketCreationDateTime = 1}
#endregion

#region Class definitions
#region TeamDynamix data classes
class TeamDynamix_Api_CustomAttributes_CustomAttributeChoice
{
    [int]     $ID
    [string]  $Name
    [boolean] $IsActive
    [datetime]$DateCreated
    [datetime]$DateModified
    [int]     $Order

    # Default constructor
    TeamDynamix_Api_CustomAttributes_CustomAttributeChoice ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_CustomAttributes_CustomAttributeChoice ([psobject]$Choice)
    {
        foreach ($Parameter in ([TeamDynamix_Api_CustomAttributes_CustomAttributeChoice]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Choice.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Choice.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_CustomAttributes_CustomAttributeChoice(
        [int]     $ID,
        [string]  $Name,
        [boolean] $IsActive,
        [datetime]$DateCreated,
        [datetime]$DateModified,
        [int]     $Order)
    {
        foreach ($Parameter in ([TeamDynamix_Api_CustomAttributes_CustomAttributeChoice]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_CustomAttributes_CustomAttributeChoice(
        [string]  $Name,
        [boolean] $IsActive,
        [int]     $Order)
    {
        $this.Name              = $Name
        $this.IsActive          = $IsActive
        $this.Order             = $Order
    }
}

class TeamDynamix_Api_CustomAttributes_CustomAttribute
{
    [int]    $ID
    [string] $Name
    [int]    $Order
    [string] $Description
    [int]    $SectionID
    [string] $SectionName
    [string] $FieldType
    [string] $DataType
    [TeamDynamix_Api_CustomAttributes_CustomAttributeChoice[]]$Choices
    [boolean]$IsRequired
    [boolean]$IsUpdatable
    [string] $Value
    [string] $ValueText
    [string] $ChoicesText
    [int[]]  $AssociatedItemIDs

    # Default constructor
    TeamDynamix_Api_CustomAttributes_CustomAttribute ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_CustomAttributes_CustomAttribute ([psobject]$CustomAttribute)
    {
        foreach ($Parameter in ([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CustomAttribute.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CustomAttribute.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_CustomAttributes_CustomAttribute(
        [int]    $ID,
        [string] $Name,
        [int]    $Order,
        [string] $Description,
        [int]    $SectionID,
        [string] $SectionName,
        [string] $FieldType,
        [string] $DataType,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeChoice[]]$Choices,
        [boolean]$IsRequired,
        [boolean]$IsUpdatable,
        [string] $Value,
        [string] $ValueText,
        [string] $ChoicesText,
        [int[]]  $AssociatedItemIDs)
    {
        foreach ($Parameter in ([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Methods
    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttribute(
        [int]               $ID,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$Component,
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.Get($ID,$Component,$AppID,$Environment)
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttribute(
        [string]            $Name,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$Component,
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.Get($Name,$Component,$AppID,$Environment)
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_CustomAttributes_CustomAttribute(
        [string] $Name,
        [int]    $Order,
        [string] $Description,
        [int]    $SectionID,
        [boolean]$IsRequired,
        [boolean]$IsUpdatable,
        [string] $Value,
        [int[]]  $AssociatedItemIDs)
    {
        $this.Name              = $Name
        $this.Order             = $Order
        $this.Description       = $Description
        $this.SectionID         = $SectionID
        $this.IsRequired        = $IsRequired
        $this.IsUpdatable       = $IsUpdatable
        $this.Value             = $Value
        $this.AssociatedItemIDs = $AssociatedItemIDs
    }

    TeamDynamix_Api_CustomAttributes_CustomAttribute(
        [string]            $AttributeName,
        [string]            $AttributeValue,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$Component,
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $Attribute = [TeamDynamix_Api_CustomAttributes_CustomAttribute]::GetCustomAttribute($AttributeName,$Component,$AppID,$TDAuthentication,$Environment)
        $this.ID   = $Attribute.ID
        $this.Name = $AttributeName
        # Assign value directly if there are no choices or the AttributeValue is blank
        if (($Attribute.Choices.Count -eq 0) -or [string]::IsNullOrEmpty($AttributeValue))
        {
            $this.Value = $AttributeValue
        }
        else
        {
            # Determine if AttributeValue is a single text item, or a list of integers
            #  Split AttributeValue at the comma (if present)
            #  Use TryParse method to determine if the first string is indeed an integer (only tests first entry, remainder are assumed to be the same)
            if ([int]::TryParse($AttributeValue.Split(',')[0],[ref]''))
            {
                # It's an integer, or list of integers. Either way, assign it directly.
                $this.Value = $AttributeValue
            }
            else
            {
                # Find choice by name
                #  Note that attribute value may be a comma-separated list of names (used for multi-select or checkbox types), or just a single name
                #  Split out names of attribute values if there's more than one
                #  Trim the name(s) of whitespace
                #  Look for attribute choices whose name(s) appear in attribute value(s)
                #  Extract ID(s)
                #  If more than one ID, join the IDs with a comma
                $this.Value = ($Attribute.Choices | Where-Object Name -in $AttributeValue.Split(',').Trim()).ID -join ','
            }
        }
    }

    TeamDynamix_Api_CustomAttributes_CustomAttribute(
        [int] $AttributeID,
        [int] $ValueID)
    {
        $this.ID    = $AttributeID
        $this.Value = $ValueID
    }
}

class TeamDynamix_Api_Roles_SecurityRole
{
    [guid]    $ID
    [string]  $Name
    [datetime]$CreatedDate
    [datetime]$ModifiedDate
    [int]     $UserCount
    [int]     $AppID
    [string[]]$Permissions
    [int]     $LicenseType
    [string]  $LicenseTypeName

    # Default constructor
    TeamDynamix_Api_Roles_SecurityRole ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_SecurityRole ([psobject]$SecurityRole)
    {
        $this.ID           = $SecurityRole.ID
        $this.Name         = $SecurityRole.Name
        $this.CreatedDate  = $SecurityRole.CreatedDate  | Get-Date
        $this.ModifiedDate = $SecurityRole.ModifiedDate | Get-Date
        $this.UserCount    = $SecurityRole.UserCount
        $this.AppID        = $SecurityRole.AppID
        $this.Permissions  = $SecurityRole.Permissions
        $this.LicenseType  = [TeamDynamix_Api_Roles_LicenseTypes]$SecurityRole.LicenseType
        if ($SecurityRole.LicenseTypeName)
        {
            $this.LicenseTypeName = $SecurityRole.LicenseTypeName
        }
        else
        {
            $this.LicenseTypeName = [TeamDynamix_Api_Roles_LicenseTypes]$SecurityRole.LicenseType
        }
    }

    # Full constructor
    TeamDynamix_Api_Roles_SecurityRole (
        [guid]    $ID,
        [string]  $Name,
        [datetime]$CreatedDate,
        [datetime]$ModifiedDate,
        [int]     $UserCount,
        [int]     $AppID,
        [string[]]$Permissions,
        [int]     $LicenseType,
        [string]$LicenseTypeName)
    {
        $this.ID           = $ID
        $this.Name         = $Name
        $this.CreatedDate  = $CreatedDate  | Get-Date
        $this.ModifiedDate = $ModifiedDate | Get-Date
        $this.UserCount    = $UserCount
        $this.AppID        = $AppID
        $this.Permissions  = $Permissions
        $this.LicenseType  = [TeamDynamix_Api_Roles_LicenseTypes]$LicenseType
        if ([string]::IsNullOrEmpty($LicenseTypeName))
        {
            $this.LicenseTypeName = [TeamDynamix_Api_Roles_LicenseTypes]$LicenseType
        }
        else
        {
            $this.LicenseTypeName = $LicenseTypeName
        }
    }

    # Constructor for editable parameters
    TeamDynamix_Api_Roles_SecurityRole(
        [string]  $Name,
        [string[]]$Permissions,
        [int]     $LicenseType)
    {
        $this.Name        = $Name
        $this.Permissions = $Permissions
        $this.LicenseType = [TeamDynamix_Api_Roles_LicenseTypes]$LicenseType
    }

    # Convenience constructor for required parameters
    TeamDynamix_Api_Roles_SecurityRole(
        [string]$Name,
        [int]   $LicenseType)
    {
        $this.Name        = $Name
        $this.LicenseType = [TeamDynamix_Api_Roles_LicenseTypes]$LicenseType
    }
}

class TeamDynamix_Api_Roles_SecurityRoleSearch
{
    [string]              $NameLike
    [int]                 $AppID
    [System.Nullable[int]]$LicenseTypeID

    # Default constructor
    TeamDynamix_Api_Roles_SecurityRoleSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_SecurityRoleSearch ([psobject]$SecurityRoleSearch)
    {
        $this.NameLike      = $SecurityRoleSearch.NameLike
        $this.AppID         = $SecurityRoleSearch.AppID
        $this.LicenseTypeID = $SecurityRoleSearch.LicenseTypeID
    }

    # Full constructor
    TeamDynamix_Api_Roles_SecurityRoleSearch(
        [string]              $NameLike,
        [int]                 $AppID,
        [System.Nullable[int]]$LicenseTypeID)
    {
        $this.NameLike      = $NameLike
        $this.AppID         = $AppID
        $this.LicenseTypeID = $LicenseTypeID
    }
}

class TeamDynamix_Api_Roles_Permission
{
    [string]$ID
    [string]$Name
    [string]$Description
    [int]   $SectionID
    [string]$SectionName

    # Default constructor
    TeamDynamix_Api_Roles_Permission ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_Permission ([psobject]$SecurityRolePermission)
    {
        $this.ID          = $SecurityRolePermission.ID
        $this.Name        = $SecurityRolePermission.Name
        $this.Description = $SecurityRolePermission.Description
        $this.SectionID   = $SecurityRolePermission.SectionID
        $this.SectionName = $SecurityRolePermission.SectionName
    }

    # Full constructor
    TeamDynamix_Api_Roles_Permission(
        [string]$ID,
        [string]$Name,
        [string]$Description,
        [int]   $SectionID,
        [string]$SectionName)
    {
        $this.ID          = $ID
        $this.Name        = $Name
        $this.Description = $Description
        $this.SectionID   = $SectionID
        $this.SectionName = $SectionName
    }
}

class TeamDynamix_Api_Roles_FunctionalRole
{
    [string]  $ID
    [string]  $Name
    [double]  $StandardRate
    [double]  $CostRate
    [datetime]$CreatedDate
    [datetime]$ModifiedDate
    [string]  $Comments
    [int]     $UsersCount
    [int]     $RequestsCount
    [int]     $ProjectsCount
    [int]     $OpportunitiesCount
    [int]     $ResourceRequestsCount

    # Default constructor
    TeamDynamix_Api_Roles_FunctionalRole ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_FunctionalRole ([psobject]$FunctionalRole)
    {
        $this.ID                    = $FunctionalRole.ID
        $this.Name                  = $FunctionalRole.Name
        $this.StandardRate          = $FunctionalRole.StandardRate
        $this.CostRate              = $FunctionalRole.CostRate
        $this.CreatedDate           = $FunctionalRole.CreatedDate  | Get-Date
        if ($FunctionalRole.ModifiedDate)
        {
            $this.ModifiedDate      = $FunctionalRole.ModifiedDate | Get-Date
        }
        $this.Comments              = $FunctionalRole.Comments
        $this.UsersCount            = $FunctionalRole.UsersCount
        $this.RequestsCount         = $FunctionalRole.RequestsCount
        $this.ProjectsCount         = $FunctionalRole.ProjectsCount
        $this.OpportunitiesCount    = $FunctionalRole.OpportunitiesCount
        $this.ResourceRequestsCount = $FunctionalRole.ResourceRequestsCount
    }

    # Full constructor
    TeamDynamix_Api_Roles_FunctionalRole(
        [string]  $ID,
        [string]  $Name,
        [double]  $StandardRate,
        [double]  $CostRate,
        [datetime]$CreatedDate,
        [datetime]$ModifiedDate,
        [string]  $Comments,
        [int]     $UsersCount,
        [int]     $RequestsCount,
        [int]     $ProjectsCount,
        [int]     $OpportunitiesCount,
        [int]     $ResourceRequestsCount)
    {
        $this.ID                    = $ID
        $this.Name                  = $Name
        $this.StandardRate          = $StandardRate
        $this.CostRate              = $CostRate
        $this.CreatedDate           = $CreatedDate  | Get-Date
        $this.ModifiedDate          = $ModifiedDate | Get-Date
        $this.Comments              = $Comments
        $this.UsersCount            = $UsersCount
        $this.RequestsCount         = $RequestsCount
        $this.ProjectsCount         = $ProjectsCount
        $this.OpportunitiesCount    = $OpportunitiesCount
        $this.ResourceRequestsCount = $ResourceRequestsCount
    }

    # Constructor for editable parameters
    TeamDynamix_Api_Roles_FunctionalRole(
        [string]$Name,
        [double]$StandardRate,
        [double]$CostRate,
        [string]$Comments)
    {
        $this.Name         = $Name
        $this.StandardRate = $StandardRate
        $this.CostRate     = $CostRate
        $this.Comments     = $Comments
    }
}

class TeamDynamix_Api_Roles_FunctionalRoleSearch
{
    [string] $Name
    [int]    $MaxResults
    [boolean]$ReturnItemCounts

    # Default constructor
    TeamDynamix_Api_Roles_FunctionalRoleSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_FunctionalRoleSearch ([psobject]$FunctionalRoleSearch)
    {
        $this.Name             = $FunctionalRoleSearch.Name
        $this.MaxResults       = $FunctionalRoleSearch.MaxResults
        $this.ReturnItemCounts = $FunctionalRoleSearch.ReturnItemCounts
    }

    # Full constructor
    TeamDynamix_Api_Roles_FunctionalRoleSearch(
        [string] $Name,
        [int]    $MaxResults,
        [boolean]$ReturnItemCounts)
    {
        $this.Name             = $Name
        $this.MaxResults       = $MaxResults
        $this.ReturnItemCounts = $ReturnItemCounts
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Roles_FunctionalRoleSearch(
        [string] $Name)
    {
        $this.Name             = $Name
        $this.MaxResults       = 0
        $this.ReturnItemCounts = $false
    }
}

class TeamDynamix_Api_Roles_UserFunctionalRole
{
    [int]     $ID
    [int]     $FunctionalRoleID
    [guid]    $UID
    [string]  $FunctionalRoleName
    [double]  $StandardRate
    [double]  $CostRate
    [datetime]$CreatedDate
    [string]  $Comments
    [boolean] $IsPrimary

    # Default constructor
    TeamDynamix_Api_Roles_UserFunctionalRole ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Roles_UserFunctionalRole ([psobject]$UserFunctionalRole)
    {
        $this.ID                 = $UserFunctionalRole.ID
        $this.FunctionalRoleID   = $UserFunctionalRole.FunctionalRoleID
        $this.UID                = $UserFunctionalRole.UID
        $this.FunctionalRoleName = $UserFunctionalRole.FunctionalRoleName
        $this.StandardRate       = $UserFunctionalRole.StandardRate
        $this.CostRate           = $UserFunctionalRole.CostRate
        $this.CreatedDate        = $UserFunctionalRole.CreatedDate | Get-Date
        $this.Comments           = $UserFunctionalRole.Comments
        $this.IsPrimary          = $UserFunctionalRole.IsPrimary
    }

    # Full constructor
    TeamDynamix_Api_Roles_UserFunctionalRole(
        [int]     $ID,
        [int]     $FunctionalRoleID,
        [guid]    $UID,
        [string]  $FunctionalRoleName,
        [double]  $StandardRate,
        [double]  $CostRate,
        [datetime]$CreatedDate,
        [string]  $Comments,
        [boolean] $IsPrimary)
    {
        $this.ID                 = $ID
        $this.FunctionalRoleID   = $FunctionalRoleID
        $this.UID                = $UID
        $this.FunctionalRoleName = $FunctionalRoleName
        $this.StandardRate       = $StandardRate
        $this.CostRate           = $CostRate
        $this.CreatedDate        = $CreatedDate | Get-Date
        $this.Comments           = $Comments
        $this.IsPrimary          = $IsPrimary
    }
}

class TeamDynamix_Api_Assets_AssetStatus
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [string]  $Name
    [string]  $Description
    [double]  $Order
    [boolean] $IsActive
    [boolean] $IsOutOfService
    [datetime]$CreatedDate
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Assets_AssetStatus ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_AssetStatus ([psobject]$AssetStatus)
    {
        $this.ID               = $AssetStatus.ID
        $this.AppID            = $AssetStatus.AppID
        $this.AppName          = $AssetStatus.AppName
        $this.Name             = $AssetStatus.Name
        $this.Description      = $AssetStatus.Description
        $this.Order            = $AssetStatus.Order
        $this.IsActive         = $AssetStatus.IsActive
        $this.IsOutOfService   = $AssetStatus.IsOutOfService
        $this.CreatedDate      = $AssetStatus.CreatedDate  | Get-Date
        $this.CreatedUID       = $AssetStatus.CreatedUID
        $this.CreatedFullName  = $AssetStatus.CreatedFullName
        $this.ModifiedDate     = $AssetStatus.ModifiedDate | Get-Date
        $this.ModifiedUID      = $AssetStatus.ModifiedUID
        $this.ModifiedFullName = $AssetStatus.ModifiedFullName
    }

    # Full constructor
    TeamDynamix_Api_Assets_AssetStatus(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [string]  $Name,
        [string]  $Description,
        [double]  $Order,
        [boolean] $IsActive,
        [boolean] $IsOutOfService,
        [datetime]$CreatedDate,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName)
    {
        $this.ID               = $ID
        $this.AppID            = $AppID
        $this.AppName          = $AppName
        $this.Name             = $Name
        $this.Description      = $Description
        $this.Order            = $Order
        $this.IsActive         = $IsActive
        $this.IsOutOfService   = $IsOutOfService
        $this.CreatedDate      = $CreatedDate  | Get-Date
        $this.CreatedUID       = $CreatedUID
        $this.CreatedFullName  = $CreatedFullName
        $this.ModifiedDate     = $ModifiedDate | Get-Date
        $this.ModifiedUID      = $ModifiedUID
        $this.ModifiedFullName = $ModifiedFullName
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_AssetStatus(
        [string]  $Name,
        [string]  $Description,
        [double]  $Order,
        [boolean] $IsActive,
        [boolean] $IsOutOfService)
    {
        $this.Name             = $Name
        $this.Description      = $Description
        $this.Order            = $Order
        $this.IsActive         = $IsActive
        $this.IsOutOfService   = $IsOutOfService
    }

    # Methods
    Static [psobject[]] GetAssetStatus (
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return ($script:TDAssetStatuses.GetAll($Environment))
    }
}

class TeamDynamix_Api_Assets_AssetStatusSearch
{
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[boolean]]$IsOutOfService
    [string]                  $SearchText

    # Default constructor
    TeamDynamix_Api_Assets_AssetStatusSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_AssetStatusSearch ([psobject]$AssetStatusSearch)
    {
        $this.IsActive       = $AssetStatusSearch.IsActive
        $this.IsOutOfService = $AssetStatusSearch.IsOutOfService
        $this.SearchText     = $AssetStatusSearch.SearchText
    }

    # Full constructor
    TeamDynamix_Api_Assets_AssetStatusSearch(
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[boolean]]$IsOutOfService,
        [string]                  $SearchText)
    {
        $this.IsActive       = $IsActive
        $this.IsOutOfService = $IsOutOfService
        $this.SearchText     = $SearchText
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Assets_AssetStatusSearch(
        [string]$SearchText)
    {
        $this.IsActive       = $null
        $this.IsOutOfService = $null
        $this.SearchText     = $SearchText
    }
}

class TeamDynamix_Api_Cmdb_MaintenanceSchedule
{
    [int]     $ID
    [string]  $Name
    [string]  $Description
    [int]     $TimeZoneID
    [string]  $TimeZoneName
    [boolean] $IsActive
    [datetime]$CreatedDateUTC
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDateUTC
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Cmdb_MaintenanceSchedule ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_MaintenanceSchedule ([psobject]$MaintenanceSchedule)
    {
        $this.ID               = $MaintenanceSchedule.ID
        $this.Name             = $MaintenanceSchedule.Name
        $this.Description      = $MaintenanceSchedule.Description
        $this.TimeZoneID       = $MaintenanceSchedule.TimeZoneID
        $this.TimeZoneName     = $MaintenanceSchedule.TimeZoneName
        $this.IsActive         = $MaintenanceSchedule.IsActive
        $this.CreatedDateUTC   = $MaintenanceSchedule.CreatedDateUTC  | Get-Date
        $this.CreatedUID       = $MaintenanceSchedule.CreatedUID
        $this.CreatedFullName  = $MaintenanceSchedule.CreatedFullName
        $this.ModifiedDateUTC  = $MaintenanceSchedule.ModifiedDateUTC | Get-Date
        $this.ModifiedUID      = $MaintenanceSchedule.ModifiedUID
        $this.ModifiedFullName = $MaintenanceSchedule.ModifiedFullName
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_MaintenanceSchedule(
        [int]     $ID,
        [string]  $Name,
        [string]  $Description,
        [int]     $TimeZoneID,
        [string]  $TimeZoneName,
        [boolean] $IsActive,
        [datetime]$CreatedDateUTC,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDateUTC,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName)
    {
        $this.ID               = $ID
        $this.Name             = $Name
        $this.Description      = $Description
        $this.TimeZoneID       = $TimeZoneID
        $this.TimeZoneName     = $TimeZoneName
        $this.IsActive         = $IsActive
        $this.CreatedDateUTC   = $CreatedDateUTC  | Get-Date
        $this.CreatedUID       = $CreatedUID
        $this.CreatedFullName  = $CreatedFullName
        $this.ModifiedDateUTC  = $ModifiedDateUTC | Get-Date
        $this.ModifiedUID      = $ModifiedUID
        $this.ModifiedFullName = $ModifiedFullName
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Cmdb_MaintenanceSchedule(
        [string]  $Name,
        [string]  $Description,
        [int]     $TimeZoneID,
        [boolean] $IsActive)
    {
        $this.Name        = $Name
        $this.Description = $Description
        $this.TimeZoneID  = $TimeZoneID
        $this.IsActive    = $IsActive
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Cmdb_MaintenanceSchedule(
        [string]  $Name,
        [string]  $Description,
        [boolean] $IsActive)
    {
        $this.Name        = $Name
        $this.Description = $Description
        $this.IsActive    = $IsActive
    }

    # Methods
    Static [TeamDynamix_Api_Cmdb_MaintenanceSchedule[]] GetMaintenanceSchedule (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDMaintenanceWindow -AuthenticationToken $TDAuthentication -Environment $Environment)
    }
}

class TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch
{
    [System.Nullable[boolean]]$IsActive
    [string]                  $NameLike

    # Default constructor
    TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch ([psobject]$MaintenanceScheduleSearch)
    {
        $this.IsActive = $MaintenanceScheduleSearch.IsActive
        $this.NameLike = $MaintenanceScheduleSearch.NameLike
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch(
        [System.Nullable[boolean]]$IsActive,
        [string]                  $NameLike)
    {
        $this.IsActive = $IsActive
        $this.NameLike = $NameLike
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch(
        [string]$NameLike)
    {
        $this.IsActive = $null
        $this.NameLike = $NameLike
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Cmdb_MaintenanceScheduleSearch(
        [System.Nullable[boolean]]$IsActive)
    {
        $this.IsActive = $IsActive
        $this.NameLike = $null
    }
}

class TeamDynamix_Api_Assets_Asset
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $FormID
    [string]  $FormName
    [int]     $ProductModelID
    [string]  $ProductModelName
    [int]     $ManufacturerID
    [string]  $ManufacturerName
    [int]     $SupplierID
    [string]  $SupplierName
    [int]     $StatusID
    [string]  $StatusName
    [int]     $LocationID
    [string]  $LocationName
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [string]  $Tag
    [string]  $SerialNumber
    [string]  $Name
    [double]  $PurchaseCost
    [datetime]$AcquisitionDate
    [datetime]$ExpectedReplacementDate
    [guid]    $RequestingCustomerID
    [string]  $RequestingCustomerName
    [int]     $RequestingDepartmentID
    [string]  $RequestingDepartmentName
    [guid]    $OwningCustomerID
    [string]  $OwningCustomerName
    [int]     $OwningDepartmentID
    [string]  $OwningDepartmentName
    [int]     $ParentID
    [string]  $ParentSerialNumber
    [string]  $ParentName
    [string]  $ParentTag
    [int]     $MaintenanceScheduleID
    [string]  $MaintenanceScheduleName
    [int]     $ConfigurationItemID
    [datetime]$CreatedDate
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName
    [string]  $ExternalID
    [int]     $ExternalSourceID
    [string]  $ExternalSourceName
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Attachments_Attachment[]]          $Attachments
    [string]  $URI

    # Default constructor
    TeamDynamix_Api_Assets_Asset ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_Asset ([psobject]$Asset)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Asset]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Asset.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Asset.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_Asset(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $FormID,
        [string]  $FormName,
        [int]     $ProductModelID,
        [string]  $ProductModelName,
        [int]     $ManufacturerID,
        [string]  $ManufacturerName,
        [int]     $SupplierID,
        [string]  $SupplierName,
        [int]     $StatusID,
        [string]  $StatusName,
        [int]     $LocationID,
        [string]  $LocationName,
        [int]     $LocationRoomID,
        [string]  $LocationRoomName,
        [string]  $Tag,
        [string]  $SerialNumber,
        [string]  $Name,
        [double]  $PurchaseCost,
        [datetime]$AcquisitionDate,
        [datetime]$ExpectedReplacementDate,
        [guid]    $RequestingCustomerID,
        [string]  $RequestingCustomerName,
        [int]     $RequestingDepartmentID,
        [string]  $RequestingDepartmentName,
        [guid]    $OwningCustomerID,
        [string]  $OwningCustomerName,
        [int]     $OwningDepartmentID,
        [string]  $OwningDepartmentName,
        [int]     $ParentID,
        [string]  $ParentSerialNumber,
        [string]  $ParentName,
        [string]  $ParentTag,
        [int]     $MaintenanceScheduleID,
        [string]  $MaintenanceScheduleName,
        [int]     $ConfigurationItemID,
        [datetime]$CreatedDate,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName,
        [string]  $ExternalID,
        [int]     $ExternalSourceID,
        [string]  $ExternalSourceName,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [TeamDynamix_Api_Attachments_Attachment[]]          $Attachments,
        [string]  $URI)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Asset]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_Asset(
        [int]     $FormID,
        [int]     $ProductModelID,
        [int]     $SupplierID,
        [int]     $StatusID,
        [int]     $LocationID,
        [int]     $LocationRoomID,
        [string]  $Tag,
        [string]  $SerialNumber,
        [string]  $Name,
        [double]  $PurchaseCost,
        [datetime]$AcquisitionDate,
        [datetime]$ExpectedReplacementDate,
        [guid]    $RequestingCustomerID,
        [guid]    $RequestingDepartmentID,
        [guid]    $OwningCustomerID,
        [int]     $OwningDepartmentID,
        [int]     $MaintenanceScheduleID,
        [string]  $ExternalID,
        [int]     $ExternalSourceID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        $this.FormID                  = $FormID
        $this.ProductModelID          = $ProductModelID
        $this.SupplierID              = $SupplierID
        $this.StatusID                = $StatusID
        $this.LocationID              = $LocationID
        $this.LocationRoomID          = $LocationRoomID
        $this.Tag                     = $Tag
        $this.SerialNumber            = $SerialNumber
        $this.Name                    = $Name
        $this.PurchaseCost            = $PurchaseCost
        $this.AcquisitionDate         = $AcquisitionDate         | Get-Date
        $this.ExpectedReplacementDate = $ExpectedReplacementDate | Get-Date
        $this.RequestingCustomerID    = $RequestingCustomerID
        $this.RequestingDepartmentID  = $RequestingDepartmentID
        $this.OwningCustomerID        = $OwningCustomerID
        $this.OwningDepartmentID      = $OwningDepartmentID
        $this.MaintenanceScheduleID   = $MaintenanceScheduleID
        $this.ExternalID              = $ExternalID
        $this.ExternalSourceID        = $ExternalSourceID
        $this.Attributes              = $Attributes
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }

    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Asset',$AppID,$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$AppID,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    [void] SetAppID (
        [string]   $AppName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AppID = ($script:TDApplications.Get($AppName,$Environment)).AppID
    }

    [void] SetStatusID (
        [string]   $StatusName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.StatusID = ([TeamDynamix_Api_Assets_AssetStatus]::GetAssetStatus($TDAuthentication,$Environment) | Where-Object Name -eq $StatusName).ID
    }

    [void] SetLocationID (
        [string]   $LocationName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.LocationID = ([TeamDynamix_Api_Locations_Location]::GetLocation($LocationName,$TDAuthentication,$Environment) | Where-Object Name -eq $LocationName).ID
    }

    [void] SetLocationRoomID (
        [string]   $RoomName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.LocationRoomID = ([TeamDynamix_Api_Locations_LocationRoom]::GetRoom($($this.LocationID),$RoomName,$TDAuthentication,$Environment) | Where-Object Name -eq $RoomName).ID
    }

    [void] SetLocationRoomID (
        [string]   $RoomName,
        [string]   $LocationName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $BuildingID          = ([TeamDynamix_Api_Locations_Location]::GetLocation($LocationName,$TDAuthentication,$Environment)         | Where-Object Name -eq $LocationName).ID
        $this.LocationRoomID = ([TeamDynamix_Api_Locations_LocationRoom]::GetRoom($BuildingID,$RoomName,$TDAuthentication,$Environment) | Where-Object Name -eq $RoomName    ).ID
    }

    [void] SetFormID (
        [string]   $FormName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.FormID = ([TeamDynamix_Api_Forms_Form]::GetForm($TDAuthentication,$Environment) | Where-Object Name -eq $FormName).ID
    }

    [void] SetMaintenanceScheduleID (
        [string]   $MaintenanceScheduleName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.MaintenanceScheduleID = ([TeamDynamix_Api_Cmdb_MaintenanceSchedule]::GetMaintenanceSchedule($TDAuthentication,$Environment) | Where-Object Name -eq $MaintenanceScheduleName).ID
    }

    [void] SetManufacturerID (
        [string]   $ManufacturerName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.ManufacturerID = ([TeamDynamix_Api_Assets_Vendor]::GetVendor($TDAuthentication,$Environment) | Where-Object Name -eq $ManufacturerName).ID
    }

    [void] SetOwningCustomerID (
        [string]   $UserName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.OwningCustomerID = ([TeamDynamix_Api_Users_User]::GetUser($UserName,$TDAuthentication,$Environment)).UID
    }

    [void] SetOwningDepartmentID (
        [string]   $DepartmentName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.OwningDepartmentID = ([TeamDynamix_Api_Accounts_Account]::GetDepartment($TDAuthentication,$Environment) | Where-Object Name -eq $DepartmentName).ID
    }

    [void] SetRequestingCustomerID (
        [string]   $UserName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.RequestingCustomerID = ([TeamDynamix_Api_Users_User]::GetUser($UserName,$TDAuthentication,$Environment)).UID
    }

    [void] SetRequestingDepartmentID (
        [string]   $DepartmentName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.RequestingDepartmentID = ([TeamDynamix_Api_Accounts_Account]::GetDepartment($TDAuthentication,$Environment) | Where-Object Name -eq $DepartmentName).ID
    }

    [void] SetProductModelID (
        [string]   $ProductModelName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.ProductModelID = ([TeamDynamix_Api_Assets_ProductModel]::GetProductModel($TDAuthentication,$Environment) | Where-Object Name -eq $ProductModelName).ID
    }

    [void] SetSupplierID (
        [string]   $SupplierName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.SupplierID = ([TeamDynamix_Api_Assets_Vendor]::GetVendor($TDAuthentication,$Environment) | Where-Object Name -eq $SupplierName).ID
    }

    [void] SetExternalSourceID (
        [string]   $ExternalSourceName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        # No external CMDB source to match up to, set to zero
        $this.ExternalSourceID = 0
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Asset',$AppID,$Environment)
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Assets_Asset
{
    [int]   $ID
    [int]   $AppID
    [string]$AppName
    [int]   $FormID
    [string]$FormName
    [int]   $ProductModelID
    [string]$ProductModelName
    [int]   $ManufacturerID
    [string]$ManufacturerName
    [int]   $SupplierID
    [string]$SupplierName
    [int]   $StatusID
    [string]$StatusName
    [int]   $LocationID
    [string]$LocationName
    [int]   $LocationRoomID
    [string]$LocationRoomName
    [string]$Tag
    [string]$SerialNumber
    [string]$Name
    [double]$PurchaseCost
    [string]$AcquisitionDate
    [string]$ExpectedReplacementDate
    [guid]  $RequestingCustomerID
    [string]$RequestingCustomerName
    [int]   $RequestingDepartmentID
    [string]$RequestingDepartmentName
    [guid]  $OwningCustomerID
    [string]$OwningCustomerName
    [int]   $OwningDepartmentID
    [string]$OwningDepartmentName
    [int]   $ParentID
    [string]$ParentSerialNumber
    [string]$ParentName
    [string]$ParentTag
    [int]   $MaintenanceScheduleID
    [string]$MaintenanceScheduleName
    [int]   $ConfigurationItemID
    [string]$CreatedDate
    [guid]  $CreatedUID
    [string]$CreatedFullName
    [string]$ModifiedDate
    [guid]  $ModifiedUID
    [string]$ModifiedFullName
    [string]$ExternalID
    [int]   $ExternalSourceID
    [string]$ExternalSourceName
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Attachments_Attachment[]]          $Attachments
    [string]  $URI

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Assets_Asset ([psobject]$Asset)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Asset]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Asset.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Asset.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Asset.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Assets_AssetSearch
{
    [string]                  $SerialLike
    [string]                  $SearchText
    [int]                     $SavedSearchID
    [int[]]                   $StatusIDs
    [string[]]                $ExternalIDs
    [System.Nullable[boolean]]$IsInService
    [int[]]                   $StatusIDsPast
    [int[]]                   $SupplierIDs
    [int[]]                   $ManufacturerIDs
    [int[]]                   $LocationIDs
    [int]                     $RoomID
    [int[]]                   $ParentIDs
    [int[]]                   $ContractIDs
    [int[]]                   $ExcludeContractIDs
    [int[]]                   $TicketIDs
    [int[]]                   $FormIDs
    [int[]]                   $ExcludeTicketIDs
    [int[]]                   $ProductModelIDs
    [int[]]                   $MaintenanceScheduleIDs
    [int[]]                   $UsingDepartmentIDs
    [int[]]                   $RequestingDepartmentIDs
    [int[]]                   $OwningDepartmentIDs
    [int[]]                   $OwningDepartmentIDsPast
    [guid[]]                  $UsingCustomerIDs
    [guid[]]                  $RequestingCustomerIDs
    [guid[]]                  $OwningCustomerIDs
    [guid[]]                  $OwningCustomerIDsPast
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [double]                  $PurchaseCostFrom
    [double]                  $PurchaseCostTo
    [int]                     $ContractProviderID
    [datetime]                $AcquisitionDateFrom
    [datetime]                $AcquisitionDateTo
    [datetime]                $ExpectedReplacementDateFrom
    [datetime]                $ExpectedReplacementDateTo
    [datetime]                $ContractEndDateFrom
    [datetime]                $ContractEndDateTo
    [boolean]                 $OnlyParentAssets
    [System.Nullable[int]]    $MaxResults

    # Default constructor
    TeamDynamix_Api_Assets_AssetSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_AssetSearch ([psobject]$AssetSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_AssetSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $AssetSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $AssetSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_AssetSearch(
        [string]                  $SerialLike,
        [string]                  $SearchText,
        [int]                     $SavedSearchID,
        [int[]]                   $StatusIDs,
        [string[]]                $ExternalIDs,
        [System.Nullable[boolean]]$IsInService,
        [int[]]                   $StatusIDsPast,
        [int[]]                   $SupplierIDs,
        [int[]]                   $ManufacturerIDs,
        [int[]]                   $LocationIDs,
        [int]                     $RoomID,
        [int[]]                   $ParentIDs,
        [int[]]                   $ContractIDs,
        [int[]]                   $ExcludeContractIDs,
        [int[]]                   $TicketIDs,
        [int[]]                   $FormIDs,
        [int[]]                   $ExcludeTicketIDs,
        [int[]]                   $ProductModelIDs,
        [int[]]                   $MaintenanceScheduleIDs,
        [int[]]                   $UsingDepartmentIDs,
        [int[]]                   $RequestingDepartmentIDs,
        [int[]]                   $OwningDepartmentIDs,
        [int[]]                   $OwningDepartmentIDsPast,
        [guid[]]                  $UsingCustomerIDs,
        [guid[]]                  $RequestingCustomerIDs,
        [guid[]]                  $OwningCustomerIDs,
        [guid[]]                  $OwningCustomerIDsPast,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [double]                  $PurchaseCostFrom,
        [double]                  $PurchaseCostTo,
        [int]                     $ContractProviderID,
        [datetime]                $AcquisitionDateFrom,
        [datetime]                $AcquisitionDateTo,
        [datetime]                $ExpectedReplacementDateFrom,
        [datetime]                $ExpectedReplacementDateTo,
        [datetime]                $ContractEndDateFrom,
        [datetime]                $ContractEndDateTo,
        [boolean]                 $OnlyParentAssets,
        [System.Nullable[int]]    $MaxResults)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_AssetSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for frequently used parameters
    TeamDynamix_Api_Assets_AssetSearch(
        [string]              $SearchText,
        [string]              $SerialLike,
        [system.Nullable[int]]$MaxResults)
    {
        $this.SearchText = $SearchText
        $this.SerialLike = $SerialLike
        $this.MaxResults = $MaxResults
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.CustomAttributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.CustomAttributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Asset',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Assets_AssetSearch
{
    [string]                  $SerialLike
    [string]                  $SearchText
    [int]                     $SavedSearchID
    [int[]]                   $StatusIDs
    [string[]]                $ExternalIDs
    [System.Nullable[boolean]]$IsInService
    [int[]]                   $StatusIDsPast
    [int[]]                   $SupplierIDs
    [int[]]                   $ManufacturerIDs
    [int[]]                   $LocationIDs
    [int]                     $RoomID
    [int[]]                   $ParentIDs
    [int[]]                   $ContractIDs
    [int[]]                   $ExcludeContractIDs
    [int[]]                   $TicketIDs
    [int[]]                   $FormIDs
    [int[]]                   $ExcludeTicketIDs
    [int[]]                   $ProductModelIDs
    [int[]]                   $MaintenanceScheduleIDs
    [int[]]                   $UsingDepartmentIDs
    [int[]]                   $RequestingDepartmentIDs
    [int[]]                   $OwningDepartmentIDs
    [int[]]                   $OwningDepartmentIDsPast
    [guid[]]                  $UsingCustomerIDs
    [guid[]]                  $RequestingCustomerIDs
    [guid[]]                  $OwningCustomerIDs
    [guid[]]                  $OwningCustomerIDsPast
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [double]                  $PurchaseCostFrom
    [double]                  $PurchaseCostTo
    [int]                     $ContractProviderID
    [string]                  $AcquisitionDateFrom
    [string]                  $AcquisitionDateTo
    [string]                  $ExpectedReplacementDateFrom
    [string]                  $ExpectedReplacementDateTo
    [string]                  $ContractEndDateFrom
    [string]                  $ContractEndDateTo
    [boolean]                 $OnlyParentAssets
    [System.Nullable[int]]    $MaxResults

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Assets_AssetSearch ([psobject]$AssetSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_AssetSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $AssetSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $AssetSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $AssetSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Attachments_Attachment
{
    [guid]    $ID
    [TeamDynamix_Api_Attachments_AttachmentType]$AttachmentType
    [int]     $ItemID
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$CreatedDate
    [string]  $Name
    [int]     $Size
    [string]  $URI
    [string]  $ContentURI

    # Default constructor
    TeamDynamix_Api_Attachments_Attachment ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Attachments_Attachment ([psobject]$Attachment)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Attachments_Attachment]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Attachment.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Attachment.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Attachments_Attachment(
        [guid]    $ID,
        [TeamDynamix_Api_Attachments_AttachmentType]$AttachmentType,
        [int]     $ItemID,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$CreatedDate,
        [string]  $Name,
        [int]     $Size,
        [string]  $URI,
        [string]  $ContentURI)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Attachments_Attachment]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_FeedEntry
{
    [string]  $Comments
    [string[]]$Notify
    [boolean] $IsPrivate
    [boolean] $IsRichHtml

    # Default constructor
    TeamDynamix_Api_Feed_FeedEntry ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_FeedEntry ([psobject]$FeedEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_FeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $FeedEntry.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $FeedEntry.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_FeedEntry(
        [string]  $Comments,
        [string[]]$Notify,
        [boolean] $IsPrivate,
        [boolean] $IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_FeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_ResourceItem
{
    [string]$ItemRole
    [string]$Name
    [string]$Initials
    [string]$Value
    [int]   $RefValue
    [string]$ProfileImageFileName

    # Default constructor
    TeamDynamix_Api_ResourceItem ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ResourceItem ([psobject]$ResourceItem)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ResourceItem]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ResourceItem.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ResourceItem.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_FeedEntry(
        [string]$ItemRole,
        [string]$Name,
        [string]$Initials,
        [string]$Value,
        [int]   $RefValue,
        [string]$ProfileImageFileName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_FeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_ApplicationFeedSearch
{
    [DateTime]$DateFrom
    [DateTime]$DateTo
    [int]     $ReplyCount
    [int]     $ReturnCount

    # Default constructor
    TeamDynamix_Api_Feed_ApplicationFeedSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_ApplicationFeedSearch ([psobject]$FeedSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ApplicationFeedSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $FeedSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $FeedSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_ApplicationFeedSearch(
        [DateTime]$DateFrom,
        [DateTime]$DateTo,
        [int]     $ReplyCount,
        [int]     $ReturnCount)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ApplicationFeedSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Feed_ApplicationFeedSearch(
        [int]$ReplyCount)
    {
        $this.ReplyCount = $ReplyCount
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Feed_ApplicationFeedSearch
{
    [string]$DateFrom
    [string]$DateTo
    [int]   $ReplyCount
    [int]   $ReturnCount

    # Constructor from object
    TD_TeamDynamix_Api_Feed_ApplicationFeedSearch ([psobject]$FeedSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ApplicationFeedSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $FeedSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $FeedSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $FeedSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Feed_ItemUpdate
{
    [int]     $ID
    [guid]    $CreatedUID
    [int]     $CreatedRefID
    [string]  $CreatedFullName
    [string]  $CreatedFirstName
    [string]  $CreatedLastName
    [string]  $CreatedByPicPath
    [datetime]$CreatedDate
    [datetime]$LastUpdatedDate
    [int]     $ProjectID
    [string]  $ProjectName
    [int]     $PlanID
    [string]  $PlanName
    [TeamDynamix_Api_Feed_FeedItemType]$ItemType
    [int]     $ItemID
    [string]  $ItemTitle
    [string]  $ReferenceID
    [string]  $Body
    [boolean] $IsRichHtml
    [TeamDynamix_Api_Feed_UpdateType]$UpdateType
    [string]  $NotifiedList
    [boolean] $IsPrivate
    [boolean] $IsParent
    [TeamDynamix_Api_Feed_ItemUpdateReply[]]$Replies
    [int]     $RepliesCount
    [TeamDynamix_Api_Feed_ItemUpdateLike[]]$Likes
    [boolean] $ILike
    [int]     $LikesCount
    [TeamDynamix_Api_Feed_Participant[]]$Participants
    [string]  $BreadcrumbsHTML
    [boolean] $HasAttachment
    [string]  $Uri

    # Default constructor
    TeamDynamix_Api_Feed_ItemUpdate ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_ItemUpdate ([psobject]$ItemUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ItemUpdate.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ItemUpdate.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_ItemUpdate(
        [int]     $ID,
        [guid]    $CreatedUID,
        [int]     $CreatedRefID,
        [string]  $CreatedFullName,
        [string]  $CreatedFirstName,
        [string]  $CreatedLastName,
        [string]  $CreatedByPicPath,
        [datetime]$CreatedDate,
        [datetime]$LastUpdatedDate,
        [int]     $ProjectID,
        [string]  $ProjectName,
        [int]     $PlanID,
        [string]  $PlanName,
        [TeamDynamix_Api_Feed_FeedItemType]$ItemType,
        [int]     $ItemID,
        [string]  $ItemTitle,
        [string]  $ReferenceID,
        [string]  $Body,
        [boolean] $IsRichHtml,
        [TeamDynamix_Api_Feed_UpdateType]$UpdateType,
        [string]  $NotifiedList,
        [boolean] $IsPrivate,
        [boolean] $IsParent,
        [TeamDynamix_Api_Feed_ItemUpdateReply[]]$Replies,
        [int]     $RepliesCount,
        [TeamDynamix_Api_Feed_ItemUpdateLike[]]$Likes,
        [boolean] $ILike,
        [int]     $LikesCount,
        [TeamDynamix_Api_Feed_Participant[]]$Participants,
        [string]  $BreadcrumbsHTML,
        [boolean] $HasAttachment,
        [string]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Feed_ItemUpdate(
        [int]   $ID,
        [string]$Body)
    {
        $this.ID   = $ID
        $this.Body = $Body
    }
}

class TeamDynamix_Api_Feed_ItemUpdatesPage
{
    [TeamDynamix_Api_Feed_ItemUpdate[]]$Entries
    [datetime]                         $AsOfDate
    [System.Nullable[datetime]]        $NextDateTo

    # Default constructor
    TeamDynamix_Api_Feed_ItemUpdatesPage ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_ItemUpdatesPage ([psobject]$ItemUpdates)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdatesPage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ItemUpdates.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ItemUpdates.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_ItemUpdatesPage(
        [TeamDynamix_Api_Feed_ItemUpdate[]]$Entries,
        [datetime]                         $AsOfDate,
        [System.Nullable[datetime]]        $NextDateTo)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdatesPage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_ItemUpdateReply
{
    [int]     $ID
    [string]  $Body
    [boolean] $IsRichHtml
    [guid]    $CreatedUID
    [int]     $CreatedRefID
    [string]  $CreatedFullName
    [string]  $CreatedFirstName
    [string]  $CreatedLastName
    [string]  $CreatedByPicPath
    [datetime]$CreatedDate

    # Default constructor
    TeamDynamix_Api_Feed_ItemUpdateReply ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_ItemUpdateReply ([psobject]$UpdateReply)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdateReply]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UpdateReply.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $UpdateReply.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_ItemUpdateReply(
        [int]     $ID,
        [string]  $Body,
        [boolean] $IsRichHtml,
        [guid]    $CreatedUID,
        [int]     $CreatedRefID,
        [string]  $CreatedFullName,
        [string]  $CreatedFirstName,
        [string]  $CreatedLastName,
        [string]  $CreatedByPicPath,
        [datetime]$CreatedDate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdateReply]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_ItemUpdateLike
{
    [int]   $ID
    [string]$UserFullName
    [guid]  $UID

    # Default constructor
    TeamDynamix_Api_Feed_ItemUpdateLike ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_ItemUpdateLike ([psobject]$UpdateLike)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdateLike]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UpdateLike.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $UpdateLike.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_ItemUpdateLike(
        [int]   $ID,
        [string]$UserFullName,
        [guid]  $UID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_ItemUpdateLike]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_Participant
{
    [string]$FullName
    [string]$Email

    # Default constructor
    TeamDynamix_Api_Feed_Participant ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_Participant ([psobject]$Participant)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_Participant]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Participant.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Participant.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_Participant(
        [string]$FullName,
        [string]$Email)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_Participant]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Forms_Form
{
    [int]     $ID
    [string]  $Name
    [int]     $AppID
    [string]  $AppName
    [int]     $ComponentID
    [boolean] $IsActive
    [boolean] $IsConfigured
    [boolean] $IsDefaultForApp
    [boolean] $IsPinned
    [boolean] $ShouldExpandHelp
    [datetime]$CreatedDate
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName
    [int]     $AssetsCount
    [int]     $ConfigurationItemsCount

    # Default constructor
    TeamDynamix_Api_Forms_Form ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Forms_Form ([psobject]$Form)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Forms_Form]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Form.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Form.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Forms_Form(
        [int]     $ID,
        [string]  $Name,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $ComponentID,
        [boolean] $IsActive,
        [boolean] $IsConfigured,
        [boolean] $IsDefaultForApp,
        [boolean] $IsPinned,
        [boolean] $ShouldExpandHelp,
        [datetime]$CreatedDate,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName,
        [int]     $AssetsCount,
        [int]     $ConfigurationItemsCount)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Forms_Form]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    Static [TeamDynamix_Api_Forms_Form[]] GetForm (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return ($script:TDForms.GetAll($Environment))
    }

    Static [TeamDynamix_Api_Forms_Form[]] GetForm (
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return ($script:TDForms.GetAll($AppID,$Environment))
    }
}

class TeamDynamix_Api_BulkOperations_ItemResult
{
    [string]  $ExternalID
    [string]  $ServiceTag
    [TeamDynamix_Api_BulkOperations_ItemResultType]$Result
    [string[]]$Errors
    [string[]]$Warnings

    # Default constructor
    TeamDynamix_Api_BulkOperations_ItemResult ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_BulkOperations_ItemResult ([psobject]$Result)
    {
        foreach ($Parameter in ([TeamDynamix_Api_BulkOperations_ItemResult]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Result.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Result.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_BulkOperations_ItemResult(
        [string]  $ExternalID,
        [string]  $ServiceTag,
        [TeamDynamix_Api_BulkOperations_ItemResultType]$Result,
        [string[]]$Errors,
        [string[]]$Warnings)
    {
        foreach ($Parameter in ([TeamDynamix_Api_BulkOperations_ItemResult]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Accounts_Account
{
    [int]     $ID
    [string]  $Name
    [System.Nullable[int]]$ParentID
    [string]  $ParentName
    [boolean] $IsActive
    [string]  $Address1
    [string]  $Address2
    [string]  $Address3
    [string]  $Address4
    [string]  $City
    [string]  $StateName
    [string]  $StateAbbr
    [string]  $PostalCode
    [string]  $Country
    [string]  $Phone
    [string]  $Fax
    [string]  $Url
    [string]  $Notes
    [datetime]$CreatedDate
    [datetime]$ModifiedDate
    [string]  $Code
    [int]     $IndustryID
    [string]  $IndustryName
    [guid]    $ManagerUID
    [string]  $ManagerFullName
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes


    # Default constructor
    TeamDynamix_Api_Accounts_Account ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Accounts_Account ([psobject]$Account)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Accounts_Account]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Account.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Account.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Accounts_Account(
        [int]     $ID,
        [string]  $Name,
        [System.Nullable[int]]$ParentID,
        [string]  $ParentName,
        [boolean] $IsActive,
        [string]  $Address1,
        [string]  $Address2,
        [string]  $Address3,
        [string]  $Address4,
        [string]  $City,
        [string]  $StateName,
        [string]  $StateAbbr,
        [string]  $PostalCode,
        [string]  $Country,
        [string]  $Phone,
        [string]  $Fax,
        [string]  $Url,
        [string]  $Notes,
        [datetime]$CreatedDate,
        [datetime]$ModifiedDate,
        [string]  $Code,
        [int]     $IndustryID,
        [string]  $IndustryName,
        [guid]    $ManagerUID,
        [string]  $ManagerFullName,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Accounts_Account]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Accounts_Account(
        [string]  $Name,
        [System.Nullable[int]]$ParentID,
        [boolean] $IsActive,
        [string]  $Address1,
        [string]  $Address2,
        [string]  $Address3,
        [string]  $Address4,
        [string]  $City,
        [string]  $StateAbbr,
        [string]  $PostalCode,
        [string]  $Country,
        [string]  $Phone,
        [string]  $Fax,
        [string]  $Url,
        [string]  $Notes,
        [string]  $Code,
        [int]     $IndustryID,
        [guid]    $ManagerUID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Accounts_Account]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Methods
    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Account',$AppID,$Environment)
    }

    Static [TeamDynamix_Api_Accounts_Account[]] GetDepartment (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return ($script:TDAccounts.GetAll($Environment))
    }
}

class TeamDynamix_Api_Accounts_AccountSearch
{
    [string] $SearchText
    [guid[]] $ManagerUIDs
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[int]]$MaxResults
    [System.Nullable[int]]$ParentAccountID
    [string] $ParentAccountName

    # Default constructor
    TeamDynamix_Api_Accounts_AccountSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Accounts_AccountSearch ([psobject]$Account)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Accounts_AccountSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Account.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Account.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Accounts_AccountSearch(
        [string] $SearchText,
        [guid[]] $ManagerUIDs,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[int]]$MaxResults,
        [System.Nullable[int]]$ParentAccountID,
        [string] $ParentAccountName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Accounts_AccountSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Auth_LoginParameters
{
    [string]$UserName
    [string]$Password

    # Default constructor
    TeamDynamix_Api_Auth_LoginParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Auth_LoginParameters ([psobject]$LoginParameters)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Auth_LoginParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $LoginParameters.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $LoginParameters.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Auth_LoginParameters(
        [string]$UserName,
        [string]$Password)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Auth_LoginParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Apps_UserApplication
{
    [string] $SecurityRoleID
    [string] $SecurityRoleName
    [boolean]$IsAdministrator
    [int]    $ID
    [string] $Name
    [string] $Description
    [string] $SystemClass
    [boolean]$IsDefault
    [boolean]$IsActive

    # Default constructor
    TeamDynamix_Api_Apps_UserApplication ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Apps_UserApplication ([psobject]$Result)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Apps_UserApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Result.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Result.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Apps_UserApplication(
        [string]$SecurityRoleID,
        [string] $SecurityRoleName,
        [boolean]$IsAdministrator,
        [int]    $ID,
        [string] $Name,
        [string] $Description,
        [string] $SystemClass,
        [boolean]$IsDefault,
        [boolean]$IsActive)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Apps_UserApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_User
{
    [guid]    $UID
    [guid]    $BEID
    [int]     $BEIDInt
    [boolean] $IsActive
    [boolean] $IsConfidential
    [string]  $UserName
    [string]  $FullName
    [string]  $FirstName
    [string]  $LastName
    [string]  $MiddleName
    [string]  $Salutation
    [string]  $Nickname
    [int]     $DefaultAccountID
    [string]  $DefaultAccountName
    [string]  $PrimaryEmail
    [string]  $AlternateEmail
    [string]  $ExternalID
    [string]  $AlternateID
    [string[]]$Applications
    [string]  $SecurityRoleName
    [string]  $SecurityRoleID
    [string[]]$Permissions
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [System.Nullable[int]]$PrimaryClientPortalApplicationID
    [int[]]   $GroupIDs
    [int]     $ReferenceID
    [string]  $AlertEmail
    [string]  $ProfileImageFileName
    [string]  $Company
    [string]  $Title
    [string]  $HomePhone
    [string]  $PrimaryPhone
    [string]  $WorkPhone
    [string]  $Pager
    [string]  $OtherPhone
    [string]  $MobilePhone
    [string]  $Fax
    [int]     $DefaultPriorityID
    [string]  $DefaultPriorityName
    [string]  $AboutMe
    [string]  $WorkAddress
    [string]  $WorkCity
    [string]  $WorkState
    [string]  $WorkZip
    [string]  $WorkCountry
    [string]  $HomeAddress
    [string]  $HomeCity
    [string]  $HomeState
    [string]  $HomeZip
    [string]  $HomeCountry
    [int]     $LocationID
    [string]  $LocationName
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [double]  $DefaultRate
    [double]  $CostRate
    [boolean] $IsEmployee
    [double]  $WorkableHours
    [boolean] $IsCapacityManaged
    [datetime]$ReportTimeAfterDate
    [datetime]$EndDate
    [boolean] $ShouldReportTime
    [string]  $ReportsToUID
    [string]  $ReportsToFullName
    [int]     $ResourcePoolID
    [string]  $ResourcePoolName
    [int]     $TZID
    [string]  $TZName
    [TeamDynamix_Api_Users_UserType]$TypeID
    [string]  $AuthenticationUserName
    [System.Nullable[int]]$AuthenticationProviderID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $IMProvider
    [string]  $IMHandle

    # Default constructor
    TeamDynamix_Api_Users_User ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_User ([psobject]$User)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_User]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $User.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $User.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_User(
        [guid]    $UID,
        [guid]    $BEID,
        [int]     $BEIDInt,
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $UserName,
        [string]  $FullName,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $DefaultAccountName,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleName,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [int[]]   $GroupIDs,
        [int]     $ReferenceID,
        [string]  $AlertEmail,
        [string]  $ProfileImageFileName,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $DefaultPriorityName,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [int]     $LocationID,
        [string]  $LocationName,
        [int]     $LocationRoomID,
        [string]  $LocationRoomName,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $TZName,
        [TeamDynamix_Api_Users_UserType]$TypeID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_User]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Users_User(
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [string]  $AlertEmail,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [int]     $LocationID,
        [int]     $LocationRoomID,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_User]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }

    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Person',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveOrgApplication (
        [guid] $SecurityID)
    {
        $UpdatedOrgApplicationList = $this.OrgApplications | Where-Object SecurityRoleID -ne $SecurityID
        # Returning null does not update the field in TD, must return an empty array to clear last item
        if ($null -eq $UpdatedOrgApplicationList)
        {
            $UpdatedOrgApplicationList = @()
        }
        $this.Attributes = $UpdatedOrgApplicationList
    }

    [void] RemoveOrgApplication (
        [string] $SecurityRoleName)
    {
        $UpdatedOrgApplicationList = $this.OrgApplications | Where-Object SecurityRoleName -ne $SecurityRoleName
        # Returning null does not update the field in TD, must return an empty array to clear last item
        if ($null -eq $UpdatedOrgApplicationList)
        {
            $UpdatedOrgApplicationList = @()
        }
        $this.OrgApplications = $UpdatedOrgApplicationList
    }

    [void] SetSecurityRoleID (
        [string]   $SecurityRoleName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.SecurityRoleID = ($script:TDSecurityRoles.Get($SecurityRoleName,$Environment)).ID
    }

    [void] SetDefaultPriorityID (
        [string]   $DefaultPriorityName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.DefaultPriorityID = (script:TDTicketPriorities.Get($DefaultPriorityName,$Environment)).ID
    }

    [void] SetTZID (
        [string]   $TZName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.SetTZID = (script:TDTimeZones.Get($TZName,$Environment)).ID
    }

    Static [TeamDynamix_Api_Users_User[]] GetUser (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDUser -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [TeamDynamix_Api_Users_User[]] GetUser (
        [string]   $UserName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        if ($UserName -like '*@*')
        {
            $Return = Get-TDUser -UserName $UserName -Detail -AuthenticationToken $TDAuthentication -Environment $Environment
        }
        else
        {
            $Return = (Get-TDUser -SearchText $UserName -Detail -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -like "$Username@*")
        }
        return $Return
    }

    [void] SetUserRole (
        [string]$UserRoleName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $RoleData = $script:TDConfig.UserRoles | Where-Object Name -eq $UserRoleName
        if ($RoleData)
        {
            $this.SecurityRoleID   = ($script:TDSecurityRoles.Get($RoleData.UserSecurityRole,$Environment)).ID
            $this.SecurityRoleName = $RoleData.UserSecurityRole
            $this.Applications     = $RoleData.Applications
            $this.OrgApplications  = Get-OrgAppsByRoleName -UserRoleName $UserRoleName -AuthenticationToken $TDAuthentication -Environment $Environment
            # Check to see if a client portal OrgApplication has been assigned
            #  Set the primary client portal ID to the new client portal
            foreach ($OrgApplication in $this.OrgApplications)
            {
                if ($OrgApplication.ID -in $script:TDApplications.GetByType('Client Portal',$Environment).ID)
                {
                    $this.PrimaryClientPortalApplicationID = $OrgApplication.ID
                }
            }
        }
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Users_User
{
    [guid]    $UID
    [guid]    $BEID
    [int]     $BEIDInt
    [boolean] $IsActive
    [boolean] $IsConfidential
    [string]  $UserName
    [string]  $FullName
    [string]  $FirstName
    [string]  $LastName
    [string]  $MiddleName
    [string]  $Salutation
    [string]  $Nickname
    [int]     $DefaultAccountID
    [string]  $DefaultAccountName
    [string]  $PrimaryEmail
    [string]  $AlternateEmail
    [string]  $ExternalID
    [string]  $AlternateID
    [string[]]$Applications
    [string]  $SecurityRoleName
    [string]  $SecurityRoleID
    [string[]]$Permissions
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [System.Nullable[int]]$PrimaryClientPortalApplicationID
    [int[]]   $GroupIDs
    [int]     $ReferenceID
    [string]  $AlertEmail
    [string]  $ProfileImageFileName
    [string]  $Company
    [string]  $Title
    [string]  $HomePhone
    [string]  $PrimaryPhone
    [string]  $WorkPhone
    [string]  $Pager
    [string]  $OtherPhone
    [string]  $MobilePhone
    [string]  $Fax
    [int]     $DefaultPriorityID
    [string]  $DefaultPriorityName
    [string]  $AboutMe
    [string]  $WorkAddress
    [string]  $WorkCity
    [string]  $WorkState
    [string]  $WorkZip
    [string]  $WorkCountry
    [string]  $HomeAddress
    [string]  $HomeCity
    [string]  $HomeState
    [string]  $HomeZip
    [string]  $HomeCountry
    [int]     $LocationID
    [string]  $LocationName
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [double]  $DefaultRate
    [double]  $CostRate
    [boolean] $IsEmployee
    [double]  $WorkableHours
    [boolean] $IsCapacityManaged
    [string]  $ReportTimeAfterDate
    [string]  $EndDate
    [boolean] $ShouldReportTime
    [string]  $ReportsToUID
    [string]  $ReportsToFullName
    [int]     $ResourcePoolID
    [string]  $ResourcePoolName
    [int]     $TZID
    [string]  $TZName
    [TeamDynamix_Api_Users_UserType]$TypeID
    [string]  $AuthenticationUserName
    [System.Nullable[int]]$AuthenticationProviderID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $IMProvider
    [string]  $IMHandle

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Users_User ([psobject]$User)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_User]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $User.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $User.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $User.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserSearch
{
    [string]$SearchText
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[boolean]]$IsEmployee
    [string]$AppName
    [int[]] $AccountIDs
    [System.Nullable[int]]    $MaxResults
    [int[]] $ReferenceIDs
    [string]$ExternalID
    [string]$AlternateID
    [string]$UserName
    [System.Nullable[guid]]   $SecurityRoleID
    [System.Nullable[boolean]]$IsConfidential

    # Default constructor
    TeamDynamix_Api_Users_UserSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserSearch ([psobject]$UserSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $UserSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserSearch(
        [string]$SearchText,
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[boolean]]$IsEmployee,
        [string]$AppName,
        [int[]] $AccountIDs,
        [System.Nullable[int]]    $MaxResults,
        [int[]] $ReferenceIDs,
        [string]$ExternalID,
        [string]$AlternateID,
        [string]$UserName,
        [System.Nullable[guid]]   $SecurityRoleID,
        [System.Nullable[boolean]]$IsConfidential)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Auth_AdminTokenParameters
{
    [guid]$BEID
    [guid]$WebServicesKey

    # Default constructor
    TeamDynamix_Api_Auth_AdminTokenParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Auth_AdminTokenParameters ([psobject]$AdminToken)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Auth_AdminTokenParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $AdminToken.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $AdminToken.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Auth_AdminTokenParameters(
        [guid]$BEID,
        [guid]$WebServicesKey)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Auth_AdminTokenParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_GroupApplication
{
        [Int32] $GroupID
        [Int32] $AppID
        [String]$AppName
        [String]$AppDescription
        [String]$AppClass

    # Default constructor
    TeamDynamix_Api_Users_GroupApplication ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_GroupApplication ([psobject]$GroupApplication)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $GroupApplication.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $GroupApplication.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $GroupApplication.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_GroupApplication(
                [Int32] $GroupID,
                [Int32] $AppID,
                [String]$AppName,
                [String]$AppDescription,
                [String]$AppClass)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_Group
{
    [int]     $ID
    [string]  $Name
    [string]  $Description
    [boolean] $IsActive
    [string]  $ExternalID
    [datetime]$CreatedDate
    [datetime]$ModifiedDate
    [TeamDynamix_Api_Users_GroupApplication[]]$PlatformApplications

    # Default constructor
    TeamDynamix_Api_Users_Group ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_Group ([psobject]$Group)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_Group]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Group.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Group.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_Group(
        [int]     $ID,
        [string]  $Name,
        [string]  $Description,
        [boolean] $IsActive,
        [string]  $ExternalID,
        [datetime]$CreatedDate,
        [datetime]$ModifiedDate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_Group]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Users_Group(
        [string] $Name,
        [string] $Description,
        [boolean]$IsActive,
        [string] $ExternalID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_Group]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Users_Group(
        [string]$Name)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_Group]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_UserGroup
{
    [int]    $GroupID
    [string] $GroupName
    [boolean]$IsPrimary
    [boolean]$IsManager
    [boolean]$IsNotified

    # Default constructor
    TeamDynamix_Api_Users_UserGroup ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserGroup ([psobject]$Group)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserGroup]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Group.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Group.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserGroup(
        [int]    $GroupID,
        [string] $GroupName,
        [boolean]$IsPrimary,
        [boolean]$IsManager,
        [boolean]$IsNotified)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_Group]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_GroupMember
{
    [boolean] $IsPrimaryGroup
    [boolean] $IsGroupManager
    [boolean] $IsGroupNotified
    [datetime]$AddedToGroupDate
    [guid]    $UID
    [guid]    $BEID
    [int]     $BEIDInt
    [boolean] $IsActive
    [boolean] $IsConfidential
    [string]  $UserName
    [string]  $FullName
    [string]  $FirstName
    [string]  $LastName
    [string]  $MiddleName
    [string]  $Salutation
    [string]  $Nickname
    [int]     $DefaultAccountID
    [string]  $DefaultAccountName
    [string]  $PrimaryEmail
    [string]  $AlternateEmail
    [string]  $ExternalID
    [string]  $AlternateID
    [string[]]$Applications
    [string]  $SecurityRoleName
    [string]  $SecurityRoleID
    [string[]]$Permissions
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [System.Nullable[int]]$PrimaryClientPortalApplicationID
    [int[]]   $GroupIDs
    [int]     $ReferenceID
    [string]  $AlertEmail
    [string]  $ProfileImageFileName
    [string]  $Company
    [string]  $Title
    [string]  $HomePhone
    [string]  $PrimaryPhone
    [string]  $WorkPhone
    [string]  $Pager
    [string]  $OtherPhone
    [string]  $MobilePhone
    [string]  $Fax
    [int]     $DefaultPriorityID
    [string]  $DefaultPriorityName
    [string]  $AboutMe
    [string]  $WorkAddress
    [string]  $WorkCity
    [string]  $WorkState
    [string]  $WorkZip
    [string]  $WorkCountry
    [string]  $HomeAddress
    [string]  $HomeCity
    [string]  $HomeState
    [string]  $HomeZip
    [string]  $HomeCountry
    [int]     $LocationID
    [string]  $LocationName
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [double]  $DefaultRate
    [double]  $CostRate
    [boolean] $IsEmployee
    [double]  $WorkableHours
    [boolean] $IsCapacityManaged
    [datetime]$ReportTimeAfterDate
    [datetime]$EndDate
    [boolean] $ShouldReportTime
    [string]  $ReportsToUID
    [string]  $ReportsToFullName
    [int]     $ResourcePoolID
    [string]  $ResourcePoolName
    [int]     $TZID
    [string]  $TZName
    [TeamDynamix_Api_Users_UserType]$TypeID
    [string]  $AuthenticationUserName
    [System.Nullable[int]]$AuthenticationProviderID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $IMProvider
    [string]  $IMHandle

    # Default constructor
    TeamDynamix_Api_Users_GroupMember ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_GroupMember ([psobject]$GroupMember)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupMember]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $GroupMember.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $GroupMember.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_GroupMember(
        [boolean] $IsPrimaryGroup,
        [boolean] $IsGroupManager,
        [boolean] $IsGroupNotified,
        [datetime]$AddedToGroupDate,
        [guid]    $UID,
        [guid]    $BEID,
        [int]     $BEIDInt,
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $UserName,
        [string]  $FullName,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $DefaultAccountName,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleName,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [int[]]   $GroupIDs,
        [int]     $ReferenceID,
        [string]  $AlertEmail,
        [string]  $ProfileImageFileName,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $DefaultPriorityName,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [int]     $LocationID,
        [string]  $LocationName,
        [int]     $LocationRoomID,
        [string]  $LocationRoomName,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $TZName,
        [TeamDynamix_Api_Users_UserType]$TypeID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupMember]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Users_GroupMember(
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [string]  $AlertEmail,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [int]     $LocationID,
        [int]     $LocationRoomID,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupMember]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_GroupSearch
{
    [System.Nullable[boolean]]$IsActive
    [string]                  $NameLike
    [System.Nullable[int]]    $HasAppID
    [string]                  $HasSystemAppName
    [System.Nullable[int]]    $AssociatedAppID

    # Default constructor
    TeamDynamix_Api_Users_GroupSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_GroupSearch ([psobject]$GroupSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $GroupSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $GroupSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_GroupSearch(
        [System.Nullable[boolean]]$IsActive,
        [string]                  $NameLike,
        [System.Nullable[int]]    $HasAppID,
        [string]                  $HasSystemAppName,
        [System.Nullable[int]]    $AssociatedAppID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_GroupSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_NewUser
{
    [string]  $Password
    [guid]    $DesktopID
    [boolean] $LinkDesktop
    [boolean] $IsActive
    [boolean] $IsConfidential
    [string]  $UserName
    [string]  $FirstName
    [string]  $LastName
    [string]  $MiddleName
    [string]  $Salutation
    [string]  $Nickname
    [int]     $DefaultAccountID
    [string]  $DefaultAccountName
    [string]  $PrimaryEmail
    [string]  $AlternateEmail
    [string]  $ExternalID
    [string]  $AlternateID
    [string[]]$Applications
    [string]  $SecurityRoleName
    [string]  $SecurityRoleID
    [string[]]$Permissions
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [System.Nullable[int]]$PrimaryClientPortalApplicationID
    [int[]]   $GroupIDs
    [int]     $ReferenceID
    [string]  $AlertEmail
    [string]  $Company
    [string]  $Title
    [string]  $HomePhone
    [string]  $PrimaryPhone
    [string]  $WorkPhone
    [string]  $Pager
    [string]  $OtherPhone
    [string]  $MobilePhone
    [string]  $Fax
    [int]     $DefaultPriorityID
    [string]  $DefaultPriorityName
    [string]  $AboutMe
    [string]  $WorkAddress
    [string]  $WorkCity
    [string]  $WorkState
    [string]  $WorkZip
    [string]  $WorkCountry
    [string]  $HomeAddress
    [string]  $HomeCity
    [string]  $HomeState
    [string]  $HomeZip
    [string]  $HomeCountry
    [double]  $DefaultRate
    [double]  $CostRate
    [boolean] $IsEmployee
    [double]  $WorkableHours
    [boolean] $IsCapacityManaged
    [datetime]$ReportTimeAfterDate
    [datetime]$EndDate
    [boolean] $ShouldReportTime
    [string]  $ReportsToUID
    [string]  $ReportsToFullName
    [int]     $ResourcePoolID
    [string]  $ResourcePoolName
    [int]     $TZID
    [string]  $TZName
    [TeamDynamix_Api_Users_UserType]$TypeID
    [string]  $AuthenticationUserName
    [System.Nullable[int]]$AuthenticationProviderID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $IMProvider
    [string]  $IMHandle
    [int32]   $LocationID
    [int32]   $LocationRoomID

    # Default constructor
    TeamDynamix_Api_Users_NewUser ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_NewUser ([psobject]$User)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_NewUser]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $User.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $User.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_NewUser(
        [string]  $Password,
        [guid]    $DesktopID,
        [boolean] $LinkDesktop,
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $UserName,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $DefaultAccountName,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleName,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [int[]]   $GroupIDs,
        [int]     $ReferenceID,
        [string]  $AlertEmail,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $DefaultPriorityName,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $TZName,
        [TeamDynamix_Api_Users_UserType]$TypeID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle,
        [int32]   $LocationID,
        [int32]   $LocationRoomID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_NewUser]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Users_NewUser(
        [string]  $Password,
        [guid]    $DesktopID,
        [boolean] $LinkDesktop,
        [boolean] $IsActive,
        [boolean] $IsConfidential,
        [string]  $FirstName,
        [string]  $LastName,
        [string]  $MiddleName,
        [string]  $Salutation,
        [string]  $Nickname,
        [int]     $DefaultAccountID,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $ExternalID,
        [string]  $AlternateID,
        [string[]]$Applications,
        [string]  $SecurityRoleID,
        [string[]]$Permissions,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [System.Nullable[int]]$PrimaryClientPortalApplicationID,
        [string]  $AlertEmail,
        [string]  $Company,
        [string]  $Title,
        [string]  $HomePhone,
        [string]  $PrimaryPhone,
        [string]  $WorkPhone,
        [string]  $Pager,
        [string]  $OtherPhone,
        [string]  $MobilePhone,
        [string]  $Fax,
        [int]     $DefaultPriorityID,
        [string]  $AboutMe,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkCountry,
        [string]  $HomeAddress,
        [string]  $HomeCity,
        [string]  $HomeState,
        [string]  $HomeZip,
        [string]  $HomeCountry,
        [double]  $DefaultRate,
        [double]  $CostRate,
        [boolean] $IsEmployee,
        [double]  $WorkableHours,
        [boolean] $IsCapacityManaged,
        [datetime]$ReportTimeAfterDate,
        [datetime]$EndDate,
        [boolean] $ShouldReportTime,
        [string]  $ReportsToUID,
        [string]  $ReportsToFullName,
        [int]     $ResourcePoolID,
        [string]  $ResourcePoolName,
        [int]     $TZID,
        [string]  $AuthenticationUserName,
        [System.Nullable[int]]$AuthenticationProviderID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $IMProvider,
        [string]  $IMHandle,
        [int32]   $LocationID,
        [int32]   $LocationRoomID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_User]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Assets_ContactInformation
{
    [int]   $ID
    [string]$AddressLine1
    [string]$AddressLine2
    [string]$AddressLine3
    [string]$AddressLine4
    [string]$City
    [string]$State
    [string]$PostalCode
    [string]$Country
    [string]$Url
    [string]$Phone
    [string]$Fax

    # Default constructor
    TeamDynamix_Api_Assets_ContactInformation ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ContactInformation ([psobject]$ContactInformation)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ContactInformation]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ContactInformation.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ContactInformation.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ContactInformation(
        [int]   $ID,
        [string]$AddressLine1,
        [string]$AddressLine2,
        [string]$AddressLine3,
        [string]$AddressLine4,
        [string]$City,
        [string]$State,
        [string]$PostalCode,
        [string]$Country,
        [string]$Url,
        [string]$Phone,
        [string]$Fax)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ContactInformation]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Assets_Vendor
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [string]  $Name
    [string]  $Description
    [boolean] $IsActive
    [string]  $AccountNumber
    [boolean] $IsContractProvider
    [boolean] $IsManufacturer
    [boolean] $IsSupplier
    [TeamDynamix_Api_Assets_ContactInformation]$CompanyInformation
    [string]  $ContactName
    [string]  $ContactTitle
    [string]  $ContactDepartment
    [string]  $ContactEmail
    [TeamDynamix_Api_Assets_ContactInformation]$PrimaryContactInformation
    [int]     $ContractsCount
    [int]     $ProductModelsCount
    [int]     $AssetsSuppliedCount
    [array]   $Attributes
    [datetime]$CreatedDate
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Assets_Vendor ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_Vendor ([psobject]$Vendor)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Vendor]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Vendor.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Vendor.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_Vendor(
    [int]     $ID,
    [int]     $AppID,
    [string]  $AppName,
    [string]  $Name,
    [string]  $Description,
    [boolean] $IsActive,
    [string]  $AccountNumber,
    [boolean] $IsContractProvider,
    [boolean] $IsManufacturer,
    [boolean] $IsSupplier,
    [TeamDynamix_Api_Assets_ContactInformation]$CompanyInformation,
    [string]  $ContactName,
    [string]  $ContactTitle,
    [string]  $ContactDepartment,
    [string]  $ContactEmail,
    [TeamDynamix_Api_Assets_ContactInformation]$PrimaryContactInformation,
    [int]     $ContractsCount,
    [int]     $ProductModelsCount,
    [int]     $AssetsSuppliedCount,
    [array]   $Attributes,
    [datetime]$CreatedDate,
    [guid]    $CreatedUid,
    [string]  $CreatedFullName,
    [datetime]$ModifiedDate,
    [guid]    $ModifiedUid,
    [string]  $ModifiedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Vendor]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_Vendor(
        [string]  $Name,
        [string]  $Description,
        [boolean] $IsActive,
        [string]  $AccountNumber,
        [boolean] $IsContractProvider,
        [boolean] $IsManufacturer,
        [boolean] $IsSupplier,
        [TeamDynamix_Api_Assets_ContactInformation]$CompanyInformation,
        [string]  $ContactName,
        [string]  $ContactTitle,
        [string]  $ContactDepartment,
        [string]  $ContactEmail,
        [TeamDynamix_Api_Assets_ContactInformation]$PrimaryContactInformation,
        [array]   $Attributes)
    {
        $this.Name                      = $Name
        $this.Description               = $Description
        $this.IsActive                  = $IsActive
        $this.IsContractProvider        = $IsContractProvider
        $this.IsSupplier                = $IsSupplier
        $this.IsManufacturer            = $IsManufacturer
        $this.CompanyInformation        = $CompanyInformation
        $this.$ContactName              = $ContactName
        $this.ContactTitle              = $ContactTitle
        $this.ContactDepartment         = $ContactDepartment
        $this.ContactEmail              = $ContactEmail
        $this.PrimaryContactInformation = $PrimaryContactInformation
        $this.Attributes                = $Attributes
    }

    TeamDynamix_Api_Assets_Vendor(
        [string] $Name,
        [string] $Description,
        [int]    $AppID)
    {
        $this.Name           = $Name
        $this.Description    = $Description
        $this.AppID          = $AppID
        $this.IsSupplier     = $true
        $this.IsManufacturer = $true
    }

    Static [TeamDynamix_Api_Assets_Vendor[]] GetVendor (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (script:TDVendors.GetAll($Environment))
    }
}

class TeamDynamix_Api_Assets_VendorSearch
{
    [string]                  $NameLike
    [string]                  $SearchText
    [boolean]                 $OnlyManufacturers
    [boolean]                 $OnlySuppliers
    [boolean]                 $OnlyContractProviders
    [System.Nullable[boolean]]$IsActive
    [array]                   $CustomAttributes

    # Default constructor
    TeamDynamix_Api_Assets_VendorSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_VendorSearch ([psobject]$VendorSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_VendorSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $VendorSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $VendorSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_VendorSearch(
    [string]                  $NameLike,
    [string]                  $SearchText,
    [boolean]                 $OnlyManufacturers,
    [boolean]                 $OnlySuppliers,
    [boolean]                 $OnlyContractProviders,
    [System.Nullable[boolean]]$IsActive,
    [array]                   $CustomAttributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_VendorSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Assets_ProductModel
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [string]  $Name
    [string]  $Description
    [boolean] $IsActive
    [int]     $ManufacturerID
    [string]  $ManufacturerName
    [int]     $ProductTypeID
    [string]  $ProductTypeName
    [string]  $PartNumber
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [datetime]$CreatedDate
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Assets_ProductModel ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ProductModel ([psobject]$ProductModel)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductModel]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProductModel.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ProductModel.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ProductModel(
    [int]     $ID,
    [int]     $AppID,
    [string]  $AppName,
    [string]  $Name,
    [string]  $Description,
    [boolean] $IsActive,
    [int]     $ManufacturerID,
    [string]  $ManufacturerName,
    [int]     $ProductTypeID,
    [string]  $ProductTypeName,
    [string]  $PartNumber,
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
    [datetime]$CreatedDate,
    [guid]    $CreatedUid,
    [string]  $CreatedFullName,
    [datetime]$ModifiedDate,
    [guid]    $ModifiedUid,
    [string]  $ModifiedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductModel]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_ProductModel(
        [string]$Name,
        [string]$Description,
        [int]   $AppID,
        [int]   $ManufacturerID,
        [int]   $ProductTypeID,
        [string]$PartNumber,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        $this.Name           = $Name
        $this.Description    = $Description
        $this.AppID          = $AppID
        $this.ManufacturerID = $ManufacturerID
        $this.ProductTypeID  = $ProductTypeID
        $this.PartNumber     = $PartNumber
        $this.Attributes     = $Attributes
    }

    TeamDynamix_Api_Assets_ProductModel(
        [string]   $Name,
        [string]   $Description,
        [int]      $AppID,
        [string]   $ManufacturerName,
        [string]   $ProductTypeName,
        [string]   $PartNumber,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.Name           = $Name
        $this.Description    = $Description
        $this.AppID          = $AppID
        $this.ManufacturerID = (script:TDVendors.Get($ManufacturerName,$Environment)).ID
        $this.ProductTypeID  = (script:TDProductTypes.Get($ProductTypeName,$Environment)).ID
        $this.PartNumber     = $PartNumber
        $this.Attributes     = $Attributes
    }

    TeamDynamix_Api_Assets_ProductModel(
        [string]$Name,
        [int]   $AppID,
        [int]   $ManufacturerID,
        [int]   $ProductTypeID,
        [string]$PartNumber)
    {
        $this.Name           = $Name
        $this.AppID          = $AppID
        $this.ManufacturerID = $ManufacturerID
        $this.ProductTypeID  = $ProductTypeID
        $this.PartNumber     = $PartNumber
    }

    TeamDynamix_Api_Assets_ProductModel(
        [string]   $Name,
        [int]      $AppID,
        [string]   $ManufacturerName,
        [string]   $ProductTypeName,
        [string]   $PartNumber,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.Name           = $Name
        $this.AppID          = $AppID
        $this.ManufacturerID = (script:TDVendors.Get($ManufacturerName,$Environment)).ID
        $this.ProductTypeID  = (script:TDProductTypes.Get($ProductTypeName,$Environment)).ID
        $this.PartNumber     = $PartNumber
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'ProductModel',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    Static [TeamDynamix_Api_Assets_ProductModel[]] GetProductModel (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (script:TDProductModels.GetAll($Environment))
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'ProductModel',$AppID,$Environment)
    }
}

class TeamDynamix_Api_Assets_ProductModelSearch
{
    [string]                  $SearchText
    [int]                     $ManufacturerID
    [int]                     $ProductTypeID
    [System.Nullable[boolean]]$IsActive
    [array]                   $CustomAttributes

    # Default constructor
    TeamDynamix_Api_Assets_ProductModelSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ProductModelSearch ([psobject]$ProductModelSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductModelSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProductModelSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ProductModelSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ProductModelSearch(
        [string]                  $SearchText,
        [int]                     $ManufacturerID,
        [int]                     $ProductTypeID,
        [System.Nullable[boolean]]$IsActive,
        [array]                   $CustomAttributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductModelSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.CustomAttributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.CustomAttributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'ProductModel',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.CustomAttributes | Where-Object ID -ne $AttributeID
        $this.CustomAttributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.CustomAttributes | Where-Object Name -ne $AttributeName
        $this.CustomAttributes = $UpdatedAttributeList
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Asset',$AppID,$Environment)
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItemType
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [boolean] $IsSystemDefined
    [string]  $Name
    [boolean] $IsActive
    [datetime]$CreatedDateUtc
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [datetime]$ModifiedDateUtc
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItemType ([psobject]$CIType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CIType.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CIType.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemType(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [boolean] $IsSystemDefined,
        [string]  $Name,
        [boolean] $IsActive,
        [datetime]$CreatedDateUtc,
        [guid]    $CreatedUid,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDateUtc,
        [guid]    $ModifiedUid,
        [string]  $ModifiedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Cmdb_ConfigurationItemType(
        [string] $Name,
        [boolean]$IsActive)
    {
        $this.Name     = $Name
        $this.IsActive = $IsActive
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch
{
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[boolean]]$IsOrganizationallyDefined
    [string]                  $SearchText

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch ([psobject]$CITypeSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CITypeSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CITypeSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch(
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[boolean]]$IsOrganizationallyDefined,
        [string]                  $SearchText)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItem
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $FormID
    [string]  $FormName
    [boolean] $IsSystemMaintained
    [int]     $BackingItemID
    [TeamDynamix_Api_Cmdb_BackingItemType]$BackingItemType
    [string]  $Name
    [int]     $TypeID
    [string]  $TypeName
    [int]     $MaintenanceScheduleID
    [string]  $MaintenanceScheduleName
    [guid]    $OwnerUID
    [string]  $OwnerFullName
    [int]     $OwningDepartmentID
    [string]  $OwningDepartmentName
    [int]     $OwningGroupID
    [string]  $OwningGroupName
    [int]     $LocationID
    [string]  $LocationName
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [boolean] $IsActive
    [datetime]$CreatedDateUtc
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDateUtc
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName
    [string]  $ExternalID
    [int]     $ExternalSourceID
    [string]  $ExternalSourceName
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Attachments_Attachment[]]          $Attachments
    [string]  $URI

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItem ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItem ([psobject]$CI)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItem]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CI.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CI.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItem(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $FormID,
        [string]  $FormName,
        [boolean] $IsSystemMaintained,
        [int]     $BackingItemID,
        [TeamDynamix_Api_Cmdb_BackingItemType]$BackingItemType,
        [string]  $Name,
        [int]     $TypeID,
        [string]  $TypeName,
        [int]     $MaintenanceScheduleID,
        [string]  $MaintenanceScheduleName,
        [guid]    $OwnerUID,
        [string]  $OwnerFullName,
        [int]     $OwningDepartmentID,
        [string]  $OwningDepartmentName,
        [int]     $OwningGroupID,
        [string]  $OwningGroupName,
        [int]     $LocationID,
        [string]  $LocationName,
        [int]     $LocationRoomID,
        [string]  $LocationRoomName,
        [boolean] $IsActive,
        [datetime]$CreatedDateUtc,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDateUtc,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName,
        [string]  $ExternalID,
        [int]     $ExternalSourceID,
        [string]  $ExternalSourceName,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [TeamDynamix_Api_Attachments_Attachment[]]          $Attachments,
        [string]  $URI)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItem]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Cmdb_ConfigurationItem(
        [int]     $FormID,
        [string]  $Name,
        [int]     $TypeID,
        [int]     $MaintenanceScheduleID,
        [guid]    $OwnerUID,
        [int]     $OwningGroupID,
        [int]     $LocationID,
        [int]     $LocationRoomID,
        [boolean] $IsActive,
        [string]  $ExternalID,
        [int]     $ExternalSourceID)
    {
        $this.FormID                = $FormID
        $this.Name                  = $Name
        $this.TypeID                = $TypeID
        $this.MaintenanceScheduleID = $MaintenanceScheduleID
        $this.OwnerUID              = $OwnerUID
        $this.OwningGroupID         = $OwningGroupID
        $this.LocationID            = $LocationID
        $this.LocationRoomID        = $LocationRoomID
        $this.IsActive              = $IsActive
        $this.ExternalID            = $ExternalID
        $this.ExternalSourceID      = $ExternalSourceID
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItemSearch
{
    [string]                  $NameLike
    [System.Nullable[boolean]]$IsActive
    [int[]]                   $TypeIDs
    [int[]]                   $MaintenanceScheduleIDs
    [array]                   $CustomAttributes

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItemSearch ([psobject]$CISearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CISearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CISearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemSearch(
        [string]                  $NameLike,
        [System.Nullable[boolean]]$IsActive,
        [int[]]                   $TypeIDs,
        [int[]]                   $MaintenanceScheduleIDs,
        [array]                   $CustomAttributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationRelationshipType
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [boolean] $IsSystemDefined
    [string]  $Description
    [string]  $InverseDescription
    [boolean] $IsOperationalDependency
    [boolean] $IsActive
    [datetime]$CreatedDateUtc
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDateUtc
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipType ([psobject]$CIRelationshipType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationRelationshipType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CIRelationshipType.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CIRelationshipType.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipType(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [boolean] $IsSystemDefined,
        [string]  $Description,
        [string]  $InverseDescription,
        [boolean] $IsOperationalDependency,
        [boolean] $IsActive,
        [datetime]$CreatedDateUtc,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDateUtc,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationRelationshipType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipType(
        [string]  $Description,
        [string]  $InverseDescription,
        [boolean] $IsOperationalDependency,
        [boolean] $IsActive)
    {
        $this.Description             = $Description
        $this.InverseDescription      = $InverseDescription
        $this.IsOperationalDependency = $IsOperationalDependency
        $this.IsActive                = $IsActive
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch
{
    [string]                  $DescriptionLike
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[boolean]]$IsOperationalDependency

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch ([psobject]$CIRelationshipTypeSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CIRelationshipTypeSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CIRelationshipTypeSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch(
        [string]                  $DescriptionLike,
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[boolean]]$IsOperationalDependency)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationRelationshipTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItemRelationship
{
    [int]    $ID
    [int]    $ParentID
    [string] $ParentName
    [int]    $ParentTypeID
    [string] $ParentTypeName
    [int]    $ChildID
    [string] $ChildName
    [int]    $ChildTypeID
    [string] $ChildTypeName
    [boolean]$IsSystemMaintained
    [int]    $RelationshipTypeID
    [string] $Description
    [string] $InverseDescription
    [boolean]$IsOperationalDependency
    [string] $CreatedDateUtc
    [guid]   $CreatedUID
    [string] $CreatedFullName

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemRelationship ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItemRelationship ([psobject]$CIRelationship)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemRelationship]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CIRelationship.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CIRelationship.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemRelationship(
        [int]    $ID,
        [int]    $ParentID,
        [string] $ParentName,
        [int]    $ParentTypeID,
        [string] $ParentTypeName,
        [int]    $ChildID,
        [string] $ChildName,
        [int]    $ChildTypeID,
        [string] $ChildTypeName,
        [boolean]$IsSystemMaintained,
        [int]    $RelationshipTypeID,
        [string] $Description,
        [string] $InverseDescription,
        [boolean]$IsOperationalDependency,
        [string] $CreatedDateUtc,
        [guid]   $CreatedUID,
        [string] $CreatedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemRelationship]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Assets_ProductType
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $ParentID
    [string]  $ParentName
    [boolean] $ParentIsActive
    [string]  $Name
    [string]  $Description
    [datetime]$CreatedDate
    [datetime]$ModifiedDate
    [double]  $Order
    [boolean] $IsActive
    [int]     $ProductModelsCount
    [int]     $SubtypesCount
    [TeamDynamix_Api_Assets_ProductType[]]$Subtypes

    # Default constructor
    TeamDynamix_Api_Assets_ProductType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ProductType ([psobject]$ProductType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProductType.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ProductType.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ProductType(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $ParentID,
        [string]  $ParentName,
        [boolean] $ParentIsActive,
        [string]  $Name,
        [string]  $Description,
        [datetime]$CreatedDate,
        [datetime]$ModifiedDate,
        [double]  $Order,
        [boolean] $IsActive,
        [int]     $ProductModelsCount,
        [int]     $SubtypesCount,
        [TeamDynamix_Api_Assets_ProductType[]]$Subtypes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_ProductType(
        [int]    $ParentID,
        [string] $Name,
        [string] $Description,
        [double] $Order,
        [boolean]$IsActive)
    {
        $this.ParentID    = $ParentID
        $this.Name        = $Name
        $this.Description = $Description
        $this.Order       = $Order
        $this.IsActive    = $IsActive
    }
}

class TeamDynamix_Api_Assets_ProductTypeSearch
{
    [string]                  $SearchText
    [System.Nullable[boolean]]$IsActive
    [System.Nullable[boolean]]$IsTopLevel
    [int]                     $ParentProductTypeID

    # Default constructor
    TeamDynamix_Api_Assets_ProductTypeSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ProductTypeSearch ([psobject]$ProductTypeSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProductTypeSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ProductTypeSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ProductTypeSearch(
        [string]                  $SearchText,
        [System.Nullable[boolean]]$IsActive,
        [System.Nullable[boolean]]$IsTopLevel,
        [int]                     $ParentProductTypeID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ProductTypeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Locations_LocationRoom
{
    [int]     $ID
    [string]  $Name
    [string]  $ExternalID
    [string]  $Description
    [string]  $Floor
    [System.Nullable[int]]$Capacity
    [int]     $AssetsCount
    [int]     $ConfigurationItemsCount
    [int]     $TicketsCount
    [int]     $UsersCount
    [datetime]$CreatedDate
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes

    # Default constructor
    TeamDynamix_Api_Locations_LocationRoom ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Locations_LocationRoom ([psobject]$LocationRoom)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_LocationRoom]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $LocationRoom.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $LocationRoom.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Locations_LocationRoom(
        [int]     $ID,
        [string]  $Name,
        [string]  $ExternalID,
        [string]  $Description,
        [string]  $Floor,
        [System.Nullable[int]]$Capacity,
        [int]     $AssetsCount,
        [int]     $ConfigurationItemsCount,
        [int]     $TicketsCount,
        [int]     $UsersCount,
        [datetime]$CreatedDate,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_LocationRoom]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Locations_LocationRoom(
        [string]  $Name,
        [string]  $ExternalID,
        [string]  $Description,
        [string]  $Floor,
        [System.Nullable[int]]$Capacity,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        $this.Name        = $Name
        $this.ExternalID  = $ExternalID
        $this.Description = $Description
        $this.Floor       = $Floor
        $this.Capacity    = $Capacity
        $this.Attributes  = $Attributes
    }

    TeamDynamix_Api_Locations_LocationRoom(
        [string]  $Name)
    {
        $this.Name = $Name
    }

    # Static methods
    Static [psobject[]] GetRoom(
        [int]      $LocationID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDLocation -ID $LocationID -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [psobject[]] GetRoom(
        [int]      $LocationID,
        [int]      $RoomID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDRoom -ID $LocationID -RoomID $RoomID -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [psobject] GetRoom(
        [int]      $LocationID,
        [string]   $RoomName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return ((Get-TDLocation -ID $LocationID -AuthenticationToken $TDAuthentication -Environment $Environment).Rooms | Where-Object Name -eq $RoomName)
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute] GetCustomAttribute(
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'LocationRoom',$AppID,$Environment)
    }
}

class TeamDynamix_Api_Locations_LocationSearch
{
    [string]  $NameLike
    [boolean] $IsActive
    [boolean] $IsRoomRequired
    [System.Nullable[int]]$RoomID
    [boolean] $ReturnItemCounts
    [boolean] $ReturnRooms
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [System.Nullable[int]]$MaxResults

    # Default constructor
    TeamDynamix_Api_Locations_LocationSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Locations_LocationSearch ([psobject]$LocationSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_LocationSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $LocationSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $LocationSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Locations_LocationSearch(
        [string]  $NameLike,
        [boolean] $IsActive,
        [boolean] $IsRoomRequired,
        [System.Nullable[int]]$RoomID,
        [boolean] $ReturnItemCounts,
        [boolean] $ReturnRooms,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [System.Nullable[int]]$MaxResults)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_LocationSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Locations_LocationSearch(
        [string]  $NameLike,
        [boolean] $IsActive,
        [System.Nullable[int]]$MaxResults)
    {
        $this.NameLike   = $NameLike
        $this.IsActive   = $IsActive
        $this.MaxResults = $MaxResults
    }
}

class TeamDynamix_Api_Locations_Location
{
    [int]     $ID
    [string]  $Name
    [string]  $Description
    [string]  $ExternalID
    [boolean] $IsActive
    [string]  $Address
    [string]  $City
    [string]  $State
    [string]  $PostalCode
    [string]  $Country
    [boolean] $IsRoomRequired
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [int]     $AssetsCount
    [int]     $ConfigurationItemsCount
    [int]     $TicketsCount
    [int]     $RoomsCount
    [int]     $UsersCount
    [TeamDynamix_Api_Locations_LocationRoom[]]$Rooms
    [datetime]$CreatedDate
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName
    [System.Nullable[decimal]]$Latitude
    [System.Nullable[decimal]]$Longitude

    # Default constructor
    TeamDynamix_Api_Locations_Location ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Locations_Location ([psobject]$Location)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_Location]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Location.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Location.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Locations_Location(
        [int]     $ID,
        [string]  $Name,
        [string]  $Description,
        [string]  $ExternalID,
        [boolean] $IsActive,
        [string]  $Address,
        [string]  $City,
        [string]  $State,
        [string]  $PostalCode,
        [string]  $Country,
        [boolean] $IsRoomRequired,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [int]     $AssetsCount,
        [int]     $ConfigurationItemsCount,
        [int]     $TicketsCount,
        [int]     $RoomsCount,
        [int]     $UsersCount,
        [TeamDynamix_Api_Locations_LocationRoom[]]$Rooms,
        [datetime]$CreatedDate,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName,
        [System.Nullable[decimal]]$Latitude,
        [System.Nullable[decimal]]$Longitude)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Locations_Location]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Locations_Location(
        [string]  $Name,
        [string]  $Description,
        [string]  $ExternalID,
        [boolean] $IsActive,
        [string]  $Address,
        [string]  $City,
        [string]  $State,
        [string]  $PostalCode,
        [string]  $Country,
        [boolean] $IsRoomRequired,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [System.Nullable[decimal]]$Latitude,
        [System.Nullable[decimal]]$Longitude)
    {
        $this.Name           = $Name
        $this.Description    = $Description
        $this.ExternalID     = $ExternalID
        $this.IsActive       = $IsActive
        $this.Address        = $Address
        $this.City           = $City
        $this.State          = $State
        $this.PostalCode     = $PostalCode
        $this.Country        = $Country
        $this.IsRoomRequired = $IsRoomRequired
        $this.Attributes     = $Attributes
        $this.Latitude       = $Latitude
        $this.Longitude      = $Longitude
    }

    TeamDynamix_Api_Locations_Location(
        [string]  $Name)
    {
        $this.Name     = $Name
        $this.IsActive = $true
    }

    # Static methods
    Static [psobject[]] GetLocation(
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDLocation -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [psobject] GetLocation(
        [int]      $ID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDLocation -ID $ID -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [psobject[]] GetLocation(
        [string]   $Name,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDLocation -NameLike $Name -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute] GetCustomAttribute(
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Location',$AppID,$Environment)
    }
}

class TeamDynamix_Api_KnowledgeBase_Article
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $CategoryID
    [string]  $CategoryName
    [string]  $Subject
    [string]  $Body
    [string]  $Summary
    [TeamDynamix_Api_KnowledgeBase_ArticleStatus]       $Status
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [System.Nullable[datetime]]$ReviewDateUtc
    [double]  $Order
    [boolean] $IsPublished
    [boolean] $IsPublic
    [boolean] $WhitelistGroups
    [boolean] $InheritPermissions
    [boolean] $NotifyOwner
    [int]     $RevisionID
    [int]     $RevisionNumber
    [System.Nullable[TeamDynamix_Api_KnowledgeBase_DraftStatus]]$DraftStatus
    [datetime]$CreatedDate
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName
    [System.Nullable[guid]]$OwnerUid
    [string]               $OwnerFullName
    [System.Nullable[int]] $OwningGroupID
    [string]  $OwningGroupName
    [string[]]$Tags
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [string]  $Uri

    # Default constructor
    TeamDynamix_Api_KnowledgeBase_Article ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_KnowledgeBase_Article ([psobject]$Article)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_Article]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Article.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Article.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_KnowledgeBase_Article(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $CategoryID,
        [string]  $CategoryName,
        [string]  $Subject,
        [string]  $Body,
        [string]  $Summary,
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]       $Status,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [System.Nullable[datetime]]$ReviewDateUtc,
        [double]  $Order,
        [boolean] $IsPublished,
        [boolean] $IsPublic,
        [boolean] $WhitelistGroups,
        [boolean] $InheritPermissions,
        [boolean] $NotifyOwner,
        [int]     $RevisionID,
        [int]     $RevisionNumber,
        [System.Nullable[TeamDynamix_Api_KnowledgeBase_DraftStatus]]$DraftStatus,
        [datetime]$CreatedDate,
        [guid]    $CreatedUid,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUid,
        [string]  $ModifiedFullName,
        [System.Nullable[guid]]$OwnerUid,
        [string]               $OwnerFullName,
        [System.Nullable[int]] $OwningGroupID,
        [string]  $OwningGroupName,
        [string[]]$Tags,
        [TeamDynamix_Api_Attachments_Attachment[]]$Attachments,
        [string]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_Article]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_KnowledgeBase_Article(
        [int]     $CategoryID,
        [string]  $Subject,
        [string]  $Body,
        [string]  $Summary,
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]       $Status,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [System.Nullable[datetime]]$ReviewDateUtc,
        [double]  $Order,
        [boolean] $IsPublished,
        [boolean] $IsPublic,
        [boolean] $WhitelistGroups,
        [boolean] $InheritPermissions,
        [boolean] $NotifyOwner,
        [System.Nullable[guid]]$OwnerUid,
        [System.Nullable[int]] $OwningGroupID,
        [string[]]$Tags)
    {
        $this.CategoryID         = $CategoryID
        $this.Subject            = $Subject
        $this.Body               = $Body
        $this.Summary            = $Summary
        $this.Status             = $Status
        $this.Attributes         = $Attributes
        $this.ReviewDateUtc      = $ReviewDateUtc
        $this.Order              = $Order
        $this.IsPublished        = $IsPublished
        $this.IsPublic           = $IsPublic
        $this.WhitelistGroups    = $WhitelistGroups
        $this.InheritPermissions = $InheritPermissions
        $this.NotifyOwner        = $NotifyOwner
        $this.OwnerUid           = $OwnerUid
        $this.Tags               = $Tags
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'KnowledgeBaseArticle',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    Static [TeamDynamix_Api_KnowledgeBase_Article[]] GetKBArticle (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDKBArticle -AuthenticationToken $TDAuthentication -Environment $Environment)
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'KnowledgeBaseArticle',$AppID,$Environment)
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_KnowledgeBase_Article
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $CategoryID
    [string]  $CategoryName
    [string]  $Subject
    [string]  $Body
    [string]  $Summary
    [TeamDynamix_Api_KnowledgeBase_ArticleStatus]$Status
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $ReviewDateUtc
    [double]  $Order
    [boolean] $IsPublished
    [boolean] $IsPublic
    [boolean] $WhitelistGroups
    [boolean] $InheritPermissions
    [boolean] $NotifyOwner
    [int]     $RevisionID
    [int]     $RevisionNumber
    [System.Nullable[TeamDynamix_Api_KnowledgeBase_DraftStatus]]$DraftStatus
    [string]  $CreatedDate
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [string]  $ModifiedDate
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName
    [guid]    $OwnerUid
    [string]  $OwnerFullName
    [System.Nullable[int]]$OwningGroupID
    [string]  $OwningGroupName
    [string[]]$Tags
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [string]  $Uri

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_KnowledgeBase_Article ([psobject]$Article)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_Article]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Article.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Article.$($Parameter.Name) | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_KnowledgeBase_ArticleSearch
{
    [TeamDynamix_Api_KnowledgeBase_ArticleStatus]       $Status
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [string]                  $SearchText
    [System.Nullable[int]]    $CategoryID
    [System.Nullable[boolean]]$IsPublished
    [System.Nullable[boolean]]$IsPublic
    [System.Nullable[guid]]   $AuthorUID
    [System.Nullable[int]]    $ReturnCount
    [boolean]                 $IncludeArticleBodies
    [boolean]                 $IncludeShortcuts

    # Default constructor
    TeamDynamix_Api_KnowledgeBase_ArticleSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_KnowledgeBase_ArticleSearch ([psobject]$ArticleSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_ArticleSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ArticleSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ArticleSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_KnowledgeBase_ArticleSearch(
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]       $Status,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [string]                  $SearchText,
        [System.Nullable[int]]    $CategoryID,
        [System.Nullable[boolean]]$IsPublished,
        [System.Nullable[boolean]]$IsPublic,
        [System.Nullable[guid]]   $AuthorUID,
        [System.Nullable[int]]    $ReturnCount,
        [boolean]                 $IncludeArticleBodies,
        [boolean]                 $IncludeShortcuts)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_ArticleSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing
{
    [Int32]  $ID
    [String] $Name
    [String] $ShortDescription
    [String] $LongDescription
    [Double] $Order
    [Boolean]$IsActive
    [Guid]   $ManagerUid
    [String] $ManagerFullName
    [Int32]  $ManagingGroupID
    [String] $ManagingGroupName
    [String] $Uri

    # Default constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing ([psobject]$ServiceOfferingListing)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ServiceOfferingListing.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ServiceOfferingListing.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ServiceOfferingListing.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing(
        [Int32]  $ID,
        [String] $Name,
        [String] $ShortDescription,
        [String] $LongDescription,
        [Double] $Order,
        [Boolean]$IsActive,
        [Guid]   $ManagerUid,
        [String] $ManagerFullName,
        [Int32]  $ManagingGroupID,
        [String] $ManagingGroupName,
        [String] $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_ServiceCatalog_Service
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [string]  $Name
    [string]  $ShortDescription
    [string]  $LongDescription
    [int]     $CategoryID
    [string]  $CategoryName
    [string]  $FullCategoryText
    [string]  $CompositeName
    [double]  $Order
    [boolean] $IsActive
    [boolean] $IsPublic
    [datetime]$CreatedDateUtc
    [guid]    $CreatedUID
    [string]  $CreatedFullName
    [datetime]$ModifiedDateUtc
    [guid]    $ModifiedUID
    [string]  $ModifiedFullName
    [guid]    $ManagerUid
    [string]  $ManagerFullName
    [int]     $ManagingGroupID
    [string]  $ManagingGroupName
    [string]  $RequestText
    [string]  $RequestUrl
    [int]     $RequestApplicationID
    [string]  $RequestApplicationName
    [boolean] $RequestApplicationIsActive
    [int]     $RequestTypeID
    [string]  $RequestTypeName
    [boolean] $RequestTypeIsActive
    [TeamDynamix_Api_ServiceCatalog_RequestComponent]$RequestTypeComponent
    [int]     $RequestTypeCategoryID
    [string]  $RequestTypeCategoryName
    [int]     $MaintenanceScheduleID
    [string]  $MaintenanceScheduleName
    [int]     $ConfigurationItemID
    [int]     $ServiceOfferingsCount
    [TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing[]]$ServiceOfferings
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [string]  $Uri
    [string]  $SubmitText
    [int]     $WorkflowID
    [string]  $WorkflowName
    [boolean] $ShouldNotifyResp
    [boolean] $ShouldNotifyRequestor
    [int]     $ConfigurationItemAppID
    [string[]]$Tags

    # Default constructor
    TeamDynamix_Api_ServiceCatalog_Service ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ServiceCatalog_Service ([psobject]$Service)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_Service]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Service.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Service.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ServiceCatalog_Service(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [string]  $Name,
        [string]  $ShortDescription,
        [string]  $LongDescription,
        [int]     $CategoryID,
        [string]  $CategoryName,
        [string]  $FullCategoryText,
        [string]  $CompositeName,
        [double]  $Order,
        [boolean] $IsActive,
        [boolean] $IsPublic,
        [datetime]$CreatedDateUtc,
        [guid]    $CreatedUID,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDateUtc,
        [guid]    $ModifiedUID,
        [string]  $ModifiedFullName,
        [guid]    $ManagerUid,
        [string]  $ManagerFullName,
        [int]     $ManagingGroupID,
        [string]  $ManagingGroupName,
        [string]  $RequestText,
        [string]  $RequestUrl,
        [int]     $RequestApplicationID,
        [string]  $RequestApplicationName,
        [boolean] $RequestApplicationIsActive,
        [int]     $RequestTypeID,
        [string]  $RequestTypeName,
        [boolean] $RequestTypeIsActive,
        [TeamDynamix_Api_ServiceCatalog_RequestComponent]$RequestTypeComponent,
        [int]     $RequestTypeCategoryID,
        [string]  $RequestTypeCategoryName,
        [int]     $MaintenanceScheduleID,
        [string]  $MaintenanceScheduleName,
        [int]     $ConfigurationItemID,
        [int]     $ServiceOfferingsCount,
        [TeamDynamix_Api_ServiceCatalog_ServiceOfferingListing[]]$ServiceOfferings,
        [TeamDynamix_Api_Attachments_Attachment[]]$Attachments,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [string]  $Uri,
        [string]  $SubmitText,
        [int]     $WorkflowID,
        [string]  $WorkflowName,
        [boolean] $ShouldNotifyResp,
        [boolean] $ShouldNotifyRequestor,
        [int]     $ConfigurationItemAppID,
        [string[]]$Tags)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_Service]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Methods
    Static [TeamDynamix_Api_ServiceCatalog_Service[]] GetService (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDService -AuthenticationToken $TDAuthentication -Environment $Environment)
    }
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }

    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Service',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Service Catalog',$AppID,$Environment)
    }
}

class TeamDynamix_Api_KnowledgeBase_ArticleCategory
{
    [int]     $ID
    [int]     $AppID
    [string]  $AppName
    [int]     $ParentID
    [string]  $ParentName
    [double]  $Order
    [string]  $Name
    [string]  $Description
    [boolean] $IsPublic
    [boolean] $WhitelistGroups
    [boolean] $InheritPermissions
    [datetime]$CreatedDate
    [guid]    $CreatedUid
    [string]  $CreatedFullName
    [datetime]$ModifiedDate
    [guid]    $ModifiedUid
    [string]  $ModifiedFullName
    [TeamDynamix_Api_KnowledgeBase_ArticleCategory[]]$Subcategories

    # Default constructor
    TeamDynamix_Api_KnowledgeBase_ArticleCategory ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_KnowledgeBase_ArticleCategory ([psobject]$ArticleCategory)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ArticleCategory.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ArticleCategory.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_KnowledgeBase_ArticleCategory(
        [int]     $ID,
        [int]     $AppID,
        [string]  $AppName,
        [int]     $ParentID,
        [string]  $ParentName,
        [double]  $Order,
        [string]  $Name,
        [string]  $Description,
        [boolean] $IsPublic,
        [boolean] $WhitelistGroups,
        [boolean] $InheritPermissions,
        [datetime]$CreatedDate,
        [guid]    $CreatedUid,
        [string]  $CreatedFullName,
        [datetime]$ModifiedDate,
        [guid]    $ModifiedUid,
        [string]  $ModifiedFullName,
        [TeamDynamix_Api_KnowledgeBase_ArticleCategory[]]$Subcategories)
    {
        foreach ($Parameter in ([TeamDynamix_Api_KnowledgeBase_ArticleCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_KnowledgeBase_ArticleCategory(
        [int]     $ParentID,
        [double]  $Order,
        [string]  $Name,
        [string]  $Description,
        [boolean] $IsPublic,
        [boolean] $WhitelistGroups,
        [boolean] $InheritPermissions)
    {
        $this.ParentID           = $ParentID
        $this.Order              = $Order
        $this.Name               = $Name
        $this.Description        = $Description
        $this.IsPublic           = $IsPublic
        $this.WhitelistGroups    = $WhitelistGroups
        $this.InheritPermissions = $InheritPermissions
    }

    # Methods
    Static [TeamDynamix_Api_KnowledgeBase_ArticleCategory[]] GetCategory (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDKBCategory -AuthenticationToken $TDAuthentication -Environment $Environment)
    }
}

class TeamDynamix_Api_Reporting_ReportInfo
{
    [int]     $ID
    [string]  $Name
    [System.Nullable[guid]]$CreatedUid
    [string]  $CreatedFullName
    [datetime]$CreatedDate
    [System.Nullable[int]]$OwningGroupID
    [string]  $OwningGroupName
    [string]  $SystemAppName
    [int]     $PlatformAppID
    [string]  $PlatformAppName
    [int]     $ReportSourceID
    [string]  $ReportSourceName
    [string]  $Uri

    # Default constructor
    TeamDynamix_Api_Reporting_ReportInfo ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Reporting_ReportInfo ([psobject]$Report)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Reporting_ReportInfo]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Report.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Report.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Reporting_ReportInfo(
        [int]     $ID,
        [string]  $Name,
        [guid]    $CreatedUid,
        [string]  $CreatedFullName,
        [datetime]$CreatedDate,
        [System.Nullable[int]]$OwningGroupID,
        [string]  $OwningGroupName,
        [string]  $SystemAppName,
        [int]     $PlatformAppID,
        [string]  $PlatformAppName,
        [int]     $ReportSourceID,
        [string]  $ReportSourceName,
        [string]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Reporting_ReportInfo]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Reporting_ReportSearch
{
    [System.Nullable[guid]]$OwnerUid
    [System.Nullable[int]] $OwningGroupID
    [string]               $SearchText
    [System.Nullable[int]] $ForAppID
    [string]               $ForApplicationName
    [System.Nullable[int]] $ReportSourceID

    # Default constructor
    TeamDynamix_Api_Reporting_ReportSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Reporting_ReportSearch ([psobject]$ReportSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Reporting_ReportSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ReportSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ReportSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Reporting_ReportSearch(
        [System.Nullable[guid]]$OwnerUid,
        [System.Nullable[int]] $OwningGroupID,
        [string]               $SearchText,
        [System.Nullable[int]] $ForAppID,
        [string]               $ForApplicationName,
        [System.Nullable[int]] $ReportSourceID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Reporting_ReportSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketTask
{
    [Int32]   $ID
    [Int32]   $TicketID
    [String]  $Title
    [String]  $Description
    [Boolean] $IsActive
    [Boolean] $NotifyResponsible
    [System.Nullable[DateTime]]$StartDate
    [System.Nullable[DateTime]]$EndDate
    [System.Nullable[Int32]]$CompleteWithinMinutes
    [Int32]   $EstimatedMinutes
    [Int32]   $ActualMinutes
    [Int32]   $PercentComplete
    [DateTime]$CreatedDate
    [Guid]    $CreatedUid
    [String]  $CreatedFullName
    [String]  $CreatedEmail
    [DateTime]$ModifiedDate
    [Guid]    $ModifiedUid
    [String]  $ModifiedFullName
    [DateTime]$CompletedDate
    [System.Nullable[Guid]]$CompletedUid
    [String]  $CompletedFullName
    [System.Nullable[Guid]]$ResponsibleUid
    [String]  $ResponsibleFullName
    [String]  $ResponsibleEmail
    [Int32]   $ResponsibleGroupID
    [String]  $ResponsibleGroupName
    [Int32]   $PredecessorID
    [String]  $PredecessorTitle
    [Int32]   $Order
    [TeamDynamix_Api_Tickets_TicketTaskType]$TypeID
    [Int32]   $DetectedConflictCount
    [TeamDynamix_Api_Tickets_ConflictType]$DetectedConflictTypes
    [DateTime]$LastConflictScanDateUtc
    [String]  $Uri

    # Default constructor
    TeamDynamix_Api_Tickets_TicketTask ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketTask ([psobject]$TicketTask)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketTask]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketTask.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketTask.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketTask(
        [Int32]   $ID,
        [Int32]   $TicketID,
        [String]  $Title,
        [String]  $Description,
        [Boolean] $IsActive,
        [Boolean] $NotifyResponsible,
        [System.Nullable[DateTime]]$StartDate,
        [System.Nullable[DateTime]]$EndDate,
        [System.Nullable[Int32]]$CompleteWithinMinutes,
        [Int32]   $EstimatedMinutes,
        [Int32]   $ActualMinutes,
        [Int32]   $PercentComplete,
        [DateTime]$CreatedDate,
        [Guid]    $CreatedUid,
        [String]  $CreatedFullName,
        [String]  $CreatedEmail,
        [DateTime]$ModifiedDate,
        [Guid]    $ModifiedUid,
        [String]  $ModifiedFullName,
        [DateTime]$CompletedDate,
        [System.Nullable[Guid]]$CompletedUid,
        [String]  $CompletedFullName,
        [System.Nullable[Guid]]$ResponsibleUid,
        [String]  $ResponsibleFullName,
        [String]  $ResponsibleEmail,
        [Int32]   $ResponsibleGroupID,
        [String]  $ResponsibleGroupName,
        [Int32]   $PredecessorID,
        [String]  $PredecessorTitle,
        [Int32]   $Order,
        [TeamDynamix_Api_Tickets_TicketTaskType]$TypeID,
        [Int32]   $DetectedConflictCount,
        [TeamDynamix_Api_Tickets_ConflictType]$DetectedConflictTypes,
        [DateTime]$LastConflictScanDateUtc,
        [String]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketTask]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Tickets_TicketTask(
        [String]  $Title,
        [String]  $Description,
        [Boolean] $NotifyResponsible,
        [System.Nullable[DateTime]]$StartDate,
        [System.Nullable[DateTime]]$EndDate,
        [System.Nullable[Int32]]$CompleteWithinMinutes,
        [Int32]   $EstimatedMinutes,
        [System.Nullable[Guid]]$ResponsibleUid,
        [Int32]   $ResponsibleGroupID,
        [Int32]   $PredecessorID)
    {
        $this.Title                 = $Title
        $this.Description           = $Description
        $this.NotifyResponsible     = $NotifyResponsible
        $this.StartDate             = $StartDate             | Get-Date
        $this.EndDate               = $EndDate               | Get-Date
        $this.CompleteWithinMinutes = $CompleteWithinMinutes
        $this.EstimatedMinutes      = $EstimatedMinutes
        $this.ResponsibleUid        = $ResponsibleUid
        $this.ResponsibleGroupID    = $ResponsibleGroupID
        $this.PredecessorID         = $PredecessorID
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Tickets_TicketTask
{
    [Int32]   $ID
    [Int32]   $TicketID
    [String]  $Title
    [String]  $Description
    [Boolean] $IsActive
    [string]  $StartDate
    [string]  $EndDate
    [System.Nullable[Int32]]$CompleteWithinMinutes
    [Int32]   $EstimatedMinutes
    [Int32]   $ActualMinutes
    [Int32]   $PercentComplete
    [DateTime]$CreatedDate
    [Guid]    $CreatedUid
    [String]  $CreatedFullName
    [String]  $CreatedEmail
    [DateTime]$ModifiedDate
    [Guid]    $ModifiedUid
    [String]  $ModifiedFullName
    [DateTime]$CompletedDate
    [System.Nullable[Guid]]$CompletedUid
    [String]  $CompletedFullName
    [System.Nullable[Guid]]$ResponsibleUid
    [String]  $ResponsibleFullName
    [String]  $ResponsibleEmail
    [Int32]   $ResponsibleGroupID
    [String]  $ResponsibleGroupName
    [Int32]   $PredecessorID
    [String]  $PredecessorTitle
    [Int32]   $Order
    [TeamDynamix_Api_Tickets_TicketTaskType]$TypeID
    [Int32]   $DetectedConflictCount
    [TeamDynamix_Api_Tickets_ConflictType]$DetectedConflictTypes
    [DateTime]$LastConflictScanDateUtc
    [String]  $Uri

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Tickets_TicketTask ([psobject]$TicketTask)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketTask]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketTask.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketTask.$($Parameter.Name) | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_Ticket
{
    [Int32]   $ID
    [Int32]   $ParentID
    [String]  $ParentTitle
    [TeamDynamix_Api_Tickets_TicketClass]$ParentClass
    [Int32]   $TypeID
    [String]  $TypeName
    [Int32]   $TypeCategoryID
    [String]  $TypeCategoryName
    [TeamDynamix_Api_Tickets_TicketClass]$Classification
    [String]  $ClassificationName
    [Int32]   $FormID
    [String]  $FormName
    [String]  $Title
    [String]  $Description
    [boolean] $IsRichHtml
    [String]  $Uri
    [Int32]   $AccountID
    [String]  $AccountName
    [Int32]   $SourceID
    [String]  $SourceName
    [Int32]   $StatusID
    [String]  $StatusName
    [TeamDynamix_Api_Statuses_StatusClass]$StatusClass
    [Int32]   $ImpactID
    [String]  $ImpactName
    [Int32]   $UrgencyID
    [String]  $UrgencyName
    [Int32]   $PriorityID
    [String]  $PriorityName
    [Double]  $PriorityOrder
    [Int32]   $SlaID
    [String]  $SlaName
    [Boolean] $IsSlaViolated
    [System.Nullable[Boolean]]$IsSlaRespondByViolated
    [System.Nullable[Boolean]]$IsSlaResolveByViolated
    [System.Nullable[DateTime]]$RespondByDate
    [System.Nullable[DateTime]]$ResolveByDate
    [System.Nullable[DateTime]]$SlaBeginDate
    [Boolean] $IsOnHold
    [System.Nullable[DateTime]]$PlacedOnHoldDate
    [System.Nullable[DateTime]]$GoesOffHoldDate
    [DateTime]$CreatedDate
    [Guid]    $CreatedUid
    [String]  $CreatedFullName
    [String]  $CreatedEmail
    [DateTime]$ModifiedDate
    [Guid]    $ModifiedUid
    [String]  $ModifiedFullName
    [String]  $RequestorName
    [String]  $RequestorFirstName
    [String]  $RequestorLastName
    [String]  $RequestorEmail
    [String]  $RequestorPhone
    [System.Nullable[Guid]]$RequestorUid
    [Int32]   $ActualMinutes
    [Int32]   $EstimatedMinutes
    [Int32]   $DaysOld
    [System.Nullable[DateTime]]$StartDate
    [System.Nullable[DateTime]]$EndDate
    [System.Nullable[Guid]]$ResponsibleUid
    [String]  $ResponsibleFullName
    [String]  $ResponsibleEmail
    [Int32]   $ResponsibleGroupID
    [String]  $ResponsibleGroupName
    [DateTime]$RespondedDate
    [System.Nullable[Guid]]$RespondedUid
    [String]  $RespondedFullName
    [DateTime]$CompletedDate
    [System.Nullable[Guid]]$CompletedUid
    [String]  $CompletedFullName
    [System.Nullable[Guid]]$ReviewerUid
    [String]  $ReviewerFullName
    [String]  $ReviewerEmail
    [Int32]   $ReviewingGroupID
    [String]  $ReviewingGroupName
    [Double]  $TimeBudget
    [Double]  $ExpensesBudget
    [Double]  $TimeBudgetUsed
    [Double]  $ExpensesBudgetUsed
    [Boolean] $IsConvertedToTask
    [DateTime]$ConvertedToTaskDate
    [System.Nullable[Guid]]$ConvertedToTaskUid
    [String]  $ConvertedToTaskFullName
    [Int32]   $TaskProjectID
    [String]  $TaskProjectName
    [Int32]   $TaskPlanID
    [String]  $TaskPlanName
    [Int32]   $TaskID
    [String]  $TaskTitle
    [DateTime]$TaskStartDate
    [DateTime]$TaskEndDate
    [Int32]   $TaskPercentComplete
    [Int32]   $LocationID
    [String]  $LocationName
    [Int32]   $LocationRoomID
    [String]  $LocationRoomName
    [String]  $RefCode
    [Int32]   $ServiceID
    [String]  $ServiceName
    [Int32]   $ServiceOfferingID
    [String]  $ServiceOfferingName
    [Int32]   $ServiceCategoryID
    [String]  $ServiceCategoryName
    [Int32]   $ArticleID
    [String]  $ArticleSubject
    [TeamDynamix_Api_KnowledgeBase_ArticleStatus]$ArticleStatus
    [String]  $ArticleCategoryPathNames
    [Int32]   $ArticleAppID
    [System.Nullable[Int32]]$ArticleShortcutID
    [Int32]   $AppID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_Tickets_TicketTask[]]$Tasks
    [TeamDynamix_Api_ResourceItem[]]$Notify
    [Int32]   $WorkflowID
    [Int32]   $WorkflowConfigurationID
    [String]  $WorkflowName

    # Default constructor
    TeamDynamix_Api_Tickets_Ticket ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_Ticket ([psobject]$Ticket)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_Ticket]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Ticket.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Ticket.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_Ticket(
        [Int32]   $ID,
        [Int32]   $ParentID,
        [String]  $ParentTitle,
        [TeamDynamix_Api_Tickets_TicketClass]$ParentClass,
        [Int32]   $TypeID,
        [String]  $TypeName,
        [Int32]   $TypeCategoryID,
        [String]  $TypeCategoryName,
        [TeamDynamix_Api_Tickets_TicketClass]$Classification,
        [String]  $ClassificationName,
        [Int32]   $FormID,
        [String]  $FormName,
        [String]  $Title,
        [String]  $Description,
        [boolean] $IsRichHtml,
        [String]  $Uri,
        [Int32]   $AccountID,
        [String]  $AccountName,
        [Int32]   $SourceID,
        [String]  $SourceName,
        [Int32]   $StatusID,
        [String]  $StatusName,
        [TeamDynamix_Api_Statuses_StatusClass]$StatusClass,
        [Int32]   $ImpactID,
        [String]  $ImpactName,
        [Int32]   $UrgencyID,
        [String]  $UrgencyName,
        [Int32]   $PriorityID,
        [String]  $PriorityName,
        [Double]  $PriorityOrder,
        [Int32]   $SlaID,
        [String]  $SlaName,
        [Boolean] $IsSlaViolated,
        [System.Nullable[Boolean]]$IsSlaRespondByViolated,
        [System.Nullable[Boolean]]$IsSlaResolveByViolated,
        [System.Nullable[DateTime]]$RespondByDate,
        [System.Nullable[DateTime]]$ResolveByDate,
        [System.Nullable[DateTime]]$SlaBeginDate,
        [Boolean] $IsOnHold,
        [System.Nullable[DateTime]]$PlacedOnHoldDate,
        [System.Nullable[DateTime]]$GoesOffHoldDate,
        [DateTime]$CreatedDate,
        [Guid]    $CreatedUid,
        [String]  $CreatedFullName,
        [String]  $CreatedEmail,
        [DateTime]$ModifiedDate,
        [Guid]    $ModifiedUid,
        [String]  $ModifiedFullName,
        [String]  $RequestorName,
        [String]  $RequestorFirstName,
        [String]  $RequestorLastName,
        [String]  $RequestorEmail,
        [String]  $RequestorPhone,
        [System.Nullable[Guid]]$RequestorUid,
        [Int32]   $ActualMinutes,
        [Int32]   $EstimatedMinutes,
        [Int32]   $DaysOld,
        [System.Nullable[DateTime]]$StartDate,
        [System.Nullable[DateTime]]$EndDate,
        [System.Nullable[Guid]]$ResponsibleUid,
        [String]  $ResponsibleFullName,
        [String]  $ResponsibleEmail,
        [Int32]   $ResponsibleGroupID,
        [String]  $ResponsibleGroupName,
        [DateTime]$RespondedDate,
        [System.Nullable[Guid]]$RespondedUid,
        [String]  $RespondedFullName,
        [DateTime]$CompletedDate,
        [System.Nullable[Guid]]$CompletedUid,
        [String]  $CompletedFullName,
        [System.Nullable[Guid]]$ReviewerUid,
        [String]  $ReviewerFullName,
        [String]  $ReviewerEmail,
        [Int32]   $ReviewingGroupID,
        [String]  $ReviewingGroupName,
        [Double]  $TimeBudget,
        [Double]  $ExpensesBudget,
        [Double]  $TimeBudgetUsed,
        [Double]  $ExpensesBudgetUsed,
        [Boolean] $IsConvertedToTask,
        [DateTime]$ConvertedToTaskDate,
        [System.Nullable[Guid]]$ConvertedToTaskUid,
        [String]  $ConvertedToTaskFullName,
        [Int32]   $TaskProjectID,
        [String]  $TaskProjectName,
        [Int32]   $TaskPlanID,
        [String]  $TaskPlanName,
        [Int32]   $TaskID,
        [String]  $TaskTitle,
        [DateTime]$TaskStartDate,
        [DateTime]$TaskEndDate,
        [Int32]   $TaskPercentComplete,
        [Int32]   $LocationID,
        [String]  $LocationName,
        [Int32]   $LocationRoomID,
        [String]  $LocationRoomName,
        [String]  $RefCode,
        [Int32]   $ServiceID,
        [String]  $ServiceName,
        [Int32]   $ServiceOfferingID,
        [String]  $ServiceOfferingName,
        [Int32]   $ServiceCategoryID,
        [String]  $ServiceCategoryName,
        [Int32]   $ArticleID,
        [String]  $ArticleSubject,
        [TeamDynamix_Api_KnowledgeBase_ArticleStatus]$ArticleStatus,
        [String]  $ArticleCategoryPathNames,
        [Int32]   $ArticleAppID,
        [System.Nullable[Int32]]$ArticleShortcutID,
        [Int32]   $AppID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [TeamDynamix_Api_Attachments_Attachment[]]$Attachments,
        [TeamDynamix_Api_Tickets_TicketTask[]]$Tasks,
        [TeamDynamix_Api_ResourceItem[]]$Notify,
        [Int32]   $WorkflowID,
        [Int32]   $WorkflowConfigurationID,
        [String]  $WorkflowName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_Ticket]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Tickets_Ticket(
        [Int32]   $TypeID,
        [Int32]   $FormID,
        [String]  $Title,
        [String]  $Description,
        [Int32]   $AccountID,
        [Int32]   $SourceID,
        [Int32]   $StatusID,
        [Int32]   $ImpactID,
        [Int32]   $UrgencyID,
        [Int32]   $PriorityID,
        [System.Nullable[DateTime]]$GoesOffHoldDate,
        [System.Nullable[Guid]]$RequestorUid,
        [Int32]   $EstimatedMinutes,
        [System.Nullable[DateTime]]$StartDate,
        [System.Nullable[DateTime]]$EndDate,
        [System.Nullable[Guid]]$ResponsibleUid,
        [Int32]   $ResponsibleGroupID,
        [Double]  $TimeBudget,
        [Double]  $ExpensesBudget,
        [Int32]   $LocationID,
        [Int32]   $LocationRoomID,
        [Int32]   $ServiceID,
        [Int32]   $ServiceOfferingID,
        [Int32]   $ArticleID,
        [System.Nullable[Int32]]$ArticleShortcutID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        $this.TypeID             = $TypeID
        $this.FormID             = $FormID
        $this.Title              = $Title
        $this.Description        = $Description
        $this.AccountID          = $AccountID
        $this.SourceID           = $SourceID
        $this.StatusID           = $StatusID
        $this.ImpactID           = $ImpactID
        $this.UrgencyID          = $UrgencyID
        $this.PriorityID         = $PriorityID
        $this.GoesOffHoldDate    = $GoesOffHoldDate    | Get-Date
        $this.RequestorUid       = $RequestorUid
        $this.EstimatedMinutes   = $EstimatedMinutes
        $this.StartDate          = $StartDate          | Get-Date
        $this.EndDate            = $EndDate            | Get-Date
        $this.ResponsibleUid     = $ResponsibleUid
        $this.ResponsibleGroupID = $ResponsibleGroupID
        $this.TimeBudget         = $TimeBudget
        $this.ExpensesBudget     = $ExpensesBudget
        $this.LocationID         = $LocationID
        $this.LocationRoomID     = $LocationRoomID
        $this.ServiceID          = $ServiceID
        $this.ServiceOfferingID  = $ServiceOfferingID
        $this.ArticleID          = $ArticleID
        $this.ArticleShortcutID  = $ArticleShortcutID
        $this.Attributes         = $Attributes
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Ticket',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }

    [void] SetTypeID (
        [string]   $TypeName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.TypeID = (Get-TDTicketType -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $TypeName).ID
    }

    [void] SetLocationID (
        [string]   $LocationName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.LocationID = ([TeamDynamix_Api_Locations_Location]::GetLocation($LocationName,$TDAuthentication,$Environment) | Where-Object Name -eq $LocationName).ID
    }

    [void] SetLocationRoomID (
        [string]   $RoomName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.LocationRoomID = ([TeamDynamix_Api_Locations_LocationRoom]::GetRoom($($this.LocationID),$RoomName,$TDAuthentication,$Environment) | Where-Object Name -eq $RoomName).ID
    }

    [void] SetLocationRoomID (
        [string]   $RoomName,
        [string]   $LocationName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $BuildingID          = ([TeamDynamix_Api_Locations_Location]::GetLocation($LocationName,$TDAuthentication,$Environment)         | Where-Object Name -eq $LocationName).ID
        $this.LocationRoomID = ([TeamDynamix_Api_Locations_LocationRoom]::GetRoom($BuildingID,$RoomName,$TDAuthentication,$Environment) | Where-Object Name -eq $RoomName    ).ID
    }

    [void] SetFormID (
        [string]   $FormName,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.FormID = ([TeamDynamix_Api_Forms_Form]::GetForm($AppID,$TDAuthentication,$Environment) | Where-Object Name -eq $FormName).ID
    }

    [void] SetAccountID (
        [string]   $AccountName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AccountID = (Get-TDAccount -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $AccountName).ID
    }

    [void] SetSourceID (
        [string]   $SourceName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.SourceID = (Get-TDTicketSource -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $SourceName).ID
    }

    [void] SetStatusID (
        [string]   $StatusName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.StatusID = (Get-TDTicketStatus -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $StatusName).ID
    }

    [void] SetImpactID (
        [string]   $ImpactName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.ImpactID = (Get-TDTicketImpact -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $ImpactName).ID
    }

    [void] SetUrgencyID (
        [string]   $UrgencyName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.UrgencyID = (Get-TDTicketUrgency -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $UrgencyName).ID
    }

    [void] SetPriorityID (
        [string]   $PriorityName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.PriorityID = (Get-TDTicketPriority -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $PriorityName).ID
    }

    [void] SetServiceID (
        [string]   $ServiceName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.ServiceID = (Get-TDService -AuthenticationToken $TDAuthentication -Environment $Environment | Where-Object Name -eq $ServiceName).ID
    }

    Static [TeamDynamix_Api_CustomAttributes_CustomAttribute[]] GetCustomAttributes (
        [int]               $AppID,
        [hashtable]         $TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return $script:TDCustomAttributes.GetAll([TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]'Ticket',$AppID,$Environment)
    }

    Static [TeamDynamix_Api_Tickets_Ticket[]] GetTicket (
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        return (Get-TDTicket -AuthenticationToken $TDAuthentication -Environment $Environment)
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Tickets_Ticket
{
    [Int32] $ID
    [Int32] $ParentID
    [String]$ParentTitle
    [TeamDynamix_Api_Tickets_TicketClass]$ParentClass
    [Int32] $TypeID
    [String]$TypeName
    [Int32] $TypeCategoryID
    [String]$TypeCategoryName
    [TeamDynamix_Api_Tickets_TicketClass]$Classification
    [String]$ClassificationName
    [Int32] $FormID
    [String]$FormName
    [String]$Title
    [String]$Description
    [String]$Uri
    [Int32] $AccountID
    [String]$AccountName
    [Int32] $SourceID
    [String]$SourceName
    [Int32] $StatusID
    [String]$StatusName
    [TeamDynamix_Api_Statuses_StatusClass]$StatusClass
    [Int32]  $ImpactID
    [String] $ImpactName
    [Int32]  $UrgencyID
    [String] $UrgencyName
    [Int32]  $PriorityID
    [String] $PriorityName
    [Double] $PriorityOrder
    [Int32]  $SlaID
    [String] $SlaName
    [Boolean]$IsSlaViolated
    [System.Nullable[Boolean]]$IsSlaRespondByViolated
    [System.Nullable[Boolean]]$IsSlaResolveByViolated
    [string] $RespondByDate
    [string] $ResolveByDate
    [string] $SlaBeginDate
    [Boolean]$IsOnHold
    [string] $PlacedOnHoldDate
    [string] $GoesOffHoldDate
    [string] $CreatedDate
    [Guid]   $CreatedUid
    [String] $CreatedFullName
    [String] $CreatedEmail
    [string] $ModifiedDate
    [Guid]   $ModifiedUid
    [String] $ModifiedFullName
    [String] $RequestorName
    [String] $RequestorFirstName
    [String] $RequestorLastName
    [String] $RequestorEmail
    [String] $RequestorPhone
    [System.Nullable[Guid]]$RequestorUid
    [Int32]  $ActualMinutes
    [Int32]  $EstimatedMinutes
    [Int32]  $DaysOld
    [string] $StartDate
    [string] $EndDate
    [Guid]   $ResponsibleUid
    [String] $ResponsibleFullName
    [String] $ResponsibleEmail
    [Int32]  $ResponsibleGroupID
    [String] $ResponsibleGroupName
    [string] $RespondedDate
    [System.Nullable[Guid]]$RespondedUid
    [String] $RespondedFullName
    [string]$CompletedDate
    [System.Nullable[Guid]]$CompletedUid
    [String] $CompletedFullName
    [System.Nullable[Guid]]$ReviewerUid
    [String] $ReviewerFullName
    [String] $ReviewerEmail
    [Int32]  $ReviewingGroupID
    [String] $ReviewingGroupName
    [Double] $TimeBudget
    [Double] $ExpensesBudget
    [Double] $TimeBudgetUsed
    [Double] $ExpensesBudgetUsed
    [Boolean]$IsConvertedToTask
    [string] $ConvertedToTaskDate
    [System.Nullable[Guid]]$ConvertedToTaskUid
    [String] $ConvertedToTaskFullName
    [Int32]  $TaskProjectID
    [String] $TaskProjectName
    [Int32]  $TaskPlanID
    [String] $TaskPlanName
    [Int32]  $TaskID
    [String] $TaskTitle
    [string] $TaskStartDate
    [string] $TaskEndDate
    [Int32]  $TaskPercentComplete
    [Int32]  $LocationID
    [String] $LocationName
    [Int32]  $LocationRoomID
    [String] $LocationRoomName
    [String] $RefCode
    [Int32]  $ServiceID
    [String] $ServiceName
    [Int32]  $ServiceOfferingID
    [String] $ServiceOfferingName
    [Int32]  $ServiceCategoryID
    [String] $ServiceCategoryName
    [Int32]  $ArticleID
    [String] $ArticleSubject
    [TeamDynamix_Api_KnowledgeBase_ArticleStatus]$ArticleStatus
    [String] $ArticleCategoryPathNames
    [Int32]  $ArticleAppID
    [System.Nullable[Int32]]$ArticleShortcutID
    [Int32]  $AppID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_Tickets_TicketTask[]]$Tasks
    [TeamDynamix_Api_ResourceItem[]]$Notify
    [Int32]  $WorkflowID
    [Int32]  $WorkflowConfigurationID
    [String] $WorkflowName

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Tickets_Ticket ([psobject]$Ticket)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_Ticket]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Ticket.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Ticket.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Ticket.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketSearch
{
    [TeamDynamix_Api_Tickets_TicketClass[]]$TicketClassification
    [Int32]  $MaxResults
    [System.Nullable[Int32]]$TicketID
    [System.Nullable[Int32]]$ParentTicketID
    [String] $SearchText
    [Int32[]]$FormIDs
    [Int32[]]$StatusIDs
    [Int32[]]$PastStatusIDs
    [Int32[]]$StatusClassIDs
    [Int32[]]$PriorityIDs
    [Int32[]]$UrgencyIDs
    [Int32[]]$ImpactIDs
    [Int32[]]$AccountIDs
    [Int32[]]$TypeIDs
    [Int32[]]$SourceIDs
    [System.Nullable[DateTime]]$UpdatedDateFrom
    [System.Nullable[DateTime]]$UpdatedDateTo
    [System.Nullable[Guid]]$UpdatedByUid
    [System.Nullable[DateTime]]$ModifiedDateFrom
    [System.Nullable[DateTime]]$ModifiedDateTo
    [System.Nullable[Guid]]$ModifiedByUid
    [System.Nullable[DateTime]]$StartDateFrom
    [System.Nullable[DateTime]]$StartDateTo
    [System.Nullable[DateTime]]$EndDateFrom
    [System.Nullable[DateTime]]$EndDateTo
    [System.Nullable[DateTime]]$RespondedDateFrom
    [System.Nullable[DateTime]]$RespondedDateTo
    [System.Nullable[Guid]]$RespondedByUid
    [System.Nullable[DateTime]]$ClosedDateFrom
    [System.Nullable[DateTime]]$ClosedDateTo
    [System.Nullable[Guid]]$ClosedByUid
    [System.Nullable[DateTime]]$RespondByDateFrom
    [System.Nullable[DateTime]]$RespondByDateTo
    [System.Nullable[DateTime]]$CloseByDateFrom
    [System.Nullable[DateTime]]$CloseByDateTo
    [System.Nullable[DateTime]]$CreatedDateFrom
    [System.Nullable[DateTime]]$CreatedDateTo
    [System.Nullable[Guid]]$CreatedByUid
    [System.Nullable[Int32]]$DaysOldFrom
    [System.Nullable[Int32]]$DaysOldTo
    [Guid[]] $ResponsibilityUids
    [Int32[]]$ResponsibilityGroupIDs
    [System.Nullable[Boolean]]$CompletedTaskResponsibilityFilter
    [Guid[]] $PrimaryResponsibilityUids
    [Int32[]]$PrimaryResponsibilityGroupIDs
    [Int32[]]$SlaIDs
    [System.Nullable[Boolean]]$SlaViolationStatus
    [TeamDynamix_Api_Tickets_UnmetConstraintSearchType]$SlaUnmetConstraints
    [Int32[]]$KBArticleIDs
    [System.Nullable[Boolean]]$AssignmentStatus
    [System.Nullable[Boolean]]$ConvertedToTask
    [System.Nullable[Guid]]$ReviewerUid
    [Guid[]] $RequestorUids
    [String] $RequestorNameSearch
    [String] $RequestorEmailSearch
    [String] $RequestorPhoneSearch
    [Int32[]]$ConfigurationItemIDs
    [Int32[]]$ExcludeConfigurationItemIDs
    [System.Nullable[Boolean]]$IsOnHold
    [System.Nullable[DateTime]]$GoesOffHoldFrom
    [System.Nullable[DateTime]]$GoesOffHoldTo
    [Int32[]]$LocationIDs
    [Int32[]]$LocationRoomIDs
    [Int32[]]$ServiceIDs
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [System.Nullable[Boolean]]$HasReferenceCode

    # Default constructor
    TeamDynamix_Api_Tickets_TicketSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketSearch ([psobject]$TicketSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketSearch(
        [TeamDynamix_Api_Tickets_TicketClass[]]$TicketClassification,
        [Int32]  $MaxResults,
        [System.Nullable[Int32]]$TicketID,
        [System.Nullable[Int32]]$ParentTicketID,
        [String] $SearchText,
        [Int32[]]$FomrIDs,
        [Int32[]]$StatusIDs,
        [Int32[]]$PastStatusIDs,
        [Int32[]]$StatusClassIDs,
        [Int32[]]$PriorityIDs,
        [Int32[]]$UrgencyIDs,
        [Int32[]]$ImpactIDs,
        [Int32[]]$AccountIDs,
        [Int32[]]$TypeIDs,
        [Int32[]]$SourceIDs,
        [System.Nullable[DateTime]]$UpdatedDateFrom,
        [System.Nullable[DateTime]]$UpdatedDateTo,
        [System.Nullable[Guid]]$UpdatedByUid,
        [System.Nullable[DateTime]]$ModifiedDateFrom,
        [System.Nullable[DateTime]]$ModifiedDateTo,
        [System.Nullable[Guid]]$ModifiedByUid,
        [System.Nullable[DateTime]]$StartDateFrom,
        [System.Nullable[DateTime]]$StartDateTo,
        [System.Nullable[DateTime]]$EndDateFrom,
        [System.Nullable[DateTime]]$EndDateTo,
        [System.Nullable[DateTime]]$RespondedDateFrom,
        [System.Nullable[DateTime]]$RespondedDateTo,
        [System.Nullable[Guid]]$RespondedByUid,
        [System.Nullable[DateTime]]$ClosedDateFrom,
        [System.Nullable[DateTime]]$ClosedDateTo,
        [System.Nullable[Guid]]$ClosedByUid,
        [System.Nullable[DateTime]]$RespondByDateFrom,
        [System.Nullable[DateTime]]$RespondByDateTo,
        [System.Nullable[DateTime]]$CloseByDateFrom,
        [System.Nullable[DateTime]]$CloseByDateTo,
        [System.Nullable[DateTime]]$CreatedDateFrom,
        [System.Nullable[DateTime]]$CreatedDateTo,
        [System.Nullable[Guid]]$CreatedByUid,
        [System.Nullable[Int32]]$DaysOldFrom,
        [System.Nullable[Int32]]$DaysOldTo,
        [Guid[]] $ResponsibilityUids,
        [Int32[]]$ResponsibilityGroupIDs,
        [System.Nullable[Boolean]]$CompletedTaskResponsibilityFilter,
        [Guid[]] $PrimaryResponsibilityUids,
        [Int32[]]$PrimaryResponsibilityGroupIDs,
        [Int32[]]$SlaIDs,
        [System.Nullable[Boolean]]$SlaViolationStatus,
        [TeamDynamix_Api_Tickets_UnmetConstraintSearchType]$SlaUnmetConstraints,
        [Int32[]]$KBArticleIDs,
        [System.Nullable[Boolean]]$AssignmentStatus,
        [System.Nullable[Boolean]]$ConvertedToTask,
        [System.Nullable[Guid]]$ReviewerUid,
        [Guid[]] $RequestorUids,
        [String] $RequestorNameSearch,
        [String] $RequestorEmailSearch,
        [String] $RequestorPhoneSearch,
        [Int32[]]$ConfigurationItemIDs,
        [Int32[]]$ExcludeConfigurationItemIDs,
        [System.Nullable[Boolean]]$IsOnHold,
        [System.Nullable[DateTime]]$GoesOffHoldFrom,
        [System.Nullable[DateTime]]$GoesOffHoldTo,
        [Int32[]] $LocationIDs,
        [Int32[]] $LocationRoomIDs,
        [Int32[]] $ServiceIDs,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [System.Nullable[Boolean]]$HasReferenceCode)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Tickets_TicketSearch
{
    [TeamDynamix_Api_Tickets_TicketClass[]]$TicketClassification
    [Int32]  $MaxResults
    [System.Nullable[Int32]]$TicketID
    [System.Nullable[Int32]]$ParentTicketID
    [String] $SearchText
    [Int32[]]$FormIDs
    [Int32[]]$StatusIDs
    [Int32[]]$PastStatusIDs
    [Int32[]]$StatusClassIDs
    [Int32[]]$PriorityIDs
    [Int32[]]$UrgencyIDs
    [Int32[]]$ImpactIDs
    [Int32[]]$AccountIDs
    [Int32[]]$TypeIDs
    [Int32[]]$SourceIDs
    [string] $UpdatedDateFrom
    [string] $UpdatedDateTo
    [System.Nullable[Guid]]$UpdatedByUid
    [string] $ModifiedDateFrom
    [string] $ModifiedDateTo
    [System.Nullable[Guid]]$ModifiedByUid
    [string] $StartDateFrom
    [string] $StartDateTo
    [string] $EndDateFrom
    [string] $EndDateTo
    [string] $RespondedDateFrom
    [string] $RespondedDateTo
    [System.Nullable[Guid]]$RespondedByUid
    [string] $ClosedDateFrom
    [string] $ClosedDateTo
    [System.Nullable[Guid]]$ClosedByUid
    [string] $RespondByDateFrom
    [string] $RespondByDateTo
    [string] $CloseByDateFrom
    [string] $CloseByDateTo
    [string] $CreatedDateFrom
    [string] $CreatedDateTo
    [System.Nullable[Guid]]$CreatedByUid
    [System.Nullable[Int32]]$DaysOldFrom
    [System.Nullable[Int32]]$DaysOldTo
    [Guid[]] $ResponsibilityUids
    [Int32[]]$ResponsibilityGroupIDs
    [System.Nullable[Boolean]]$CompletedTaskResponsibilityFilter
    [Guid[]] $PrimaryResponsibilityUids
    [Int32[]]$PrimaryResponsibilityGroupIDs
    [Int32[]]$SlaIDs
    [System.Nullable[Boolean]]$SlaViolationStatus
    [TeamDynamix_Api_Tickets_UnmetConstraintSearchType]$SlaUnmetConstraints
    [Int32[]]$KBArticleIDs
    [System.Nullable[Boolean]]$AssignmentStatus
    [System.Nullable[Boolean]]$ConvertedToTask
    [System.Nullable[Guid]]$ReviewerUid
    [Guid[]] $RequestorUids
    [String] $RequestorNameSearch
    [String] $RequestorEmailSearch
    [String] $RequestorPhoneSearch
    [Int32[]]$ConfigurationItemIDs
    [Int32[]]$ExcludeConfigurationItemIDs
    [System.Nullable[Boolean]]$IsOnHold
    [string]$GoesOffHoldFrom
    [string]$GoesOffHoldTo
    [Int32[]]$LocationIDs
    [Int32[]]$LocationRoomIDs
    [Int32[]]$ServiceIDs
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [System.Nullable[Boolean]]$HasReferenceCode

    # Constructor from object
    TD_TeamDynamix_Api_Tickets_TicketSearch ([psobject]$TicketSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketCreateOptions
{
    [Boolean]$EnableNotifyReviewer
    [Boolean]$NotifyRequestor
    [Boolean]$NotifyResponsible
    [Boolean]$AllowRequestorCreation

    # Default constructor
    TeamDynamix_Api_Tickets_TicketCreateOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketCreateOptions ([psobject]$TicketCreateOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketCreateOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketCreateOptions.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketCreateOptions.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketCreateOptions(
        [Boolean]$EnableNotifyReviewer,
        [Boolean]$NotifyRequestor,
        [Boolean]$NotifyResponsible,
        [Boolean]$AllowRequestorCreation)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketCreateOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketStatus
{
    [Int32]   $ID
    [Int32]   $AppID
    [String]  $AppName
    [String]  $Name
    [String]  $Description
    [Double]  $Order
    [TeamDynamix_Api_Statuses_StatusClass]$StatusClass
    [Boolean] $IsActive
    [Boolean] $RequireGoesOffHold
    [Boolean] $DoNotReopen
    [Boolean] $IsDefault

    # Default constructor
    TeamDynamix_Api_Tickets_TicketStatus ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketStatus ([psobject]$TicketStatus)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketStatus]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketStatus.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketStatus.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketStatus(
        [Int32]   $ID,
        [Int32]   $AppID,
        [String]  $AppName,
        [String]  $Name,
        [String]  $Description,
        [Double]  $Order,
        [TeamDynamix_Api_Statuses_StatusClass]$StatusClass,
        [Boolean] $IsActive,
        [Boolean] $RequireGoesOffHold,
        [Boolean] $DoNotReopen,
        [Boolean] $IsDefault)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketStatus]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Tickets_TicketStatus(
        [String]  $Name,
        [String]  $Description,
        [Double]  $Order,
        [TeamDynamix_Api_Statuses_StatusClass]$StatusClass,
        [Boolean] $IsActive,
        [Boolean] $RequiresGoesOffHold,
        [Boolean] $DoNotReopen)
    {
        $this.Name        = $Name
        $this.Description = $Description
        $this.Order       = $Order
        $this.StatusClass = $StatusClass
        $this.IsActive    = $IsActive
    }
}

class TeamDynamix_Api_Tickets_TicketStatusSearch
{
    [String]                  $SearchText
    [System.Nullable[Boolean]]$IsActive
    [System.Nullable[Boolean]]$IsDefault
    [System.Nullable[Int32]]  $StatusClass
    [System.Nullable[Boolean]]$RequiresGoesOffHold

    # Default constructor
    TeamDynamix_Api_Tickets_TicketStatusSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketStatusSearch ([psobject]$TicketStatusSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketStatusSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketStatusSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketStatusSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketStatusSearch(
        [String]                  $SearchText,
        [System.Nullable[Boolean]]$IsActive,
        [System.Nullable[Boolean]]$IsDefault,
        [System.Nullable[Int32]]  $StatusClass,
        [System.Nullable[Boolean]]$RequiresGoesOffHold)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketStatusSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketType
{
    [Int32]   $ID
    [Int32]   $AppID
    [String]  $AppName
    [String]  $Name
    [String]  $Description
    [Int32]   $CategoryID
    [String]  $CategoryName
    [String]  $FullName
    [Boolean] $IsActive
    [DateTime]$CreatedDate
    [System.Nullable[Guid]]$CreatedByUid
    [DateTime]$ModifiedDate
    [System.Nullable[Guid]]$ModifiedByUid
    [System.Nullable[Guid]]$ReviewerUid
    [String]  $ReviewerFullName
    [String]  $ReviewerEmail
    [Int32]   $ReviewingGroupID
    [String]  $ReviewingGroupName
    [Boolean] $NotifyReviewer
    [String]  $OtherNotificationEmailAddresses
    [Int32]   $DefaultSLAID
    [String]  $DefaultSLAName
    [Boolean] $DefaultSLAIsActive
    [Int32]   $WorkspaceID
    [String]  $WorkspaceName
    [Boolean] $ShouldAlertResponsibleOnTaskClose

    # Default constructor
    TeamDynamix_Api_Tickets_TicketType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketType ([psobject]$TicketType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketType.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketType.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketType(
        [Int32]   $ID,
        [Int32]   $AppID,
        [String]  $AppName,
        [String]  $Name,
        [String]  $Description,
        [Int32]   $CategoryID,
        [String]  $CategoryName,
        [String]  $FullName,
        [Boolean] $IsActive,
        [DateTime]$CreatedDate,
        [System.Nullable[Guid]]$CreatedByUid,
        [DateTime]$ModifiedDate,
        [System.Nullable[Guid]]$ModifiedByUid,
        [System.Nullable[Guid]]$ReviewerUid,
        [String]  $ReviewerFullName,
        [String]  $ReviewerEmail,
        [Int32]   $ReviewingGroupID,
        [String]  $ReviewingGroupName,
        [Boolean] $NotifyReviewer,
        [String]  $OtherNotificationEmailAddresses,
        [Int32]   $DefaultSLAID,
        [String]  $DefaultSLAName,
        [Boolean] $DefaultSLAIsActive,
        [Int32]   $WorkspaceID,
        [String]  $WorkspaceName,
        [Boolean] $ShouldAlertResponsibleOnTaskClose)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketSource
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Boolean] $IsActive

    # Default constructor
    TeamDynamix_Api_Tickets_TicketSource ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketSource ([psobject]$TicketSource)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketSource.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketSource.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketSource(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Boolean] $IsActive)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest
{
    [Guid]  $StepID
    [String]$ActionID
    [String]$Comments

    # Default constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest ([psobject]$TicketWorkflowStepApproveRequest)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStepApproveRequest.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStepApproveRequest.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStepApproveRequest.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest(
        [Guid]  $StepID,
        [String]$ActionID,
        [String]$Comments)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepApproveRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage
{
    [Guid[]]  $StepIDs
    [String]  $Message
    [String[]]$MemberNames

    # Default constructor
    TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage ([psobject]$WorkflowValidationMessage)
    {
        foreach ($Parameter in ([TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $WorkflowValidationMessage.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $WorkflowValidationMessage.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $WorkflowValidationMessage.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage(
        [Guid[]]  $StepIDs,
        [String]  $Message,
        [String[]]$MemberNames)
    {
        foreach ($Parameter in ([TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult
{
    [Boolean]$IsSuccessful
    [String] $Message
    [TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage[]]$Errors
    [Boolean]$WasWorkflowUpdated

    # Default constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult ([psobject]$TicketWorkflowStepActionResult)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStepActionResult.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStepActionResult.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStepActionResult.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult(
        [Boolean]$IsSuccessful,
        [String] $Message,
        [TeamDynamix_Api_WorkflowEngine_WorkflowValidationMessage[]]$Errors,
        [Boolean]$WasWorkflowUpdated)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepActionResult]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction
{
    [String]$ID
    [String]$Name
    [String]$Tooltip

    # Default constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction ([psobject]$TicketWorkflowStepAction)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStepAction.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStepAction.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStepAction.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction(
        [String]$ID,
        [String]$Name,
        [String]$Tooltip)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepAction]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_WorkflowEngine_HistoryEntry
{
    [Int32]   $ID
    [Guid]    $StepID
    [DateTime]$ActionDateUtc
    [Guid]    $PersonUid
    [Int32]   $PersonRefID
    [String]  $PersonFirstName
    [String]  $PersonLastName
    [String]  $PersonFullName
    [String]  $PersonProfileImageFileName
    [String]  $ActionID
    [String]  $ActionName
    [TeamDynamix_Api_WorkflowEngine_WorkflowAdvancement]$Context
    [String]  $Comments
    [Boolean] $IsStepComplete

    # Default constructor
    TeamDynamix_Api_WorkflowEngine_HistoryEntry ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_WorkflowEngine_HistoryEntry ([psobject]$HistoryEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_WorkflowEngine_HistoryEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_WorkflowEngine_HistoryEntry(
        [Int32]   $ID,
        [Guid]    $StepID,
        [DateTime]$ActionDateUtc,
        [Guid]    $PersonUid,
        [Int32]   $PersonRefID,
        [String]  $PersonFirstName,
        [String]  $PersonLastName,
        [String]  $PersonFullName,
        [String]  $PersonProfileImageFileName,
        [String]  $ActionID,
        [String]  $ActionName,
        [TeamDynamix_Api_WorkflowEngine_WorkflowAdvancement]$Context,
        [String]  $Comments,
        [Boolean] $IsStepComplete)
    {
        foreach ($Parameter in ([TeamDynamix_Api_WorkflowEngine_HistoryEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_WorkflowEngine_HistoryEntry
{
    [Int32]  $ID
    [Guid]   $StepID
    [String] $ActionDateUtc
    [Guid]   $PersonUid
    [Int32]  $PersonRefID
    [String] $PersonFirstName
    [String] $PersonLastName
    [String] $PersonFullName
    [String] $PersonProfileImageFileName
    [String] $ActionID
    [String] $ActionName
    [TeamDynamix_Api_WorkflowEngine_WorkflowAdvancement]$Context
    [String] $Comments
    [Boolean]$IsStepComplete

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_WorkflowEngine_HistoryEntry ([psobject]$HistoryEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_WorkflowEngine_HistoryEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $HistoryEntry.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep
{
    [String]  $Name
    [Guid]    $ID
    [String]  $TypeName
    [String]  $TypeDescription
    [String]  $Description
    [Int32]   $StageID
    [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History
    [DateTime]$StartDateTime
    [Boolean] $IsCurrent

    # Default constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep ([psobject]$TicketWorkflowStep)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep(
        [String]  $Name,
        [Guid]    $ID,
        [String]  $TypeName,
        [String]  $TypeDescription,
        [String]  $Description,
        [Int32]   $StageID,
        [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History,
        [DateTime]$StartDateTime,
        [Boolean] $IsCurrent)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep
{
    [String] $Name
    [Guid]   $ID
    [String] $TypeName
    [String] $TypeDescription
    [String] $Description
    [Int32]  $StageID
    [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History
    [String] $StartDateTime
    [Boolean]$IsCurrent

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep ([psobject]$TicketWorkflowStep)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStep.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketWorkflow
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Int32]   $TicketId
    [Int32]   $WorkflowConfigurationID
    [Guid]    $BeginStepID
    [Guid[]]  $CurrentStepIDs
    [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep[]]$Steps
    [TeamDynamix_Api_WorkflowEngine_WorkflowStatus]$Status
    [Boolean] $IsComplete
    [DateTime]$CreatedDateUtc
    [DateTime]$StartDateUtc
    [System.Nullable[DateTime]]$CompletedDateUtc
    [Guid]    $FinalApprovalStepID
    [Guid]    $FinalRejectionStepID
    [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History
    [Boolean] $NotifyRequestor
    [Boolean] $NotifyReviewer

    # Default constructor
    TeamDynamix_Api_Tickets_TicketWorkflow ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketWorkflow ([psobject]$TicketWorkflow)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketWorkflow]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketWorkflow(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Int32]   $TicketId,
        [Int32]   $WorkflowConfigurationID,
        [Guid]    $BeginStepID,
        [Guid[]]  $CurrentStepIDs,
        [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep[]]$Steps,
        [TeamDynamix_Api_WorkflowEngine_WorkflowStatus]$Status,
        [Boolean] $IsComplete,
        [DateTime]$CreatedDateUtc,
        [DateTime]$StartDateUtc,
        [System.Nullable[DateTime]]$CompletedDateUtc,
        [Guid]    $FinalApprovalStepID,
        [Guid]    $FinalRejectionStepID,
        [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History,
        [Boolean] $NotifyRequestor,
        [Boolean] $NotifyReviewer)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketWorkflow]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Tickets_TicketWorkflow
{
    [Int32]  $ID
    [String] $Name
    [String] $Description
    [Int32]  $TicketId
    [Int32]  $WorkflowConfigurationID
    [Guid]   $BeginStepID
    [Guid[]] $CurrentStepIDs
    [TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStep[]]$Steps
    [TeamDynamix_Api_WorkflowEngine_WorkflowStatus]$Status
    [Boolean]$IsComplete
    [String] $CreatedDateUtc
    [String] $StartDateUtc
    [String] $CompletedDateUtc
    [Guid]   $FinalApprovalStepID
    [Guid]   $FinalRejectionStepID
    [TeamDynamix_Api_WorkflowEngine_HistoryEntry[]]$History

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Tickets_TicketWorkflow ([psobject]$TicketWorkflow)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketWorkflow]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflow.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest
{
    [Guid] $StepID
    [System.Nullable[Guid]] $UserId
    [System.Nullable[Int32]]$GroupId

    # Default constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest ([psobject]$TicketWorkflowStepReassignRequest)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketWorkflowStepReassignRequest.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketWorkflowStepReassignRequest.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketWorkflowStepReassignRequest.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest(
        [Guid] $StepID,
        [System.Nullable[Guid]] $UserId,
        [System.Nullable[Int32]]$GroupId)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_WorkflowSteps_TicketWorkflowStepReassignRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_PriorityFactors_Impact
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Double]  $Order
    [Boolean] $IsActive
    [Boolean] $IsDefault

    # Default constructor
    TeamDynamix_Api_PriorityFactors_Impact ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_PriorityFactors_Impact ([psobject]$Impact)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Impact]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Impact.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Impact.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_PriorityFactors_Impact(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Double]  $Order,
        [Boolean] $IsActive,
        [Boolean] $IsDefault)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Impact]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_PriorityFactors_Priority
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Double]  $Order
    [Boolean] $IsActive
    [Boolean] $IsDefault

    # Default constructor
    TeamDynamix_Api_PriorityFactors_Priority ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_PriorityFactors_Priority ([psobject]$Priority)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Priority]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Priority.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Priority.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_PriorityFactors_Priority(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Double]  $Order,
        [Boolean] $IsActive,
        [Boolean] $IsDefault)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Priority]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_PriorityFactors_Urgency
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Double]  $Order
    [Boolean] $IsActive
    [Boolean] $IsDefault

    # Default constructor
    TeamDynamix_Api_PriorityFactors_Urgency ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_PriorityFactors_Urgency ([psobject]$Urgency)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Urgency]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Urgency.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Urgency.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_PriorityFactors_Urgency(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Double]  $Order,
        [Boolean] $IsActive,
        [Boolean] $IsDefault)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PriorityFactors_Urgency]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_TicketFeedEntry
{
    [System.Nullable[Int32]]$NewStatusID
    [Boolean] $CascadeStatus
    [String]  $Comments
    [String[]]$Notify
    [Boolean] $IsPrivate
    [boolean] $IsRichHtml

    # Default constructor
    TeamDynamix_Api_Feed_TicketFeedEntry ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_TicketFeedEntry ([psobject]$TicketFeedEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_TicketFeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketFeedEntry.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketFeedEntry.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_TicketFeedEntry(
        [System.Nullable[Int32]]$NewStatusID,
        [Boolean] $CascadeStatus,
        [String]  $Comments,
        [String[]]$Notify,
        [Boolean] $IsPrivate,
        [boolean] $IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_TicketFeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Cmdb_BlackoutWindow
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Int32]   $TimeZoneID
    [String]  $TimeZoneName
    [Boolean] $IsActive
    [DateTime]$CreatedDateUtc
    [Guid]    $CreatedUid
    [String]  $CreatedFullName
    [DateTime]$ModifiedDateUtc
    [Guid]    $ModifiedUid
    [String]  $ModifiedFullName

    # Default constructor
    TeamDynamix_Api_Cmdb_BlackoutWindow ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_BlackoutWindow ([psobject]$BlackoutWindow)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_BlackoutWindow]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $BlackoutWindow.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $BlackoutWindow.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_BlackoutWindow(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Int32]   $TimeZoneID,
        [String]  $TimeZoneName,
        [Boolean] $IsActive,
        [DateTime]$CreatedDateUtc,
        [Guid]    $CreatedUid,
        [String]  $CreatedFullName,
        [DateTime]$ModifiedDateUtc,
        [Guid]    $ModifiedUid,
        [String]  $ModifiedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_BlackoutWindow]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Cmdb_BlackoutWindow(
        [String]  $Name,
        [String]  $Description,
        [Int32]   $TimeZoneID,
        [Boolean] $IsActive)
    {
        $this.Name        = $Name
        $this.Description = $Description
        $this.TimeZoneID  = $TimeZoneID
        $this.IsActive    = $IsActive
    }
}

class TeamDynamix_Api_Cmdb_BlackoutWindowSearch
{
    [System.Nullable[Boolean]]$IsActive
    [String]                  $NameLike

    # Default constructor
    TeamDynamix_Api_Cmdb_BlackoutWindowSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_BlackoutWindowSearch ([psobject]$BlackoutWindowSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_BlackoutWindowSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $BlackoutWindowSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $BlackoutWindowSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_BlackoutWindowSearch(
        [System.Nullable[Boolean]]$IsActive,
        [String]                  $NameLike)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_BlackoutWindowSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_SavedSearches_SavedSearch
{
    [Int32] $ID
    [String]$Name
    [String]$Application
    [Int32] $AppID
    [String]$AppName
    [Int32] $ComponentID
    [String]$ComponentName
    [Double]$ComponentOrder
    [Guid]  $CreatedUID
    [String]$CreatedFullName

    # Default constructor
    TeamDynamix_Api_SavedSearches_SavedSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_SavedSearches_SavedSearch ([psobject]$SavedSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_SavedSearches_SavedSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $SavedSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $SavedSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_SavedSearches_SavedSearch(
        [Int32] $ID,
        [String]$Name,
        [String]$Application,
        [Int32] $AppID,
        [String]$AppName,
        [Int32] $ComponentID,
        [String]$ComponentName,
        [Double]$ComponentOrder,
        [Guid]  $CreatedUID,
        [String]$CreatedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_SavedSearches_SavedSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_RequestPage
{
    [Int32]$PageIndex
    [Int32]$PageSize

    # Default constructor
    TeamDynamix_Api_RequestPage ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_RequestPage ([psobject]$RequestPage)
    {
        foreach ($Parameter in ([TeamDynamix_Api_RequestPage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $RequestPage.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $RequestPage.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_RequestPage(
        [Int32]$PageIndex,
        [Int32]$PageSize)
    {
        foreach ($Parameter in ([TeamDynamix_Api_RequestPage]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketSavedSearchOptions
{
    [String] $SearchText
    [Boolean]$OnlyMy
    [Boolean]$OnlyOpen
    [TeamDynamix_Api_RequestPage]$Page

    # Default constructor
    TeamDynamix_Api_Tickets_TicketSavedSearchOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketSavedSearchOptions ([psobject]$SavedSearchOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $SavedSearchOptions.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $SavedSearchOptions.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketSavedSearchOptions(
        [String] $SearchText,
        [Boolean]$OnlyMy,
        [Boolean]$OnlyOpen,
        [TeamDynamix_Api_RequestPage]$Page)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Assets_AssetSavedSearchOptions
{
    [String]$SearchText
    [TeamDynamix_Api_RequestPage]$Page

    # Default constructor
    TeamDynamix_Api_Assets_AssetSavedSearchOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_AssetSavedSearchOptions ([psobject]$SavedSearchOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_AssetSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $SavedSearchOptions.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $SavedSearchOptions.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_AssetSavedSearchOptions(
        [String]$SearchText,
        [TeamDynamix_Api_RequestPage]$Page)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_AssetSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_EligibleAssignment
{
    [String]  $Name
    [String]  $Value
    [String]  $Email
    [Boolean] $IsUser

    # Default constructor
    TeamDynamix_Api_Users_EligibleAssignment ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_EligibleAssignment ([psobject]$EligibleAssignment)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_EligibleAssignment]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $EligibleAssignment.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $EligibleAssignment.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_EligibleAssignment(
        [String]  $Name,
        [String]  $Value,
        [String]  $Email,
        [Boolean] $IsUser)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_EligibleAssignment]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Feed_TicketTaskFeedEntry
{
    [System.Nullable[Int32]]$PercentComplete
    [String]  $Comments
    [String[]]$Notify
    [Boolean] $IsPrivate
    [boolean] $IsRichHtml

    # Default constructor
    TeamDynamix_Api_Feed_TicketTaskFeedEntry ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Feed_TicketTaskFeedEntry ([psobject]$TicketTaskFeedEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_TicketTaskFeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketTaskFeedEntry.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TicketTaskFeedEntry.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Feed_TicketTaskFeedEntry(
        [System.Nullable[Int32]]$PercentComplete,
        [String]  $Comments,
        [String[]]$Notify,
        [Boolean] $IsPrivate,
        [boolean] $IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Feed_TicketTaskFeedEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeEntry
{
        [Int32]   $TimeID
        [Int32]   $ItemID
        [String]  $ItemTitle
        [String]  $InvoiceID
        [String]  $StatusFullName
        [String]  $StatusUid
        [DateTime]$StatusDate
        [String]  $Uid
        [Double]  $CostRate
        [Double]  $BillRate
        [Boolean] $Limited
        [Int32]   $TimeTypeID
        [Int32]   $FunctionalRoleID
        [Boolean] $Billable
        [Int32]   $AppID
        [String]  $AppName
        [TeamDynamix_Api_Time_TimeEntryComponent]$Component
        [TeamDynamix_Api_Time_TimeStatus]$Status
        [Int32]   $TicketID
        [Double]  $Hours
        [Double]  $Minutes
        [String]  $Description
        [Int32]   $PortfolioID
        [String]  $PortfolioName
        [Int32]   $ProjectID
        [String]  $ProjectName
        [Int32]   $PlanID
        [DateTime]$TimeDate
        [Boolean] $ProjectIsActive
        [String]  $ApproverFullName
        [String]  $ApproverUid

    # Default constructor
    TeamDynamix_Api_Time_TimeEntry ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeEntry ([psobject]$TimeEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeEntry.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeEntry.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeEntry(
        [Int32]   $TimeID,
        [Int32]   $ItemID,
        [String]  $ItemTitle,
        [String]  $InvoiceID,
        [String]  $StatusFullName,
        [String]  $StatusUid,
        [DateTime]$StatusDate,
        [String]  $Uid,
        [Double]  $CostRate,
        [Double]  $BillRate,
        [Boolean] $Limited,
        [Int32]   $TimeTypeID,
        [Int32]   $FunctionalRoleID,
        [Boolean] $Billable,
        [Int32]   $AppID,
        [String]  $AppName,
        [TeamDynamix_Api_Time_TimeEntryComponent]$Component,
        [TeamDynamix_Api_Time_TimeStatus]$Status,
        [Int32]   $TicketID,
        [Double]  $Hours,
        [Double]  $Minutes,
        [String]  $Description,
        [Int32]   $PortfolioID,
        [String]  $PortfolioName,
        [Int32]   $ProjectID,
        [String]  $ProjectName,
        [Int32]   $PlanID,
        [DateTime]$TimeDate,
        [Boolean] $ProjectIsActive,
        [String]  $ApproverFullName,
        [String]  $ApproverUid)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Time_TimeEntry(
        [Double]  $Minutes,
        [String]  $Description)
    {
        $this.Minutes     = $Minutes
        $this.Description = $Description
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Time_TimeEntry
{
    [Int32]   $TimeID
    [Int32]   $ItemID
    [String]  $ItemTitle
    [String]  $InvoiceID
    [String]  $StatusFullName
    [String]  $StatusUid
    [String]  $StatusDate
    [String]  $Uid
    [Double]  $CostRate
    [Double]  $BillRate
    [Boolean] $Limited
    [Int32]   $TimeTypeID
    [Int32]   $FunctionalRoleID
    [Boolean] $Billable
    [Int32]   $AppID
    [String]  $AppName
    [TeamDynamix_Api_Time_TimeEntryComponent]$Component
    [TeamDynamix_Api_Time_TimeStatus]$Status
    [Int32]   $TicketID
    [Double]  $Hours
    [Double]  $Minutes
    [String]  $Description
    [Int32]   $PortfolioID
    [String]  $PortfolioName
    [Int32]   $ProjectID
    [String]  $ProjectName
    [Int32]   $PlanID
    [String]  $TimeDate
    [Boolean] $ProjectIsActive
    [String]  $ApproverFullName
    [String]  $ApproverUid

    # Constructor from object
    TD_TeamDynamix_Api_Time_TimeEntry ([psobject]$TimeEntry)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeEntry]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeEntry.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TimeEntry.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TimeEntry.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Time_IndexAndIDPair
{
    [Int32]$Index
    [Int32]$ID

    # Default constructor
    TeamDynamix_Api_Time_IndexAndIDPair ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_IndexAndIDPair ([psobject]$IndexAndIDPair)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_IndexAndIDPair]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IndexAndIDPair.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $IndexAndIDPair.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_IndexAndIDPair(
        [Int32]$Index,
        [Int32]$ID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_IndexAndIDPair]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeApiError
{
    [Int32]   $Index
    [Int32]   $TimeEntryID
    [String]  $ErrorMessage
    [TeamDynamix_Api_Time_TimeApiErrorCode]$ErrorCode
    [String]  $ErrorCodeName

    # Default constructor
    TeamDynamix_Api_Time_TimeApiError ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeApiError ([psobject]$TimeApiError)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeApiError]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeApiError.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeApiError.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeApiError(
        [Int32]   $Index,
        [Int32]   $TimeEntryID,
        [String]  $ErrorMessage,
        [TeamDynamix_Api_Time_TimeApiErrorCode]$ErrorCode,
        [String]  $ErrorCodeName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeApiError]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_BulkOperationResults
{
    [TeamDynamix_Api_Time_IndexAndIDPair[]]$Succeeded
    [TeamDynamix_Api_Time_TimeApiError[]]  $Failed

    # Default constructor
    TeamDynamix_Api_Time_BulkOperationResults ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_BulkOperationResults ([psobject]$BulkOperationResults)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_BulkOperationResults]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $BulkOperationResults.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $BulkOperationResults.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_BulkOperationResults(
        [TeamDynamix_Api_Time_IndexAndIDPair[]]$Succeeded,
        [TeamDynamix_Api_Time_TimeApiError[]]  $Failed)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_BulkOperationResults]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeReport
{
    [Int32]   $ID
    [DateTime]$PeriodStartDate
    [DateTime]$PeriodEndDate
    [TeamDynamix_Api_Time_TimeEntry[]]$Times
    [TeamDynamix_Api_Time_TimeStatus]$Status
    [String]  $TimeReportUid
    [String]  $UserFullName
    [String]  $UserAlertEmail
    [Int64]   $MinutesBillable
    [Int64]   $MinutesNonBillable
    [Int64]   $MinutesTotal
    [Int32]   $TimeEntriesCount
    [DateTime]$ModifiedDate
    [DateTime]$CreatedDate
    [DateTime]$CompletedDate

    # Default constructor
    TeamDynamix_Api_Time_TimeReport ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeReport ([psobject]$TimeReport)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeReport]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeReport.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeReport.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeReport(
        [Int32]   $ID,
        [DateTime]$PeriodStartDate,
        [DateTime]$PeriodEndDate,
        [TeamDynamix_Api_Time_TimeEntry[]]$Times,
        [TeamDynamix_Api_Time_TimeStatus]$Status,
        [String]  $TimeReportUid,
        [String]  $UserFullName,
        [String]  $UserAlertEmail,
        [Int64]   $MinutesBillable,
        [Int64]   $MinutesNonBillable,
        [Int64]   $MinutesTotal,
        [Int32]   $TimeEntriesCount,
        [DateTime]$ModifiedDate,
        [DateTime]$CreatedDate,
        [DateTime]$CompletedDate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeReport]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeSearch
{
    [System.Nullable[Int32]]   $MinutesFrom
    [System.Nullable[Int32]]   $MinutesTo
    [System.Nullable[DateTime]]$EntryDateFrom
    [System.Nullable[DateTime]]$EntryDateTo
    [System.Nullable[DateTime]]$CreatedDateFrom
    [System.Nullable[DateTime]]$CreatedDateTo
    [System.Nullable[DateTime]]$StatusDateFrom
    [System.Nullable[DateTime]]$StatusDateTo
    [System.Nullable[Double]]  $BillRateFrom
    [System.Nullable[Double]]  $BillRateTo
    [System.Nullable[Double]]  $CostRateFrom
    [System.Nullable[Double]]  $CostRateTo
    [Int32[]]$TimeTypeIDs
    [Int32[]]$ProjectOrWorkspaceIDs
    [Int32[]]$PlanIDs
    [Int32[]]$TaskIDs
    [Int32[]]$IssueIDs
    [Int32[]]$TicketIDs
    [Int32[]]$TicketTaskIDs
    [Int32[]]$ApplicationIDs
    [Int32[]]$StatusIDs
    [Guid[]] $PersonUIDs
    [TeamDynamix_Api_Time_TimeEntryComponent[]]$Components
    [System.Nullable[Boolean]]$IsTimeOff
    [System.Nullable[Boolean]]$IsBillable
    [System.Nullable[Boolean]]$IsLimited
    [System.Nullable[Int32]]  $MaxResults

    # Default constructor
    TeamDynamix_Api_Time_TimeSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeSearch ([psobject]$TimeSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeSearch(
        [System.Nullable[Int32]]   $MinutesFrom,
        [System.Nullable[Int32]]   $MinutesTo,
        [System.Nullable[DateTime]]$EntryDateFrom,
        [System.Nullable[DateTime]]$EntryDateTo,
        [System.Nullable[DateTime]]$CreatedDateFrom,
        [System.Nullable[DateTime]]$CreatedDateTo,
        [System.Nullable[DateTime]]$StatusDateFrom,
        [System.Nullable[DateTime]]$StatusDateTo,
        [System.Nullable[Double]]  $BillRateFrom,
        [System.Nullable[Double]]  $BillRateTo,
        [System.Nullable[Double]]  $CostRateFrom,
        [System.Nullable[Double]]  $CostRateTo,
        [Int32[]]$TimeTypeIDs,
        [Int32[]]$ProjectOrWorkspaceIDs,
        [Int32[]]$PlanIDs,
        [Int32[]]$TaskIDs,
        [Int32[]]$IssueIDs,
        [Int32[]]$TicketIDs,
        [Int32[]]$TicketTaskIDs,
        [Int32[]]$ApplicationIDs,
        [Int32[]]$StatusIDs,
        [Guid[]] $PersonUIDs,
        [TeamDynamix_Api_Time_TimeEntryComponent[]]$Components,
        [System.Nullable[Boolean]]$IsTimeOff,
        [System.Nullable[Boolean]]$IsBillable,
        [System.Nullable[Boolean]]$IsLimited,
        [System.Nullable[Int32]]  $MaxResults)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

# This class uses the input DateTime types changed to strings
# TD requires a specific textual format for the date, which is supplied by this class
class TD_TeamDynamix_Api_Time_TimeSearch
{
    [System.Nullable[Int32]] $MinutesFrom
    [System.Nullable[Int32]] $MinutesTo
    [String]$EntryDateFrom
    [String]$EntryDateTo
    [String]$CreatedDateFrom
    [String]$CreatedDateTo
    [String]$StatusDateFrom
    [String]$StatusDateTo
    [System.Nullable[Double]]$BillRateFrom
    [System.Nullable[Double]]$BillRateTo
    [System.Nullable[Double]]$CostRateFrom
    [System.Nullable[Double]]$CostRateTo
    [Int32[]]$TimeTypeIDs
    [Int32[]]$ProjectOrWorkspaceIDs
    [Int32[]]$PlanIDs
    [Int32[]]$TaskIDs
    [Int32[]]$IssueIDs
    [Int32[]]$TicketIDs
    [Int32[]]$TicketTaskIDs
    [Int32[]]$ApplicationIDs
    [Int32[]]$StatusIDs
    [Guid[]] $PersonUIDs
    [TeamDynamix_Api_Time_TimeEntryComponent[]]$Components
    [System.Nullable[Boolean]]$IsTimeOff
    [System.Nullable[Boolean]]$IsBillable
    [System.Nullable[Boolean]]$IsLimited
    [System.Nullable[Int32]]  $MaxResults

    # Constructor from object
    TD_TeamDynamix_Api_Time_TimeSearch ([psobject]$TimeSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TimeSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TimeSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeType
{
        [Int32]   $ID
        [String]  $Name
        [String]  $Code
        [String]  $GLAccount
        [String]  $HelpText
        [Int32]   $DefaultLimitMinutes
        [Boolean] $IsBillable
        [Boolean] $IsCapitalized
        [Boolean] $IsLimited
        [Boolean] $IsActive
        [Boolean] $IsTimeOffTimeType
        [Boolean] $CreateScheduleEntriesForTimeOff
        [DateTime]$CreatedDate
        [DateTime]$ModifiedDate
        [Boolean] $IsActiveOnItem
        [Double]  $ItemActualHours
        [System.Nullable[DateTime]]$ItemAddedDate
        [System.Nullable[Guid]]$ItemAddedUid
        [String]  $ItemAddedFullName

    # Default constructor
    TeamDynamix_Api_Time_TimeType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeType ([psobject]$TimeType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeType.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeType.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeType(
                [Int32]   $ID,
                [String]  $Name,
                [String]  $Code,
                [String]  $GLAccount,
                [String]  $HelpText,
                [Int32]   $DefaultLimitMinutes,
                [Boolean] $IsBillable,
                [Boolean] $IsCapitalized,
                [Boolean] $IsLimited,
                [Boolean] $IsActive,
                [Boolean] $IsTimeOffTimeType,
                [Boolean] $CreateScheduleEntriesForTimeOff,
                [DateTime]$CreatedDate,
                [DateTime]$ModifiedDate,
                [Boolean] $IsActiveOnItem,
                [Double]  $ItemActualHours,
                [System.Nullable[DateTime]]$ItemAddedDate,
                [System.Nullable[Guid]]$ItemAddedUid,
                [String]  $ItemAddedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Time_TimeTypeLimit
{
        [Int32]   $TimeTypeID
        [DateTime]$StartDate
        [DateTime]$EndDate
        [Double]  $Hours
        [Double]  $HoursRemaining

    # Default constructor
    TeamDynamix_Api_Time_TimeTypeLimit ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Time_TimeTypeLimit ([psobject]$TimeTypeLimit)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeTypeLimit]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TimeTypeLimit.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TimeTypeLimit.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Time_TimeTypeLimit(
                [Int32]   $TimeTypeID,
                [DateTime]$StartDate,
                [DateTime]$EndDate,
                [Double]  $Hours,
                [Double]  $HoursRemaining)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Time_TimeTypeLimit]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Projects_CustomColumn
{
    [Int32] $Index
    [String]$DisplayName

    # Default constructor
    TeamDynamix_Api_Projects_CustomColumn ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Projects_CustomColumn ([psobject]$CustomColumn)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_CustomColumn]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $CustomColumn.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $CustomColumn.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Projects_CustomColumn(
        [Int32] $Index,
        [String]$DisplayName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_CustomColumn]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Users_UserSummary
{
    [Guid]  $UID
    [Int32] $ReferenceID
    [String]$FullName
    [String]$FirstName
    [String]$LastName
    [String]$ProfileImageFileName
    [String]$AlertEmail

    # Default constructor
    TeamDynamix_Api_Users_UserSummary ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserSummary ([psobject]$UserSummary)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserSummary]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserSummary.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserSummary.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserSummary.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserSummary(
        [Guid]  $UID,
        [Int32] $ReferenceID,
        [String]$FullName,
        [String]$FirstName,
        [String]$LastName,
        [String]$ProfileImageFileName,
        [String]$AlertEmail)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserSummary]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Projects_Project
{
    [Int32]   $ID
    [String]  $Name
    [Boolean] $IsRead
    [Double]  $Budget
    [Int32]   $AccountID
    [String]  $AccountName
    [String]  $SponsorEmail
    [Guid]    $SponsorUID
    [String]  $SponsorName
    [DateTime]$CreatedDate
    [DateTime]$ModifiedDate
    [Guid]    $ModifiedUID
    [String]  $ModifiedFullName
    [DateTime]$StatusModifiedDate
    [String]  $Description
    [Double]  $ExpensesBudget
    [Double]  $ExpensesBudgetUsed
    [Double]  $ActualHours
    [Boolean] $AllowProjectTime
    [Boolean] $ApproveTimeByReportsTo
    [String]  $BriefcasePath
    [DateTime]$EndDateBaseline
    [String]  $Identifier
    [Int32]   $PriorityID
    [String]  $PriorityName
    [Boolean] $IsActive
    [Double]  $TimeBudget
    [Double]  $TimeBudgetUsed
    [Int32]   $TypeCategoryID
    [String]  $TypeCategoryName
    [Int32]   $TypeID
    [String]  $TypeName
    [Boolean] $IsPrivate
    [Boolean] $IsPublic
    [Boolean] $IsPublished
    [Boolean] $IsTemplate
    [Boolean] $IsRequest
    [DateTime]$StartDateBaseline
    [Int32]   $TemplateID
    [Int32]   $PercentComplete
    [DateTime]$MinScheduledDate
    [DateTime]$MaxScheduledDate
    [DateTime]$MinPendingScheduleDate
    [DateTime]$MaxPendingScheduleDate
    [Boolean] $UpdateStartEnd
    [Boolean] $ScheduleHoursByPlan
    [TeamDynamix_Api_ResourceAllocationEditMode]$AllocationEditMode
    [Boolean] $UseRemainingHours
    [Boolean] $AlertOnEstimatedHoursExceeded
    [Boolean] $AlertOnAssignedHoursExceeded
    [Guid]    $Admin2UID
    [String]  $Admin2FullName
    [String]  $Admin2Email
    [TeamDynamix_Api_Users_UserSummary[]]$AlternateManagers
    [Int32]   $RequestWorkflowID
    [Int32]   $ClassificationID
    [String]  $ClassificationName
    [Boolean] $AddContact
    [DateTime]$DateScored
    [String]  $AdminName
    [Guid]    $AdminUID
    [String]  $AdminEmail
    [DateTime]$EndDateInitial
    [Boolean] $EndDateInitialIsNull
    [Double]  $ExpensesBudgetInitial
    [DateTime]$StartDateInitial
    [Boolean] $StartDateInitialIsNull
    [Double]  $BudgetInitial
    [Double]  $TimeBudgetInitial
    [String]  $RequestStatus
    [String]  $Requirements
    [String]  $IntangibleBenefits
    [Guid]    $CreatedUID
    [String]  $CreatedFullName
    [String]  $CreatedEmail
    [String]  $StatusName
    [Boolean] $ApplyMetrics
    [String]  $StatusComments
    [Guid]    $StatusModifiedByUID
    [String]  $StatusModifiedByFullName
    [Double]  $DeductAmount
    [Double]  $TimeAmount
    [Double]  $EstimatedHours
    [Double]  $EstimatedHoursInitial
    [Double]  $ScheduledHours
    [Double]  $PendingHours
    [DateTime]$EndDate
    [DateTime]$StartDate
    [Int32]   $StatusID
    [TeamDynamix_Api_Projects_HealthChoice]$Health
    [String]  $HealthName
    [String]  $HealthDescription
    [String]  $ReferenceType
    [String]  $ReferenceID
    [String]  $StatusDescription
    [Double]  $GoalsScore
    [Double]  $RisksScore
    [Double]  $ScorecardScore
    [Double]  $CompositeScore
    [Double]  $CompositeScorePct
    [String]  $InternalTypeID
    [Int32]   $PortfoliosCount
    [Int32]   $ProgramsCount
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [TeamDynamix_Api_Projects_CustomColumn[]]$CustomColumns
    [Boolean] $IsBaselineSupported
    [Boolean] $IsResourceAssignmentSupported
    [Boolean] $IsTaskDetailSupported
    [Boolean] $IsTaskUpdateSupported
    [Boolean] $IsTimeEntrySupported
    [Boolean] $IsTicketToTaskConversionSupported
    [Boolean] $IsActiveOpenAndUserOnProject
    [Boolean] $IsBackupSupported
    [Int32]   $ServiceID
    [String]  $ServiceName
    [Int32]   $ServiceOfferingID
    [String]  $ServiceOfferingName
    [Int32]   $ServiceCategoryID
    [String]  $ServiceCategoryName
    [DateTime[]]$NonWorkingDays

    # Default constructor
    TeamDynamix_Api_Projects_Project ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Projects_Project ([psobject]$Project)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_Project]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Project.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Project.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Project.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Projects_Project(
        [Int32]   $ID,
        [String]  $Name,
        [Boolean] $IsRead,
        [Double]  $Budget,
        [Int32]   $AccountID,
        [String]  $AccountName,
        [String]  $SponsorEmail,
        [Guid]    $SponsorUID,
        [String]  $SponsorName,
        [DateTime]$CreatedDate,
        [DateTime]$ModifiedDate,
        [Guid]    $ModifiedUID,
        [String]  $ModifiedFullName,
        [DateTime]$StatusModifiedDate,
        [String]  $Description,
        [Double]  $ExpensesBudget,
        [Double]  $ExpensesBudgetUsed,
        [Double]  $ActualHours,
        [Boolean] $AllowProjectTime,
        [Boolean] $ApproveTimeByReportsTo,
        [String]  $BriefcasePath,
        [DateTime]$EndDateBaseline,
        [String]  $Identifier,
        [Int32]   $PriorityID,
        [String]  $PriorityName,
        [Boolean] $IsActive,
        [Double]  $TimeBudget,
        [Double]  $TimeBudgetUsed,
        [Int32]   $TypeCategoryID,
        [String]  $TypeCategoryName,
        [Int32]   $TypeID,
        [String]  $TypeName,
        [Boolean] $IsPrivate,
        [Boolean] $IsPublic,
        [Boolean] $IsPublished,
        [Boolean] $IsTemplate,
        [Boolean] $IsRequest,
        [DateTime]$StartDateBaseline,
        [Int32]   $TemplateID,
        [Int32]   $PercentComplete,
        [DateTime]$MinScheduledDate,
        [DateTime]$MaxScheduledDate,
        [DateTime]$MinPendingScheduleDate,
        [DateTime]$MaxPendingScheduleDate,
        [Boolean] $UpdateStartEnd,
        [Boolean] $ScheduleHoursByPlan,
        [TeamDynamix_Api_ResourceAllocationEditMode]$AllocationEditMode,
        [Boolean] $UseRemainingHours,
        [Boolean] $AlertOnEstimatedHoursExceeded,
        [Boolean] $AlertOnAssignedHoursExceeded,
        [Guid]    $Admin2UID,
        [String]  $Admin2FullName,
        [String]  $Admin2Email,
        [TeamDynamix_Api_Users_UserSummary[]]$AlternateManagers,
        [Int32]   $RequestWorkflowID,
        [Int32]   $ClassificationID,
        [String]  $ClassificationName,
        [Boolean] $AddContact,
        [DateTime]$DateScored,
        [String]  $AdminName,
        [Guid]    $AdminUID,
        [String]  $AdminEmail,
        [DateTime]$EndDateInitial,
        [Boolean] $EndDateInitialIsNull,
        [Double]  $ExpensesBudgetInitial,
        [DateTime]$StartDateInitial,
        [Boolean] $StartDateInitialIsNull,
        [Double]  $BudgetInitial,
        [Double]  $TimeBudgetInitial,
        [String]  $RequestStatus,
        [String]  $Requirements,
        [String]  $IntangibleBenefits,
        [Guid]    $CreatedUID,
        [String]  $CreatedFullName,
        [String]  $CreatedEmail,
        [String]  $StatusName,
        [Boolean] $ApplyMetrics,
        [String]  $StatusComments,
        [Guid]    $StatusModifiedByUID,
        [String]  $StatusModifiedByFullName,
        [Double]  $DeductAmount,
        [Double]  $TimeAmount,
        [Double]  $EstimatedHours,
        [Double]  $EstimatedHoursInitial,
        [Double]  $ScheduledHours,
        [Double]  $PendingHours,
        [DateTime]$EndDate,
        [DateTime]$StartDate,
        [Int32]   $StatusID,
        [TeamDynamix_Api_Projects_HealthChoice]$Health,
        [String]  $HealthName,
        [String]  $HealthDescription,
        [String]  $ReferenceType,
        [String]  $ReferenceID,
        [String]  $StatusDescription,
        [Double]  $GoalsScore,
        [Double]  $RisksScore,
        [Double]  $ScorecardScore,
        [Double]  $CompositeScore,
        [Double]  $CompositeScorePct,
        [String]  $InternalTypeID,
        [Int32]   $PortfoliosCount,
        [Int32]   $ProgramsCount,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [TeamDynamix_Api_Projects_CustomColumn[]]$CustomColumns,
        [Boolean] $IsBaselineSupported,
        [Boolean] $IsResourceAssignmentSupported,
        [Boolean] $IsTaskDetailSupported,
        [Boolean] $IsTaskUpdateSupported,
        [Boolean] $IsTimeEntrySupported,
        [Boolean] $IsTicketToTaskConversionSupported,
        [Boolean] $IsActiveOpenAndUserOnProject,
        [Boolean] $IsBackupSupported,
        [Int32]   $ServiceID,
        [String]  $ServiceName,
        [Int32]   $ServiceOfferingID,
        [String]  $ServiceOfferingName,
        [Int32]   $ServiceCategoryID,
        [String]  $ServiceCategoryName,
        [DateTime[]]$NonWorkingDays)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_Project]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Projects_Project(
        [String]  $Name,
        [Double]  $Budget,
        [Int32]   $AccountID,
        [Guid]    $SponsorUID,
        [String]  $Description,
        [Double]  $ExpensesBudget,
        [Boolean] $AllowProjectTime,
        [Boolean] $ApproveTimeByReportsTo,
        [Int32]   $PriorityID,
        [Boolean] $IsActive,
        [Double]  $TimeBudget,
        [Int32]   $TypeID,
        [Boolean] $IsPublic,
        [Boolean] $IsPublished,
        [Boolean] $UpdateStartEnd,
        [Boolean] $ScheduleHoursByPlan,
        [TeamDynamix_Api_ResourceAllocationEditMode]$AllocationEditMode,
        [Boolean] $UseRemainingHours,
        [Boolean] $AlertOnEstimatedHoursExceeded,
        [Boolean] $AlertOnAssignedHoursExceeded,
        [Int32]   $ClassificationID,
        [Boolean] $AddContact,
        [String]  $Requirements,
        [DateTime]$EndDate,
        [DateTime]$StartDate,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [Int32]   $ServiceID,
        [Int32]   $ServiceOfferingID)
    {
        $this.Name                          = $Name
        $this.Budget                        = $Budget
        $this.AccountID                     = $AccountID
        $this.SponsorUID                    = $SponsorUID
        $this.Description                   = $Description
        $this.ExpensesBudget                = $ExpensesBudget
        $this.AllowProjectTime              = $AllowProjectTime
        $this.ApproveTimeByReportsTo        = $ApproveTimeByReportsTo
        $this.PriorityID                    = $PriorityID
        $this.IsActive                      = $IsActive
        $this.TimeBudget                    = $TimeBudget
        $this.TypeID                        = $TypeID
        $this.IsPublic                      = $IsPublic
        $this.IsPublished                   = $IsPublished
        $this.UpdateStartEnd                = $UpdateStartEnd
        $this.ScheduleHoursByPlan           = $ScheduleHoursByPlan
        $this.AllocationEditMode            = $AllocationEditMode
        $this.UseRemainingHours             = $UseRemainingHours
        $this.AlertOnEstimatedHoursExceeded = $AlertOnEstimatedHoursExceeded
        $this.AlertOnAssignedHoursExceeded  = $AlertOnAssignedHoursExceeded
        $this.ClassificationID              = $ClassificationID
        $this.AddContact                    = $AddContact
        $this.Requirements                  = $Requirements
        $this.EndDate                       = $EndDate                       | Get-Date
        $this.StartDate                     = $StartDate                     | Get-Date
        $this.Attributes                    = $Attributes
        $this.ServiceID                     = $ServiceID
        $this.ServiceOfferingID             = $ServiceOfferingID
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Project',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }
}

class TD_TeamDynamix_Api_Projects_Project
{
        [Int32]  $ID
        [String] $Name
        [Boolean]$IsRead
        [Double] $Budget
        [Int32]  $AccountID
        [String] $AccountName
        [String] $SponsorEmail
        [Guid]   $SponsorUID
        [String] $SponsorName
        [String] $CreatedDate
        [String] $ModifiedDate
        [Guid]   $ModifiedUID
        [String] $ModifiedFullName
        [String] $StatusModifiedDate
        [String] $Description
        [Double] $ExpensesBudget
        [Double] $ExpensesBudgetUsed
        [Double] $ActualHours
        [Boolean]$AllowProjectTime
        [Boolean]$ApproveTimeByReportsTo
        [String] $BriefcasePath
        [String] $EndDateBaseline
        [String] $Identifier
        [Int32]  $PriorityID
        [String] $PriorityName
        [Boolean]$IsActive
        [Double] $TimeBudget
        [Double] $TimeBudgetUsed
        [Int32]  $TypeCategoryID
        [String] $TypeCategoryName
        [Int32]  $TypeID
        [String] $TypeName
        [Boolean]$IsPrivate
        [Boolean]$IsPublic
        [Boolean]$IsPublished
        [Boolean]$IsTemplate
        [Boolean]$IsRequest
        [String] $StartDateBaseline
        [Int32]  $TemplateID
        [Int32]  $PercentComplete
        [String] $MinScheduledDate
        [String] $MaxScheduledDate
        [String] $MinPendingScheduleDate
        [String] $MaxPendingScheduleDate
        [Boolean]$UpdateStartEnd
        [Boolean]$ScheduleHoursByPlan
        [TeamDynamix_Api_ResourceAllocationEditMode]$AllocationEditMode
        [Boolean]$UseRemainingHours
        [Boolean]$AlertOnEstimatedHoursExceeded
        [Boolean]$AlertOnAssignedHoursExceeded
        [Guid]   $Admin2UID
        [String] $Admin2FullName
        [String] $Admin2Email
        [TeamDynamix_Api_Users_UserSummary[]]$AlternateManagers
        [Int32]  $RequestWorkflowID
        [Int32]  $ClassificationID
        [String] $ClassificationName
        [Boolean]$AddContact
        [String] $DateScored
        [String] $AdminName
        [Guid]   $AdminUID
        [String] $AdminEmail
        [String] $EndDateInitial
        [Boolean]$EndDateInitialIsNull
        [Double] $ExpensesBudgetInitial
        [String] $StartDateInitial
        [Boolean]$StartDateInitialIsNull
        [Double] $BudgetInitial
        [Double] $TimeBudgetInitial
        [String] $RequestStatus
        [String] $Requirements
        [String] $IntangibleBenefits
        [Guid]   $CreatedUID
        [String] $CreatedFullName
        [String] $CreatedEmail
        [String] $StatusName
        [Boolean]$ApplyMetrics
        [String] $StatusComments
        [Guid]   $StatusModifiedByUID
        [String] $StatusModifiedByFullName
        [Double] $DeductAmount
        [Double] $TimeAmount
        [Double] $EstimatedHours
        [Double] $EstimatedHoursInitial
        [Double] $ScheduledHours
        [Double] $PendingHours
        [String] $EndDate
        [String] $StartDate
        [Int32]  $StatusID
        [TeamDynamix_Api_Projects_HealthChoice]$Health
        [String] $HealthName
        [String] $HealthDescription
        [String] $ReferenceType
        [String] $ReferenceID
        [String] $StatusDescription
        [Double] $GoalsScore
        [Double] $RisksScore
        [Double] $ScorecardScore
        [Double] $CompositeScore
        [Double] $CompositeScorePct
        [String] $InternalTypeID
        [Int32]  $PortfoliosCount
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
        [TeamDynamix_Api_Projects_CustomColumn[]]$CustomColumns
        [Boolean] $IsBaselineSupported
        [Boolean] $IsResourceAssignmentSupported
        [Boolean] $IsTaskDetailSupported
        [Boolean] $IsTaskUpdateSupported
        [Boolean] $IsTimeEntrySupported
        [Boolean] $IsTicketToTaskConversionSupported
        [Boolean] $IsActiveOpenAndUserOnProject
        [Boolean] $IsBackupSupported
        [Int32]   $ServiceID
        [String]  $ServiceName
        [Int32]   $ServiceOfferingID
        [String]  $ServiceOfferingName
        [Int32]   $ServiceCategoryID
        [String]  $ServiceCategoryName
        [String[]]$NonWorkingDays

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Projects_Project ([psobject]$Project)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_Project]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Project.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Project.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Project.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Projects_Resource
{
    [Guid]   $UID
    [String] $FullName
    [String] $FirstName
    [String] $LastName
    [Int32]  $ReferenceID
    [String] $ProfileImageFileName
    [Boolean]$IsProjectActive
    [Boolean]$IsUserActive
    [Int32]  $RoleID
    [String] $RoleName
    [String] $UniqueKey
    [Boolean]$UserHasMultipleRolesOnProject
    [TeamDynamix_Api_FunctionalRole_FunctionalRole[]]$FunctionalRoles

    # Default constructor
    TeamDynamix_Api_Projects_Resource ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Projects_Resource ([psobject]$Resource)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_Resource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Resource.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Resource.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Resource.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Projects_Resource(
        [Guid]   $UID,
        [String] $FullName,
        [String] $FirstName,
        [String] $LastName,
        [Int32]  $ReferenceID,
        [String] $ProfileImageFileName,
        [Boolean]$IsProjectActive,
        [Boolean]$IsUserActive,
        [Int32]  $RoleID,
        [String] $RoleName,
        [String] $UniqueKey,
        [Boolean]$UserHasMultipleRolesOnProject,
        [TeamDynamix_Api_FunctionalRole_FunctionalRole[]]$FunctionalRoles)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_Resource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_TaskRelationship
{
    [Int32]   $PredTaskID
    [Int32]   $DepTaskID
    [Int32]   $Lag
    [TeamDynamix_Api_Plans_RelationshipType]$RelationshipType

    # Default constructor
    TeamDynamix_Api_Plans_TaskRelationship ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_TaskRelationship ([psobject]$TaskRelationship)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskRelationship]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TaskRelationship.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TaskRelationship.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_TaskRelationship(
            [Int32]   $PredTaskID,
            [Int32]   $DepTaskID,
            [Int32]   $Lag,
            [TeamDynamix_Api_Plans_RelationshipType]$RelationshipType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskRelationship]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Plans_TaskResource
{
    [String] $ResourceUID
    [String] $ResourceFullName
    [Double] $PercentAssignedWhole
    [Int32]  $ResourceRoleID
    [String] $ResourceRoleName
    [Boolean]$HasMultipleRolesOnProject
    [String] $UniqueKey

    # Default constructor
    TeamDynamix_Api_Plans_TaskResource ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_TaskResource ([psobject]$TaskResource)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskResource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TaskResource.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $TaskResource.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_TaskResource(
            [String] $ResourceUID,
            [String] $ResourceFullName,
            [Double] $PercentAssignedWhole,
            [Int32]  $ResourceRoleID,
            [String] $ResourceRoleName,
            [Boolean]$HasMultipleRolesOnProject,
            [String] $UniqueKey)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskResource]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Plans_Task
{
    [Int32]   $OutlineNumber
    [String]  $Wbs
    [Boolean] $IsParent
    [Int32]   $IndentLevel
    [Int32]   $ParentID
    [Int32]   $PlanID
    [String]  $PlanName
    [Boolean] $IsFlagged
    [Int32]   $TicketID
    [Int32]   $TicketAppID
    [String]  $Field1
    [String]  $Field2
    [String]  $Field3
    [String]  $Field4
    [String]  $Field5
    [String]  $Field6
    [String]  $Field7
    [String]  $Field8
    [String]  $Field9
    [String]  $Field10
    [Boolean] $IsMilestone
    [Boolean] $IsConvertedFromTicket
    [Boolean] $HasExternalRelationships
    [Boolean] $IsExternalRelationshipViolated
    [Boolean] $CanShiftForward
    [DateTime]$ShiftForwardDate
    [Boolean] $HasIssues
    [Boolean] $HasAttachments
    [Int32]   $Priority
    [Boolean] $IsStory
    [Int32]   $OpenIssuesCount
    [Int32]   $IssuesCount
    [TeamDynamix_Api_Plans_TaskRelationship[]]$Predecessors
    [String]  $PredecessorsOutlineNumbersComplex
    [TeamDynamix_Api_Plans_TaskResource[]]$Resources
    [String]  $ResourcesNamesAndPercents
    [Boolean] $IsCriticalPath
    [Int32]   $StatusID
    [String]  $Status
    [Int32]   $OrderInParent
    [String[]]$Tags
    [Int32]   $ID
    [String]  $Title
    [String]  $Description
    [DateTime]$StartDateUtc
    [DateTime]$EndDateUtc
    [Int32]   $Duration
    [String]  $DurationString
    [DateTime]$CompletedDateUtc
    [Double]  $EstimatedHoursAtCompletion
    [Int32]   $ProjectID
    [String]  $ProjectIDEncrypted
    [String]  $ProjectName
    [String]  $CreatedUID
    [String]  $CreatedFullName
    [DateTime]$CreatedDate
    [Double]  $EstimatedHours
    [Double]  $EstimatedHoursBaseline
    [Double]  $ActualHours
    [Double]  $PercentComplete
    [DateTime]$StartDateBaselineUtc
    [DateTime]$EndDateBaselineUtc
    [Double]  $StoryPoints
    [Double]  $ValuePoints
    [Double]  $RemainingHours
    [Int32]   $PlanType
    [Int32]   $VarianceDays

    # Default constructor
    TeamDynamix_Api_Plans_Task ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_Task ([psobject]$Task)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_Task]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Task.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Task.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_Task(
        [Int32]   $OutlineNumber,
        [String]  $Wbs,
        [Boolean] $IsParent,
        [Int32]   $IndentLevel,
        [Int32]   $ParentID,
        [Int32]   $PlanID,
        [String]  $PlanName,
        [Boolean] $IsFlagged,
        [Int32]   $TicketID,
        [Int32]   $TicketAppID,
        [String]  $Field1,
        [String]  $Field2,
        [String]  $Field3,
        [String]  $Field4,
        [String]  $Field5,
        [String]  $Field6,
        [String]  $Field7,
        [String]  $Field8,
        [String]  $Field9,
        [String]  $Field10,
        [Boolean] $IsMilestone,
        [Boolean] $IsConvertedFromTicket,
        [Boolean] $HasExternalRelationships,
        [Boolean] $IsExternalRelationshipViolated,
        [Boolean] $CanShiftForward,
        [DateTime]$ShiftForwardDate,
        [Boolean] $HasIssues,
        [Boolean] $HasAttachments,
        [Int32]   $Priority,
        [Boolean] $IsStory,
        [Int32]   $OpenIssuesCount,
        [Int32]   $IssuesCount,
        [TeamDynamix_Api_Plans_TaskRelationship[]]$Predecessors,
        [String]  $PredecessorsOutlineNumbersComplex,
        [TeamDynamix_Api_Plans_TaskResource[]]$Resources,
        [String]  $ResourcesNamesAndPercents,
        [Boolean] $IsCriticalPath,
        [Int32]   $StatusID,
        [String]  $Status,
        [Int32]   $OrderInParent,
        [String[]]$Tags,
        [Int32]   $ID,
        [String]  $Title,
        [String]  $Description,
        [DateTime]$StartDateUtc,
        [DateTime]$EndDateUtc,
        [Int32]   $Duration,
        [String]  $DurationString,
        [DateTime]$CompletedDateUtc,
        [Double]  $EstimatedHoursAtCompletion,
        [Int32]   $ProjectID,
        [String]  $ProjectIDEncrypted,
        [String]  $ProjectName,
        [String]  $CreatedUID,
        [String]  $CreatedFullName,
        [DateTime]$CreatedDate,
        [Double]  $EstimatedHours,
        [Double]  $EstimatedHoursBaseline,
        [Double]  $ActualHours,
        [Double]  $PercentComplete,
        [DateTime]$StartDateBaselineUtc,
        [DateTime]$EndDateBaselineUtc,
        [Double]  $StoryPoints,
        [Double]  $ValuePoints,
        [Double]  $RemainingHours,
        [Int32]   $PlanType,
        [Int32]   $VarianceDays)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_Task]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Plans_Plan
{
    [Int32]   $TaskCount
    [Int32]   $MyTaskCount
    [Boolean] $IsCheckedOut
    [Boolean] $AnyNewTaskAssignments
    [DateTime]$CheckedOutDate
    [String]  $CheckedOutUID
    [String]  $CheckedOutFullName
    [String]  $CheckedOutAppID
    [Boolean] $CanShiftForward
    [Int32]   $CurrentVersion
    [Boolean] $IsBaselined
    [Int32]   $SelectedBaselineId
    [TeamDynamix_Api_Plans_Task[]]$Tasks
    [Int32]   $DraftID
    [Int32]   $ID
    [String]  $Title
    [String]  $Description
    [DateTime]$StartDateUtc
    [DateTime]$EndDateUtc
    [Int32]   $Duration
    [String]  $DurationString
    [DateTime]$CompletedDateUtc
    [Double]  $EstimatedHoursAtCompletion
    [Int32]   $ProjectID
    [String]  $ProjectIDEncrypted
    [String]  $ProjectName
    [String]  $CreatedUID
    [String]  $CreatedFullName
    [DateTime]$CreatedDate
    [Double]  $EstimatedHours
    [Double]  $EstimatedHoursBaseline
    [Double]  $ActualHours
    [Double]  $PercentComplete
    [DateTime]$StartDateBaselineUtc
    [DateTime]$EndDateBaselineUtc
    [Double]  $StoryPoints
    [Double]  $ValuePoints
    [Double]  $RemainingHours
    [Int32]   $PlanType
    [Int32]   $VarianceDays

    # Default constructor
    TeamDynamix_Api_Plans_Plan ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_Plan ([psobject]$Plan)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_Plan]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Plan.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $Plan.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_Plan(
        [Int32]   $TaskCount,
        [Int32]   $MyTaskCount,
        [Boolean] $IsCheckedOut,
        [Boolean] $AnyNewTaskAssignments,
        [DateTime]$CheckedOutDate,
        [String]  $CheckedOutUID,
        [String]  $CheckedOutFullName,
        [String]  $CheckedOutAppID,
        [Boolean] $CanShiftForward,
        [Int32]   $CurrentVersion,
        [Boolean] $IsBaselined,
        [Int32]   $SelectedBaselineId,
        [TeamDynamix_Api_Plans_Task[]]$Tasks,
        [Int32]   $DraftID,
        [Int32]   $ID,
        [String]  $Title,
        [String]  $Description,
        [DateTime]$StartDateUtc,
        [DateTime]$EndDateUtc,
        [Int32]   $Duration,
        [String]  $DurationString,
        [DateTime]$CompletedDateUtc,
        [Double]  $EstimatedHoursAtCompletion,
        [Int32]   $ProjectID,
        [String]  $ProjectIDEncrypted,
        [String]  $ProjectName,
        [String]  $CreatedUID,
        [String]  $CreatedFullName,
        [DateTime]$CreatedDate,
        [Double]  $EstimatedHours,
        [Double]  $EstimatedHoursBaseline,
        [Double]  $ActualHours,
        [Double]  $PercentComplete,
        [DateTime]$StartDateBaselineUtc,
        [DateTime]$EndDateBaselineUtc,
        [Double]  $StoryPoints,
        [Double]  $ValuePoints,
        [Double]  $RemainingHours,
        [Int32]   $PlanType,
        [Int32]   $VarianceDays)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_Plan]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TeamDynamix_Api_Projects_ProjectSearch
{
    [String] $Name
    [String] $NameLike
    [Boolean]$IsGlobal
    [Int32[]]$PriorityIDs
    [Int32[]]$AccountIDs
    [Int32[]]$TypeIDs
    [Int32[]]$ClassificationIDs
    [Int32[]]$RiskIDs
    [Int32[]]$ProcessIDs
    [Int32[]]$GoalIDs
    [Int32[]]$SystemIDs
    [Int32[]]$PortfolioIDs
    [System.Nullable[Double]]$RisksScoreFrom
    [System.Nullable[Double]]$RisksScoreTo
    [System.Nullable[Double]]$GoalsScoreFrom
    [System.Nullable[Double]]$GoalsScoreTo
    [System.Nullable[Double]]$ScorecardScoreFrom
    [System.Nullable[Double]]$ScorecardScoreTo
    [System.Nullable[Double]]$CompositeScoreFrom
    [System.Nullable[Double]]$CompositeScoreTo
    [System.Nullable[Double]]$CompositeScorePercentFrom
    [System.Nullable[Double]]$CompositeScorePercentTo
    [System.Nullable[DateTime]]$CreatedDateFrom
    [System.Nullable[DateTime]]$CreatedDateTo
    [String]$StartsOperator
    [System.Nullable[DateTime]]$Starts
    [String]$EndsOperator
    [System.Nullable[DateTime]]$Ends
    [System.Nullable[Double]]$EstimatedHoursFrom
    [System.Nullable[Double]]$EstimatedHoursTo
    [System.Nullable[Guid]]$ManagerUID
    [Int32[]]$ProjectIDs
    [Int32[]]$ProjectIDsExclude
    [Int32[]]$PortfolioIDsExclude
    [String] $StatusLastUpdatedOperator
    [System.Nullable[DateTime]]$StatusLastUpdated
    [Int32[]]$StatusIDs
    [String] $BudgetOperator
    [System.Nullable[Double]]$Budget
    [String] $PercentCompleteOperator
    [System.Nullable[Int32]]$PercentComplete
    [System.Nullable[Boolean]]$IsOpen
    [System.Nullable[Boolean]]$IsActive
    [String] $SponsorName
    [String] $SponsorEmail
    [Guid]   $SponsorUID
    [String] $ReportsToName
    [System.Nullable[Guid]]$ReportsToUID
    [Boolean]$CascadeReportsToUID
    [Int32[]]$FunctionalRoleIDs
    [Boolean]$ShowManagedByPlan
    [Boolean]$ShowManagedByProject
    [Boolean]$ShowManagedBoth
    [Int32[]]$SelectedFieldIDs
    [System.Nullable[Boolean]]$IsPrivate
    [System.Nullable[Boolean]]$HasTimeOff
    [System.Nullable[Boolean]]$HasPortfolio
    [Boolean]$ShouldEnforceProjectMembership
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [System.Nullable[Boolean]]$IsPublic
    [System.Nullable[Boolean]]$IsPublished

    # Default constructor
    TeamDynamix_Api_Projects_ProjectSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Projects_ProjectSearch ([psobject]$ProjectSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_ProjectSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProjectSearch.$($Parameter.Name)
            }
            else
            {
                $this.$($Parameter.Name) = $ProjectSearch.$($Parameter.Name) | Get-Date
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Projects_ProjectSearch(
        [String] $Name,
        [String] $NameLike,
        [Boolean]$IsGlobal,
        [Int32[]]$PriorityIDs,
        [Int32[]]$AccountIDs,
        [Int32[]]$TypeIDs,
        [Int32[]]$ClassificationIDs,
        [Int32[]]$RiskIDs,
        [Int32[]]$ProcessIDs,
        [Int32[]]$GoalIDs,
        [Int32[]]$SystemIDs,
        [Int32[]]$PortfolioIDs,
        [System.Nullable[Double]]$RisksScoreFrom,
        [System.Nullable[Double]]$RisksScoreTo,
        [System.Nullable[Double]]$GoalsScoreFrom,
        [System.Nullable[Double]]$GoalsScoreTo,
        [System.Nullable[Double]]$ScorecardScoreFrom,
        [System.Nullable[Double]]$ScorecardScoreTo,
        [System.Nullable[Double]]$CompositeScoreFrom,
        [System.Nullable[Double]]$CompositeScoreTo,
        [System.Nullable[Double]]$CompositeScorePercentFrom,
        [System.Nullable[Double]]$CompositeScorePercentTo,
        [System.Nullable[DateTime]]$CreatedDateFrom,
        [System.Nullable[DateTime]]$CreatedDateTo,
        [String]$StartsOperator,
        [System.Nullable[DateTime]]$Starts,
        [String]$EndsOperator,
        [System.Nullable[DateTime]]$Ends,
        [System.Nullable[Double]]$EstimatedHoursFrom,
        [System.Nullable[Double]]$EstimatedHoursTo,
        [System.Nullable[Guid]]$ManagerUID,
        [Int32[]]$ProjectIDs,
        [Int32[]]$ProjectIDsExclude,
        [Int32[]]$PortfolioIDsExclude,
        [String] $StatusLastUpdatedOperator,
        [System.Nullable[DateTime]]$StatusLastUpdated,
        [Int32[]]$StatusIDs,
        [String] $BudgetOperator,
        [System.Nullable[Double]]$Budget,
        [String] $PercentCompleteOperator,
        [System.Nullable[Int32]]$PercentComplete,
        [System.Nullable[Boolean]]$IsOpen,
        [System.Nullable[Boolean]]$IsActive,
        [String] $SponsorName,
        [String] $SponsorEmail,
        [Guid]   $SponsorUID,
        [String] $ReportsToName,
        [System.Nullable[Guid]]$ReportsToUID,
        [Boolean]$CascadeReportsToUID,
        [Int32[]]$FunctionalRoleIDs,
        [Boolean]$ShowManagedByPlan,
        [Boolean]$ShowManagedByProject,
        [Boolean]$ShowManagedBoth,
        [Int32[]]$SelectedFieldIDs,
        [System.Nullable[Boolean]]$IsPrivate,
        [System.Nullable[Boolean]]$HasTimeOff,
        [System.Nullable[Boolean]]$HasPortfolio,
        [Boolean]$ShouldEnforceProjectMembership,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [System.Nullable[Boolean]]$IsPublic,
        [System.Nullable[Boolean]]$IsPublished)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_ProjectSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
            }
        }
    }
}

class TD_TeamDynamix_Api_Projects_ProjectSearch
{
    [String] $Name
    [String] $NameLike
    [Boolean]$IsGlobal
    [Int32[]]$PriorityIDs
    [Int32[]]$AccountIDs
    [Int32[]]$TypeIDs
    [Int32[]]$ClassificationIDs
    [Int32[]]$RiskIDs
    [Int32[]]$ProcessIDs
    [Int32[]]$GoalIDs
    [Int32[]]$SystemIDs
    [Int32[]]$PortfolioIDs
    [System.Nullable[Double]]$RisksScoreFrom
    [System.Nullable[Double]]$RisksScoreTo
    [System.Nullable[Double]]$GoalsScoreFrom
    [System.Nullable[Double]]$GoalsScoreTo
    [System.Nullable[Double]]$ScorecardScoreFrom
    [System.Nullable[Double]]$ScorecardScoreTo
    [System.Nullable[Double]]$CompositeScoreFrom
    [System.Nullable[Double]]$CompositeScoreTo
    [System.Nullable[Double]]$CompositeScorePercentFrom
    [System.Nullable[Double]]$CompositeScorePercentTo
    [String]$CreatedDateFrom
    [String]$CreatedDateTo
    [String]$StartsOperator
    [String]$Starts
    [String]$EndsOperator
    [String]$Ends
    [System.Nullable[Double]]$EstimatedHoursFrom
    [System.Nullable[Double]]$EstimatedHoursTo
    [System.Nullable[Guid]]$ManagerUID
    [Int32[]]$ProjectIDs
    [Int32[]]$ProjectIDsExclude
    [Int32[]]$PortfolioIDsExclude
    [String] $StatusLastUpdatedOperator
    [String] $StatusLastUpdated
    [Int32[]]$StatusIDs
    [String] $BudgetOperator
    [System.Nullable[Double]]$Budget
    [String] $PercentCompleteOperator
    [System.Nullable[Int32]]$PercentComplete
    [System.Nullable[Boolean]]$IsOpen
    [System.Nullable[Boolean]]$IsActive
    [String] $SponsorName
    [String] $SponsorEmail
    [Guid]   $SponsorUID
    [String] $ReportsToName
    [System.Nullable[Guid]]$ReportsToUID
    [Boolean]$CascadeReportsToUID
    [Int32[]]$FunctionalRoleIDs
    [Boolean]$ShowManagedByPlan
    [Boolean]$ShowManagedByProject
    [Boolean]$ShowManagedBoth
    [Int32[]]$SelectedFieldIDs
    [System.Nullable[Boolean]]$IsPrivate
    [System.Nullable[Boolean]]$HasTimeOff
    [System.Nullable[Boolean]]$HasPortfolio
    [Boolean]$ShouldEnforceProjectMembership
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [System.Nullable[Boolean]]$IsPublic
    [System.Nullable[Boolean]]$IsPublished

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Projects_ProjectSearch ([psobject]$ProjectSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_ProjectSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProjectSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ProjectSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ProjectSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_PlanSearch
{
    [String] $NameLike
    [Int32]  $ProjectID
    [Boolean]$IncludeEmpty

    # Default constructor
    TeamDynamix_Api_Plans_PlanSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_PlanSearch ([psobject]$PlanSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_PlanSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $PlanSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $PlanSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $PlanSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_PlanSearch(
        [String] $NameLike,
        [Int32]  $ProjectID,
        [Boolean]$IncludeEmpty)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_PlanSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_PlanEdit
{
    [Int32] $ProjectID
    [Int32] $PlanID
    [Int32] $DraftID
    [String]$Title
    [String]$Description

    # Default constructor
    TeamDynamix_Api_Plans_PlanEdit ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_PlanEdit ([psobject]$PlanEdit)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_PlanEdit]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $PlanEdit.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $PlanEdit.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $PlanEdit.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_PlanEdit(
        [Int32] $ProjectID,
        [Int32] $PlanID,
        [Int32] $DraftID,
        [String]$Title,
        [String]$Description)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_PlanEdit]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_PlanUpdates
{
    [TeamDynamix_Api_Plans_Task]$Plan
    [TeamDynamix_Api_Plans_Task[]]$Tasks
    [Boolean]$Succeeded
    [Boolean]$AnyNewTaskAssignments
    [Int32]  $ErrorID
    [String] $Message

    # Default constructor
    TeamDynamix_Api_PlanUpdates ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_PlanUpdates ([psobject]$PlanUpdates)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PlanUpdates]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $PlanUpdates.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $PlanUpdates.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $PlanUpdates.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_PlanUpdates(
        [TeamDynamix_Api_Plans_Task]$Plan,
        [TeamDynamix_Api_Plans_Task[]]$Tasks,
        [Boolean]$Succeeded,
        [Boolean]$AnyNewTaskAssignments,
        [Int32]  $ErrorID,
        [String] $Message)
    {
        foreach ($Parameter in ([TeamDynamix_Api_PlanUpdates]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Apps_OrgApplication
{
    [int32]  $AppID
    [string] $Name
    [string] $Description
    [string] $Type
    [string] $AppClass
    [string] $ExternalUrl
    [string] $Purpose
    [boolean]$Active
    [string] $PartialUrl

    # Default constructor
    TeamDynamix_Api_Apps_OrgApplication ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Apps_OrgApplication ([psobject]$OrgApplication)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Apps_OrgApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $OrgApplication.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $OrgApplication.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $OrgApplication.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Apps_OrgApplication(
        [int32]  $AppID,
        [string] $Name,
        [string] $Description,
        [string] $Type,
        [string] $AppClass,
        [string] $ExternalUrl,
        [string] $Purpose,
        [boolean]$Active,
        [string] $PartialUrl)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Apps_OrgApplication]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_ApplicationIdentifier
{
    [String]$AppID

    # Default constructor
    TeamDynamix_Api_Plans_ApplicationIdentifier ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_ApplicationIdentifier ([psobject]$ApplicationIdentifier)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_ApplicationIdentifier]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ApplicationIdentifier.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ApplicationIdentifier.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ApplicationIdentifier.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_ApplicationIdentifier(
        [String]$AppID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_ApplicationIdentifier]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_TaskChanges
{
    [TeamDynamix_Api_Plans_ApplicationIdentifier]$AppId
    [TeamDynamix_Api_Plans_Task]$Task
    [System.Nullable[Boolean]]  $NotifyNewResources

    # Default constructor
    TeamDynamix_Api_Plans_TaskChanges ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_TaskChanges ([psobject]$TaskChanges)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskChanges]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TaskChanges.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TaskChanges.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TaskChanges.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_TaskChanges(
        [TeamDynamix_Api_Plans_ApplicationIdentifier]$AppId,
        [TeamDynamix_Api_Plans_Task]$Task,
        [System.Nullable[Boolean]]  $NotifyNewResources)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskChanges]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Plans_TaskUpdate
{
    [Int32]   $ID
    [Int32]   $ProjectId
    [Int32]   $PlanId
    [Int32]   $TaskId
    [String[]]$Notify
    [String]  $Comments
    [DateTime]$CompletedDate
    [Int32]   $TimeTypeId
    [Int32]   $FunctionalRoleID
    [Double]  $HoursWorked
    [DateTime]$DateWorked
    [Double]  $PercentComplete
    [Double]  $RemainingHours
    [Boolean] $IsPrivate

    # Default constructor
    TeamDynamix_Api_Plans_TaskUpdate ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Plans_TaskUpdate ([psobject]$TaskUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Plans_TaskUpdate(
        [Int32]   $ID,
        [Int32]   $ProjectId,
        [Int32]   $PlanId,
        [Int32]   $TaskId,
        [String[]]$Notify,
        [String]  $Comments,
        [DateTime]$CompletedDate,
        [Int32]   $TimeTypeId,
        [Int32]   $FunctionalRoleID,
        [Double]  $HoursWorked,
        [DateTime]$DateWorked,
        [Double]  $PercentComplete,
        [Double]  $RemainingHours,
        [Boolean] $IsPrivate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Plans_TaskUpdate
{
    [Int32]   $ID
    [Int32]   $ProjectId
    [Int32]   $PlanId
    [Int32]   $TaskId
    [String[]]$Notify
    [String]  $Comments
    [String]  $CompletedDate
    [Int32]   $TimeTypeId
    [Int32]   $FunctionalRoleID
    [Double]  $HoursWorked
    [String]  $DateWorked
    [Double]  $PercentComplete
    [Double]  $RemainingHours
    [Boolean] $IsPrivate

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Plans_TaskUpdate ([psobject]$TaskUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Plans_TaskUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TaskUpdate.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_Risk
{
    [Boolean] $IsOpportunity
    [System.Nullable[Double]]$Impact
    [System.Nullable[Double]]$Probability
    [System.Nullable[Double]]$Urgency
    [System.Nullable[Int32]]$ResponseStrategyID
    [String]  $ResponseStrategyName
    [String]  $ResponseStrategyDescription
    [Int32]   $ID
    [String]  $Title
    [String]  $Description
    [Boolean] $IsRead
    [Int32]   $CategoryID
    [String]  $CategoryName
    [Int32]   $StatusID
    [String]  $StatusName
    [Int32]   $StatusValue
    [Int32]   $DaysOld
    [Int32]   $ProjectID
    [String]  $ProjectName
    [DateTime]$CreatedDate
    [String]  $CreatedFullName
    [String]  $CreatedUID
    [String]  $CreatedEmail
    [String]  $ResponsibleFullName
    [String]  $ResponsibleUID
    [String]  $ResponsibleEmail
    [Boolean] $ResponsibleIsRead
    [DateTime]$ResponsibleDateRead
    [DateTime]$ModifiedDate
    [String]  $ModifiedFullName
    [String]  $ModifiedUID
    [Boolean] $Flagged
    [DateTime]$DateFlagged
    [String]  $LastUpdateText
    [DateTime]$LastUpdatedDate
    [String]  $LastUpdatedByFullName
    [String]  $LastUpdatedByUID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [DateTime]$CompletedDate
    [String]  $CompletedUID
    [String]  $CompletedFullName

    # Default constructor
    TeamDynamix_Api_Issues_Risk ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_Risk ([psobject]$Risk)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_Risk]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Risk.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Risk.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Risk.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_Risk(
        [Boolean] $IsOpportunity,
        [System.Nullable[Double]]$Impact,
        [System.Nullable[Double]]$Probability,
        [System.Nullable[Double]]$Urgency,
        [System.Nullable[Int32]]$ResponseStrategyID,
        [String]  $ResponseStrategyName,
        [String]  $ResponseStrategyDescription,
        [Int32]   $ID,
        [String]  $Title,
        [String]  $Description,
        [Boolean] $IsRead,
        [Int32]   $CategoryID,
        [String]  $CategoryName,
        [Int32]   $StatusID,
        [String]  $StatusName,
        [Int32]   $StatusValue,
        [Int32]   $DaysOld,
        [Int32]   $ProjectID,
        [String]  $ProjectName,
        [DateTime]$CreatedDate,
        [String]  $CreatedFullName,
        [String]  $CreatedUID,
        [String]  $CreatedEmail,
        [String]  $ResponsibleFullName,
        [String]  $ResponsibleUID,
        [String]  $ResponsibleEmail,
        [Boolean] $ResponsibleIsRead,
        [DateTime]$ResponsibleDateRead,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedFullName,
        [String]  $ModifiedUID,
        [Boolean] $Flagged,
        [DateTime]$DateFlagged,
        [String]  $LastUpdateText,
        [DateTime]$LastUpdatedDate,
        [String]  $LastUpdatedByFullName,
        [String]  $LastUpdatedByUID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [DateTime]$CompletedDate,
        [String]  $CompletedUID,
        [String]  $CompletedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_Risk]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

        # Convenience constructor for editable parameters
        TeamDynamix_Api_Issues_Risk(
            [Boolean] $IsOpportunity,
            [System.Nullable[Double]]$Impact,
            [System.Nullable[Double]]$Probability,
            [System.Nullable[Double]]$Urgency,
            [System.Nullable[Int32]]$ResponseStrategyID,
            [String]  $Title,
            [String]  $Description,
            [Int32]   $CategoryID,
            [Int32]   $StatusID,
            [String]  $ResponsibleUID,
            [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
        {
            $this.IsOpportunity      = $IsOpportunity
            $this.Impact             = $Impact
            $this.Probability        = $Probability
            $this.Urgency            = $Urgency
            $this.ResponseStrategyID = $ResponseStrategyID
            $this.Title              = $Title
            $this.Description        = $Description
            $this.CategoryID         = $CategoryID
            $this.StatusID           = $StatusID
            $this.ResponsibleUID     = $ResponsibleUID
            $this.Attributes         = $Attributes
        }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Risk',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }
}

class TeamDynamix_Api_Issues_RiskSearch
{
    [Double[]]$Probabilities
    [Double[]]$Impacts
    [Double[]]$Urgencies
    [System.Nullable[Boolean]]$IsOpportunity
    [Int32[]] $ResponseStrategyIDs
    [System.Nullable[Int32]]$MaxResults
    [String]  $ID
    [Int32[]] $ProjectIDs
    [Int32[]] $StatusIDs
    [Int32[]] $StatusIDsNot
    [Int32[]] $CategoryIDs
    [DateTime]$ModifiedDateFrom
    [DateTime]$ModifiedDateTo
    [String]  $CreatedUID
    [DateTime]$CreatedDateFrom
    [DateTime]$CreatedDateTo
    [DateTime]$UpdatedFrom
    [DateTime]$UpdatedTo
    [String]  $UpdatedUID
    [String]  $ResponsibilityUID
    [String]  $NameLike
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes

    # Default constructor
    TeamDynamix_Api_Issues_RiskSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_RiskSearch ([psobject]$RiskSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_RiskSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_RiskSearch(
        [Double[]]$Probabilities,
        [Double[]]$Impacts,
        [Double[]]$Urgencies,
        [System.Nullable[Boolean]]$IsOpportunity,
        [Int32[]] $ResponseStrategyIDs,
        [System.Nullable[Int32]]$MaxResults,
        [String]  $ID,
        [Int32[]] $ProjectIDs,
        [Int32[]] $StatusIDs,
        [Int32[]] $StatusIDsNot,
        [Int32[]] $CategoryIDs,
        [DateTime]$ModifiedDateFrom,
        [DateTime]$ModifiedDateTo,
        [String]  $CreatedUID,
        [DateTime]$CreatedDateFrom,
        [DateTime]$CreatedDateTo,
        [DateTime]$UpdatedFrom,
        [DateTime]$UpdatedTo,
        [String]  $UpdatedUID,
        [String]  $ResponsibilityUID,
        [String]  $NameLike,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_RiskSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Issues_RiskSearch
{
    [Double[]]$Probabilities
    [Double[]]$Impacts
    [Double[]]$Urgencies
    [System.Nullable[Boolean]]$IsOpportunity
    [Int32[]] $ResponseStrategyIDs
    [System.Nullable[Int32]]$MaxResults
    [String]  $ID
    [Int32[]] $ProjectIDs
    [Int32[]] $StatusIDs
    [Int32[]] $StatusIDsNot
    [Int32[]] $CategoryIDs
    [String]  $ModifiedDateFrom
    [String]  $ModifiedDateTo
    [String]  $CreatedUID
    [String]  $CreatedDateFrom
    [String]  $CreatedDateTo
    [String]  $UpdatedFrom
    [String]  $UpdatedTo
    [String]  $UpdatedUID
    [String]  $ResponsibilityUID
    [String]  $NameLike
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Issues_RiskSearch ([psobject]$RiskSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_RiskSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $RiskSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_IssueStatus
{
    [Int32]  $ID
    [String] $Name
    [String] $Description
    [Double] $Order
    [TeamDynamix_Api_Statuses_StatusClass]$StatusClass
    [Boolean]$IsActive
    [Boolean]$IsDefault

    # Default constructor
    TeamDynamix_Api_Issues_IssueStatus ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_IssueStatus ([psobject]$IssueStatus)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueStatus]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IssueStatus.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $IssueStatus.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $IssueStatus.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_IssueStatus(
        [Int32]  $ID,
        [String] $Name,
        [String] $Description,
        [Double] $Order,
        [TeamDynamix_Api_Statuses_StatusClass]$StatusClass,
        [Boolean]$IsActive,
        [Boolean]$IsDefault)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueStatus]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_RiskUpdate
{
    [Int32]   $RiskId
    [Int32]   $ProjectId
    [Int32]   $StatusID
    [String[]]$Notify
    [String]  $Comments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [Boolean] $IsPrivate
    [boolean] $IsRichHtml

    # Default constructor
    TeamDynamix_Api_Issues_RiskUpdate ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_RiskUpdate ([psobject]$RiskUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_RiskUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $RiskUpdate.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $RiskUpdate.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $RiskUpdate.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_RiskUpdate(
        [Int32]   $RiskId,
        [Int32]   $ProjectId,
        [Int32]   $StatusID,
        [String[]]$Notify,
        [String]  $Comments,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [Boolean] $IsPrivate,
        [boolean] $IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_RiskUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_Issue
{
    [Double]  $EstimatedHours
    [Double]  $ActualHours
    [DateTime]$StartDate
    [DateTime]$EndDate
    [Int32]   $PriorityID
    [String]  $PriorityName
    [Double]  $PriorityOrder
    [Int32]   $TaskID
    [String]  $TaskName
    [Int32]   $ID
    [String]  $Title
    [String]  $Description
    [Boolean] $IsRead
    [Int32]   $CategoryID
    [String]  $CategoryName
    [Int32]   $StatusID
    [String]  $StatusName
    [Int32]   $StatusValue
    [Int32]   $DaysOld
    [Int32]   $ProjectID
    [String]  $ProjectName
    [DateTime]$CreatedDate
    [String]  $CreatedFullName
    [String]  $CreatedUID
    [String]  $CreatedEmail
    [String]  $ResponsibleFullName
    [String]  $ResponsibleUID
    [String]  $ResponsibleEmail
    [Boolean] $ResponsibleIsRead
    [DateTime]$ResponsibleDateRead
    [DateTime]$ModifiedDate
    [String]  $ModifiedFullName
    [String]  $ModifiedUID
    [Boolean] $Flagged
    [DateTime]$DateFlagged
    [String]  $LastUpdateText
    [DateTime]$LastUpdatedDate
    [String]  $LastUpdatedByFullName
    [String]  $LastUpdatedByUID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [DateTime]$CompletedDate
    [String]  $CompletedUID
    [String]  $CompletedFullName

    # Default constructor
    TeamDynamix_Api_Issues_Issue ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_Issue ([psobject]$Issue)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_Issue]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Issue.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Issue.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Issue.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_Issue(
        [Double]  $EstimatedHours,
        [Double]  $ActualHours,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [Int32]   $PriorityID,
        [String]  $PriorityName,
        [Double]  $PriorityOrder,
        [Int32]   $TaskID,
        [String]  $TaskName,
        [Int32]   $ID,
        [String]  $Title,
        [String]  $Description,
        [Boolean] $IsRead,
        [Int32]   $CategoryID,
        [String]  $CategoryName,
        [Int32]   $StatusID,
        [String]  $StatusName,
        [Int32]   $StatusValue,
        [Int32]   $DaysOld,
        [Int32]   $ProjectID,
        [String]  $ProjectName,
        [DateTime]$CreatedDate,
        [String]  $CreatedFullName,
        [String]  $CreatedUID,
        [String]  $CreatedEmail,
        [String]  $ResponsibleFullName,
        [String]  $ResponsibleUID,
        [String]  $ResponsibleEmail,
        [Boolean] $ResponsibleIsRead,
        [DateTime]$ResponsibleDateRead,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedFullName,
        [String]  $ModifiedUID,
        [Boolean] $Flagged,
        [DateTime]$DateFlagged,
        [String]  $LastUpdateText,
        [DateTime]$LastUpdatedDate,
        [String]  $LastUpdatedByFullName,
        [String]  $LastUpdatedByUID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [DateTime]$CompletedDate,
        [String]  $CompletedUID,
        [String]  $CompletedFullName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_Issue]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

        # Convenience constructor for editable parameters
        TeamDynamix_Api_Issues_Issue(
            [Double]  $EstimatedHours,
            [DateTime]$StartDate,
            [DateTime]$EndDate,
            [Int32]   $PriorityID,
            [Int32]   $TaskID,
            [String]  $Title,
            [String]  $Description,
            [Int32]   $CategoryID,
            [Int32]   $StatusID,
            [String]  $ResponsibleUID,
            [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
        {
            $this.EstimatedHours = $EstimatedHours
            $this.StartDate      = $StartDate      | Get-Date
            $this.EndDate        = $EndDate        | Get-Date
            $this.PriorityID     = $PriorityID
            $this.TaskID         = $TaskID
            $this.Title          = $Title
            $this.Description    = $Description
            $this.CategoryID     = $CategoryID
            $this.StatusID       = $StatusID
            $this.ResponsibleUID = $ResponsibleUID
            $this.Attributes     = $Attributes
        }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $Attribute.ID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($Attribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += $Attribute
        }
        else # $FoundAttribute is true and $Overwrite is false
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    # Delegating methods for AddCustomAttribute
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$Overwrite)
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Attribute in $Attributes)
        {
            $this.AddCustomAttribute($Attribute,$false)
        }
    }


    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue),$Overwrite)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute([TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Issue',$TDAuthentication,$Environment),$Overwrite)
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute]$Attribute)
    {
        $this.AddCustomAttribute($Attribute,$false)
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [int] $AttributeValue)
    {
        $this.AddCustomAttribute($AttributeID,$AttributeValue,$false)
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $this.AddCustomAttribute($AttributeName,$AttributeValue,$false,$TDAuthentication,$Environment)
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }
}

class TD_TeamDynamix_Api_Issues_Issue
{
    [Double] $EstimatedHours
    [Double] $ActualHours
    [String] $StartDate
    [String] $EndDate
    [Int32]  $PriorityID
    [String] $PriorityName
    [Double] $PriorityOrder
    [Int32]  $TaskID
    [String] $TaskName
    [Int32]  $ID
    [String] $Title
    [String] $Description
    [Boolean]$IsRead
    [Int32]  $CategoryID
    [String] $CategoryName
    [Int32]  $StatusID
    [String] $StatusName
    [Int32]  $StatusValue
    [Int32]  $DaysOld
    [Int32]  $ProjectID
    [String] $ProjectName
    [String] $CreatedDate
    [String] $CreatedFullName
    [String] $CreatedUID
    [String] $CreatedEmail
    [String] $ResponsibleFullName
    [String] $ResponsibleUID
    [String] $ResponsibleEmail
    [Boolean]$ResponsibleIsRead
    [String] $ResponsibleDateRead
    [String] $ModifiedDate
    [String] $ModifiedFullName
    [String] $ModifiedUID
    [Boolean]$Flagged
    [String] $DateFlagged
    [String] $LastUpdateText
    [String] $LastUpdatedDate
    [String] $LastUpdatedByFullName
    [String] $LastUpdatedByUID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [String] $CompletedDate
    [String] $CompletedUID
    [String] $CompletedFullName

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Issues_Issue ([psobject]$Issue)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_Issue]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Issue.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Issue.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Issue.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_IssueSearch
{
    [Int32[]] $PriorityIDs
    [DateTime]$EndDateFrom
    [DateTime]$EndDateTo
    [DateTime]$StartDateFrom
    [DateTime]$StartDateTo
    [Int32[]] $ParentIDs
    [System.Nullable[Int32]]$MaxResults
    [String]  $ID
    [Int32[]] $ProjectIDs
    [Int32[]] $StatusIDs
    [Int32[]] $StatusIDsNot
    [Int32[]] $CategoryIDs
    [DateTime]$ModifiedDateFrom
    [DateTime]$ModifiedDateTo
    [String]  $CreatedUID
    [DateTime]$CreatedDateFrom
    [DateTime]$CreatedDateTo
    [DateTime]$UpdatedFrom
    [DateTime]$UpdatedTo
    [String]  $UpdatedUID
    [String]  $ResponsibilityUID
    [String]  $NameLike
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes

    # Default constructor
    TeamDynamix_Api_Issues_IssueSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_IssueSearch ([psobject]$IssueSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_IssueSearch(
        [Int32[]] $PriorityIDs,
        [DateTime]$EndDateFrom,
        [DateTime]$EndDateTo,
        [DateTime]$StartDateFrom,
        [DateTime]$StartDateTo,
        [Int32[]] $ParentIDs,
        [System.Nullable[Int32]]$MaxResults,
        [String]  $ID,
        [Int32[]] $ProjectIDs,
        [Int32[]] $StatusIDs,
        [Int32[]] $StatusIDsNot,
        [Int32[]] $CategoryIDs,
        [DateTime]$ModifiedDateFrom,
        [DateTime]$ModifiedDateTo,
        [String]  $CreatedUID,
        [DateTime]$CreatedDateFrom,
        [DateTime]$CreatedDateTo,
        [DateTime]$UpdatedFrom,
        [DateTime]$UpdatedTo,
        [String]  $UpdatedUID,
        [String]  $ResponsibilityUID,
        [String]  $NameLike,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Issues_IssueSearch
{
    [Int32[]]$PriorityIDs
    [String] $EndDateFrom
    [String] $EndDateTo
    [String] $StartDateFrom
    [String] $StartDateTo
    [Int32[]]$ParentIDs
    [System.Nullable[Int32]]$MaxResults
    [String] $ID
    [Int32[]]$ProjectIDs
    [Int32[]]$StatusIDs
    [Int32[]]$StatusIDsNot
    [Int32[]]$CategoryIDs
    [String] $ModifiedDateFrom
    [String] $ModifiedDateTo
    [String] $CreatedUID
    [String] $CreatedDateFrom
    [String] $CreatedDateTo
    [String] $UpdatedFrom
    [String] $UpdatedTo
    [String] $UpdatedUID
    [String] $ResponsibilityUID
    [String] $NameLike
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Issues_IssueSearch ([psobject]$IssueSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $IssueSearch.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Issues_IssueUpdate
{
    [Int32]   $IssueId
    [DateTime]$TimeEntryDate
    [Double]  $HoursWorked
    [Int32]   $TimeTypeId
    [Int32]   $FunctionalRoleID
    [Int32]   $ParentId
    [Int32]   $ProjectId
    [Int32]   $StatusID
    [String[]]$Notify
    [String]  $Comments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [Boolean] $IsPrivate
    [boolean] $IsRichHtml

    # Default constructor
    TeamDynamix_Api_Issues_IssueUpdate ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Issues_IssueUpdate ([psobject]$IssueUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Issues_IssueUpdate(
        [Int32]   $IssueId,
        [DateTime]$TimeEntryDate,
        [Double]  $HoursWorked,
        [Int32]   $TimeTypeId,
        [Int32]   $FunctionalRoleID,
        [Int32]   $ParentId,
        [Int32]   $ProjectId,
        [Int32]   $StatusID,
        [String[]]$Notify,
        [String]  $Comments,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [Boolean] $IsPrivate,
        [boolean] $IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TD_TeamDynamix_Api_Issues_IssueUpdate
{
    [Int32]   $IssueId
    [String]  $TimeEntryDate
    [Double]  $HoursWorked
    [Int32]   $TimeTypeId
    [Int32]   $FunctionalRoleID
    [Int32]   $ParentId
    [Int32]   $ProjectId
    [Int32]   $StatusID
    [String[]]$Notify
    [String]  $Comments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [Boolean] $IsPrivate

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Issues_IssueUpdate ([psobject]$IssueUpdate)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Issues_IssueUpdate]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $IssueUpdate.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Briefcase_Folder
{
    [String]  $ID
    [String]  $Name
    [TeamDynamix_Api_Briefcase_Folder[]]$Folders
    [DateTime]$CreatedDate
    [String]  $Uri

    # Default constructor
    TeamDynamix_Api_Briefcase_Folder ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Briefcase_Folder ([psobject]$Folder)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Briefcase_Folder]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Folder.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Folder.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Folder.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Briefcase_Folder(
        [String]  $ID,
        [String]  $Name,
        [TeamDynamix_Api_Briefcase_Folder[]]$Folders,
        [DateTime]$CreatedDate,
        [String]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Briefcase_Folder]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Briefcase_File
{
    [Guid]  $ID
    [String]$Name
    [String]$Description
    [Int32] $Size
    [String]$Uri
    [String]$ContentUri

    # Default constructor
    TeamDynamix_Api_Briefcase_File ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Briefcase_File ([psobject]$File)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Briefcase_File]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $File.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $File.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $File.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Briefcase_File(
        [Guid]  $ID,
        [String]$Name,
        [String]$Description,
        [Int32] $Size,
        [String]$Uri,
        [String]$ContentUri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Briefcase_File]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserGroupsBulkManagementParameters
{
    [Guid[]] $UserUIDs
    [Int32[]]$GroupIDs
    [Boolean]$RemoveOtherGroups

    # Default constructor
    TeamDynamix_Api_Users_UserGroupsBulkManagementParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserGroupsBulkManagementParameters ([psobject]$UserGroupsBulkManagementParameters)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserGroupsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserGroupsBulkManagementParameters.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserGroupsBulkManagementParameters.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserGroupsBulkManagementParameters.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserGroupsBulkManagementParameters(
        [Guid[]] $UserUIDs,
        [Int32[]]$GroupIDs,
        [Boolean]$RemoveOtherGroups)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserGroupsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters
{
    [Guid[]] $UserUids
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [Boolean]$ReplaceExistingOrgApplications

    # Default constructor
    TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters ([psobject]$UserOrgApplicationsBulkManagementParameters)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserOrgApplicationsBulkManagementParameters.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserOrgApplicationsBulkManagementParameters.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserOrgApplicationsBulkManagementParameters.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters(
        [Guid[]] $UserUids,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [Boolean]$ReplaceExistingOrgApplications)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserOrgApplicationsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters
{
    [Guid[]]  $UserUids
    [String[]]$ApplicationNames
    [Boolean] $ReplaceExistingApplications

    # Default constructor
    TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters ([psobject]$UserApplicationsBulkManagementParameters)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserApplicationsBulkManagementParameters.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserApplicationsBulkManagementParameters.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserApplicationsBulkManagementParameters.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters(
        [Guid[]]  $UserUids,
        [String[]]$ApplicationNames,
        [Boolean] $ReplaceExistingApplications)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserApplicationsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserAccountsBulkManagementParameters
{
    [Guid[]] $UserUids
    [Int32[]]$AccountIDs
    [Boolean]$ReplaceExistingAccounts

    # Default constructor
    TeamDynamix_Api_Users_UserAccountsBulkManagementParameters ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserAccountsBulkManagementParameters ([psobject]$UserAccountsBulkManagementParameters)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserAccountsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserAccountsBulkManagementParameters.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserAccountsBulkManagementParameters.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserAccountsBulkManagementParameters.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserAccountsBulkManagementParameters(
        [Guid[]] $UserUids,
        [Int32[]]$AccountIDs,
        [Boolean]$ReplaceExistingAccounts)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserAccountsBulkManagementParameters]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_ServiceCatalog_ServiceOffering
{
    [Int32]   $ID
    [Int32]   $AppID
    [String]  $AppName
    [String]  $Name
    [String]  $ShortDescription
    [String]  $LongDescription
    [Int32]   $ParentServiceID
    [String]  $ParentServiceName
    [Int32]   $CategoryID
    [String]  $CategoryName
    [String]  $FullCategoryText
    [String]  $CompositeName
    [Double]  $Order
    [Boolean] $IsActive
    [Boolean] $IsPublic
    [Int32]   $IconCharCode
    [DateTime]$CreatedDateUtc
    [Guid]    $CreatedUID
    [String]  $CreatedFullName
    [DateTime]$ModifiedDateUtc
    [Guid]    $ModifiedUID
    [String]  $ModifiedFullName
    [Guid]    $ManagerUid
    [String]  $ManagerFullName
    [Int32]   $ManagingGroupID
    [String]  $ManagingGroupName
    [String]  $RequestText
    [String]  $SubmitText
    [String]  $RequestUrl
    [Int32]   $RequestApplicationID
    [String]  $RequestApplicationName
    [Boolean] $RequestApplicationIsActive
    [Int32]   $RequestTypeID
    [String]  $RequestTypeName
    [Boolean] $RequestTypeIsActive
    [TeamDynamix_Api_ServiceCatalog_RequestComponent]$RequestTypeComponent
    [Int32]   $RequestTypeCategoryID
    [String]  $RequestTypeCategoryName
    [Int32]   $WorkflowID
    [String]  $WorkflowName
    [Boolean] $ShouldNotifyResp
    [Boolean] $ShouldNotifyRequestor
    [Int32]   $MaintenanceScheduleID
    [String]  $MaintenanceScheduleName
    [Int32]   $ConfigurationItemID
    [String]  $ConfigurationItemName
    [Int32]   $ConfigurationItemAppID
    [String]  $ConfigurationItemAppName
    [String[]]$Tags
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [String]  $Uri

    # Default constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOffering ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ServiceCatalog_ServiceOffering ([psobject]$ServiceOffering)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOffering]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ServiceOffering.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ServiceOffering.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ServiceOffering.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOffering(
        [Int32]   $ID,
        [Int32]   $AppID,
        [String]  $AppName,
        [String]  $Name,
        [String]  $ShortDescription,
        [String]  $LongDescription,
        [Int32]   $ParentServiceID,
        [String]  $ParentServiceName,
        [Int32]   $CategoryID,
        [String]  $CategoryName,
        [String]  $FullCategoryText,
        [String]  $CompositeName,
        [Double]  $Order,
        [Boolean] $IsActive,
        [Boolean] $IsPublic,
        [Int32]   $IconCharCode,
        [DateTime]$CreatedDateUtc,
        [Guid]    $CreatedUID,
        [String]  $CreatedFullName,
        [DateTime]$ModifiedDateUtc,
        [Guid]    $ModifiedUID,
        [String]  $ModifiedFullName,
        [Guid]    $ManagerUid,
        [String]  $ManagerFullName,
        [Int32]   $ManagingGroupID,
        [String]  $ManagingGroupName,
        [String]  $RequestText,
        [String]  $RequestUrl,
        [Int32]   $RequestApplicationID,
        [String]  $RequestApplicationName,
        [Boolean] $RequestApplicationIsActive,
        [Int32]   $RequestTypeID,
        [String]  $RequestTypeName,
        [Boolean] $RequestTypeIsActive,
        [TeamDynamix_Api_ServiceCatalog_RequestComponent]$RequestTypeComponent,
        [Int32]   $RequestTypeCategoryID,
        [String]  $RequestTypeCategoryName,
        [Int32]   $WorkflowID,
        [String]  $WorkflowName,
        [Boolean] $ShouldNotifyResp,
        [Boolean] $ShouldNotifyRequestor,
        [Int32]   $MaintenanceScheduleID,
        [String]  $MaintenanceScheduleName,
        [Int32]   $ConfigurationItemID,
        [String]  $ConfigurationItemName,
        [Int32]   $ConfigurationItemAppID,
        [String]  $ConfigurationItemAppName,
        [String[]]$Tags,
        [TeamDynamix_Api_Attachments_Attachment[]]$Attachments,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [String]  $Uri)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOffering]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_FunctionalRole_FunctionalRole
{
    [Int32] $ID
    [String]$Name

    # Default constructor
    TeamDynamix_Api_FunctionalRole_FunctionalRole ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_FunctionalRole_FunctionalRole ([psobject]$FunctionalRole)
    {
        foreach ($Parameter in ([TeamDynamix_Api_FunctionalRole_FunctionalRole]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $FunctionalRole.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $FunctionalRole.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $FunctionalRole.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_FunctionalRole_FunctionalRole(
        [Int32] $ID,
        [String]$Name)
    {
        foreach ($Parameter in ([TeamDynamix_Api_FunctionalRole_FunctionalRole]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Assets_Contract
{
    [Int32]   $ID
    [Int32]   $AppID
    [String]  $AppName
    [String]  $ContractNumber
    [Double]  $ContractPrice
    [String]  $Description
    [Int32]   $ProviderID
    [String]  $ProviderName
    [Boolean] $IsFixedModel
    [String]  $DateModel
    [DateTime]$StartDate
    [DateTime]$EndDate
    [Int32]   $SlidingDefaultDuration
    [TeamDynamix_Api_Assets_SlidingContractDateUnit]$SlidingDefaultDateUnit
    [String]  $SlidingDefaultDateUnitName
    [TeamDynamix_Api_Assets_ContractType]$TypeID
    [String]  $TypeName
    [Int32]   $AccountID
    [String]  $AccountName
    [DateTime]$CreatedDate
    [String]  $CreatedUID
    [String]  $CreatedFullName
    [DateTime]$ModifiedDate
    [String]  $ModifiedUID
    [String]  $ModifiedFullName
    [Int32]   $AssetsCount
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [Boolean] $IsActive

    # Default constructor
    TeamDynamix_Api_Assets_Contract ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_Contract ([psobject]$Contract)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Contract]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Contract.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Contract.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Contract.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_Contract(
        [Int32]   $ID,
        [Int32]   $AppID,
        [String]  $AppName,
        [String]  $ContractNumber,
        [Double]  $ContractPrice,
        [String]  $Description,
        [Int32]   $ProviderID,
        [String]  $ProviderName,
        [Boolean] $IsFixedModel,
        [String]  $DateModel,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [Int32]   $SlidingDefaultDuration,
        [TeamDynamix_Api_Assets_SlidingContractDateUnit]$SlidingDefaultDateUnit,
        [String]  $SlidingDefaultDateUnitName,
        [TeamDynamix_Api_Assets_ContractType]$TypeID,
        [String]  $TypeName,
        [Int32]   $AccountID,
        [String]  $AccountName,
        [DateTime]$CreatedDate,
        [String]  $CreatedUID,
        [String]  $CreatedFullName,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedUID,
        [String]  $ModifiedFullName,
        [Int32]   $AssetsCount,
        [TeamDynamix_Api_Attachments_Attachment[]]$Attachments,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [Boolean] $IsActive)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Contract]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_Assets_Contract(
        [String]  $ContractNumber,
        [Double]  $ContractPrice,
        [String]  $Description,
        [Int32]   $ProviderID,
        [Boolean] $IsFixedModel,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [Int32]   $SlidingDefaultDuration,
        [TeamDynamix_Api_Assets_SlidingContractDateUnit]$SlidingDefaultDateUnit,
        [TeamDynamix_Api_Assets_ContractType]$TypeID,
        [Int32]   $AccountID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [Boolean] $IsActive)
    {
        $this.ContractNumber         = $ContractNumber
        $this.ContractPrice          = $ContractPrice
        $this.Description            = $Description
        $this.ProviderID             = $ProviderID
        $this.IsFixedModel           = $IsFixedModel
        $this.StartDate              = $StartDate              | Get-Date
        $this.EndDate                = $EndDate                | Get-Date
        $this.SlidingDefaultDuration = $SlidingDefaultDuration
        $this.SlidingDefaultDateUnit = $SlidingDefaultDateUnit
        $this.TypeID                 = $TypeID
        $this.AccountID              = $AccountID
        $this.Attributes             = $Attributes
        $this.IsActive               = $IsActive
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($CustomAttribute in $Attributes)
        {
            # Check to see if attribute is already present
            $FoundAttribute = $this.Attributes | Where-Object ID -eq $CustomAttribute.ID
            if (-not $FoundAttribute)
            {
                # Add attribute
                $this.Attributes += $CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($CustomAttribute in $Attributes)
        {
            # Check to see if attribute is already present
            $FoundAttribute = $this.Attributes | Where-Object ID -eq $CustomAttribute.ID
            # Remove if Overwrite is set and the attribute is present
            if ($FoundAttribute -and $Overwrite)
            {
                $this.RemoveCustomAttribute($CustomAttribute.ID)
            }
            if ((-not $FoundAttribute) -or $Overwrite)
            {
                # Add attribute
                $this.Attributes += $CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [Int] $AttributeValue)
    {
        # Check to see if attribute is already present on the asset
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $AttributeID
        if (-not $FoundAttribute)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [Int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $AttributeID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($AttributeID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object Name -eq $AttributeName
        if (-not $FoundAttribute)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Asset',$AppID,$TDAuthentication,$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object Name -eq $AttributeName
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($FoundAttribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Asset',$AppID,$TDAuthentication,$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }
}

class TD_TeamDynamix_Api_Assets_Contract
{
    [Int32]  $ID
    [Int32]  $AppID
    [String] $AppName
    [String] $ContractNumber
    [Double] $ContractPrice
    [String] $Description
    [Int32]  $ProviderID
    [String] $ProviderName
    [Boolean]$IsFixedModel
    [String] $DateModel
    [String] $StartDate
    [String] $EndDate
    [Int32]  $SlidingDefaultDuration
    [TeamDynamix_Api_Assets_SlidingContractDateUnit]$SlidingDefaultDateUnit
    [String] $SlidingDefaultDateUnitName
    [TeamDynamix_Api_Assets_ContractType]$TypeID
    [String] $TypeName
    [Int32]  $AccountID
    [String] $AccountName
    [String] $CreatedDate
    [String] $CreatedUID
    [String] $CreatedFullName
    [String] $ModifiedDate
    [String] $ModifiedUID
    [String] $ModifiedFullName
    [Int32]  $AssetsCount
    [TeamDynamix_Api_Attachments_Attachment[]]$Attachments
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes
    [Boolean]$IsActive

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_Assets_Contract ([psobject]$Contract)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_Contract]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $Contract.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $Contract.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $Contract.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Assets_ContractSearch
{
    [String]  $NameLike
    [Int32[]] $ProviderIDs
    [DateTime]$StartDateFrom
    [DateTime]$StartDateTo
    [DateTime]$EndDateFrom
    [DateTime]$EndDateTo
    [Int32[]] $AssetIDs
    [Int32[]] $ExcludeAssetIDs
    [Double]  $ContractPriceFrom
    [Double]  $ContractPriceTo
    [TeamDynamix_Api_Assets_ContractType[]]$ContractTypeIDs
    [Int32[]] $AccountIDs
    [Boolean] $IsActive
    [Boolean] $IsFixedDateModel
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes
    [Int32]   $MaxResults

    # Default constructor
    TeamDynamix_Api_Assets_ContractSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Assets_ContractSearch ([psobject]$ContractSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ContractSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ContractSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ContractSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ContractSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Assets_ContractSearch(
        [String]  $NameLike,
        [Int32[]] $ProviderIDs,
        [DateTime]$StartDateFrom,
        [DateTime]$StartDateTo,
        [DateTime]$EndDateFrom,
        [DateTime]$EndDateTo,
        [Int32[]] $AssetIDs,
        [Int32[]] $ExcludeAssetIDs,
        [Double]  $ContractPriceFrom,
        [Double]  $ContractPriceTo,
        [TeamDynamix_Api_Assets_ContractType[]]$ContractTypeIDs,
        [Int32[]] $AccountIDs,
        [Boolean] $IsActive,
        [Boolean] $IsFixedDateModel,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$CustomAttributes,
        [Int32]   $MaxResults)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Assets_ContractSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_ServiceCatalog_ServiceCategory
{
    [Int32]   $ID
    [Int32]   $AppID
    [String]  $AppName
    [Int32]   $ParentID
    [String]  $ParentName
    [Double]  $Order
    [String]  $Name
    [String]  $Description
    [Boolean] $IsActive
    [Int32]   $IconCharCode
    [String]  $IconColor
    [Boolean] $IsPublic
    [Boolean] $AllowlistGroups
    [Boolean] $InheritPermissions
    [DateTime]$CreatedDate
    [Guid]    $CreatedUid
    [String]  $CreatedFullName
    [DateTime]$ModifiedDate
    [Guid]    $ModifiedUid
    [String]  $ModifiedFullName
    [TeamDynamix_Api_ServiceCatalog_ServiceCategory[]]$Subcategories

    # Default constructor
    TeamDynamix_Api_ServiceCatalog_ServiceCategory ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ServiceCatalog_ServiceCategory ([psobject]$ServiceCategory)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ServiceCategory.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ServiceCategory.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ServiceCategory.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ServiceCatalog_ServiceCategory(
        [Int32]   $ID,
        [Int32]   $AppID,
        [String]  $AppName,
        [Int32]   $ParentID,
        [String]  $ParentName,
        [Double]  $Order,
        [String]  $Name,
        [String]  $Description,
        [Boolean] $IsActive,
        [Int32]   $IconCharCode,
        [String]  $IconColor,
        [Boolean] $IsPublic,
        [Boolean] $AllowlistGroups,
        [Boolean] $InheritPermissions,
        [DateTime]$CreatedDate,
        [Guid]    $CreatedUid,
        [String]  $CreatedFullName,
        [DateTime]$ModifiedDate,
        [Guid]    $ModifiedUid,
        [String]  $ModifiedFullName,
        [TeamDynamix_Api_ServiceCatalog_ServiceCategory[]]$Subcategories)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_ServiceCatalog_ServiceCategory(
        [Int32]  $ParentID,
        [Double] $Order,
        [String] $Name,
        [String] $Description,
        [Boolean]$IsActive,
        [Int32]  $IconCharCode,
        [String] $IconColor)
    {
        $this.ParentID     = $ParentID
        $this.Order        = $Order
        $this.Name         = $Name
        $this.Description  = $Description
        $this.IsActive     = $IsActive
        $this.IconCharCode = $IconCharCode
        $this.IconColor    = $IconColor
    }
}

class TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch
{
    [String] $SearchText
    [Int32]  $RequestFormID
    [Int32]  $CategoryID
    [Guid]   $ManagerUID
    [Int32]  $ManagingGroupID
    [Int32[]]$MaintenanceWindowIDs
    [Boolean]$IsActive
    [Boolean]$IsPublic
    [Int32]  $ReturnCount
    [Boolean]$IncludeLongDescription
    [Boolean]$IncludeShortcuts

    # Default constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch ([psobject]$ServiceOrOfferingSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ServiceOrOfferingSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ServiceOrOfferingSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ServiceOrOfferingSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch(
        [String] $SearchText,
        [Int32]  $RequestFormID,
        [Int32]  $CategoryID,
        [Guid]   $ManagerUID,
        [Int32]  $ManagingGroupID,
        [Int32[]]$MaintenanceWindowIDs,
        [Boolean]$IsActive,
        [Boolean]$IsPublic,
        [Int32]  $ReturnCount,
        [Boolean]$IncludeLongDescription,
        [Boolean]$IncludeShortcuts)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ServiceCatalog_ServiceOrOfferingSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions
{
    [String]$SearchText
    [TeamDynamix_Api_RequestPage]$Page

    # Default constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions ([psobject]$ConfigurationItemSavedSearchOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ConfigurationItemSavedSearchOptions.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ConfigurationItemSavedSearchOptions.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ConfigurationItemSavedSearchOptions.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions(
        [String]$SearchText,
        [TeamDynamix_Api_RequestPage]$Page)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Cmdb_ConfigurationItemSavedSearchOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_TicketListing
{
    [Int32]   $ID
    [String]  $Title
    [Int32]   $AppID
    [String]  $AppName
    [Int32]   $ClassificationID
    [String]  $ClassificationName
    [Int32]   $StatusID
    [String]  $StatusName
    [Int32]   $AccountID
    [String]  $AccountName
    [Int32]   $TypeCategoryID
    [String]  $TypeCategoryName
    [Int32]   $TypeID
    [String]  $TypeName
    [Guid]    $CreatedUid
    [DateTime]$CreatedDate
    [String]  $CreatedFullName
    [Guid]    $ModifiedUid
    [DateTime]$ModifiedDate
    [String]  $ModifiedFullName
    [Guid]    $ContactUid
    [String]  $ContactFullName
    [DateTime]$StartDate
    [DateTime]$EndDate
    [DateTime]$RespondByDate
    [DateTime]$ResolveByDate
    [DateTime]$GoesOffHoldDate
    [Boolean] $IsArchived
    [Int32]   $PriorityID
    [String]  $PriorityName
    [Int32]   $LocationID
    [String]  $LocationName
    [Int32]   $LocationRoomID
    [String]  $LocationRoomName

    # Default constructor
    TeamDynamix_Api_Tickets_TicketListing ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_TicketListing ([psobject]$TicketListing)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TicketListing.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TicketListing.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TicketListing.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_TicketListing(
        [Int32]   $ID,
        [String]  $Title,
        [Int32]   $AppID,
        [String]  $AppName,
        [Int32]   $ClassificationID,
        [String]  $ClassificationName,
        [Int32]   $StatusID,
        [String]  $StatusName,
        [Int32]   $AccountID,
        [String]  $AccountName,
        [Int32]   $TypeCategoryID,
        [String]  $TypeCategoryName,
        [Int32]   $TypeID,
        [String]  $TypeName,
        [Guid]    $CreatedUid,
        [DateTime]$CreatedDate,
        [String]  $CreatedFullName,
        [Guid]    $ModifiedUid,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedFullName,
        [Guid]    $ContactUid,
        [String]  $ContactFullName,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [DateTime]$RespondByDate,
        [DateTime]$ResolveByDate,
        [DateTime]$GoesOffHoldDate,
        [Boolean] $IsArchived,
        [Int32]   $PriorityID,
        [String]  $PriorityName,
        [Int32]   $LocationID,
        [String]  $LocationName,
        [Int32]   $LocationRoomID,
        [String]  $LocationRoomName)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_TicketListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Users_UserListing
{
    [Guid]   $UID
    [Int32]  $ReferenceID
    [String] $UserName
    [String] $FirstName
    [String] $LastName
    [String] $FullName
    [String] $PrimaryEmail
    [String] $AlertEmail
    [String] $AuthenticationUserName
    [String] $ExternalID
    [String] $AlternateID
    [Boolean]$IsEmployee
    [Boolean]$IsActive
    [Boolean]$IsConfidential
    [TeamDynamix_Api_Users_UserType]$TypeID
    [Int32]  $DefaultAccountID

    # Default constructor
    TeamDynamix_Api_Users_UserListing ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Users_UserListing ([psobject]$UserListing)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserListing.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserListing.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserListing.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Users_UserListing(
        [Guid]   $UID,
        [Int32]  $ReferenceID,
        [String] $UserName,
        [String] $FirstName,
        [String] $LastName,
        [String] $FullName,
        [String] $PrimaryEmail,
        [String] $AlertEmail,
        [String] $AuthenticationUserName,
        [String] $ExternalID,
        [String] $AlternateID,
        [Boolean]$IsEmployee,
        [Boolean]$IsActive,
        [Boolean]$IsConfidential,
        [TeamDynamix_Api_Users_UserType]$TypeID,
        [Int32]  $DefaultAccountID)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Users_UserListing]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_TypeCategories_TypeCategory
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [DateTime]$CreatedDate
    [String]  $CreatedByUid
    [String]  $CreatedByFullName
    [DateTime]$ModifiedDate
    [String]  $ModifiedByUid
    [String]  $ModifiedByFullName
    [Double]  $Order
    [Boolean] $IsActive

    # Default constructor
    TeamDynamix_Api_TypeCategories_TypeCategory ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_TypeCategories_TypeCategory ([psobject]$TypeCategory)
    {
        foreach ($Parameter in ([TeamDynamix_Api_TypeCategories_TypeCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $TypeCategory.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $TypeCategory.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $TypeCategory.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_TypeCategories_TypeCategory(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [DateTime]$CreatedDate,
        [String]  $CreatedByUid,
        [String]  $CreatedByFullName,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedByUid,
        [String]  $ModifiedByFullName,
        [Double]  $Order,
        [Boolean] $IsActive)
    {
        foreach ($Parameter in ([TeamDynamix_Api_TypeCategories_TypeCategory]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

        # Convenience constructor for editable parameters
        TeamDynamix_Api_TypeCategories_TypeCategory(
                [String]  $Name,
                [String]  $Description,
                [Double]  $Order,
                [Boolean] $IsActive)
        {
                $this.Name        = $Name
                $this.Description = $Description
                $this.Order       = $Order
                $this.IsActive    = $IsActive
        }
}

class TeamDynamix_Api_Projects_ProjectType
{
    [Int32]   $ID
    [String]  $Name
    [String]  $Description
    [Int32]   $CategoryID
    [String]  $CategoryName
    [String]  $FullName
    [Boolean] $IsActive
    [DateTime]$CreatedDate
    [String]  $CreatedByUid
    [DateTime]$ModifiedDate
    [String]  $ModifiedByUid
    [Guid]    $EvaluatorUid
    [String]  $EvaluatorFullName
    [String]  $EvaluatorEmail
    [Boolean] $NotifyEvaluator

    # Default constructor
    TeamDynamix_Api_Projects_ProjectType ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Projects_ProjectType ([psobject]$ProjectType)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_ProjectType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProjectType.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ProjectType.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ProjectType.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Projects_ProjectType(
        [Int32]   $ID,
        [String]  $Name,
        [String]  $Description,
        [Int32]   $CategoryID,
        [String]  $CategoryName,
        [String]  $FullName,
        [Boolean] $IsActive,
        [DateTime]$CreatedDate,
        [String]  $CreatedByUid,
        [DateTime]$ModifiedDate,
        [String]  $ModifiedByUid,
        [Guid]    $EvaluatorUid,
        [String]  $EvaluatorFullName,
        [String]  $EvaluatorEmail,
        [Boolean] $NotifyEvaluator)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Projects_ProjectType]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

        # Convenience constructor for editable parameters
        TeamDynamix_Api_Projects_ProjectType(
                [String]  $Name,
                [String]  $Description,
                [Int32]   $CategoryID,
                [Boolean] $IsActive,
                [Guid]    $EvaluatorUid,
                [Boolean] $NotifyEvaluator)
        {
                $this.Name            = $Name
                $this.Description     = $Description
                $this.CategoryID      = $CategoryID
                $this.IsActive        = $IsActive
                $this.EvaluatorUid    = $EvaluatorUid
                $this.NotifyEvaluator = $NotifyEvaluator
        }
}

class TeamDynamix_Api_Schedules_ResourcePool
{
    [Int32]   $ID
    [String]  $Name
    [DateTime]$CreatedDate
    [DateTime]$ModifiedDate
    [Boolean] $IsActive
    [Boolean] $NotifyOnAssignment
    [Boolean] $RequiresApproval
    [String]  $ManagerFullName
    [Guid]    $ManagerUID
    [Int32]   $ResourceCount

    # Default constructor
    TeamDynamix_Api_Schedules_ResourcePool ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Schedules_ResourcePool ([psobject]$ResourcePool)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Schedules_ResourcePool]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ResourcePool.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ResourcePool.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ResourcePool.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Schedules_ResourcePool(
        [Int32]   $ID,
        [String]  $Name,
        [DateTime]$CreatedDate,
        [DateTime]$ModifiedDate,
        [Boolean] $IsActive,
        [Boolean] $NotifyOnAssignment,
        [Boolean] $RequiresApproval,
        [String]  $ManagerFullName,
        [Guid]    $ManagerUID,
        [Int32]   $ResourceCount)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Schedules_ResourcePool]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

        # Convenience constructor for editable parameters
        TeamDynamix_Api_Schedules_ResourcePool(
                [String]  $Name,
                [Boolean] $IsActive,
                [Boolean] $NotifyOnAssignment,
                [Boolean] $RequiresApproval,
                [Guid]    $ManagerUID)
        {
                $this.Name               = $Name
                $this.IsActive           = $IsActive
                $this.NotifyOnAssignment = $NotifyOnAssignment
                $this.RequiresApproval   = $RequiresApproval
                $this.ManagerUID         = $ManagerUID
        }
}

class TeamDynamix_Api_Schedules_ResourcePoolSearch
{
    [String] $Name
    [Guid]   $ManagerUID
    [Int32]  $MaxResults
    [Boolean]$IsActive
    [Boolean]$ReturnItemCounts

    # Default constructor
    TeamDynamix_Api_Schedules_ResourcePoolSearch ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Schedules_ResourcePoolSearch ([psobject]$ResourcePoolSearch)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Schedules_ResourcePoolSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ResourcePoolSearch.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ResourcePoolSearch.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ResourcePoolSearch.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Schedules_ResourcePoolSearch(
        [String] $Name,
        [Guid]   $ManagerUID,
        [Int32]  $MaxResults,
        [Boolean]$IsActive,
        [Boolean]$ReturnItemCounts)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Schedules_ResourcePoolSearch]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_ProjectRequests_ProjectRequest
{
    [Int32]   $ID
    [String]  $Name
    [DateTime]$StartDate
    [DateTime]$EndDate
    [Int32]   $AccountID
    [Int32]   $TypeID
    [Int32]   $ServiceID
    [Int32]   $ServiceOfferingID
    [Int32]   $PriorityID
    [Guid]    $SponsorUID
    [String]  $Description
    [String]  $Requirements
    [Boolean] $AssignServiceFormIfExists
    [Int32]   $ClassificationID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes

    # Default constructor
    TeamDynamix_Api_ProjectRequests_ProjectRequest ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_ProjectRequests_ProjectRequest ([psobject]$ProjectRequest)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ProjectRequests_ProjectRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_ProjectRequests_ProjectRequest(
        [Int32]   $ID,
        [String]  $Name,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [Int32]   $AccountID,
        [Int32]   $TypeID,
        [Int32]   $ServiceID,
        [Int32]   $ServiceOfferingID,
        [Int32]   $PriorityID,
        [Guid]    $SponsorUID,
        [String]  $Description,
        [String]  $Requirements,
        [Boolean] $AssignServiceFormIfExists,
        [Int32]   $ClassificationID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ProjectRequests_ProjectRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

    # Convenience constructor for editable parameters
    TeamDynamix_Api_ProjectRequests_ProjectRequest(
        [String]  $Name,
        [DateTime]$StartDate,
        [DateTime]$EndDate,
        [Int32]   $AccountID,
        [Int32]   $TypeID,
        [Int32]   $ServiceID,
        [Int32]   $ServiceOfferingID,
        [Int32]   $PriorityID,
        [Guid]    $SponsorUID,
        [String]  $Description,
        [String]  $Requirements,
        [Boolean] $AssignServiceFormIfExists,
        [Int32]   $ClassificationID,
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        $this.Name                      = $Name
        $this.StartDate                 = $StartDate                 | Get-Date
        $this.EndDate                   = $EndDate                   | Get-Date
        $this.AccountID                 = $AccountID
        $this.TypeID                    = $TypeID
        $this.ServiceID                 = $ServiceID
        $this.ServiceOfferingID         = $ServiceOfferingID
        $this.PriorityID                = $PriorityID
        $this.SponsorUID                = $SponsorUID
        $this.Description               = $Description
        $this.Requirements              = $Requirements
        $this.AssignServiceFormIfExists = $AssignServiceFormIfExists
        $this.ClassificationID          = $ClassificationID
        $this.Attributes                = $Attributes
    }

    # Methods
    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes)
    {
        foreach ($CustomAttribute in $Attributes)
        {
            # Check to see if attribute is already present
            $FoundAttribute = $this.Attributes | Where-Object ID -eq $CustomAttribute.ID
            if (-not $FoundAttribute)
            {
                # Add attribute
                $this.Attributes += $CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes,
        [boolean]$Overwrite)
    {
        foreach ($CustomAttribute in $Attributes)
        {
            # Check to see if attribute is already present
            $FoundAttribute = $this.Attributes | Where-Object ID -eq $CustomAttribute.ID
            # Remove if Overwrite is set and the attribute is present
            if ($FoundAttribute -and $Overwrite)
            {
                $this.RemoveCustomAttribute($CustomAttribute.ID)
            }
            if ((-not $FoundAttribute) -or $Overwrite)
            {
                # Add attribute
                $this.Attributes += $CustomAttribute
            }
            else
            {
                Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
            }
        }
    }

    [void] AddCustomAttribute (
        [int] $AttributeID,
        [Int] $AttributeValue)
    {
        # Check to see if attribute is already present on the asset
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $AttributeID
        if (-not $FoundAttribute)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [int]    $AttributeID,
        [Int]    $AttributeValue,
        [boolean]$Overwrite)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object ID -eq $AttributeID
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($AttributeID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeID,$AttributeValue)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object Name -eq $AttributeName
        if (-not $FoundAttribute)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Project',$AppID,$TDAuthentication,$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] AddCustomAttribute (
        [string]   $AttributeName,
        [string]   $AttributeValue,
        [boolean]  $Overwrite,
        [int]      $AppID,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        # Check to see if attribute is already present
        $FoundAttribute = $this.Attributes | Where-Object Name -eq $AttributeName
        # Remove if Overwrite is set and the attribute is present
        if ($FoundAttribute -and $Overwrite)
        {
            $this.RemoveCustomAttribute($FoundAttribute.ID)
        }
        if ((-not $FoundAttribute) -or $Overwrite)
        {
            # Add attribute
            $this.Attributes += [TeamDynamix_Api_CustomAttributes_CustomAttribute]::new($AttributeName,$AttributeValue,'Project',$AppID,$TDAuthentication,$Environment)
        }
        else
        {
            Write-ActivityHistory -MessageChannel 'Error' -Message "Attribute $($FoundAttribute.Name) is already present on $this.Name."
        }
    }

    [void] RemoveCustomAttribute (
        [int] $AttributeID)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object ID -ne $AttributeID
        $this.Attributes = $UpdatedAttributeList
    }

    [void] RemoveCustomAttribute (
        [string] $AttributeName)
    {
        $UpdatedAttributeList = $this.Attributes | Where-Object Name -ne $AttributeName
        $this.Attributes = $UpdatedAttributeList
    }
}

class TD_TeamDynamix_Api_ProjectRequests_ProjectRequest
{
    [Int32]  $ID
    [String] $Name
    [String] $StartDate
    [String] $EndDate
    [Int32]  $AccountID
    [Int32]  $TypeID
    [Int32]  $ServiceID
    [Int32]  $ServiceOfferingID
    [Int32]  $PriorityID
    [Guid]   $SponsorUID
    [String] $Description
    [String] $Requirements
    [Boolean]$AssignServiceFormIfExists
    [Int32]  $ClassificationID
    [TeamDynamix_Api_CustomAttributes_CustomAttribute[]]$Attributes

    # Constructor from object (such as a return from REST API)
    TD_TeamDynamix_Api_ProjectRequests_ProjectRequest ([psobject]$ProjectRequest)
    {
        foreach ($Parameter in ([TeamDynamix_Api_ProjectRequests_ProjectRequest]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name) | ForEach-Object {$_ | Get-Date -Format o}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $ProjectRequest.$($Parameter.Name) | Get-Date -Format o
                }
            }
        }
    }
}

class TeamDynamix_Api_Permissions_PermissionStore
{
    [Boolean]$InheritPermissions
    [Boolean]$IsPublic
    [Int32[]]$GroupIDs
    [Boolean]$AllowlistGroups

    # Default constructor
    TeamDynamix_Api_Permissions_PermissionStore ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Permissions_PermissionStore ([psobject]$PermissionStore)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Permissions_PermissionStore]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $PermissionStore.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $PermissionStore.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $PermissionStore.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Permissions_PermissionStore(
        [Boolean]$InheritPermissions,
        [Boolean]$IsPublic,
        [Int32[]]$GroupIDs,
        [Boolean]$AllowlistGroups)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Permissions_PermissionStore]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_MoveTicketOptions
{
    [Int32]  $NewAppID
    [Int32]  $NewFormID
    [Int32]  $NewTicketTypeID
    [Int32]  $NewStatusID
    [String] $Comments
    [Boolean]$IsRichHtml

    # Default constructor
    TeamDynamix_Api_Tickets_MoveTicketOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_MoveTicketOptions ([psobject]$MoveTicketOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_MoveTicketOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $MoveTicketOptions.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $MoveTicketOptions.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $MoveTicketOptions.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_MoveTicketOptions(
        [Int32]  $NewAppID,
        [Int32]  $NewFormID,
        [Int32]  $NewTicketTypeID,
        [Int32]  $NewStatusID,
        [String] $Comments,
        [Boolean]$IsRichHtml)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_MoveTicketOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_SlaAssignmentOptions
{
    [Int32]   $NewSlaID
    [TeamDynamix_Api_Tickets_SlaStartBasis]$StartBasis
    [Boolean] $ShouldCascade
    [String[]]$Notify
    [String]  $Comments

    # Default constructor
    TeamDynamix_Api_Tickets_SlaAssignmentOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_SlaAssignmentOptions ([psobject]$SlaAssignmentOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_SlaAssignmentOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $SlaAssignmentOptions.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $SlaAssignmentOptions.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $SlaAssignmentOptions.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_SlaAssignmentOptions(
        [Int32]   $NewSlaID,
        [TeamDynamix_Api_Tickets_SlaStartBasis]$StartBasis,
        [Boolean] $ShouldCascade,
        [String[]]$Notify,
        [String]  $Comments)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_SlaAssignmentOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}

class TeamDynamix_Api_Tickets_SlaRemovalOptions
{
    [Boolean] $ShouldCascade
    [String[]]$Notify
    [String]  $Comments

    # Default constructor
    TeamDynamix_Api_Tickets_SlaRemovalOptions ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TeamDynamix_Api_Tickets_SlaRemovalOptions ([psobject]$SlaRemovalOptions)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_SlaRemovalOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $SlaRemovalOptions.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $SlaRemovalOptions.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $SlaRemovalOptions.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TeamDynamix_Api_Tickets_SlaRemovalOptions(
        [Boolean] $ShouldCascade,
        [String[]]$Notify,
        [String]  $Comments)
    {
        foreach ($Parameter in ([TeamDynamix_Api_Tickets_SlaRemovalOptions]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }
}
#endregion

#region Script working classes, not derived from TeamDynamix objects
# Stores user data for use with user updates
class TD_UserInfo
{
    [string]  $Username
    [guid]    $UID
    [string]  $LastName
    [string]  $FirstName
    [string]  $MiddleName
    [boolean] $IsActive
    [string]  $PrimaryEmail
    [string]  $AlternateEmail
    [string]  $AlertEmail
    [string]  $Company
    [string]  $Title
    [string]  $WorkAddress
    [string]  $WorkCity
    [string]  $WorkState
    [string]  $WorkZip
    [string]  $WorkPhone
    [int]     $LocationRoomID
    [string]  $LocationRoomName
    [int]     $LocationID
    [string]  $LocationName
    [int]     $DefaultAccountID
    [string]  $DefaultAccountName
    [string]  $AlternateID
    [string]  $SecurityRoleID
    [string]  $SecurityRoleName
    [guid]    $DesktopID
    [string[]]$Applications
    [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications
    [int]     $PrimaryClientPortalApplicationID

    # Default constructor
    TD_UserInfo ()
    {
    }

    # Constructor from object (such as a return from REST API)
    TD_UserInfo ([psobject]$UserInfo)
    {
        foreach ($Parameter in ([TD_UserInfo]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = $UserInfo.$($Parameter.Name)
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = $UserInfo.$($Parameter.Name) | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = $UserInfo.$($Parameter.Name) | Get-Date
                }
            }
        }
    }

    # Full constructor
    TD_UserInfo (
        [string]  $Username,
        [guid]    $UID,
        [string]  $LastName,
        [string]  $FirstName,
        [string]  $MiddleName,
        [boolean] $IsActive,
        [string]  $PrimaryEmail,
        [string]  $AlternateEmail,
        [string]  $AlertEmail,
        [string]  $Company,
        [string]  $Title,
        [string]  $WorkAddress,
        [string]  $WorkCity,
        [string]  $WorkState,
        [string]  $WorkZip,
        [string]  $WorkPhone,
        [int]     $LocationRoomID,
        [string]  $LocationRoomName,
        [int]     $LocationID,
        [string]  $LocationName,
        [int]     $DefaultAccountID,
        [string]  $DefaultAccountName,
        [string]  $AlternateID,
        [string]  $SecurityRoleID,
        [string]  $SecurityRoleName,
        [guid]    $DesktopID,
        [string[]]$Applications,
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications,
        [int]     $PrimaryClientPortalApplicationID)
    {
        foreach ($Parameter in ([TD_UserInfo]::new() | Get-Member -MemberType Property))
        {
            if ($Parameter.Definition -notmatch '^datetime')
            {
                $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value
            }
            else
            {
                if ($Parameter.Definition -match '^datetime\[\]') # Handle array of dates
                {
                    if ($null -ne $this.$($Parameter.Name))
                    {
                        $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | ForEach-Object {$_ | Get-Date}
                    }
                }
                else # Single date
                {
                    $this.$($Parameter.Name) = (Get-Variable -Name $Parameter.Name).Value | Get-Date
                }
            }
        }
    }

    # Methods
    [void] SetUserRole (
        [string]$UserRoleName,
        [hashtable]$TDAuthentication,
        [EnvironmentChoices]$Environment)
    {
        $RoleData = $script:TDConfig.UserRoles | Where-Object Name -eq $UserRoleName
        if ($RoleData)
        {
            $this.SecurityRoleID   = ($script:TDSecurityRoles.Get($RoleData.UserSecurityRole,$Environment)).ID
            $this.SecurityRoleName = $RoleData.UserSecurityRole
            $this.Applications     = $RoleData.Applications
            $this.OrgApplications  = Get-OrgAppsByRoleName -UserRoleName $UserRoleName -AuthenticationToken $TDAuthentication -Environment $Environment
            $this.PrimaryClientPortalApplicationID = ($this.OrgApplications | Where-Object SystemClass -eq TDClient | Select-Object -First 1).ID
        }
    }
    [void] SetSecurityRoleID (
        [string]$SecurityRoleID)
    {
        $this.SecurityRoleID = $SecurityRoleID
    }
    [void] SetApplications (
        [string[]]$Applications)
    {
        $this.Applications = $Applications
    }
    [void] SetOrgApplications (
        [TeamDynamix_Api_Apps_UserApplication[]]$OrgApplications)
    {
        $this.OrgApplications = $OrgApplications
    }
}

# Base class for caching TeamDynamix object data
#  Constructs an in-memory cache, with separate containers for each environment name.
#  In each environment container is another container for each AppID, which contains the objects.
#  Data flows only into the cache from TeamDynamix. There is no capability to modify cached data locally or push it to TeamDynamix.
#
#  Prvate methods
#   Add         - Adds an object to the cache. Checks to see if the object exists in the cache first, with GetCached, then adds the object if necessary.
#                 Add by target name/ID must be overridden. For data types with no lookup by name/ID, they must be flagged as invalid actions.
#   Remove      - Removes an object from the cache.
#   FlushCache  - Removes all objects from the cache. Used automatically when re-authenticating. Should be used when making changes to the data on TeamDynamix.
#   Replace     - Replaces an object in the cache.
#   GetCached   - Internal function, retrieves an object from the cache. Calls LoadTargets if the requested environment/AppID combination does not exist.
#               - Assumes that all possible data has been populated if the environment/AppID container exists. Override if that's not true.
#
#  Public methods
#   Get         - Public version of GetCached. Must be overridden if detail is needed. Add already supports detail by default.
#   GetAll      - Gets all objects from the cache. Calls LoadTargets if the requested environment/AppID combination does not exist.
#   LoadTargets - Loads objects into the cache using the Add method, which expects objects. Objects are typically retrieved by calling the corresponding Get-TD command that retrieves all entries.
#  Additional methods may be added as appropriate for the data type.
#
class Object_Cache
{
    # $WorkingEnvironment points at the working environment cache
    hidden [hashtable]$WorkingEnvironment
    hidden [hashtable]$Production
    hidden [hashtable]$Sandbox
    hidden [hashtable]$Preview
    hidden [int]      $DefaultAppID

    # Default constructor
    Object_Cache ()
    {
        $type = $this.GetType()

        if ($type -eq [Object_Cache])
        {
            throw "Class $type must be inherited"
        }
    }

    # Methods
    #  Add by target object - all add commands pass through here
    #  Override for detail or for cases where there's no ID
    hidden [void]Add(
        [System.Object]     $TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        # Add
        #  Add new items, or replace existing items if detail information isn't present
        $CachedTargetObject = $null
        if ($CheckCache)
        {
            # This check is skipped when bulk-loading data, since the cache is empty when that happens
            $CachedTargetObject = $this.GetCached($TargetObject.Name,$AppID,$Environment)
        }
        if (-not $CachedTargetObject)
        {
            # Create the array holder for the data, if none exists
            if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
            {
                $this.$Environment += @{"AppID$AppID" = @()}
            }
            $this.$Environment."AppID$AppID" += $TargetObject
        }
        $this.WorkingEnvironment = $this.$script:WorkingEnvironment
    }
    #  Add multiple targets
    hidden [void]Add(
        [System.Object[]]   $TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        foreach ($Target in $TargetObject)
        {
            $this.Add($Target,$AppID,$Environment,$Detail,$CheckCache)
        }
    }
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Must override this method"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Must override this method"
    }
    #  Delegating methods for Add
    #  Add by target object, default AppID
    hidden [void]Add(
        [System.Object]     $TargetObject,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        $this.Add($TargetObject,$this.DefaultAppID,$Environment,$Detail,$CheckCache)
    }
    #  Add multiple targets, default AppID
    hidden [void]Add(
        [System.Object[]]   $TargetObject,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        foreach ($Target in $TargetObject)
        {
            $this.Add($TargetObject,$this.DefaultAppID,$Environment,$Detail,$CheckCache)
        }
    }
    #  Add by target name, default AppID
    hidden [void]Add(
        [string]            $TargetName,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add($TargetName,$this.DefaultAppID,$Environment,$Detail)
    }
    #  Add by target ID, default AppID
    hidden [void]Add(
        [int]               $TargetID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add($TargetID,$this.DefaultAppID,$Environment,$Detail)
    }
    #  Add by target object, default Environment
    hidden [void]Add(
        [System.Object]$TargetObject,
        [int]          $AppID,
        [switch]       $Detail,
        [switch]       $CheckCache
        )
    {
        $this.Add($TargetObject,$AppID,$script:WorkingEnvironment,$Detail,$CheckCache)
    }
    #  Add multiple targets, default Environment
    hidden [void]Add(
        [System.Object[]]$TargetObject,
        [int]            $AppID,
        [switch]         $Detail,
        [switch]         $CheckCache
        )
    {
        foreach ($Target in $TargetObject)
        {
            $this.Add($TargetObject,$AppID,$script:WorkingEnvironment,$Detail,$CheckCache)
        }
    }
    #  Add by target name, default Environment
    hidden [void]Add(
        [string]$TargetName,
        [int]   $AppID,
        [switch]$Detail
        )
    {
        $this.Add($TargetName,$AppID,$script:WorkingEnvironment,$Detail)
    }
    #  Add by target ID, default Environment
    hidden [void]Add(
        [int]   $TargetID,
        [int]   $AppID,
        [switch]$Detail
        )
    {
        $this.Add($TargetID,$AppID,$script:WorkingEnvironment,$Detail)
    }
    #  Add by target object, default AppID and Environment
    hidden [void]Add(
        [System.Object]$TargetObject
        )
    {
        $this.Add($TargetObject,$script:WorkingEnvironment,$true,$true)
    }
    #  Add by target object array, default AppID and Environment
    hidden [void]Add(
        [System.Object[]]$TargetObject
        )
    {
        $this.Add($TargetObject,$script:WorkingEnvironment,$true,$true)
    }
    #  Add by target name, default AppID and Environment
    hidden [void]Add(
        [string]$TargetName
        )
    {
        $this.Add($TargetName,$script:WorkingEnvironment,$true,$true)
    }
    #  Add by target ID, default AppID and Environment
    hidden [void]Add(
        [int]$TargetID
        )
    {
        $this.Add($TargetID,$script:WorkingEnvironment,$true,$true)
    }

    # Remove
    #  Remove $TargetObject in cache by creating temporary copy, clearing existing list and adding everything back, except the one to delete
    hidden [void]Remove(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Copy targets to temporary array
        $TemporaryTargets = $this.$Environment."AppID$AppID".Clone()
        # Erase targets array
        $this.FlushCache($AppID,$Environment)
        # Add targets back from temporary array
        foreach ($Target in $TemporaryTargets)
        {
            # Exclude desired target
            if ($Target.ID -ne $TargetID)
            {
                $this.Add($Target,$AppID,$Environment,$false,$false)
            }
        }
    }
    #  Delegating methods for remove
    hidden [void]Remove(
        [int]$TargetID
        )
    {
        $this.Remove($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }

    # FlushCache
    #  Remove all cached targets for a specific app and environment
    [void]FlushCache(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $this.$Environment."AppID$AppID" = @()
    }
    #  Remove all cached targets for all apps in a specific environment
    [void]FlushCache(
        [EnvironmentChoices]$Environment
        )
    {
        $this.$Environment = @{}
    }
    #  Delegating method for FlushCache
    [void]FlushCache()
    {
        $this.FlushCache($this.DefaultAppID,$script:WorkingEnvironment)
    }

    # Replace
    #  Replace $TargetObject in cache by removing it and re-adding it
    hidden [void]Replace(
        [system.object]     $TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Remove entry with matching ID from cache
        $this.Remove($TargetObject.ID,$AppID,$Environment)
        # Add replacement entry to cache
        $this.Add($TargetObject,$AppID,$Environment,$false,$true)
    }
    #  Delegating method for replace
    hidden [void]Replace(
        [system.object]$TargetObject
        )
    {
        $this.Replace($TargetObject.ID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    # GetCached
    #  Get a target from the cache, by name
    hidden [system.object]GetCached(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object Name -eq $TargetName
    }
    #  Get a target from the cache, by ID
    hidden [system.object]GetCached(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object ID -eq $TargetID
    }
    # Delegating methods for GetCached
    #  Get a target from the cache, by name
    hidden [system.object]GetCached(
        [string]$TargetName
        )
    {
        return $this.GetCached($TargetName,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    #  Get a target from the cache, by ID
    hidden [system.object]GetCached(
        [int]$TargetID
        )
    {
        return $this.GetCached($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }

    # Get
    #  Get a target from the cache, if present; if not retrieve and add to cache - by name
    #  Override needed for cases where detail is needed.
    [system.object]Get(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetName,$AppID,$Environment)
        return $Target
    }
    #  Get a target from the cache, if present, if not retrieve and add to cache - by ID
    [system.object]Get(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetID,$AppID,$Environment)
        return $Target
    }
    #  Delegating methods for Get
    [system.object]Get(
        [int]               $TargetID,
        [EnvironmentChoices]$Environment
        )
    {
        return $this.Get($TargetID,$this.DefaultAppID,$Environment)
    }
    [system.object]Get(
        [string]            $TargetName,
        [EnvironmentChoices]$Environment
        )
    {
        return $this.Get($TargetName,$this.DefaultAppID,$Environment)
    }
    [system.object]Get(
        [int]$TargetID,
        [int]$AppID
        )
    {
        return $this.Get($TargetID,$AppID,$script:WorkingEnvironment)
    }
    [system.object]Get(
        [string]$TargetName,
        [int]   $AppID
        )
    {
        return $this.Get($TargetName,$AppID,$script:WorkingEnvironment)
    }
    [system.object]Get(
        [int]$TargetID
        )
    {
        return $this.Get($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    [system.object]Get(
        [string]$TargetName
        )
    {
        return $this.Get($TargetName,$this.DefaultAppID,$script:WorkingEnvironment)
    }

    # GetAll
    #  Get all targets from the cache for an environment, if present; if not retrieve and add to cache
    [system.object[]]GetAll(
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Retrieve data for cache
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($AppID,$Environment)
        }
        # Start with all entries, filter if necessary
        $Return = $this.$Environment."AppID$AppID"
        # Check for entry IsActive status and filter if requested
        if (-not $null -eq $IsActive)
        {
            # Objects can have property of "Active" or "IsActive" - determine which is present
            #  If object has no matching property, no filter is applied
            if ($Return | Get-Member -Name IsActive)
            {
                $Return = $Return | Where-Object IsActive -eq $IsActive
            }
            elseif ($Return | Get-Member -Name Active)
            {
                $Return = $Return | Where-Object Active -eq $IsActive
            }
        }
        else
        {
            $Return = $this.$Environment."AppID$AppID"
        }
        return $Return
    }
    #  Delegating methods for GetAll
    [system.object[]]GetAll(
        [int]   $AppID,
        [string]$Environment
        )
    {
        return $this.GetAll($AppID,$Environment,$null)
    }
    [system.object[]]GetAll(
        [string]                  $Environment, # Use string here to differentiate between a string and an int, (enums are both)
        [system.nullable[boolean]]$IsActive
        )
    {
        return $this.GetAll($this.DefaultAppID,$Environment,$IsActive)
    }
    [system.object[]]GetAll(
        [string]$Environment # Use string here to differentiate between a string and an int, (enums are both)
        )
    {
        return $this.GetAll($this.DefaultAppID,$Environment,$null)
    }
    [system.object[]]GetAll(
        [int]$AppID
        )
    {
        return $this.GetAll($AppID,$script:WorkingEnvironment,$null)
    }
    [system.object[]]GetAll(
        [System.Nullable[boolean]]$IsActive
        )
    {
        return $this.GetAll($this.DefaultAppID,$script:WorkingEnvironment,$IsActive)
    }
    [system.object[]]GetAll()
    {
        return $this.GetAll($this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
    [system.object[]]Get()
    {
        return $this.GetAll()
    }

    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw "Must override this method"
    }
    #  Delegating method for LoadTargets
    [void]LoadTargets()
    {
        $this.LoadTargets($this.DefaultAppID,$script:WorkingEnvironment)
    }
}

# Stores location (building/room) data
class TD_Location_Cache : Object_Cache
{
    # Default constructor
    TD_Location_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target object - all add commands pass through here
    hidden [void]Add(
        [TeamDynamix_Api_Locations_Location]$TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        # Add
        #  Add new items, or replace existing items if detail information isn't present
        $CachedTargetObject = $null
        if ($CheckCache)
        {
            # This check is skipped when bulk-loading data, since the cache is empty when that happens
            $CachedTargetObject = $this.GetCached($TargetObject.Name,$AppID,$Environment)
        }
        if (-not $CachedTargetObject)
        {
            if ($Detail)
            {
                # Look up detail data if not present
                if (-not $TargetObject.Rooms)
                {
                    $TargetObject = Get-TDLocation -ID $TargetObject.ID -Environment $Environment
                }
            }
            # Create the array holder for the data, if none exists
            if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
            {
                $this.$Environment += @{"AppID$AppID" = @()}
            }
            $this.$Environment."AppID$AppID" += $TargetObject
        }
        else
        {
            if ($Detail)
            {
                # Look up detail data if not present
                if (-not $CachedTargetObject.Rooms)
                {
                    #Replace existing entry with one that contains detail data
                    $this.Replace((Get-TDLocation -ID $TargetObject.ID -Environment $Environment),$AppID,$Environment)
                }
            }
        }
        $this.WorkingEnvironment = $this.$script:WorkingEnvironment
    }
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDLocation -NameLike $TargetName -Exact -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDLocation -ID $TargetID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # Get
    #  Get a target from the cache, if present; if not retrieve and add to cache - by name
    [system.object]Get(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetName,$AppID,$Environment)
        # Check to see if target and detail data exist
        if ($Target.Rooms)
        {
            return $Target
        }
        else
        {
            # No target or detail data, add target with detail to cache
            $this.Add($TargetName,$AppID,$Environment,$true)
            # Extract newly-added/updated entry from cache
            return $this.GetCached($TargetName,$AppID,$Environment)
        }
    }
    #  Get a target from the cache, if present, if not retrieve and add to cache - by ID
    [system.object]Get(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetID,$AppID,$Environment)
        # Check to see if target and detail data exist
        if ($Target.Rooms)
        {
            return $Target
        }
        else
        {
            # No target or no detail data, add target with detail to cache
            $this.Add($TargetID,$AppID,$Environment,$true)
            # Extract newly-added/updated entry from cache
            return $this.GetCached($TargetID,$AppID,$Environment)
        }
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDLocation -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByExternalID
    #  Get a target from the cache by external ID
    [TeamDynamix_Api_Locations_Location]GetByExternalID(
        [string]            $ExternalID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object ExternalID -eq $ExternalID
        # Ensure detail data in included by passing through Get by ID, which pulls detail data
        if ($Target)
        {
            return $this.Get($Target.ID,$this.DefaultAppID,$Environment)
        }
        else
        {
            return $null
        }
    }
    # GetRoomByExternalID
    #  Get a target from the cache by external ID
    [TeamDynamix_Api_Locations_Location]GetRoomByExternalID(
        [string]            $BuildingExternalID,
        [string]            $RoomExternalID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object ExternalID -eq $BuildingExternalID
        # Ensure detail data in included by passing through Get by ID, which pulls detail data
        if ($Target)
        {
            $Target = $this.Get($Target.ID,$this.DefaultAppID,$Environment)
            $Target = $this.Rooms | Where-Object ExternalID -eq $RoomExternalID
            if ($Target)
            {
                return $Target
            }
            else
            {
                return $null
            }
        }
        else
        {
            return $null
        }
    }
    #  Delegating method for GetByExternalID
    [TeamDynamix_Api_Locations_Location]GetByExternalID(
        [string]$ExternalID
        )
    {
        return $this.GetByExternalID($ExternalID,$script:WorkingEnvironment)
    }
    #  Get a room from the cache by location ID and room ID and Environment
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [int]               $LocationID,
        [int]               $RoomID,
        [EnvironmentChoices]$Environment
        )
    {
        # Get the target (side-effect collects detail data)
        $TargetObject = $this.Get($LocationID,$this.DefaultAppID,$Environment)
        # Match room
        $DetailObject = $TargetObject.Rooms | Where-Object ID -eq $RoomID
        return $DetailObject
    }
    #  Get a room from the cache by location name and room ID and Environment
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [string]            $LocationName,
        [int]               $RoomID,
        [EnvironmentChoices]$Environment
        )
    {
        # Get the target (side-effect collects detail data)
        $TargetObject = $this.Get($LocationName,$this.DefaultAppID,$Environment)
        # Match room
        $DetailObject = $TargetObject.Rooms | Where-Object ID -eq $RoomID
        return $DetailObject
    }
    #  Get a room from the cache by location ID and room name and Environment
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [int]               $LocationID,
        [string]            $RoomName,
        [EnvironmentChoices]$Environment
        )
    {
        # Get the target (side-effect collects detail data)
        $TargetObject = $this.Get($LocationID,$this.DefaultAppID,$Environment)
        # Match room
        $DetailObject = $TargetObject.Rooms | Where-Object Name -eq $RoomName
        return $DetailObject
    }
    #  Get a room from the cache by location name and room name and Environment
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [string]            $LocationName,
        [string]            $RoomName,
        [EnvironmentChoices]$Environment
        )
    {
        # Get the target (side-effect collects detail data)
        $TargetObject = $this.Get($LocationName,$this.DefaultAppID,$Environment)
        # Match room
        $DetailObject = $TargetObject.Rooms | Where-Object Name -eq $RoomName
        return $DetailObject
    }
    #  Delegating method for GetRoom
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [int]$LocationID,
        [int]$RoomID
        )
    {
        $DetailObject = $this.GetRoom($LocationID,$RoomID,$script:WorkingEnvironment)
        return $DetailObject
    }
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [string]$LocationName,
        [int]   $RoomID
        )
    {
        $DetailObject = $this.GetRoom($LocationName,$RoomID,$script:WorkingEnvironment)
        return $DetailObject
    }
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [int]   $LocationID,
        [string]$RoomName
        )
    {
        $DetailObject = $this.GetRoom($LocationID,$RoomName,$script:WorkingEnvironment)
        return $DetailObject
    }
    [TeamDynamix_Api_Locations_LocationRoom]GetRoom(
        [string]$LocationName,
        [string]$RoomName
        )
    {
        $DetailObject = $this.GetRoom($LocationName,$RoomName,$script:WorkingEnvironment)
        return $DetailObject
    }
}

# Stores application data
class TD_Application_Cache : Object_Cache
{
    # Default constructor
    TD_Application_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target object - all add commands pass through here
    hidden [void]Add(
        [TeamDynamix_Api_Apps_OrgApplication]$TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        # Add
        #  Add new items, or replace existing items if detail information isn't present
        $CachedTargetObject = $null
        if ($CheckCache)
        {
            # This check is skipped when bulk-loading data, since the cache is empty when that happens
            $TargetObject | Add-Member -MemberType AliasProperty -Name ID -Value AppID
            $CachedTargetObject = $this.GetCached($TargetObject.Name,$AppID,$Environment)
        }
        if (-not $CachedTargetObject)
        {
            # Add an ID property alias set to AppID if the ID is not already present
            if (-not $TargetObject.ID)
            {
                $TargetObject | Add-Member -MemberType AliasProperty -Name ID -Value AppID
            }
            # Create the array holder for the data, if none exists
            if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
            {
                $this.$Environment += @{"AppID$AppID" = @()}
            }
            $this.$Environment."AppID$AppID" += $TargetObject
        }
        $this.WorkingEnvironment = $this.$script:WorkingEnvironment
    }
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw 'Invalid cache action.'
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw 'Invalid cache action.'
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDApplication -IsActive $null -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByType
    #  Get a target from the cache by type
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByType(
        [string]            $Type,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object Type -eq $Type
        return $Target
    }
    #  Delegating method for GetByType
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByType(
        [string]$Type
        )
    {
        return $this.GetByType($Type,$script:WorkingEnvironment)
    }
    # GetByAppClass
    #  Get a target from the cache by application class
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByAppClass(
        [string]            $AppClass,
        [EnvironmentChoices]$Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment,$IsActive) | Where-Object AppClass -eq $AppClass
        return $Target
    }
    #  Delegating method for GetByAppClass
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByAppClass(
        [string]            $AppClass,
        [EnvironmentChoices]$Environment
        )
    {
        return $this.GetByAppClass($AppClass,$Environment,$null)
    }
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByAppClass(
        [string]                  $AppClass,
        [system.nullable[boolean]]$IsActive
        )
    {
        return $this.GetByAppClass($AppClass,$script:WorkingEnvironment,$IsActive)
    }
    [TeamDynamix_Api_Apps_OrgApplication[]]GetByAppClass(
        [string]$AppClass
        )
    {
        return $this.GetByAppClass($AppClass,$script:WorkingEnvironment,$null)
    }
}

# Stores account (department) data
class TD_Account_Cache : Object_Cache
{
    # Default constructor
    TD_Account_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDAccount -SearchText $TargetName -Exact -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by ID
        $this.Add((Get-TDAccount -ID $TargetID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDAccount -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByCode
    #  Get a target from the cache by code
    [TeamDynamix_Api_Accounts_Account[]]GetByCode(
        [string]            $Code,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object Code -eq $Code
        return $Target
    }
    #  Delegating method for GetByCode
    [TeamDynamix_Api_Accounts_Account[]]GetByCode(
        [string]$Code
        )
    {
        return $this.GetByCode($Code,$script:WorkingEnvironment)
    }
    # GetByParent
    #  Get a target from the cache by parent
    [TeamDynamix_Api_Accounts_Account[]]GetByParent(
        [string]            $ParentName,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object ParentName -eq $ParentName
        return $Target
    }
    [TeamDynamix_Api_Accounts_Account[]]GetByParent(
        [int]               $ParentID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object ParentID -eq $ParentID
        return $Target
    }
    #  Delegating method for GetByParent
    [TeamDynamix_Api_Accounts_Account[]]GetByParent(
        [string]$ParentName
        )
    {
        return $this.GetByParent($ParentName,$script:WorkingEnvironment)
    }
    [TeamDynamix_Api_Accounts_Account[]]GetByParent(
        [int]$ParentID
        )
    {
        return $this.GetByParent($ParentID,$script:WorkingEnvironment)
    }
}

# Stores group data
class TD_Group_Cache : Object_Cache
{
    # Default constructor
    TD_Group_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDGroup -NameLike $TargetName -Exact -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by ID
        $this.Add((Get-TDGroup -ID $TargetID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDGroup -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByExternalID
    #  Get a target from the cache by external ID
    [TeamDynamix_Api_Users_Group[]]GetByExternalID(
        [string]            $ExternalID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($this.DefaultAppID,$Environment) | Where-Object ExternalID -eq $ExternalID
        return $Target
    }
    #  Delegating method for GetByExternalID
    [TeamDynamix_Api_Users_Group[]]GetByExternalID(
        [string]$ExternalID
        )
    {
        return $this.GetByExternalID($ExternalID,$script:WorkingEnvironment)
    }
}

# Stores product model data
class TD_ProductModel_Cache : Object_Cache
{
    # Default constructor
    TD_ProductModel_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_ProductModel_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDProductModel -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDProductModel -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDProductModel -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByType
    #  Get a target from the cache by type
    [TeamDynamix_Api_Assets_ProductModel[]]GetByType(
        [string]            $TypeName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ProductTypeName -eq $TypeName
        return $Target
    }
    [TeamDynamix_Api_Assets_ProductModel[]]GetByType(
        [int]               $TypeID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ProductTypeID -eq $TypeID
        return $Target
    }
    #  Delegating method for GetByType
    [TeamDynamix_Api_Assets_ProductModel[]]GetByType(
        [string]$TypeName
        )
    {
        return $this.GetByType($TypeName,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    [TeamDynamix_Api_Assets_ProductModel[]]GetByType(
        [int]$TypeID
        )
    {
        return $this.GetByType($TypeID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    # GetByManufacturer
    #  Get a target from the cache by manufacturer
    [TeamDynamix_Api_Assets_ProductModel[]]GetByManufacturer(
        [string]            $ManufacturerName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ManufacturerName -eq $ManufacturerName
        return $Target
    }
    [TeamDynamix_Api_Assets_ProductModel[]]GetByManufacturer(
        [int]               $ManufacturerID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ManufacturerID -eq $ManufacturerID
        return $Target
    }
    #  Delegating method for GetByManufacturer
    [TeamDynamix_Api_Assets_ProductModel[]]GetByManufacturer(
        [string]$TypeName
        )
    {
        return $this.GetByManufacturer($TypeName,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    [TeamDynamix_Api_Assets_ProductModel[]]GetByManufacturer(
        [int]$TypeID
        )
    {
        return $this.GetByManufacturer($TypeID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    # GetByPartNumber
    #  Get a target from the cache by part number
    [TeamDynamix_Api_Assets_ProductModel[]]GetByPartNumber(
        [string]            $PartNumber,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object PartNumber -eq $PartNumber
        return $Target
    }
    #  Delegating method for GetByPartNumber
    [TeamDynamix_Api_Assets_ProductModel[]]GetByPartNumber(
        [string]$PartNumber
        )
    {
        return $this.GetByPartNumber($PartNumber,$this.DefaultAppID,$script:WorkingEnvironment)
    }
}

# Stores form data
# Must always specify AppID since this can be a portal, ticket, or asset function
class TD_Form_Cache : Object_Cache
{
    # Default constructor
    TD_Form_Cache ()
    {
        $this.DefaultAppID = 0
    }

    TD_Form_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDForm -AppID $AppID -Environment $Environment | Where-Object Name -eq $TargetName),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDForm -AppID $AppID -Environment $Environment | Where-Object ID -eq $TargetID),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDForm -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByComponent
    #  Get a target from the cache by component
    [TeamDynamix_Api_Forms_Form[]]GetByComponent(
        [string]            $ComponentName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object {$_.ComponentID -eq [int][TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentName}
        return $Target
    }
    [TeamDynamix_Api_Forms_Form[]]GetByComponent(
        [int]               $ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ComponentID -eq $ComponentID
        return $Target
    }
}

# Stores asset search data
class TD_AssetSearch_Cache : Object_Cache
{
    # Default constructor
    TD_AssetSearch_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_AssetSearch_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDAssetSearch -AppID $AppID -Environment $Environment | Where-Object Name -eq $TargetName),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDAssetSearch -AppID $AppID -Environment $Environment | Where-Object ID -eq $TargetID),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDAssetSearch -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByComponent
    #  Get a target from the cache by component
    [TeamDynamix_Api_SavedSearches_SavedSearch[]]GetByComponent(
        [string]            $ComponentName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object {$_.ComponentID -eq [int][TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentName}
        return $Target
    }
    [TeamDynamix_Api_SavedSearches_SavedSearch[]]GetByComponent(
        [int]               $ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ComponentID -eq $ComponentID
        return $Target
    }
    #  Delegating method for GetByComponent
    [TeamDynamix_Api_SavedSearches_SavedSearch[]]ComponentID(
        [string]$ComponentID
        )
    {
        return $this.GetByComponent($ComponentID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
}

# Stores configuration item type data
class TD_ConfigurationItemType_Cache : Object_Cache
{
    # Default constructor
    TD_ConfigurationItemType_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_ConfigurationItemType_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDConfigurationItemType -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDConfigurationItemType -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDConfigurationItemType -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores vendor data
class TD_Vendor_Cache : Object_Cache
{
    # Default constructor
    TD_Vendor_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_Vendor_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDVendor -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDVendor -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDVendor -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByAccountNumber
    #  Get a target from the cache by account number
    [TeamDynamix_Api_Assets_Vendor[]]GetByAccountNumber(
        [string]                  $AccountNumber,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object AccountNumber -eq $AccountNumber | Where-Object IsActive -eq $IsActive
        return $Target
    }
    #  Delegating method for GetByAccountNumber
    [TeamDynamix_Api_Assets_Vendor[]]GetByAccountNumber(
        [string]$AccountNumber
        )
    {
        return $this.GetByAccountNumber($AccountNumber,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
}

# Stores product type data
class TD_ProductType_Cache : Object_Cache
{
    # Default constructor
    TD_ProductType_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_ProductType_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDProductTypeInt -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDProductTypeInt -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDProductTypeInt -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByParent
    #  Get a target from the cache by parent
    [TeamDynamix_Api_Assets_ProductType[]]GetByParent(
        [string]                  $ParentName,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ParentName -eq $ParentName | Where-Object IsActive -eq $IsActive
        return $Target
    }
    [TeamDynamix_Api_Assets_ProductType[]]GetByParent(
        [int]                     $ParentID,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object ParentID -eq $ParentID | Where-Object IsActive -eq $IsActive
        return $Target
    }
    #  Delegating method for GetByParent
    [TeamDynamix_Api_Assets_ProductType[]]GetByParent(
        [string]$ParentName
        )
    {
        return $this.GetByParent($ParentName,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
    [TeamDynamix_Api_Assets_ProductType[]]GetByParent(
        [int]$ParentID
        )
    {
        return $this.GetByParent($ParentID,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
}

# Stores asset status data
class TD_AssetStatus_Cache : Object_Cache
{
    # Default constructor
    TD_AssetStatus_Cache ()
    {
        $this.DefaultAppID = $script:AssetCIAppID
    }

    TD_AssetStatus_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDAssetStatus -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDAssetStatus -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDAssetStatus -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores ticket status data
class TD_TicketStatus_Cache : Object_Cache
{
    # Default constructor
    TD_TicketStatus_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketStatus_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDTicketStatus -SearchText $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDTicketStatus -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketStatus -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByStatusClass
    #  Get a target from the cache by status class
    [TeamDynamix_Api_Tickets_TicketStatus[]]GetByStatusClass(
        [string]                  $StatusClass,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object StatusClass -eq $StatusClass | Where-Object IsActive -eq $IsActive
        return $Target
    }
    #  Delegating method for GetByStatusClass
    [TeamDynamix_Api_Tickets_TicketStatus[]]GetByStatusClass(
        [string]$StatusClass
        )
    {
        return $this.GetByStatusClass($StatusClass,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
}

# Stores product type data
class TD_TicketType_Cache : Object_Cache
{
    # Default constructor
    TD_TicketType_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketType_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketType -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByCategory
    #  Get a target from the cache by category
    [TeamDynamix_Api_Tickets_TicketType[]]GetByCategory(
        [string]                  $CategoryName,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object CategoryName -eq $CategoryName | Where-Object IsActive -eq $IsActive
        return $Target
    }
    [TeamDynamix_Api_Tickets_TicketType[]]GetByCategory(
        [int]                     $CategoryID,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object CategoryID -eq $CategoryID | Where-Object IsActive -eq $IsActive
        return $Target
    }
    #  Delegating method for GetByCategory
    [TeamDynamix_Api_Tickets_TicketType[]]GetByCategory(
        [string]$CategoryName
        )
    {
        return $this.GetByCategory($CategoryName,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
}

# Stores product type data
class TD_Service_Cache : Object_Cache
{
    # Default constructor
    TD_Service_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_Service_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDService -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDService -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }

    # Custom methods
    # GetByCategory
    #  Get a target from the cache by category
    [TeamDynamix_Api_ServiceCatalog_Service[]]GetByCategory(
        [string]                  $CategoryName,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object CategoryName -eq $CategoryName | Where-Object IsActive -eq $IsActive
        return $Target
    }
    [TeamDynamix_Api_ServiceCatalog_Service[]]GetByCategory(
        [int]                     $CategoryID,
        [int]                     $AppID,
        [EnvironmentChoices]      $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Find target
        $Target = $this.GetAll($AppID,$Environment) | Where-Object CategoryID -eq $CategoryID | Where-Object IsActive -eq $IsActive
        return $Target
    }
    #  Delegating method for GetByCategory
    [TeamDynamix_Api_ServiceCatalog_Service[]]GetByCategory(
        [string]$CategoryName
        )
    {
        return $this.GetByCategory($CategoryName,$this.DefaultAppID,$script:WorkingEnvironment,$null)
    }
}

# Stores ticket source data
class TD_TicketSource_Cache : Object_Cache
{
    # Default constructor
    TD_TicketSource_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketSource_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketSource -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores ticket priority data
class TD_TicketPriority_Cache : Object_Cache
{
    # Default constructor
    TD_TicketPriority_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketPriority_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketPriority -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores ticket urgency data
class TD_TicketUrgency_Cache : Object_Cache
{
    # Default constructor
    TD_TicketUrgency_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketUrgency_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketUrgency -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores ticket impact data
class TD_TicketImpact_Cache : Object_Cache
{
    # Default constructor
    TD_TicketImpact_Cache ()
    {
        $this.DefaultAppID = $script:TicketingAppID
    }

    TD_TicketImpact_Cache ([int]$AppID)
    {
        $this.DefaultAppID = $AppID
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    #  Add by target ID
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw "Invalid cache action"
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDTicketImpact -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
}

# Stores security role data
#  ID requires a GUID, which means that all parent methods using ID must be overridden
class TD_SecurityRole_Cache : Object_Cache
{
    # Default constructor
    TD_SecurityRole_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target name
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        # Look up by name
        $this.Add((Get-TDSecurityRole -NameLike $TargetName -Exact -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID
    hidden [void]Add(
        [guid]              $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add((Get-TDSecurityRole -ID $TargetID -AppID $AppID -Environment $Environment),$AppID,$Environment,$Detail,$true)
    }
    #  Add by target ID, default AppID
    hidden [void]Add(
        [guid]              $TargetID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $this.Add($TargetID,$this.DefaultAppID,$Environment,$Detail)
    }
    #  Add by target ID, default Environment
    hidden [void]Add(
        [guid]  $TargetID,
        [int]   $AppID,
        [switch]$Detail
        )
    {
        $this.Add($TargetID,$AppID,$script:WorkingEnvironment,$Detail)
    }
    #  Add by target ID, default AppID and Environment
    hidden [void]Add(
        [guid]$TargetID
        )
    {
        $this.Add($TargetID,$script:WorkingEnvironment,$true,$true)
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Only load existing targets if there's nothing in the cache - don't load detail data, skip cache checks
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.Add((Get-TDSecurityRole -AppID $AppID -Environment $Environment),$AppID,$Environment,$false,$false)
        }
    }
    # Remove
    #  Remove $TargetObject in cache by creating temporary copy, clearing existing list and adding everything back, except the one to delete
    hidden [void]Remove(
        [guid]              $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Copy targets to temporary array
        $TemporaryTargets = $this.$Environment."AppID$AppID".Clone()
        # Erase targets array
        $this.FlushCache($AppID,$Environment)
        # Add targets back from temporary array
        foreach ($Target in $TemporaryTargets)
        {
            # Exclude desired target
            if ($Target.ID -ne $TargetID)
            {
                $this.Add($Target,$AppID,$Environment,$false,$false)
            }
        }
    }
    #  Delegating methods for remove
    hidden [void]Remove(
        [guid]$TargetID
        )
    {
        $this.Remove($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    # GetCached
    #  Get a target from the cache, by ID
    hidden [system.object]GetCached(
        [guid]              $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object ID -eq $TargetID
    }
    # Delegating methods for GetCached
    #  Get a target from the cache, by ID
    hidden [system.object]GetCached(
        [guid]$TargetID
        )
    {
        return $this.GetCached($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
    # Get
    #  Get a target from the cache, if present, if not retrieve and add to cache - by ID
    [system.object]Get(
        [guid]              $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetID,$AppID,$Environment)
        return $Target
    }
    #  Delegating methods for Get
    [system.object]Get(
        [guid]              $TargetID,
        [EnvironmentChoices]$Environment
        )
    {
        return $this.Get($TargetID,$this.DefaultAppID,$Environment)
    }
    [system.object]Get(
        [guid]$TargetID,
        [int] $AppID
        )
    {
        return $this.Get($TargetID,$AppID,$script:WorkingEnvironment)
    }
    [system.object]Get(
        [guid]$TargetID
        )
    {
        return $this.Get($TargetID,$this.DefaultAppID,$script:WorkingEnvironment)
    }
}
# Stores custom attribute data
class TD_CustomAttribute_Cache : Object_Cache
{
    # Default constructor
    TD_CustomAttribute_Cache ()
    {
        # Nothing should ever end up with a default app ID
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Add by target object - all add commands pass through here
    #   Use ComponentID in GetCached call
    hidden [void]Add(
        [System.Object]     $TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        # Add
        #  Add new items, or replace existing items if detail information isn't present
        $CachedTargetObject = $null
        if ($CheckCache)
        {
            # This check is skipped when bulk-loading data, since the cache is empty when that happens
            $CachedTargetObject = $this.GetCached($TargetObject.Name,$TargetObject.ComponentID,$AppID,$Environment)
        }
        if (-not $CachedTargetObject)
        {
            # Create the array holder for the data, if none exists
            if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
            {
                $this.$Environment += @{"AppID$AppID" = @()}
            }
            $this.$Environment."AppID$AppID" += $TargetObject
        }
        $this.WorkingEnvironment = $this.$script:WorkingEnvironment
    }
    #  Invalid Add delegates - ComponentID required for this cache object
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw 'Invalid cache action.'
    }
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw 'Invalid cache action.'
    }
    # GetCached
    #  Get a target from the cache, by name
    #   Add ComponentID
    hidden [system.object]GetCached(
        [string]            $TargetName,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($ComponentID,$AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object Name -eq $TargetName
    }
    #  Get a target from the cache, by ID
    hidden [system.object]GetCached(
        [int]               $TargetID,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($ComponentID,$AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object ID -eq $TargetID
    }
    #  Invalid GetCached delegates - ComponentID required for this cache object
    hidden [system.object]GetCached(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw 'Invalid cache action.'
    }
    hidden [system.object]GetCached(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw 'Invalid cache action.'
    }
    # Get
    #  Get a target from the cache, if present; if not retrieve and add to cache - by name
    #   Add ComponentID
    [system.object]Get(
        [string]            $TargetName,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetName,$ComponentID,$AppID,$Environment)
        return $Target
    }
    #  Get a target from the cache, if present, if not retrieve and add to cache - by ID
    #   Add ComponentID
    [system.object]Get(
        [int]               $TargetID,
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetID,$ComponentID,$AppID,$Environment)
        return $Target
    }
    # GetAll
    #  Get all targets from the cache for an environment, if present; if not retrieve and add to cache
    #   Add ComponentID
    [system.object[]]GetAll(
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]                     $AppID,
        [string]                  $Environment,
        [system.nullable[boolean]]$IsActive
        )
    {
        # Retrieve data for cache
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($ComponentID,$AppID,$Environment)
        }
        # Start with all entries, filter if necessary
        $Return = $this.$Environment."AppID$AppID"
        # Check for entry IsActive status and filter if requested
        if (-not $null -eq $IsActive)
        {
            # Objects can have property of "Active" or "IsActive" - determine which is present
            #  If object has no matching property, no filter is applied
            if ($Return | Get-Member -Name IsActive)
            {
                $Return = $Return | Where-Object {($_.IsActive -eq $IsActive) -and ($_.ComponentID -eq $ComponentID)}
            }
            elseif ($Return | Get-Member -Name Active)
            {
                $Return = $Return | Where-Object {($_.Active -eq $IsActive) -and ($_.ComponentID -eq $ComponentID)}
            }
        }
        else
        {
            $Return = $this.$Environment."AppID$AppID" | Where-Object ComponentID -eq $ComponentID
        }
        return $Return
    }
    #  Delegating methods for GetAll
    #   Add ComponentID
    #   Must specify TeamDynamix_Api_CustomAttributes_CustomAttributeComponent to ensure proper type coercion
    [system.object[]]GetAll(
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        return $this.GetAll($ComponentID,$AppID,$Environment,$null)
    }
    [system.object[]]GetAll(
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]$AppID
        )
    {
        return $this.GetAll($ComponentID,$AppID,$script:WorkingEnvironment,$null)
    }
    #  Invalid GetAll delegates
    [system.object[]]GetAll(
        [string]                  $Environment, # Use string here to differentiate between a string and an int, (enums are both)
        [system.nullable[boolean]]$IsActive
        )
    {
        throw 'Invalid cache action.'
    }
    [system.object[]]GetAll(
        [System.Nullable[boolean]]$IsActive
        )
    {
        throw 'Invalid cache action.'
    }
    [system.object[]]GetAll()
    {
        throw 'Invalid cache action.'
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    #   Add component ID
    [void]LoadTargets(
        [TeamDynamix_Api_CustomAttributes_CustomAttributeComponent]$ComponentID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Don't load detail data, skip cache checks
        # Check to see if container exists
        # Allow loading of additional data, even if the environment/AppID exist, since multiple components may apply to a single app
        # Create the array holder for the data, if none exists
        if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
        {
            $this.$Environment += @{"AppID$AppID" = @()}
        }
        # Load requested data
        $CustomAttributes = Get-TDCustomAttribute -ComponentID $ComponentID -AppID $AppID -Environment $Environment
        $CustomAttributes | Add-Member -MemberType NoteProperty -Name ComponentID -Value $ComponentID
        $this.Add(($CustomAttributes),$AppID,$Environment,$false,$false)
    }
    #  Invalid GetCached delegates - ComponentID required for this cache object
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw 'Invalid cache action.'
    }
}
# Stores choice data for custom attribute choices
class TD_CustomAttributeChoice_Cache : Object_Cache
{
    # Default constructor
    TD_Application_Cache ()
    {
        $this.DefaultAppID = 0
    }

    # Override methods
    #  Search cache by ID - Names are not unique for custom attribute choices
    hidden [void]Add(
        [System.Object]     $TargetObject,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail,
        [switch]            $CheckCache
        )
    {
        # Add
        #  Add new items, or replace existing items if detail information isn't present
        $CachedTargetObject = $null
        if ($CheckCache)
        {
            # This check is skipped when bulk-loading data, since the cache is empty when that happens
            $CachedTargetObject = $this.GetCached($TargetObject.ID,$AppID,$Environment)
        }
        if (-not $CachedTargetObject)
        {
            # Create the array holder for the data, if none exists
            if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
            {
                $this.$Environment += @{"AppID$AppID" = @()}
            }
            $this.$Environment."AppID$AppID" += $TargetObject
        }
        $this.WorkingEnvironment = $this.$script:WorkingEnvironment
    }
    #  Add by target ID - target IDs are unique for custom attribute choices
    hidden [void]Add(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        $Choices = $null
        # Look up by ID
        try
        {
            $Choices = Get-TDCustomAttributeChoice -ID $TargetID -Environment $Environment
        }
        catch {}
        if ($Choices)
        {
            $ChoiceObject = [pscustomobject]@{
                ID      = $TargetID
                Choices = $Choices
            }
            $this.Add($ChoiceObject,$AppID,$Environment,$Detail,$true)
        }
        else
        {
            return
        }
    }
    #  Invalid Add delegates - target names are not unique for custom attribute choices
    hidden [void]Add(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment,
        [switch]            $Detail
        )
    {
        throw 'Invalid cache action.'
    }
    # GetCached
    #  Get a target from the cache, by ID
    #   Add TargetID to LoadTargets call
    hidden [system.object]GetCached(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # If there's nothing in the cache, load basic target data
        if (-not $this.$Environment."AppID$AppID")
        {
            $this.LoadTargets($TargetID,$AppID,$Environment)
        }
        return $this.$Environment."AppID$AppID" | Where-Object ID -eq $TargetID
    }
    #  Invalid GetCached delegates - target names are not unique for custom attribute choices
    hidden [system.object]GetCached(
        [string]            $TargetName,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw 'Invalid cache action.'
    }
    # Get
    #  Return only choices, as the Get-TDCustomAttributeChoice would do
    #  Must specify AppID of 0
    [system.object]Get(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        $Target = $this.GetCached($TargetID,$AppID,$Environment)
        return $Target.Choices
    }
    # LoadTargets
    #  Load existing targets into cache, no detail data
    #   Add component ID
    [void]LoadTargets(
        [int]               $TargetID,
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        # Don't load detail data, skip cache checks
        # Check to see if container exists
        # Allow loading of additional data, even if the environment/AppID exist, since multiple components may apply to a single app
        if (-not ($this.$Environment.Keys -contains "AppID$AppID"))
        {
            $this.$Environment += @{"AppID$AppID" = @()}
        }
        # Load requested data
        $Choices = $null
        try
        {
            $Choices = Get-TDCustomAttributeChoice -ID $TargetID -Environment $Environment
        }
        catch {}
        if ($Choices)
        {
            $ChoiceObject = [pscustomobject]@{
                ID      = $TargetID
                Choices = $Choices
            }
            $this.Add($ChoiceObject,$AppID,$Environment,$false,$false)
        }
        else
        {
            return
        }
    }
    #  Invalid GetCached delegates - Name or ID required for this cache object
    [void]LoadTargets(
        [int]               $AppID,
        [EnvironmentChoices]$Environment
        )
    {
        throw 'Invalid cache action.'
    }
    [void]LoadTargets()
    {
        throw 'Invalid cache action.'
    }
}
#endregion
#endregion

# Source all .ps1 scripts contained in the module
(Test-ModuleManifest $PSScriptRoot\TeamDynamix.psd1).FileList | Where-Object {$_ -like '*.ps1'} | ForEach-Object {. $_}

#region Module authentication

# Check to see if a non-credentialed start has been requested
if (-not $NoLogin)
{
    Write-Progress -ID 100 -Activity 'Loading module' -Status 'Authenticating' -PercentComplete 66
    # Check to see if a credential is supplied via -ArgumentList
    if (-not $Credential)
    {
        # Prompt user for authentication information
        $GUILogin = Set-TDAuthentication -GUI -Passthru -NoInvalidateCache
        switch ($GUILogin.Site)
        {
            Production {$WorkingEnvironment = 'Production'}
            Sandbox    {$WorkingEnvironment = 'Sandbox'   }
            Preview    {$WorkingEnvironment = 'Preview'   }
        }
        if ($GUILogin.Authenticated -eq $false)
        {
            $NoLogin = $true
        }
    }
    else
    {
        # Authenticate from a file or via PSCredential
        switch ($Credential.GetType().Name)
        {
            'string'
            {
                Set-TDAuthentication -CredentialPath $Credential -Environment $WorkingEnvironment -NoInvalidateCache
            }
            'PSCredential'
            {
                Set-TDAuthentication -Credential     $Credential -Environment $WorkingEnvironment -NoInvalidateCache
            }
            default
            {
                throw 'Unable to authenticate. No authentication methods provided. Use NoLogin parameter to start an unauthenticated session.'
            }
        }
    }
}
if ($NoLogin)
{
    Write-Warning 'Unauthenticated session requested. Most functions will not work correctly.'
}
#endregion

#region Variable definitions dependent on classes or authentication
# Any script-wide or global variables that depend on class definitions or TD authentication must come after this point.

# Skip variable definitions if -NoLogin has been requested
if (-not $NoLogin)
{
    Write-Progress -ID 100 -Activity 'Loading module' -Status 'Loading caches' -PercentComplete 90

    # Load caches - order dependent
    try
    {
        $script:TDApplications           = [TD_Application_Cache]::new()
        $script:TicketingAppID           = ($TDApplications.Get($TDConfig.DefaultTicketingApp)).AppID
        $script:AssetCIAppID             = ($TDApplications.Get($TDConfig.DefaultAssetCIsApp )).AppID
        $script:ClientPortalID           = ($TDApplications.Get($TDConfig.DefaultPortalApp   )).AppID
        $script:TDAssetStatuses          = [TD_AssetStatus_Cache]::new($AssetCIAppID)
        $script:TDTicketPriorities       = [TD_TicketPriority_Cache]::new($TicketingAppID)
        $script:TDTicketUrgencies        = [TD_TicketUrgency_Cache ]::new($TicketingAppID)
        $script:TDTicketStatuses         = [TD_TicketStatus_Cache  ]::new($TicketingAppID)
        $script:TDTicketSources          = [TD_TicketSource_Cache  ]::new($TicketingAppID)
        $script:TDTicketImpacts          = [TD_TicketImpact_Cache  ]::new($TicketingAppID)
        $script:TDTicketTypes            = [TD_TicketType_Cache    ]::new($TicketingAppID)
        $script:TDTicketStatusClasses    = Get-TDTicketStatusClass -AuthenticationToken $TDAuthentication -Environment $WorkingEnvironment | Sort-Object Name
        $script:TDTimeZones              = Get-TDTimeZoneInformation -SortByGMTOffset
        $script:TDVendors                = [TD_Vendor_Cache]::new($AssetCIAppID)
        $script:TDProductTypes           = [TD_ProductType_Cache ]::new($AssetCIAppID)
        $script:TDProductModels          = [TD_ProductModel_Cache]::new($AssetCIAppID)
        $script:TDAccounts               = [TD_Account_Cache]::new()
        $script:TDGroups                 = [TD_Group_Cache]::new()
        $script:TDForms                  = [TD_Form_Cache ]::new()
        $script:TDAssetSearches          = [TD_AssetSearch_Cache]::new()
        $script:TDConfigurationItemTypes = [TD_ConfigurationItemType_Cache]::new()
        $script:TDSecurityRoles          = [TD_SecurityRole_Cache]::new()
        $script:TDBuildingsRooms         = [TD_Location_Cache]::new()
        $script:TDServices               = [TD_Service_Cache]::new()
        $script:TDCustomAttributes       = [TD_CustomAttribute_Cache]::new()
        $script:TDCustomAttributeChoices = [TD_CustomAttributeChoice_Cache]::new()
    }
    catch
    {
        throw 'Unable to lookup TeamDynamix applications from server'
    }
}
#endregion

Write-Progress -ID 100 -Completed -Activity 'Finishing'
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBYUnFh01PvG9zoN98C3p06W9
# GhOgggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHbs
# 2srrJX3FbFba6y86oZ45q2T4MA0GCSqGSIb3DQEBAQUABIICAEkW1igJTdVXXaYd
# U0Va9wR8VUb/OlaouNBAqAtKsQftKSBCvKI2UgFKg40NHaW93wzv8woLMVQjBoJA
# 0NZHiAm2Etm9Pgh2vRZgkQUDtDy4XZTDUMWN+xqCBWzLVxJZ4rXQkYRSABEqqH0h
# PFcvaFOcUK6Rc9J0AQ59gXiQVLsD/WwRh5aNJxIsd4V4uinlfWlRpLShOvWccdys
# bHChQ5fFCGyxuiu/XBXA53ySaEyskVQ6MZ7fYres5Kt3ysqp1KA4eLhpItKbAQhd
# bbZfpWCad8GpGt3tcssK+Z1QwuIUkZhMu9vMi1QizDZQ689jpRyIukqdb89pTDfi
# Crkb/76NRz8jDjrpYwDXrVRFB2BWZeMq+Cf7MqmL+vrR+vlNhf8RVw+di7K6cNo8
# lW2Bcv4OTe7usQbQjuQ1sA/Y086gq/5H/ecT9QtrM0vK1B3YHr7ktEdxX9WEpiPN
# IQMDTY2MEpdIOVkFe6cm+YIUf1D29IcuxHdw1erkI8JDl3QvkRegiwKh0TGVkvUZ
# 9rZmw+YdXLa4YnhsglPuSdjKv8YXQu7TzwvV1vI8B5GdhXonfi//j8ldM7PdauY2
# 4pWqr1qhwegiwYdESbfVZRE59qq/OgRsbN9VrSK5Ugb1d+O0hKA7Bx/W9opZ99o2
# P+R3Oxya6RegLABuuGxNfPpIVjFu
# SIG # End signature block
