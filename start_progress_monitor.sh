#!/bin/bash
# 独立ターミナルで進捗モニターを起動するスクリプト

echo "🚀 AutoDev 進捗モニターを新しいターミナルで起動しています..."

# 使用可能なターミナルエミュレータを検出して起動
if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -c "/workspace/Demo/scripts/progress_monitor.sh; exec bash"
elif command -v xterm >/dev/null 2>&1; then
    xterm -e "/workspace/Demo/scripts/progress_monitor.sh; exec bash" &
elif command -v konsole >/dev/null 2>&1; then
    konsole -e "/workspace/Demo/scripts/progress_monitor.sh; exec bash" &
elif command -v alacritty >/dev/null 2>&1; then
    alacritty -e bash -c "/workspace/Demo/scripts/progress_monitor.sh; exec bash" &
else
    echo "⚠️ 新しいターミナルを自動起動できません。"
    echo "手動で新しいターミナルを開いて以下のコマンドを実行してください："
    echo ""
    echo "  /workspace/Demo/scripts/progress_monitor.sh"
    echo ""
    exit 1
fi

echo "✅ 進捗モニターが別ターミナルで起動されました！"
echo "💡 メインのtmuxセッションとは独立して動作します。"