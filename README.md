# GLM Chat

[English](#english) | [Русский](#русский)

---

<a name="english"></a>
## English

GLM Chat is a professional Flutter application for communicating with the GLM 4.7 neural network model from Zhipu AI.

### Features

- **Professional Dark Theme** - Material 3 design with minimalistic UI
- **Chat with GLM 4.7** - Real-time messaging with Zhipu AI's powerful model
- **File Attachments** - Support for all file types (images, documents, code, etc.)
  - Images are sent directly to the model (GLM-4V vision capability)
  - Text files are read and their content is added to the message
  - Automatic MIME type detection
  - Image compression for optimal performance
- **Syntax Highlighting** - Color-coded code blocks for 50+ programming languages
- **Inline Message Editing** - Edit your messages directly in the input field
  - Press ENTER to save and resend
  - Press ESC to cancel editing
  - Deletes all subsequent messages and regenerates response
- **Copy Response** - One-click copy for assistant responses
- **Completion Indicator** - Visual confirmation when response is complete
- **Secure Storage** - API key stored in encrypted storage
- **Cross-Platform** - Supports Android, iOS, Web, and Desktop

### Architecture

The application follows clean architecture principles with:

- **Riverpod StateNotifier** - Modern state management pattern
- **Layered architecture** - Separation of concerns (core, data, providers, services, widgets)
- **Immutable state** - State classes hold immutable data via `copyWith()`
- **Type-safe models** - Strongly-typed data models with JSON serialization

### Project Structure

```
lib/
├── core/                    # Application core
│   ├── constants/          # API constants and configuration
│   └── theme/              # App theme (Material 3 dark)
├── data/                   # Data models
│   └── models/            # Message, ChatRequest, ChatResponse, AttachedFile
├── providers/              # State management (Riverpod)
├── services/              # API service and secure storage
└── widgets/               # UI components
    ├── chat/              # Chat screen, messages, input field
    ├── code/              # Code rendering with syntax highlighting
    └── settings/          # Settings screen
```

### Key Technologies

| Dependency | Version | Purpose |
|------------|---------|---------|
| flutter_riverpod | ^2.5.0 | State management |
| http | ^1.2.0 | HTTP client |
| flutter_markdown | ^0.7.0 | Markdown rendering |
| flutter_highlight | ^0.7.0 | Code syntax highlighting |
| flutter_secure_storage | ^9.2.0 | Encrypted key storage |
| file_picker | ^8.0.0 | File selection |
| cross_file | ^0.3.4 | Cross-platform file handling |
| image | ^4.2.0 | Image compression |
| mime | ^1.0.0 | MIME type detection |

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd glm_chat
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

### Getting API Key

1. Visit [Zhipu AI](https://open.bigmodel.cn/)
2. Register or login to your account
3. Create an API key
4. Add the key in the app settings

### Usage

1. On first launch, the app will show the API key setup screen
2. Enter your API key and click "Save" (or "Сохранить" in Russian)
3. Start chatting with GLM 4.7!

### Keyboard Shortcuts

- **ENTER** - Send message
- **SHIFT+ENTER** - New line in input field
- **ESC** - Cancel message editing

### Known Issues

- File attachments are not available in edit mode
- Maximum image dimension is 1024px (auto-compression)

### License

MIT License

---

<a name="русский"></a>
## Русский

GLM Chat - профессиональное Flutter приложение для общения с нейросетевой моделью GLM 4.7 от компании Zhipu AI.

### Особенности

- **Профессиональная тёмная тема** - Дизайн Material 3 с минималистичным интерфейсом
- **Чат с GLM 4.7** - Общение в реальном времени с мощной моделью от Zhipu AI
- **Прикрепление файлов** - Поддержка всех типов файлов (изображения, документы, код и т.д.)
  - Изображения отправляются напрямую модели (возможности зрения GLM-4V)
  - Текстовые файлы читаются, их содержимое добавляется в сообщение
  - Автоматическое определение MIME-типов
  - Сжатие изображений для оптимизации производительности
- **Подсветка синтаксиса** - Цветовая подсветка кода для 50+ языков программирования
- **Встроенное редактирование сообщений** - Редактируйте сообщения прямо в поле ввода
  - Нажмите ENTER для сохранения и отправки
  - Нажмите ESC для отмены редактирования
  - Удаляет все последующие сообщения и перегенерирует ответ
- **Копирование ответа** - Копирование ответа ассистента в один клик
- **Индикатор завершения** - Визуальное подтверждение окончания ответа
- **Безопасное хранение** - API ключ хранится в зашифрованном хранилище
- **Кроссплатформенность** - Поддержка Android, iOS, Web и Desktop

### Архитектура

Приложение следует принципам чистой архитектуры с:

- **Riverpod StateNotifier** - Современный паттерн управления состоянием
- **Многоуровневая архитектура** - Разделение ответственности (core, data, providers, services, widgets)
- **Неизменяемое состояние** - Классы состояния хранят неизменяемые данные через `copyWith()`
- **Типизированные модели** - Строго типизированные модели данных с JSON-сериализацией

### Структура проекта

```
lib/
├── core/                    # Ядро приложения
│   ├── constants/          # Константы API и конфигурация
│   └── theme/              # Тема оформления (Material 3 dark)
├── data/                   # Модели данных
│   └── models/            # Message, ChatRequest, ChatResponse, AttachedFile
├── providers/              # Управление состоянием (Riverpod)
├── services/              # API сервис и безопасное хранение
└── widgets/               # UI компоненты
    ├── chat/              # Экран чата, сообщения, поле ввода
    ├── code/              # Рендеринг кода с подсветкой синтаксиса
    └── settings/          # Экран настроек
```

### Ключевые технологии

| Зависимость | Версия | Назначение |
|-------------|--------|------------|
| flutter_riverpod | ^2.5.0 | Управление состоянием |
| http | ^1.2.0 | HTTP клиент |
| flutter_markdown | ^0.7.0 | Рендеринг Markdown |
| flutter_highlight | ^0.7.0 | Подсветка синтаксиса кода |
| flutter_secure_storage | ^9.2.0 | Зашифрованное хранение ключей |
| file_picker | ^8.0.0 | Выбор файлов |
| cross_file | ^0.3.4 | Кроссплатформенная работа с файлами |
| image | ^4.2.0 | Сжатие изображений |
| mime | ^1.0.0 | Определение MIME-типов |

### Установка

1. Клонируйте репозиторий:
```bash
git clone <repository-url>
cd glm_chat
```

2. Установите зависимости:
```bash
flutter pub get
```

3. Запустите приложение:
```bash
flutter run
```

### Получение API ключа

1. Перейдите на [Zhipu AI](https://open.bigmodel.cn/)
2. Зарегистрируйтесь или войдите в аккаунт
3. Создайте API ключ
4. Добавьте ключ в настройках приложения

### Использование

1. При первом запуске приложение покажет экран настройки API ключа
2. Введите ваш API ключ и нажмите "Сохранить"
3. Начните общение с GLM 4.7!

### Горячие клавиши

- **ENTER** - Отправить сообщение
- **SHIFT+ENTER** - Новая строка в поле ввода
- **ESC** - Отменить редактирование сообщения

### Известные ограничения

- Прикрепление файлов недоступно в режиме редактирования
- Максимальный размер изображения: 1024px (автоматическое сжатие)

### Лицензия

MIT License
