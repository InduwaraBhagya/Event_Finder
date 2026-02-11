import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isActive;
  final IconData? icon;
  final ButtonStyle? style;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isActive = true,
    this.icon,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon != null
          ? ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(label),
              onPressed: isActive && !isLoading ? onPressed : null,
              style: style,
            )
          : ElevatedButton(
              onPressed: isActive && !isLoading ? onPressed : null,
              style: style,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(label),
            ),
    );
  }
}
