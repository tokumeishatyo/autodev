# 開発ワークフロー 初回起動手順

## 事前準備

### 1. planning.txtの準備
```bash
# planning.txtを編集
vi /workspace/Demo/WorkFlow/planning.txt
```

planning.txtの記入例：
```markdown
# プロジェクト企画書テンプレート

## プロジェクト概要
Webベースのタスク管理アプリケーションを開発したい

## 目的・背景
チーム内のタスク管理を効率化し、進捗の可視化を図りたい

## 要求機能・仕様
- ユーザー登録・ログイン機能
- タスクの作成・編集・削除
- タスクの進捗管理（未着手・進行中・完了）
- チームメンバーへのタスク割り当て
- ダッシュボード画面

## 制約事項
- 開発期間：2ヶ月以内
- 技術スタック：React + Node.js
- 予算制約：特になし

## 期待される成果
- 使いやすいWebアプリケーション
- モバイル対応
- セキュアな認証システム
```

## 初回起動手順

### 1. ワークスペース起動
```bash
cd /workspace/Demo
./setup_claude_workspace.sh
```

### 2. 各ペインの状態確認
起動後、4つのペインで以下が表示されます：
- **CEO（左上・紫）**: instructions_ceo.mdの内容
- **Manager（右上・オレンジ）**: instructions_manager.mdの内容
- **Review（左下・青）**: instructions_review.mdの内容
- **Developer（右下・緑）**: instructions_developer.mdの内容

### 3. CEOペインで作業開始
CEOペインに移動して以下を実行：
```
planning.txtを確認しました。
以下のアプリケーション開発を開始します。

【プロジェクト内容】
Webベースのタスク管理アプリケーション

マネージャーペイン: planning.txtの内容を確認し、要件定義書と外部仕様書の作成を開始してください。
一度で完成させず、議論を重ねて合意を形成していきます。
まずは初期版を作成してください。
```

### 4. 以降は自動的に進行
- ManagerがCEOの指示を受けて要件定義書作成開始
- CEO-Manager間で段階的な議論
- 承認後、Developer・Reviewが順次参加

## ペイン間の移動方法
```bash
# ペイン移動（tmuxのキーバインド）
Ctrl + B, ←  # 左のペインへ
Ctrl + B, →  # 右のペインへ
Ctrl + B, ↑  # 上のペインへ
Ctrl + B, ↓  # 下のペインへ

# または番号で直接移動
Ctrl + B, 0  # CEOペイン（左上）
Ctrl + B, 1  # Managerペイン（右上）
Ctrl + B, 2  # Reviewペイン（左下）
Ctrl + B, 3  # Developerペイン（右下）
```

## Opusリミット対応

### 中断時の操作
```bash
# セッションから離脱（セッションは保持）
Ctrl + B, D

# または端末を閉じる（tmuxセッションはバックグラウンドで継続）
```

### 再開時の操作
```bash
# セッション一覧確認
tmux list-sessions

# 既存セッションに再接続
tmux attach-session -t claude_workspace

# 再接続後、Managerペインで復旧確認を実行
```

## 重要なポイント

1. **planning.txtは具体的に書く** - 曖昧だと要件定義が困難
2. **CEOから開始** - 必ずCEOペインから指示を出す
3. **段階的進行** - 一度に全て決めず、議論を重ねる
4. **各ペインの役割を守る** - 直接やりとりは禁止
5. **tmuxセッションを保持** - 中断・再開時の効率化

## 開発フロー概要

### Phase 1: 要件定義・外部仕様作成（手順3-7）
- CEO初期指示
- Manager要件定義書・外部仕様書作成
- CEO-Manager議論・改善
- CEO最終承認

### Phase 2: 詳細仕様・テスト手順書作成（手順8-15）
- Manager→Developer詳細仕様書作成指示
- Developer作成（実装開始しない）
- Manager→Review文書チェック依頼
- Review厳格チェック実施
- Manager→Developer修正指示（承認まで繰り返し）

### Phase 3: 実装・開発（手順16-21）
- Manager→Developer実装開始指示
- Developer実装（レビュー依頼中は進行停止）
- Manager→Reviewコードレビュー・単体テスト依頼
- Review厳格レビュー実施
- 手順16-20をアプリ完成まで繰り返し

### Phase 4: 総合テスト・完了（手順22-29）
- Manager→Review総合テスト依頼
- Review総合テスト実施
- Manager→CEO完了報告
- Manager→DeveloperREADME.md作成依頼
- Manager→ReviewREADME.mdレビュー依頼
- Manager→CEO最終納品

## ファイル構成
```
/workspace/Demo/
├── setup_claude_workspace.sh （実行スクリプト）
├── start.md （この手順書）
└── WorkFlow/
    ├── planning.txt （プロジェクト企画書テンプレート）
    ├── prompt.txt （作業手順書）
    ├── instructions_ceo.md （CEO用指示書）
    ├── instructions_manager.md （Manager用指示書）
    ├── instructions_developer.md （Developer用指示書）
    └── instructions_review.md （Review用指示書）
```

これで開発プロジェクトが開始されます。最初はCEO→Managerの要件定義段階から始まり、段階的に全体が動き出します。