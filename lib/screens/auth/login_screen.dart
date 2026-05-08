import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  String _selectedCountryCode = '+94';
  String _selectedCountryName = 'Sri Lanka';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() => _isLoading = false);

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber:
                  '$_selectedCountryCode${_phoneController.text.trim()}',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2563EB), Color(0xFF1E40AF), Color(0xFF1E3A8A)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 25,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF2563EB),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to continue your safe journey',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              // Form
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Enter Your Phone Number',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered phone number to continue',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 28),
                      // Country Code Selector
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showCountryPicker(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  _getCountryFlag(_selectedCountryCode),
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCountryCode,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    Text(
                                      _selectedCountryName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Phone Field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter phone number',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Continue Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      // Terms
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            children: const [
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Country',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _buildCountryOption('🇱🇰', '+94', 'Sri Lanka'),
                    _buildCountryOption('🇺🇸', '+1', 'United States'),
                    _buildCountryOption('🇮🇳', '+91', 'India'),
                    _buildCountryOption('🇬🇧', '+44', 'United Kingdom'),
                    _buildCountryOption('🇦🇺', '+61', 'Australia'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountryOption(String flag, String code, String name) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCountryCode = code;
            _selectedCountryName = name;
          });
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    code,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCountryFlag(String code) {
    switch (code) {
      case '+94':
        return '🇱🇰';
      case '+1':
        return '🇺🇸';
      case '+91':
        return '🇮🇳';
      case '+44':
        return '🇬🇧';
      case '+61':
        return '🇦🇺';
      default:
        return '🌍';
    }
  }
}
