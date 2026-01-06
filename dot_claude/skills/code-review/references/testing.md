# テスト戦略（Testing Strategy）

## 目次

1. [振る舞いテスト vs 実装テスト](#振る舞いテスト-vs-実装テスト)
2. [AAAパターン](#aaaパターン)
3. [モックの適切な使用](#モックの適切な使用)
4. [テストの網羅性](#テストの網羅性)
5. [テストの独立性と決定論的動作](#テストの独立性と決定論的動作)
6. [テストのアンチパターン](#テストのアンチパターン)

---

## 振る舞いテスト vs 実装テスト

テストコードのレビューにおける最も重要な視点は、テストが「内部実装」に依存せず、「外部から見た振る舞い」を検証しているかとする。

### 振る舞い（Behavior）とは

- 入力に対する出力
- システム外部への副作用（DBへの保存、メール送信など）
- パブリックインターフェースを通じた結果

### 実装詳細への結合の問題

#### 脆いテスト（Fragile Test）

内部実装に結合したテストは、リファクタリングで壊れる：

```python
# 悪い例 - 実装詳細に依存
def test_calculate_total():
    service = OrderService()
    service.calculate_total(order)

    # 内部メソッドの呼び出しを検証（実装詳細）
    assert service._apply_discount.called
    assert service._calculate_tax.called
```

```python
# 良い例 - 振る舞いを検証
def test_calculate_total():
    service = OrderService()
    result = service.calculate_total(order)

    # 出力（振る舞い）を検証
    assert result == expected_total
```

### プライベートメソッドのテスト

プライベートメソッドや内部フィールドをリフレクション等で無理やりテストしているコード（Anal Probeアンチパターン）は修正を求める。

#### 対処法

- パブリックインターフェースを通じてテスト
- テストが必要なほど複雑なプライベートメソッドは、別クラスに抽出を検討

### ドキュメントとしてのテスト

テストは「生きた仕様書」として機能すべきとする。

#### テスト名の書き方

```python
# 悪い例
def test_order():
    pass

# 良い例（仕様を表現）
def test_calculate_total_applies_10_percent_discount_for_premium_members():
    pass

# BDDスタイル
def test_given_premium_member_when_checkout_then_applies_discount():
    pass
```

---

## AAAパターン

テストコードの可読性を高めるデファクトスタンダード。

### 構造

1. **Arrange（準備）**: テストに必要なオブジェクト生成、データセットアップ、モック定義
2. **Act（実行）**: テスト対象メソッド（SUT）の実行
3. **Assert（検証）**: 実行結果が期待通りであるかの確認

### 良い例

```python
def test_apply_discount_for_bulk_order():
    # Arrange
    order = Order(items=[
        Item(price=100, quantity=10),
        Item(price=200, quantity=5),
    ])
    calculator = PriceCalculator(discount_threshold=10)

    # Act
    total = calculator.calculate(order)

    # Assert
    assert total == 1800  # 10%割引適用
```

### レビューポイント

- 3つのフェーズが視覚的に分離されているか
- 1つのテストで複数のAct-Assertが繰り返されていないか
- 「1つのテストケースは1つの概念のみを検証する」原則に従っているか

---

## モックの適切な使用

### モックとスタブの区別

| 種類 | 目的 | 検証対象 |
|------|------|----------|
| スタブ（Stub） | テスト実行に必要な入力を提供 | 状態（State） |
| モック（Mock） | 呼び出しが行われたかを検証 | 振る舞い（Behavior） |

### 使い分けの例

```python
# スタブ - データ取得のための代替実装
def test_get_user_profile():
    user_repository = Mock()
    user_repository.find_by_id.return_value = User(name="Alice")  # スタブとして使用

    service = UserService(user_repository)
    profile = service.get_profile(user_id=1)

    assert profile.name == "Alice"  # 状態を検証
```

```python
# モック - 副作用の発生を検証
def test_send_welcome_email():
    email_service = Mock()

    service = UserService(email_service=email_service)
    service.register(User(email="test@example.com"))

    email_service.send.assert_called_once_with(  # 呼び出しを検証
        to="test@example.com",
        template="welcome"
    )
```

### 過剰なモック（The Mockery）

全ての依存をモック化し、「モックのメソッドが呼ばれたこと」だけを検証するテストは価値が低い。

#### 問題点

- 実際のロジックが正しく動いているか保証されない
- テストが壊れにくいが、バグも検出できない

#### 推奨アプローチ

- ドメインロジックを持つクラス（Value Object、Entity）は実インスタンスを使用
- モックは制御不能な外部境界（DB、ネットワーク、ファイルシステム）に限定

```python
# 良い例 - ドメインロジックは実インスタンス
def test_order_total_calculation():
    # 実際のドメインオブジェクトを使用
    order = Order()
    order.add_item(Item(price=100, quantity=2))
    order.add_item(Item(price=50, quantity=3))

    assert order.total == 350  # 実際のロジックをテスト
```

---

## テストの網羅性

カバレッジの数値だけを追うのではなく、「質的網羅性」を評価する。

### 境界値テスト

```python
# テストすべき境界値の例
def test_age_validation():
    # 境界値
    assert is_adult(18) == True   # ちょうど境界
    assert is_adult(17) == False  # 境界の直前
    assert is_adult(19) == True   # 境界の直後

    # エッジケース
    assert is_adult(0) == False   # 最小値
    assert is_adult(-1) == False  # 不正値
    assert is_adult(None) == False  # Null
```

### 異常系のテスト

- Null/None入力
- 空リスト/空文字列
- 最大値/最小値
- 不正なフォーマット
- 例外が発生するケース

### 回帰テスト

バグ修正のPRでは、そのバグを再現するテストケースが最初に追加されているか確認する。

```python
# バグ修正時のテスト追加
def test_negative_quantity_does_not_cause_negative_total():
    """
    Issue #123: 数量が負の値の場合に合計がマイナスになるバグの修正
    """
    order = Order()
    order.add_item(Item(price=100, quantity=-1))

    assert order.total == 0  # 負の数量は0として扱う
```

---

## テストの独立性と決定論的動作

テストはいつでも、誰の環境でも、どのような順序で実行しても、常に同じ結果になるべきとする。

### 共有状態の汚染

#### 問題のあるパターン

- テスト間でDBの状態を共有
- シングルトンや静的変数の共有
- グローバル状態の変更

#### 対策

```python
class TestUserService:
    def setup_method(self):
        # 各テスト前にクリーンな状態を作成
        self.db = create_test_database()
        self.service = UserService(self.db)

    def teardown_method(self):
        # 各テスト後にクリーンアップ
        self.db.clear()
```

### 非決定的な要素の排除

#### 時刻依存

```python
# 悪い例 - 実行時刻に依存
def test_is_expired():
    token = Token(expires_at=datetime.now() + timedelta(hours=1))
    assert token.is_expired() == False  # 時刻によって結果が変わる

# 良い例 - 時刻をモック
def test_is_expired(freezer):
    freezer.move_to("2024-01-01 12:00:00")
    token = Token(expires_at=datetime(2024, 1, 1, 13, 0, 0))
    assert token.is_expired() == False
```

#### ランダム値

```python
# 悪い例 - ランダムに依存
def test_generate_code():
    code = generate_random_code()
    assert len(code) == 8  # 長さは検証できるが値は不定

# 良い例 - シードを固定
def test_generate_code():
    random.seed(42)
    code = generate_random_code()
    assert code == "A1B2C3D4"  # 決定論的に検証可能
```

### Flaky Test（間欠的に失敗するテスト）

開発者のテストへの信頼を損なうため、レビュー段階で徹底的に排除する。

#### 原因

- 時刻やランダム値への依存
- 外部サービスへの依存
- 非同期処理のタイミング問題
- テスト間の依存関係

---

## テストのアンチパターン

| アンチパターン | 特徴 | 修正案 |
|--------------|------|--------|
| **Fragile Test** | 実装詳細に依存、リファクタリングで壊れる | パブリックAPIを通じた振る舞い検証に変更 |
| **The Mockery** | 全依存をモック化、実質何もテストしていない | 値オブジェクトは実物を使い、外部IOのみモック化 |
| **The Liar** | テスト名は立派だがAssertがない | 適切なアサーションを追加、期待値を明確化 |
| **The Slow Poke** | 実行に時間がかかりCIのボトルネック | DB接続やスリープをモック/スタブに置換 |
| **Anal Probe** | リフレクションでprivateメンバを覗き見 | 設計見直し、振る舞いテストに変更 |
| **The Giant** | 1つのテストで多くのことを検証 | 1テスト1概念に分割 |
| **The Stranger** | テスト対象と関係ない検証を含む | 無関係なアサーションを削除 |
| **The Secret Catcher** | 例外をキャッチして握りつぶす | 例外を適切に検証または伝播 |

---

## サマリー

テストコードのレビューで確認すべき主要ポイント：

1. **振る舞いをテストしているか** - 実装詳細ではなくパブリックインターフェースを通じた結果を検証
2. **AAAパターンに従っているか** - Arrange/Act/Assertが明確に分離
3. **モックの使用は適切か** - 外部境界のみモック、ドメインロジックは実インスタンス
4. **網羅性は十分か** - 正常系だけでなく異常系、境界値もカバー
5. **独立性があるか** - テスト間で状態を共有せず、決定論的に動作
