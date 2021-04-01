### Attachments

<#
.Synopsis
    Get information on an attachment in TeamDynamix.
.DESCRIPTION
    Get information on an attachment in TeamDynamix. Optionally save the
    attachment to a local directory. Specify the attachment ID number.
.PARAMETER AttachmentID
    Attachment ID to retrieve from TeamDynamix.
.PARAMETER Path
    Save attachment to this directory.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Get-TDAttachment -ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Retrieves attachment info with ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from
    TeamDynamix.
.EXAMPLE
    C:\>Get-TDAttachment -ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -Path C:\Temp -AuthenticationToken $Authentication

    Retrieves attachment with ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from
    TeamDynamix, and saves the file in C:\Temp.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Get-TDAttachment
{
    [CmdletBinding()]
    Param
    (
        # Attachment ID to retrieve from TeamDynamix
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [guid]
        $ID,

         # Path to directory to save attached file
        [Parameter(Mandatory=$false,
                   Position=1)]
        [validatescript({Test-Path -PathType Container $_})]
        [string]
        $Path,

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
        $Process = $true
        try
        {
            $Attachment = [TeamDynamix_Api_Attachments_Attachment]::new((Invoke-RESTCall -Uri "$BaseURI/attachments/$ID" -ContentType $ContentType -Method Get -Headers $AuthenticationToken))
        }
        catch
        {
            Write-ActivityHistory -ErrorRecord $_
            $Process = $false
        }
        if ($Path -and $Process) # Download file
        {
            Invoke-WebRequest -Uri "$BaseURI/attachments/$ID/content" -ContentType $ContentType -Headers $AuthenticationToken -OutFile "$Path\$($Attachment.Name)"
        }
        return $Attachment # Return attachment info
    }
}

<#
.Synopsis
    Deletes an attachment from TeamDynamix
.DESCRIPTION
    Deletes an attachment from TeamDynamix. Specify the attachment ID number.
.PARAMETER ID
    Attachment ID to delete from TeamDynamix.
.PARAMETER AuthenticationToken
    Hashtable with one key: "Authorization" and value of "Bearer" followed
    by the JSON bearer web token. See Set-TDAuthentication.
.PARAMETER Environment
    Execute the commands on the specified TeamDynamix site. Valid options are
    "Production", "Sandbox", and "Preview". Default is the site selected when
    the module was loaded.
.EXAMPLE
    C:\>Remove-TDAttachment -ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX -AuthenticationToken $Authentication

    Removes attachment with ID XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX from
    TeamDynamix.
.NOTES
    Author: Brian Keller <keller.4@osu.edu>
#>
function Remove-TDAttachment
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param
    (
        # Attachment ID to delete from TeamDynamix
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$true,
                   Position=0)]
        [guid]
        $AttachmentID,

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
        if ($pscmdlet.ShouldProcess($ID, 'Remove TeamDynamix attachment'))
        {
            Invoke-RESTCall -Uri "$BaseURI/attachments/$ID" -ContentType $ContentType -Method Delete -Headers $AuthenticationToken
        }
    }
}
