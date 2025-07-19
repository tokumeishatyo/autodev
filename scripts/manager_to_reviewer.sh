#!/bin/bash
# ManagerペインからReviewerペインにメッセージを送信するスクリプト（ファイルベース版）

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
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_TYPE=$(source "$WORKSPACE_DIR/scripts/detect_work_type.sh" && detect_work_type "$MESSAGE" 1 3)

# 通信前チェック（リミット＋生存確認）
HEALTH_INTEGRATION="$WORKSPACE_DIR/scripts/manager_health_integration.sh"
if [ -f "$HEALTH_INTEGRATION" ]; then
    echo "📊 システム状態とClaude使用量をチェックしています..."
    "$HEALTH_INTEGRATION" comm_check "Reviewer" "$MESSAGE"
    local check_result=$?
    
    if [ $check_result -eq 2 ]; then
        echo "待機モードに移行したため通信を中止しました"
        exit 2
    elif [ $check_result -eq 1 ]; then
        echo "システム異常のため通信を中止しました"
        exit 1
    fi
else
    # 従来のチェック方法（フォールバック）
    echo "📊 Claude使用量をチェックしています..."
    if ! "$WORKSPACE_DIR/scripts/check_claude_usage.sh"; then
        echo "❌ 使用量チェックでエラーが発生しました。"
        exit 1
    fi
fi

# メッセージをファイルに書き込み（上書き）
echo "$MESSAGE" > "$WORKSPACE_DIR/tmp/tmp_manager.txt"

# ログファイルに追記
echo "[$(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')] Manager → Reviewer: $MESSAGE" >> "$WORKSPACE_DIR/logs/communication_log.txt"

# 独立ターミナルの進捗モニターに状態更新
"$WORKSPACE_DIR/scripts/update_progress_status.sh" "Reviewer" "Managerからのレビュー依頼を受信、確認中..." "$WORK_TYPE" >/dev/null 2>&1

# Reviewerペイン（pane 2）に切り替えて通知メッセージを送信
tmux select-pane -t claude_workspace:0.2
tmux send-keys -t claude_workspace:0.2 "cat \"$WORKSPACE_DIR/tmp/tmp_manager.txt\""
tmux send-keys -t claude_workspace:0.2 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Manager → Reviewer] メッセージをtmp/tmp_manager.txtに書き込みました (進捗表示開始: $WORK_TYPE)"