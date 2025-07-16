#!/bin/bash
# 進捗表示システムクリーンアップスクリプト

echo "進捗表示システムをクリーンアップしています..."

# 進捗表示デーモンを停止
/workspace/Demo/scripts/stop_progress.sh

# 一時ファイルを削除
rm -f /tmp/claude_workspace_progress
rm -f /tmp/claude_workspace_progress.pid

echo "クリーンアップが完了しました。"