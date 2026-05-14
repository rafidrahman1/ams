#!/bin/bash
# Script to help debugging: check if the receiver is actually registered correctly
# and if there are any logs related to scanner broadcasts
adb logcat | grep -i "scanner"
