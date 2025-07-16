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

# 作業種別を自動検出
WORK_TYPE=$(source /workspace/Demo/scripts/detect_work_type.sh && detect_work_type "$MESSAGE" 1 2)

# ステータスペインでReviewer作業開始を表示
/workspace/Demo/scripts/update_status_pane.sh 2 "メッセージを受信、作業を開始しています..." "$WORK_TYPE" >/dev/null 2>&1

# Reviewerペインで進捗表示を開始
/workspace/Demo/scripts/start_progress.sh 2 "$WORK_TYPE" >/dev/null 2>&1 &

# Reviewerペイン（pane 2）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.2
tmux send-keys -t claude_workspace:0.2 "$MESSAGE"
tmux send-keys -t claude_workspace:0.2 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Manager → Reviewer] メッセージを送信しました (進捗表示開始: $WORK_TYPE)"