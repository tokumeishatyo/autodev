#!/bin/bash
# 進捗表示開始スクリプト

PROGRESS_FILE="/tmp/claude_workspace_progress"
PROGRESS_PID_FILE="/tmp/claude_workspace_progress.pid"

# 使用方法チェック
if [ $# -ne 2 ]; then
    echo "使用方法: $0 <target_pane> <work_type>"
    echo "target_pane: 0=CEO, 1=Manager, 2=Reviewer, 3=Developer"
    echo "work_type: thinking, document_creation, code_development, code_review, testing, analysis, specification, planning"
    exit 1
fi

TARGET_PANE="$1"
WORK_TYPE="$2"

# 既存の進捗表示を停止
if [ -f "$PROGRESS_PID_FILE" ]; then
    OLD_PID=$(cat "$PROGRESS_PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        kill -TERM "$OLD_PID" 2>/dev/null
        sleep 1
    fi
    rm -f "$PROGRESS_PID_FILE"
fi

# 進捗状況ファイルを作成
cat > "$PROGRESS_FILE" << EOF
TARGET_PANE=$TARGET_PANE
WORK_TYPE=$WORK_TYPE
STATUS=working
START_TIME=$(date +%s)
EOF

# 進捗表示デーモンを開始
/workspace/Demo/scripts/progress_indicator.sh daemon &
PROGRESS_PID=$!

# PIDを保存
echo "$PROGRESS_PID" > "$PROGRESS_PID_FILE"

echo "進捗表示を開始しました (PID: $PROGRESS_PID, ペイン: $TARGET_PANE, 作業種別: $WORK_TYPE)"