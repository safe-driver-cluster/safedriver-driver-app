import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'otp_screen.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Check if driver exists in 'drivers' collection
      final query = await FirebaseFirestore.instance
          .collection('drivers')
          .where('phoneNumber', isEqualTo: phone)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.driverNotFound)),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // If exists, proceed to OTP (In a real app, trigger Firebase Auth OTP here)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(phoneNumber: phone),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  hintText: l10n.enterPhoneNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(l10n.sendOtp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
