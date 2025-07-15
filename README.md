# Claude Development Workflow

4つのClaudeインスタンスを使った協働開発ワークフローシステム

## 概要

このシステムは、CEO、Manager、Developer、Reviewの4つの役割を持つClaudeインスタンスが協働して、アプリケーション開発を行うワークフローです。

## 特徴

- **段階的な品質管理**: 各フェーズで厳格な承認プロセス
- **役割分担の明確化**: 各担当者が専門分野に集中
- **Opusリミット対応**: 開発中断・再開機能
- **汎用性**: 任意のプロジェクトに適用可能

## システム構成

```
CEO (左上・紫)     Manager (右上・オレンジ)
    ↓                  ↓
Review (左下・青)   Developer (右下・緑)
```

### 役割分担

- **CEO**: 戦略的判断・最終承認（作業は行わない）
- **Manager**: プロジェクト管理・情報伝達ハブ（実作業は行わない）
- **Developer**: 実装・文書作成（Opusモデル使用）
- **Review**: 品質チェック・承認（厳格な審査）

## 開発フロー

1. **Phase 1**: 要件定義・外部仕様作成
2. **Phase 2**: 詳細仕様・テスト手順書作成
3. **Phase 3**: 実装・開発
4. **Phase 4**: 総合テスト・完了

## クイックスタート

### 1. planning.txtの準備
```bash
vi WorkFlow/planning.txt
```

### 2. ワークスペース起動
```bash
./setup_claude_workspace.sh
```

### 3. CEOペインで開発開始
```
マネージャーペイン: planning.txtの内容を確認し、要件定義書と外部仕様書の作成を開始してください。
```

詳細な手順は [start.md](start.md) をご参照ください。

## ファイル構成

```
/
├── setup_claude_workspace.sh  # ワークスペース起動スクリプト
├── start.md                   # 初回起動手順
└── WorkFlow/
    ├── planning.txt           # プロジェクト企画書テンプレート
    ├── prompt.txt             # 作業手順書（29手順）
    ├── instructions_ceo.md    # CEO用指示書
    ├── instructions_manager.md # Manager用指示書
    ├── instructions_developer.md # Developer用指示書
    └── instructions_review.md  # Review用指示書
```

## 要件

- tmux
- Claude CLI
- Bash

## 注意事項

- Review↔Developer間の直接やりとりは禁止
- 各段階で必ず承認を得る
- OpusリミットはManager経由で管理
- tmuxセッションを保持して作業継続

## ライセンス

MIT License

## 作成者

Claude Code を使用して作成