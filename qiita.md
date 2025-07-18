# 4つのClaudeインスタンスによる協働開発ワークフローシステム「autodev」

## はじめに

チーム開発において、要件定義から実装、レビューまでの一連のプロセスを効率的に管理することは常に課題となっています。本記事では、4つのClaudeインスタンスを異なる役割に割り当てて協働させる開発ワークフローシステム「autodev」について紹介します。

## autodevとは

autodevは、CEO、Manager、Developer、Reviewerの4つの役割を持つClaudeインスタンスが協働して、アプリケーション開発を行うワークフローシステムです。tmuxを使用した6ペイン構成により、開発プロセス全体を可視化しながら進めることができます。

## 主な特徴

### 1. 役割分担による品質管理

```
CEO (左上・紫)        Reviewer (中上・青)      Progress (右上・白)
    ↓                     ↓                     ↓
Manager (左下・オレンジ)   Developer (中下・緑)    Usage (右下・金)
```

各役割には明確な責任範囲があり、直接的なやり取りは禁止されています。これにより、適切な承認プロセスと品質管理が実現されています。

### 2. GitHub連携によるブランチ戦略

```bash
# feature/[機能名]ブランチでの作業
git checkout -b feature/user-authentication
# 実装後はプルリクエストを作成
gh pr create --title "ユーザー認証機能の実装"
```

mainブランチは保護され、すべての変更はプルリクエスト経由でマージされます。

### 3. Opusリミット対応

Claude使用量が85%を超えると自動的に待機モードに入り、安全な作業継続を実現します。tmuxセッションは保持されるため、制限解除後すぐに作業を再開できます。

### 4. 自動ログと時間分析

```bash
# 開発完了後の時間分析
./scripts/analyze_logs.sh

# 分析結果例
=== 推定作業時間 ===
総推定作業時間: 1h 50m
  - Phase 1 (要件定義): 30m
  - Phase 2 (実装): 1h 0m
  - Phase 3 (テスト): 20m
```

## 使い方

### 1. 事前準備

```bash
# GitHub CLI認証
gh auth login

# プロジェクト企画書の作成
vi /workspace/Demo/WorkFlow/planning.txt
```

### 2. ワークスペース起動

```bash
cd /workspace/Demo
./setup_claude_workspace.sh
```

### 3. GitHub初期化（CEOが手動実行）

```bash
# テンプレートクローン
git clone https://github.com/tokumeishatyo/autodev.git [プロジェクト名]
cd [プロジェクト名]

# 新規プロジェクトとして初期化
rm -rf .git
git init
git add .
git commit -m "Initial commit from autodev template"
git remote add origin https://github.com/[USERNAME]/[プロジェクト名].git
git push -u origin main
```

### 4. 開発フロー

自動的にCEOペインから開始され、以下のフェーズを経て開発が進行します：

1. **Phase 1**: 要件定義・外部仕様作成
2. **Phase 2**: 詳細仕様・テスト手順書作成
3. **Phase 3**: 実装・開発
4. **Phase 4**: 総合テスト・プルリクエスト
5. **Phase 5**: 完了・納品

## 監視システム

### 進捗監視（Progressペイン）

```
💭 思考中... (3分経過) ●○○
📝 文書作成中... (7分経過) ●●○
💻 コード作成中... (12分経過) ●●●
```

メッセージ内容から作業種別を自動判定し、リアルタイムで進捗を表示します。

### 使用量監視（Usageペイン）

```
=== Claude使用量モニター ===
📅 更新時刻: 2025-07-17 14:30:15
✅ 使用量: 45% (安全)
💚 状態: 正常動作中
```

使用量が85%を超えると自動的に待機モードに移行し、作業の中断を防ぎます。

## 実際の利用例

タスク管理アプリケーションの開発を例に、planning.txtを以下のように記述します：

```markdown
## プロジェクト概要
Webベースのタスク管理アプリケーションを開発したい

## 要求機能・仕様
- ユーザー登録・ログイン機能
- タスクの作成・編集・削除
- タスクの進捗管理（未着手・進行中・完了）
- チームメンバーへのタスク割り当て
```

このように記述することで、CEOからManagerへ指示が伝達され、段階的に開発が進行します。

## まとめ

autodevは、複数のClaudeインスタンスの協働により、品質管理と効率性を両立した開発ワークフローを実現します。GitHub連携、自動ログ、時間分析など、実践的な機能により、個人開発からチーム開発まで幅広く活用できます。

プルリクエストやIssueをいただいても対応できないので、ご自由にフォークされてご使用ください。

https://github.com/tokumeishatyo/autodev

## 参考情報

- tmux
- Claude CLI
- GitHub CLI (gh)
- Bash
- jq

## ライセンス

MIT License