#!/bin/bash
# 独立ターミナル用進捗モニター

# 共有ディレクトリ設定
SHARED_DIR="/tmp/autodev_status"
ACTIVE_ROLE_FILE="$SHARED_DIR/active_role.txt"
PROGRESS_FILE="$SHARED_DIR/progress.txt" 
WORK_TYPE_FILE="$SHARED_DIR/work_type.txt"
START_TIME_FILE="$SHARED_DIR/start_time.txt"
PID_FILE="$SHARED_DIR/monitor.pid"

# 共有ディレクトリを作成
mkdir -p "$SHARED_DIR"

# このプロセスのPIDを保存
echo $$ > "$PID_FILE"

# 初期化
echo "待機中" > "$ACTIVE_ROLE_FILE"
echo "システム起動中..." > "$PROGRESS_FILE"
echo "general" > "$WORK_TYPE_FILE"
echo $(date +%s) > "$START_TIME_FILE"

# 役割アイコンマッピング
declare -A ROLE_ICONS=(
    ["CEO"]="🟣"
    ["Manager"]="🟠"
    ["Reviewer"]="🔵"
    ["Developer"]="🟢"
    ["待機中"]="⚪"
)

# 作業種別アイコンマッピング
declare -A WORK_ICONS=(
    ["thinking"]="💭"
    ["document_creation"]="📝"
    ["code_development"]="💻"
    ["code_review"]="🔍"
    ["testing"]="🧪"
    ["analysis"]="📊"
    ["specification"]="📋"
    ["planning"]="📈"
    ["general"]="⏳"
)

# カウンター
counter=0

# 画面クリア関数
clear_screen() {
    clear
    echo "================================================================"
    echo "           📊 AutoDev 進捗モニター (独立ターミナル)"
    echo "================================================================"
    echo ""
}

# ステータス表示関数
display_status() {
    local active_role=$(cat "$ACTIVE_ROLE_FILE" 2>/dev/null || echo "待機中")
    local progress_msg=$(cat "$PROGRESS_FILE" 2>/dev/null || echo "システム起動中...")
    local work_type=$(cat "$WORK_TYPE_FILE" 2>/dev/null || echo "general")
    local start_time=$(cat "$START_TIME_FILE" 2>/dev/null || echo $(date +%s))
    
    local role_icon="${ROLE_ICONS[$active_role]:-⚪}"
    local work_icon="${WORK_ICONS[$work_type]:-⏳}"
    
    # 経過時間計算
    local current_time=$(date +%s)
    local elapsed_seconds=$((current_time - start_time))
    local elapsed_minutes=$((elapsed_seconds / 60))
    local elapsed_hours=$((elapsed_minutes / 60))
    local remaining_minutes=$((elapsed_minutes % 60))
    
    # プログレスバー生成
    local dots=""
    case $((counter % 4)) in
        0) dots="●○○○" ;;
        1) dots="○●○○" ;;
        2) dots="○○●○" ;;
        3) dots="○○○●" ;;
    esac
    
    echo "🎯 アクティブ役割: $role_icon $active_role"
    echo "📋 作業状況: $work_icon $progress_msg"
    echo "⏰ 経過時間: $(printf "%02d:%02d" $elapsed_hours $remaining_minutes) $dots"
    echo "🕐 開始時刻: $(date -d @$start_time +'%H:%M:%S')"
    echo "🔄 更新回数: $counter"
    echo ""
    echo "💡 このモニターは独立して動作し、tmuxセッションに影響しません"
    echo "💡 終了するには Ctrl+C を押してください"
    echo ""
    echo "================================================================"
}

# シグナルハンドラー
cleanup() {
    echo ""
    echo "🛑 進捗モニターを終了しています..."
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGINT SIGTERM

# メインループ
echo "🚀 AutoDev 進捗モニターを起動しています..."
sleep 2

while true; do
    clear_screen
    display_status
    counter=$((counter + 1))
    sleep 5  # 5秒間隔で更新
done