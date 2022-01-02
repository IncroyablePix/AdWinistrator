Function Add-DNSSub() {
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string] $ServerName,
		[Parameter(Mandatory=$true, Position=1)]
		[string] $IP,
		[Parameter(Mandatory=$true, Position=2)]
		[string] $DomainName,
		[Parameter(Mandatory=$true, Position=3)]
		[string] $Subdomain
	)
	
	Invoke-Expression -Command:"dnscmd $($ServerName) /RecordAdd $($DomainName) $($Subdomain) A $($IP)"
}

Function Add-ReverseLookupIP() {
	Param (
		[Parameter(Mandatory=$true, Position=0)]
		[string] $ServerName,
		[Parameter(Mandatory=$true, Position=1)]
		[string] $IP,
		[Parameter(Mandatory=$true, Position=2)]
		[string] $DomainName
	)
	
    $splits = $IP.Split(".")
    $reversed = $splits[2] + "." + $splits[1] + "." + $splits[0] + ".in-addr.arpa"
	$last = $splits[3]
	
	Invoke-Expression -Command:"dnscmd $($ServerName) /RecordAdd $($reversed) $($last) PTR $($DomainName)"
}

Export-ModuleMember -Function Add-ReverseLookupIP
Export-ModuleMember -Function Add-DNSSub