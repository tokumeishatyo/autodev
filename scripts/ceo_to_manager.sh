#!/bin/bash
# CEOペインからManagerペインにメッセージを送信するスクリプト

# メッセージを引数から取得
MESSAGE="$*"

if [ -z "$MESSAGE" ]; then
    echo "使用方法: ./scripts/ceo_to_manager.sh メッセージ内容"
    echo "例: ./scripts/ceo_to_manager.sh planning.txtを確認しました。要件定義書の作成を開始してください。"
    exit 1
fi

# 現在のペインを保存
CURRENT_PANE=$(tmux display-message -p '#P')

# 作業種別を自動検出
WORK_TYPE=$(source /workspace/Demo/scripts/detect_work_type.sh && detect_work_type "$MESSAGE" 0 1)

# 独立ターミナルの進捗モニターに状態更新
/workspace/Demo/scripts/update_progress_status.sh "Manager" "CEOからの指示を受信、作業を開始しています..." "$WORK_TYPE" >/dev/null 2>&1

# Managerペイン（pane 1）に切り替えてメッセージを送信
tmux select-pane -t claude_workspace:0.1
tmux send-keys -t claude_workspace:0.1 "$MESSAGE"
tmux send-keys -t claude_workspace:0.1 C-m

# 元のペインに戻る
tmux select-pane -t claude_workspace:0.$CURRENT_PANE

echo "[CEO → Manager] メッセージを送信しました (進捗表示開始: $WORK_TYPE)"