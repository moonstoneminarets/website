# Convert Jannah Journeys articles to MoonPress format
$sourceArticles = "d:\code\mm\content\articles\jannah-journeys"
$destArticles = "d:\code\mm\content-moonpress\jannah-journeys"

# Ensure destination exists
New-Item -ItemType Directory -Force -Path $destArticles | Out-Null

# Process each article markdown file
Get-ChildItem -Path $sourceArticles -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Replace |static| tokens with proper paths
    $content = $content -replace '\|static\|/', '/'
    
    # Convert frontmatter format
    $content = $content -replace "^Title:", "title:"
    $content = $content -replace "^Date:", "datePublished:"
    
    # Add category and time to datePublished
    $content = $content -replace "datePublished: (\d{4}-\d{2}-\d{2})\s*$", "datePublished: `$1 10:00:00`ncategory: Jannah Journeys"
    $content = $content -replace "datePublished: (\d{4}-\d{2}-\d{2})\r?\n", "datePublished: `$1 10:00:00`ncategory: Jannah Journeys`n"
    
    # Convert to fenced YAML format
    if ($content -notmatch "^---") {
        $lines = $content -split "`r?`n"
        $metadataLines = @()
        $contentStart = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^\w+:") {
                $metadataLines += $lines[$i]
            } elseif ($lines[$i].Trim() -eq "") {
                continue
            } else {
                $contentStart = $i
                break
            }
        }
        
        if ($metadataLines.Count -gt 0) {
            $metadata = $metadataLines -join "`n"
            $body = $lines[$contentStart..($lines.Count - 1)] -join "`n"
            $content = "---`n$metadata`n---`n`n$body"
        }
    }
    
    # Write to destination
    $destPath = Join-Path $destArticles $_.Name
    Set-Content -Path $destPath -Value $content -NoNewline
    Write-Host "Converted: $($_.Name)"
}

Write-Host "`nJannah Journeys conversion complete!"
