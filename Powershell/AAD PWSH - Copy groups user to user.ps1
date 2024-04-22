# enter login name of the first user
$user1 = Read-host "Enter username to copy from: "

# enter login name of the second user
$user2  = Read-host "Enter username to copy to: " 

# Get ObjectId based on username of user to copy from and user to copy to
$user1Obj = Get-AzureADUser -ObjectID $user1
$user2Obj = Get-AzureADUser -ObjectID $user2


$membershipGroups = Get-AzureADUserMembership -ObjectId $user1Obj.ObjectId

Write-Host "\-- Groups available to copy from" $user1 to $user2 "--\" -ForegroundColor Green

foreach($group in $membershipGroups) {
Write-Host "[!] - Adding" $user2Obj.UserPrincipalName " to " $group.DisplayName "... " -ForegroundColor Green -nonewline
Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user2Obj.ObjectId
Write-Host "Done"
}