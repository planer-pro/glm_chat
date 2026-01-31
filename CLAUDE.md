# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important Rules

1. **Always run the app after making changes** - Execute `flutter run` after any code modifications to verify changes work correctly
2. **Always respond in Russian** - All communication with the user must be in Russian
3. **Always comment all code** - Every function, class, and important code block must have comments in Russian explaining what it does
4. **Always update CLAUDE.md** - Update this file when making architectural changes, adding new features, or modifying the project structure

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for release (Android)
flutter build apk

# Run tests
flutter test

# Analyze code
flutter analyze
```

## Architecture Overview

This is a Flutter chat application for GLM 4.7 (Zhipu AI). The architecture follows a clean separation of concerns with Riverpod for state management.

### State Management Pattern

The app uses **Riverpod StateNotifier pattern** for state management:

- **State classes** hold immutable data (e.g., `ChatState` in `lib/providers/chat_provider.dart`)
- **Notifier classes** (`ChatNotifier`) contain business logic and modify state via `copyWith()`
- **Providers** (`chatProvider`, `settingsProvider`) expose state to widgets

Example from `chat_provider.dart`:
```dart
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatNotifier(apiService, ref);
});
```

### Provider Dependencies

Providers can depend on other providers using `ref.watch()` or `ref.read()`:

```dart
// In ChatNotifier - accessing another provider
final apiKey = await _ref.read(settingsProvider.notifier).getApiKey();
```

### Message Flow

1. User sends message via `ChatInputField`
2. `ChatNotifier.sendMessage()` is called with optional files
3. User message added to state immediately with attached files (optimistic UI)
4. **Deep copy** of messages created to prevent data loss during async serialization
5. `ChatRequest.glm47(messages)` creates API request with full conversation history
6. `request.toJson()` called asynchronously to serialize messages and read file contents
7. Text files: content read and added to message text
8. Images: converted to base64 and added to multimodal content array
9. `ApiService.createChatCompletion()` sends to GLM 4.7 endpoint
10. Response parsed to `ChatResponse` and converted to `Message`
11. Assistant message added to state
12. "✓ Ответ окончен" indicator appears in last assistant message

### Message Editing Architecture

Messages can be edited inline via the input field (no dialog):
- User clicks edit button in `MessageBubble` → calls `ChatNotifier.startEditing(message)`
- `ChatState.editingMessageId` and `editingMessageText` are set
- `ChatInputField` watches state and loads message text into input field
- Visual indicator shows "Режим редактирования" with ESC cancel hint
- User edits text in the input field and presses ENTER
- `_sendMessage()` detects editing mode → calls `ChatNotifier.updateMessage(newContent)`
- `updateMessage()` deletes all messages after edited one and sends new API request
- `editingMessageId` and `editingMessageText` reset to null
- Input field clears and exits editing mode
- ESC key or cancel button exits editing mode without sending

**Key Files:**
- `lib/widgets/chat/chat_input_field.dart` - Inline editing UI and logic
- `lib/providers/chat_provider.dart` - `startEditing()`, `updateMessage()`, `cancelEditing()`
- `lib/widgets/chat/message_bubble.dart` - Edit button, copy button, completion indicator

**Assistant Message Actions**:
- Copy button: Copies entire response to clipboard
- Completion indicator: Shows "✓ Ответ окончен" when response is complete
- Only visible for the last assistant message when not loading

### API Layer

`ApiService` (lib/services/api_service.dart) handles all HTTP communication:
- Throws `ApiException` for error cases (401, 429, 400, 5xx)
- 60-second timeout configured in `ApiConstants.requestTimeout`
- Returns typed `ChatResponse` objects

### Secure Storage

API keys stored via `flutter_secure_storage` (lib/services/storage_service.dart):
- Keys are encrypted at rest
- Use `SettingsProvider` to access, never access `StorageService` directly from widgets

### Session Management

**ChatSession Model** (lib/data/models/chat_session.dart):
- Represents a chat session with id, title, messages, createdAt, updatedAt
- Title auto-generated from first user message
- Methods: `toJson()`, `fromJson()`, `copyWith()`

**SessionManagerProvider** (lib/providers/session_provider.dart):
- `SessionManagerState` - holds list of sessions and active session ID
- `SessionManagerNotifier` - manages sessions:
  - `loadSessions()` - загрузка сессий из хранилища
  - `createSession()` - создание новой сессии
  - `updateSession()` - обновление существующей сессии
  - `deleteSession()` - удаление сессии
  - `deleteAllSessions()` - удаление всех сессий
  - `setActiveSession()` - переключение активной сессии
  - `getActiveSession()` - получение активной сессии

**Session Storage** (lib/services/storage_service.dart):
- `saveSessions(String sessionsJson)` - сохранение списка сессий
- `getSessions()` - загрузка списка сессий
- `saveActiveSessionId(String sessionId)` - сохранение ID активной сессии
- `getActiveSessionId()` - получение ID активной сессии

**UI Components**:
- `SessionDrawer` (lib/widgets/sessions/session_drawer.dart) - боковое меню со списком сессий
- `SessionListItem` (lib/widgets/sessions/session_list_item.dart) - элемент списка сессий

**Integration**:
- При запуске: загружаются сессии → активируется последняя или создаётся новая
- При отправке сообщения: автосохранение сессии
- При переключении: загрузка сообщений выбранной сессии
- Кнопка меню (гамбургер) в AppBar открывает/закрывает боковое меню

### Widget Organization

```
lib/widgets/
├── chat/           # Chat-specific UI (ChatScreen, MessageBubble, ChatInputField)
├── code/           # Code rendering (CodeBlockWidget, CopyButton)
├── sessions/       # Session management (SessionDrawer, SessionListItem)
└── settings/       # Settings screen
```

### Data Models

All models support immutable updates via `copyWith()`:
- `Message` - has `role`, `content`, `timestamp`, `isEdited`, `id`, `attachedFiles`
- `AttachedFile` - represents attached file with MIME type detection
- `ChatRequest` - wraps messages for API
- `ChatResponse` - parsed from API JSON

Models have `toJson()` for serialization and factory constructors like `Message.fromJson()` or `ChatRequest.glm47()` for creation.

**AttachedFile Features**:
- Automatic MIME type detection by file extension
- `isTextFile` getter identifies text files (code, configs, etc.)
- `isImage` getter identifies image files
- `getTextContent()` method reads text file content (UTF-8/Latin1)
- `getBase64Data()` method encodes files for API transmission
- Image compression for large images (max 1024px dimension)

## Key Constants

API configuration in `lib/core/constants/api_constants.dart`:
- Base URL: `https://open.bigmodel.cn/api/paas/v4`
- Model: `glm-4.7`
- Timeout: 60 seconds
- Max tokens: 4096

## Theme

Material 3 dark theme configured in `lib/core/theme/app_theme.dart`. App uses `theme: AppTheme.darkTheme` in MaterialApp.

**Design Philosophy** (Updated 2026-01-26):
- **Minimalistic**: Clean UI without avatars, minimal borders, subtle colors
- **Professional**: User messages in blue (#60A5FA), assistant in dark (#1E293B)
- **Typography**: Optimized font sizes (15px for messages, configurable code font)
- **Spacing**: Consistent 20px horizontal padding, 6px vertical for messages

## User Input & Keyboard Shortcuts

**Chat Input Field** (`lib/widgets/chat/chat_input_field.dart`):
- **ENTER** - Send message
- **SHIFT+ENTER** - New line
- Supports multi-line input (up to 5 lines)
- Auto-focuses after sending
- Visual feedback during loading

## Settings & Customization

**Code Font Size** (stored in secure storage):
- Default: 20px
- Range: 12-32px (adjustable via slider)
- Quick presets: Small (14), Medium (20), Large (26)
- Stored in `flutter_secure_storage` with key `code_font_size`

**Settings Provider** (`lib/providers/settings_provider.dart`):
- Manages API key and code font size
- Notifier pattern for state updates
- Persists to `StorageService`
- Loaded on app startup via `_loadSettings()`

## Recent Changes

### 2026-01-31: Session Management & Dependency Updates
**New Feature**: Added side drawer with chat history management.

**Implementation**:
1. **Created `ChatSession` model** (`lib/data/models/chat_session.dart`):
   - Fields: id, title, messages, createdAt, updatedAt
   - Auto-generated title from first user message
   - Methods: `toJson()`, `fromJson()`, `copyWith()`

2. **Extended `StorageService`** (`lib/services/storage_service.dart`):
   - `saveSessions()` - сохранение списка сессий в JSON
   - `getSessions()` - загрузка списка сессий
   - `saveActiveSessionId()` - сохранение ID активной сессии
   - `getActiveSessionId()` - получение ID активной сессии

3. **Created `SessionProvider`** (`lib/providers/session_provider.dart`):
   - `SessionManagerState` - список сессий + активная сессия
   - `SessionManagerNotifier` - управление сессиями
   - Provider: `sessionManagerProvider`

4. **Updated `ChatProvider`** (`lib/providers/chat_provider.dart`):
   - Добавлено `currentSessionId` в `ChatState`
   - `sendMessage()` автосохраняет сессию
   - `loadSession()` загружает сообщения сессии
   - `clearChat()` создаёт новую сессию

5. **Created UI Components**:
   - `SessionDrawer` (`lib/widgets/sessions/session_drawer.dart`) - боковое меню
   - `SessionListItem` (`lib/widgets/sessions/session_list_item.dart`) - элемент списка

6. **Updated `ChatScreen`** (`lib/widgets/chat/chat_screen.dart`):
   - Добавлен Drawer в Scaffold
   - Кнопка меню (гамбургер) в AppBar
   - Интеграция с SessionManagerProvider

**Dependencies Updated**:
- flutter_riverpod: ^2.5.0 → ^3.2.0
- riverpod: ^3.2.0 (новая зависимость)
- flutter_markdown: ^0.7.0 → flutter_markdown_plus: ^0.7.0
- flutter_secure_storage: ^9.2.0 → ^10.0.0
- file_picker: ^8.0.0 → ^10.3.10
- cross_file: ^0.3.4 → ^0.3.5+2
- mime: ^1.0.0 → ^2.0.0
- uuid: ^4.0.0 (новая зависимость)
- flutter_lints: ^3.0.0 → ^6.0.0
- lints: ^6.1.0 (новая зависимость)

**How it works**:
1. При запуске загружаются сохранённые сессии
2. Активируется последняя сессия или создаётся новая
3. Каждое сообщение автосохраняется
4. Боковое меню показывает все сессии с заголовками и датами
5. Можно переключаться между сессиями
6. Можно удалять отдельные сессии или всю историю

**Changes:**
- Created: `lib/data/models/chat_session.dart`
- Created: `lib/providers/session_provider.dart`
- Created: `lib/widgets/sessions/session_drawer.dart`
- Created: `lib/widgets/sessions/session_list_item.dart`
- Modified: `lib/services/storage_service.dart` - Added session storage methods
- Modified: `lib/providers/chat_provider.dart` - Integrated with sessions
- Modified: `lib/widgets/chat/chat_screen.dart` - Added drawer
- Modified: `pubspec.yaml` - Updated dependencies

### 2026-01-26: Copy Button & Completion Indicator
**New Features**: Added copy button for assistant responses and in-message completion indicator.

**Implementation**:
1. **Copy Button in MessageBubble**:
   - Added "Копировать" button at the end of each assistant response
   - Copies full response text to clipboard
   - Shows "Ответ скопирован" notification on click
   - Located in `lib/widgets/chat/message_bubble.dart`

2. **Completion Indicator**:
   - "✓ Ответ окончен" appears at the end of assistant's last message
   - Only shows for the most recent message when not loading
   - Green color with check icon
   - Automatically appears when response completes
   - Part of `MessageBubble` widget for assistant messages

**Changes:**
- Modified: `lib/widgets/chat/message_bubble.dart` - Added copy button and completion indicator
- Uses `flutter/services.dart` for clipboard access

**How it works**:
1. Assistant generates response
2. When response completes and `isLoading` becomes false
3. "✓ Ответ окончен" appears at the bottom of the response
4. User can click "Копировать" to copy entire response
5. Notification confirms successful copy

### 2026-01-26: File Attachment Support
**New Feature**: Added ability to attach files to messages for analysis by GLM model.

**Implementation**:
1. **Created `AttachedFile` model** (`lib/data/models/attached_file.dart`):
   - Supports all file types (images, documents, videos, audio, etc.)
   - Automatic MIME type detection by extension
   - `isTextFile` property determines if file content should be read
   - `getTextContent()` method reads text files (supports UTF-8 and Latin1)
   - Image compression for large images (max 1024px)
   - Base64 encoding for API transmission
   - Files without extension treated as text files

2. **Updated `Message` model**:
   - Added `attachedFiles` field (List<AttachedFile>)
   - Modified async `toJson()` to support multimodal content
   - Text files: content is read and added to message text (wrapped in "Файл: ... --- Конец файла ---")
   - Images: sent as base64 data URLs in multimodal format
   - Creates multimodal content array when images are present

3. **Updated `ChatInputField`**:
   - Added attachment button (📎 icon) before input field
   - File preview with thumbnails for images
   - File icons for different document types (PDF, Word, Excel, etc.)
   - Remove files before sending with ❌ button
   - Support for multiple file attachment

4. **Updated `MessageBubble`**:
   - Displays attached files in user messages
   - Shows image thumbnails or file icons with names
   - Different icons for different file types

5. **Updated `ChatRequest` and `ApiService`**:
   - Async `toJson()` for multimodal content serialization
   - Sends images as base64 data URLs to API

**Dependencies Added**:
- `file_picker: ^8.0.0` - File selection dialog
- `cross_file: ^0.3.4` - Cross-platform file handling
- `image: ^4.2.0` - Image compression
- `mime: ^1.0.0` - MIME type detection

**How it works**:
1. User clicks 📎 button in chat input field
2. File picker opens (supports all file types)
3. Selected files appear as previews above input field
4. User can add message text and press ENTER
5. For text files: content is read and formatted as "Файл: name\n...content...\n--- Конец файла ---"
6. For images: converted to base64 and compressed
7. Message sent to GLM-4V with multimodal content (text + images)
8. Model responds with analysis of attached content

**Important Notes**:
- **Images** are sent to API as base64 (GLM-4V vision capability)
- **Text files** (code, configs, etc.) are read and their content is added to the message text
- Files without extension are treated as text files
- Other file types are displayed but not analyzed by model
- Images are automatically compressed to reduce API payload
- Maximum image dimension: 1024px
- File attachment not available in edit mode
- Deep copy of messages with files is created before API call to prevent data loss

**Changes:**
- Created: `lib/data/models/attached_file.dart`
- Modified: `lib/data/models/message.dart` - Added `attachedFiles` field, async `toJson()`
- Modified: `lib/data/models/chat_request.dart` - Async `toJson()` for multimodal content
- Modified: `lib/services/api_service.dart` - Uses async `toJson()`
- Modified: `lib/providers/chat_provider.dart` - `sendMessage()` accepts files parameter
- Modified: `lib/widgets/chat/chat_input_field.dart` - Added attachment button and preview
- Modified: `lib/widgets/chat/message_bubble.dart` - Displays attached files
- Modified: `pubspec.yaml` - Added file picker dependencies

### 2026-01-26: Message Editing System (Multiple Fixes)
**Initial Issue**: Message editing opened a dialog window instead of inline editing via input field.

**Second Issue**: After sending edited message, the "Режим редактирования" indicator and cancel button remained visible in UI.

**Root Cause of Second Issue**: `copyWith()` method couldn't properly reset `editingMessageId` to `null` because of the `??` operator. When passing `null`, it would fall back to the current value instead of resetting it.

**Solution**:
1. **Removed dialog-based editing**: Deleted `lib/widgets/chat/edit_message_dialog.dart` and removed `showDialog` logic from `ChatScreen`
2. **Confirmed inline editing**: `ChatInputField` already had full inline editing support built-in
3. **Fixed state reset**: Created dedicated `_clearEditingState()` method that explicitly creates a new `ChatState` with `editingMessageId: null` and `editingMessageText: null`

**Changes:**
- Removed: `lib/widgets/chat/edit_message_dialog.dart`
- Modified: `lib/widgets/chat/chat_screen.dart` - Removed showDialog logic
- Modified: `lib/providers/chat_provider.dart` - Added `_clearEditingState()`, modified `updateMessage()` and `cancelEditing()`

**How it works now:**
1. User clicks edit button on a message
2. Message text loads into input field with visual indicator "Режим редактирования (ESC — отмена)"
3. User edits text and presses ENTER
4. `_clearEditingState()` called → editing mode exits **immediately** (synchronous)
5. UI updates → indicator and cancel button disappear
6. Message list updates (all messages after edited one are deleted)
7. New request sent to API
8. Input field clears and receives focus

**Keyboard Shortcuts in Edit Mode:**
- **ENTER** - Save changes and send to API
- **ESC** - Cancel editing without sending
- **SHIFT+ENTER** - New line
- Click ❌ button - Cancel editing

---

## Known Issues & Technical Debt

### Critical Issues (2026-01-28)

1. **Тестовый файл ошибочен** - `test/widget_test.dart:7`
   - Проблема: отсутствует импорт `flutter_riverpod/flutter_riverpod.dart`
   - Исправление: добавить импорт `import 'package:flutter_riverpod/flutter_riverpod.dart';`

2. **Типизация в MessageBubble** - `lib/widgets/chat/message_bubble.dart`
   - Проблема: методы `_buildAttachedFile` и `_buildFileIcon` используют `dynamic file` вместо `AttachedFile`
   - Исправление: заменить `dynamic` на `AttachedFile`

3. **Неиспользуемый импорт** - `lib/widgets/chat/chat_screen.dart:3`
   - Проблема: импортируется `message.dart`, но не используется
   - Исправление: удалить импорт

### Performance Issues

4. **Лишние пересборки** в `ChatInputField` при добавлении файлов
   - Частые вызовы `setState` могут влиять на производительность
   - Решение: использовать `setState` только при необходимости

5. **Большие файлы**
   - Нет ограничения на размер загружаемых файлов
   - Риск: утечка памяти при загрузке очень больших файлов
   - Решение: добавить ограничение (например, 10MB)

6. **Блокирующие операции**
   - Чтение файлов в `getTextContent()` может блокировать UI поток
   - Решение: использовать `compute()` для чтения в изолированном потоке

### Deprecated APIs

7. **Устаревшие API клавиатуры** - `lib/widgets/chat/chat_input_field.dart`
   - `RawKeyEvent`, `RawKeyDownEvent` → использовать `KeyEvent`, `KeyDownEvent`
   - `isShiftPressed` → использовать `HardwareKeyboard.instance.isShiftPressed`
   - `RawKeyboardListener` → использовать `KeyboardListener`

8. **Устаревший API цветов** - несколько файлов
   - `withOpacity()` → использовать `.withValues()`
   - Затронуты: `chat_input_field.dart`, `chat_screen.dart`

### Code Quality

9. **Отсутствие блоков** - `lib/data/models/attached_file.dart`
   - Строки 81, 93, 99, 105, 109, 113 - управляющие структуры без фигурных скобок
   - Рекомендация: добавлять блоки для улучшения читаемости

10. **Комментарии не на русском**
    - Некоторые файлы содержат комментарии на английском (например, `api_constants.dart`)
    - Требование согласно CLAUDE.md: все комментарии на русском

### Dependencies

11. **Устаревшие пакеты**
    - 18 пакетов имеют более новые версии
    - Пакет `flutter_markdown` прекращён, заменён на `flutter_markdown_plus`

### Testing

12. **Минимальное покрытие тестами**
    - Только один тестовый файл
    - Нет тестов для API сервисов, провайдеров, обработки ошибок
    - Рекомендация: добавить unit и widget тесты

### Security Considerations

13. **Логирование чувствительных данных**
    - `attached_file.dart:174` и `message.dart:51` логируются имена файлов
    - Риск: имена файлов могут содержать чувствительную информацию
    - Решение: убрать или анонимизировать логирование

14. **Нет валидации файлов**
    - Загрузка произвольных файлов без ограничений
    - Риск: потенциальная уязвимость безопасности
    - Решение: добавить валидацию типа и размера

### Architecture

15. **Потенциальная утечка памяти** в `ChatNotifier`
    - `StreamSubscription? _streamSubscription` может быть не отменён
    - Решение: проверить dispose на null

16. **Race condition**
    - При быстрой последовательной отправке сообщений возможны конфликты
    - Deep copy в `chat_provider.dart:111` может не предотвратить все проблемы
