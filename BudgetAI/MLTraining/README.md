# ML Training Scripts

Ця папка містить скрипти для тренування Machine Learning моделі класифікації транзакцій.

## Файли

- `generate_rich_dataset.py` - Python скрипт для генерації тренувальних даних
- `train_rich.swift` - Swift скрипт для тренування ML моделі
- `transaction_training_data_rich.csv` - CSV файл з тренувальними даними

## Використання

### 1. Генерація даних (опціонально)

```bash
cd BudgetAI/mlTraining
python3 generate_rich_dataset.py
```

### 2. Тренування моделі

```bash
cd BudgetAI/mlTraining
swift train_rich.swift
```

### 3. Копіювання моделі в проект

Після успішного тренування скопіюйте згенеровану модель:

```bash
cp TransactionCategoryClassifier.mlmodel ../Services/MachineLearning/
```

### 4. Rebuild проекту

Відкрийте проект в Xcode і виконайте Clean Build (Cmd + Shift + K), потім Build (Cmd + B).

## Важливо

⚠️ Файл `train_rich.swift` - це standalone скрипт для командного рядка, він НЕ повинен компілюватися разом з iOS проектом.
