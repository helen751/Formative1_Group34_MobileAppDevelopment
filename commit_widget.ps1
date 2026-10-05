param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FilePath,

    [Parameter(Mandatory=$true, Position=1)]
    [string]$Message
)

$branch = (git branch --show-current).Trim()

if (-not (Test-Path $FilePath)) {
    Write-Host "Error: File '$FilePath' not found." -ForegroundColor Red
    exit 1
}

Write-Host "==> Staging: $FilePath" -ForegroundColor Yellow
git add $FilePath

$status = git status --porcelain $FilePath
if ($status) {
    Write-Host "==> Committing: $Message" -ForegroundColor Green
    git commit -m "$Message"

    Write-Host "==> Pushing to origin $branch..." -ForegroundColor Magenta
    git push origin $branch
    Write-Host "Successfully pushed $FilePath to branch '$branch'!" -ForegroundColor Green
} else {
    Write-Host "No unstaged changes found in '$FilePath'." -ForegroundColor DarkYellow
}
