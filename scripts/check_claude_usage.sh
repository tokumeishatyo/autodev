#!/bin/bash
# Claude使用量チェックスクリプト（max5プラン対応版）
# Managerが作業前に使用量を確認し、85%を超えている場合は待機

USAGE_LOG="/tmp/autodev_status/claude_usage.log"
SHARED_DIR="/tmp/autodev_status"
START_TIME_FILE="$SHARED_DIR/session_start_time.txt"

# max5プラン設定
MAX_TOKENS=88000
MAX_PROMPTS=200
RESET_INTERVAL_HOURS=5

# 共有ディレクトリが存在しない場合は作成
mkdir -p "$SHARED_DIR"

# セッション開始時刻を記録（初回のみ）
init_session_time() {
    if [ ! -f "$START_TIME_FILE" ]; then
        date +%s > "$START_TIME_FILE"
        echo "[$(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')] セッション開始時刻を記録しました" >> "$USAGE_LOG"
    fi
}

# セッション開始からの経過時間を取得（秒）
get_elapsed_seconds() {
    local start_time=$(cat "$START_TIME_FILE" 2>/dev/null || echo $(date +%s))
    local current_time=$(date +%s)
    echo $((current_time - start_time))
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

# ccusageから使用量データを取得
get_ccusage_data() {
    local ccusage_output=$(npx ccusage@latest 2>/dev/null)
    
    # 今日の日付（MM-DD形式）
    local today_date=$(date +%m-%d)
    
    # 今日のデータ行を探す（opus-4の行）
    local today_line=$(echo "$ccusage_output" | grep -B2 "$today_date" | grep "opus-4" | tail -1)
    
    if [ -n "$today_line" ]; then
        # ANSIエスケープシーケンスを除去
        local clean_line=$(echo "$today_line" | sed 's/\x1b\[[0-9;]*m//g')
        # 8番目のカラム（Total Tokens）を抽出
        local total_tokens=$(echo "$clean_line" | awk -F'│' '{print $8}' | grep -oE '[0-9,]+' | tr -d ',' | tr -d ' ')
        
        if [ -n "$total_tokens" ] && [ "$total_tokens" -gt 0 ]; then
            echo "$total_tokens"
            return 0
        fi
    fi
    
    echo "0"
}

# claude-monitorから使用量データを取得（非対話的）
get_monitor_data() {
    if command -v claude-monitor >/dev/null 2>&1; then
        # claude-monitorを一時的に実行してデータを取得（タイムアウト付き）
        local monitor_output=$(timeout 2 claude-monitor 2>&1 | head -50)
        
        # トークン使用量を探す
        local token_usage=$(echo "$monitor_output" | grep -A1 "Token Usage:" | tail -1 | grep -oE '[0-9,]+' | head -1 | tr -d ',')
        
        if [ -n "$token_usage" ] && [ "$token_usage" -gt 0 ]; then
            echo "$token_usage"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# プロンプト数を推定（簡易計算）
estimate_prompts() {
    local tokens="$1"
    # 平均440トークン/プロンプトで計算（実際の使用量に基づく）
    echo $((tokens / 440))
}

# 使用量チェック関数
check_usage() {
    # セッション開始時刻を初期化
    init_session_time
    
    local current_tokens=""
    local usage_source=""
    
    # まずccusageを試行
    current_tokens=$(get_ccusage_data)
    if [ -n "$current_tokens" ] && [ "$current_tokens" -gt 0 ]; then
        usage_source="ccusage"
    else
        # ccusageが失敗した場合はclaude-monitorを使用
        current_tokens=$(get_monitor_data)
        usage_source="claude-monitor"
    fi
    
    # 使用率を計算
    local token_percentage=0
    if [ "$current_tokens" -gt 0 ]; then
        token_percentage=$(( (current_tokens * 100) / MAX_TOKENS ))
    fi
    
    # プロンプト数を推定
    local prompt_count=$(estimate_prompts "$current_tokens")
    local prompt_percentage=$(( (prompt_count * 100) / MAX_PROMPTS ))
    
    # リセットまでの時間
    local remaining_time=$(get_remaining_time_string)
    
    # ログに記録（日本時間）
    echo "[$(TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S')] トークン: ${current_tokens}/${MAX_TOKENS} (${token_percentage}%), プロンプト: ${prompt_count}/${MAX_PROMPTS} (${prompt_percentage}%), リセットまで: ${remaining_time} (source: $usage_source)" >> "$USAGE_LOG"
    
    # 最も高い使用率を返す
    if [ "$token_percentage" -gt "$prompt_percentage" ]; then
        echo "$token_percentage"
    else
        echo "$prompt_percentage"
    fi
}

# 85%チェック
is_usage_high() {
    local usage="$1"
    if [ -n "$usage" ] && [ "$usage" -ge 85 ]; then
        return 0  # true (使用量が高い)
    else
        return 1  # false (使用量は安全)
    fi
}

# リセット時間チェック（5時間ごと）
should_reset() {
    local elapsed=$(get_elapsed_seconds)
    local reset_seconds=$((RESET_INTERVAL_HOURS * 3600))
    
    # 前回のリセットから5時間経過したか
    if [ $elapsed -ge $reset_seconds ]; then
        # セッション開始時刻を更新
        date +%s > "$START_TIME_FILE"
        return 0  # true (リセットすべき)
    else
        return 1  # false (まだリセット時刻ではない)
    fi
}

# 待機モード
wait_for_reset() {
    local remaining_time=$(get_remaining_time_string)
    echo "⚠️ Claude使用量が85%を超えています。リセットまで${remaining_time}待機します..."
    
    # 進捗表示を待機モードに更新
    /workspace/Demo/scripts/update_progress_status.sh "Manager" "使用量上限により待機中... (リセットまで${remaining_time})" "待機" >/dev/null 2>&1
    
    while true; do
        sleep 60  # 1分間隔でチェック
        
        if should_reset; then
            echo "🔄 リセット時間になりました。使用量を再確認します..."
            local new_usage=$(check_usage)
            
            if ! is_usage_high "$new_usage"; then
                echo "✅ 使用量がリセットされました (${new_usage}%)。作業を再開します。"
                return 0
            fi
        fi
        
        local remaining_time=$(get_remaining_time_string)
        echo "⏰ まだ待機中... リセットまで${remaining_time} ($(TZ=Asia/Tokyo date '+%H:%M:%S'))"
    done
}

# メイン処理
main() {
    local current_usage=$(check_usage)
    
    if [ -z "$current_usage" ]; then
        echo "⚠️ 使用量を取得できませんでした。作業を続行します。"
        return 0
    fi
    
    local remaining_time=$(get_remaining_time_string)
    echo "📊 現在のClaude使用量: ${current_usage}% (リセットまで${remaining_time})"
    
    if is_usage_high "$current_usage"; then
        echo "🚫 使用量が85%を超えています (${current_usage}%)。"
        wait_for_reset
    else
        echo "✅ 使用量は安全範囲内です (${current_usage}%)。作業を開始します。"
    fi
    
    return 0
}

# スクリプトが直接実行された場合
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi