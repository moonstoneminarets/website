# Convert Pelican content to MoonPress format
$sourceBooks = "d:\code\mm\content\books"
$destBooks = "d:\code\mm\content-moonpress\books"

# Ensure destination exists
New-Item -ItemType Directory -Force -Path $destBooks | Out-Null

# Process each book markdown file
Get-ChildItem -Path $sourceBooks -Filter "*.md" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Convert frontmatter format
    $content = $content -replace "^Title:", "title:"
    $content = $content -replace "^Date:", "datePublished:"
    $content = $content -replace "^Category:", "category:"
    $content = $content -replace "^Slug:", "slug:"
    $content = $content -replace "^Summary:", "summary:"
    
    # Fix cover path (remove /images/covers/ prefix, keep just filename)
    $content = $content -replace "cover: /images/covers/", "cover: "
    
    # Add time to datePublished if not present
    $content = $content -replace "datePublished: (\d{4}-\d{2}-\d{2})\s*$", "datePublished: `$1 10:00:00"
    $content = $content -replace "datePublished: (\d{4}-\d{2}-\d{2})\r?\n", "datePublished: `$1 10:00:00`n"
    
    # Convert to fenced YAML format (--- at start and end of metadata)
    if ($content -notmatch "^---") {
        # Find where content starts (after metadata)
        $lines = $content -split "`r?`n"
        $metadataEnd = 0
        $inMetadata = $true
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "^---\s*$" -and $inMetadata) {
                $metadataEnd = $i
                $inMetadata = $false
                break
            }
            if ($lines[$i] -notmatch "^\w+:" -and $lines[$i].Trim() -ne "" -and $inMetadata) {
                $metadataEnd = $i - 1
                break
            }
        }
        
        if ($metadataEnd -gt 0) {
            $metadata = $lines[0..$metadataEnd] -join "`n"
            $body = $lines[($metadataEnd + 1)..($lines.Count - 1)] -join "`n"
            $content = "---`n$metadata`n---`n$body"
        }
    }
    
    # Write to destination
    $destPath = Join-Path $destBooks $_.Name
    Set-Content -Path $destPath -Value $content -NoNewline
    Write-Host "Converted: $($_.Name)"
}

Write-Host "`nConversion complete!"
