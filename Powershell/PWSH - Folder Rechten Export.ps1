$folderpath = read-host -Prompt "Wat is het pad van de map die bekeken moet worden?"
$Foldercontent = Get-ChildItem -Directory -Path $folderpath 
$Report = @()
Foreach ($Folder in $Foldercontent) {
    $Acl = Get-Acl -Path $Folder.FullName
    foreach ($Access in $acl.Access.Where({ 
                $_.IdentityReference.Value -notlike "*admin*" -and $_.IdentityReference.Value -notlike "*test*" -and $_.IdentityReference.Value -notlike "*S-1*" -and $_.IdentityReference.Value -notlike "*system*" -and $_.IdentityReference.Value -notlike "*creator*" })) {
        $Properties = [ordered]@{'FolderName' = $Folder.FullName; 'ADGroup or User' = $Access.IdentityReference; 'Permissions' = $Access.FileSystemRights; 'Inherited' = $Access.IsInherited }
        $Report += New-Object -TypeName PSObject -Property $Properties
    }
}
$Report | Export-Csv -path "C:\Temp\FolderPermissionsDisk.csv"