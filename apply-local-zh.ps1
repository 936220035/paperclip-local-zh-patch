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
  $null = & git @GitArgs 2>$null
  return $LASTEXITCODE -eq 0
}

function Apply-LocalPatch {
  param(
    [string]$PatchPath,
    [string]$Name
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

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git is required but was not found in PATH."
}

if ($PaperclipRepo) {
  if (-not (Test-Path -Path $PaperclipRepo)) {
    throw "Paperclip repo path not found: $PaperclipRepo"
  }
  Set-Location -Path $PaperclipRepo
}

$repoRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
if (-not $repoRoot) {
  throw "Run this script inside a Paperclip git repository, or pass -PaperclipRepo C:\path\to\paperclip."
}

Set-Location -LiteralPath $repoRoot

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainPatch = Join-Path $scriptDir "0001-local-zh-ui-and-windows-fixes.patch"
$modelPatch = Join-Path $scriptDir "0002-optional-codex-model-default.patch"

Write-Host "Paperclip local Chinese patch pack"
Write-Host "Repo: $repoRoot"

Apply-LocalPatch -PatchPath $mainPatch -Name "Chinese UI + Windows local fixes"

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
