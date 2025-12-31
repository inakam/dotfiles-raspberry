# AI生成コードの悪臭カタログ

AI生成コードに特有の悪臭パターンとその検出方法。

## 目次

1. [認知的複雑度](#認知的複雑度)
2. [実装の冗長性](#実装の冗長性)
3. [不要なコメント](#不要なコメント)
4. [幻覚による依存](#幻覚による依存)
5. [セキュリティ問題](#セキュリティ問題)
6. [型安全性不足](#型安全性不足)
7. [DRY違反](#dry違反)
8. [ゾンビコード](#ゾンビコード)
9. [防御的肥大化](#防御的肥大化)
10. [抽象化の破綻](#抽象化の破綻)

---

## 認知的複雑度

### 症状

- 深くネストされたif/else連鎖
- 複雑な条件式（3つ以上の論理演算子）
- 大きなswitch文（5ケース以上）

### 検出パターン

```python
# 悪臭: アローコード（矢印型のネスト）
if condition1:
    if condition2:
        if condition3:
            if condition4:
                do_something()  # ネスト深度4
```

```javascript
// 悪臭: 複雑な条件式
if ((a && b) || (c && !d) || (e && f)) {
  // 理解困難
}
```

### 検出基準

- ネスト深度 > 3: Warning
- ネスト深度 > 4: Critical
- サイクロマティック複雑度 > 10: Critical

---

## 実装の冗長性

### 症状

- 組み込み関数で置換可能な手動ループ
- 過剰なコメント（自明なコードへの説明）
- チュートリアル形式のステップバイステップ実装

### 検出パターン

```python
# 悪臭: 手動ループ（sum()で置換可能）
total = 0
for item in items:
    total += item

# 悪臭: 手動ループ（all()で置換可能）
result = True
for item in items:
    if not item.is_valid:
        result = False
        break
```

```javascript
// 悪臭: forEach+push（mapで置換可能）
const results = [];
items.forEach((item) => {
  results.push(item * 2);
});

// 悪臭: 冗長なコメント
// iを1増やす
i += 1;
```

### 検出基準

- 3行以上のループが組み込み関数で1行に置換可能: Warning
- 自明なコードへのコメント: Info

---

## 不要なコメント

### 症状

- コードの動作をそのまま言い換えたコメント
- チュートリアル形式の「まず〜次に〜最後に」説明
- 関数名や変数名と同じ内容の繰り返し
- 過剰なdocstring（自明なパラメータの説明）

### 検出パターン

```python
# 悪臭: コードの言い換え
x = x + 1  # xに1を加える
items.append(item)  # itemsにitemを追加

# 悪臭: チュートリアル形式
# Step 1: ユーザーを取得する
user = get_user(id)
# Step 2: ユーザーの権限を確認する
if not user.has_permission:
    return None
# Step 3: データを処理する
result = process(user)
# Step 4: 結果を返す
return result

# 悪臭: 関数名の繰り返し
def calculate_total(items):
    """アイテムの合計を計算する"""  # 関数名と同じ
    return sum(item.price for item in items)
```

```javascript
// 悪臭: 自明な型コメント
const count = 0; // number型の変数
const name = ""; // 文字列

// 悪臭: 意味のないセクション区切り
// ========================================
// ユーザー処理
// ========================================
function getUser() { ... }
```

### 残すべきコメント

```python
# Why（なぜ）の説明 - 残す
# 税率10%は2024年法改正に基づく（変更時は法務確認必須）
TAX_RATE = 0.10

# 非自明なロジックの説明 - 残す
# ビット演算で偶奇判定（%演算より高速）
is_even = (n & 1) == 0

# 警告・注意喚起 - 残す
# FIXME: 大量データで遅くなる。キャッシュ導入検討
# TODO: v2.0でこのAPIは廃止予定

# 正規表現の説明 - 残す
# RFC 5322準拠のメールアドレス検証パターン
EMAIL_PATTERN = r'^[a-zA-Z0-9._%+-]+@...'
```

### 重要: docstringは残す

**関数・クラスのdocstringは必須であり、削除対象ではない。** 以下のdocstringは脱臭対象外:

```python
# 良いdocstring: 関数の目的・使用方法を説明
def calculate_discount(price: float, user: User) -> float:
    """割引後の価格を計算する。

    ユーザーの会員ランクに応じて割引率を適用する。
    ゴールド会員は20%、シルバー会員は10%、一般会員は0%。

    Args:
        price: 元の価格
        user: 割引対象のユーザー

    Returns:
        割引適用後の価格

    Raises:
        ValueError: 価格が負の場合
    """
    ...

# 良いdocstring: クラスの責務と使用例
class OrderProcessor:
    """注文処理を担当するクラス。

    注文の検証、在庫確認、決済処理を一連のフローとして実行する。
    外部決済APIとの連携を含むため、ネットワークエラー時のリトライ処理を内蔵。

    Example:
        processor = OrderProcessor(payment_gateway)
        result = processor.process(order)
    """
    ...

# 良いdocstring: モジュールの概要
"""注文管理モジュール。

このモジュールは以下の機能を提供する:
- 注文の作成・更新・キャンセル
- 在庫との連携
- 決済処理

外部依存: payment_gateway, inventory_service
"""
```

**削除対象のdocstring（関数名を繰り返すだけ）:**

```python
# 悪臭: 関数名をそのまま言い換えただけ
def get_user(id: int) -> User:
    """ユーザーを取得する。"""  # 関数名で自明
    return db.query(User).get(id)

# 悪臭: 引数名と型を繰り返すだけ
def add(a: int, b: int) -> int:
    """2つの整数を足す。

    Args:
        a: 整数a
        b: 整数b

    Returns:
        合計
    """
    return a + b
```

**判断基準:**

| docstringの種類                    | 判断 | 理由                                   |
| :--------------------------------- | :--- | :------------------------------------- |
| 関数の目的・ビジネスロジックを説明 | 残す | コードだけでは読み取れない意図を伝える |
| 処理の流れ・アルゴリズムの概要     | 残す | 実装を読む前に全体像を把握できる       |
| 使用例・Exampleを含む              | 残す | 利用者の理解を助ける                   |
| 例外・エッジケースの説明           | 残す | 呼び出し側が対処すべき状況を明示       |
| 関数名の言い換えのみ               | 削除 | 情報量がゼロ                           |
| 引数名・型をそのまま繰り返す       | 削除 | 型ヒントで自明                         |

### 検出基準

- コードと同じ内容のコメント: Warning
- チュートリアル形式の連番説明: Warning
- 関数名を繰り返すだけのdocstring: Info
- 意味のない装飾的コメント: Info

---

## 幻覚による依存

### 症状

- 存在しないライブラリのインポート
- 架空の関数やメソッドの呼び出し
- 実在しないAPIエンドポイントの使用

### 検出パターン

```python
# 悪臭: 存在しないモジュール
from utils.helpers import format_data  # このモジュールは存在しない
from company_lib import internal_func  # 幻覚されたパッケージ

# 悪臭: 存在しないメソッド
result = data.to_formatted_string()  # strにそのようなメソッドはない
items = list.flatten(nested)  # listにflattenメソッドはない
```

```javascript
// 悪臭: 存在しないライブラリメソッド
import { formatCurrency } from "lodash"; // lodashにformatCurrencyはない
const result = array.unique(); // Arrayにuniqueメソッドはない
```

### 検出基準

- 存在しないパッケージのインポート: Critical
- 存在しないメソッドの呼び出し: Critical
- タイポスクワッティングのリスクがあるパッケージ名: Warning

---

## セキュリティ問題

### 症状

- ハードコードされた認証情報
- SQLインジェクション脆弱性
- 安全でない入力処理

### 検出パターン

```python
# 悪臭: ハードコードされたシークレット
API_KEY = "sk-1234567890abcdef"
DATABASE_PASSWORD = "admin123"
SECRET_TOKEN = "eyJhbGciOiJIUzI1NiIs..."

# 悪臭: SQLインジェクション
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(f"DELETE FROM items WHERE name = '{item_name}'")

# 悪臭: 安全でないeval
result = eval(user_input)
```

```javascript
// 悪臭: 文字列連結によるクエリ構築
const query = `SELECT * FROM users WHERE email = '${email}'`;

// 悪臭: innerHTML への未検証入力
element.innerHTML = userProvidedContent;
```

### 検出基準

- ハードコードされたシークレット: Critical
- SQLインジェクション脆弱性: Critical
- eval/exec の使用: Critical
- XSS脆弱性: Critical

---

## 型安全性不足

### 症状

- any型の多用（TypeScript）
- 型ヒントの欠如（Python）
- 曖昧なジェネリック型

### 検出パターン

```typescript
// 悪臭: any型の乱用
function processData(data: any): any {
  return data.items.map((item: any) => item.value);
}

// 悪臭: 型アサーションの乱用
const user = response.data as User; // 検証なしのキャスト
```

```python
# 悪臭: 型ヒントなし
def process_items(items):
    results = []
    for item in items:
        results.append(item.value)
    return results

# 悪臭: 曖昧な型
def get_data() -> dict:  # dict[str, Any]のように具体化すべき
    return {"key": "value"}
```

### 検出基準

- any型の使用: Warning
- 型ヒントなしの関数: Warning
- 検証なしの型アサーション: Warning
- 曖昧なジェネリック型: Info

---

## DRY違反

### 症状

- 複数箇所で同一ロジックがコピー
- 類似の関数が複数存在
- 検証ロジックの重複

### 検出パターン

```python
# 悪臭: 重複した検証ロジック
def create_user(data):
    if not data.get('email'):
        raise ValueError('Email required')
    if not data.get('name'):
        raise ValueError('Name required')
    # ...

def update_user(data):
    if not data.get('email'):  # 重複
        raise ValueError('Email required')
    if not data.get('name'):   # 重複
        raise ValueError('Name required')
    # ...
```

### 検出基準

- 5行以上の同一コードブロックが2箇所以上: Critical
- 類似ロジック（80%以上一致）が2箇所以上: Warning

---

## ゾンビコード

### 症状

- 未使用の変数宣言
- 到達不可能なコード分岐
- 呼び出されない関数
- 代入されたが読み取られない変数

### 検出パターン

```python
# 悪臭: 未使用変数
def process():
    unused_var = calculate_something()  # 使用されない
    return other_value

# 悪臭: 到達不可能な分岐
def get_status(code):
    if code == 200:
        return 'OK'
    elif code == 200:  # 到達不可能
        return 'Success'
```

```javascript
// 悪臭: 代入後未使用
const result = expensiveCalculation();
return defaultValue; // resultは使用されない
```

### 検出基準

- 未使用変数: Warning
- 到達不可能コード: Critical
- 未使用関数: Warning

---

## 防御的肥大化

### 症状

- 論理的に発生し得ないケースへのチェック
- 過剰なtry-catch（すべてをラップ）
- 内部関数での入力検証（境界でのみ必要）

### 検出パターン

```python
# 悪臭: 過剰なnullチェック（型ヒントで保証済みの場合）
def process(data: list[int]) -> int:
    if data is None:  # 型ヒントで非Noneが保証される
        return 0
    if not isinstance(data, list):  # 不要
        return 0
    return sum(data)
```

```javascript
// 悪臭: 過剰なtry-catch
function add(a, b) {
  try {
    return a + b; // 例外は発生しない
  } catch (e) {
    return 0;
  }
}
```

### 検出基準

- 型システムで保証される検証: Info
- 例外が発生し得ない箇所のtry-catch: Info

---

## 抽象化の破綻

### 症状

- インターフェース定義後の即座の具象キャスト
- カプセル化の違反（private操作への外部アクセス）
- 使用されない抽象レイヤー

### 検出パターン

```typescript
// 悪臭: 無意味なインターフェース
interface IProcessor {
  process(data: any): any;
}

class ConcreteProcessor implements IProcessor {
  process(data: any): any {
    return data;
  }
}

// 使用箇所で即座にキャスト
const processor: IProcessor = new ConcreteProcessor();
(processor as ConcreteProcessor).specificMethod(); // 抽象化の破綻
```

### 検出基準

- インターフェース経由で取得後の即座キャスト: Warning
- 1つの実装しかないインターフェース（拡張予定なし）: Info
