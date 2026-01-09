---
name: deep-work
description: 長時間・複雑なタスクを自律的に進めるためのスキル。Ralph Loopによる反復実行とファイルベースの計画管理を組み合わせる。「大規模な機能を実装して」「このプロジェクトをリファクタリングして」「調査してまとめて」「長時間タスクを開始」「deep workモードで」などのリクエスト時に使用する。
---

# Deep Work

Ralph Loop + ファイルベース計画で長時間タスクを自律実行する。

## クイックスタート

1. ユーザーにタスク内容・完了条件を確認
2. `task_plan.md` を作成
3. Ralph Loop を起動

## ワークフロー

### Step 1: タスクの明確化

AskUserQuestionで以下を確認:

- タスクの概要と目標
- 完了条件（テストが通る、ファイルが生成される等）
- 最大イテレーション数（デフォルト: 30）

### Step 2: 計画ファイル作成

作業ディレクトリに以下を作成:

**task_plan.md**（必須）:

```markdown
# Task Plan: [タスク名]

## Goal

[最終的に達成したい状態を1文で]

## Completion Criteria

- [ ] [完了条件1]
- [ ] [完了条件2]
- [ ] [完了条件3]

## Phases

- [ ] Phase 1: 調査・設計
- [ ] Phase 2: 実装
- [ ] Phase 3: テスト・検証
- [ ] Phase 4: 完了確認

## Status

**Phase 1進行中** - [現在の作業内容]

## Decisions

- [決定事項]: [理由]

## Errors Encountered

- [エラー]: [解決方法]
```

**notes.md**（任意）:
調査結果や発見事項を蓄積するファイル。

### Step 3: Ralph Loop 起動

```bash
/ralph-loop "[タスク説明]

## 作業手順
1. task_plan.md を読んで現在の状態を把握
2. 次のPhaseを実行
3. task_plan.md を更新（進捗・エラー記録）
4. 完了条件をすべて満たしたら <promise>DONE</promise> を出力

## 完了条件
[具体的な完了条件をリスト]

## 注意事項
- 各Phase完了後に必ず task_plan.md を更新
- エラーは Errors Encountered に記録
- 15イテレーション経過で未完了なら状況を notes.md に記録して続行
" --max-iterations 30 --completion-promise "DONE"
```

## プロンプト例

### 大規模機能開発

```bash
/ralph-loop "REST APIでTodoアプリを実装する

## 作業手順
1. task_plan.md を読む
2. 次のPhaseを実行（設計→実装→テスト）
3. task_plan.md を更新
4. すべてのテストが通ったら <promise>DONE</promise>

## 完了条件
- CRUD操作が動作する
- バリデーションが実装されている
- テストカバレッジ80%以上
- README.md にAPI仕様を記載
" --max-iterations 50 --completion-promise "DONE"
```

### リファクタリング

```bash
/ralph-loop "src/以下のコードをリファクタリングする

## 作業手順
1. task_plan.md を読む
2. 対象ファイルを分析してnotes.mdに記録
3. リファクタリングを実施
4. テストを実行して確認
5. task_plan.md を更新
6. すべてのテストがパスしたら <promise>DONE</promise>

## 完了条件
- 既存テストがすべてパス
- コード重複が解消されている
- 命名規則が統一されている
" --max-iterations 30 --completion-promise "DONE"
```

### 調査・ドキュメント作成

```bash
/ralph-loop "技術調査を行い報告書を作成する

## 作業手順
1. task_plan.md を読む
2. 各ソースを調査してnotes.mdに記録
3. 調査完了後、report.md にまとめる
4. task_plan.md を更新
5. レポートが完成したら <promise>DONE</promise>

## 完了条件
- 3つ以上のソースを調査
- notes.md に調査結果を記録
- report.md に結論・推奨事項を記載
" --max-iterations 20 --completion-promise "DONE"
```

## ループ中のルール

### 毎イテレーション開始時

```
Read task_plan.md  # 現状把握
```

### Phase完了時

```
Edit task_plan.md  # [x]マーク、Status更新
```

### エラー発生時

```
Edit task_plan.md  # Errors Encounteredに記録
```

### 情報蓄積時

```
Write/Edit notes.md  # 調査結果・発見を保存
```

## キャンセル方法

ループを中断する場合:

```bash
/cancel-ralph
```

## アンチパターン

| NG                         | OK                       |
| -------------------------- | ------------------------ |
| 完了条件が曖昧             | 具体的・検証可能な条件   |
| max-iterations未設定       | 適切な上限を設定         |
| task_plan.md未更新         | 毎Phase更新              |
| エラー無視                 | Errors Encounteredに記録 |
| コンテキストに情報詰め込み | ファイルに保存           |
