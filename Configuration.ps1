function Update-ConfigurationFile {
    $Return = $false
    # Set current version of the configuration file, increment to module version when config file changes
    $ConfigurationVersion = '2.5.3'
    # If a config file exists, read it - if not, create a new one with default values
    if (Test-Path -Path $PSScriptRoot\Configuration.psd1 -PathType Leaf) {
        $CurrentSettings = Import-PowerShellDataFile $PSScriptRoot\Configuration.psd1
    }
    else {
        $CurrentSettings = $null
    }
    # Default settings to move from the current config file into the new config file
    $DefaultSettings = @(
        'LogFileDirDefault'
        'DefaultEmailDomain'
        'UsernameRegex'
        'DefaultAssetCIsApp'
        'DefaultTicketingApp'
        'DefaultPortalApp'
        'DefaultTDBaseURI'
        'DefaultTDPreviewBaseURI'
        'DefaultAuthenticationProviderID'
        'DefaultADConnector'
        'DirectoryLookup'
        'AlternateEmailDomain'
        'MaxActivityHistoryDefault'
    )
    $DefaultConfiguration = @'
@{
    ConfigurationVersion = 'XXXConfigurationVersionXXX'
    #region Global settings
        #region Required settings
            # Log file directory (used for user and asset updates)
            LogFileDirDefault = 'C:\Temp\TD'

            # Email address domain (the part after the @), used to set usernames and primary email address
            DefaultEmailDomain = 'osu.edu'

            # User recognition regex pattern
            #  Using a regular expression, describe what a valid username looks like (the part before the @ in an email address)
            #  If you wish to not use a recognition pattern (or don't know regular expressions), use ".*"
            UsernameRegex = '.*\.\d+'

            # Default TeamDynamix applications
            DefaultAssetCIsApp  = 'Assets/CIs'
            DefaultTicketingApp = 'Tickets'
            DefaultPortalApp    = 'Client Portal'

            # TeamDynamix URIs, used for API and portal
            DefaultTDBaseURI        = 'https://osuasc.teamdynamix.com'
            DefaultTDPreviewBaseURI = 'https://osuasc.teamdynamixpreview.com'

            # Default TeamDynamix authentication provider ID
            DefaultAuthenticationProviderID = 373
        #endregion

        #region Optional settings
            # Active Directory configuration info
            #  Must be a user connector
            #  Must have a DefaultADDomainName and DefaultADSearchBase for finding departments
            #  Must be marked as active
            DefaultADConnector = 'Active Directory People'

            # User directory information command
            #  Command should be written so it is possible to add the name to lookup to the end
            DirectoryLookup = 'Get-OSUDirectoryListing -Properties * -Name'

            # Alternate email address domain (the part after the @), used to set alternate email address
            AlternateEmailDomain = 'buckeyemail.osu.edu'

            # Activity reporting queue depth, select any value 1 or higher
            #  This is the number of recent activities to be reported when there is an error
            #  Used for debugging
            #  Recommended default: 1
            MaxActivityHistoryDefault = 1

            # Define security roles for users
            # Role names must be unique
            # Security roles must match a TD security role, same for FunctionalRole and TD functional role, this does not create the roles
            # Function is code used to determine if someone belongs in one of the roles (do not include by default)
            #  User is granted the first role matched by function (evaluates to something other than $false), so list roles in order of most specific to least specific
            #  $User is used to identify the current user being reviewed
            #  Role flagged as Default = $true is the one given when no roles match by function
            # If a role has no function and is not the default, it will not be assigned automatically under any circumstances
            # Application admin specifies if the role users will have the ability to access the Admin area of that app via the application itself - click gear in the top-right corner
            UserRoles = @(
                @{
                    Name = 'Technician - Student'
                    Default = $false
                    UserSecurityRole   = 'Technician - Student'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'MyWork'
                        'TDAssets'
                        'TDChat'
                        'TDCommunity'
                        'TDNext'
                        'TDPeople'
                        'TDTickets'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Technician + Knowledge Base, Questions, Services, Ticket Requests'
                        }
                        @{
                            Name         = 'Tickets'
                            SecurityRole = 'Ticketing - Tech Access'
                        }
                        @{
                            Name         = 'Assets/CIs'
                            SecurityRole = 'Technician'
                        }
                    )
                    Function = @"
                        if (`$Connector.Subclass -eq `'ActiveDirectory`')
                        {
                            `$User.DistinguishedName -match `"OU=Students,OU=_ASC Technology,OU=_ASC College of Arts and Sciences,OU=The Ohio State University,DC=asc,DC=ohio-state,DC=edu`"
                        }
                        # elseif (other connector/condition) {other result}
"@

                }
                @{
                    Name = 'Technician'
                    Default = $false
                    UserSecurityRole   = 'Technician'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'MyWork'
                        'TDAssets'
                        'TDChat'
                        'TDCommunity'
                        'TDNext'
                        'TDPeople'
                        'TDTickets'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Technician + Knowledge Base, Questions, Services, Ticket Requests'
                        }
                        @{
                            Name         = 'Tickets'
                            SecurityRole = 'Ticketing - Tech Access'
                        }
                        @{
                            Name         = 'Assets/CIs'
                            SecurityRole = 'Technician'
                        }
                    )
                    Function = @"
                    if (`$Connector.Subclass -eq `'ActiveDirectory`')
                    {
                        # Look up user default account
                        `$AccountID = Invoke-Expression `$Connector.data.FieldMappings.AttributesMap.DefaultAccountID
                        if (`$AccountID)
                        {
                            `$TDAccounts.Get(`$AccountID).Name -eq `'ASC Technology`'
                        }
                        else
                        {
                            `$false
                        }
                    }
                    # elseif (other connector/condition) {other result}
"@
                }
                @{
                    Name = 'Customer'
                    Default = $true
                    UserSecurityRole   = 'Customer'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'TDClient'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Customer + Knowledge Base, Services, Ticket Requests'
                        }
                    )
                    Function = '$true'
                }
                @{
                    Name = 'Enterprise Admin'
                    Default = $false
                    UserSecurityRole   = 'Enterprise - Full Access'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'MyWork'
                        'TDAssets'
                        'TDChat'
                        'TDCommunity'
                        'TDNext'
                        'TDPeople'
                        'TDTickets'
                        'TDAnalysis'
                        'TDFileCabinet'
                        'TDPortfolios'
                        'TDProjects'
                        'TDTimeExpense'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Enterprise - Full Access + Knowledge Base, Project Requests, Projects, Questions, Services, Ticket Requests'
                            AppAdmin     = $true
                        }
                        @{
                            Name         = 'Tickets'
                            SecurityRole = 'Ticketing - All Access'
                            AppAdmin     = $true
                        }
                        @{
                            Name         = 'Assets/CIs'
                            SecurityRole = 'Enterprise - Full Access'
                            AppAdmin     = $true
                        }
                    )
                    Function = '$false'
                }
                @{
                    Name = 'Service'
                    Default = $false
                    UserSecurityRole   = 'Service'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'TDAssets'
                        'TDNext'
                        'TDPeople'
                        'TDTickets'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Customer'
                        }
                        @{
                            Name         = 'Assets/CIs'
                            SecurityRole = 'Service Read-Only'
                        }
                    )
                    Function = '$false'
                }
                @{
                    Name = 'Project Manager'
                    Default = $false
                    UserSecurityRole   = 'Project Manager'
                    UserFunctionalRole = 'Participant'
                    Applications = @(
                        'MyWork'
                        'TDAnalysis'
                        'TDFileCabinet'
                        'TDNext'
                        'TDPortfolios'
                        'TDProjects'
                        'TDTicketRequests'
                        'TDTimeExpense'
                    )
                    OrgApplications = @(
                        @{
                            Name         = 'Client Portal'
                            SecurityRole = 'Customer + Knowledge Base, Projects, Services, Ticket Requests'
                        }
                    )
                    Function = '$false'
                }
            )
        #endregion
    #endregion

    #region Application configurations (one for each application, add as necessary)
        # Asset applications"
        AssetApplications = @(
            @{
                # Required
                #  Name of application, used to refer to its settings
                Name = 'Assets/CIs'
                # Optional
                DefaultSecurityRole = 'Technician'
                #  All asset report (omits invalid assets), used to enumerate assets for consistency reports
                #  For OSU ASC, omits assets with status "Duplicate Asset"
                AllAssetReportID = 163286
                IgnoredStatuses = @('Duplicate Asset')
            }
        )

        # Ticket applications"
        TicketingApplications = @(
            @{
                # Required
                #  Name of application, used to refer to its settings
                Name = 'Tickets'
                # Optional
                DefaultSecurityRole = 'Ticketing - Tech Access'
            }
        )

        # Portal applications"
        PortalApplications = @(
            @{
                # Required
                #  Name of application, used to refer to its settings
                Name = 'Client Portal'
                # Optional
                DefaultSecurityRole = 'Technician + Knowledge Base, Questions, Services, Ticket Requests'
                #  Default desktop UID
                DefaultDesktop = '88389253-090a-4bfb-a5b7-ec8f9e27d555'
            }
        )
    #endregion

    #region Connectors (add as necessary) and data mapping
        # Common variables for connectors
        DefaultAssetStatus = 'In Use'
        BadSerialNumbers = @(
            $null
            ''
            'None'
            'Not Specified'
            'N/A'
            'NA'
            'System Serial Number'
            'To be filled by O.E.M.'
            'ps'
            'Default string'
            'Chassis Serial Number'
            '1234567890'
            '1234567890.'
            '0123456789'
            '0'
            'Not Available'
            'No Serial'
            'APPLIANCE (CANNOT ACCESS)'
            'VIRTUAL MACHINE (CANNOT ACCESS)'
            '............'
        )
        BadProductNames = @(
            'System Product Name'
            'All Series'
            'OEM'
            'To Be Filled By O.E.M.'
        )

        # Connector specifications
        #  Connector names must be unique
        #  No spaces or special characters allowed in the name of the connector (it's used as part of a parameter to retrieve credentials in Update-TDAllAssets)
        # Application is the name of the TeamDynamix application that the connector applies to
        # Type indicates whether the connector is used to specify the primary list of assets/users/?? (Primary) or if it is used to provide supplemental data for individual assets/users/?? (Supplemental)
        #  All primary connectors for an application are executed in the order they appear, to collect the list of users and populate data from the field mappings
        #  All supplemental connectors are executed in the order they appear, to add/replace data on users from the primary connector list
        # Class is the general group for the connector, used to aggregate processing in Update-TDAsset.
        #  Assets in the same class are
        # Deactivate a connector by setting IsActive to $false
        # Function is the name of the function to call (with complete parameters) to retrieve data from the connector
        # AuthRequired gives the name of the authentication required, which will be prompted for
        #  Use $null for systems that do not require authentication
        # Data contains all settings needed for the connector
        #  Field mappings use:
        #   $Asset to refer to the current asset from the connector
        #   $User to refer to the current user from the connector
        #   $Username to refer to the current username
        #   $Connector to refer to the current connector
        #   $ConnectorCredential to refer to the credential for the current connector
        #  Field mapping logic and code will be executed as written, expecting a string output
        #   Use Here-String for multi-line code blocks in field mapping logic
        DataConnectors = @(
            #region Asset connectors
            @{
                # Configuration Manager connector requires that the Config Manager PowerShell cmdlets are installed on the machine running the query
                Name         = 'ASCConfigurationManager'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'MECM'
                IsActive     = $true
                Function     = 'Get-ConfigManagerData -Connector $Connector'
                AuthRequired = $null
                Supplemental = $null
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    BadProductNames    = @"
                        @(
                            `$(`$TDConfig.BadProductNames)
                        )
"@
                    # Data source info
                    DataSource = @{
                        # Is the MECM server local or accessed remotely
                        Local = $true
                        # For remote servers, name of the server and the Config Manager root are required
                        RemoteServer = $null
                        MECMRootName = $null
                        # Query names for retrieving asset info
                        ConfigManagerQueryNames = @(
                            'BK Inventory'
                            'BK Inventory - BitLocker Info'
                            'BK Inventory - Disk Info'
                        )
                    }
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.SerialNumber.SerialNumber)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.SMS_R_System.Name) {$Asset.SMS_R_System.Name.Trim()}'
                            'ProductName'    = '$Asset.SMS_G_System_COMPUTER_SYSTEM.Model.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"ASC Configuration Manager"'
                            'OS Version'                = '"$($Asset.SMS_R_System.OperatingSystemNameandVersion), Build $($Asset.SMS_R_System.Build)"'
                            'IP Address'                = 'if ($Asset.SMS_R_System.IPAddresses ) {$Asset.SMS_R_System.IPAddresses[0] }'
                            'MAC Address 1'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[0]}'
                            'MAC Address 2'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[1]}'
                            'Recent User Name'          = '$Asset.SMS_R_System.LastLogonUserName'
                            'Organizational Unit'       = '$Matches = $null; if ($_.SMS_R_System.SystemOUName -and $Asset.SMS_R_System.SystemOUName[-1] -match "ASC.OHIO-STATE.EDU\/(THE OHIO STATE UNIVERSITY\/_ASC COLLEGE OF ARTS AND SCIENCES\/)?(.*)") {$Matches[2]}'
                            'Last Check-In'             = '$Asset.SMS_G_System_WORKSTATION_STATUS.LastHardwareScan'
                            'Encryption Status'         = '($Asset.Encryption | ForEach-Object {"$($_.Driveletter) $($_.ProtectionStatus)"}) -join ", "'
                            'CPU'                       = '$Asset.SMS_G_System_PROCESSOR.Name'
                            'Physical Memory (GB)'      = '($Asset.SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory / 1024 / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = 'if ($Asset.DiskInfo | Where-Object DriveLetter -eq "C:") {(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").DiskSize[0]  / 1000).ToString("#,##0.00")}'
                            'Boot Disk Free Space (GB)' = 'if ($Asset.DiskInfo | Where-Object DriveLetter -eq "C:") {(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").FreeSpace[0] / 1000).ToString("#,##0.00")}'
                            'Backup Console ID'         = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.code42_guid'
                            'Nessus Console ID'         = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.nessus_uuid'
                            'AV Console ID'             = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.sep_clientid'
                        }
                    }
                }
            }
            @{
                # Configuration Manager connector requires that the Config Manager PowerShell cmdlets are installed on the machine running the query
                Name         = 'OCIOConfigurationManager'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'MECM'
                IsActive     = $true
                Function     = 'Get-ConfigManagerData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'OCIOCM'
                Supplemental = $null
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    BadProductNames    = @"
                        @(
                            `$(`$TDConfig.BadProductNames)
                        )
"@
                    # Data source info
                    DataSource = @{
                        # Is the MECM server local or accessed remotely
                        Local = $true
                        # For remote servers, name of the server and the Config Manager root are required
                        RemoteServer = 'asc-infjmpwin01.bcd.it.osu.edu'
                        MECMRootName = 'cio-ecmappd01.bcd.it.osu.edu'
                        # Query names for retrieving asset info
                        ConfigManagerQueryNames = @(
                            'ASC TeamDynamix Inventory'
                            'ASC TeamDynamix Inventory - BitLocker Info'
                            'ASC TeamDynamix Inventory - Disk Info'
                        )
                    }
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.SMS_G_System_PC_BIOS.SerialNumber)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.SMS_R_System.Name) {$Asset.SMS_R_System.Name.Trim()}'
                            'ProductName'    = '$Asset.SMS_G_System_COMPUTER_SYSTEM.Model.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"OCIO Configuration Manager"'
                            'OS Version'                = '"$($Asset.SMS_R_System.OperatingSystemNameandVersion), Build $($Asset.SMS_R_System.Build)"'
                            'IP Address'                = 'if ($Asset.SMS_R_System.IPAddresses ) {$Asset.SMS_R_System.IPAddresses[0] }'
                            'MAC Address 1'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[0]}'
                            'MAC Address 2'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[1]}'
                            'Recent User Name'          = '$Asset.SMS_R_System.LastLogonUserName'
                            'Organizational Unit'       = '$Matches = $null; if ($_.SMS_R_System.SystemOUName -and $Asset.SMS_R_System.SystemOUName[-1] -match "ASC.OHIO-STATE.EDU\/(THE OHIO STATE UNIVERSITY\/_ASC COLLEGE OF ARTS AND SCIENCES\/)?(.*)") {$Matches[2]}'
                            'Last Check-In'             = '$Asset.SMS_G_System_WORKSTATION_STATUS.LastHardwareScan'
                            'Encryption Status'         = '($Asset.Encryption | ForEach-Object {"$($_.Driveletter) $($_.ProtectionStatus)"}) -join ", "'
                            'CPU'                       = '$Asset.SMS_G_System_PROCESSOR.Name'
                            'Physical Memory (GB)'      = '($Asset.SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory / 1024 / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = 'if ($Asset.DiskInfo | Where-Object DriveLetter -eq "C:") {(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").DiskSize[0]  / 1000).ToString("#,##0.00")}'
                            'Boot Disk Free Space (GB)' = 'if ($Asset.DiskInfo | Where-Object DriveLetter -eq "C:") {(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").FreeSpace[0] / 1000).ToString("#,##0.00")}'
                            'Nessus Console ID'         = '$Asset.SMS_G_System_Tenable64.TAG'
                            'Nessus Console Check-In'   = '$Asset.SMS_G_System_Tenable64.TimeStamp'
                            'AV Console Check-In'       = '$Asset.SMS_G_System_Crowdstrike_64.TimeStamp'
                        }
                    }
                }
            }
            @{
                Name         = 'OCIOJamf'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'JamfDesktop'
                IsActive     = $true
                Function     = 'Get-JamfData -Connector $Connector'
                AuthRequired = 'OCIOJamf'
                Supplemental = @(
                    @{
                        Name = 'Active Directory'
                        Parameters = $null
                    }
                )
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    APIEndpoint        = 'JSSResource/advancedcomputersearches/id/63'
                    ConsoleURL         = 'https://jamf.service.osu.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.Serial_Number)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.Computer_Name) {$Asset.Computer_Name.Trim()}'
                            'ProductName'    = '$Asset.Model.Trim()'
                            'ProductPart'    = '$Asset.Model_Identifier.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"OCIO Jamf"'
                            'OS Version'                = '"$($Asset.Operating_System), Build $($Asset.Operating_System_Build)"'
                            'IP Address'                = '$Asset.IP_Address'
                            'MAC Address 1'             = '$Asset.MAC_Address'
                            'Recent User Name'          = 'if ($Asset.Last_User_Login) {$Asset.Last_User_Login} else {$Asset.Username}'
                            'Last Check-In'             = '$Asset.Last_Check_in'
                            'Encryption Status'         = '$Asset.FileVault_2_Status'
                            'CPU'                       = '"$($Asset.Processor_Type), $($Asset.Processor_Speed_MHz / 1000)GHz, $($Asset.Total_Number_of_Cores) cores"'
                            'Physical Memory (GB)'      = '($Asset.Total_RAM_MB / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = '($Asset.Drive_Capacity_MB / 1000).ToString("#,##0.00")'
                            'Boot Disk Free Space (GB)' = '($Asset.Boot_Drive_Available_MB / 1000).ToString("#,##0.00")'
                            'Backup Console ID'         = 'if ($Asset.Code42_GUID -ne "Identity file(s) not found.") {if ($Asset.Code42_GUID) {$Asset.Code42_GUID} else {$Asset.Code42_Status}}'
                            'Nessus Console ID'         = '$Asset.Nessus_UUID'
                            'AV Console ID'             = '$Asset.SEP_ClientId'
                        }
                    }
                }
            }
            @{
                Name         = 'OCIOJamfMobile'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'JamfMobile'
                IsActive     = $true
                Function     = 'Get-JamfData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'OCIOJamf'
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    APIEndpoint        = 'JSSResource/advancedmobiledevicesearches/id/64'
                    ConsoleURL         = 'https://jamf.service.osu.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.Serial_Number)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.name) {$Asset.name.Trim()}'
                            'ProductName'    = '$Asset.Model.Trim()'
                            'ProductPart'    = '$Asset.Model_Identifier.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"OCIO Jamf"'
                            'OS Version'                = '$Asset.iOS_Version'
                            'IP Address'                = '$Asset.IP_Address'
                            'MAC Address 1'             = '$Asset.Wi_Fi_MAC_Address'
                            'Recent User Name'          = '$Asset.Username'
                            'Last Check-In'             = '$Asset.Last_Inventory_Update'
                            'Encryption Status'         = '$Asset.Data_Protection'
                        }
                    }
                }
            }
            @{
                Name         = 'ASCJamf'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'JamfDesktop'
                IsActive     = $false
                Function     = 'Get-JamfData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'ASC'
                Supplemental = @(
                    @{
                        Name = 'Active Directory'
                        Parameters = $null
                    }
                )
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    APIEndpoint        = 'JSSResource/advancedcomputersearches/id/104'
                    ConsoleURL         = 'https://jss.asc.ohio-state.edu:8443'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.Serial_Number)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.Computer_Name) {$Asset.Computer_Name.Trim()}'
                            'ProductName'    = '$Asset.Model.Trim()'
                            'ProductPart'    = '$Asset.Model_Identifier.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"ASC Jamf"'
                            'OS Version'                = '$Asset.Operating_System'
                            'IP Address'                = '$Asset.IP_Address'
                            'MAC Address 1'             = '$Asset.MAC_Address'
                            'Recent User Name'          = 'if ($Asset.Last_User_Login) {$Asset.Last_User_Login} else {$Asset.Username}'
                            'Last Check-In'             = '$Asset.Last_Check_in'
                            'Encryption Status'         = '$Asset.FileVault_2_Status'
                            'CPU'                       = '"$($Asset.Processor_Type), $($Asset.Processor_Speed_MHz / 1000)GHz, $($Asset.Total_Number_of_Cores) cores"'
                            'Physical Memory (GB)'      = '($Asset.Total_RAM_MB / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = '($Asset.Drive_Capacity_MB / 1000).ToString("#,##0.00")'
                            'Boot Disk Free Space (GB)' = '($Asset.Boot_Drive_Available_MB / 1000).ToString("#,##0.00")'
                            'Backup Console ID'         = 'if ($Asset.Code42_GUID -ne "Identity file(s) not found.") {if ($Asset.Code42_GUID) {$Asset.Code42_GUID} else {$Asset.Code42_Status}}'
                            'Nessus Console ID'         = '$Asset.Nessus_UUID'
                            'AV Console ID'             = '$Asset.SEP_ClientId'
                        }
                    }
                }
            }
            @{
                Name         = 'ASCJamfMobile'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'JamfMobile'
                IsActive     = $false
                Function     = 'Get-JamfData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'ASC'
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    APIEndpoint        = 'JSSResource/advancedmobiledevicesearches/id/109'
                    ConsoleURL         = 'https://jss.asc.ohio-state.edu:8443'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation "`$(`$Asset.Serial_Number)" -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.name) {$Asset.name.Trim()}'
                            'ProductName'    = '$Asset.Model.Trim()'
                            'ProductPart'    = '$Asset.Model_Identifier.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"ASC Jamf"'
                            'OS Version'                = '$Asset.iOS_Version'
                            'IP Address'                = '$Asset.IP_Address'
                            'MAC Address 1'             = '$Asset.Wi_Fi_MAC_Address'
                            'Recent User Name'          = '$Asset.Username'
                            'Last Check-In'             = '$Asset.Last_Inventory_Update'
                            'Encryption Status'         = '$Asset.Data_Protection'
                        }
                    }
                }
            }
            @{
                Name         = 'Satellite'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'Satellite'
                IsActive     = $true
                Function     = 'Get-SatelliteData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'ASC'
                Supplemental = @(
                    @{
                        Name = 'Active Directory'
                        Parameters = $null
                    }
                )
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    BadProductNames    = @"
                        @(
                            `$(`$TDConfig.BadProductNames)
                        )
"@
                    ConsoleURL         = 'https://satellite-01.asc.ohio-state.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("`$(`$Asset.facts.`"dmi::chassis::serial_number`")","`$(`$Asset.facts.`"dmi::system::serial_number`")","`$(`$Asset.facts.`"dmi::baseboard::serial_number`")","`$(`$Asset.facts.serialnumber)") -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.certname) {$Asset.certname.Split(".")[0].Trim()}'
                            'ProductName'    = @"
                                if (-not [string]::IsNullOrEmpty(`$Asset.facts.'dmi::system::product_name') -and -not (`$Asset.facts.'dmi::system::product_name' -in (Invoke-Expression `$Connector.Data.BadProductNames)))
                                {
                                    `$Asset.facts.'dmi::system::product_name'.Trim()
                                }
                                elseif (-not [string]::IsNullOrEmpty(`$Asset.facts.'dmi::baseboard::product_name') -and -not (`$Asset.facts.'dmi::baseboard::product_name' -in (Invoke-Expression `$Connector.Data.BadProductNames)))
                                {
                                    `$Asset.facts.'dmi::baseboard::product_name'.Trim()
                                }
                                elseif (-not [string]::IsNullOrEmpty(`$Asset.facts.productname) -and -not (`$Asset.facts.productname -in (Invoke-Expression `$Connector.Data.BadProductNames)))
                                {
                                    `$Asset.facts.productname.Trim()
                                }
                                else
                                {
                                    `$null
                                }
"@
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"Satellite"'
                            'OS Version'                = '"$($Asset.facts.`"distribution::name`") $($Asset.facts.`"distribution::version`") $($Asset.facts.`"distribution::version::modifier`")"'
                            'IP Address'                = '$Asset.ip'
                            'MAC Address 1'             = '$Asset.mac'
                            'Last Check-In'             = '$Asset.updated_at.Trim(" UTC") | Get-Date'
                            'CPU'                       = '$Asset.facts."lscpu::model_name"'
                            'Physical Memory (GB)'      = 'if ($Asset.facts."memory::memtotal" -ne $null) {($Asset.facts."memory::memtotal" / 1024 / 1024).ToString("#,##0.00")} elseif ($Asset.facts.memorysize_mb -ne $null) {($Asset.facts.memorysize_mb / 1024).ToString("#,##0.00")}'
                        }
                    }
                }
            }
            @{
                Name         = 'Puppet'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                Class        = 'Asset'
                Subclass     = 'Puppet'
                IsActive     = $true
                Function     = 'Get-PuppetData -Connector $Connector -ConnectorCredential $ConnectorCredential'
                AuthRequired = 'ASC'
                Supplemental = @(
                    @{
                        Name = 'Active Directory'
                        Parameters = @{
                            Name = '$Asset.SupplementalAttributes.ADName'
                        }
                    }
                )
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = @"
                        @(
                            `$(`$TDConfig.BadSerialNumbers)
                        )
"@
                    BadProductNames    = @"
                        @(
                            `$(`$TDConfig.BadProductNames)
                        )
"@
                    ConsoleURL         = 'http://puppet.asc.ohio-state.edu:8080'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("`$(`$Asset.serialnumber)","`$(`$Asset.boardserialnumber)") -BadSerialNumbers (Get-BadSerialNumber -Connector $Connector)'
                            'Name'           = 'if ($Asset.hostname) {$Asset.hostname.Trim()}'
                            'ProductName'    = @"
                                if (-not [string]::IsNullOrEmpty(`$Asset.productname) -and -not (`$Asset.productname -in (Invoke-Expression `$Connector.Data.BadProductNames)))
                                {
                                    `$Asset.productname.Trim()
                                }
                                elseif (-not [string]::IsNullOrEmpty(`$Asset.boardproductname) -and -not (`$Asset.boardproductname -in (Invoke-Expression `$Connector.Data.BadProductNames)))
                                {
                                    `$Asset.boardproductname.Trim()
                                }
                                else
                                {
                                    `$null
                                }
"@
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"Puppet"'
                            'OS Version'                = '"$($Asset.os.name) $($Asset.os.release.full)"'
                            'IP Address'                = '$Asset.ipaddress'
                            'MAC Address 1'             = '$Asset.macaddress'
                            'Last Check-In'             = '$Asset.producer_timestamp | Get-Date'
                            'CPU'                       = '$Asset.processor0'
                            'Physical Memory (GB)'      = '($Asset.memorysize_mb / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = 'if ($Asset.blockdevice_sda_size) {($Asset.blockdevice_sda_size / 1000 / 1000 / 1000).ToString("#,##0.00")} else {(($Asset.partitions | Where-Object drive_letter -eq "C").size / 1000 / 1000 / 1000).ToString("#,##0.00")}'
                            'Boot Disk Free Space (GB)' = 'if ($Asset.drives.C) {($Asset.drives.C.free_bytes /1000 /1000 /1000).ToString("#,##0.00")}'
                            'Backup Console ID'         = 'if ($Asset.code42_guid -ne "800500063364859900") {$Asset.code42_guid}'
                            'Nessus Console ID'         = '$Asset.nessus_uuid'
                            'AV Console ID'             = '$Asset.sep_clientid'
                        }
                        SupplementalAttributesMap = @{
                            'ADName'                    = 'if ($Asset.ad_bind.netbios_name) {$Asset.ad_bind.netbios_name} else {$Asset.hostname}'
                        }
                    }
                }
            }
            @{
                Name         = 'Active Directory Assets'
                Application  = 'Assets/CIs'
                Type         = 'Supplemental'
                Class        = 'Asset'
                Subclass     = 'ActiveDirectory'
                IsActive     = $true
                Function     = 'Get-AssetDataFromAD -Connector $Connector'
                AuthRequired = $null
                # Additional info required for the connector
                Data = @{
                    ADDomainName = 'asc.ohio-state.edu'
                    Properties   = @(
                        'CanonicalName, LastLogonDate'
                    )
                    FieldMappings = @{
                        'OrganizationalUnit'  = '$Matches = $null; $ConnectorQuery.CanonicalName -match "ASC.OHIO-STATE.EDU\/(THE OHIO STATE UNIVERSITY\/_ASC COLLEGE OF ARTS AND SCIENCES\/)?(.*)" | Out-Null; $Matches[2]'
                        'ADLastLastLogonDate' = '$ConnectorQuery.LastLogonDate'
                    }
                }
            }
            #endregion
            #region User connectors
            # User primary connector functions must support -Username and -All parameters to get data for individual/all users
            #  In Function, $ConnectorCredential holds credentials, as requested by name in AuthRequired at runtime.
            #  Special AttributesMap keys in FieldMappings include:
            #   LocationSearch (text search string for building and room)
            #   BuildingNumber (maps to Location ExternalID)
            #   RoomNumber (maps to LocationRoomName)
            @{
                Name         = 'Active Directory People'
                Application  = 'People'
                Type         = 'Primary'
                Class        = 'User'
                Subclass     = 'ActiveDirectory'
                IsActive     = $true
                #Function (All)     = 'Get-ADUser -Server $Connector.Data.ADDomainName -Filter "Enabled -eq $true" -SearchBase $DepartmentDN | Where-Object UserPrincipalName -Match "^$($TDConfig.UsernameRegex)@.*$"'
                Function     = "Get-ADUser -Filter `"UserPrincipalName -eq ```"`$Username@`$(`$Connector.Data.ADDomainName)```"`" -Server `$Connector.Data.ADDomainName -Properties `$Connector.Data.UserAttributesList"
                AuthRequired = $null
                # Additional info required for the connector
                Data = @{
                    SetUserRole = $true
                    ADDomainName = 'asc.ohio-state.edu'
                    UserAttributesList = @(
                        'UserPrincipalName',
                        'Enabled',
                        'GivenName',
                        'Surname',
                        'MiddleName',
                        'EmployeeID',
                        'Company',
                        'DistinguishedName',
                        'Title',
                        'Office',
                        'City',
                        'State',
                        'PostalCode'
                    )
                    Include = @{
                        ADSearchBase = @(
                            'OU=_ASC College of Arts and Sciences,OU=The Ohio State University,DC=asc,DC=ohio-state,DC=edu',
                            'OU=Non-Affiliated,DC=asc,DC=ohio-state,DC=edu',
                            'OU=_MRSH Mershon Center,OU=The Ohio State University,DC=asc,DC=ohio-state,DC=edu'
                        )
                    }
                    Exclude = @{
                        OU = 'Students'
                    }
                    FieldMappings = @{
                        AttributesMap = @{
                            DefaultAccountID = @"
                                `$User.DistinguishedName -match '(?:(^CN=.+?,OU=_(.+?),.*)(?:OU=The Ohio State University))|(?:(^CN=.+?,(OU=.+?,)?OU=(.+?),.*)(?!OU=The Ohio State University))' | Out-Null # Department DN starts with "OU=_" and stop collecting at the comma that follows
                                `$DepartmentName = `$Matches[[int](`$Matches.Keys | Measure-Object -Maximum).Maximum] # Take last match
                                `if (`$DepartmentName -eq `'Foreign Language Center (FLC)`') {`$DepartmentName = `'Center for Languages, Literatures and Cultures (CLLC)`'}
                                `$TDAccounts.Get(`$DepartmentName).ID
"@
                            Username       = '"$($User.UserPrincipalName.Split(`"@`")[0])@$($TDConfig.DefaultEmailDomain)"'
                            IsActive       = '$User.Enabled'
                            Firstname      = '$User.GivenName'
                            LastName       = '$User.Surname'
                            MiddleName     = '$User.MiddleName'
                            PrimaryEmail   = '"$($User.UserPrincipalName.Split(`"@`")[0])@$($TDConfig.DefaultEmailDomain)"'
                            AlertEmail     = '"$($User.UserPrincipalName.Split(`"@`")[0])@$($TDConfig.DefaultEmailDomain)"'
                            AlternateID    = '$User.EmployeeID'
                            Title          = '$User.Title'
                            Company        = 'if ($User.Company) {$User.Company} else {"The Ohio State University"}'
                            LocationSearch = '$User.Office'
                            WorkCity       = '$User.City'
                            WorkState      = '$User.State'
                            WorkZip        = '$User.PostalCode'
                            WorkPhone      = '$User.OfficePhone'
                        }
                        CustomAttributesMap = @{
                        }
                    }
                }
            }
            @{
                Name         = 'FindPeople'
                Application  = 'People'
                Type         = 'Primary'
                Class        = 'User'
                Subclass     = 'FindPeople'
                IsActive     = $true
                Function     = 'Get-OSUDirectoryListing -NameN $Username -Credential $ConnectorCredential -Connector $Connector'
                AuthRequired = 'PeopleAPI'
                # Additional info required for the connector
                Data = @{
                    SetUserRole = $false
                    FieldMappings = @{
                        AttributesMap = @{
                            DefaultAccountID = @"
                                `$UserAccount = if (`$User.Organization) {`$User.Organization.Split("|")[-1].Trim()}
                                switch (`$UserAccount)
                                {
                                    'Student Affairs Advising'                        {`$DepartmentName = 'Advising'}
                                    'African American and African Studies'            {`$DepartmentName = 'African American Studies (AAAS)'}
                                    'Anthropology'                                    {`$DepartmentName = 'Anthropology'}
                                    'Arabidopsis Biological Resource Center'          {`$DepartmentName = 'Arabidopsis Biological Resource Center (ABRC)'}
                                    'Art'                                             {`$DepartmentName = 'Art'}
                                    'Arts Administration Education and Policy'        {`$DepartmentName = 'Art Education'}
                                    'Information Technology'                          {`$DepartmentName = 'ASC Technology'}
                                    'Astronomy'                                       {`$DepartmentName = 'Astronomy'}
                                    'Service Center'                                  {`$DepartmentName = 'Business Services Center (BSC)'}
                                    'Center for Career and Professional Success'      {`$DepartmentName = 'Career Services'}
                                    'Center for Applied Plant Sciences'               {`$DepartmentName = 'Center for Applied Plant Sciences (CAPS)'}
                                    'Center for Languages Literature and Cultures'    {`$DepartmentName = 'Center for Languages, Literatures and Cultures (CLLC)'}
                                    'Center for Folklore Studies'                     {`$DepartmentName = 'Center for Folklore Studies (CFS)'}
                                    'Center for Human Resource Research'              {`$DepartmentName = 'Center for Human Resource Research (CHRR)'}
                                    'Center for Medieval and Renaissance Studies'     {`$DepartmentName = 'Center for Medieval and Renaissance Studies (CMRS)'}
                                    'Center for Study of Teaching and Writing'        {`$DepartmentName = 'Center for the Study and Teaching of Writing (CSTW)'}
                                    'Center for the Study of Religion'                {`$DepartmentName = 'Center for the Study of Religion'}
                                    'Chemistry and Biochemistry Administration'       {`$DepartmentName = 'Chemistry and Biochemistry (CBC)'}
                                    'Classics'                                        {`$DepartmentName = 'Classics (Formerly Greek and Latin)'}
                                    'Center for Humanities'                           {`$DepartmentName = 'Colab Research and Public Humanities'}
                                    'Marketing and Communications'                    {`$DepartmentName = 'Communications'}
                                    'Comparative Studies'                             {`$DepartmentName = 'Comparative Studies'}
                                    'Student Affairs Curriculum and Assessment'       {`$DepartmentName = 'Curriculum'}
                                    'Dance'                                           {`$DepartmentName = 'Dance'}
                                    'Design'                                          {`$DepartmentName = 'Design'}
                                    'Development Constituency Fundraising'            {`$DepartmentName = 'Development'}
                                    'Earth Sciences'                                  {`$DepartmentName = 'Earth Sciences'}
                                    'East Asian Languages and Literatures'            {`$DepartmentName = 'East Asian Languages and Literature (EALL)'}
                                    'Economics'                                       {`$DepartmentName = 'Economics'}
                                    'English'                                         {`$DepartmentName = 'English'}
                                    'Environmental Science Graduate Program'          {`$DepartmentName = 'Environmental Sciences Network'}
                                    'Evolution Ecology and Organismal Biology'        {`$DepartmentName = 'Evolution Ecology and Organismal Biology (EEOB)'}
                                    'French and Italian'                              {`$DepartmentName = 'French and Italian (FRIT)'}
                                    'Geography'                                       {`$DepartmentName = 'Geography'}
                                    'Germanic Languages and Literatures'              {`$DepartmentName = 'Germanic Languages and Literatures (GLL)'}
                                    'History'                                         {`$DepartmentName = 'History'}
                                    'History of Art'                                  {`$DepartmentName = 'History of Art'}
                                    'Student Affairs Honors Advising'                 {`$DepartmentName = 'Honors'}
                                    'Center for Life Science Education'               {`$DepartmentName = 'Introductory Biology'}
                                    'Melton Center for Jewish Studies'                {`$DepartmentName = 'Jewish Studies'}
                                    'Linguistics'                                     {`$DepartmentName = 'Linguistics'}
                                    'Mathematics'                                     {`$DepartmentName = 'Mathematics'}
                                    'Microbiology Administration'                     {`$DepartmentName = 'Microbiology'}
                                    'Molecular Genetics Administration'               {`$DepartmentName = 'Molecular Genetics'}
                                    'The Mershon Center'                              {`$DepartmentName = 'MRSH Mershon Center'}
                                    'Near Eastern Languages and Cultures'             {`$DepartmentName = 'Near Eastern Languages and Cultures (NELC)'}
                                    'Office of the Deans'                             {`$DepartmentName = 'Office of the Executive Dean'}
                                    'Philosophy'                                      {`$DepartmentName = 'Philosophy'}
                                    'Physics Administration'                          {`$DepartmentName = 'Physics'       }
                                    'Political Science'                               {`$DepartmentName = 'Political Science'}
                                    'Psychology'                                      {`$DepartmentName = 'Psychology'}
                                    'Student Affairs Undergraduate Recruitment'       {`$DepartmentName = 'Recruitment and Diversity Services'}
                                    'School of Communication'                         {`$DepartmentName = 'School of Communication'}
                                    'Music'                                           {`$DepartmentName = 'School of Music'}
                                    'OSU Marching Band'                               {`$DepartmentName = 'School of Music'}
                                    'Slavic and East European Languages and Cultures' {`$DepartmentName = 'Slavic and East European Languages and Literatures (SEELL)'}
                                    'Sociology'                                       {`$DepartmentName = 'Sociology'}
                                    'Spanish and Portuguese'                          {`$DepartmentName = 'Spanish and Portuguese (SPPO)'}
                                    'Speech Hearing Science'                          {`$DepartmentName = 'Speech and Hearing'}
                                    'Statistics'                                      {`$DepartmentName = 'Statistics'}
                                    'Theatre, Film, and Media Arts'                   {`$DepartmentName = 'Theatre'}
                                    'University Press'                                {`$DepartmentName = 'Upress'}
                                    'Womens Gender and Sexuality Studies'             {`$DepartmentName = 'Womens Studies'}
                                }
                                `$TDAccounts.Get(`$DepartmentName).ID
"@
                            Username       = '"$($User.Username)@$($TDConfig.DefaultEmailDomain)"'
                            PrimaryEmail   = '"$($User.Username)@$($TDConfig.DefaultEmailDomain)"'
                            AlertEmail     = '"$($User.Username)@$($TDConfig.DefaultEmailDomain)"'
                            AlternateEmail = 'if ($User.Student) {"$($User.Username)@$($TDConfig.AlternateEmailDomain)"}'
                            IsActive       = '$User.Affiliated'
                            Firstname      = '$User.FirstName'
                            LastName       = '$User.LastName'
                            MiddleName     = '$User.MiddleName'
                            WorkAddress    = '$User.Street'
                            WorkCity       = '$User.City'
                            WorkState      = '$User.State'
                            WorkZip        = '$User.Zip'
                            WorkPhone      = '$User.Phone'
                            BuildingNumber = '$User.BuildingNumber'
                            RoomNumber     = '$User.Room'
                            Title          = '$User.WorkingTitle'
                            Company        = 'if ($User.Organization) {$User.Organization.Split("|")[0].Trim()} else {"The Ohio State University"}'
                            AlternateID    = '$User.EmployeeID'
                        }
                        CustomAttributesMap = @{
                        }
                    }
                }
            }
            @{
                Name         = 'FindPeople'
                Application  = 'People'
                Type         = 'Supplemental'
                Class        = 'User'
                Subclass     = 'FindPeople'
                IsActive     = $true
                Function     = 'Get-OSUDirectoryListing -NameN $Username -Credential $ConnectorCredential -Connector $Connector'
                AuthRequired = 'PeopleAPI'
                # Additional info required for the connector
                Data = @{
                    SetUserRole = $false
                    FieldMappings = @{
                        AttributesMap = @{
                            Firstname      = 'if ($null -ne $User.FirstName) {$User.FirstName}'
                            LastName       = 'if ($null -ne $User.LastName ) {$User.LastName }'
                            MiddleName     = 'if (-not [string]::IsNullOrEmpty($User.MiddleName)) {$User.MiddleName}'
                            WorkAddress    = 'if (-not [string]::IsNullOrEmpty($User.Street    )) {$User.Street}    '
                            WorkCity       = 'if (-not [string]::IsNullOrEmpty($User.City      )) {$User.City}      '
                            WorkState      = 'if (-not [string]::IsNullOrEmpty($User.State     )) {$User.State}     '
                            WorkZip        = 'if (-not [string]::IsNullOrEmpty($User.Zip       )) {$User.Zip}       '
                            WorkPhone      = 'if (-not [string]::IsNullOrEmpty($User.Phone     )) {$User.Phone}     '
                            BuildingNumber = '$User.BuildingNumber'
                            RoomNumber     = '$User.Room'
                            AlternateEmail = 'if ($User.Student) {"$($User.Username)@$($TDConfig.AlternateEmailDomain)"}'
                        }
                        CustomAttributesMap = @{
                        }
                    }
                }
            }
            #endregion
            #region Data storage connector
            #  Used to store historical data for later reference
            #  Only one active storage connector is allowed
            #  In default configuration, used to store user data for comparison, to avoid updating every user every week
            #  Load all data vs. database query per item?
            @{
                # XML data store, keeps data in files
                Name      = 'XML Store'
                Type      = 'Storage'
                IsActive  = $true
                Function  = 'Get-XMLHistoricalData'
                Directory = '$TDConfig.LogFileDirDefault'
                # Additional info required for the connector
                Data = @{}
            }
            #endregion
        )
    #endregion
}
'@

    # Regular expression is built from spaces ahead of the setting name, spaces, an equal-sign, spaces, the setting value, then spaces
    #  The part before the setting name
    $SearchPrepend = '(?m)^\s*'
    #  The part after the setting name (contains the setting value)
    $SearchAppend  = '\s*=\s*(?<Setting>.*?)\s*$'

    # Check to see if the config file is missing or old - needs to be updated/created
    if ($CurrentSettings.ConfigurationVersion -ne $ConfigurationVersion) {
        # Check to see if there were settings to import from the existing file
        if ($CurrentSettings) {
            # Step through each setting
            foreach ($Setting in $DefaultSettings) {
                # Construct the regular expression as described above
                $Regex = "$SearchPrepend$Setting$SearchAppend"
                if ($CurrentSettings.$Setting) {
                    # Clear previous matches
                    Clear-Variable Matches -ErrorAction Ignore -Confirm:$false
                    # Search the default configuration for the setting name
                    $DefaultConfiguration -match $Regex | Out-Null
                    # The entire line is captured in $Matches[0], which we'll adjust and put back in place
                    $DefaultLine = $Matches[0]
                    # Check to see how to format (strings need quotes)
                    switch ($CurrentSettings.$Setting.GetType().Name)
                    {
                        Int32  {$CurrentSettingsString =   "$($CurrentSettings.$Setting)"}
                        String {$CurrentSettingsString = "`'$($CurrentSettings.$Setting)`'"}
                    }
                    # Replace the default setting in the line, captured in $Matches.Setting, with the setting from the current config file
                    $UpdatedLine = $DefaultLine.Replace($Matches.Setting, $CurrentSettingsString)
                    # Swap the old line in the default configuration for the new one
                    $DefaultConfiguration = $DefaultConfiguration.Replace($DefaultLine, $UpdatedLine)
                }
            }
            # Keep a copy of the old configuration file
            Move-Item $PSScriptRoot\Configuration.psd1 $PSScriptRoot\Configuration.old -Force
        }
        # Configuration has been rebuilt from the default, now add configuration version number in the same way settings were updated
        # Construct the regular expression for ConfigVersion as described above
        $Regex = "$($SearchPrepend)ConfigurationVersion$SearchAppend"
        # Clear previous matches
        Clear-Variable Matches -ErrorAction Ignore -Confirm:$false
        # Search the default configuration for the setting name
        $DefaultConfiguration -match $Regex | Out-Null
        # The entire line is captured in $Matches[0], which we'll adjust and put back in place
        $DefaultLine = $Matches[0]
        # Replace the placeholder setting in the line with the version number
        $UpdatedLine = $DefaultLine.Replace('XXXConfigurationVersionXXX', $ConfigurationVersion)
        # Swap the old line in the default configuration for the new one
        $DefaultConfiguration = $DefaultConfiguration.Replace($DefaultLine, $UpdatedLine)

        # Write new configuration file
        $DefaultConfiguration | Out-File $PSScriptRoot\Configuration.psd1
        $Return = $true
    }
    return $Return
}
# SIG # Begin signature block
# MIIOsQYJKoZIhvcNAQcCoIIOojCCDp4CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdCzUZJ3J/htXE/pYFepCFSuk
# BHqgggsLMIIEnTCCA4WgAwIBAgITXAAAAASry1piY/gB3QAAAAAABDANBgkqhkiG
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFDrQ
# uGU4PNj5P26rfgAn3hO/lQ0rMA0GCSqGSIb3DQEBAQUABIICAGEk3NCPxEE0WDYs
# vio/oqY0D02BsHJrDZgXzsdM8FRly70EVKAlfFSYmQe8FxOxrEFVupkrwSQGojs1
# 35/IQ6bH9ztaQOtYtORBMkKKDYomz85GMFuKQDkWb26mvcO6cQDTcdRx0ZLAdX1E
# +JN+D2l4wy4b1tZDx6w//VjUl5bB9/Cvn7BnMnS4EUeFZ9NCyGRCFfDM7i6o5VR0
# qBdn+ydUGrwmaUPO0G2jZ1QZfh8lj3htgs4yMV3J6ixqcebUWG9WoAOMZ8g4NKEz
# mde8kXiQnGI2DZC+Db/uzeL+0Q2lknHRrtm/MG03Qn1SMyO3oCTMWFM4SqBeF6WM
# Lu+RLskPxkOxjjshQJ5s/MAA4vfySVzi3NqC0CxSaRKSNy+aNNhutaV2sAJLbT3q
# i/iEerXPikEqTZZ3UfaZaP44IWpE+oRQqvezpVlEd1RU5lM2MAy6ggJm79xLvYAI
# G5mNnV2T6uwojnvSmr8by8acL7a/dV5mzuZwarskl6ME4SnhgXvH3V500QTw/E4W
# UsnIti08eQGt5kBoU2wOc2YRfWt3SodFyVNVzWUTVyt/cNAvWW3GziTJKYRotyMZ
# a6crc/WXsFuVTekIFGiPnFcR4PcsZI09QxrGmOSVj+gpLyjUl8rT/hA4wOv25HrH
# 9JN8EGFTWJyH5K73AJyCrs8z6v+1
# SIG # End signature block
