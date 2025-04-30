import 'package:bookcase/screens/home_page.dart';
import 'package:bookcase/utils/password_suffix_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _currentUsernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newUsernameController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  String? _errorMessage;

  Future<bool> _reauthenticate(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user != null && email != null) {
      final cred =
          EmailAuthProvider.credential(email: email, password: password);
      try {
        await user.reauthenticateWithCredential(cred);
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<bool> _checkCurrentUsername(String enteredUsername) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final currentUsername = userDoc.data()?['username'];
      return currentUsername == enteredUsername;
    }
    return false;
  }

  Future<void> _updateUsername(String newUsername) async {
    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: newUsername)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      setState(() {
        _errorMessage = "Bu kullanıcı adı zaten alınmış.";
      });
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'username': newUsername});
      setState(() {
        _errorMessage = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kullanıcı adı güncellendi.")));
    }
  }

  Future<void> _updatePassword(String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Şifre güncellendi.")));
    }
  }

  void _onSubmit() async {
    final currentUsername = _currentUsernameController.text.trim();
    final currentPassword = _currentPasswordController.text.trim();
    final newUsername = _newUsernameController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final correctUsername = await _checkCurrentUsername(currentUsername);
    final authenticated = await _reauthenticate(currentPassword);

    if (!correctUsername || !authenticated) {
      setState(() {
        _errorMessage = "Mevcut kullanıcı adı veya şifre yanlış.";
      });
      return;
    }
    if (newUsername.isNotEmpty) {
      await _updateUsername(newUsername);
    }
    if (newPassword.isNotEmpty) {
      await _updatePassword(newPassword);
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Ayarlar"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (context) => HomePage()));
                  },
                  child: Text(
                    "Anasayfa",
                    style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 18,
                        decoration: TextDecoration.underline),
                  )),
            ),
            SizedBox(height: 20),
            Text("Güvenlik için mevcut bilgileriniz:",
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            TextField(
              controller: _currentUsernameController,
              decoration: InputDecoration(
                  labelText: "Mevcut kullanıcı adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _currentPasswordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.password),
                labelText: "Mevcut Şifre",
                border: OutlineInputBorder(),
                suffixIcon: PasswordSuffixIcon(
                  isPasswordVisible: _isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            Divider(height: 42),
            Text("Yeni bilgileriniz:", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            TextField(
              controller: _newUsernameController,
              decoration: InputDecoration(
                  labelText: "Yeni kullanıcı adı",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person)),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.password),
                labelText: "Yeni Şifre",
                border: OutlineInputBorder(),
                suffixIcon: PasswordSuffixIcon(
                  isPasswordVisible: _isNewPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.redAccent),
              ),
              SizedBox(height: 10),
            ],
            ElevatedButton(onPressed: _onSubmit, child: Text("Güncelle")),
          ],
        ),
      ),
    );
  }
}
