import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await authService.value.createAccount(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          username: _usernameController.text.trim(),
        );

        await authService.value.updateUsername(
          username: _usernameController.text.trim(),
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.green.shade100;
    final textColor = Colors.black;
    final buttonColor = const Color.fromARGB(255, 229, 229, 229);
    final buttonTextColor = Colors.black;
    final inputColor = Colors.white;
    final appBarColor = const Color.fromARGB(111, 33, 64, 101).withOpacity(0.85);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/icon.png', height: 150, width: 150),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome! Start Writing Your Journey',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create Your Diary Sync Account',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 350,
                            child: TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
                                fillColor: inputColor,
                                filled: true,
                              ),
                              style: TextStyle(color: textColor),
                              validator: (value) => value == null || value.isEmpty ? 'Enter username' : null,
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: 350,
                            child: TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
                                fillColor: inputColor,
                                filled: true,
                              ),
                              style: TextStyle(color: textColor),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Enter email';
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: 350,
                            child: TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
                                fillColor: inputColor,
                                filled: true,
                              ),
                              style: TextStyle(color: textColor),
                              validator: (value) => value == null || value.isEmpty ? 'Enter password' : null,
                            ),
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: 300,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                backgroundColor: buttonColor,
                                foregroundColor: buttonTextColor,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Register', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}