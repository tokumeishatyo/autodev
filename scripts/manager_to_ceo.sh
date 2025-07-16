#!/bin/bash
# ManagerペインからCEOペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/manager_to_ceo.sh メッセージ内容"
    echo "例: ./scripts/manager_to_ceo.sh 要件定義書の初期版を作成しました。レビューをお願いします。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# CEOペイン（pane 0）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.0
tmux send-keys -t claude_workspace:0.0 "$MESSAGE" C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Manager → CEO] メッセージを送信しました"