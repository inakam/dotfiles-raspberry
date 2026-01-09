---
name: deep-work
description: 長時間・複雑なタスクを自律的に進めるためのスキル。Ralph Loopによる反復実行とplanning-with-filesプラグインのファイルベース計画管理を組み合わせる。「大規模な機能を実装して」「このプロジェクトをリファクタリングして」「調査してまとめて」「長時間タスクを開始」「deep workモードで」などのリクエスト時に使用する。
---

# Deep Work

Ralph Loop + planning-with-files で長時間タスクを自律実行する。

## クイックスタート

1. ユーザーにタスク内容・完了条件を確認
2. `/planning-with-files` で計画ファイルを初期化
3. Ralph Loop を起動

## ワークフロー

### Step 1: タスクの明確化

AskUserQuestionで以下を確認:

- タスクの概要と目標
- 完了条件（テストが通る、ファイルが生成される等）
- 最大イテレーション数（デフォルト: 30）

### Step 2: 計画ファイル初期化

`/planning-with-files` スキルを呼び出して3ファイルを作成:

| File           | Purpose                      |
| -------------- | ---------------------------- |
| `task_plan.md` | フェーズ管理、進捗、決定事項 |
| `findings.md`  | 調査結果、発見事項           |
| `progress.md`  | セッションログ、テスト結果   |

### Step 3: Ralph Loop 起動

```bash
/ralph-loop "[タスク説明]

## 作業手順
1. task_plan.md を読んで現在の状態を把握
2. 次のPhaseを実行
3. task_plan.md, progress.md を更新（進捗・エラー記録）
4. 発見事項は findings.md に記録
5. 完了条件をすべて満たしたら <promise>DONE</promise> を出力

## 完了条件
[具体的な完了条件をリスト]

## 重要ルール
- 2アクションルール: 2回の操作ごとに必ず発見事項をファイルに保存
- 3ストライクルール: 同じエラーで3回失敗したらユーザーに相談
- 同じ失敗アクションを繰り返さない
" --max-iterations 30 --completion-promise "DONE"
```

## プロンプト例

### 大規模機能開発

```bash
/ralph-loop "REST APIでTodoアプリを実装する

## 作業手順
1. task_plan.md を読む
2. 次のPhaseを実行（設計→実装→テスト）
3. task_plan.md, progress.md を更新
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
2. 対象ファイルを分析してfindings.mdに記録
3. リファクタリングを実施
4. テストを実行してprogress.mdに結果を記録
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
2. 各ソースを調査してfindings.mdに記録（2アクションルール厳守）
3. 調査完了後、report.md にまとめる
4. progress.md に進捗を記録
5. レポートが完成したら <promise>DONE</promise>

## 完了条件
- 3つ以上のソースを調査
- findings.md に調査結果を記録
- report.md に結論・推奨事項を記載
" --max-iterations 20 --completion-promise "DONE"
```

## planning-with-files の重要ルール

### 2アクションルール

> 2回のview/browser/search操作ごとに、必ず発見事項をファイルに保存

視覚情報・マルチモーダル情報はすぐに失われるため。

### 3ストライクエラープロトコル

```
ATTEMPT 1: 診断して修正
ATTEMPT 2: 別のアプローチを試す（同じ失敗を繰り返さない）
ATTEMPT 3: 前提を疑い、計画を見直す
3回失敗後: ユーザーに相談
```

### 5つの質問テスト

以下に答えられれば状態管理は正常:

| 質問           | 回答元                      |
| -------------- | --------------------------- |
| 今どこにいる？ | task_plan.md の現在フェーズ |
| どこへ向かう？ | 残りのフェーズ              |
| ゴールは？     | task_plan.md のGoal         |
| 何を学んだ？   | findings.md                 |
| 何をした？     | progress.md                 |

## キャンセル方法

```bash
/cancel-ralph
```

## アンチパターン

| NG                         | OK                     |
| -------------------------- | ---------------------- |
| 完了条件が曖昧             | 具体的・検証可能な条件 |
| max-iterations未設定       | 適切な上限を設定       |
| ファイル更新を忘れる       | 2アクションルール厳守  |
| 同じエラーで何度もリトライ | 3ストライクルール      |
| コンテキストに情報詰め込み | ファイルに保存         |
