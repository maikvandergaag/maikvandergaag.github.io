$file = "_posts\2023-05-11-creating-a-logic-app-api-connection-that-uses-the-managed-identity-using-bicep.html"

# Get all HTML files in the _posts folder
$files = Get-ChildItem _posts\*.html

# Process each file
foreach ($file in $files) {
    # Get the line numbers of lines containing '---'
$lineNumbers = (Get-Content $file.FullName | Select-String '---').LineNumber

Import-Module powershell-yaml

# If there are at least two lines with '---'
if ($lineNumbers.Count -ge 2) {
    # Get the content between the first two lines containing '---'
    $startLine = $lineNumbers[0]
    $endLine = $lineNumbers[1]
    $content = (Get-Content $file | Select-Object -Index ($startLine..($endLine-2))) -join "`n"
    $yamlObject = ConvertFrom-Yaml $content.ToString()
    $yamlObject.Remove("author")
    $yamlObject.Remove("meta")
    $yamlObject.Remove("publish")
    $yamlObject.Remove("password")
    $yamlObject.Remove("published")
    $yamlObject.Remove("parent_id")
    $yamlObject.Remove("layout")
    $topContent = ConvertTo-Yaml $yamlObject
}

    $lastLineNumber = (Get-Content $file.FullName | Measure-Object -Line).Lines
    # If there are at least two lines with '---'
    if ($lineNumbers.Count -ge 2) {
        # Get the content between the first two lines containing '---'
        $endLine = $lineNumbers[1]
        $content = (Get-Content $file | Select-Object -Index ($endLine..($lastlineNumber))) -join "`n"

        $content = $content.Replace("https://msftplayground.com/wp-content/uploads", "/assets/archive");
        $content = $content.Replace("{{ site.baseurl }}", "");
        $content = $content -replace "<!--.*?-->", "";
        $content = $content -replace "<(\w+)\b[^>]*>\s*</\1>", ""
        $content = $content -replace "<pre.*?>", "<pre class=""highlight"">"
    }

    $fileContent = "---`n" + $topContent + "---`n" + $content

    $fileContent | Out-File $file.FullName -Encoding utf8
}


