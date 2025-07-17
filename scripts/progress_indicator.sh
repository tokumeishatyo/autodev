#!/bin/bash
# 進捗表示システム - 1分間隔で作業状況を表示

PROGRESS_FILE="/tmp/claude_workspace_progress"
INTERVAL=60  # 60秒間隔

# 進捗メッセージの定義
declare -A PROGRESS_MESSAGES=(
    ["thinking"]="💭 思考中..."
    ["document_creation"]="📝 文書作成中..."
    ["code_development"]="💻 コード作成中..."
    ["code_review"]="🔍 レビュー中..."
    ["testing"]="🧪 テスト実行中..."
    ["analysis"]="📊 分析中..."
    ["specification"]="📋 仕様書作成中..."
    ["planning"]="📈 計画策定中..."
)

# カウンター用の配列
declare -A COUNTERS

# 進捗状況ファイルが存在するかチェック
check_progress_file() {
    [ -f "$PROGRESS_FILE" ]
}

# 進捗状況を読み込み
read_progress_status() {
    if check_progress_file; then
        source "$PROGRESS_FILE" 2>/dev/null
        return 0
    else
        return 1
    fi
}

# 進捗メッセージをステータスペインに送信
send_progress_message() {
    local target_pane="$1"
    local work_type="$2"
    local elapsed_minutes="$3"
    
    # カウンターを更新
    local counter_key="${target_pane}_${work_type}"
    COUNTERS[$counter_key]=$((${COUNTERS[$counter_key]:-0} + 1))
    local count=${COUNTERS[$counter_key]}
    
    # 役割名を取得
    local role_name=""
    case $target_pane in
        0) role_name="🟣 CEO" ;;
        1) role_name="🟠 Manager" ;;
        3) role_name="🔵 Reviewer" ;;
        4) role_name="🟢 Developer" ;;
        *) role_name="⚪ Unknown" ;;
    esac
    
    # メッセージを構築
    local base_message="${PROGRESS_MESSAGES[$work_type]:-"⏳ 作業中..."}"
    local progress_message="$base_message (${elapsed_minutes}分経過)"
    
    # 進捗インジケーターを追加
    local dots=""
    case $((count % 4)) in
        1) dots="●○○" ;;
        2) dots="○●○" ;;
        3) dots="○○●" ;;
        0) dots="●●●" ;;
    esac
    
    # ステータスペイン（pane 2）にメッセージを送信
    if tmux list-sessions | grep -q "claude_workspace"; then
        # ステータスペインをクリアして新しい情報を表示
        tmux send-keys -t "claude_workspace:0.2" "clear" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo '=== 📊 進捗ステータス ==='" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo ''" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo '🎯 アクティブ役割: $role_name'" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo '📋 作業内容: $progress_message $dots'" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo '⏰ 開始時刻: $(date -d @$START_TIME +"%H:%M:%S")'" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo ''" C-m
        tmux send-keys -t "claude_workspace:0.2" "echo '💡 Tip: この表示はClaudeの作業に影響しません'" C-m
    fi
}

# メインループ
main() {
    echo "進捗表示システムを開始しました..."
    
    while true; do
        if read_progress_status; then
            # 経過時間を計算
            local current_time=$(date +%s)
            local elapsed_seconds=$((current_time - START_TIME))
            local elapsed_minutes=$((elapsed_seconds / 60))
            
            # 最低1分経過してから表示開始
            if [ $elapsed_minutes -ge 1 ]; then
                send_progress_message "$TARGET_PANE" "$WORK_TYPE" "$elapsed_minutes"
            fi
        fi
        
        sleep $INTERVAL
    done
}

# シグナルハンドラー - SIGTERM受信時にクリーンアップ
cleanup() {
    echo "進捗表示システムを停止しています..."
    rm -f "$PROGRESS_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# バックグラウンドで実行されている場合のチェック
if [ "$1" = "daemon" ]; then
    main
else
    echo "使用方法: $0 daemon"
    echo "このスクリプトはデーモンモードで実行してください"
fi