# ログ機能について

## 概要
このワークフローシステムでは、各役割（CEO、Manager、Reviewer、Developer）の活動を自動的にログ出力する機能を提供しています。

## ログの種類

### 1. 全体活動ログ (`activity_log.txt`)
すべての役割の以下のツール使用がログされます：
- **Task** - タスク実行
- **TodoWrite** - Todo管理
- **Write** - ファイル作成
- **MultiEdit** - 複数ファイル編集
- **Edit** - ファイル編集

### 2. Developer専用作業ログ (`developer_work_log.txt`)
Developerが以下のファイルを操作した場合に詳細ログが記録されます：
- `coding_log*` - コーディング記録
- `work_notes*` - 作業メモ
- `detailed_spec*` - 詳細仕様書
- `unit_test*` - 単体テスト関連
- `integration_test*` - 統合テスト関連

## ログ設定

### 設定ファイル
`.claude/settings.local.json`にhooksが設定されています：

```json
{
  "hooks": {
    "on_tool_call": {
      "command": "bash",
      "args": ["全体活動ログ出力コマンド"]
    },
    "on_tool_result": {
      "command": "bash",
      "args": ["Developer作業ログ出力コマンド"]
    }
  }
}
```

## ログ出力例

### 全体活動ログ
```
[2024-07-15 14:30:15] Write - /workspace/Demo/requirements.md
[2024-07-15 14:32:20] TodoWrite - Action executed
[2024-07-15 14:35:45] Edit - /workspace/Demo/external_spec.md
```

### Developer作業ログ
```
[2024-07-15 15:10:30] Developer Work Log - coding_log.md: Implementation progress
[2024-07-15 15:25:15] Developer Work Log - detailed_spec.md: File modified
[2024-07-15 15:40:22] Developer Work Log - unit_test_plan.md: Test case creation
```

## 注意事項

1. **自動生成** - ログは自動的に生成されます
2. **Git除外** - ログファイルは`.gitignore`に含まれています
3. **タイムスタンプ** - すべてのログにタイムスタンプが付きます
4. **ファイル追記** - 既存のログファイルに追記されます

## トラブルシューティング

### ログが出力されない場合
1. `jq`コマンドがインストールされているか確認
2. `.claude/settings.local.json`の書式が正しいか確認
3. ファイルの書き込み権限があるか確認

### ログファイルの初期化
```bash
# ログファイルを初期化する場合
rm -f /workspace/Demo/activity_log.txt
rm -f /workspace/Demo/developer_work_log.txt
```