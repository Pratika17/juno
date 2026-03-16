import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).errorMessage ??
                    'Login failed',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Stack(
        children: [
          // Top Decorative Circles
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFFC8BFF4), // Light Purple
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: 150,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.secondary, // Yellow
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        'Log In.',
                        style: AppTextStyles.heading1.copyWith(fontSize: 36),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'EMAIL',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          fillColor:
                              isDark ? AppColors.darkSurface : const Color(0xFFF4F4F9),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'PASSWORD',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          fillColor:
                              isDark ? AppColors.darkSurface : const Color(0xFFF4F4F9),
                        ),
                        obscureText: true,
                        validator: Validators.validatePassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to Forgot Password Screen (Optional)
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.bodyTextSecondary.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (authProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _submit,
                          child: Text(
                            'Log In',
                            style: AppTextStyles.bodyText.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Social Login placeholders (optional as per design)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.bodyTextSecondary,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text(
                              "Sign up",
                              style: AppTextStyles.bodyTextSecondary.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
