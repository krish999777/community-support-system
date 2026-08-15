import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';

class SessionTimeoutListener extends StatefulWidget {
  final Widget child;

  const SessionTimeoutListener({super.key, required this.child});

  @override
  State<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      _timer = Timer(const Duration(seconds: 30), _onTimeout);
    }
  }

  void _onTimeout() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      authProvider.logout();
      if (mounted) {
        // Clear all navigation stack and push login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired due to 30 seconds of inactivity."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleInteraction() {
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // If not authenticated, do not listen
    if (!authProvider.isAuthenticated) {
      _timer?.cancel();
      return widget.child;
    }

    // Start timer if not running
    if (_timer == null || !_timer!.isActive) {
      _resetTimer();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleInteraction(),
      onPointerMove: (_) => _handleInteraction(),
      onPointerUp: (_) => _handleInteraction(),
      child: widget.child,
    );
  }
}
