import 'package:flutter/material.dart';
import '../../domain/entities/praise_material.dart';
import 'pdf_reader_page.dart';
import 'audio_reader_page.dart';
import 'lyrics_reader_page.dart';

/// Roteador para abrir o leitor apropriado baseado no tipo de material
class ReaderRouter {
  /// Abre o leitor apropriado para o material
  static Widget getReaderPage({
    required PraiseMaterial material,
    String? materialName,
  }) {
    // Determina o tipo de material baseado no material_type ou extensão do arquivo
    final extension = _getFileExtension(material.path);
    final materialTypeName = material.materialType?.name.toLowerCase() ?? '';

    if (materialTypeName.contains('pdf') || extension == 'pdf') {
      return PdfReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    } else if (materialTypeName.contains('audio') ||
        ['mp3', 'wav', 'ogg', 'm4a'].contains(extension)) {
      return AudioReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    } else if (materialTypeName.contains('text') ||
        materialTypeName.contains('lyric') ||
        ['txt', 'md'].contains(extension)) {
      return LyricsReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    } else {
      // Fallback: tenta abrir como texto
      return LyricsReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    }
  }

  static String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }
}
