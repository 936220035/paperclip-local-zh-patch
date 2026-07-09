param(
  [string]$PaperclipRepo,
  [switch]$IncludeCodexModelDefault,
  [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Git {
  param([string[]]$GitArgs)
  & git @GitArgs
  return $LASTEXITCODE
}

function Test-GitOk {
  param([string[]]$GitArgs)
  try {
    $null = & git @GitArgs 2>$null
    return $LASTEXITCODE -eq 0
  } catch {
    return $false
  }
}

function Apply-LocalPatch {
  param(
    [string]$PatchPath,
    [string]$Name,
    [string[]]$AppliedMarkers = @()
  )

  if (-not (Test-Path -LiteralPath $PatchPath)) {
    throw "Patch file not found: $PatchPath"
  }

  Write-Host ""
  Write-Host "==> $Name"

  if (Test-GitOk @("apply", "--reverse", "--check", "--", $PatchPath)) {
    Write-Host "Already applied, skipping."
    return
  }

  if (-not (Test-GitOk @("apply", "--check", "--", $PatchPath))) {
    if (Test-AppliedMarkers -Markers $AppliedMarkers) {
      Write-Host "Already appears applied from Chinese UI markers, skipping."
      return
    }
    Write-Host "Patch cannot be applied cleanly. Run this command for details:"
    Write-Host "git apply --check `"$PatchPath`""
    throw "Failed to apply: $Name"
  }

  if ($CheckOnly) {
    Write-Host "Can apply cleanly."
    return
  }

  $exitCode = Invoke-Git @("apply", "--whitespace=nowarn", "--", $PatchPath)
  if ($exitCode -ne 0) {
    throw "git apply failed: $Name"
  }

  Write-Host "Applied."
}

function Test-AppliedMarkers {
  param([string[]]$Markers)
  if (-not $Markers -or $Markers.Count -eq 0) {
    return $false
  }

  foreach ($marker in $Markers) {
    $parts = $marker -split "::", 2
    if ($parts.Count -ne 2) {
      return $false
    }
    $path = Join-Path (Get-Location) $parts[0]
    if (-not (Test-Path -LiteralPath $path)) {
      return $false
    }
    $content = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
    if (-not $content.Contains($parts[1])) {
      return $false
    }
  }

  return $true
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required but was not found in PATH."
}

if ($PaperclipRepo) {
  if (-not (Test-Path -Path $PaperclipRepo)) {
    throw "Paperclip repo path not found: $PaperclipRepo"
  }
  Set-Location -Path $PaperclipRepo
}

$repoRoot = ""
if (Test-GitOk @("rev-parse", "--is-inside-work-tree")) {
  $repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
}
if (-not $repoRoot) {
  if ($PaperclipRepo) {
    $repoRoot = (Resolve-Path -LiteralPath $PaperclipRepo).Path
  } else {
    $repoRoot = (Get-Location).Path
  }
}

Set-Location -LiteralPath $repoRoot

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainPatch = Join-Path $scriptDir "0001-local-zh-ui-and-windows-fixes.patch"
$comprehensiveZhPatch = Join-Path $scriptDir "0003-comprehensive-zh-ui-text.patch"
$modelPatch = Join-Path $scriptDir "0002-optional-codex-model-default.patch"

Write-Host "Paperclip local Chinese patch pack"
Write-Host "Repo: $repoRoot"

Apply-LocalPatch -PatchPath $mainPatch -Name "Chinese UI + Windows local fixes"
Apply-LocalPatch `
  -PatchPath $comprehensiveZhPatch `
  -Name "Comprehensive Chinese UI text coverage" `
  -AppliedMarkers @(
    "ui\src\pages\IssueDetail.tsx::暂停任务",
    "ui\src\components\NewIssueDialog.tsx::任务标题",
    "ui\src\pages\Inbox.tsx::搜索收件箱",
    "ui\src\components\IssuesList.tsx::进行中"
  )

if ($IncludeCodexModelDefault) {
  Apply-LocalPatch -PatchPath $modelPatch -Name "Optional Codex model default for relay compatibility"
} else {
  Write-Host ""
  Write-Host "Optional model patch skipped."
  Write-Host "Use -IncludeCodexModelDefault only if your relay does not support gpt-5.3-codex-spark."
}

if ($CheckOnly) {
  Write-Host ""
  Write-Host "Check complete. No files were changed."
} else {
  Write-Host ""
  Write-Host "Done. Next steps:"
  Write-Host "1. Review changes: git diff --stat"
  Write-Host "2. Start Paperclip: pnpm dev"
}

