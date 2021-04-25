### Attachments

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
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}

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
    end
    {
        Write-ActivityHistory "-----`nLeaving $($MyInvocation.MyCommand.Name)"
    }
}
