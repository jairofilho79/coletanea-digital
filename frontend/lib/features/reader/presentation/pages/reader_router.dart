import 'package:flutter/material.dart';
import '../../domain/entities/praise_material.dart';
import 'pdf_reader_page.dart';
import 'audio_reader_page.dart';
import 'lyrics_reader_page.dart';

/// Roteador para abrir o leitor apropriado baseado no tipo de material
class ReaderRouter {
  /// Abre o leitor apropriado para o material.
  /// Prioriza a extensão do arquivo para evitar abrir PDF/áudio como letra quando
  /// o materialType vem incorreto (ex. "Letra") da API.
  static Widget getReaderPage({
    required PraiseMaterial material,
    String? materialName,
  }) {
    final extension = _getFileExtension(material.path);
    final path = material.path;
    final materialTypeName = material.materialType?.name.toLowerCase() ?? '';

    if (extension == 'pdf' || path.toLowerCase().contains('.pdf')) {
      return PdfReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    }
    if (['mp3', 'wav', 'ogg', 'm4a'].contains(extension) ||
        materialTypeName.contains('audio')) {
      return AudioReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    }
    if (materialTypeName.contains('text') ||
        materialTypeName.contains('lyric') ||
        materialTypeName == 'letra' ||
        ['txt', 'md'].contains(extension)) {
      return LyricsReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    }
    if (materialTypeName.contains('pdf')) {
      return PdfReaderPage(
        materialId: material.id,
        materialPath: material.path,
        materialName: materialName,
      );
    }
    return LyricsReaderPage(
      materialId: material.id,
      materialPath: material.path,
      materialName: materialName,
    );
  }

  static String _getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }
}
