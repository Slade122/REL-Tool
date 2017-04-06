
$inputXML = @"
<Window x:Class="WpfApplication1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApplication1"
        mc:Ignorable="d"
        Title="REL Tool - v0.1" Height="350" Width="700">
    <Grid HorizontalAlignment="Left" Width="701" Margin="-11,0,0,0">
        <Button x:Name="StartPerfmon" Content="Start Perfmon" HorizontalAlignment="Left" Margin="28,52,0,0" VerticalAlignment="Top" Width="100"/>
        <Button x:Name="StopPerfmon" Content="Stop Perfmon" HorizontalAlignment="Left" Margin="28,77,0,0" VerticalAlignment="Top" Width="100"/>
        <TextBox x:Name="ComputerNameInput" HorizontalAlignment="Left" Height="16" Margin="133,21,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="155" RenderTransformOrigin="2.086,-2.764"/>
        <TextBlock x:Name="ComputerName" HorizontalAlignment="Left" Margin="37,21,0,0" TextWrapping="Wrap" Text="Computer Name:" VerticalAlignment="Top"/>
        <RichTextBox x:Name="RichOutput" HorizontalAlignment="Left" Height="299" Margin="304,10,0,0" VerticalAlignment="Top" Width="387" IsEnabled="False" FontFamily="Consolas" FontSize="11" BorderBrush="#FF535353" BorderThickness="2">
            <FlowDocument>
                <Paragraph>
                    <Run Text="THE STUFF WITH THE THING"/>
                </Paragraph>
            </FlowDocument>
        </RichTextBox>
        <Button x:Name="Ping" Content="Ping" HorizontalAlignment="Left" Margin="145,52,0,0" VerticalAlignment="Top" Width="100"/>
        <Button x:Name="NSLOOKUP" Content="NSLOOKUP" HorizontalAlignment="Left" Margin="145,77,0,0" VerticalAlignment="Top" Width="100"/>
        <Button x:Name="WPR" Content="WPR" HorizontalAlignment="Left" Margin="28,102,0,0" VerticalAlignment="Top" Width="100"/>
    </Grid>
</Window>

"@
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
$WPFComputerNameInput.Text = $env:COMPUTERNAME
$WPFRichOutput.IsReadOnly = $true

#===========================================================================
# Actually make the objects work
#===========================================================================

#===========================================================================
# START PERFMON BUTTON
#===========================================================================

$WPFStartPerfmon.add_click({
[String]$computername = $WPFComputerNameInput.Text
$WPFRichOutput.AppendText("`nStarting Performance Log...")
Invoke-Command -ComputerName $computername -ScriptBlock {logman.exe create counter Perflog -f bincirc -v mmddhhmm -max 250 -c “\LogicalDisk(*)\*” “\Memory\*” “\Network Interface(*)\*” “\Paging File(*)\*” “\PhysicalDisk(*)\*” “\Process(*)\*” “\Redirector\*” “\Server\*” “\System\*” “\Thread(*)\*”   -si 00:00:02}
Invoke-Command -ComputerName $computername -ScriptBlock {logman.exe start Perflog}
[String]$logman = logman.exe query -s $computername
If ($LOGMAN.Contains("successfully") -eq $true)
	{
	$WPFRichOutput.AppendText("`nPerfmon Started Successfully!")
	$WPFRichOutput.ScrollToEnd()
	}
If ($LOGMAN.Contains("successfully") -eq $false)
	{
	$WPFRichOutput.AppendText("`nPerfmon Failed to Start!")
	$WPFRichOutput.ScrollToEnd()
	}

})

#===========================================================================
# STOP PERFMON BUTTON
#===========================================================================
 $WPFStopPerfmon.add_click({
[String]$computername = $WPFComputerNameInput.Text
$WPFRichOutput.AppendText("`nStopping Performance Log...")
Invoke-Command -ComputerName $computername -ScriptBlock {logman.exe stop Perflog}
[String]$logman = logman.exe query -s $computername
If ($LOGMAN.Contains("successfully") -eq $true)
	{
	$WPFRichOutput.AppendText("`nPerfmon Stopped Successfully!")
	$WPFRichOutput.ScrollToEnd()
	}
If ($LOGMAN.Contains("successfully") -eq $false)
	{
	$WPFRichOutput.AppendText("`nPerfmon Failed to Stop!")
	$WPFRichOutput.ScrollToEnd()
	}

})
#===========================================================================
# PING BUTTON
#===========================================================================
$WPFPing.Add_click({

[String]$computername = $WPFComputerNameInput.Text
$WPFRichOutput.AppendText("`nTesting Connection to remote machine...")
$pingtest = Ping.exe $computername
$WPFRichOutput.AppendText("`n$pingtest")

})


#===========================================================================
# NSLOOKUP BUTTON
#===========================================================================
$WPFNSLOOKUP.Add_click({

[String]$computername = $WPFComputerNameInput.Text
$WPFRichOutput.AppendText("`nPerforming Nameserver Lookup...")
$nslookup = Resolve-DnsName -Name $computername | select Name,IPAddress
$WPFRichOutput.AppendText("`n$nslookup")

})

#===========================================================================
# WINDOWS PERFORMANCE RECORDER BUTTON
#===========================================================================
$WPFWPR.Add_click({

[String]$computername = $WPFComputerNameInput.Text
$WPR = Test-Path "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\wpr.exe"
If ($WPR -eq $true)
{
$WPFRichOutput.AppendText("`nWPR is Installed!")
}
$WPR = Test-Path "C:\Program Files (x86)\Windows Kits\10\Windows Performance Toolkit\wpr.exe"
If ($WPR = $false)
{
$WPFRichOutput.AppendText("`nWPR not Installed!")
}

})


#===========================================================================
# Shows the form
#===========================================================================
$Form.ShowDialog() | out-null