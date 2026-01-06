# 拡張性とスケーラビリティ（Extensibility & Scalability）

## 目次

1. [SOLID原則](#solid原則)
2. [結合度の低減とモジュール性](#結合度の低減とモジュール性)
3. [依存性の注入（DI）](#依存性の注入di)
4. [パフォーマンスとスケーラビリティ](#パフォーマンスとスケーラビリティ)
5. [エラーハンドリング](#エラーハンドリング)

---

## SOLID原則

SOLID原則は抽象的な概念ではなく、具体的なコードの良し悪しを判断する「ものさし」として機能する。

### 単一責任の原則（SRP: Single Responsibility Principle）

クラスやモジュールが変更される理由は一つだけでなければならない。

#### 違反の例

```python
class UserService:
    def save_to_database(self, user):
        # DBへの保存ロジック
        pass

    def validate_email(self, email):
        # バリデーションロジック
        pass

    def render_profile_html(self, user):
        # 表示ロジック
        pass
```

#### 改善例

```python
class UserRepository:
    def save(self, user): pass

class UserValidator:
    def validate_email(self, email): pass

class UserView:
    def render_profile(self, user): pass
```

### 開放閉鎖の原則（OCP: Open/Closed Principle）

既存のコードを変更せずに拡張可能であるべきとする。

#### 違反の例

```python
class PaymentService:
    def process(self, payment_type, amount):
        if payment_type == "credit_card":
            # クレジットカード処理
            pass
        elif payment_type == "paypal":
            # PayPal処理
            pass
        elif payment_type == "bank_transfer":
            # 銀行振込処理（新規追加のたびに変更が必要）
            pass
```

#### 改善例（Strategyパターン）

```python
class PaymentProcessor(ABC):
    @abstractmethod
    def process(self, amount): pass

class CreditCardProcessor(PaymentProcessor):
    def process(self, amount): pass

class PayPalProcessor(PaymentProcessor):
    def process(self, amount): pass

# 新しい支払い方法は新クラスを追加するだけ
class BankTransferProcessor(PaymentProcessor):
    def process(self, amount): pass
```

### リスコフの置換原則（LSP: Liskov Substitution Principle）

親クラスを子クラスに置き換えてもプログラムの正当性が損なわれてはならない。

#### 違反の兆候

- 子クラスで親のメソッドをオーバーライドし、`NotImplementedError`を投げる
- 事前条件を厳しくする
- 事後条件を緩める

#### チェックポイント

- 継承関係が「is-a」関係を正しく表現しているか
- 子クラスが親クラスの契約を守っているか

### インターフェース分離の原則（ISP: Interface Segregation Principle）

クライアントが使用しないメソッドへの依存を強制してはならない。

#### 違反の例

```python
class Worker(ABC):
    @abstractmethod
    def work(self): pass

    @abstractmethod
    def eat(self): pass

    @abstractmethod
    def sleep(self): pass

# ロボットワーカーは食事も睡眠も不要
class RobotWorker(Worker):
    def work(self): pass
    def eat(self): raise NotImplementedError  # 違反
    def sleep(self): raise NotImplementedError  # 違反
```

#### 改善例

```python
class Workable(ABC):
    @abstractmethod
    def work(self): pass

class Eatable(ABC):
    @abstractmethod
    def eat(self): pass

class HumanWorker(Workable, Eatable):
    def work(self): pass
    def eat(self): pass

class RobotWorker(Workable):
    def work(self): pass
```

### 依存性逆転の原則（DIP: Dependency Inversion Principle）

上位モジュールは下位モジュールの詳細に依存してはならず、抽象に依存すべきとする。

#### 違反の例

```python
class OrderService:
    def __init__(self):
        self.repository = MySQLOrderRepository()  # 具象クラスに直接依存
```

#### 改善例

```python
class OrderService:
    def __init__(self, repository: OrderRepository):  # 抽象に依存
        self.repository = repository
```

---

## 結合度の低減とモジュール性

拡張性を確保するための核心は、コンポーネント間の依存関係を適切に管理し、変更の影響範囲を局所化すること（疎結合）とする。

### 疎結合の特徴

- モジュール間の依存が最小限
- インターフェースを通じた通信
- 変更の影響範囲が限定的

### 密結合の兆候

- あるクラスの変更が多数のクラスに影響
- テスト時に多くのモックが必要
- 循環参照の存在

---

## 依存性の注入（DI）

### ハードコードされた依存関係の排除

クラス内で`new`演算子を使用して具体的なクラスを直接インスタンス化している箇所を排除する。

#### 問題点

- モジュール間の結合度が高まる
- 単体テストにおけるモックへの差し替えが困難
- 実装の変更が困難

### コンストラクタインジェクション

```python
# 悪い例
class UserService:
    def __init__(self):
        self.db = MySQLDatabase()  # 直接インスタンス化

# 良い例
class UserService:
    def __init__(self, db: Database):  # 外部から注入
        self.db = db
```

### DIのメリット

- データベース実装の変更が容易
- テスト時にモック/スタブへの差し替えが可能
- 柔軟性と拡張性の向上

---

## パフォーマンスとスケーラビリティ

### N+1問題

Webアプリケーション開発において最も頻出するパフォーマンス問題の一つ。

#### 問題の構造

```python
# N+1問題の例
users = User.objects.all()  # 1回のクエリ
for user in users:
    print(user.profile.bio)  # N回のクエリ（各ユーザーごと）
```

#### 解決策

```python
# Eager Loading（事前読み込み）
users = User.objects.select_related('profile').all()
for user in users:
    print(user.profile.bio)  # 追加クエリなし
```

#### レビュー時のチェックポイント

- ループ内でDBクエリやAPIコールが行われていないか
- データ量が増加した際の影響を考慮しているか

### アルゴリズムの計算量

#### ネストされたループの警戒

```python
# O(N^2) - 警戒すべき
for item in items:
    if item in other_items:  # other_itemsがリストの場合O(N)
        process(item)

# O(N) - 改善例
other_items_set = set(other_items)  # O(N)で変換
for item in items:
    if item in other_items_set:  # O(1)で探索
        process(item)
```

#### チェックポイント

- リスト探索をハッシュマップ（辞書/Set）に変換できないか
- 計算量がO(N²)以上になっていないか

### メモリリークの防止

#### 警戒すべきパターン

- シングルトンや静的変数へのデータ追加
- イベントリスナーの解除忘れ
- キャッシュの無制限な成長
- クロージャによる参照の保持

#### リソースのライフサイクル管理

- 作成と破棄が対になっているか
- コンテキストマネージャ（with文）の使用
- 明示的なクリーンアップ処理

---

## エラーハンドリング

### 例外の握りつぶし（Swallowing Exceptions）

絶対に見逃してはならないアンチパターン：

```python
# 悪い例 - エラーを隠蔽
try:
    process_data()
except Exception:
    pass  # 何もしない

# 良い例 - 適切なハンドリング
try:
    process_data()
except SpecificException as e:
    logger.error(f"Data processing failed: {e}")
    raise  # または適切な代替処理
```

### フェイルセーフ設計

外部サービスへの依存がある場合の考慮事項：

- タイムアウトの設定
- リトライ処理（エクスポネンシャルバックオフ）
- サーキットブレーカーパターン
- フォールバック処理

### カスケード障害の防止

- 一部の障害が全体に波及しない設計
- 適切な境界の設定
- グレースフルデグラデーション

---

## サマリーテーブル

| 観点 | チェックポイント | 改善策 |
|------|-----------------|--------|
| DBアクセス | ループ内でクエリを実行していないか？ | IDリストを作成しIN句で一括取得、Eager Loading使用 |
| アルゴリズム | ネストされたループで全探索していないか？ | ListをSet/Mapに変換して探索を高速化 |
| 依存関係 | `new`で具象クラスを生成していないか？ | インターフェースに依存させ、コンストラクタ経由で注入 |
| エラー処理 | 例外を握りつぶしていないか？ | 適切なログ出力、リトライ戦略、サーキットブレーカー導入 |
