import 'package:bookcase/screens/email_verification_page.dart';
import 'package:bookcase/screens/home_page.dart';
import 'package:bookcase/screens/reset_password_page.dart';
import 'package:bookcase/services/auth_service.dart';
import 'package:bookcase/utils/get_error_messages.dart';
import 'package:bookcase/utils/password_suffix_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  String? errorMessage;
  bool _isPasswordVisible = false;
  bool _isRepeatPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
            child: Opacity(
          opacity: 0.1,
          child: Image.asset(
            'assets/pictures/splashscreen.png',
            fit: BoxFit.cover,
          ),
        )),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text("Hoşgeldiniz"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 35),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isLogin)
                      TextFormField(
                        controller: _userNameController,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            hintText: "Kullanıcı Adı",
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Kullanıcı adı gerekli";
                          }
                          return null;
                        },
                      ),
                    if (!_isLogin) const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email),
                          hintText:
                              _isLogin ? "E-posta / Kullanıcı Adı" : "E-posta",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "E-posta gerekli";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _passwordController,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                      autocorrect: false,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: "Şifre",
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        suffixIcon: PasswordSuffixIcon(
                          isPasswordVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Şifre gerekli";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    if (!_isLogin)
                      TextFormField(
                        controller: _confirmPasswordController,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        autocorrect: false,
                        obscureText: !_isRepeatPasswordVisible,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          hintText: "Şifre Tekrar",
                          hintStyle: TextStyle(color: Colors.grey.shade600),
                          suffixIcon: PasswordSuffixIcon(
                            isPasswordVisible: _isRepeatPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isRepeatPasswordVisible =
                                    !_isRepeatPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) => validatePasswordConfirmation(
                            value, _passwordController.text),
                      ),
                    SizedBox(height: 20),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: 30),
                    ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_isLogin) {
                              await signIn();
                            } else {
                              await createUser(
                                  email: _emailController.text,
                                  password: _passwordController.text,
                                  username: _userNameController.text);
                            }
                          }
                        },
                        child: _isLogin ? Text("Giriş Yap") : Text("Kayıt Ol")),
                    SizedBox(height: 15),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? "Henüz hesabın yok mu?  Kayıt Ol."
                              : "Zaten hesabın var mu?  Giriş Yap.",
                          style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontSize: 16),
                        )),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ResetPasswordPage()));
                      },
                      child: Text(
                        "Şifremi Unuttum",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      if (username.trim().isEmpty) {
        setState(() {
          errorMessage = 'Kullanıcı adı boş olamaz.';
        });
        return;
      }

      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        setState(() {
          errorMessage = 'Bu kullanıcı adı zaten alınmış.';
        });
        return;
      }

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = credential.user;
      if (user != null) {
        await user.sendEmailVerification();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({'email': email, 'username': username});

      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => EmailVerificationPage()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = getErrorMessage(e.code);
      });
    }
    _clearForm();
  }

  Future<void> signIn() async {
    try {
      String input = _emailController.text.trim();
      String password = _passwordController.text;
      String emailToUse = input;

      if (input.isEmpty || password.isEmpty) {
        setState(() {
          errorMessage = "Lütfen e-posta/kullanıcı adı ve şifre giriniz.";
        });
        return;
      }

      if (!input.contains('@')) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          emailToUse = query.docs.first['email'];
        } else {
          setState(() {
            errorMessage = "Kullanıcı adı bulunamadı.";
          });
          return;
        }
      }
      await Auth()
          .signIn(email: emailToUse, password: _passwordController.text);
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
      } else {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const EmailVerificationPage()));
      }
    } on FirebaseAuthException catch (e) {
      print('Hata kodu: ${e.code}');
      setState(() {
        errorMessage = getErrorMessage(e.code);
      });
    } catch (err) {
      print("Beklenmeyen hata: $err");
      setState(() {
        errorMessage = "Bir hata oluştu. Lütfen tekrar deneyiniz.";
      });
    }
    _clearForm();
  }

  Future<void> signOut() async {
    await Auth().signOut();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => LoginRegisterPage()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    }
  }

  String? validatePasswordConfirmation(
      String? confirmPassword, String password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return "Lütfen şifreyi tekrar giriniz.";
    } else if (confirmPassword != password) {
      return "Şifreler eşleşmiyor.";
    }
    return null;
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    if (!_isLogin) {
      _userNameController.clear();

      _confirmPasswordController.clear();
    }
  }
}
