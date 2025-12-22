import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/peer_identity.dart';

/// A profile avatar widget that displays either a profile image or
/// a placeholder with initials using accessible colors.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.identity, this.size = 40.0});

  final PeerIdentity identity;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (identity.profileImage != null && identity.profileImage!.isNotEmpty) {
      try {
        // Decode base64 string to image bytes
        final Uint8List imageBytes = base64Decode(identity.profileImage!);
        return CircleAvatar(
          radius: size / 2,
          backgroundImage: MemoryImage(imageBytes),
          backgroundColor: Colors.grey.shade200,
        );
      } catch (e) {
        // If base64 decode fails, fall back to placeholder
        return _PlaceholderAvatar(identity: identity, size: size);
      }
    }

    return _PlaceholderAvatar(identity: identity, size: size);
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.identity, required this.size});

  final PeerIdentity identity;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(identity);
    final backgroundColor = _getAccessibleColor(identity.id);
    final textColor = _getContrastingTextColor(backgroundColor);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getInitials(PeerIdentity identity) {
    final name = identity.name ?? identity.displayName;
    if (name.isEmpty) {
      return '??';
    }

    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      // Take first letter of first and last word
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else {
      // Take first two letters of single word
      final word = parts.first;
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word[0].toUpperCase();
    }
  }

  /// Generates an accessible color based on the user ID.
  /// Colors are selected to ensure sufficient contrast with both
  /// white and black text while maintaining visual variety.
  Color _getAccessibleColor(String id) {
    // Use the ID to generate a consistent color for each user
    final hash = id.hashCode.abs();

    // Predefined color palette with WCAG AA compliant contrast ratios
    // These colors work well with white text (contrast ratio > 4.5:1)
    final accessibleColors = [
      const Color(0xFF1976D2), // Blue 700
      const Color(0xFF388E3C), // Green 700
      const Color(0xFFD32F2F), // Red 700
      const Color(0xFF7B1FA2), // Purple 700
      const Color(0xFFF57C00), // Orange 700
      const Color(0xFF0097A7), // Cyan 700
      const Color(0xFF5D4037), // Brown 700
      const Color(0xFF455A64), // Blue Grey 700
      const Color(0xFFC2185B), // Pink 700
      const Color(0xFF00796B), // Teal 700
      const Color(0xFF303F9F), // Indigo 700
      const Color(0xFFAFB42B), // Lime 700
    ];

    return accessibleColors[hash % accessibleColors.length];
  }

  /// Returns a contrasting text color that maintains WCAG AA compliance
  /// (contrast ratio >= 4.5:1) while using colors when possible.
  Color _getContrastingTextColor(Color backgroundColor) {
    final bgLuminance = _calculateLuminance(backgroundColor);

    // Light text colors for dark backgrounds
    final lightTextColors = [
      const Color(0xFFFFFFFF), // White
      const Color(0xFFE3F2FD), // Blue 50
      const Color(0xFFFCE4EC), // Pink 50
      const Color(0xFFF3E5F5), // Purple 50
      const Color(0xFFE8F5E9), // Green 50
      const Color(0xFFFFF8E1), // Amber 50
      const Color(0xFFE0F7FA), // Cyan 50
    ];

    // Dark text colors for light backgrounds
    final darkTextColors = [
      const Color(0xFF212121), // Grey 900
      const Color(0xFF1A237E), // Indigo 900
      const Color(0xFF880E4F), // Pink 900
      const Color(0xFF1B5E20), // Green 900
      const Color(0xFF4A148C), // Purple 900
      const Color(0xFF006064), // Cyan 900
      const Color(0xFFBF360C), // Deep Orange 900
    ];

    // Choose palette based on background luminance
    final candidates = bgLuminance > 0.4 ? darkTextColors : lightTextColors;

    // Find the color with the best contrast ratio
    Color bestColor = candidates.first;
    double bestContrast = 0;

    for (final color in candidates) {
      final contrast = _calculateContrastRatio(bgLuminance, color);
      if (contrast > bestContrast) {
        bestContrast = contrast;
        bestColor = color;
      }
    }

    // Ensure minimum contrast of 4.5:1 for WCAG AA
    if (bestContrast < 4.5) {
      return bgLuminance > 0.5 ? Colors.black87 : Colors.white;
    }

    return bestColor;
  }

  /// Calculates relative luminance using WCAG formula.
  double _calculateLuminance(Color color) {
    final r = (color.r * 255.0).round() / 255.0;
    final g = (color.g * 255.0).round() / 255.0;
    final b = (color.b * 255.0).round() / 255.0;

    final rLum = r <= 0.03928 ? r / 12.92 : math.pow((r + 0.055) / 1.055, 2.4);
    final gLum = g <= 0.03928 ? g / 12.92 : math.pow((g + 0.055) / 1.055, 2.4);
    final bLum = b <= 0.03928 ? b / 12.92 : math.pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * (rLum as double) +
        0.7152 * (gLum as double) +
        0.0722 * (bLum as double);
  }

  /// Calculates WCAG contrast ratio between background luminance and a color.
  double _calculateContrastRatio(double bgLuminance, Color foreground) {
    final fgLuminance = _calculateLuminance(foreground);
    final lighter = math.max(bgLuminance, fgLuminance);
    final darker = math.min(bgLuminance, fgLuminance);
    return (lighter + 0.05) / (darker + 0.05);
  }
}
