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

### Widget Organization

```
lib/widgets/
├── chat/           # Chat-specific UI (ChatScreen, MessageBubble, ChatInputField)
├── code/           # Code rendering (CodeBlockWidget, CopyButton)
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
