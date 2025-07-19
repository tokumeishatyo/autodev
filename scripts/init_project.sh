#!/bin/bash
# プロジェクト初期化スクリプト
# 新規プロジェクト検知とクリーニング機能

# 設定
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLANNING_FILE="$WORKSPACE_DIR/WorkFlow/planning.txt"
HASH_FILE="$WORKSPACE_DIR/.project_hash"
LOG_DIR="$WORKSPACE_DIR/logs"
TMP_DIR="$WORKSPACE_DIR/tmp"
BACKUP_DIR="$WORKSPACE_DIR/.backup_$(date +%Y%m%d_%H%M%S)"

# 色付きメッセージ関数
print_info() { echo -e "\033[34mℹ️  $1\033[0m"; }
print_warning() { echo -e "\033[33m⚠️  $1\033[0m"; }
print_success() { echo -e "\033[32m✅ $1\033[0m"; }
print_error() { echo -e "\033[31m❌ $1\033[0m"; }

# 日本時間で現在時刻を取得
current_time() {
    TZ=Asia/Tokyo date '+%Y-%m-%d %H:%M:%S'
}

# planning.txtのハッシュ値を取得
get_planning_hash() {
    if [ -f "$PLANNING_FILE" ]; then
        sha256sum "$PLANNING_FILE" | cut -d' ' -f1
    else
        echo ""
    fi
}

# 前回のハッシュ値を取得
get_previous_hash() {
    if [ -f "$HASH_FILE" ]; then
        cat "$HASH_FILE"
    else
        echo ""
    fi
}

# ハッシュ値を保存
save_current_hash() {
    local current_hash=$(get_planning_hash)
    if [ -n "$current_hash" ]; then
        echo "$current_hash" > "$HASH_FILE"
        print_info "プロジェクトハッシュを保存しました"
    fi
}

# 既存ファイルの存在チェック
check_existing_files() {
    local has_logs=false
    local has_tmp=false
    
    # ログファイルの存在チェック
    if [ -f "$LOG_DIR/communication_log.txt" ] && [ -s "$LOG_DIR/communication_log.txt" ]; then
        has_logs=true
    fi
    
    # tmpファイルの存在チェック
    if [ -d "$TMP_DIR" ] && [ -n "$(find "$TMP_DIR" -name "tmp_*.txt" -type f 2>/dev/null)" ]; then
        has_tmp=true
    fi
    
    if $has_logs || $has_tmp; then
        return 0  # 既存ファイルあり
    else
        return 1  # 既存ファイルなし
    fi
}

# ファイルをバックアップ
create_backup() {
    print_info "既存ファイルをバックアップしています..."
    
    mkdir -p "$BACKUP_DIR"
    
    # ログディレクトリのバックアップ
    if [ -d "$LOG_DIR" ]; then
        cp -r "$LOG_DIR" "$BACKUP_DIR/logs" 2>/dev/null
    fi
    
    # tmpディレクトリのバックアップ
    if [ -d "$TMP_DIR" ]; then
        cp -r "$TMP_DIR" "$BACKUP_DIR/tmp" 2>/dev/null
    fi
    
    # セッション状態ファイルのバックアップ
    if [ -f "/tmp/autodev_status/session_start_time.txt" ]; then
        mkdir -p "$BACKUP_DIR/autodev_status"
        cp "/tmp/autodev_status/session_start_time.txt" "$BACKUP_DIR/autodev_status/" 2>/dev/null
    fi
    
    print_success "バックアップ完了: $BACKUP_DIR"
}

# プロジェクトファイルをクリーニング
clean_project_files() {
    print_info "プロジェクトファイルをクリーニングしています..."
    
    # tmpファイルの削除
    if [ -d "$TMP_DIR" ]; then
        rm -f "$TMP_DIR"/tmp_*.txt 2>/dev/null
        rm -f "$TMP_DIR"/system_state.txt 2>/dev/null
        rm -rf "$TMP_DIR/standby" 2>/dev/null
        print_info "tmpファイルをクリーニングしました"
    fi
    
    # ログファイルの削除
    if [ -d "$LOG_DIR" ]; then
        rm -f "$LOG_DIR/communication_log.txt" 2>/dev/null
        rm -f "$LOG_DIR/progress.log" 2>/dev/null
        rm -f "$LOG_DIR/time_tracking_log.txt" 2>/dev/null
        rm -f "$LOG_DIR/current_task.txt" 2>/dev/null
        print_info "ログファイルをクリーニングしました"
    fi
    
    # セッション状態の削除
    rm -f "/tmp/autodev_status/session_start_time.txt" 2>/dev/null
    rm -f "/tmp/autodev_status/claude_usage.log" 2>/dev/null
    print_info "セッション状態をクリーニングしました"
    
    print_success "クリーニング完了"
}

# ユーザー確認プロンプト
prompt_user_action() {
    local situation="$1"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 AutoDev プロジェクト初期化"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    case "$situation" in
        "planning_changed")
            print_warning "planning.txtが前回から変更されています"
            echo "   新しいプロジェクトを開始する可能性があります"
            ;;
        "files_exist")
            print_warning "前回のプロジェクトファイルが残っています"
            echo "   planning.txtに変更はありませんが、既存ファイルがあります"
            ;;
        "both")
            print_warning "planning.txtが変更され、既存ファイルも残っています"
            echo "   新しいプロジェクトまたは既存プロジェクトの選択が必要です"
            ;;
    esac
    
    echo ""
    echo "【既存ファイルの状況】"
    
    # ログファイルの確認
    if [ -f "$LOG_DIR/communication_log.txt" ]; then
        local log_lines=$(wc -l < "$LOG_DIR/communication_log.txt" 2>/dev/null || echo "0")
        local last_log=$(tail -1 "$LOG_DIR/communication_log.txt" 2>/dev/null | cut -c1-60)
        echo "   📋 通信ログ: ${log_lines}行 (最新: ${last_log}...)"
    fi
    
    # tmpファイルの確認
    local tmp_files=$(find "$TMP_DIR" -name "tmp_*.txt" -type f 2>/dev/null | wc -l)
    if [ "$tmp_files" -gt 0 ]; then
        echo "   📁 tmpファイル: ${tmp_files}個"
    fi
    
    echo ""
    echo "【選択してください】"
    echo "1) 🔄 継続 - 既存ファイルをそのまま使用して作業を継続"
    echo "2) 🆕 新規開始 - 既存ファイルをバックアップして新規プロジェクトを開始"
    echo "3) 🗑️  強制削除 - バックアップなしで既存ファイルを削除して新規開始"
    echo "4) ❌ キャンセル - 何も変更せずに終了"
    echo ""
    
    while true; do
        echo -n "選択 (1-4): "
        read -r choice
        
        case "$choice" in
            1)
                print_success "既存プロジェクトを継続します"
                save_current_hash
                return 0
                ;;
            2)
                echo ""
                print_info "新規プロジェクトを開始します（バックアップ付き）"
                create_backup
                clean_project_files
                save_current_hash
                print_success "新規プロジェクトの準備が完了しました"
                return 0
                ;;
            3)
                echo ""
                print_warning "既存ファイルを削除して新規開始します"
                echo -n "本当に削除しますか？ (y/N): "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy] ]]; then
                    clean_project_files
                    save_current_hash
                    print_success "新規プロジェクトの準備が完了しました"
                    return 0
                else
                    print_info "削除をキャンセルしました"
                fi
                ;;
            4)
                print_info "操作をキャンセルしました"
                return 1
                ;;
            *)
                print_error "無効な選択です。1-4を入力してください"
                ;;
        esac
    done
}

# メイン処理
main() {
    echo "$(current_time) - プロジェクト初期化チェックを開始"
    
    # フラグ処理
    local force_clean=false
    local resume_mode=false
    
    for arg in "$@"; do
        case "$arg" in
            --force)
                force_clean=true
                ;;
            --resume)
                resume_mode=true
                ;;
            --help|-h)
                echo "使用方法: $0 [オプション]"
                echo "オプション:"
                echo "  --force   バックアップなしで強制クリーニング"
                echo "  --resume  既存プロジェクトを継続（確認なし）"
                echo "  --help    このヘルプを表示"
                return 0
                ;;
        esac
    done
    
    # planning.txtの存在確認
    if [ ! -f "$PLANNING_FILE" ]; then
        print_error "planning.txtが見つかりません: $PLANNING_FILE"
        return 1
    fi
    
    # 強制クリーニングモード
    if $force_clean; then
        print_warning "強制クリーニングモードで実行"
        clean_project_files
        save_current_hash
        return 0
    fi
    
    # 継続モード
    if $resume_mode; then
        print_info "継続モードで実行"
        save_current_hash
        return 0
    fi
    
    # ハッシュ値の取得
    local current_hash=$(get_planning_hash)
    local previous_hash=$(get_previous_hash)
    
    # 状況判定
    local planning_changed=false
    local files_exist=false
    
    if [ "$current_hash" != "$previous_hash" ] && [ -n "$previous_hash" ]; then
        planning_changed=true
    fi
    
    if check_existing_files; then
        files_exist=true
    fi
    
    # 初回実行（ハッシュファイルなし）
    if [ -z "$previous_hash" ]; then
        if $files_exist; then
            prompt_user_action "files_exist"
        else
            print_info "初回実行を検出しました"
            save_current_hash
            print_success "プロジェクトを初期化しました"
        fi
        return 0
    fi
    
    # 状況に応じた処理
    if $planning_changed && $files_exist; then
        prompt_user_action "both"
    elif $planning_changed; then
        prompt_user_action "planning_changed"
    elif $files_exist; then
        prompt_user_action "files_exist"
    else
        print_info "変更なし - プロジェクトを継続します"
        save_current_hash
    fi
    
    return 0
}

# スクリプトが直接実行された場合
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi