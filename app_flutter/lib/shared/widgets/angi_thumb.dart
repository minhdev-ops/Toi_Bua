import 'package:flutter/material.dart';

import '../../core/theme/angi_tokens.dart';

/// Ảnh quán/món. `image_url == null` (hoặc ảnh fail) ⇒ **tem hue của `type` + 2 ký tự đầu
/// tên món viết hoa**, không bao giờ placeholder xám (DESIGN.md §Iconography).
class AngiThumb extends StatelessWidget {
  const AngiThumb({
    required this.name,
    required this.hue,
    this.imageUrl,
    this.size = AngiScale.thumbFallback,
    super.key,
  });

  final String name;
  final Color hue;
  final String? imageUrl;
  final double size;

  static String initialsOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final letters = trimmed.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), ' ').split(' ').where((w) => w.isNotEmpty).toList();
    if (letters.isEmpty) return trimmed.characters.first.toUpperCase();
    if (letters.length == 1) return letters.first.characters.take(2).toString().toUpperCase();
    return (letters[0].characters.first + letters[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final roles = AngiRoles.of(context);
    final fallback = Container(
      width: size,
      height: size,
      color: hue,
      alignment: Alignment.center,
      child: Text(
        initialsOf(name),
        style: roles.title.copyWith(color: AngiTokens.of(context).onData, fontSize: size * 0.34),
      ),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return ClipRRect(borderRadius: BorderRadius.circular(AngiScale.radiusSm), child: fallback);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AngiScale.radiusSm),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (_, child, progress) => progress == null ? child : fallback,
      ),
    );
  }
}
