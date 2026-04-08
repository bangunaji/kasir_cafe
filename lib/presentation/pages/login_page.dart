import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../../../core/theme/app_colors.dart';
import 'pos_page.dart';
import 'admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isKasirMode = true; // true = Kasir, false = Admin
  String pinInput = '';

  void _onPinKeyPress(String value) {
    if (pinInput.length < 6) {
      setState(() {
        pinInput += value;
      });
    }
  }

  void _onPinBackspace() {
    if (pinInput.isNotEmpty) {
      setState(() {
        pinInput = pinInput.substring(0, pinInput.length - 1);
      });
    }
  }

  void _submitPin() {
    if (pinInput.isNotEmpty) {
      context.read<AuthBloc>().add(SignInWithPinEvent(pinInput));
      setState(() {
        pinInput = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthenticatedAsOwner) {
            _showOwnerSelectionDialog(context);
          } else if (state is AuthenticatedAsKasir) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PosPage()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.cardLight,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront_rounded, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('Kasir Cafe', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 32),
                  
                  // Toggle Role
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isKasirMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isKasirMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('Kasir', style: TextStyle(color: isKasirMode ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isKasirMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isKasirMode ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text('Admin', style: TextStyle(color: !isKasirMode ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (isKasirMode) ...[
                    // PIN Mode
                    const Text('Masukkan PIN Kasir', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < pinInput.length ? AppColors.primary : Colors.grey.shade300,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    _buildNumpad(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: pinInput.isNotEmpty ? _submitPin : null,
                        child: const Text('MASUK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    // Admin Mode
                    const Text('Login sebagai Pemilik Toko', style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const CircularProgressIndicator();
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.read<AuthBloc>().add(SignInWithGoogleEvent());
                            },
                            icon: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                              width: 24,
                              height: 24,
                            ),
                            label: const Text('Login dengan Google', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numpadButton('1'), _numpadButton('2'), _numpadButton('3')]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numpadButton('4'), _numpadButton('5'), _numpadButton('6')]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_numpadButton('7'), _numpadButton('8'), _numpadButton('9')]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          const SizedBox(width: 64, height: 64),
          _numpadButton('0'),
          GestureDetector(
            onTap: _onPinBackspace,
            child: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: const Icon(Icons.backspace_outlined, color: Colors.grey),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _numpadButton(String value) {
    return GestureDetector(
      onTap: () => _onPinKeyPress(value),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showOwnerSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Selamat Datang Owner'),
        content: const Text('Ingin masuk ke mana?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PosPage()),
              );
            },
            child: const Text('Buka Kasir'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
              );
            },
            child: const Text('Buka Admin Dashboard'),
          ),
        ],
      ),
    );
  }
}
