#!/bin/bash
# ステータスペイン更新スクリプト

# 使用方法チェック
if [ $# -lt 2 ]; then
    echo "使用方法: $0 <active_pane> <message> [work_type]"
    echo "active_pane: 0=CEO, 1=Manager, 2=Reviewer, 3=Developer"
    echo "message: 表示するメッセージ"
    echo "work_type: (オプション) 作業種別"
    exit 1
fi

ACTIVE_PANE="$1"
MESSAGE="$2"
WORK_TYPE="${3:-"general"}"

# 役割名を取得
case $ACTIVE_PANE in
    0) ROLE_NAME="🟣 CEO" ;;
    1) ROLE_NAME="🟠 Manager" ;;
    2) ROLE_NAME="🔵 Reviewer" ;;
    3) ROLE_NAME="🟢 Developer" ;;
    *) ROLE_NAME="⚪ Unknown" ;;
esac

# 作業種別アイコンを取得
case $WORK_TYPE in
    "thinking") WORK_ICON="💭" ;;
    "document_creation") WORK_ICON="📝" ;;
    "code_development") WORK_ICON="💻" ;;
    "code_review") WORK_ICON="🔍" ;;
    "testing") WORK_ICON="🧪" ;;
    "analysis") WORK_ICON="📊" ;;
    "specification") WORK_ICON="📋" ;;
    "planning") WORK_ICON="📈" ;;
    *) WORK_ICON="⏳" ;;
esac

# tmuxセッションが存在するかチェック
if ! tmux list-sessions | grep -q "claude_workspace"; then
    echo "エラー: claude_workspaceセッションが見つかりません"
    exit 1
fi

# ステータスペイン（pane 4）を更新
tmux send-keys -t "claude_workspace:0.4" "clear" C-m
tmux send-keys -t "claude_workspace:0.4" "echo '=== 📊 進捗ステータス ==='" C-m
tmux send-keys -t "claude_workspace:0.4" "echo ''" C-m
tmux send-keys -t "claude_workspace:0.4" "echo '🎯 アクティブ役割: $ROLE_NAME'" C-m
tmux send-keys -t "claude_workspace:0.4" "echo '$WORK_ICON 状態: $MESSAGE'" C-m
tmux send-keys -t "claude_workspace:0.4" "echo '⏰ 更新時刻: $(date +"%H:%M:%S")'" C-m
tmux send-keys -t "claude_workspace:0.4" "echo ''" C-m
tmux send-keys -t "claude_workspace:0.4" "echo '💡 この表示はClaudeの作業を妨げません'" C-m

echo "ステータスペインを更新しました: $ROLE_NAME - $MESSAGE"