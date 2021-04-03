<#
.SYNOPSIS
GUI front-end for TeamDynamix authentication
.DESCRIPTION
GUI front-end for TeamDynamix authentication. Allows user to select production,
sandbox, or preview site.
#>
function Get-TDGUILogin
{
    [xml]$Xaml = @"
        <Window
            xmlns         = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation'
            xmlns:x       = 'http://schemas.microsoft.com/winfx/2006/xaml'
            SizeToContent = 'WidthAndHeight'
            ShowInTaskbar = 'True'
            Background    = 'lightgray'>
            <StackPanel Orientation = 'Vertical'>
                <Label
                    FontSize   = '18'
                    FontWeight = 'Bold'
                    Content    = 'Enter your TeamDynamix credentials'/>
                <StackPanel Orientation = 'Vertical'>
                    <StackPanel Orientation = 'Horizontal'>
                        <Label
                            Width   = '70'
                            Content = 'Username'/>
                        <TextBox
                            Name   = 'UsernameTextBox'
                            Height = '25'
                            Width  = '200'/>
                    </StackPanel>
                    <StackPanel Orientation = 'Horizontal'>
                        <Label
                            Width   = '70'
                            Content = 'Password'/>
                        <PasswordBox
                            Name         = 'PasswordBox'
                            Height       = '25'
                            Width        = '200'
                            PasswordChar = '*'/>
                    </StackPanel>
                    <TextBox
                        Name   = 'tbAuthName'
                        Visibility = 'Collapsed'/>
                        <TextBox
                        Name   = 'tbAuthValue'
                        Visibility = 'Collapsed'/>
                    <StackPanel
                        Orientation = 'Horizontal'
                        Margin      = '5'>
                        <Border
                            BorderBrush     = 'Silver'
                            BorderThickness = '1'>
                            <StackPanel Name = 'rbSiteGroup'>
                                <Label
                                    FontWeight = 'Bold'
                                    Content    = 'Site Selection'/>
                                <RadioButton
                                    GroupName = 'Site'
                                    Name      = 'Production'
                                    IsChecked = 'True'
                                    Content   = 'Production'/>
                                <RadioButton
                                    GroupName = 'Site'
                                    Name      = 'Sandbox'
                                    Content   = 'Sandbox'/>
                                <RadioButton
                                    GroupName = 'Site'
                                    Name      = 'Preview'
                                    Content   = 'Preview'/>
                            </StackPanel>
                        </Border>
                    <StackPanel
                        VerticalAlignment = 'Bottom'
                        HorizontalAlignment = 'Center'>
                        <Label
                        Name   = 'lbStatus'
                        FontWeight = 'Bold'
                        Visibility = 'Collapsed'/>
                    </StackPanel>
                    </StackPanel>
                    <StackPanel HorizontalAlignment = 'Center'>
                        <Button
                            Name       = 'LoginButton'
                            FontWeight = 'Bold'
                            Margin     = '5'
                            Padding    = '5,2'
                            Content    = 'Login'
                            IsDefault  = 'True'/>
                    </StackPanel>
                </StackPanel>
            </StackPanel>
        </Window>
"@

    # Error if GUI is unsupported
    if (-not $ModuleGUI)
    {
        throw 'Use of the GUI is not supported on this platform.'
    }
    # Set up WPF form
    Add-Type -AssemblyName PresentationFramework
    $XamlReader = (New-Object System.Xml.XmlNodeReader $Xaml)
    $LoginGUI   = [System.Windows.Markup.XamlReader]::Load($XamlReader)

    # Create friendly names for controls
    $UsernameTextBox = $LoginGUI.FindName('UsernameTextBox')
    $PasswordBox     = $LoginGUI.FindName('PasswordBox'    )
    $LoginButton     = $LoginGUI.FindName('LoginButton'    )
    $rbSiteGroup     = $LoginGUI.FindName('rbSiteGroup'    )
    $tbAuthName      = $LoginGUI.FindName('tbAuthName'     )
    $tbAuthValue     = $LoginGUI.FindName('tbAuthValue'    )
    $lbStatus        = $LoginGUI.FindName('lbStatus'       )
    # Shortcut for mass creation: $xaml.SelectNodes('//*[@Name]') | foreach-object {Set-Variable -Name ($_.Name) -Value $LoginGUI.FindName($_.Name)}
    #  See system.xml documentation and XPath for how to query SelectNodes (this one reads: search whole document and return the attribute named, "Name", from all nodes)

    # Set typing focus
    $UsernameTextBox.Focus()

    # Event handlers
    #  Attempt authentication when login button is clicked
    $LoginButton.add_Click(
        {
            Authenticate
        }
    )

    function Authenticate
    {
        # Read Site radiobuttons and find the one that's checked - use to determine which site to authenticate to
        switch (($rbSiteGroup.Children | Where-Object IsChecked -eq $true).Name)
        {
            Production
            {
                $Environment = 'Production'
            }
            Sandbox
            {
                $Environment = 'Sandbox'
            }
            Preview
            {
                $Environment = 'Preview'
            }
        }
        $ErrorFlag = $false
        # Attempt to authenticate
        $PSCredential = New-Object System.Management.Automation.PsCredential ($UsernameTextBox.Text, (ConvertTo-SecureString $PasswordBox.Password -AsPlainText -Force))
        try
        {
            $Authentication = Set-TDAuthentication -Credential $PSCredential -Environment $Environment -NoUpdate
        }
        catch
        {
            switch ($_.Exception.Message)
            {
                "Cannot bind argument to parameter `'Username`' because it is an empty string."
                {
                    $UsernameTextBox.Clear()
                    $PasswordBox.Clear()
                    $lbStatus.Content = 'Error: empty username'
                    $lbStatus.Visibility = 'Visible'
                    $ErrorFlag = $true
                }
                "Cannot bind argument to parameter `'Password`' because it is an empty string."
                {
                    $UsernameTextBox.Clear()
                    $PasswordBox.Clear()
                    $lbStatus.Content = 'Error: empty password'
                    $lbStatus.Visibility = 'Visible'
                    $ErrorFlag = $true
                }
                $script:TDLoginFailureText
                {
                    $UsernameTextBox.Clear()
                    $PasswordBox.Clear()
                    $lbStatus.Content = 'Error: bad user/password'
                    $lbStatus.Visibility = 'Visible'
                    $ErrorFlag = $true
                }
                Default
                {
                    $UsernameTextBox.Clear()
                    $PasswordBox.Clear()
                    $lbStatus.Content = "Error: unspecified - $($_.Exception.Message)"
                    $lbStatus.Visibility = 'Visible'
                    $ErrorFlag = $true
                }
            }
        }
        if (-not $ErrorFlag)
        {
            $LoginButton.Content = 'Logged in'
            $tbAuthName.Text  = $Authentication.Authentication.Keys[0]
            $tbAuthValue.Text = $Authentication.Authentication.Values[0]
            $LoginGUI.close()
        }
    }

    # Launch the window
    $LoginGUI.ShowDialog() | Out-Null
    if ($tbAuthName.Text -eq '')
    {
        throw 'Authentication cancelled.'
    }
    $Return = [PSCustomObject]@{
        Authentication = @{$tbAuthName.Text = $tbAuthValue.Text}
        Site           = ($rbSiteGroup.Children | Where-Object IsChecked -eq $true).Name
        }
    return $Return
}

function Start-TDGUI
{
    [CmdletBinding()]
    Param
    (
    )
    # Setup data
    #$OrganizationalUnits = Get-ADOrganizationalUnit -Filter * -SearchBase $TDConfig.ADSearchBase -SearchScope OneLevel -Server $TDConfig.DefaultADDomainName
    #$OrganizationalUnits += (Get-ADOrganizationalUnit -Identity 'OU=Non-Affiliated,DC=asc,DC=ohio-state,DC=edu' -Server $TDConfig.DefaultADDomainName)
    #$UnitNames = $OrganizationalUnits.Name.Trim('_') | Sort-Object
    #$ADUsers = Get-ADUser -Server $TDConfig.DefaultADDomainName -Filter 'Enabled -eq $true' | Where-Object SamAccountName -match '^\w.*\.\d+$'

    # Create and display the GUI
    [xml]$Xaml = @"
    <Window
        xmlns         = 'http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x       = 'http://schemas.microsoft.com/winfx/2006/xaml'
        Height        = '700'
        Width         = '600'
        ShowInTaskbar = 'True'
        Background    = 'lightgray'
        Name          = 'wMain'>
        <DockPanel Name = 'pMain'>
            <Label
                DockPanel.Dock = 'Top'
                FontSize       = '18'
                FontWeight     = 'Bold'
                Content        = 'TeamDynamix Task'/>
            <DockPanel
                Name           = 'mnuNavigation'
                DockPanel.Dock = 'Top'>
                <WrapPanel>
                    <Button
                        Name    = 'bCommandGUI'
                        Padding = '5,2'
                        Content = 'Command G_UI'/>
                    <Button
                        Name    = 'bUpdateUser'
                        Padding = '5,2'
                        Content = 'U_pdate User Data'
                        Visibility = 'Collapsed'/>
                    <Button
                        Name    = 'bOSUDir'
                        Padding = '5,2'
                        Content = 'OSU Directory _Info'/>
                    <Button
                        Name    = 'bAssetConsistency'
                        Padding = '5,2'
                        Content = 'Asset _Consistency'
                        Visibility = 'Collapsed'/>
                    <Button
                        Name    = 'bGroups'
                        Padding = '5,2'
                        Content = 'Manage User _Groups'
                        Visibility = 'Collapsed'/>
                    <Button
                        Name    = 'bDuplicates'
                        Padding = '5,2'
                        Content ='Manage _Duplicate Assets'
                        HorizontalAlignment = 'Left'/>
                </WrapPanel>
            </DockPanel>
            <DockPanel
                Name       = 'pOSUDir'
                Dock       = 'Top'
                Visibility = 'Collapsed'>
                <DockPanel Dock = 'Top'>
                    <Label>Username</Label>
                    <TextBox
                        Name   = 'tbOSUDirUsername'
                        Height = '25'
                        Width  = '200'/>
                    <Button
                        Name      = 'bOSUDirSearch'
                        Padding   = '5,2'
                        Margin    = '5,0'
                        IsDefault = 'True'
                        Content   = '_Search'
                        HorizontalAlignment = 'Left'/>
                </DockPanel>
                <DockPanel Name = 'pDirOut'>
                    <ScrollViewer
                        VerticalScrollBarVisibility   = 'Auto'
                        HorizontalScrollBarVisibility = 'Auto'>
                        <TextBox
                            Name            = 'tbOSUDirOut'
                            FontFamily      = 'Consolas'
                            Background      = 'Transparent'
                            BorderThickness = '0'
                            Text            = '{Binding Text, Mode=OneWay}'
                            IsReadOnly      = 'True'/>
                    </ScrollViewer>
                </DockPanel>
            </DockPanel>
            <DockPanel
                Name       = 'pUpdateUser'
                Dock       = 'Top'
                Visibility = 'Collapsed'>
                <DockPanel>
                    <Label>Username</Label>
                    <TextBox
                        Name   = 'tbUpdateUserUsername'
                        Height = '25'
                        Width  = '200'/>
                    <Button
                        Name      = 'bUpdateUserSearch'
                        Padding   = '5,2'
                        Margin    = '5,0'
                        IsDefault = 'True'
                        Content   = '_Search'
                        HorizontalAlignment = 'Left'/>
                </DockPanel>
                <ScrollViewer
                    VerticalScrollBarVisibility   = 'Auto'
                    HorizontalScrollBarVisibility = 'Auto'>
                    <TextBlock
                        Name       = 'pUpdateUserDataOut'
                        FontFamily = 'Consolas'/>
                </ScrollViewer>
            </DockPanel>
            <DockPanel
                Name       = 'pDuplicateAssets'
                Dock       = 'Top'
                Visibility = 'Collapsed'>
                <DockPanel
                    Name = 'pDuplicateSelectSearch'
                    Dock = 'Top'>
                    <StackPanel
                        Name        = 'pDuplicateTypeSelect'
                        Orientation = 'Vertical'>
                        <Label>Select duplicate type</Label>
                        <RadioButton
                            GroupName = 'rbgDuplicateTypeSelect'
                            Name      = 'rbDupTypeSelName'
                            IsChecked = 'true'
                            Content   = '_Name'/>
                        <RadioButton
                            GroupName = 'rbgDuplicateTypeSelect'
                            Name      = 'rbDupTypeSelSerial'
                            Content   = '_Serial Number'/>
                        <RadioButton
                            GroupName = 'rbgDuplicateTypeSelect'
                            Name      = 'rbDupTypeSelMAC'
                            Content   = '_MAC Address'/>
                    </StackPanel>
                    <Button
                        Name      = 'bDuplicateAssetSearch'
                        Padding   = '5,2'
                        IsDefault = 'True'
                        Content   = '_Search'
                        VerticalAlignment   = 'Bottom'
                        HorizontalAlignment = 'Left'/>
                </DockPanel>
                <DockPanel
                    Name = 'pDuplicateContent'
                    Dock = 'Top'>
                    <DockPanel Dock = 'Top'>
                        <Label
                            Content = 'Commit all changes'
                            VerticalAlignment = 'Top'/>
                        <Button
                            Name    = 'bDuplicateAssetCommit'
                            Padding = '5,2'
                            Content = 'C_ommit'
                            VerticalAlignment   = 'Top'
                            HorizontalAlignment = 'Left'/>
                    </DockPanel>
                    <DockPanel
                        Name = 'pAssetsCount'
                        Dock = 'Top'>
                        <Label Name = 'lAssetsCount'/>
                    </DockPanel>
                    <StackPanel
                        Name           = 'pDuplicateCompare'
                        Orientation    = 'Vertical'
                        DockPanel.Dock = 'Top'>
                        <Label>
                            <TextBlock>
                                Select asset to keep.<LineBreak/>The other will be marked as a duplicate.<LineBreak/>Click the Undo button to undo the previous selection.<LineBreak/>Click the Commit button to commit all changes.
                            </TextBlock>
                        </Label>
                        <RadioButton
                            GroupName = 'rbgDuplicate'
                            Name      = 'rbDupAssetLeft'
                            Content   = '_Left'/>
                        <RadioButton
                            GroupName = 'rbgDuplicate'
                            Name      = 'rbDupAssetRight'
                            Content   = '_Right'/>
                        <RadioButton
                            GroupName = 'rbgDuplicate'
                            Name      = 'rbDupAssetBoth'
                            Content   = '_Both'/>
                        <RadioButton
                            GroupName = 'rbgDuplicate'
                            Name      = 'rbDupAssetNeither'
                            IsChecked = 'true'
                            Content   = '_Neither'/>
                        <DockPanel>
                            <Button
                                Name                = 'bDuplicateAssetSelect'
                                Padding             = '5,2'
                                HorizontalAlignment = 'Left'
                                Content             = '_Select'/>
                            <Button
                                Name                = 'bDuplicateAssetUndo'
                                Padding             = '5,2'
                                HorizontalAlignment = 'Left'
                                Visibility          = 'Hidden'
                                Content             = '_Undo'/>
                        </DockPanel>
                    </StackPanel>
                    <DockPanel
                        Name = 'pDuplicateViewer'>
                        <DockPanel
                            Name = 'pDuplicateLeft'
                            Dock = 'Left'>
                            <DockPanel Dock = 'Top'>
                                <Label
                                    Name                = 'lDuplicateLeft'
                                    HorizontalAlignment = 'Center'/>
                            </DockPanel>
                            <DockPanel Dock = 'Top'>
                                <Border
                                    Name        = 'bdDuplicateLeft'
                                    BorderBrush = 'Silver'>
                                    <ScrollViewer
                                        VerticalScrollBarVisibility = 'Auto'>
                                        <TextBlock
                                            Name         = 'tbDuplicateLeft'
                                            FontFamily   = 'Consolas'
                                            TextWrapping = 'Wrap'/>
                                    </ScrollViewer>
                                </Border>
                            </DockPanel>
                        </DockPanel>
                        <DockPanel
                            Name = 'pDuplicateRight'
                            Dock = 'Right'>
                            <DockPanel Dock = 'Top'>
                                <Label
                                    Name                = 'lDuplicateRight'
                                    HorizontalAlignment = 'Center'/>
                            </DockPanel>
                            <DockPanel Dock = 'Top'>
                                <Border
                                    Name        = 'bdDuplicateRight'
                                    BorderBrush = 'Silver'>
                                    <ScrollViewer
                                        VerticalScrollBarVisibility = 'Auto'>
                                        <RichTextBox
                                            Name         = 'tbDuplicateRight'
                                            FontFamily   = 'Consolas'/>
                                    </ScrollViewer>
                                </Border>
                            </DockPanel>
                        </DockPanel>
                    </DockPanel>
                </DockPanel>
            </DockPanel>
            <DockPanel
                Name = 'pCommandGUI'
                Dock = 'Top'
                Visibility = 'Collapsed'>
                <DockPanel Dock = 'Top'>
                    <ComboBox Name = 'cmbCommandGUI'>
                    </ComboBox>
                    <Button
                        Name      = 'bCommandGUIHelp'
                        Padding   = '5,2'
                        Margin    = '5,0'
                        IsDefault = 'True'
                        Content   = '_Help'
                        HorizontalAlignment = 'Left'/>
                    <Button
                        Name      = 'bCommandGUIExecute'
                        Padding   = '5,2'
                        Margin    = '5,0'
                        IsDefault = 'True'
                        Content   = 'E_xecute'
                        HorizontalAlignment = 'Left'/>
                </DockPanel>
                <DockPanel Dock = 'Top'>
                <TextBox
                    Name            = 'tbCommandGUICommand'
                    Background      = 'Transparent'
                    BorderThickness = '0'
                    Text            = '{Binding Text, Mode=OneWay}'
                    IsReadOnly      = 'True'/>
                </DockPanel>
                <DockPanel Name = 'pCommandGUIOut'>
                    <ScrollViewer
                        VerticalScrollBarVisibility   = 'Auto'
                        HorizontalScrollBarVisibility = 'Auto'>
                        <TextBox
                            Name            = 'tbCommandGUIOut'
                            FontFamily      = 'Consolas'
                            Background      = 'Transparent'
                            BorderThickness = '0'
                            Text            = '{Binding Text, Mode=OneWay}'
                            IsReadOnly      = 'True'/>
                    </ScrollViewer>
                </DockPanel>
            </DockPanel>
        </DockPanel>
    </Window>
"@

    # Error if GUI is unsupported
    if (-not $ModuleGUI)
    {
        throw 'Use of the GUI is not supported on this platform.'
    }
    #Set up WPF form
    Add-Type -AssemblyName PresentationFramework
    $XamlReader = (New-Object System.Xml.XmlNodeReader $Xaml)
    $TDGUI = [System.Windows.Markup.XamlReader]::Load($XamlReader)

    # Set up variables
    $DuplicateStatusID = (Get-TDAssetStatus -Authentication $TDAuthentication -Environment $WorkingEnvironment | Where-Object Name -eq "Duplicate Asset").ID
    $script:Assets = New-Object -TypeName psobject
    [int]$script:AssetCountIndex = 0
    $script:AssetGroup = New-Object -TypeName psobject
    [int]$script:AssetIndexLeftWindow  = 0
    [int]$script:AssetIndexRightWindow = 0
    $DuplicateAssetStack = New-Object -TypeName System.Collections.Stack
    $CommandList = (Get-Module TeamDynamix | Select-Object -ExpandProperty ExportedCommands).Keys | Sort-Object @{Expression={$_.Substring($_.IndexOf('-')+1)}}

    # Create variables for each of the named controls
    $xaml.SelectNodes('//*[@Name]') | foreach-object {Set-Variable -Name ($_.Name) -Value $TDGUI.FindName($_.Name)}

    # Populate controls

    # Event handlers
    $bCommandGUI.add_Click(
        {
            $pCommandGUI.Visibility      = 'Visible'
            $pOSUDir.Visibility          = 'Collapsed'
            $pUpdateUser.Visibility      = 'Collapsed'
            $pDuplicateAssets.Visibility = 'Collapsed'
            $cmbCommandGUI.ItemsSource   = $CommandList
            $cmbCommandGUI.SelectedItem  = 'Get-TDAsset'
            $cmbCommandGUI.Focus()
        }
    )
    $bOSUDir.add_Click(
        {
            $pCommandGUI.Visibility      = 'Collapsed'
            $pOSUDir.Visibility          = 'Visible'
            $pUpdateUser.Visibility      = 'Collapsed'
            $pDuplicateAssets.Visibility = 'Collapsed'
            $tbOSUDirUsername.Focus()
        }
    )
    $bUpdateUser.add_Click(
        {
            $pCommandGUI.Visibility      = 'Collapsed'
            $pOSUDir.Visibility          = 'Collapsed'
            $pUpdateUser.Visibility      = 'Visible'
            $pDuplicateAssets.Visibility = 'Collapsed'
            $tbUpdateUserUsername.Focus()
        }
    )

    $bDuplicates.add_Click(
        {
            $pCommandGUI.Visibility            = 'Collapsed'
            $pOSUDir.Visibility                = 'Collapsed'
            $pUpdateUser.Visibility            = 'Collapsed'
            $pDuplicateAssets.Visibility       = 'Visible'
            $pDuplicateSelectSearch.Visibility = 'Visible'
            $pDuplicateContent.Visibility      = 'Collapsed'
        }
    )

    $bAssetConsistency.add_Click(
        {
            $pCommandGUI.Visibility      = 'Collapsed'
            $pOSUDir.Visibility          = 'Collapsed'
            $pUpdateUser.Visibility      = 'Collapsed'
            $pDuplicateAssets.Visibility = 'Collapsed'
        }
    )

    $bGroups.add_Click(
        {
            $pOSUDir.Visibility          = 'Collapsed'
            $pUpdateUser.Visibility      = 'Collapsed'
            $pDuplicateAssets.Visibility = 'Collapsed'
        }
    )

    $bCommandGUIHelp.add_Click(
        {
            CommandGUIHelp
        }
    )

    $bCommandGUIExecute.add_Click(
        {
            CommandGUI
        }
    )

    $bOSUDirSearch.add_Click(
        {
            OSUDir
        }
    )

    $bUpdateUserSearch.add_Click(
        {
            UpdateUserSearch
        }
    )
    $bDuplicateAssetSearch.add_Click(
        {
            DuplicateAssetSearch
        }
    )

    $bDuplicateAssetSelect.add_Click(
        {
            DuplicateAssetSelect
        }
    )

    $bDuplicateAssetCommit.add_Click(
        {
            DuplicateAssetCommit
        }
    )

    $bDuplicateAssetUndo.add_Click(
        {
            DuplicateAssetUndo
        }
    )

    $rbDupAssetLeft.add_Checked(
        {
            $lDuplicateLeft.Content  = 'Keep'
            $lDuplicateRight.Content = ''
            $bdDuplicateLeft.BorderThickness = '2'
            $bdDuplicateRight.BorderThickness = '0'
        }
    )

    $rbDupAssetRight.add_Checked(
        {
            $lDuplicateLeft.Content  = ''
            $lDuplicateRight.Content = 'Keep'
            $bdDuplicateLeft.BorderThickness = '0'
            $bdDuplicateRight.BorderThickness = '2'
        }
    )

    $rbDupAssetBoth.add_Checked(
        {
            $lDuplicateLeft.Content  = 'Keep'
            $lDuplicateRight.Content = 'Keep'
            $bdDuplicateLeft.BorderThickness = '2'
            $bdDuplicateRight.BorderThickness = '2'
        }
    )

    $rbDupAssetNeither.add_Checked(
        {
            $lDuplicateLeft.Content  = ''
            $lDuplicateRight.Content = ''
            $bdDuplicateLeft.BorderThickness = '0'
            $bdDuplicateRight.BorderThickness = '0'
        }
    )

    $wMain.add_SizeChanged(
        {
            WindowResize
        }
    )

    function CommandGUIHelp
    {
        $bCommandGUIHelp.IsEnabled = $false
        $tbCommandGUICommand.Text = ''
        $Return = Get-Help -Detailed $cmbCommandGUI.SelectedItem
        $tbCommandGUIOut.Text = ($Return | Out-String)
        $bCommandGUIHelp.IsEnabled = $true
    }
    function CommandGUI
    {
        $bCommandGUIExecute.IsEnabled = $false
        $CommandString = Show-Command $cmbCommandGUI.SelectedItem -PassThru
        if ($CommandString)
        {
            $tbCommandGUICommand.Text = $CommandString
            $Return = Invoke-Expression $CommandString
            $tbCommandGUIOut.Text = ($Return | Out-String)
        }
        else
        {
            $tbCommandGUICommand.Text = ''
            $tbCommandGUIOut.Text       = ''
        }
        $bCommandGUIExecute.IsEnabled = $true
    }
    function OSUDir
    {
        $bOSUDirSearch.IsEnabled = $false
        $Return = Get-OSUDirectoryListing $tbOSUDirUsername.Text -Properties *
        $tbOSUDirOut.Text = ($Return | Out-String)
        $bOSUDirSearch.IsEnabled = $true
    }
    function UpdateUserSearch
    {
        if ($tbUpdateUserUsername.text -match '^.*\.\d+@osu\.edu$')
        {
            $bUpdateUserSearch.IsEnabled = $false
            $Return = Get-TDUser -Username $tbUpdateUserUsername.Text -Authentication $TDAuthentication -Environment $WorkingEnvironment
            $pUpdateUserDataOut.Text = ($Return | Out-String)
            $bUpdateUserSearch.IsEnabled = $true
        }
        else
        {
            $pUpdateUserDataOut.Text = 'Please use full "name.n@osu.edu"'
        }
    }
    function DuplicateAssetSearch
    {
        $pDuplicateSelectSearch.Visibility = 'Collapsed'
        $pDuplicateContent.Visibility = 'Visible'
        $pDuplicateLeft.Width  = $TDGUI.Width / 2
        $pDuplicateRight.Width = $TDGUI.Width / 2
        $bDuplicateAssetSelect.isDefault   = $true
        $script:Assets = Get-TDAssetConsistency -NameDuplicate -SerialNumberDuplicate -MACDuplicate -Authentication $TDAuthentication -Environment $WorkingEnvironment
        if ($rbDupTypeSelName.IsChecked)
        {
            $script:DuplicateSearchType = 'DuplicateName'
        }
        elseif ($rbDupTypeSelSerial.IsChecked)
        {
            $script:DuplicateSearchType = 'DuplicateSN'
        }
        elseif ($rbDupTypeSelMAC.IsChecked)
        {
            $script:DuplicateSearchType = 'DuplicateMAC'
        }
        if ($Assets)
        {
            # Determine length of longest attribute name for padding - use first entry in first group of assets to get names
            $script:AttributeNames = $Assets.$DuplicateSearchType[0].Group[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
            $script:MaxLengthAttributeNames = ($AttributeNames | Measure-Object -Maximum -Property Length).Maximum
            # Start index at zero (first step will advance it to 1, for one-based counting)
            $script:AssetCountIndex = 0
            # Advance to first asset group
            DuplicateGroupAdvance
        }
    }

    function DuplicateAssetSelect
    {
        # Determine the name of the radio button currently selected
        $KeepAssetRB = ($pDuplicateCompare.Children | Where-Object {$_ -is [system.windows.controls.radiobutton] -and $_.IsChecked}).Name
        switch ($KeepAssetRB)
        {
            rbDupAssetLeft
            {
                RecordAssetDuplicateStatus($Assets.$DuplicateSearchType[$AssetCountIndex - 1].Group[$AssetIndexRightWindow])
                DuplicateAssetAdvance('Left')
            }
            rbDupAssetRight
            {
                RecordAssetDuplicateStatus($Assets.$DuplicateSearchType[$AssetCountIndex - 1].Group[$AssetIndexLeftWindow])
                DuplicateAssetAdvance('Right')
            }
            rbDupAssetBoth
            {
                RecordAssetDuplicateStatus
                DuplicateAssetAdvance('Both')
            }
            rbDupAssetNeither
            {
                RecordAssetDuplicateStatus(@($Assets.$DuplicateSearchType[$AssetCountIndex - 1].Group[$AssetIndexLeftWindow], $Assets.$DuplicateSearchType[$AssetCountIndex - 1].Group[$AssetIndexRightWindow]))
                DuplicateAssetAdvance('Left')
                DuplicateAssetAdvance('Right')
            }
        }
    }

    function DuplicateAssetAdvance ([string]$Side)
    {
        # Note that Side is the side being kept, Opposite is the duplicate
        switch ($Side)
        {
            Left  {$Opposite = 'Right'}
            Right {$Opposite = 'Left' }
        }
        if ($Side -in ('Left','Right'))
        {
            # Check if Group is exhausted
            if ([math]::Max($script:AssetIndexLeftWindow,$script:AssetIndexRightWindow) -eq $Assets.$DuplicateSearchType[$script:AssetCountIndex - 1].Group.Count - 1)
            {
                # Group is exhausted
                # Check to see if there are more duplicates
                if ($script:AssetCountIndex -eq $Assets.$DuplicateSearchType.Count)
                {
                    # No more duplicates
                    $pDuplicateCompare.Visibility = 'Collapsed'
                }
                else
                {
                    # Move to next group of duplicates
                    DuplicateGroupAdvance
                }
            }
            # More duplicates in group
            else
            {
                # Move to next duplicate within current Group, put it in the window not kept (opposite)
                Set-Variable "AssetIndex$($Opposite)Window" -Value ([math]::Max($AssetIndexLeftWindow,$AssetIndexRightWindow) + 1) -Scope script
                DisplayDuplicateGroup -AssetGroupNumber ($AssetCountIndex - 1) -AssetIndexLeftWindowNumber $AssetIndexLeftWindow -AssetIndexRightWindowNumber $AssetIndexRightWindow
            }
        }
        # Keep both
        else
        {
            $RemainingItems = $Assets.$DuplicateSearchType[$script:AssetCountIndex - 1].Group.Count - [math]::Max($script:AssetIndexLeftWindow,$script:AssetIndexRightWindow) - 1 # Windows are zero-based, Count is one-based
            if ($RemainingItems -eq 0)
            {
                # No items remain, go to next group
                DuplicateGroupAdvance
            }
            else
            {
                # See if number of remaining duplicates is odd or even
                #  If odd, show one of the kept items
                #  If even, show two new items
                if (($RemainingItems % 2) -eq 1)
                {
                    # Odd - replace item in right window
                    $script:AssetIndexRightWindow = ([math]::Max($AssetIndexLeftWindow,$AssetIndexRightWindow) + 1)
                    DisplayDuplicateGroup -AssetGroupNumber ($AssetCountIndex - 1) -AssetIndexLeftWindowNumber $AssetIndexLeftWindow -AssetIndexRightWindowNumber $AssetIndexRightWindow
                }
                else
                {
                    # Even - replace items in both windows
                    $script:AssetIndexLeftWindow  = ([math]::Max($AssetIndexLeftWindow,$AssetIndexRightWindow) + 1)
                    $script:AssetIndexRightWindow = ([math]::Max($AssetIndexLeftWindow,$AssetIndexRightWindow) + 1)
                    DisplayDuplicateGroup -AssetGroupNumber ($AssetCountIndex - 1) -AssetIndexLeftWindowNumber $AssetIndexLeftWindow -AssetIndexRightWindowNumber $AssetIndexRightWindow
                }
            }
        }
    }

    function DuplicateGroupAdvance
    {
        # Move to next group of duplicates
        $script:AssetCountIndex++
        DisplayDuplicateGroup -AssetGroupNumber ($AssetCountIndex - 1) -AssetIndexLeftWindowNumber 0 -AssetIndexRightWindowNumber 1
    }

    function DisplayDuplicateGroup (
        [int]$AssetGroupNumber,
        [int]$AssetIndexLeftWindowNumber,
        [int]$AssetIndexRightWindowNumber)

    {
        # Set Group number and AssetIndexes
        $script:AssetGroup = $Assets.$DuplicateSearchType[$AssetGroupNumber].Group
        $script:AssetIndexLeftWindow  = $AssetIndexLeftWindowNumber
        $script:AssetIndexRightWindow = $AssetIndexRightWindowNumber
        # Clear contents of the textboxes
        $tbDuplicateLeft.Text  = ''
        $tbDuplicateRight.Text = ''
        foreach ($AttributeName in $script:AttributeNames)
        {
            # Compare values of each attribute between the windows
            if ($script:AssetGroup[$script:AssetIndexLeftWindow].$AttributeName -eq $script:AssetGroup[$script:AssetIndexRightWindow].$AttributeName)
            {
                # Black text - same in both windows
                # Left side
                $tbDuplicateLeft.Inlines.Add("$($AttributeName.PadRight($MaxLengthAttributeNames)): $($script:AssetGroup[$script:AssetIndexLeftWindow].$AttributeName)")
                $tbDuplicateLeft.Inlines.Add((New-Object -TypeName System.Windows.Documents.LineBreak))
                # Right side
                $tbDuplicateRight.Inlines.Add("$($AttributeName.PadRight($MaxLengthAttributeNames)): $($script:AssetGroup[$script:AssetIndexRightWindow].$AttributeName)")
                $tbDuplicateRight.Inlines.Add((New-Object -TypeName System.Windows.Documents.LineBreak))
            }
            else
            {
                # Red text - different between windows
                # Left side
                $RunRed = New-Object -TypeName System.Windows.Documents.Run
                $RunRed.Foreground = 'Red'
                $RunRed.Text = "$($AttributeName.PadRight($MaxLengthAttributeNames)): $($script:AssetGroup[$script:AssetIndexLeftWindow].$AttributeName)"
                $tbDuplicateLeft.Inlines.Add($RunRed)
                $tbDuplicateLeft.Inlines.Add((New-Object -TypeName System.Windows.Documents.LineBreak))
                # Right side
                $RunRed = New-Object -TypeName System.Windows.Documents.Run
                $RunRed.Foreground = 'Red'
                $RunRed.Text = "$($AttributeName.PadRight($MaxLengthAttributeNames)): $($script:AssetGroup[$script:AssetIndexRightWindow].$AttributeName)"
                $tbDuplicateRight.Inlines.Add($RunRed)
                $tbDuplicateRight.Inlines.Add((New-Object -TypeName System.Windows.Documents.LineBreak))
            }
        }
        $lAssetsCount.Content = "$script:AssetCountIndex of $($Assets.$DuplicateSearchType.Count)"
    }

    function RecordAssetDuplicateStatus ([psobject[]]$Asset)
    {
        # Use a stack with which items were in which windows, and what command would be run
        $DuplicateInfo = [psobject]@{
                            AssetCountIndex       = $AssetCountIndex
                            AssetIndexLeftWindow  = $AssetIndexLeftWindow
                            AssetIndexRightWindow = $AssetIndexRightWindow
                            AssetID               = $Asset.AssetID}
        $DuplicateAssetStack.Push($DuplicateInfo)
        # Ensure Undo button is available
        $bDuplicateAssetUndo.Visibility = 'Visible'
    }

    function DuplicateAssetCommit
    {
        # Commit changes to duplicate assets
        # To complete the mark for delete, run the commands from the stack
        while ($DuplicateAssetStack.Count -ne 0)
        {
            $MarkAsDuplicate = $DuplicateAssetStack.Pop()
            if (-not [string]::IsNullOrEmpty($MarkAsDuplicate.AssetID))
            {
                $MarkAsDuplicate | ForEach-Object {Set-TDAsset -ID $_.AssetID -StatusID $DuplicateStatusID -Authentication $TDAuthentication -Environment $WorkingEnvironment -Confirm:$false}
            }
        }
        # Nothing left to undo - hide Undo button
        $bDuplicateAssetUndo.Visibility = 'Hidden'
    }

    function DuplicateAssetUndo
    {
        # Undo previous duplicate asset selection
        if ($DuplicateAssetStack.Count -ne 0)
        {
            # Pop top of the stack, removing previous choice
            $PreviousView = $DuplicateAssetStack.Pop()
            # Display previous options
            DisplayDuplicateGroup -AssetGroupNumber ($PreviousView.AssetCountIndex - 1) -AssetIndexLeftWindowNumber $PreviousView.AssetIndexLeftWindow -AssetIndexRightWindowNumber $PreviousView.AssetIndexRightWindow
        }
        if  ($DuplicateAssetStack.Count -eq 0)
        {
            # Hide Undo button if there's nothing to undo
            $bDuplicateAssetUndo.Visibility = 'Hidden'
        }
    }

    function WindowResize
    {
        if ($pDuplicateCompare.Visibility -eq 'Visible')
        {
            $pDuplicateLeft.Width  = $pDuplicateViewer.ActualWidth / 2
            $pDuplicateRight.Width = $pDuplicateViewer.ActualWidth / 2
        }
    }

    # Launch the window
    $TDGUI.ShowDialog() | Out-Null
}