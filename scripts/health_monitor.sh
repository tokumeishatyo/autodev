#!/bin/bash

# システム生存監視スクリプト
# 定期的な生存確認とClaudeリミット監視を統合

# 設定
WORKSPACE_DIR="/workspace/Demo"
HEALTH_CHECK_SCRIPT="$WORKSPACE_DIR/scripts/health_check.sh"
USAGE_MONITOR_SCRIPT="$WORKSPACE_DIR/scripts/usage_monitor.sh"
LOG_FILE="$WORKSPACE_DIR/logs/health_monitor.log"
STATE_FILE="$WORKSPACE_DIR/tmp/system_state.txt"
MONITOR_PID_FILE="$WORKSPACE_DIR/tmp/health_monitor.pid"

# 監視間隔（秒）
NORMAL_INTERVAL=300      # 通常時: 5分
WORKING_INTERVAL=60      # 作業中: 1分
STANDBY_INTERVAL=600     # 待機中: 10分

# 日本時間で現在時刻を取得
current_time() {
    TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S'
}

# ログ出力
log_message() {
    echo "[$(current_time)] $1" | tee -a "$LOG_FILE"
}

# システム状態を取得
get_system_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "normal"
    fi
}

# 作業中かどうかの判定
is_working() {
    # 最近の通信ログを確認して作業中かどうかを判定
    local recent_activity=$(find "$WORKSPACE_DIR/logs" -name "communication_log.txt" -mmin -10 2>/dev/null)
    if [ -n "$recent_activity" ]; then
        return 0
    else
        return 1
    fi
}

# 監視間隔の決定
get_monitor_interval() {
    local state=$(get_system_state)
    
    case "$state" in
        "standby")
            echo $STANDBY_INTERVAL
            ;;
        "normal")
            if is_working; then
                echo $WORKING_INTERVAL
            else
                echo $NORMAL_INTERVAL
            fi
            ;;
        *)
            echo $NORMAL_INTERVAL
            ;;
    esac
}

# Claudeリミット確認
check_claude_limits() {
    if [ -f "$USAGE_MONITOR_SCRIPT" ]; then
        local usage_result=$("$USAGE_MONITOR_SCRIPT" 2>/dev/null)
        local limit_status=$?
        
        if [ $limit_status -eq 1 ]; then
            log_message "Claudeリミット警告: 使用量が上限に近づいています"
            return 1
        elif [ $limit_status -eq 2 ]; then
            log_message "Claudeリミット到達: 待機モードに移行します"
            "$HEALTH_CHECK_SCRIPT" standby
            return 2
        fi
    fi
    return 0
}

# 総合監視実行
perform_monitoring() {
    log_message "=== 統合監視開始 ==="
    
    # 1. Claudeリミットチェック
    check_claude_limits
    local limit_status=$?
    
    if [ $limit_status -eq 2 ]; then
        log_message "リミット到達のため監視を一時停止"
        return 2
    fi
    
    # 2. システム生存確認
    "$HEALTH_CHECK_SCRIPT" check
    local health_status=$?
    
    if [ $health_status -ne 0 ]; then
        local state=$(get_system_state)
        if [ "$state" != "standby" ]; then
            log_message "システム異常を検出、復旧を試行"
            "$HEALTH_CHECK_SCRIPT" recover
        else
            log_message "待機モード中のため復旧はスキップ"
        fi
    fi
    
    log_message "統合監視完了"
    return 0
}

# 監視ループ
monitoring_loop() {
    log_message "システム監視を開始"
    
    while true; do
        perform_monitoring
        local monitor_result=$?
        
        # 監視間隔の決定
        local interval=$(get_monitor_interval)
        local state=$(get_system_state)
        
        log_message "次回監視まで${interval}秒待機 (状態: $state)"
        
        # 待機モードでリミット到達の場合は監視を一時停止
        if [ $monitor_result -eq 2 ]; then
            log_message "リミット到達のため監視を一時停止します"
            break
        fi
        
        sleep $interval
    done
    
    log_message "システム監視を終了"
}

# 監視の開始
start_monitoring() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local existing_pid=$(cat "$MONITOR_PID_FILE")
        if ps -p "$existing_pid" > /dev/null 2>&1; then
            log_message "監視は既に実行中です (PID: $existing_pid)"
            return 1
        else
            log_message "古いPIDファイルを削除"
            rm -f "$MONITOR_PID_FILE"
        fi
    fi
    
    log_message "バックグラウンドで監視を開始"
    monitoring_loop &
    local monitor_pid=$!
    echo $monitor_pid > "$MONITOR_PID_FILE"
    log_message "監視プロセス開始 (PID: $monitor_pid)"
    
    return 0
}

# 監視の停止
stop_monitoring() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local monitor_pid=$(cat "$MONITOR_PID_FILE")
        if ps -p "$monitor_pid" > /dev/null 2>&1; then
            log_message "監視プロセスを停止中 (PID: $monitor_pid)"
            kill "$monitor_pid"
            rm -f "$MONITOR_PID_FILE"
            log_message "監視プロセスを停止しました"
        else
            log_message "監視プロセスは既に停止しています"
            rm -f "$MONITOR_PID_FILE"
        fi
    else
        log_message "監視プロセスのPIDファイルが見つかりません"
    fi
}

# 監視状態の確認
status_monitoring() {
    if [ -f "$MONITOR_PID_FILE" ]; then
        local monitor_pid=$(cat "$MONITOR_PID_FILE")
        if ps -p "$monitor_pid" > /dev/null 2>&1; then
            log_message "監視プロセス実行中 (PID: $monitor_pid)"
            local state=$(get_system_state)
            log_message "システム状態: $state"
            return 0
        else
            log_message "監視プロセスは停止しています"
            return 1
        fi
    else
        log_message "監視プロセスは実行されていません"
        return 1
    fi
}

# メイン処理
main() {
    # ログディレクトリの作成
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$(dirname "$MONITOR_PID_FILE")"
    
    # 引数による処理分岐
    case "${1:-start}" in
        "start")
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "restart")
            stop_monitoring
            sleep 2
            start_monitoring
            ;;
        "status")
            status_monitoring
            ;;
        "check")
            perform_monitoring
            ;;
        *)
            echo "使用法: $0 {start|stop|restart|status|check}"
            echo "  start   - 監視を開始"
            echo "  stop    - 監視を停止"
            echo "  restart - 監視を再開"
            echo "  status  - 監視状態を確認"
            echo "  check   - 一回だけ監視実行"
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"