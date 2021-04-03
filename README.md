Project provides a PowerShell wrapper to many TeamDynamix REST API calls. Also includes local TeamDynamix management functions. Some of the wrappers and functions have been debugged.

Import the module with "Import-Module TeamDynamix", which will prompt for TeamDynamix credentials and initialize the module to the desired environment with a reporting history depth of 1 item in the event of an error. All commands issued will default to the environment specified when the module was loaded. The environment may be overridden on each command, if desired.

The TeamDynamix authentication information provided during import will be used for all subsequent commands, unless specifically overridden. The authentication is valid for 24 hours. It may be updated at any time so that it is valid for another 24 hours, or the identity of the logged in user changed, by using the "Update-TDAuthentication" command. Information about the current authentication, including its age, is available from the Get-TDAuthentication command. If desired, alternate credentials may be obtained using the "Set-TDAuthentication -Passthru" command, and then used with the -AuthenticationToken option on TeamDynamix commands.

Parameters available in the ArgumentList for Import-Module TeamDynamix are (in positional order):
Credential - Provide a credential object or a path to one to log into TeamDynamix.
Environment - Valid choices are "Production", "Sandbox", and "Preview". Initializes the module from the named TeamDynamix site (environment) and sets the default for all commands to be from that environment. The default is "Production".
MaxActivityHistoryDefault - Set the number of recent events to report in case of an error. Used for debugging. Default is 1.


If options are desired for the import, add their values in order. Values omitted at the end will be set to their defaults. Values prior to the end must not be omitted.
Example 1:
    Import-Module TeamDynamix

    The default. Prompts for TeamDynamix credentials. Initializes the module to the production environment with a reporting history depth of 1 item in the event of an error.
Example 2:
    Import-Module TeamDynamix -ArgumentList $Credential

    Initializes the module to the production environment with a reporting history depth of 1 item in the event of an error.
Example 3:
    Import-Module TeamDynamix -ArgumentList $Credential,,2

    Initializes the module to the production environment with a reporting history depth of 2 items in the event of an error.
Example 4:
    Import-Module TeamDynamix -ArgumentList $Credential,Sandbox,1

    Initializes the module to the sandbox environment with a reporting history depth of 1 item in the event of an error.
Example 5:
    Import-Module TeamDynamix -ArgumentList $Credential,Preview,1

    Initializes the module to the preview environment with a reporting history depth of 1 item in the event of an error.

If TeamDynamix is set to use an external authentication system, such as Shibboleth, users wishing to authenticate to the TeamDynamix API will have to request that their password be set manually by a TeamDynamix administrator.

Where they are used as parameters that list their values, slowly changing data, such as security roles, ticket and asset statuses, group and account names, vendors, forms, and searches, are cached for performance reasons. They are only updated when the module is imported.

Configure local defaults, including TeamDynamix portal URLs, log file directories, security roles, default applications, and data connectors in the Configuration.psd1 file.
Currently, only settings in "region Required" are implemented. Other settings are present for future development. Contact Brian Keller if you wish to participate in the development process.

Send questions and comments to keller.4@osu.edu.