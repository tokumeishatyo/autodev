#!/bin/bash
# ReviewerペインからManagerペインにメッセージを送信するスクリプト（ファイルベース版）

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/reviewer_to_manager.sh メッセージ内容"
    echo "例: ./scripts/reviewer_to_manager.sh レビューを完了しました。以下の修正点があります。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# ベースディレクトリを取得
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Reviewer作業完了のため進捗表示を停止
"$WORKSPACE_DIR/scripts/stop_progress.sh" >/dev/null 2>&1

# 作業種別を自動検出
WORK_TYPE=$(source "$WORKSPACE_DIR/scripts/detect_work_type.sh" && detect_work_type "$MESSAGE" 3 1)

# メッセージをファイルに書き込み（上書き）
echo "$MESSAGE" > "$WORKSPACE_DIR/tmp/tmp_reviewer.txt"

# ログファイルに追記
echo "[$(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')] Reviewer → Manager: $MESSAGE" >> "$WORKSPACE_DIR/logs/communication_log.txt"

# 独立ターミナルの進捗モニターに状態更新
"$WORKSPACE_DIR/scripts/update_progress_status.sh" "Manager" "Reviewerからのフィードバックを受信、対応中..." "$WORK_TYPE" >/dev/null 2>&1

# Managerペイン（pane 1）に切り替えて通知メッセージを送信
tmux select-pane -t claude_workspace:0.1
tmux send-keys -t claude_workspace:0.1 "cat \"$WORKSPACE_DIR/tmp/tmp_reviewer.txt\""
tmux send-keys -t claude_workspace:0.1 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Reviewer → Manager] メッセージをtmp/tmp_reviewer.txtに書き込みました (進捗表示: Reviewer停止 → Manager開始: $WORK_TYPE)"