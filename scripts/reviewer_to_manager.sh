#!/bin/bash
# ReviewerペインからManagerペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/reviewer_to_manager.sh メッセージ内容"
    echo "例: ./scripts/reviewer_to_manager.sh レビューを完了しました。以下の修正点があります。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# Managerペイン（pane 1）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.1
tmux send-keys -t claude_workspace:0.1 "$MESSAGE" C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Reviewer → Manager] メッセージを送信しました"