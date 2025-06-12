#!/bin/bash
# 隐藏 Dock 配置
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock no-bouncing -bool true
defaults write com.apple.dock tilesize -int 1
killall Dock
echo "Dock 已隐藏"