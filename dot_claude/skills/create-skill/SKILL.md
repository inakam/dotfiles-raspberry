---
name: create-skill
description: Claude Codeのスキルを作成するためのスキル。「スキルを作りたい」「新しいスキルを作成して」「○○のスキルを作って」などユーザーがスキル作成を希望したときに使用する。skill-creatorを呼び出してスキル作成を代行する。
---

# Create Skill

ユーザーがスキル作成を希望した際に、skill-creatorを使ってスキルを作成する。

## ワークフロー

1. AskUserQuestionで作成したいスキルの内容を確認
2. Skillツールで`example-skills:skill-creator`を呼び出し
3. skill-creatorの指示に従ってスキルを作成

## 実行コマンド

```
skill-creatorを使って、○○のスキルを作成して。
ユーザーに判断を求める場合はAskUserQuestionツールを使って質問して。
```

※「○○」の部分はユーザーが希望するスキルの内容に置き換える
