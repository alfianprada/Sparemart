import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  void showErrorPopup(String message) {
  if (!mounted) return;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Login Gagal"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


  Future<void> login() async {
  final email = emailCtrl.text.trim();
  final password = passCtrl.text.trim();

  // ✅ 1. VALIDASI EMAIL KOSONG
  if (email.isEmpty) {
    showErrorPopup("Email tidak boleh kosong");
    return;
  }

  // ✅ 2. VALIDASI PASSWORD KOSONG
  if (password.isEmpty) {
    showErrorPopup("Password tidak boleh kosong");
    return;
  }

  // ✅ 3. VALIDASI FORMAT EMAIL
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(email)) {
    showErrorPopup("Format email tidak valid");
    return;
  }

  setState(() => loading = true);

  try {
    final supabase = Supabase.instance.client;

    // ✅ 4. LOGIN AUTH (SUPABASE YANG MENENTUKAN SALAH ATAU BENAR)
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      showErrorPopup("Email atau password salah");
      setState(() => loading = false);
      return;
    }

    final uid = res.user!.id;

    // ✅ 5. AMBIL PROFIL USER
    final profile = await supabase
        .from('user_profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    final role = profile?['role'] ?? 'kasir';

    if (!mounted) return;

    // ✅ 6. PINDAH DASHBOARD
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DashboardPage()),
    );
  } on AuthException catch (e) {
    showErrorPopup("Email atau password salah");
  } catch (e) {
    showErrorPopup("Login error: $e");
  }

  setState(() => loading = false);
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF003366), // biru tua
              Color(0xFF000000), // hitam
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LOGO
              Image.asset(
                'images/sparemart_logo.png',
                height: 250,
              ),

              const SizedBox(height: 10),

              // CARD FORM
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // EMAIL FIELD
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email),
                        labelText: "E-mail",
                        border: UnderlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // PASSWORD FIELD
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        labelText: "Password",
                        border: UnderlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 35),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEB00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 3,
                        ),
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // SIGN IN TEXT
                    const Text(
                      "Sign in to continue",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
