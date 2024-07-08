#!/bin/bash
#
# Script Name: postCreateCommand.sh
# Author: Julian Pawlowski
# Company: Workoho GmbH
# Copyright: © 2024 Workoho GmbH
# License: https://github.com/workoho/azureautomation-sdk-powershell/blob/main/LICENSE.txt
# Project: https://github.com/workoho/azureautomation-sdk-powershell
# Created: 2024-05-16
# Last Modified: 2024-05-16
# Version: 1.0.0
# Description: Run commands after the container is created
# Usage: sudo ./postCreateCommand.sh
#

echo "Running postCreateCommand.sh..."

echo "Setting default shell to PowerShell"
chsh vscode -s $(which pwsh)

echo "Running postCreateCommand.ps1..."
$(which pwsh) -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$(dirname "$0")/postCreateCommand.ps1"
