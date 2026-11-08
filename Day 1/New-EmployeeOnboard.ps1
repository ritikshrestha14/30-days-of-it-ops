Write-Host "`n=== Bulk Identity Onboarding ===" -ForegroundColor Yellow

$users = Invoke-RestMethod -Uri "https://jsonplaceholder.typicode.com/users" | Select-Object -First 10

foreach ($person in $users) {
    
    # 1. Regex Cleanup: Strip titles (Mrs., Mr., Dr.) from the beginning of the string
    $cleanFullName = ($person.name -replace '^(Mr\.|Mrs\.|Ms\.|Dr\.)\s+', '').Trim()
    
    # 2. Split the cleaned name
    $nameParts = $cleanFullName -split '\s+'
    
    # 3. Grab exactly the first and second words (ignoring suffixes like "V")
    $rawFirst = $nameParts[0]
    $rawLast  = if ($nameParts.Count -gt 1) { $nameParts[-1] } else { "user" }
    
    # 4. Strip out any weird punctuation and lowercase everything
    $firstClean   = $rawFirst.ToLower() -replace '[^a-z]', ''
    $lastClean    = $rawLast.ToLower()  -replace '[^a-z]', ''
    $firstInitial = $firstClean.Substring(0, 1)
    
    # 5. Build the final username
    $username = "$firstInitial$lastClean"

    [PSCustomObject]@{
        FullName   = $person.name
        Username   = $username
        CorpEmail  = "$username@company.com"
        Department = $person.company.name
    }
}