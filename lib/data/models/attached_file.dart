import 'dart:io';
import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';

/// Тип прикреплённого файла
enum AttachedFileType {
  /// Изображение
  image,

  /// Документ
  document,

  /// Другой тип файла
  other,
}

/// Модель прикреплённого файла
class AttachedFile {
  /// Путь к файлу
  final String path;

  /// Имя файла
  final String name;

  /// MIME тип файла
  final String mimeType;

  /// Размер файла в байтах
  final int size;

  /// Тип файла
  final AttachedFileType type;

  /// Base64 представление файла (для отправки в API)
  String? _base64Data;

  AttachedFile({
    required this.path,
    required this.name,
    required this.mimeType,
    required this.size,
    required this.type,
  });

  /// Создание AttachedFile из XFile
  factory AttachedFile.fromXFile(XFile file) {
    String mimeType = file.mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';

    // Если MIME тип общий, пытаемся определить по расширению файла
    if (mimeType == 'application/octet-stream') {
      mimeType = _guessMimeTypeFromExtension(file.path);
    }

    final type = _getTypeFromMimeType(mimeType);

    return AttachedFile(
      path: file.path,
      name: file.name,
      mimeType: mimeType,
      size: 0, // Будет заполнен при чтении
      type: type,
    );
  }

  /// Определение MIME типа по расширению файла
  static String _guessMimeTypeFromExtension(String filePath) {
    final extension = filePath.toLowerCase();
    if (extension.endsWith('.dart')) return 'text/x-dart';
    if (extension.endsWith('.py')) return 'text/x-python';
    if (extension.endsWith('.js')) return 'text/javascript';
    if (extension.endsWith('.ts')) return 'text/typescript';
    if (extension.endsWith('.jsx')) return 'text/jsx';
    if (extension.endsWith('.tsx')) return 'text/tsx';
    if (extension.endsWith('.java')) return 'text/x-java-source';
    if (extension.endsWith('.cpp') ||
        extension.endsWith('.cc') ||
        extension.endsWith('.cxx')) return 'text/x-c++src';
    if (extension.endsWith('.c')) return 'text/x-csrc';
    if (extension.endsWith('.h')) return 'text/x-chdr';
    if (extension.endsWith('.cs')) return 'text/x-csharp';
    if (extension.endsWith('.go')) return 'text/x-go';
    if (extension.endsWith('.rs')) return 'text/x-rust';
    if (extension.endsWith('.php')) return 'text/x-php';
    if (extension.endsWith('.rb')) return 'text/x-ruby';
    if (extension.endsWith('.swift')) return 'text/x-swift';
    if (extension.endsWith('.kt')) return 'text/x-kotlin';
    if (extension.endsWith('.scala')) return 'text/x-scala';
    if (extension.endsWith('.sh') || extension.endsWith('.bash'))
      return 'text/x-shellscript';
    if (extension.endsWith('.zsh')) return 'text/x-zsh';
    if (extension.endsWith('.fish')) return 'text/x-fish';
    if (extension.endsWith('.ps1')) return 'text/x-powershell';
    if (extension.endsWith('.sql')) return 'text/x-sql';
    if (extension.endsWith('.html') || extension.endsWith('.htm'))
      return 'text/html';
    if (extension.endsWith('.css')) return 'text/css';
    if (extension.endsWith('.scss')) return 'text/x-scss';
    if (extension.endsWith('.sass')) return 'text/x-sass';
    if (extension.endsWith('.less')) return 'text/x-less';
    if (extension.endsWith('.yaml') || extension.endsWith('.yml'))
      return 'text/x-yaml';
    if (extension.endsWith('.toml')) return 'text/x-toml';
    if (extension.endsWith('.ini')) return 'text/x-ini';
    if (extension.endsWith('.cfg') || extension.endsWith('.conf'))
      return 'text/plain';
    if (extension.endsWith('.json')) return 'application/json';
    if (extension.endsWith('.xml')) return 'text/xml';
    if (extension.endsWith('.md') || extension.endsWith('.markdown'))
      return 'text/markdown';
    if (extension.endsWith('.txt')) return 'text/plain';
    if (extension.endsWith('.log')) return 'text/plain';
    return 'application/octet-stream';
  }

  /// Определение типа файла по MIME типу
  static AttachedFileType _getTypeFromMimeType(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return AttachedFileType.image;
    } else if (mimeType.startsWith('text/') ||
        mimeType == 'application/pdf' ||
        mimeType.contains('document') ||
        mimeType.contains('sheet')) {
      return AttachedFileType.document;
    }
    return AttachedFileType.other;
  }

  /// Чтение содержимого текстового файла
  Future<String> getTextContent() async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return '[Ошибка: файл не найден: ${file.path}]';
      }

      final bytes = await file.readAsBytes();

      // Пытаемся декодировать как UTF-8
      try {
        final content = utf8.decode(bytes);
        // Проверяем, что содержимое не пустое
        if (content.trim().isEmpty) {
          return '[Файл пуст: $name]';
        }
        return content;
      } catch (e) {
        // Если UTF-8 не сработал, пытаемся latin1
        try {
          return latin1.decode(bytes);
        } catch (e2) {
          return '[Не удалось декодировать файл: $name. Ошибка: $e]';
        }
      }
    } catch (e) {
      return '[Ошибка при чтении файла $name: $e]';
    }
  }

  /// Проверка, является ли файл текстовым (для включения в сообщение)
  bool get isTextFile {
    // Проверяем по MIME типу
    if (mimeType.startsWith('text/')) return true;

    // Для application/octet-stream проверяем по имени файла
    // Если файл без расширения - считаем его текстовым (пользователь сможет прочитать)
    if (mimeType == 'application/octet-stream') {
      final lowerName = name.toLowerCase();
      // Файл без расширения или маленький файл - считаем текстовым
      if (!lowerName.contains('.') || lowerName.startsWith('.')) {
        print('[AttachedFile] Файл $name без расширения, считаем текстовым');
        return true;
      }
    }

    // Проверяем специальные типы, которые являются текстовыми
    final textMimeTypes = [
      'application/json',
      'application/javascript',
      'application/xml',
      'application/x-yaml',
      'application/x-toml',
      'application/x-sh',
      'application/x-python',
      'application/x-ruby',
      'application/x-perl',
      'application/x-php',
      'application/x-java-source',
      'application/x-csharp',
      'application/x-go',
      'application/x-rust',
      'application/x-kotlin',
      'application/x-scala',
      'application/x-swift',
      'application/xhtml+xml',
    ];

    if (textMimeTypes.any((type) => mimeType.contains(type))) {
      return true;
    }

    final lowerName = name.toLowerCase();

    // Проверяем файлы без расширения по имени
    final textFileNames = [
      'dockerfile',
      'makefile',
      'procfile',
      'rakefile',
      'gemfile',
      'capfile',
      'todo',
      'readme',
      'license',
      'authors',
      'contributing',
      'changelog',
      'version',
      'manifest',
      'vagrantfile',
      'rvmrc',
      'gemfile.lock',
      'package',
      'podfile',
      'cartfile',
      'composer.lock',
      'requirements',
      'pipfile',
      'tox.ini',
      'bzrignore',
      'hgignore',
      'cvsignore',
      'gitkeep',
      'gitmodules',
      'mailmap',
      'desc',
      'keywords',
      'license-files',
    ];

    // Проверяем, что файл без расширения (нет точки в имени, кроме скрытых файлов)
    if (!lowerName.contains('.') || lowerName.startsWith('.')) {
      // Для скрытых файлов проверяем имя после точки
      final fileNameToCheck =
          lowerName.startsWith('.') ? lowerName.substring(1) : lowerName;
      if (textFileNames.contains(fileNameToCheck)) {
        return true;
      }
    }

    // Проверяем по расширению файла (более надёжно)
    final textExtensions = [
      '.dart',
      '.py',
      '.js',
      '.ts',
      '.jsx',
      '.tsx',
      '.java',
      '.cpp',
      '.cc',
      '.cxx',
      '.c',
      '.h',
      '.hpp',
      '.cs',
      '.go',
      '.rs',
      '.php',
      '.rb',
      '.swift',
      '.kt',
      '.scala',
      '.sh',
      '.bash',
      '.zsh',
      '.fish',
      '.ps1',
      '.psm1',
      '.psd1',
      '.sql',
      '.html',
      '.htm',
      '.css',
      '.scss',
      '.sass',
      '.less',
      '.yaml',
      '.yml',
      '.toml',
      '.ini',
      '.cfg',
      '.conf',
      '.json',
      '.xml',
      '.md',
      '.markdown',
      '.txt',
      '.log',
      '.gitignore',
      '.gitattributes',
      '.env',
      '.env.example',
      '.dockerignore',
      '.editorconfig',
      '.eslintrc',
      '.prettierrc',
      '.babelrc',
      '.tslintrc',
      '.pug-lintrc',
      '.yarnrc',
    ];

    return textExtensions.any((ext) => lowerName.endsWith(ext));
  }

  /// Получение base64 данных файла
  Future<String> getBase64Data() async {
    if (_base64Data != null) {
      return _base64Data!;
    }

    final file = File(path);
    final bytes = await file.readAsBytes();

    // Если это изображение, сжимаем его для уменьшения размера
    if (type == AttachedFileType.image) {
      try {
        final image = img.decodeImage(bytes);
        if (image != null) {
          // Ограничиваем размер изображения до 1024px по большей стороне
          const maxDimension = 1024;
          if (image.width > maxDimension || image.height > maxDimension) {
            final thumbnail = img.copyResize(
              image,
              width: image.width > image.height ? maxDimension : null,
              height: image.height >= image.width ? maxDimension : null,
              interpolation: img.Interpolation.linear,
            );
            final compressed = img.encodeJpg(thumbnail, quality: 85);
            _base64Data = base64Encode(compressed);
          } else {
            _base64Data = base64Encode(bytes);
          }
        } else {
          _base64Data = base64Encode(bytes);
        }
      } catch (e) {
        // Если сжатие не удалось, используем оригинал
        _base64Data = base64Encode(bytes);
      }
    } else {
      // Для не-изображений просто кодируем в base64
      _base64Data = base64Encode(bytes);
    }

    return _base64Data!;
  }

  /// Проверка, является ли файл изображением
  bool get isImage => type == AttachedFileType.image;

  /// Проверка, является ли файл документом
  bool get isDocument => type == AttachedFileType.document;

  /// Создание копии с изменёнными полями
  AttachedFile copyWith({
    String? path,
    String? name,
    String? mimeType,
    int? size,
    AttachedFileType? type,
  }) {
    return AttachedFile(
      path: path ?? this.path,
      name: name ?? this.name,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      type: type ?? this.type,
    );
  }
}
