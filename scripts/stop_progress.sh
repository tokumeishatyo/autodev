#!/bin/bash
# 進捗表示停止スクリプト

PROGRESS_FILE="/tmp/claude_workspace_progress"
PROGRESS_PID_FILE="/tmp/claude_workspace_progress.pid"

# 進捗表示デーモンを停止
if [ -f "$PROGRESS_PID_FILE" ]; then
    PROGRESS_PID=$(cat "$PROGRESS_PID_FILE")
    if kill -0 "$PROGRESS_PID" 2>/dev/null; then
        kill -TERM "$PROGRESS_PID" 2>/dev/null
        sleep 1
        
        # 強制終了が必要な場合
        if kill -0 "$PROGRESS_PID" 2>/dev/null; then
            kill -KILL "$PROGRESS_PID" 2>/dev/null
        fi
        
        echo "進捗表示を停止しました (PID: $PROGRESS_PID)"
    else
        echo "進捗表示プロセスが見つかりません"
    fi
    rm -f "$PROGRESS_PID_FILE"
else
    echo "進捗表示は実行されていません"
fi

# 進捗状況ファイルを削除
rm -f "$PROGRESS_FILE"