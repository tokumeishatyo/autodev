#!/bin/bash
# ManagerペインからDeveloperペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/manager_to_developer.sh メッセージ内容"
    echo "例: ./scripts/manager_to_developer.sh 詳細仕様書の作成を開始してください。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# 作業種別を自動検出
WORK_TYPE=$(source /workspace/Demo/scripts/detect_work_type.sh && detect_work_type "$MESSAGE" 1 3)

# Developerペインで進捗表示を開始
/workspace/Demo/scripts/start_progress.sh 3 "$WORK_TYPE" >/dev/null 2>&1 &

# Developerペイン（pane 3）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.3
tmux send-keys -t claude_workspace:0.3 "$MESSAGE"
tmux send-keys -t claude_workspace:0.3 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[Manager → Developer] メッセージを送信しました (進捗表示開始: $WORK_TYPE)"