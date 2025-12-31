---
name: deodorizing-code
description: AI生成コードの冗長性・複雑性を検出し、リファクタリングを行うスキル。「コードを脱臭して」「AIコードをリファクタリング」「冗長なコードを簡潔にして」「このコードを最適化」「複雑度を下げて」などのリクエストで起動する。Python/JavaScript/TypeScriptの生成コードに対して、ガード節の適用、DRY原則の強制、認知的複雑度の低減を実施する。
---

# コード脱臭スキル

AI生成コードに特有の「悪臭（Code Smells）」を検出し、体系的にリファクタリングする。

## ワークフロー概要

```
1. 対象コードの特定（通常: ブランチの変更点）
2. 悪臭の検出・分析
3. リファクタリング計画の策定
4. 段階的な脱臭の実施
5. 結果の検証
```

## ステップ1: 対象コードの特定

### 推奨: ブランチの変更点を対象にする

通常は現在のブランチで変更されたコードのみを脱臭する。

```bash
# ベースブランチとの差分ファイル一覧を取得
git diff --name-only main...HEAD

# 変更内容の確認
git diff main...HEAD -- [file]
```

**手順:**

1. `git diff --name-only main...HEAD` で変更ファイル一覧を取得
2. 各ファイルをReadツールで読み込み、変更箇所を重点的に分析
3. 新規追加されたコードを優先的に脱臭

> **注意**: ベースブランチは `main` または `master`、プロジェクトによっては `develop` を使用

### その他の対象指定方法

- ユーザーがファイルパスを指定 → Readツールで読み込み
- ユーザーがコードを直接貼り付け → そのまま分析
- ディレクトリ指定 → 対象言語のファイルを列挙

### 対象言語の確認

- Python: `.py`
- Rust: `.rs`
- JavaScript: `.js`, `.jsx`
- TypeScript: `.ts`, `.tsx`
- Go: `.go`
- その他: ユーザーが指定した言語でのファイルを対象にする

## ステップ2: 悪臭の検出・分析

対象コードを以下の観点で分析する。詳細は[code-smells.md](references/code-smells.md)を参照。

### 検出対象の悪臭カテゴリ

| カテゴリ       | 症状                                 | 優先度   |
| :------------- | :----------------------------------- | :------- |
| 認知的複雑度   | 深いネスト、複雑な分岐               | Critical |
| 冗長性         | 不要な行数、手動ループ               | Critical |
| 幻覚による依存 | 存在しないライブラリのインポート     | Critical |
| セキュリティ   | ハードコードされたシークレット       | Critical |
| 不要なコメント | 自明なコード説明、チュートリアル形式 | Warning  |
| 型安全性不足   | any型の使用、型ヒント不足            | Warning  |
| DRY違反        | 重複ロジック                         | Warning  |
| ゾンビコード   | 未使用変数、到達不能分岐             | Warning  |
| 防御的肥大化   | 不要なnullチェック、try-catch        | Info     |

### 分析レポート形式

```markdown
## 悪臭分析レポート

**ファイル**: {ファイル名}
**行数**: {総行数}
**検出した悪臭**: {件数}

### Critical

- {行番号}: {悪臭の種類} - {説明}

### Warning

- {行番号}: {悪臭の種類} - {説明}

### Info

- {行番号}: {悪臭の種類} - {説明}
```

## ステップ3: リファクタリング計画

検出した悪臭に対して、適用すべきリファクタリングパターンを提案する。
詳細は[refactoring-patterns.md](references/refactoring-patterns.md)を参照。

### 主要なリファクタリング手法

1. **ガード節の適用** - ネストの平坦化
2. **メソッド抽出** - DRY原則の強制
3. **マップルックアップ** - 条件分岐の簡素化
4. **言語イディオム** - Pythonic/モダンJS化

## ステップ4: 段階的な脱臭

### 実施順序

1. Critical問題を優先的に修正
2. 各修正は1つずつ適用
3. 修正ごとにユーザーに確認（必要な場合）

### Python向け脱臭

```python
# Before: 命令型ループ
result = []
for x in items:
    if x > 0:
        result.append(x * 2)

# After: リスト内包表記
result = [x * 2 for x in items if x > 0]
```

```python
# Before: 深いネスト
def process(data):
    if data:
        if data.is_valid:
            if data.has_permission:
                return do_something(data)
    return None

# After: ガード節
def process(data):
    if not data:
        return None
    if not data.is_valid:
        return None
    if not data.has_permission:
        return None
    return do_something(data)
```

### JavaScript/TypeScript向け脱臭

```typescript
// Before: 順次await
const user = await getUser();
const posts = await getPosts();

// After: 並列await（独立している場合）
const [user, posts] = await Promise.all([getUser(), getPosts()]);
```

```typescript
// Before: switch文
function getPrice(type: string): number {
  switch (type) {
    case "apple":
      return 1.0;
    case "banana":
      return 0.5;
    default:
      return 0;
  }
}

// After: マップルックアップ
const prices: Record<string, number> = {
  apple: 1.0,
  banana: 0.5,
};
const getPrice = (type: string): number => prices[type] ?? 0;
```

### 幻覚による依存の検出

AIは存在しないライブラリや関数をインポートすることがある。

```python
# 悪臭: 存在しないライブラリ
from utils.helpers import format_data  # utils.helpersは存在しない
import company_internal_lib  # 幻覚されたパッケージ

# 対処: インポートの存在確認
# 1. pip show [package] または npm list [package] で確認
# 2. 標準ライブラリまたは明示的にインストール済みのパッケージのみ使用
```

### セキュリティ問題の検出

```python
# 悪臭: ハードコードされたシークレット
API_KEY = "sk-1234567890abcdef"  # Critical: 環境変数へ移動
password = "admin123"  # Critical: 設定ファイルへ

# 悪臭: SQLインジェクション
query = f"SELECT * FROM users WHERE id = {user_id}"  # Critical

# 脱臭後
API_KEY = os.environ.get("API_KEY")
query = "SELECT * FROM users WHERE id = ?"  # パラメータ化クエリ
```

### 型安全性の強制

```typescript
// 悪臭: any型の乱用
function process(data: any): any {
  // Warning
  return data.value;
}

// 脱臭後: 適切な型定義
interface Data {
  value: string;
}
function process(data: Data): string {
  return data.value;
}
```

```python
# 悪臭: 型ヒントなし
def process(data):
    return data["value"]

# 脱臭後: 型ヒント追加
def process(data: dict[str, Any]) -> str:
    return data["value"]
```

### コンテキストマネージャの使用（Python）

```python
# 悪臭: リソースの手動管理
f = open("file.txt")
try:
    content = f.read()
finally:
    f.close()

# 脱臭後: with文
with open("file.txt") as f:
    content = f.read()
```

### 不要なコメントの脱臭

AIは以下のような不要なコメントを生成しがち。これらは削除する。

**削除対象のコメント:**

```python
# 悪臭: 自明なコメント
i += 1  # iを1増やす
return result  # 結果を返す
user = get_user(id)  # ユーザーを取得

# 悪臭: チュートリアル形式の説明
# まず、データを取得します
data = fetch_data()
# 次に、データを処理します
processed = process(data)
# 最後に、結果を返します
return processed
```

**脱臭後:**

```python
i += 1
return result
user = get_user(id)

data = fetch_data()
processed = process(data)
return processed
```

**残すべきコメント:**

- **Why（なぜ）** を説明するコメント（ビジネスロジックの理由）
- 複雑なアルゴリズムの概要説明
- TODO/FIXME/HACK等の注意喚起
- 正規表現やマジックナンバーの説明

```python
# 良いコメント例
# 税率は2024年の法改正に基づく
TAX_RATE = 0.10

# RFC 5322準拠のメールアドレス検証
EMAIL_REGEX = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

# TODO: キャッシュ機構を追加してパフォーマンス改善
def fetch_user(id: int) -> User:
    return db.query(User).get(id)
```

## ステップ5: 結果の検証

### 検証項目

- [ ] 認知的複雑度が10以下
- [ ] 重複コードが排除されている
- [ ] 未使用コードが削除されている
- [ ] 言語イディオムに従っている
- [ ] 自明なコメントが削除されている
- [ ] 存在しないインポートがない
- [ ] ハードコードされたシークレットがない
- [ ] 適切な型定義がされている

### 脱臭完了レポート

```markdown
## 脱臭完了レポート

**対象**: {ファイル名}
**Before**: {修正前行数}行
**After**: {修正後行数}行
**削減率**: {削減率}%

### 実施した修正

1. {修正内容}
2. {修正内容}

### 残存する課題（あれば）

- {課題}
```

## 静的解析ツールとの連携

> **注意**: ツールがインストールされていない場合は、手動リファクタリングのみ実施する

### Python

```bash
# Ruffで自動修正
ruff check --fix {file}

# 複雑度チェック
ruff check --select C901 {file}
```

### JavaScript/TypeScript

```bash
# ESLintで自動修正
npx eslint --fix {file}
```

## 注意事項

- 機能の変更は行わない（リファクタリングのみ）
- テストがある場合は修正後にテスト実行を推奨
- 大規模な変更は段階的に実施
