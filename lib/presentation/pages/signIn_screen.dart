import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    home: SignInScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool isLoading = false;
  bool obscurePass = true;
  bool obscureConfirm = true;

  Future<void> _registerWithEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم التسجيل بنجاح")),
        );
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "حدث خطأ")),
        );
      }
      setState(() => isLoading = false);
    }
  }

  bool _googleSignInInitialized = false;

  Future<void> _initGoogleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      clientId: '<YOUR_WEB_CLIENT_ID_IF_NEEDED>',
    );
    _googleSignInInitialized = true;
  }

  Future<void> signInWithGoogle() async {
    try {
      if (!_googleSignInInitialized) {
        await _initGoogleSignIn();
      }

      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount? googleUser =
          await googleSignIn.authenticate(scopeHint: ['email']);

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      final String? accessToken =
          (await googleUser.authorizationClient?.authorizationForScopes(['email']))
              as String?;

      if (idToken == null) {
        throw Exception('لا يوجد idToken');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      print("✅ تم تسجيل الدخول بجوجل بنجاح");
    } catch (e) {
      print("❌ خطأ في تسجيل الدخول بجوجل: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1,
                      size: 80, color: Colors.white),
                  const SizedBox(height: 15),
                  const Text(
                    "انضم إلينا",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "أنشئ حسابك واستمتع بمشاركة الوجبات",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // الصندوق الأبيض
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // الاسم الكامل
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'الاسم الكامل',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'أدخل اسمك الكامل' : null,
                        ),
                        const SizedBox(height: 16),

                        // البريد الإلكتروني
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) =>
                              value!.contains('@') ? null : 'أدخل بريدًا صحيحًا',
                        ),
                        const SizedBox(height: 16),

                        // كلمة المرور
                        TextFormField(
                          controller: passController,
                          obscureText: obscurePass,
                          decoration: InputDecoration(
                            labelText: 'كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  obscurePass = !obscurePass;
                                });
                              },
                            ),
                          ),
                          validator: (value) => value!.length < 6
                              ? 'كلمة المرور قصيرة جدًا'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // تأكيد كلمة المرور
                        TextFormField(
                          controller: confirmPassController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  obscureConfirm = !obscureConfirm;
                                });
                              },
                            ),
                          ),
                          validator: (value) =>
                              value != passController.text
                                  ? 'كلمتا المرور غير متطابقتين'
                                  : null,
                        ),
                        const SizedBox(height: 20),

                        // زر التسجيل بالبريد
                        isLoading
                            ? const CircularProgressIndicator()
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7F00FF),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _registerWithEmail,
                                  child: const Text(
                                    "إنشاء حساب بالبريد الإلكتروني",
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                        const SizedBox(height: 16),

                        // زر جوجل
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.mail_outline),
                            label: const Text("التسجيل باستخدام جوجل"),
                            onPressed: signInWithGoogle,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // زر الهاتف (واجهة فقط)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.phone),
                            label: const Text("التسجيل باستخدام رقم الهاتف"),
                            onPressed: () {
                              // انتقل لواجهة الهاتف
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // تسجيل الدخول
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("لديك حساب بالفعل؟",
                          style: TextStyle(color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "تسجيل الدخول",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
