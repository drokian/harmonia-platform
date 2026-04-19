#!/usr/bin/env bash
# install.sh — PowerShell 7 varligini kontrol eder ve install.ps1'e yonlendirir.
set -euo pipefail

if ! command -v pwsh &>/dev/null; then
    echo "PowerShell 7+ bulunamadi."
    echo "Kurulum icin: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
    exit 1
fi

pwsh "$(dirname "$0")/install.ps1" "$@"
