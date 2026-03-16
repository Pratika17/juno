import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../utils/constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await Provider.of<AuthProvider>(context, listen: false)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            department: _departmentController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      setState(() => _isLoading = false);

      if (success) {
        if (mounted) Navigator.of(context).pop(); // Go back to login
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).errorMessage ??
                    'Registration failed',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: Stack(
        children: [
          // Bottom Decorative Circles (instead of Top)
          Positioned(
            bottom: -150,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: Color(0xFFC8BFF4), // Light Purple
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Sign Up.',
                      style: AppTextStyles.heading1.copyWith(fontSize: 36),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'NAME',
                      isDark: isDark,
                      validator: (value) => Validators.validateRequired(value, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'EMAIL',
                      isDark: isDark,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      hint: 'PHONE',
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _departmentController,
                      hint: 'DEPARTMENT',
                      isDark: isDark,
                      validator: (value) => Validators.validateRequired(value, 'Department'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'PASSWORD',
                      isDark: isDark,
                      obscureText: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'CONFIRM PASSWORD',
                      isDark: isDark,
                      obscureText: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _submit,
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.bodyText.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: AppTextStyles.bodyTextSecondary,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Log in",
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black38,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        fillColor: isDark ? AppColors.darkSurface : const Color(0xFFF4F4F9),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
