#!/bin/bash
# Claude使用量表示モニター（max5プラン対応版）
# 人間が理解しやすい形で現在の使用量とステータスを表示

USAGE_LOG="/tmp/autodev_status/claude_usage.log"
SHARED_DIR="/tmp/autodev_status"
START_TIME_FILE="$SHARED_DIR/session_start_time.txt"

# max5プラン設定
MAX_TOKENS=88000
MAX_PROMPTS=200
RESET_INTERVAL_HOURS=5

# 共有ディレクトリが存在しない場合は作成
mkdir -p "$SHARED_DIR"

# セッション開始からの経過時間を取得（秒）
get_elapsed_seconds() {
    if [ -f "$START_TIME_FILE" ]; then
        local start_time=$(cat "$START_TIME_FILE")
        local current_time=$(date +%s)
        echo $((current_time - start_time))
    else
        echo "0"
    fi
}

# リセットまでの残り時間を取得（秒）
get_remaining_seconds() {
    local elapsed=$(get_elapsed_seconds)
    local reset_seconds=$((RESET_INTERVAL_HOURS * 3600))
    local remaining=$((reset_seconds - (elapsed % reset_seconds)))
    echo $remaining
}

# リセットまでの残り時間を人間可読形式で取得
get_remaining_time_string() {
    local remaining=$(get_remaining_seconds)
    local hours=$((remaining / 3600))
    local minutes=$(((remaining % 3600) / 60))
    echo "${hours}時間${minutes}分"
}

# 最新の使用量データを取得
get_latest_usage_data() {
    if [ -f "$USAGE_LOG" ]; then
        local latest_line=$(tail -1 "$USAGE_LOG")
        echo "$latest_line"
    else
        echo ""
    fi
}

# 使用量情報を解析
parse_usage_data() {
    local data="$1"
    
    # トークン使用量
    local tokens=$(echo "$data" | grep -oE 'トークン: [0-9]+' | grep -oE '[0-9]+' || echo "0")
    local token_percentage=$(echo "$data" | grep -oE 'トークン:[^(]+\(([0-9]+)%\)' | grep -oE '[0-9]+' | head -1 || echo "0")
    
    # プロンプト使用量
    local prompts=$(echo "$data" | grep -oE 'プロンプト: [0-9]+' | grep -oE '[0-9]+' || echo "0")
    local prompt_percentage=$(echo "$data" | grep -oE 'プロンプト:[^(]+\(([0-9]+)%\)' | grep -oE '[0-9]+' | tail -1 || echo "0")
    
    # データソース
    local source=$(echo "$data" | grep -oE 'source: [a-z-]+' | cut -d' ' -f2 || echo "unknown")
    
    echo "$tokens|$token_percentage|$prompts|$prompt_percentage|$source"
}

# 使用量グラフの生成
generate_usage_bar() {
    local percentage="$1"
    local width=30
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # 色の決定
    local color=""
    if [ "$percentage" -lt 50 ]; then
        color="\033[32m"  # 緑
    elif [ "$percentage" -lt 75 ]; then
        color="\033[33m"  # 黄
    elif [ "$percentage" -lt 85 ]; then
        color="\033[35m"  # マゼンタ
    else
        color="\033[31m"  # 赤
    fi
    
    # バーの生成
    printf "[${color}"
    for i in $(seq 1 $filled); do printf "█"; done
    printf "\033[0m"
    for i in $(seq 1 $empty); do printf "░"; done
    printf "] %3d%%" "$percentage"
}

# 使用量状況の表示
display_usage_status() {
    local usage_data="$1"
    
    printf "\n╔══════════════════════════════════════╗\n"
    printf "║     Claude使用量モニター (max5)     ║\n"
    printf "╚══════════════════════════════════════╝\n"
    printf "📅 更新時刻: %s\n\n" "$(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S JST')"
    
    if [ -z "$usage_data" ]; then
        printf "⚠️  使用量: データなし\n"
        printf "💡 状態: 初回チェック待ち\n"
    else
        # データ解析
        IFS='|' read -r tokens token_pct prompts prompt_pct source <<< "$(parse_usage_data "$usage_data")"
        
        # トークン使用量表示
        printf "📊 トークン使用量:\n"
        printf "   "
        generate_usage_bar "$token_pct"
        printf "\n"
        printf "   %s / %s トークン\n\n" "$tokens" "$MAX_TOKENS"
        
        # プロンプト使用量表示
        printf "💬 プロンプト使用量:\n"
        printf "   "
        generate_usage_bar "$prompt_pct"
        printf "\n"
        printf "   %s / %s プロンプト\n\n" "$prompts" "$MAX_PROMPTS"
        
        # リセット情報
        local remaining_time=$(get_remaining_time_string)
        printf "⏰ リセットまで: %s\n" "$remaining_time"
        
        # 状態表示
        local max_pct=$token_pct
        if [ "$prompt_pct" -gt "$max_pct" ]; then
            max_pct=$prompt_pct
        fi
        
        printf "\n"
        if [ "$max_pct" -lt 50 ]; then
            printf "💚 状態: 正常動作中\n"
        elif [ "$max_pct" -lt 75 ]; then
            printf "💛 状態: 使用量やや高め\n"
        elif [ "$max_pct" -lt 85 ]; then
            printf "🧡 状態: 間もなく制限に到達\n"
        else
            printf "❤️  状態: 待機モード推奨\n"
        fi
        
        # データソース
        printf "📡 データソース: %s\n" "$source"
    fi
    
    printf "══════════════════════════════════════\n"
}

# リアルタイム監視モード
monitor_mode() {
    echo "🚀 Claude使用量リアルタイム監視を開始します..."
    echo "終了するには Ctrl+C を押してください"
    echo ""
    
    while true; do
        clear
        local usage_data=$(get_latest_usage_data)
        display_usage_status "$usage_data"
        
        # 現在のアクティブ役割も表示
        if [ -f "$SHARED_DIR/active_role.txt" ]; then
            local active_role=$(cat "$SHARED_DIR/active_role.txt" 2>/dev/null | head -1)
            if [ -n "$active_role" ]; then
                printf "\n🎯 現在アクティブ: %s\n" "$active_role"
            fi
        fi
        
        if [ -f "$SHARED_DIR/progress.txt" ]; then
            local progress=$(cat "$SHARED_DIR/progress.txt" 2>/dev/null | head -1)
            if [ -n "$progress" ]; then
                printf "📝 進捗状況: %s\n" "$progress"
            fi
        fi
        
        printf "\n💡 終了するには Ctrl+C を押してください\n"
        
        sleep 30  # 30秒間隔で更新
    done
}

# ワンショット表示モード
oneshot_mode() {
    local usage_data=$(get_latest_usage_data)
    display_usage_status "$usage_data"
}

# メイン処理
main() {
    case "${1:-oneshot}" in
        "monitor"|"watch"|"-m")
            monitor_mode
            ;;
        "oneshot"|"show"|"-s"|"")
            oneshot_mode
            ;;
        "help"|"-h"|"--help")
            echo "使用方法:"
            echo "  $0                リアルタイム使用量を1回表示"
            echo "  $0 monitor        リアルタイム監視モード"
            echo "  $0 oneshot        使用量を1回表示"
            echo "  $0 help           このヘルプを表示"
            ;;
        *)
            echo "不明なオプション: $1"
            echo "ヘルプを表示するには: $0 help"
            exit 1
            ;;
    esac
}

# Ctrl+Cのハンドリング
trap 'echo ""; echo "監視を終了します..."; exit 0' INT

# スクリプトが直接実行された場合
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi