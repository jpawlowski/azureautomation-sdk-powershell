#!/bin/bash
#
# Script Name: postStartCommand.sh
# Author: Julian Pawlowski
# Company: Workoho GmbH
# Copyright: © 2024 Workoho GmbH
# License: https://github.com/workoho/azureautomation-sdk-powershell/blob/main/LICENSE.txt
# Project: https://github.com/workoho/azureautomation-sdk-powershell
# Created: 2024-07-08
# Last Modified: 2024-07-08
# Version: 1.0.0
# Description: Run commands after the container is started
# Usage: ./postStartCommand.sh
#

echo "Running postStartCommand.sh..."

echo "Running postStartCommand.ps1..."
$(which pwsh) -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "$(dirname "$0")/postStartCommand.ps1"
