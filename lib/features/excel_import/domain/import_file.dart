import 'dart:typed_data';

class ImportFile {
  ImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  String get extension {
    final separator = name.lastIndexOf('.');
    return separator == -1 ? '' : name.substring(separator + 1).toLowerCase();
  }

  int get sizeInBytes => bytes.lengthInBytes;
}
