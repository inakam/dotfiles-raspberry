---
name: create-pr
description: GitHub PRを作成するスキル。ブランチの変更を分析し、構造化されたPR本文を生成して`gh pr create`で作成する。「PRを作成して」「プルリクエストを作って」「PR出して」などの発言時に使用する。リポジトリ内のPRテンプレートがあれば参照する。
---

# Create PR

ブランチの変更を分析し、GitHub PRを作成する。

## ワークフロー

### Phase 1: 情報収集

1. `git status`で未コミットの変更を確認（あれば先にコミットを促す）
2. `git log origin/main..HEAD --oneline`でコミット一覧を取得
3. `git diff origin/main...HEAD`で全変更差分を確認
4. PRテンプレートを検索（`.github/PULL_REQUEST_TEMPLATE.md`または`.github/pull_request_template.md`）

### Phase 2: PR本文生成

テンプレートがある場合はそれに従い、ない場合は以下の形式で生成：

```markdown
## 概要 (Summary)

[変更の要約を1-2文で記述]

## 関連Issue (Related Issues)

- fix #[Issue番号]

## 変更内容 (What changed?)

- [具体的な変更点をリスト形式で]

## なぜ変更したか (Why?)

[変更の背景・理由を記述]

## 動作確認 (Verification)

[テスト方法や確認手順]

## 特記事項 / 懸念点 (Notes / Concerns)

[レビュアーに伝えたい点があれば記述]

## チェックリスト (Checklist)

- [ ] セルフレビューを実施した
- [ ] 自動テストが通っている
- [ ] UIの動作確認を実施した
```

### Phase 3: ユーザー確認

AskUserQuestionでPRのタイトルと本文を確認：

- タイトル案を提示
- 本文案を提示
- 修正があれば反映

### Phase 4: PR作成

```bash
gh pr create --title "タイトル" --body "$(cat <<'EOF'
本文
EOF
)"
```

作成後、PR URLをユーザーに提示する。

## 注意事項

- 未プッシュのコミットがあれば先に`git push -u origin <branch>`を実行
- ベースブランチはデフォルトでmain（必要に応じて変更）
- ドラフトPRが必要な場合は`--draft`オプションを追加
