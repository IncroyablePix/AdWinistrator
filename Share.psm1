# Créer un partage réseau SharedSocial et connecter les membres de la catégorie social à ce partage en utilisant un script batch (lecteur X:,accès en modification pour social, inaccessible pour les autres). Ajoutez une GPO Ordinateur « Configure Logon Script Delay » à 0 minute, sur les postes clients (VM Windows 10).

# En ce qui concerne les préférences, il faut aller dans User Configuration\Preferences\ Windows Settings\Drive Maps. Il convient alors d’ajouter un nouveau mappage en mentionnant, comme emplacement, un chemin réseau \\SERVEUR\Partage.

Function Add-SharedSpace() {
	Param(
		[Parameter(Mandatory=$true, Position=0)]
		[string] $Drive,
		[Parameter(Mandatory=$true, Position=1)]
		[string] $Path
	)
	
    Invoke-Expression -Command:"net use $($Drive): $($Path)"
}

Export-ModuleMember -Function Add-SharedSpace