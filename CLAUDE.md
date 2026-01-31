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

# Format code
dart format .
```

## Architecture Overview

This is a Flutter chat application for AI models with support for multiple providers (GLM, OpenRouter). The architecture follows a clean separation of concerns with Riverpod for state management.

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
5. `ChatRequest` created with dynamic model from settings
6. `request.toJson()` called asynchronously to serialize messages and read file contents
7. Text files: content read and added to message text
8. Images: converted to base64 and added to multimodal content array
9. `ApiService.createStreamingChatCompletion()` sends to selected provider endpoint
10. Response parsed to `ChatResponse` and converted to `Message`
11. Assistant message added to state
12. "✓ Ответ окончен" indicator appears in last assistant message

### AI Provider System

The app uses a **Strategy pattern** with abstract `AIProvider` base class to support multiple AI APIs:

**Providers** (`lib/services/providers/`):
- `base_provider.dart` - Abstract base class defining provider interface
- `glm_provider.dart` - Implementation for Zhipu GLM API
- `openrouter_provider.dart` - Implementation for OpenRouter API
- `provider_factory.dart` - Factory for creating and retrieving providers

**Provider Interface**:
```dart
abstract class AIProvider {
  String get providerId;           // Unique ID (e.g., 'glm', 'openrouter')
  String get displayName;          // Display name for UI
  String get baseUrl;              // API base URL
  String get chatEndpoint;         // Chat endpoint
  String get defaultModel;         // Default model
  List<String> get modelExamples;  // Example models for autocomplete

  Map<String, String> buildHeaders(String apiKey);
  bool isValidApiKey(String apiKey);
}
```

**Settings Integration**:
- Provider selection stored in secure storage (`selected_provider`)
- Model name stored separately (`model_name`)
- API keys stored separately for each provider
- UI allows switching between providers with dropdown
- Model name editable with autocomplete examples

**Supported Providers**:
1. **GLM (Zhipu AI)**:
   - Base URL: `https://open.bigmodel.cn/api/paas/v4`
   - Models: `glm-4.7`, `glm-4-plus`, `glm-4-flash`
   - API Key stored in `glm_api_key`

2. **OpenRouter**:
   - Base URL: `https://openrouter.ai/api/v1`
   - Models: `anthropic/claude-3.5-sonnet`, `openai/gpt-4o`, `google/gemini-pro-1.5`, etc.
   - API Key stored in `openrouter_api_key`
   - Requires additional headers: `HTTP-Referer`, `X-Title`

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

`ApiService` (lib/services/api_service.dart) handles all HTTP communication with AI providers:
- Accepts `AIProvider` parameter for flexible provider switching
- Uses `provider.buildHeaders()` for provider-specific headers
- Uses `provider.baseUrl` and `provider.chatEndpoint` for URLs
- Throws `ApiException` for error cases (401, 429, 400, 5xx)
- **Configurable timeout**: default 60 seconds in code, but uses settings value (120s default, range 30-300s)
- Returns typed `ChatResponse` objects

**Methods**:
```dart
Future<ChatResponse> createChatCompletion(
  AIProvider provider,
  String apiKey,
  ChatRequest request,
  {Duration? timeout}
)

Stream<StreamedChatEvent> createStreamingChatCompletion(
  AIProvider provider,
  String apiKey,
  ChatRequest request,
  {Duration? timeout}
)
```

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
- Timeout: configurable in settings (30-300s range, default 120s in UI, 60s in code)
- Max tokens: 4096

## Theme

Material 3 dark theme configured in `lib/core/theme/app_theme.dart`. App uses `theme: AppTheme.darkTheme` in MaterialApp.

**Design Philosophy** (Updated 2026-01-26):
- **Minimalistic**: Clean UI without avatars, minimal borders, subtle colors
- **Professional**: User messages in blue (#60A5FA), assistant in dark (#1E293B)
- **Typography**: Optimized font sizes (15px for messages, configurable font)
- **Spacing**: Consistent 20px horizontal padding, 6px vertical for messages

## User Input & Keyboard Shortcuts

**Chat Input Field** (`lib/widgets/chat/chat_input_field.dart`):
- **ENTER** - Send message
- **SHIFT+ENTER** - New line
- **ESC** - Cancel editing mode
- Supports multi-line input (up to 5 lines)
- Auto-focuses after sending
- Visual feedback during loading

## Settings & Customization

**Font Size** (stored in secure storage):
- Default: 20px
- Range: 12-32px (adjustable via slider)
- Quick presets: Small (14), Medium (20), Large (26)
- Stored in `flutter_secure_storage` with key `code_font_size`
- Applied to ALL messages (user and assistant)

**Request Timeout** (stored in secure storage):
- Default: 120 seconds in UI settings
- Range: 30-300 seconds (adjustable via slider)
- Quick presets: 30s, 60s, 120s, 5min
- Stored in `flutter_secure_storage` with key `request_timeout`
- Used in API requests (configurable per request)
- Code default: 60 seconds if not specified in settings

**Settings Provider** (`lib/providers/settings_provider.dart`):
- Manages API key, font size, and request timeout
- Notifier pattern for state updates
- Persists to `StorageService`
- Loaded on app startup via `_loadSettings()`

## Dependencies Status

Актуальные версии пакетов (из pubspec.yaml):

### State Management
- flutter_riverpod: ^2.6.1
- riverpod: ^2.6.1

### HTTP & API
- http: ^1.2.0

### Markdown & Code
- flutter_markdown_plus: ^1.0.7 (заменён flutter_markdown)
- markdown: ^7.2.0
- flutter_highlight: ^0.7.0
- highlight: ^0.7.0

### Storage
- flutter_secure_storage: ^10.0.0

### File Handling
- file_picker: ^10.3.10
- cross_file: ^0.3.5+2
- image: ^4.2.0
- mime: ^2.0.0

### Utilities
- uuid: ^4.0.0

### Dev Dependencies
- flutter_lints: ^6.0.0
- lints: ^6.1.0

**Статус:** Все зависимости в актуальном состоянии.

## Code Style Guidelines

### Обязательные требования:
1. **Все комментарии на русском** - включая JSDoc для публичных API
2. **Типизация** - избегать `dynamic`, использовать конкретные типы
3. **Фигурные скобки** - всегда использовать для управляющих структур
4. **Именование** - camelCase для переменных, PascalCase для классов

### Форматирование:
- Используйте `dart format .` для форматирования
- Максимальная длина строки: 80 символов

## Testing Strategy

### Текущее состояние:
- **1 тестовый файл:** `test/widget_test.dart`
- **Покрытие:** Минимальное (базовый тест запуска приложения)

### План развития:
- [ ] Unit тесты для `ApiService`
- [ ] Unit тесты для `StorageService`
- [ ] Widget тесты для `MessageBubble`
- [ ] Widget тесты для `ChatInputField`
- [ ] Интеграционные тесты для потока сообщений

## Recent Changes

### 2026-01-31: Исправление UI и сохранения модели
**Fixes & Improvements**: Исправлены критические ошибки с сохранением модели и отображением UI.

**Исправления**:
1. **Исправлено сохранение модели** (`lib/widgets/settings/settings_screen.dart`):
   - Исправлена кнопка сохранения - теперь использует `_modelNameController.text` вместо `controller.text`
   - Улучшена логика `didChangeDependencies()` - не перезаписывает контроллер если он содержит правильное значение
   - Добавлена валидация - проверка на пустую строку перед сохранением

2. **Исправлена логика смены провайдера** (`lib/providers/settings_provider.dart`):
   - Умная логика определения модели по умолчанию при переключении провайдеров
   - Проверка: если сохранена дефолтная модель GLM ("glm-4.7") для OpenRouter - заменяется на дефолтную модель OpenRouter
   - Добавлено отладочное логирование для диагностики

3. **Динамические названия моделей в UI** (`lib/widgets/chat/chat_screen.dart`):
   - AppBar показывает название приложения на основе провайдера/модели (например, "GPT Chat" для OpenRouter)
   - Индикатор загрузки показывает название модели: "gpt-4o думает..." вместо "GLM 4.7 думает..."
   - Заголовок сообщения показывает название модели (с удалением префикса провайдера)
   - Добавлен метод `_getModelDisplayName()` для красивого отображения названий

**Проблемы, которые были исправлены**:
- ❌ Модель не сохранялась при выходе из настроек → ✅ Теперь сохраняется корректно
- ❌ Кнопка сохранения не работала → ✅ Теперь использует правильный контроллер
- ❌ Название "GLM 4.7" везде → ✅ Теперь динамическое название выбранной модели
- ❌ Модель перезаписывалась на дефолтную при входе в настройки → ✅ Умная логика проверки

**Результат**:
- ✅ Пользователь может выбирать и сохранять любую модель
- ✅ Модель корректно сохраняется и загружается при повторном входе
- ✅ UI отображает актуальную информацию о выбранной модели
- ✅ Работает для всех провайдеров (GLM, OpenRouter)

**Changes**:
- Modified: `lib/providers/settings_provider.dart` - Умная логика setProvider()
- Modified: `lib/widgets/settings/settings_screen.dart` - Исправлено сохранение
- Modified: `lib/widgets/chat/chat_screen.dart` - Динамические названия

### 2026-01-31: OpenRouter Support & Multi-Provider Architecture
**New Feature**: Added support for OpenRouter API with flexible provider selection system.

**Implementation**:
1. **Created Provider Architecture** (`lib/services/providers/`):
   - `base_provider.dart` - Abstract base class for all AI providers
   - `glm_provider.dart` - GLM (Zhipu AI) implementation
   - `openrouter_provider.dart` - OpenRouter implementation
   - `provider_factory.dart` - Factory for provider management

2. **Extended StorageService** (`lib/services/storage_service.dart`):
   - `saveSelectedProvider()` - сохранение выбранного провайдера
   - `getSelectedProvider()` - загрузка провайдера (default 'glm')
   - `saveModelName()` - сохранение названия модели
   - `getModelName()` - загрузка модели (default 'glm-4.7')
   - `saveOpenRouterApiKey()` - сохранение API ключа OpenRouter
   - `getOpenRouterApiKey()` - загрузка API ключа OpenRouter
   - `deleteOpenRouterApiKey()` - удаление API ключа OpenRouter

3. **Updated SettingsProvider** (`lib/providers/settings_provider.dart`):
   - Added `selectedProviderId`, `modelName`, `maskedOpenRouterApiKey`, `isValidOpenRouterApiKey` to state
   - `setProvider()` - смена провайдера с установкой модели по умолчанию
   - `setModelName()` - обновление названия модели
   - `setOpenRouterApiKey()` - сохранение API ключа OpenRouter
   - `clearOpenRouterApiKey()` - удаление API ключа OpenRouter
   - `getApiKey()` - возвращает ключ для текущего провайдера
   - `getCurrentProvider()` - возвращает объект провайдера

4. **Updated ApiService** (`lib/services/api_service.dart`):
   - Added `AIProvider provider` parameter to methods
   - Uses `provider.buildHeaders()` for provider-specific headers
   - Uses `provider.baseUrl` and `provider.chatEndpoint` for URLs
   - Maintains backward compatibility with legacy methods

5. **Updated ChatProvider** (`lib/providers/chat_provider.dart`):
   - `sendMessage()` now uses dynamic provider from settings
   - Uses `modelName` from settings instead of hardcoded model
   - Logs provider and model information

6. **Redesigned Settings Screen** (`lib/widgets/settings/settings_screen.dart`):
   - Provider dropdown (GLM / OpenRouter)
   - Model name input with autocomplete examples
   - Dynamic info card based on selected provider
   - Separate API key management per provider

**Supported Models**:
- **GLM**: `glm-4.7`, `glm-4-plus`, `glm-4-flash`, `glm-4-air`
- **OpenRouter**: `anthropic/claude-3.5-sonnet`, `openai/gpt-4o`, `google/gemini-pro-1.5`, `meta-llama/llama-3.1-70b`, etc.

**Benefits**:
- Easy switching between AI providers
- Support for multiple models through single interface
- Easy to add new providers in future
- Backward compatible with existing GLM setup

**Changes**:
- Created: `lib/services/providers/base_provider.dart`
- Created: `lib/services/providers/glm_provider.dart`
- Created: `lib/services/providers/openrouter_provider.dart`
- Created: `lib/services/providers/provider_factory.dart`
- Modified: `lib/services/storage_service.dart` - Added provider/model storage
- Modified: `lib/providers/settings_provider.dart` - Added provider management
- Modified: `lib/services/api_service.dart` - Added provider parameter
- Modified: `lib/providers/chat_provider.dart` - Uses provider from settings
- Modified: `lib/widgets/settings/settings_screen.dart` - Redesigned UI

### 2026-01-31: Безопасная прокрутка чата
**Fix**: Исправлена ошибка "ScrollController not attached" при прокрутке чата.

**Implementation**:
- Метод `_scrollToBottom()` теперь использует `WidgetsBinding.instance.addPostFrameCallback()`
- Заменён `Future.delayed()` на более надёжный механизм

**Changes:**
- Modified: `lib/widgets/chat/chat_screen.dart:249-256`

### 2026-01-31: API Timeout Settings & Performance Improvements
**New Features**: Added configurable API timeout and improved loading indicators.

**Implementation**:
1. **Timeout Settings** (`lib/providers/settings_provider.dart`):
   - Added `requestTimeout` field to `SettingsState` (default 120s)
   - `setRequestTimeout()` method for updating timeout
   - Stored in secure storage with key `request_timeout`
   - Range: 30-300 seconds with quick presets

2. **Settings UI** (`lib/widgets/settings/settings_screen.dart`):
   - New "Timeout Settings" card with slider
   - Quick presets: 30s, 60s, 120s, 5min
   - Real-time value display
   - `_TimeoutButton` widget for presets

3. **API Service** (`lib/services/api_service.dart`):
   - Added optional `timeout` parameter to methods
   - `createChatCompletion()` accepts custom timeout
   - `createStreamingChatCompletion()` accepts custom timeout
   - Default: 60 seconds if not specified

4. **Chat Provider Integration** (`lib/providers/chat_provider.dart`):
   - Reads timeout from settings before API call
   - Logs timeout value for debugging
   - Passes timeout to API service

5. **Improved Loading Indicator** (`lib/widgets/chat/chat_screen.dart`):
   - Enhanced "GLM thinks..." indicator with better styling
   - Added explanatory text about wait time
   - Larger spinner (20x20 instead of 16x16)
   - Better typography (15px bold, 12px subtitle)

6. **Response Time Logging** (`lib/providers/chat_provider.dart`):
   - Logs start time, elapsed time, and response length
   - Helps track API performance
   - Example: `Ответ сгенерирован за 3.456с (3456мс)`

**Changes:**
- Modified: `lib/core/constants/api_constants.dart` - Increased default timeout to 120s
- Modified: `lib/providers/settings_provider.dart` - Added timeout management
- Modified: `lib/services/storage_service.dart` - Added timeout storage methods
- Modified: `lib/services/api_service.dart` - Added timeout parameter
- Modified: `lib/providers/chat_provider.dart` - Integrated timeout settings
- Modified: `lib/widgets/settings/settings_screen.dart` - Added timeout UI
- Modified: `lib/widgets/chat/chat_screen.dart` - Improved loading indicator

**User Benefits**:
- Configurable timeout for complex queries
- Better visibility during long responses
- Performance tracking via logs

### 2026-01-31: Font Size for All Messages
**New Feature**: Font size setting now applies to all messages (user and assistant).

**Implementation**:
1. **MessageBubble Update** (`lib/widgets/chat/message_bubble.dart`):
   - Added `fontSize` parameter from settings
   - Applied to main text with proper scaling
   - Markdown headers scaled proportionally (h1=1.6x, h2=1.35x, h3=1.2x)
   - Code blocks scaled to 0.9x of base font size

**Changes:**
- Modified: `lib/widgets/chat/message_bubble.dart` - Applied font size everywhere

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
- flutter_riverpod: ^2.6.1
- riverpod: ^2.6.1
- flutter_markdown_plus: ^1.0.7 (заменил flutter_markdown)
- flutter_secure_storage: ^10.0.0
- file_picker: ^10.3.10
- cross_file: ^0.3.5+2
- mime: ^2.0.0
- uuid: ^4.0.0
- flutter_lints: ^6.0.0
- lints: ^6.1.0

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
- `file_picker: ^10.3.10` - File selection dialog
- `cross_file: ^0.3.5+2` - Cross-platform file handling
- `image: ^4.2.0` - Image compression
- `mime: ^2.0.0` - MIME type detection

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

### 2026-01-31: Dropdown Model Selection & Enhanced Error Handling
**New Features**: Replaced Autocomplete with Dropdown for model selection, added comprehensive error messages.

**Implementation**:

1. **Dropdown Model Selection** (`lib/widgets/settings/settings_screen.dart`):
   - Replaced Autocomplete TextField with DropdownButtonFormField
   - Models loaded automatically on settings open and provider switch
   - Grouped display for OpenRouter models with separators (── provider)
   - Alphabetical sorting within provider groups
   - Disabled separator items (visual grouping only)
   - Model count display

2. **Extended GLM Models List** (`lib/providers/settings_provider.dart`):
   - Added 29 GLM models including legacy versions
   - GLM-4 series: glm-4.7, glm-4-plus, glm-4-flash, glm-4-air, glm-4-airx, glm-4-long
   - GLM-3 series: glm-3-turbo, glm-3-turbo-0524, glm-3, glm-3a
   - CodeGeeX series: codegeex-4, codegeex-4-all
   - Sorted alphabetically for easy navigation

3. **OpenRouter API Integration** (`lib/services/api_service.dart`):
   - Added `ApiModel` class for parsing model list responses
   - `getAvailableModels()` method fetches models from OpenRouter
   - Handles int/String conversion for context_length field
   - Groups models by provider and sorts alphabetically
   - Falls back to model examples on error or missing API key

4. **Enhanced Error Messages** (`lib/services/api_service.dart`):
   - 402 error: "Недостаточно средств на балансе. Пополните баланс на сайте провайдера."
   - Added `displayText` getter to ApiException for clean UI messages
   - Updated ChatProvider to use `displayText` instead of `toString()`

5. **Model Validation on Provider Switch** (`lib/providers/settings_provider.dart`):
   - `setProvider()` now validates if current model is supported
   - Automatically switches to default model if incompatible
   - Prevents using GLM models with OpenRouter and vice versa

6. **Improved Model Identity Handling** (`lib/data/models/chat_request.dart`):
   - System prompt forces model to correctly identify itself
   - Detects identity questions ("какая ты модель", "who are you")
   - Clears history for identity questions to prevent confusion
   - Explicit instruction: "Do NOT claim to be ChatGPT, GPT-4, Claude..."

7. **Request Logging** (`lib/services/api_service.dart`):
   - Logs full request body for debugging
   - Logs response model field to verify actual model
   - Tracks provider, timing, and response length

**Benefits**:
- Easy model selection from organized dropdown
- 29 GLM models including legacy versions
- 300+ OpenRouter models grouped by provider
- Clear error messages for common issues (402 payment required)
- Models correctly identify themselves
- Verified model switching (different providers, response times)

**Changes**:
- Modified: `lib/providers/settings_provider.dart` - Dropdown, loadAvailableModels(), GLM models list, validation
- Modified: `lib/widgets/settings/settings_screen.dart` - Dropdown UI, group separators, count display
- Modified: `lib/services/api_service.dart` - ApiModel, getAvailableModels(), error handling, logging
- Modified: `lib/data/models/chat_request.dart` - System prompt, history filtering for identity questions
- Modified: `lib/providers/chat_provider.dart` - Uses displayText for error messages
- Created: `lib/providers/service_providers.dart` - Exports apiServiceProvider

---

## Known Issues & Technical Debt

### Critical (Критические проблемы)

1. **Типизация `dynamic` в MessageBubble** - `lib/widgets/chat/message_bubble.dart:119,149`
   - Проблема: методы `_buildAttachedFile` и `_buildFileIcon` используют `dynamic file` вместо `AttachedFile`
   - Риск: потеря типобезопасности, потенциальные ошибки runtime
   - Исправление: заменить `dynamic` на `AttachedFile`

### High (Высокий приоритет - производительность и безопасность)

2. **Лишние пересборки в ChatInputField** - `lib/widgets/chat/chat_input_field.dart`
   - Места: строки 64, 89, 118, 149
   - Проблема: частые вызовы `setState` могут влиять на производительность
   - Решение: оптимизировать вызовы setState, объединять обновления состояния

3. **Большие файлы без ограничения размера**
   - Проблема: нет валидации размера в `_pickFiles()` (chat_input_field.dart:40)
   - Риск: утечка памяти при загрузке очень больших файлов
   - Решение: добавить ограничение 10MB с понятным сообщением пользователю

4. **Блокирующие операции ввода-вывода** - `lib/data/models/attached_file.dart:140-167`
   - Проблема: `getTextContent()` блокирует UI поток при чтении файлов
   - Решение: использовать `compute()` для чтения в изолированном потоке

5. **Отсутствие валидации файлов** (Security)
   - Проблема: загрузка произвольных файлов без проверки типа и размера
   - Риск: потенциальная уязвимость безопасности
   - Решение: добавить валидацию типа MIME и размера файла

6. **Логирование чувствительных данных** (Security) - `lib/data/models/attached_file.dart:144,181`
   - Проблема: логируются имена файлов (могут содержать чувствительную информацию)
   - Решение: убрать или анонимизировать логирование имён файлов

### Medium (Средний приоритет - deprecated APIs)

7. **Устаревшие API клавиатуры** - `lib/widgets/chat/chat_input_field.dart:161`
   - `RawKeyEvent` → использовать `KeyEvent`
   - `RawKeyDownEvent` → использовать `KeyDownEvent`
   - `isShiftPressed` → использовать `HardwareKeyboard.instance.isShiftPressed`
   - `RawKeyboardListener` → использовать `KeyboardListener`

8. **Устаревший API цветов** - несколько файлов
   - `withOpacity()` → использовать `.withValues()`
   - Затронуты: session_drawer.dart, session_list_item.dart, chat_screen.dart, chat_input_field.dart:223, 313

### Low (Низкий приоритет - качество кода)

9. **Отсутствие фигурных скобок** - `lib/data/models/attached_file.dart`
   - Строки: 79-83, 94-96, 101-103, 108-110, 113-114
   - Проблема: управляющие структуры без фигурных скобок
   - Решение: добавить блоки для улучшения читаемости

10. **Минимальное покрытие тестами**
    - Только 1 тестовый файл (`test/widget_test.dart`)
    - Нет тестов для API сервисов, провайдеров, обработки ошибок
    - Решение: добавить unit и widget тесты

### Примечание
Все проблемы из списка 2026-01-28 были проверены и обновлены. Устаревшие проблемы удалены.
