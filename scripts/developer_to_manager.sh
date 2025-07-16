#!/bin/bash
# DeveloperペインからManagerペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/developer_to_manager.sh メッセージ内容"
    echo "例: ./scripts/developer_to_manager.sh 詳細仕様書を作成しました。レビューをお願いします。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# Developer作業完了のため進捗表示を停止
/workspace/Demo/scripts/stop_progress.sh >/dev/null 2>&1

# 作業種別を自動検出
WORK_TYPE=$(source /workspace/Demo/scripts/detect_work_type.sh && detect_work_type "$MESSAGE" 3 1)

# ステータスペインでManager作業開始を表示
/workspace/Demo/scripts/update_status_pane.sh 1 "メッセージを受信、作業を開始しています..." "$WORK_TYPE" >/dev/null 2>&1

# Managerペインで進捗表示を開始
/workspace/Demo/scripts/start_progress.sh 1 "$WORK_TYPE" >/dev/null 2>&1 &

# Managerペイン（pane 1）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.1
tmux send-keys -t claude_workspace:0.1 "$MESSAGE"
tmux send-keys -t claude_workspace:0.1 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Developer → Manager] メッセージを送信しました (進捗表示: Developer停止 → Manager開始: $WORK_TYPE)"