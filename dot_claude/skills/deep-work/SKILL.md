---
name: deep-work
description: 長時間・複雑なタスクを自律的に実行するスキル。「大規模な機能実装」「deep workモードで」などのリクエスト時に使用する。dig→planning-with-files→ralph-loopの順にプラグインを組み合わせて実行する。
---

# Deep Work

長時間タスクを自律実行するためのスキル。

## ワークフロー

```
1. /dig:dig            → タスクの要件・完了条件を明確化
2. /ralph-loop:ralph-loop     → 自律的に実行（コードの場合は簡素化も含む）
```

## 実行手順

### Step 1: 要件の明確化

`/dig:dig` を実行してユーザーのニーズを深堀りする。

確認すべき項目:

- タスクの目標と範囲
- 完了条件（テストが通る、ファイルが生成される等）
- 制約事項

### Step 2: 自律実行

`/ralph-loop` を以下のプロンプトで実行:

```
/ralph-loop:ralph-loop "[タスク説明]

## 作業手順
planning-with-files を利用して作業進捗を管理する

## 完了条件
[/digで確認した完了条件]

## コード簡素化（コードを書くタスクの場合）
完了条件を満たしたら code-simplifier を使って簡素化する
" --max-iterations 30 --completion-promise "DONE"
```

## キャンセル

```
/cancel-ralph:cancel-ralph
```

