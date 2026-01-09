---

## name: deep-work

description: 長時間・複雑なタスクを自律的に実行するスキル。「大規模な機能実装」「リファクタリング」「調査・分析」「deep workモードで」などのリクエスト時に使用する。dig→planning-with-files→ralph-loopの順でプラグインを実行する。

# Deep Work

長時間タスクを自律実行するためのスキル。

## ワークフロー

```
1. /dig            → タスクの要件・完了条件を明確化
2. /ralph-loop     → 自律的に実行
3. /code-simplifier → コードの場合、簡素化（オプション）
```

## 実行手順

### Step 1: 要件の明確化

`/dig` を実行してユーザーのニーズを深堀りする。

確認すべき項目:

- タスクの目標と範囲
- 完了条件（テストが通る、ファイルが生成される等）
- 制約事項

### Step 2: 自律実行

`/ralph-loop` を以下のプロンプトで実行:

```
/ralph-loop "[タスク説明]

## 作業手順
planning-with-files を利用して作業進捗を管理する

## 完了条件
[/digで確認した完了条件]
" --max-iterations 30 --completion-promise "DONE"
```

### Step 3: コード簡素化（オプション）

コードを書くタスクの場合、`/code-simplifier` を実行して簡素化する。

## キャンセル

```
/cancel-ralph
```
