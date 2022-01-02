Function Add-OrganizationalUnit() {
    Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string] $OuName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $DC,
        [Parameter(Mandatory=$false, Position=2)]
        [string] $OU
    )
    
	
    $splits = $DC.Split(".")
    $dcs = ($splits | % { "DC=" + $_}) -join ","
    $path = ""
    if(!($OU)) {
        $path = "$($dcs)"
    }
    else {
        $path = "OU=$($OU),$($dcs)"
    }

    New-ADOrganizationalUnit -Name $OuName -Path $path

    #$cmd = "dsadd.exe ou `"OU=$($OuName),$($dcs)`""
    #Write-Output $cmd;

    #Invoke-Expression -Command:"dnscmd $($ServerName) /RecordAdd $($reversed) $($last) PTR $($DomainName)"
}

Function Add-GlobalUser() {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FirstName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $LastName,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $Password,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $Name,
        [Parameter(Mandatory=$true, Position=4)]
        [string] $DC,
        [Parameter(Mandatory=$true, Position=5)]
        [string] $OU,
        [Parameter(Mandatory=$true, Position=6)]
        [string] $SamName,
        [Parameter(Mandatory=$false, Position=7)]
        [string] $Directory,
        [Parameter(Mandatory=$false, Position=8)]
        [string] $ProfileName,
        [Parameter(Mandatory=$false, Position=9)]
        [string] $LocalDirectory
    )

    if(!($Directory)) {
        $Directory = "C:\Users"
    }

    if(!($LocalDirectory)) {
        $LocalDirectory = $Directory
    }

    if(!($ProfileName)) {
        $ProfileName = "ntprof"
    }

    $full_name = "$FirstName $LastName"

    $splits = $DC.Split(".")
    $dcs = ($splits | % { "DC=" + $_}) -join ","
    $path = "OU=$($OU),$($dcs)"

    Write-Output -path
    #New-ADUser -Name $full_name -AccountPassword (ConvertTo-SecureString -AsPlainText $Password -Force) -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -SamAccountName $SamAccount -UserPrincipalName "$($SamName)@$($DC)" -Path $path -GivenName $FirstName -Surname $LastName -DisplayName $full_name
    $user = New-ADUser -Name "$($FirstName) $($LastName)" -AccountPassword (ConvertTo-SecureString -AsPlainText "$($Password)" -Force) `
        -Enabled $true -PasswordNeverExpires $true -CannotChangePassword $true -SamAccountName "$($SamName)" -UserPrincipalName "$($Name)@$($DC)" `
        -Path $path -GivenName "$($FirstName) $($LastName)" -Surname "$($LastName)" -DisplayName "$($FirstName) $($LastName)"

    # Creating directories names
    [string] $home_dir = "$($Directory)\$($Name)"
    [string] $local_home_dir = "$($LocalDirectory)\$($Name)"
    [string] $profile_dir = "$($home_dir)\$($ProfileName)"
    [string] $local_profile_dir = "$($local_home_dir)\$($ProfileName)"

    # ADSI
    $userADSI = [ADSI] "WinNT://$($env:computername)/$($Name)"
    $userADSI.Profile = $local_profile_dir
    $userADSI.HomeDirectory = $home_dir
    $userADSI.SetInfo()

    #
    New-Item -Path "$($local_home_dir)" -ItemType Directory

    # Remove Inheritance from user's folder and remove User group permissions
    &"icacls" "$($local_home_dir)" "/inheritance:d"
    &"icacls" "$($local_home_dir)" "/remove" "Users"

    #
    New-Item -Path "$($local_profile_dir).V6" -ItemType Directory

    # Giving full access to user directories
    &"icacls" "$($local_profile_dir).V6" "/grant" "$($Name):(OI)(CI)(F)"
    &"icacls" "$($local_home_dir)" "/grant" "$($Name):(F)"
}

Function Add-GlobalGroupUser() {
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string] $GivenName,
		[Parameter(Mandatory=$true, Position=1)]
		[string] $GroupName,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $OU,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $DC,
        [Parameter(Mandatory=$true, Position=4)]
        [string] $SamName,
        [Parameter(Mandatory=$false, Position=5)]
        [string] $OUGroup
	)

    if(!($OUGroup)) {
        $OUGroup = $OU
    }
	
	$group = $null
	try {
		$group = Get-ADGroup "$($GroupName)" -ErrorAction Stop
	}
	catch {
		$group = Add-GlobalGroup -GroupName $GroupName -OU $OU -DC $DC -SamName $SamName
	}

    $splits = $DC.Split(".")
    $dcs = ($splits | % { "DC=" + $_}) -join ","
    $path = "CN=$($GroupName),OU=$($OUGroup),$($dcs)"

    $member = "CN=$($GivenName),OU=$($OU),$($dcs)"
    Write-Output $path $member
    
	Add-ADGroupMember $path -Members $member
}

Function Add-GlobalGroup() {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $GroupName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $OU,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $DC,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $SamName
    )
    
    $splits = $DC.Split(".")
    $dcs = ($splits | % { "DC=" + $_}) -join ","
    $path = "OU=$($OU),$($dcs)"

    Write-Output $path
    
    $new_group = New-ADGroup -Name $GroupName -SamAccountName $SamName -GroupCategory Security -GroupScope Global -Path $path


    return $new_group
}

Function Add-Computer() {
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string] $ComputerName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $SamName,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $OU,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $DC
    )

    $splits = $DC.Split(".")
    $dcs = ($splits | % { "DC=" + $_}) -join ","
    $path = "OU=$($OU),$($dcs)"

    New-ADComputer -Name $ComputerName -SAMAccountName $SamName -Path $path
}

Export-ModuleMember -Function Add-OrganizationalUnit
Export-ModuleMember -Function Add-GlobalUser
Export-ModuleMember -Function Add-GlobalGroupUser
Export-ModuleMember -Function Add-GlobalGroup
Export-ModuleMember -Function Add-Computer
