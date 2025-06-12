#!/bin/bash
# 隐藏 Dock 配置
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock tilesize -int 48
killall Dock
echo "Dock 已显示"