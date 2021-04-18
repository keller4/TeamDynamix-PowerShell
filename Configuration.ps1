function Update-ConfigurationFile {
    $Return = $false
    # Set current version of the configuration file, increment to module version when config file changes
    $ConfigurationVersion = '2.0.9'
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
        'DefaultTDPortalBaseURI'
        'DefaultTDPortalPreviewBaseURI'
        'DefaultADConnector'
        'DirectoryLookup'
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

            # Set default TeamDynamix applications
            DefaultAssetCIsApp  = 'Assets/CIs'
            DefaultTicketingApp = 'Tickets'
            DefaultPortalApp    = 'Client Portal'

            # TeamDynamix portal target
            DefaultTDPortalBaseURI        = 'https://osuasc.teamdynamix.com'
            DefaultTDPortalPreviewBaseURI = 'https://osuasc.teamdynamixpreview.com'
        #endregion

        #region Optional settings
            # Active Directory configuration info
            #  Must be a user connector
            #  Must have a DefaultADDomainName and DefaultADSearchBase for finding departments
            #  Must be marked as active
            DefaultADConnector = 'Active Directory'

            # User directory information command
            #  Command should be written so it is possible to add the name to lookup to the end
            DirectoryLookup = 'Get-OSUDirectoryListing -Properties * -Name'

            # Activity reporting queue depth, select any value 1 or higher
            #  This is the number of recent activities to be reported when there is an error
            #  Used for debugging
            #  Recommended default: 1
            MaxActivityHistoryDefault = 1

            # Define security roles for users
            # Role names must be unique
            # Security roles must match a TD security role, same for FunctionalRole and TD functional role, this does not create the roles
            # Function is code used to determine if someone belongs in one of the roles (do not include by default)
            #  User is granted the first role matched by function, so list roles in order of most specific to least specific
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
                    Function = '$User.DefaultAccountName -eq "ASC Technology" -and $User.Title -like "*Student Assistant*"'
                }
                @{
                    Name = 'Technician'
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
                    Function = '$User.DefaultAccountName -eq "ASC Technology"'
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
                    Function = $null
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
                    Function = $null
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
                    Function = $null
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
                    Function = $null
                }
            )
        #endregion
    #endregion

    #region Application configuration (add as necessary)
        # Default asset application - usually named "Assets/CIs"
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

        # Default ticket application - usually named "Tickets"
        TicketingApplications = @(
            @{
                # Required
                #  Name of application, used to refer to its settings
                Name = 'Tickets'
                # Optional
                DefaultSecurityRole = 'Ticketing - Tech Access'
            }
        )

        # Default portal application - name: "Client Portal"
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
        # Deactivate a connector by setting IsActive to $false
        # Function is the name of the function to call (with complete parameters) to retrieve data from the connector
        #  The connector must be found manually in the function definition, but $Connector may be used in the field mappings
        # AuthRequired gives the name of the authentication required, which will be prompted for
        #  Use $null for systems that do not require authentication
        # Data contains all settings needed for the connector
        #  Field mappings use:
        #   $Asset to refer to the current asset from the connector
        #   $User to refer to the current user from the connector
        #   $Connector to refer to the current connector
        #  Field mapping logic and code will be executed as written, expecting a string output
        #   Use Here-String for multi-line code blocks in field mapping logic
        DataConnectors = @(
            #region Asset connectors
            @{
                # SCCM connector requires that the SCCM PowerShell cmdlets are installed on the machine running the update
                Name         = 'SCCM'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                IsActive     = $true
                Function     = 'Get-SCCMData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "SCCM" -and $_.IsActive -eq $true})'
                AuthRequired = $null
                Supplemental = $null
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = $null
                    BadProductNames    = '$TDConfig.BadProductNames'
                    # Query names for retrieving asset info
                    SCCMQueryNames = @(
                        'BK Inventory'
                        'BK Inventory - BitLocker Info'
                        'BK Inventory - Disk Info'
                    )
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.SerialNumber.SerialNumber") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.SMS_R_System.Name) {$Name = $Asset.SMS_R_System.Name.Trim()}'
                            'ProductName'    = '$Asset.SMS_G_System_COMPUTER_SYSTEM.Model.Trim()'
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"SCCM"'
                            'OS Version'                = '"$($Asset.SMS_R_System.OperatingSystemNameandVersion), Build $($Asset.SMS_R_System.Build)"'
                            'IP Address'                = 'if ($Asset.SMS_R_System.IPAddresses ) {$Asset.SMS_R_System.IPAddresses[0] }'
                            'MAC Address 1'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[0]}'
                            'MAC Address 2'             = 'if ($Asset.SMS_R_System.MACAddresses) {$Asset.SMS_R_System.MACAddresses[1]}'
                            'Recent User Name'          = '$Asset.SMS_R_System.LastLogonUserName'
                            'Organizational Unit'       = '$Matches = $null; $Asset.SMS_R_System.SystemOUName[-1] -match "ASC.OHIO-STATE.EDU\/(THE OHIO STATE UNIVERSITY\/_ASC COLLEGE OF ARTS AND SCIENCES\/)?(.*)" | Out-Null; $Matches[2]'
                            'Last Check-In'             = '$Asset.SMS_G_System_WORKSTATION_STATUS.LastHardwareScan'
                            'Encryption Status'         = '($Asset.Encryption | ForEach-Object {"$($_.Driveletter) $($_.ProtectionStatus)"}) -join ", "'
                            'CPU'                       = '$Asset.SMS_G_System_PROCESSOR.Name'
                            'Physical Memory (GB)'      = '($Asset.SMS_G_System_X86_PC_MEMORY.TotalPhysicalMemory / 1024 / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = '(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").DiskSize[0]  / 1000).ToString("#,##0.00")'
                            'Boot Disk Free Space (GB)' = '(($Asset.DiskInfo | Where-Object DriveLetter -eq "C:").FreeSpace[0] / 1000).ToString("#,##0.00")'
                            'Backup Console ID'         = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.code42_guid'
                            'Nessus Console ID'         = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.nessus_uuid'
                            'AV Console ID'             = '$Asset.SMS_G_System_Custom_AllIDs64_1_0.sep_clientid'
                        }
                    }
                }
            }
            @{
                Name         = 'OCIOJamf'
                Application  = 'Assets/CIs'
                Type         = 'Primary'
                IsActive     = $true
                Function     = 'Get-JamfData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "OCIOJamf" -and $_.IsActive -eq $true})'
                AuthRequired = 'OCIO'
                Supplemental = @(
                    @{
                        Name = 'Active Directory'
                        Parameters = $null
                    }
                )
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = $null
                    APIDesktop         = 'JSSResource/advancedcomputersearches/id/63'
                    ConsoleURL         = 'https://jamf.service.osu.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.Serial_Number") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.Computer_Name) {$Name = $Asset.Computer_Name.Trim()}'
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
                IsActive     = $true
                Function     = 'Get-JamfData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "OCIOJamfMobile" -and $_.IsActive -eq $true})'
                AuthRequired = 'OCIO'
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = $null
                    APIMobile          = 'JSSResource/advancedmobiledevicesearches/id/64'
                    ConsoleURL         = 'https://jamf.service.osu.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.Serial_Number") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.name) {$Name = $Asset.name.Trim()}'
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
                IsActive     = $false
                Function     = 'Get-JamfData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "ASCJamf" -and $_.IsActive -eq $true})'
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
                    BadSerialNumbers   = $null
                    APIDesktop         = 'JSSResource/advancedcomputersearches/id/104'
                    ConsoleURL         = 'https://jss.asc.ohio-state.edu:8443'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.Serial_Number") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.Computer_Name) {$Name = $Asset.Computer_Name.Trim()}'
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
                IsActive     = $false
                Function     = 'Get-JamfData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "ASCJamfMobile" -and $_.IsActive -eq $true})'
                AuthRequired = 'ASC'
                # Additional info required for the connector
                Data = @{
                    DefaultAssetStatus = '$TDConfig.DefaultAssetStatus'
                    BadSerialNumbers   = $null
                    APIMobile          = 'JSSResource/advancedmobiledevicesearches/id/109'
                    ConsoleURL         = 'https://jss.asc.ohio-state.edu:8443'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.Serial_Number") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.name) {$Name = $Asset.name.Trim()}'
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
                IsActive     = $true
                Function     = 'Get-SatelliteData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "Satellite" -and $_.IsActive -eq $true})'
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
                    BadSerialNumbers   = $null
                    BadProductNames    = '$TDConfig.BadProductNames'
                    ConsoleURL         = 'https://satellite-01.asc.ohio-state.edu'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.facts.dmi::chassis::serial_number","$Asset.facts.dmi::system::serial_number","$Asset.facts.dmi::baseboard::serial_number","$Asset.facts.serialnumber") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.facts."uname::nodename") {$Name = $Asset.facts."uname::nodename".Split(".")[0].Trim()}'
                            'ProductName'    = @"
                                if ((-not [string]::IsNullOrEmpty(`$Asset.facts.'dmi::system::product_name')) -or (`$Asset.facts.'dmi::system::product_name' -in `$Connector.Data.BadProductNames))
                                {
                                    `$ProductName = `$Asset.facts.'dmi::system::product_name'.Trim()
                                }
                                elseif (-not [string]::IsNullOrEmpty(`$Asset.facts.'dmi::baseboard::product_name'))
                                {
                                    `$ProductName = `$Asset.facts.'dmi::baseboard::product_name'.Trim()
                                }
"@
                            'ProductPart'    = ''
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
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
                IsActive     = $true
                Function     = 'Get-PuppetData -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "Puppet" -and $_.IsActive -eq $true})'
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
                    BadSerialNumbers   = $null
                    BadProductNames    = '$TDConfig.BadProductNames'
                    ConsoleURL         = 'http://puppet.asc.ohio-state.edu:8080'
                    FieldMappings = @{
                        AttributesMap = @{
                            'SerialNumber'   = 'Get-AssetSerialNumber -Asset $Asset -SNLocation @("$Asset.serialnumber","$Asset.boardserialnumber") -BadSerialNumbers (if ($Connector.Data.BadSerialNumbers) {$Connector.Data.BadSerialNumbers} else {$TDConfig.BadSerialNumbers}'
                            'Name'           = 'if ($Asset.hostname) {$Name = $Asset.hostname.Trim()}'
                            'ProductName'    = @"
                                if ((-not [string]::IsNullOrEmpty(`$Asset.productname)) -or (`$Asset.productname -in `$Connector.Data.BadProductNames))
                                {
                                    `$ProductName = `$Asset.productname.Trim()
                                }
                                elseif (-not [string]::IsNullOrEmpty(`$Asset.boardproductname))
                                {
                                    `$ProductName = `$Asset.facts.boardproductname.Trim()
                                }
"@
                            'ProductPart'    = ''
                            'ProductModelID' = 'Get-AssetProductModelID -Asset $Asset -ProductNameLocation $Connector.Data.FieldMappings.AttributesMap.ProductName -ProductPartLocation $Connector.Data.FieldMappings.AttributesMap.ProductName'
                        }
                        CustomAttributesMap = @{
                            'Update Data Source'        = '"Puppet"'
                            'OS Version'                = '"$($Asset.os.name) $($Asset.os.release.full)"'
                            'IP Address'                = '$Asset.ipaddress'
                            'MAC Address 1'             = '$Asset.macaddress'
                            'Last Check-In'             = '$Asset.producer_timestamp | Get-Date'
                            'CPU'                       = '$Asset.processor0'
                            'Physical Memory (GB)'      = '($Asset.memorysize_mb / 1024).ToString("#,##0.00")'
                            'Boot Disk Capacity (GB)'   = '($Asset.blockdevice_sda_size / 1000 / 1000 / 1000).ToString("#,##0.00")'
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
                IsActive     = $true
                Function     = 'Get-AssetDataFromAD -Connector ($TDConfig.DataConnectors | Where-Object {$_.Name -eq "Active Directory Assets" -and $_.IsActive -eq $true})'
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
            @{
                Name         = 'Active Directory People'
                Application  = 'People'
                Type         = 'Primary'
                IsActive     = $true
                Function     = 'Get-UserDataFromAD'
                AuthRequired = $null
                # Additional info required for the connector
                Data = @{
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
                        ADSearchBase = 'OU=_ASC College of Arts and Sciences,OU=The Ohio State University,DC=asc,DC=ohio-state,DC=edu'
                        SupplementalDepartmentOUs = @(
                            'OU=Non-Affiliated,DC=asc,DC=ohio-state,DC=edu'
                            'OU=_MRSH Mershon Center,OU=The Ohio State University,DC=asc,DC=ohio-state,DC=edu'
                        )
                    }
                    Exclude = @{}
                    FieldMappings = @{
                        AttributesMap = @{
                            DefaultAccountID = @"
                                `$User.DistinguishedName -match '(?:(^CN=.+?,OU=_(.+?),.*)(?:OU=The Ohio State University))|(?:(^CN=.+?,(OU=.+?,)?OU=(.+?),.*)(?!OU=The Ohio State University))' | Out-Null # Department DN starts with "OU=_" and stop collecting at the comma that follows
                                `$DepartmentName = `$Matches[[int](`$Matches.Keys | Measure-Object -Maximum).Maximum] # Take last match
                                (`$TDAccounts | Where-Object name -eq `$DepartmentName).ID
"@
                            Username     = '"$($User.UserPrincipalName.Split(`"@`")[0])@$($TDConfig.DefaultEmailDomain)"'
                            IsActive     = '$User.Enabled'
                            Firstname    = '$User.GivenName'
                            LastName     = '$User.Surname'
                            MiddleName   = '$User.MiddleName'
                            PrimaryEmail = '$User.Username'
                            AlertEmail   = '$User.Username'
                            AlternateID  = '$User.EmployeeID'
                            Title        = '$User.Title'
                            Company      = '$User.Company'
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
                IsActive     = $true
                Function     = 'Get-OSUDirectoryListing'
                AuthRequired = $null
                # Additional info required for the connector
                Data = @{
                    ConfigItem = ''
                    FieldMappings = @{
                        AttributesMap = @{
                            Firstname    = 'if ($null -ne $User.FirstName) {$User.FirstName}'
                            LastName     = 'if ($null -ne $User.LastName) {$User.LastName}'
                            MiddleName   = '$User.MiddleName'
                            WorkAddress  = '$User.Street'
                            WorkCity     = '$User.City'
                            WorkState    = '$User.State'
                            WorkZip      = '$User.Zip'
                            WorkPhone    = '$User.Phone'
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
                    $Matches = $null
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
        $Matches = $null
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