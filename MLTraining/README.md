# 🤖 ML Training для BudgetAI

## 📁 Файли

- **`transaction_training_data_rich.csv`** - датасет (1047 прикладів)
- **`train_rich.swift`** - скрипт для тренування
- **`generate_rich_dataset.py`** - генератор датасету
- **`TransactionCategoryClassifier.mlmodel`** - натренована модель

## 🚀 Швидке перетренування

```bash
cd MLTraining
python3 generate_rich_dataset.py
swift train_rich.swift
cp TransactionCategoryClassifier.mlmodel ../BudgetAI/ML/
```

Потім: **Cmd + Shift + K** (Clean), **Cmd + R** (Run)

## 📊 Метрики

- **Прикладів:** 1047
- **Точність валідації:** 96.15%
- **Тести:** 100% (27/27)

## 🔧 Додавання ключових слів

Відредагуйте `generate_rich_dataset.py`:

```python
EXPENSE_KEYWORDS = {
    "Їжа": [
        "продукти в АТБ",
        "піцу",
        # додайте свої
    ],
}
```

Згенеруйте і перетренуйте:
```bash
python3 generate_rich_dataset.py
swift train_rich.swift
```
