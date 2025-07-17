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

# Reviewer作業完了のため進捗表示を停止
/workspace/Demo/scripts/stop_progress.sh >/dev/null 2>&1

# 作業種別を自動検出
WORK_TYPE=$(source /workspace/Demo/scripts/detect_work_type.sh && detect_work_type "$MESSAGE" 3 1)

# 独立ターミナルの進捗モニターに状態更新
/workspace/Demo/scripts/update_progress_status.sh "Manager" "Reviewerからのフィードバックを受信、対応中..." "$WORK_TYPE" >/dev/null 2>&1

# Managerペイン（pane 1）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.1
tmux send-keys -t claude_workspace:0.1 "$MESSAGE"
tmux send-keys -t claude_workspace:0.1 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Reviewer → Manager] メッセージを送信しました (進捗表示: Reviewer停止 → Manager開始: $WORK_TYPE)"