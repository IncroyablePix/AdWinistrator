Function Add-LocalGroupNTUser() {
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string] $UserName,
		[Parameter(Mandatory=$true, Position=1)]
		[string] $GroupName
	)
	
	$group = $null
	try {
		$group = Get-LocalGroup "$($GroupName)" -ErrorAction Stop
	}
	catch {
		$group = New-LocalGroup -Name "$($GroupName)"
	}
	
	Add-LocalGroupMember -Group "$($GroupName)" -Member $UserName
	
	return $group
}

Function Add-NTLocalUser() {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FullName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Name,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $Password,
        [Parameter(Mandatory=$false, Position=3)]
        [string] $Directory,
        [Parameter(Mandatory=$false, Position=4)]
        [string] $ProfileName
    )

    if(!($Directory)) {
        $Directory = "C:\Users"
    }

    if(!($ProfileName)) {
        $ProfileName = "ntprof"
    }

    # Creating directories names
    [string] $home_dir = "$($Directory)\$($Name)"
    [string] $profile_dir = "$($home_dir)\$($ProfileName)"
    
    # Creating local user
    $user = New-LocalUser -Name "$($Name)" -FullName "$($FullName)" -AccountNeverExpires -PasswordNeverExpires -Password (ConvertTo-SecureString -AsPlainText $Password -Force) -UserMayNotChangePassword

	# Users group assignement
	Add-LocalGroupNTUser -User "$($Name)" -GroupName "Users"

    # ADSI
    $userADSI = [ADSI] "WinNT://$($env:computername)/$($Name)"
    $userADSI.Profile = $profile_dir
    $userADSI.HomeDirectory = $home_dir
    $userADSI.SetInfo()

    # Creating directories
    New-Item "$($home_dir)" -type directory # HomeDir => 
    New-Item "$($profile_dir).V6" -type directory # Profile => Where all the data is stored

    # Giving Full control to newly created user
    Invoke-Expression -Command:"icacls $($profile_dir).V6 /grant $($Name):'(OI)(CI)(F)'"
    Invoke-Expression -Command:"icacls $($home_dir) /grant $($Name):'(OI)(CI)(F)'"
    # $result = &"icacls" "$($profile_dir).V6" "/grant" "$($Name):(OI)(CI)(F)"
    # $result = &"icacls" "$($home_dir)" "/grant" "$($Name):(F)"

    return $user
}

Export-ModuleMember -Function Add-NTLocalUser
Export-ModuleMember -Function Add-LocalGroupNTUser