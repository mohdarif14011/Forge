import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnimatedBackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const AnimatedBackButton({super.key, this.onPressed});

  @override
  State<AnimatedBackButton> createState() => _AnimatedBackButtonState();
}

class _AnimatedBackButtonState extends State<AnimatedBackButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (_isTapped) return;
    _isTapped = true;
    
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        // Fallback for screens where canPop is false but we need to go to home
        context.go('/home');
      }
    }
    
    // Reset tap state after a short delay in case pop doesn't happen
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _isTapped = false;
      }
    });
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
          ),
          child: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface, size: 20),
        ),
      ),
    );
  }
}
