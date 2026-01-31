# GLM Chat

[English](#english) | [Русский](#русский)

---

<a name="english"></a>
## English

GLM Chat is a professional Flutter application for communicating with the GLM 4.7 neural network model from Zhipu AI.

### Features

- **Professional Dark Theme** - Material 3 design with minimalistic UI
- **Chat with GLM 4.7** - Real-time messaging with Zhipu AI's powerful model
  - Configurable timeout (30-300 seconds, default 120s)
  - Response time logging
- **Session Management** - Side drawer with chat history
  - Auto-save sessions after each message
  - Switch between previous conversations
  - Delete individual sessions or entire history
  - Persistent storage across app restarts
  - Auto-generated titles from first message
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
- **Customizable Font Size** - Apply to all messages (user and assistant)
- **Secure Storage** - API key and settings stored in encrypted storage
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
│   └── models/            # Message, ChatRequest, ChatResponse, AttachedFile, ChatSession
├── providers/              # State management (Riverpod)
├── services/              # API service and secure storage
└── widgets/               # UI components
    ├── chat/              # Chat screen, messages, input field
    ├── code/              # Code rendering with syntax highlighting
    ├── sessions/          # Session drawer and session list items
    └── settings/          # Settings screen
```

### Key Technologies

| Dependency | Version | Purpose |
|------------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management |
| riverpod | ^2.6.1 | State management core |
| http | ^1.2.0 | HTTP client |
| flutter_markdown_plus | ^1.0.7 | Markdown rendering |
| markdown | ^7.2.0 | Markdown parsing |
| flutter_highlight | ^0.7.0 | Code syntax highlighting |
| flutter_secure_storage | ^10.0.0 | Encrypted key storage |
| file_picker | ^10.3.10 | File selection |
| cross_file | ^0.3.5+2 | Cross-platform file handling |
| image | ^4.2.0 | Image compression |
| mime | ^2.0.0 | MIME type detection |
| uuid | ^4.0.0 | Session ID generation |

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

### Settings

The app provides several customization options:

- **API Key** - Your Zhipu AI API key for accessing GLM 4.7
- **Font Size** - Adjust text size for all messages (12-32px)
- **Response Timeout** - Configure API request timeout (30-300 seconds, default 120s)
  - Higher values allow the model more time for complex queries
  - Quick presets: 30s, 60s, 120s, 5min

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
  - Настраиваемый таймаут ответа (30-300 секунд, по умолчанию 120с)
  - Логирование времени генерации ответа
- **Управление сессиями** - Боковое меню с историей чатов
  - Автосохранение сессий после каждого сообщения
  - Переключение между предыдущими разговорами
  - Удаление отдельных сессий или всей истории
  - Сохранение истории между запусками приложения
  - Автоматическая генерация заголовка из первых слов запроса
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
- **Настройка размера шрифта** - Применяется ко всем сообщениям (запросы и ответы)
- **Безопасное хранение** - API ключ и настройки хранятся в зашифрованном хранилище
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
│   └── models/            # Message, ChatRequest, ChatResponse, AttachedFile, ChatSession
├── providers/              # Управление состоянием (Riverpod)
├── services/              # API сервис и безопасное хранение
└── widgets/               # UI компоненты
    ├── chat/              # Экран чата, сообщения, поле ввода
    ├── code/              # Рендеринг кода с подсветкой синтаксиса
    ├── sessions/          # Боковое меню сессий и элементы списка
    └── settings/          # Экран настроек
```

### Ключевые технологии

| Зависимость | Версия | Назначение |
|-------------|--------|------------|
| flutter_riverpod | ^3.2.0 | Управление состоянием |
| riverpod | ^3.2.0 | Ядро управления состоянием |
| http | ^1.2.0 | HTTP клиент |
| flutter_markdown_plus | ^0.7.0 | Рендеринг Markdown |
| flutter_highlight | ^0.7.0 | Подсветка синтаксиса кода |
| flutter_secure_storage | ^10.0.0 | Зашифрованное хранение ключей |
| file_picker | ^10.3.10 | Выбор файлов |
| cross_file | ^0.3.5+2 | Кроссплатформенная работа с файлами |
| image | ^4.2.0 | Сжатие изображений |
| mime | ^2.0.0 | Определение MIME-типов |
| uuid | ^4.0.0 | Генерация ID сессий |

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

### Настройки

Приложение предоставляет различные настройки:

- **API ключ** - Ваш ключ Zhipu AI для доступа к GLM 4.7
- **Размер шрифта** - Настройка размера текста для всех сообщений (12-32px)
- **Таймаут ответа** - Настройка таймаута запроса к API (30-300 секунд, по умолчанию 120с)
  - Большие значения позволяют модели больше времени на сложные запросы
  - Быстрые пресеты: 30с, 60с, 120с, 5мин

### Горячие клавиши

- **ENTER** - Отправить сообщение
- **SHIFT+ENTER** - Новая строка в поле ввода
- **ESC** - Отменить редактирование сообщения

### Известные ограничения

- Прикрепление файлов недоступно в режиме редактирования
- Максимальный размер изображения: 1024px (автоматическое сжатие)

### Лицензия

MIT License
