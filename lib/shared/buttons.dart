import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:para_demo/provider/auth_provider.dart';

class SocialAuthButton extends StatelessWidget {
  final SocialProvider provider;
  final bool isLoading;
  final VoidCallback onPressed;

  const SocialAuthButton({
    super.key,
    required this.provider,
    required this.isLoading,
    required this.onPressed,
  });

  String get _iconAsset {
    return switch (provider) {
      SocialProvider.google => 'assets/google.svg',
      SocialProvider.apple => 'assets/apple.svg',
      SocialProvider.discord => 'assets/discord.png',
    };
  }

  String get _label {
    return switch (provider) {
      SocialProvider.google => 'Google',
      SocialProvider.apple => 'Apple',
      SocialProvider.discord => 'Discord',
    };
  }

  Color? get _iconColor {
    return switch (provider) {
      SocialProvider.discord => const Color(0xFF5865F2),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,

      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.1),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
        ),
        padding: EdgeInsets.zero,
      ),
      child: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  _iconAsset,
                  width: 24,
                  height: 24,
                  color: _iconColor,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.login,
                      size: 24,
                      color:
                          _iconColor ?? Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
    );
  }
}
