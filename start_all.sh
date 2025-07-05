#!/bin/bash

# 1. 首先关闭所有终端窗口（排除当前终端）
current_tty=$(tty | sed 's/\/dev\///')
osascript <<EOF
tell application "Terminal"
    activate
    set windowList to every window
    repeat with theWindow in windowList
        set tabList to every tab of theWindow
        repeat with theTab in tabList
            if theTab's tty is not "${current_tty}" then
                close theWindow saving no
                exit repeat
            end if
        end repeat
    end repeat
end tell
EOF
sleep 2

# 2. 启动VPN（新终端窗口，放在下层右下角）
osascript -e 'tell app "Terminal" to do script "~/shell/quickq_auto.sh"'
echo "✅ VPN已启动，等待2秒后启动Docker..."
sleep 2

# 获取屏幕尺寸
screen_size=$(osascript -e 'tell application "Finder" to get bounds of window of desktop')
read -r x1 y1 x2 y2 <<< $(echo $screen_size | tr ',' ' ')
width=$((x2-x1))
height=$((y2-y1))

# 窗口排列函数
function arrange_window {
    local title=$1
    local x=$2
    local y=$3
    local w=$4
    local h=$5
    
    osascript <<EOF
tell application "Terminal"
    set targetWindow to first window whose name contains "${title}"
    set bounds of targetWindow to {${x}, ${y}, ${x}+${w}, ${y}+${h}}
end tell
EOF
}

# 布局参数
spacing=20  # 间距20px
upper_height=$((height/2-2*spacing))  # 上层高度总共减少40px
lower_height=$((height/2-2*spacing))  # 下层高度总共减少40px
lower_y=$((y1+upper_height+2*spacing))  # 下层位置下移40px

# 上层布局
gensyn_width=$((width*2/5))  # 保持原有宽度不变
gensyn_x=$((x1+400))         # 向右移动400px

# 下层布局
item_width=$(( (width-3*spacing)/3 ))  # 3个项目，总间距60px (20px*3)

# 3. 启动Docker（不新建终端窗口）
echo "✅ 正在后台启动Docker..."
open -a Docker --background

# 等待Docker完全启动
echo "⏳ 等待Docker服务就绪..."
until docker info >/dev/null 2>&1; do sleep 1; done
sleep 30  # 额外等待确保完全启动

# 4. 启动gensyn（保持原大小，向右移动400px）
osascript -e 'tell app "Terminal" to do script "until docker info >/dev/null 2>&1; do sleep 1; done && ~/shell/gensyn.sh"'
sleep 1
arrange_window "gensyn" $gensyn_x $y1 $gensyn_width $upper_height

# 5. 启动nexus（下层左侧）
osascript -e 'tell app "Terminal" to do script "~/shell/nexus.sh"'
sleep 1
arrange_window "nexus" $x1 $lower_y $item_width $lower_height

# 6. 启动wai run（下层中间）
osascript -e 'tell app "Terminal" to do script "wai run"'
sleep 1
arrange_window "wai" $((x1+item_width+spacing)) $lower_y $item_width $lower_height

# 7. 排列VPN窗口（下层右侧，高度减少40px）
arrange_window "quickq" $((x1+2*item_width+2*spacing)) $lower_y $item_width $lower_height

echo "✅ 所有项目已启动完成！"
echo "   - Docker已在后台运行"
echo "   - 其他应用窗口已按布局打开"