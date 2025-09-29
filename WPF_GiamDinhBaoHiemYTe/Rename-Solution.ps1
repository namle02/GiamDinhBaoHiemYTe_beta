param (
    [string]$OldName = "",
    [string]$NewName = ""
)

if (-not $OldName -or -not $NewName) {
    Write-Host "Usage: .\Rename-Solution.ps1 -OldName 'OldName' -NewName 'NewName'"
    exit 1
}

Write-Host "🔄 Đang đổi tên từ '$OldName' sang '$NewName'..."

# 1. Đổi tên file và folder
Get-ChildItem -Recurse -Directory | Where-Object { $_.Name -eq $OldName } | Rename-Item -NewName $NewName
Get-ChildItem -Recurse -File | Where-Object { $_.Name -like "*$OldName*" } | ForEach-Object {
    $newFileName = $_.Name -replace [regex]::Escape($OldName), $NewName
    Rename-Item $_.FullName -NewName $newFileName
}

# 2. Replace toàn bộ text trong file (chỉ các file code, config, không replace file binary)
$exts = @("*.cs","*.xaml","*.csproj","*.sln","*.config","*.xml","*.json","*.md","*.txt")
foreach ($ext in $exts) {
    Get-ChildItem -Recurse -Include $ext | ForEach-Object {
        (Get-Content $_.FullName) -replace $OldName, $NewName | Set-Content $_.FullName
    }
}

# 3. Đổi tên solution (.sln) nếu cần
Get-ChildItem -Recurse -File -Filter "*$OldName*.sln" | ForEach-Object {
    $newFileName = $_.Name -replace [regex]::Escape($OldName), $NewName
    Rename-Item $_.FullName -NewName $newFileName
}

Write-Host "✅ Xong! Đổi tên solution/project/namespace sạch đẹp. Hãy kiểm thử lại solution."
