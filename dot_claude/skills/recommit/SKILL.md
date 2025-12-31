---
name: recommit
description: ベースブランチからの差分コミットをリセットし、レビューしやすい粒度でコミットしなおすスキル。「コミットを整理して」「コミットをやり直して」「recommitして」「developからの差分で整理して」などと発言したときに使用する。git reset --softでコミットを一旦リセットし、論理的な単位で再コミットする。ベースブランチはデフォルトでmain/masterだが、ユーザー指定も可能。
---

# Recommit

ベースブランチからの差分コミットをリセットし、レビューしやすい粒度でコミットしなおす。

## ワークフロー

### Phase 1: 現状確認

1. ベースブランチを特定（ユーザー指定があればそれを使用、なければmain/masterを自動検出）
   ```bash
   # ユーザー指定がない場合
   git branch -r | grep -E 'origin/(main|master)$' | head -1
   ```
2. ベースブランチからの差分コミットを確認
   ```bash
   git log --oneline <base-branch>..HEAD
   ```
3. 差分の全体像を確認
   ```bash
   git diff <base-branch>..HEAD --stat
   ```
4. AskUserQuestionで現状をユーザーに報告し、リセットの確認を取る

### Phase 2: リセット

1. ベースブランチとの分岐点を特定
   ```bash
   git merge-base <base-branch> HEAD
   ```
2. git reset --softでコミットをリセット
   ```bash
   git reset --soft <merge-base-commit>
   ```
3. リセット後の状態を確認
   ```bash
   git status
   ```

### Phase 3: 再コミット

1. `git diff --cached`でステージされた全差分を確認
2. 変更をレビューしやすい粒度でグループ化し、コミット計画を作成
3. AskUserQuestionでコミット計画をユーザーに確認
4. 計画に従って順次コミット実行
   - `git reset HEAD`で一旦アンステージ
   - 各コミット単位でファイルをステージして`git commit`

## コミット粒度の基準

- 1コミット = 1つの論理的な変更単位
- 機能追加、バグ修正、リファクタリングは別コミット
- 関連するファイルのみをまとめる
- テストコードは対応する実装と同じコミット

## Conventional Commits形式

```
<type>(<scope>): <subject>
```

| type     | 用途                             |
| -------- | -------------------------------- |
| feat     | 新機能追加                       |
| fix      | バグ修正                         |
| docs     | ドキュメントのみの変更           |
| style    | フォーマット等の変更             |
| refactor | バグ修正でも機能追加でもない変更 |
| test     | テストの追加・修正               |
| chore    | その他の変更                     |

## 注意事項

- リセット前に必ずユーザーの確認を取る
- リモートにpush済みのコミットの場合、再コミット後に`git push --force-with-lease`が必要になることを事前に警告する
- .envやcredentials.jsonなどの機密ファイルはコミット対象外とする
