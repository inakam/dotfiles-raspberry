# リファクタリングパターン集

悪臭を脱臭するための具体的なリファクタリング手法。

## 目次

1. [ガード節の適用](#ガード節の適用)
2. [メソッド抽出](#メソッド抽出)
3. [マップルックアップ](#マップルックアップ)
4. [言語イディオムへの変換](#言語イディオムへの変換)
5. [非同期処理の最適化](#非同期処理の最適化)

---

## ガード節の適用

### 目的

深いネストを平坦化し、認知的複雑度を低減。

### パターン

**Before（アローコード）:**

```python
def process_order(order):
    if order:
        if order.is_valid:
            if order.items:
                if order.customer.is_active:
                    total = calculate_total(order)
                    return create_invoice(total)
                else:
                    return "Customer inactive"
            else:
                return "No items"
        else:
            return "Invalid order"
    else:
        return "No order"
```

**After（ガード節）:**

```python
def process_order(order):
    if not order:
        return "No order"
    if not order.is_valid:
        return "Invalid order"
    if not order.items:
        return "No items"
    if not order.customer.is_active:
        return "Customer inactive"

    total = calculate_total(order)
    return create_invoice(total)
```

### 適用手順

1. 最も外側の条件を反転
2. 早期リターンで終了
3. 次の条件に対して繰り返し
4. 正常系ロジックを最後に配置

---

## メソッド抽出

### 目的

重複コードを排除し、DRY原則を強制。

### パターン

**Before（重複ロジック）:**

```python
def create_user(data):
    if not data.get('email') or '@' not in data['email']:
        raise ValueError('Invalid email')
    if not data.get('name') or len(data['name']) < 2:
        raise ValueError('Invalid name')
    # 作成ロジック

def update_user(user_id, data):
    if not data.get('email') or '@' not in data['email']:
        raise ValueError('Invalid email')
    if not data.get('name') or len(data['name']) < 2:
        raise ValueError('Invalid name')
    # 更新ロジック
```

**After（抽出済み）:**

```python
def _validate_user_data(data):
    if not data.get('email') or '@' not in data['email']:
        raise ValueError('Invalid email')
    if not data.get('name') or len(data['name']) < 2:
        raise ValueError('Invalid name')

def create_user(data):
    _validate_user_data(data)
    # 作成ロジック

def update_user(user_id, data):
    _validate_user_data(data)
    # 更新ロジック
```

### 適用手順

1. 重複箇所を特定
2. 共通ロジックを新関数に抽出
3. 元の箇所を関数呼び出しに置換
4. 関数名は動詞で開始（validate, calculate, etc.）

---

## マップルックアップ

### 目的

条件分岐を宣言的なデータ構造に変換。

### パターン

**Before（switch/if-else連鎖）:**

```python
def get_discount(customer_type):
    if customer_type == 'gold':
        return 0.20
    elif customer_type == 'silver':
        return 0.10
    elif customer_type == 'bronze':
        return 0.05
    else:
        return 0.0
```

**After（マップルックアップ）:**

```python
DISCOUNT_RATES = {
    'gold': 0.20,
    'silver': 0.10,
    'bronze': 0.05,
}

def get_discount(customer_type):
    return DISCOUNT_RATES.get(customer_type, 0.0)
```

### TypeScript版

**Before:**

```typescript
function getStatusText(code: number): string {
  switch (code) {
    case 200:
      return "OK";
    case 404:
      return "Not Found";
    case 500:
      return "Server Error";
    default:
      return "Unknown";
  }
}
```

**After:**

```typescript
const STATUS_TEXT: Record<number, string> = {
  200: "OK",
  404: "Not Found",
  500: "Server Error",
};

const getStatusText = (code: number): string => STATUS_TEXT[code] ?? "Unknown";
```

### 適用手順

1. 分岐条件と戻り値のペアを特定
2. 定数マップとして定義
3. `.get()` または `??` でデフォルト処理

---

## 言語イディオムへの変換

### Python

| Before                                                             | After                                    |
| :----------------------------------------------------------------- | :--------------------------------------- |
| `for x in items: result.append(f(x))`                              | `result = [f(x) for x in items]`         |
| `for x in items: if cond(x): result.append(x)`                     | `result = [x for x in items if cond(x)]` |
| `total = 0; for x in items: total += x`                            | `total = sum(items)`                     |
| `flag = True; for x in items: if not cond(x): flag = False; break` | `flag = all(cond(x) for x in items)`     |
| `for i in range(len(items))`                                       | `for i, item in enumerate(items)`        |
| `keys = list(d.keys())`                                            | `keys = list(d)`                         |

### JavaScript/TypeScript

| Before                                             | After                                          |
| :------------------------------------------------- | :--------------------------------------------- |
| `arr.forEach(x => result.push(f(x)))`              | `result = arr.map(f)`                          |
| `arr.forEach(x => { if(cond(x)) result.push(x) })` | `result = arr.filter(cond)`                    |
| `let total = 0; arr.forEach(x => total += x)`      | `const total = arr.reduce((a, b) => a + b, 0)` |
| `for (let i = 0; i < arr.length; i++)`             | `for (const item of arr)` または `arr.forEach` |
| `arr.filter(x => x !== null && x !== undefined)`   | `arr.filter(Boolean)`                          |

---

## 非同期処理の最適化

### 目的

独立した非同期処理を並列化。

### パターン

**Before（順次実行）:**

```typescript
async function fetchData() {
  const user = await getUser();
  const posts = await getPosts();
  const comments = await getComments();
  return { user, posts, comments };
}
// 実行時間: T(user) + T(posts) + T(comments)
```

**After（並列実行）:**

```typescript
async function fetchData() {
  const [user, posts, comments] = await Promise.all([
    getUser(),
    getPosts(),
    getComments(),
  ]);
  return { user, posts, comments };
}
// 実行時間: max(T(user), T(posts), T(comments))
```

### 適用条件

- 各Promiseが独立している（依存関係がない）
- エラーハンドリングが適切（1つの失敗で全体が失敗してよい場合）

### 依存関係がある場合

```typescript
// userIDが必要な場合は順次
async function fetchUserPosts() {
  const user = await getUser();
  const posts = await getPostsByUserId(user.id); // 依存あり
  return { user, posts };
}

// 部分的に並列化可能な場合
async function fetchAll() {
  const user = await getUser();
  const [posts, settings] = await Promise.all([
    getPostsByUserId(user.id),
    getSettingsByUserId(user.id),
  ]);
  return { user, posts, settings };
}
```
