#!/bin/bash
# プロジェクト使用量追跡スクリプト
# プロジェクト単位でのトークン使用量を管理

# 設定
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED_DIR="/tmp/autodev_status"
BASELINE_FILE="$SHARED_DIR/project_baseline.txt"
SUMMARY_FILE="$WORKSPACE_DIR/logs/project_usage_summary.txt"

# 色付きメッセージ関数
print_info() { echo -e "\033[34mℹ️  $1\033[0m"; }
print_success() { echo -e "\033[32m✅ $1\033[0m"; }
print_warning() { echo -e "\033[33m⚠️  $1\033[0m"; }

# 現在時刻（日本時間）
current_time() {
    TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S'
}

# ccusageから現在のトークン使用量を取得
get_current_tokens() {
    local ccusage_output=$(npx ccusage@latest 2>/dev/null)
    local today_date=$(date +%m-%d)
    local today_line=$(echo "$ccusage_output" | grep -B2 "$today_date" | grep "opus-4" | tail -1)
    
    if [ -n "$today_line" ]; then
        local clean_line=$(echo "$today_line" | sed 's/\x1b\[[0-9;]*m//g')
        local input_tokens=$(echo "$clean_line" | awk -F'│' '{print $4}' | grep -oE '[0-9,]+' | tr -d ',' | tr -d ' ')
        local output_tokens=$(echo "$clean_line" | awk -F'│' '{print $5}' | grep -oE '[0-9,]+' | tr -d ',' | tr -d ' ')
        
        input_tokens=${input_tokens:-0}
        output_tokens=${output_tokens:-0}
        
        echo $((input_tokens + output_tokens))
    else
        echo "0"
    fi
}

# プロジェクトベースラインを初期化
init_project_baseline() {
    mkdir -p "$SHARED_DIR"
    mkdir -p "$(dirname "$SUMMARY_FILE")"
    
    local current_tokens=$(get_current_tokens)
    local timestamp=$(current_time)
    local planning_hash=""
    
    if [ -f "$WORKSPACE_DIR/WorkFlow/planning.txt" ]; then
        planning_hash=$(sha256sum "$WORKSPACE_DIR/WorkFlow/planning.txt" | cut -d' ' -f1)
    fi
    
    # ベースライン情報を記録
    cat > "$BASELINE_FILE" << EOF
# プロジェクトベースライン情報
PROJECT_START_TIME="$timestamp"
PROJECT_START_TOKENS="$current_tokens"
PROJECT_NAME="$(basename "$WORKSPACE_DIR")"
PLANNING_HASH="$planning_hash"
EOF
    
    print_info "プロジェクトベースラインを記録しました"
    print_info "開始時トークン: $current_tokens"
    print_info "開始時刻: $timestamp"
}

# プロジェクトベースラインを読み込み
load_project_baseline() {
    if [ -f "$BASELINE_FILE" ]; then
        source "$BASELINE_FILE"
        return 0
    else
        PROJECT_START_TOKENS=0
        PROJECT_START_TIME="N/A"
        PROJECT_NAME="Unknown"
        PLANNING_HASH=""
        return 1
    fi
}

# プロジェクト使用量を計算
calculate_project_usage() {
    local current_tokens=$(get_current_tokens)
    local project_tokens=$((current_tokens - PROJECT_START_TOKENS))
    
    if [ "$project_tokens" -lt 0 ]; then
        project_tokens=0
    fi
    
    echo "$project_tokens"
}

# プロジェクト経過時間を計算
get_project_elapsed_time() {
    if [ -n "$PROJECT_START_TIME" ] && [ "$PROJECT_START_TIME" != "N/A" ]; then
        local start_epoch=$(date -d "$PROJECT_START_TIME" +%s 2>/dev/null || echo 0)
        local current_epoch=$(date +%s)
        local elapsed=$((current_epoch - start_epoch))
        
        local hours=$((elapsed / 3600))
        local minutes=$(((elapsed % 3600) / 60))
        echo "${hours}時間${minutes}分"
    else
        echo "N/A"
    fi
}

# プロジェクト使用量サマリーを表示
show_project_summary() {
    load_project_baseline
    
    local current_tokens=$(get_current_tokens)
    local project_tokens=$(calculate_project_usage)
    local elapsed_time=$(get_project_elapsed_time)
    local cost_estimate="N/A"
    
    if [ "$project_tokens" -gt 0 ]; then
        cost_estimate=$(echo "scale=2; $project_tokens * 0.000015" | bc 2>/dev/null || echo "N/A")
    fi
    
    echo "================================================================"
    echo "               📊 プロジェクト使用量サマリー"
    echo "================================================================"
    echo "📁 プロジェクト名: $PROJECT_NAME"
    echo "📅 開始時刻: $PROJECT_START_TIME"
    echo "⏱️  経過時間: $elapsed_time"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 本日累計トークン: $current_tokens"
    echo "📦 プロジェクト開始時: $PROJECT_START_TOKENS"
    echo "🎯 プロジェクト使用量: $project_tokens トークン"
    echo "💰 推定コスト: \$$cost_estimate"
    echo "================================================================"
}

# プロジェクト完了時のサマリーを保存
save_project_summary() {
    load_project_baseline
    
    local current_tokens=$(get_current_tokens)
    local project_tokens=$(calculate_project_usage)
    local elapsed_time=$(get_project_elapsed_time)
    local end_time=$(current_time)
    local cost_estimate="N/A"
    
    if [ "$project_tokens" -gt 0 ]; then
        cost_estimate=$(echo "scale=2; $project_tokens * 0.000015" | bc 2>/dev/null || echo "N/A")
    fi
    
    # サマリーをファイルに保存
    cat >> "$SUMMARY_FILE" << EOF

================================
プロジェクト完了サマリー
================================
プロジェクト名: $PROJECT_NAME
開始時刻: $PROJECT_START_TIME
終了時刻: $end_time
経過時間: $elapsed_time
開始時トークン: $PROJECT_START_TOKENS
終了時トークン: $current_tokens
プロジェクト使用量: $project_tokens トークン
推定コスト: \$$cost_estimate
Planning Hash: $PLANNING_HASH
================================

EOF
    
    print_success "プロジェクトサマリーを保存しました: $SUMMARY_FILE"
}

# リアルタイム使用量監視
monitor_usage() {
    while true; do
        clear
        show_project_summary
        echo ""
        echo "📊 リアルタイム監視中... (Ctrl+C で停止)"
        echo "⏰ 更新間隔: 30秒"
        sleep 30
    done
}

# メイン処理
main() {
    case "${1:-summary}" in
        "init")
            init_project_baseline
            ;;
        "summary")
            show_project_summary
            ;;
        "save")
            save_project_summary
            ;;
        "monitor")
            monitor_usage
            ;;
        "--help"|"-h")
            echo "使用方法: $0 [コマンド]"
            echo "コマンド:"
            echo "  init     プロジェクトベースラインを初期化"
            echo "  summary  現在のプロジェクト使用量サマリーを表示（デフォルト）"
            echo "  save     プロジェクト完了サマリーを保存"
            echo "  monitor  リアルタイム使用量監視"
            echo "  --help   このヘルプを表示"
            ;;
        *)
            echo "不明なコマンド: $1"
            echo "使用方法: $0 --help"
            exit 1
            ;;
    esac
}

# スクリプトが直接実行された場合
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi