import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../theme/crm_colors.dart';
import '../theme/crm_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    // Placeholder for next step: API auth integration with CRM backend.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Mock Authentication Logic
    // In a real app, the API would return specific error codes for wrong email vs wrong password
    if (email != 'admin@company.com' || password != 'admin123') {
      _showErrorAlert(
        title: 'Authentication Failed',
        message: 'You have entered an incorrect email or password.\n\nPlease double-check your credentials. Make sure you are using your assigned CRM email and that CAPS lock is off.',
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login Successful! API integration is next.')),
    );
  }

  void _showErrorAlert({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktopWidth = size.width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/checkbackground.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.12),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.84),
                    Colors.white.withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktopWidth ? 940 : 460,
                  ),
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktopWidth ? 28 : 18,
                        vertical: isDesktopWidth ? 30 : 20,
                      ),
                      child: isDesktopWidth
                          ? Row(
                              children: [
                                Expanded(child: _InfoPanel(theme: theme)),
                                const SizedBox(width: 26),
                                Expanded(
                                  child: _buildForm(theme, compact: false),
                                ),
                              ],
                            )
                          : _buildForm(theme, compact: true),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme, {required bool compact}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            _MobileHeader(theme: theme),
            const SizedBox(height: 18),
          ] else ...[
            Text('Sign In', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Use your assigned CRM account to access your dashboard.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
          ],
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'name@company.com',
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onSignIn,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: SpinKitFoldingCube(
                        color: Colors.white,
                        size: 20.0,
                      ),
                    )
                  : const Text('Sign In'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Forgot password?'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(CrmTheme.radiusMd),
            border: Border.all(color: CrmColors.border),
          ),
          child: Image.asset('assets/ais-icon-dark.png'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AESTHETIC INTERIOR', style: theme.textTheme.labelSmall),
              const SizedBox(height: 2),
              Text('Sign In', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(CrmTheme.radiusMd),
                border: Border.all(color: CrmColors.border),
              ),
              child: Image.asset('assets/ais-icon-dark.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AESTHETIC INTERIOR', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Operations Management Software',
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'A focused workspace to manage leads, task assignments, follow-ups, and delivery flow.',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(CrmTheme.radiusLg),
            border: Border.all(color: CrmColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHAT THIS SYSTEM COVERS',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 10),
              Text(
                '• Lead intake and qualification workflow',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '• Team assignment by department',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '• Follow-up, visit, and progress tracking',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
