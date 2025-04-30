import 'package:bookcase/screens/home_page.dart';
import 'package:bookcase/screens/login_register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _isSending = false;
  bool _isChecking = false;

  Future<void> _sendVerificationEmail() async {
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Doğrulama e-postası tekrar gönderildi.")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("E-posta gönderilemedi. Hata: $e")),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("E-posta henüz doğrulanmadı.")),
      );
    }
    setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("E-posta Doğrulama")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Lütfen e-posta adresinize gönderilen doğrulama bağlantısını kontrol edin.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("Doğrulamayı Kontrol Et"),
              onPressed: _isChecking ? null : _checkVerificationStatus,
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              icon: Icon(Icons.email),
              label: Text("Tekrar E-posta Gönder"),
              onPressed: _isSending ? null : _sendVerificationEmail,
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginRegisterPage()));
              },
              child: Text("Çıkış Yap"),
            )
          ],
        ),
      ),
    );
  }
}
