# Python Table Driven Test (pytest)

```python
import pytest

def add(a: int, b: int) -> int:
    return a + b

@pytest.mark.parametrize(
    "a, b, expected",
    [
        (2, 3, 5),      # 正の数同士
        (-1, 5, 4),     # 負の数を含む
        (0, 0, 0),      # ゼロを含む
    ],
)
def test_add(a: int, b: int, expected: int) -> None:
    assert add(a, b) == expected
```
