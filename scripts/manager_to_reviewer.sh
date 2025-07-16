#!/bin/bash
# ManagerペインからReviewerペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/manager_to_reviewer.sh メッセージ内容"
    echo "例: ./scripts/manager_to_reviewer.sh 詳細仕様書のレビューをお願いします。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# Reviewerペイン（pane 2）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.2
tmux send-keys -t claude_workspace:0.2 "$MESSAGE" C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Manager → Reviewer] メッセージを送信しました"