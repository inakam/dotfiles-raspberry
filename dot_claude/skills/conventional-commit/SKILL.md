---
name: conventional-commit
description: Gitの変更を検出してConventional Commits形式で日本語コミットメッセージを自動生成・実行するスキル。コード変更後やユーザーが「コミットして」「変更を保存」などと発言したときに使用する。git add、git commit、変更の分析を含む。
---

# Conventional Commit

変更を分析し、Conventional Commits形式で日本語コミットメッセージを生成してコミットする。

## 基本方針

**レビューしやすい粒度でコミットを分割する。**

- 1コミット = 1つの論理的な変更単位
- 機能追加、バグ修正、リファクタリングは別コミット
- 関連するファイルのみをまとめる
- 大きな変更は複数の小さなコミットに分割

## ワークフロー

### Phase 1: 計画

1. `git status`で全変更ファイルを確認
2. `git diff`で全差分を確認
3. `git log --oneline -5`で直近のコミットスタイルを確認
4. 変更をレビューしやすい粒度でグループ化し、コミット計画を作成
5. AskUserQuestionでコミット計画をユーザーに確認

### Phase 2: 実行（計画の各コミットに対して繰り返し）

1. 対象ファイルの差分を`git diff <files>`で確認
2. Conventional Commit形式のメッセージを生成
3. AskUserQuestionでメッセージをユーザーに確認
4. 承認後、`git add <files>`と`git commit`を実行
5. 次のコミットへ（全コミット完了まで繰り返し）

## Conventional Commits形式

```
<type>(<scope>): <subject>
```

### type一覧

| type     | 用途                                                 |
| -------- | ---------------------------------------------------- |
| feat     | 新機能追加                                           |
| fix      | バグ修正                                             |
| docs     | ドキュメントのみの変更                               |
| style    | コードの意味に影響しない変更（空白、フォーマット等） |
| refactor | バグ修正でも機能追加でもないコード変更               |
| perf     | パフォーマンス改善                                   |
| test     | テストの追加・修正                                   |
| build    | ビルドシステムや外部依存の変更                       |
| ci       | CI設定ファイルの変更                                 |
| chore    | その他の変更（ソースやテストに影響しない）           |
| revert   | 以前のコミットを取り消す                             |

### 例（日本語）

```bash
git commit -m "feat(auth): JWTトークンのリフレッシュ機能を追加"
git commit -m "fix(api): nullレスポンス時のエラーハンドリングを修正"
git commit -m "docs(readme): インストール手順を追記"
git commit -m "refactor(core): バリデーションロジックを共通化"
git commit -m "test(user): ユーザー登録のテストケースを追加"
```

## 注意事項

- scopeは省略可能。ファイルやモジュール名から推測
- subjectは命令形ではなく「〜を追加」「〜を修正」のような体言止め
- .envやcredentials.jsonなどの機密ファイルはコミット対象外とする
