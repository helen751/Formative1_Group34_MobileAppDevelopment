# ==============================================================================
# commit_stages.ps1
# Automates progressive, granular commits and pushes file-by-file & widget-by-widget
# ==============================================================================

$branch = (git branch --show-current).Trim()
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " Starting Progressive Granular Git Commits" -ForegroundColor Cyan
Write-Host " Branch: $branch" -ForegroundColor Cyan
Write-Host "======================================================`n" -ForegroundColor Cyan

function CommitAndPush($filePattern, $message) {
    Write-Host "`n--> Staging: $filePattern" -ForegroundColor Yellow
    git add $filePattern
    
    $staged = git diff --cached --name-only
    if ($staged) {
        Write-Host "--> [COMMIT] $message" -ForegroundColor Green
        git commit -m "$message"
        Write-Host "--> [PUSH] Pushing to origin $branch..." -ForegroundColor Magenta
        git push origin $branch
    } else {
        Write-Host "No staged changes found for $filePattern" -ForegroundColor DarkGray
    }
}

# --------------------------------------------------------------------------
# STAGE 1: Theme & Design Tokens
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 1: Design Tokens & Theme ===" -ForegroundColor Yellow
CommitAndPush "lib/theme/devtrack_theme.dart" "feat(theme): define DevTrackColors palette and card decoration helper"

# --------------------------------------------------------------------------
# STAGE 2: Domain Models & Logic
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 2: Domain Models & Logic ===" -ForegroundColor Yellow
CommitAndPush "lib/models/devtrack_models.dart" "feat(models): add Task, Member, AppNotification models and TaskListStats extension"

# --------------------------------------------------------------------------
# STAGE 3: Mock Data Store
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 3: Mock Data Store ===" -ForegroundColor Yellow
CommitAndPush "lib/data/mock_data.dart" "feat(data): add mock dataset for members, tasks and initial state"

# --------------------------------------------------------------------------
# STAGE 4: Reusable UI Widgets (Widget-by-Widget)
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 4: Individual UI Widgets ===" -ForegroundColor Yellow
CommitAndPush "lib/widgets/status_badge.dart" "feat(widgets): add StatusBadge pill component for SLA status indicators"
CommitAndPush "lib/widgets/filter_pill.dart" "feat(widgets): add FilterPill animated toggle chip component"
CommitAndPush "lib/widgets/dark_button.dart" "feat(widgets): add DarkButton primary action button component"
CommitAndPush "lib/widgets/task_tile.dart" "feat(widgets): add TaskTile component with SLA color stripe and badge"
CommitAndPush "lib/widgets/member_profile_sheet.dart" "feat(widgets): add MemberProfileSheet modal bottom sheet for member details"

# --------------------------------------------------------------------------
# STAGE 5: Team Members Screen
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 5: Team Members Screen ===" -ForegroundColor Yellow
CommitAndPush "lib/screens/team_members_page.dart" "feat(team): implement TeamMembersPage with live search, workload cards and profile modal"

# --------------------------------------------------------------------------
# STAGE 6: Dashboard Screen
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 6: Dashboard Screen ===" -ForegroundColor Yellow
CommitAndPush "lib/screens/dashboard.dart" "feat(dashboard): implement DashboardPage with custom progress ring, SLA grid, filters and attention list"

# --------------------------------------------------------------------------
# STAGE 7: Navigation Shell & App Bootstrap
# --------------------------------------------------------------------------
Write-Host "`n=== Stage 7: Home Shell & Bootstrap ===" -ForegroundColor Yellow
CommitAndPush "lib/screens/home_shell.dart" "feat(shell): implement HomeShell with 4-tab bottom navigation and IndexedStack persistence"
CommitAndPush "lib/main.dart" "feat(core): configure MyApp entry point with DevTrackTheme and HomeShell root"

# --------------------------------------------------------------------------
# STAGE 8: Test & Script Cleanup
# --------------------------------------------------------------------------
if (-not (Test-Path "test/widget_test.dart")) {
    git add -u "test/widget_test.dart" 2>$null
    $staged = git diff --cached --name-only
    if ($staged) {
        Write-Host "`n=== Stage 8: Test Cleanup ===" -ForegroundColor Yellow
        git commit -m "chore(test): remove unused default widget test"
        git push origin $branch
    }
}

# Add helper scripts
CommitAndPush "commit_widget.ps1" "chore(scripts): add commit_widget.ps1 helper script"
CommitAndPush "commit_stages.ps1" "chore(scripts): add commit_stages.ps1 automation script"

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host " ALL STAGES COMMITTED & PUSHED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
