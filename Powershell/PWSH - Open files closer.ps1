$keyword = Read-Host "Enter keyword to search for"

$openFiles = Get-SmbOpenFile | Where-Object {$_.Path -like "*$keyword*"}

if ($openFiles) {
    Write-Host "Open Files:"
    $openFiles | Format-Table -AutoSize -Property Path, FileId, ShareRelativePath
} else {
    Write-Host "No open files found matching the keyword '$keyword'"
}

$lastSearch = $openFiles

if ($openFiles) {
    do {
        $fileId = Read-Host "Enter the file ID of the file you want to close, or type 'q' to quit"
        
        if ($fileId -ne 'q') {
            $fileToClose = $lastSearch | Where-Object {$_.FileId -eq $fileId}
            
            if ($fileToClose) {
                Write-Host "Closing file $($fileToClose.Path) with file ID $($fileToClose.FileId)"
                Close-SmbOpenFile -FileId $fileId -Force
                $lastSearch = $lastSearch | Where-Object {$_.FileId -ne $fileId}
                Write-Host "Open Files:"
                $lastSearch | Format-Table -AutoSize -Property Path, FileId, ShareRelativePath
            } else {
                Write-Host "No open files found with file ID '$fileId'"
            }
        }
    } while ($fileId -ne 'q')
} else {
    Write-Host "No open files found"
}

pause
