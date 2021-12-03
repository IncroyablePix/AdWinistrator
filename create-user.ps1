Function Create-User() {
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $FullName,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Name,
        [Parameter(Mandatory=$true, Position=2)]
        [string] $Password,
        [Parameter(Mandatory=$true, Position=3)]
        [string] $Directory
    )
    
    $user = New-LocalUser -AccountNeverExpires -PasswordNeverExpires 
    -FullName $FullName -name $Name
    -Password (ConvertTo-SecureString -AsPlainText $Password -Force)
    -UserMayNotChangePassword

    # Creating directories
    [string] $home_dir = "$($Directory)\$($Name)"
    [string] $profile_dir = "$($home_dir)\ntprof"

    New-Item $home_dir -type directory
    New-Item $profile_dir -type directory

    # Giving Full control to newly created user
    $result = &"icacls" $home_dir "/grant" "$($Name):(OI)(CI)(F)"
    $result = &"icacls" $profile_dir "/grant" "$($Name):(OI)(CI)(F)"

    # ADSI
    $userADSI = [ADSI] "WinNT://$env:computername/$($Name)"
    $userADSI.Profile = $profile_dir
    $userADSI.HomeDirectory = $home_dir
    $userADSI.SetInfo()

    return $user
}