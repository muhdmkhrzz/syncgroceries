import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'registerpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await authService.value.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
        child: Column(
          children: [
            const Text("🛒 GROCERIES", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            // The Hero Image Container from your screenshot
            Container(
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                image: const DecorationImage(
                  image: AssetImage('assets/grocery_hero.jpg'), // Ensure this exists or use a Placeholder
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Shop Together,", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text("Instantly.", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 20),
            const Text(
              "The shared list that works as fast as you shop. Collaborate in real-time.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(hintText: "Email", filled: true, fillColor: const Color(0xFF1A242E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(hintText: "Password", filled: true, fillColor: const Color(0xFF1A242E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Start Your List →", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
              child: const Text("Don't have an account? Register", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}