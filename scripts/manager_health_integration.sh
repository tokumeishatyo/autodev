#!/bin/bash

# Manager用生存確認統合スクリプト
# 通常の作業フローに生存確認を統合

# 設定
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEALTH_CHECK_SCRIPT="$WORKSPACE_DIR/scripts/health_check.sh"
USAGE_MONITOR_SCRIPT="$WORKSPACE_DIR/scripts/usage_monitor.sh"
LOG_FILE="$WORKSPACE_DIR/logs/manager_health.log"

# 日本時間で現在時刻を取得
current_time() {
    TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S'
}

# ログ出力
log_message() {
    echo "[$(current_time)] $1" | tee -a "$LOG_FILE"
}

# 作業前の事前チェック
pre_work_check() {
    local operation_name="$1"
    
    log_message "作業前チェック開始: $operation_name"
    
    # 1. リミットチェック
    if [ -f "$USAGE_MONITOR_SCRIPT" ]; then
        local usage_output=$("$USAGE_MONITOR_SCRIPT" 2>&1)
        local usage_status=$?
        
        echo "$usage_output"
        
        if [ $usage_status -eq 1 ]; then
            log_message "警告: Claude使用量が上限に近づいています"
            echo "警告: Claude使用量が上限に近づいています。作業を継続しますか？"
            echo "継続する場合は Enter を押してください。待機モードに入る場合は 'standby' と入力してください。"
            read user_input
            
            if [ "$user_input" = "standby" ]; then
                log_message "ユーザー指示により待機モードに移行"
                "$HEALTH_CHECK_SCRIPT" standby
                return 2
            fi
        elif [ $usage_status -eq 2 ]; then
            log_message "Claude使用量が上限に達しました。待機モードに移行します"
            echo "Claude使用量が上限に達しました。待機モードに移行します。"
            echo "復帰可能予測時間: 次回リセット時刻をご確認ください"
            echo "復帰時は /restart コマンドを実行してください"
            "$HEALTH_CHECK_SCRIPT" standby
            return 2
        fi
    fi
    
    # 2. システム生存確認
    if ! "$HEALTH_CHECK_SCRIPT" check > /dev/null 2>&1; then
        log_message "システム異常を検出。復旧を試行します"
        echo "システム異常を検出しました。復旧を試行します..."
        
        if "$HEALTH_CHECK_SCRIPT" recover; then
            log_message "システム復旧成功"
            echo "システム復旧が完了しました。作業を継続します。"
        else
            log_message "システム復旧失敗"
            echo "システム復旧に失敗しました。手動での確認が必要です。"
            return 1
        fi
    fi
    
    log_message "作業前チェック完了: $operation_name"
    return 0
}

# 作業後の事後チェック
post_work_check() {
    local operation_name="$1"
    
    log_message "作業後チェック開始: $operation_name"
    
    # システム状態の確認
    if ! "$HEALTH_CHECK_SCRIPT" check > /dev/null 2>&1; then
        log_message "作業後にシステム異常を検出"
        echo "作業後にシステム異常を検出しました。確認が必要です。"
        return 1
    fi
    
    log_message "作業後チェック完了: $operation_name"
    return 0
}

# 通信前チェック（統合版）
communication_check() {
    local target="$1"
    local message="$2"
    
    log_message "通信前チェック: $target への通信"
    
    # 事前チェック実行
    pre_work_check "通信: $target"
    local check_result=$?
    
    if [ $check_result -eq 2 ]; then
        log_message "待機モードに移行したため通信を中止"
        return 2
    elif [ $check_result -eq 1 ]; then
        log_message "システム異常のため通信を中止"
        return 1
    fi
    
    log_message "通信前チェック完了: $target"
    return 0
}

# 待機モード管理
standby_mode_manager() {
    log_message "待機モード管理を開始"
    
    # 現在の状況を記録
    local current_state_file="$WORKSPACE_DIR/tmp/standby_context.txt"
    
    cat > "$current_state_file" << EOF
=== 待機モード移行時の状況 ===
移行時刻: $(current_time)
最後の作業: $(tail -1 "$WORKSPACE_DIR/logs/communication_log.txt" 2>/dev/null || echo "記録なし")
システム状態: $(cat "$WORKSPACE_DIR/tmp/system_state.txt" 2>/dev/null || echo "unknown")

=== 復帰時の作業予定 ===
1. システム生存確認
2. 前回の作業状況確認
3. 作業再開

復帰方法: /restart コマンドを実行
EOF
    
    echo "=== 待機モードに移行します ==="
    echo "現在の状況を記録しました: $current_state_file"
    echo ""
    echo "【復帰可能予測時間】"
    echo "Claude使用量リセット時刻をご確認ください"
    echo ""
    echo "【復帰方法】"
    echo "復帰可能になりましたら、Managerペインで以下のコマンドを実行してください:"
    echo "/restart"
    echo ""
    echo "待機モードに入ります..."
    
    # Managerペインにフォーカス
    if tmux has-session -t claude_workspace 2>/dev/null; then
        tmux select-pane -t claude_workspace:0.0
    fi
    
    log_message "待機モード移行完了"
}

# 復帰処理
restart_manager() {
    log_message "復帰処理を開始"
    
    # 待機モードから通常モードに移行
    "$HEALTH_CHECK_SCRIPT" restart
    
    # 前回の状況を確認
    local context_file="$WORKSPACE_DIR/tmp/standby_context.txt"
    if [ -f "$context_file" ]; then
        echo "=== 前回の状況 ==="
        cat "$context_file"
        echo ""
        echo "=== 復帰完了 ==="
        echo "システムが復旧しました。作業を再開できます。"
    else
        echo "=== 復帰完了 ==="
        echo "システムが復旧しました。作業を再開できます。"
    fi
    
    log_message "復帰処理完了"
}

# メイン処理
main() {
    # ログディレクトリの作成
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # 引数による処理分岐
    case "${1:-help}" in
        "pre_check")
            pre_work_check "${2:-unknown}"
            ;;
        "post_check")
            post_work_check "${2:-unknown}"
            ;;
        "comm_check")
            communication_check "$2" "$3"
            ;;
        "standby")
            standby_mode_manager
            ;;
        "restart")
            restart_manager
            ;;
        *)
            echo "Manager用生存確認統合スクリプト"
            echo "使用法: $0 {pre_check|post_check|comm_check|standby|restart}"
            echo "  pre_check   - 作業前チェック"
            echo "  post_check  - 作業後チェック"
            echo "  comm_check  - 通信前チェック"
            echo "  standby     - 待機モード移行"
            echo "  restart     - 復帰処理"
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@"