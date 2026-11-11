

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'admin_dashboard.dart';

import 'forgot_password_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nhmp_dashboard.dart';

import 'signup_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'user_dashboard.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override

  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  // ============================================================

  // THEME

  // ============================================================

  static const Color dark = Color(0xff071525);

  static const Color card = Color(0xff0D2035);

  static const Color blue = Color(0xff1687E8);

  static const Color cyan = Color(0xff20C4E8);

  static const Color errorRed = Color(0xffE5485D);

  // ============================================================

  // CONTROLLERS

  // ============================================================

  final TextEditingController emailController =

      TextEditingController();

  final TextEditingController passwordController =

      TextEditingController();

  // ============================================================

  // FOCUS NODES

  // ============================================================

  final FocusNode emailFocusNode = FocusNode();

  final FocusNode passwordFocusNode = FocusNode();

  // ============================================================

  // STATE

  // ============================================================

  bool isPasswordVisible = false;

  bool rememberMe = false;

  bool isLoading = false;

  String selectedRole = 'User Login';

  String? activeError;

  String? errorField;

  // ============================================================

  // INIT

  // ============================================================

  @override

  @override
void initState() {
  super.initState();
  emailFocusNode.requestFocus();
  _loadRememberedEmail();
}

Future<void> _loadRememberedEmail() async {
  final prefs = await SharedPreferences.getInstance();

  final savedEmail = prefs.getString('remembered_email');
  final shouldRemember = prefs.getBool('remember_me') ?? false;

  if (!mounted) return;

  if (shouldRemember && savedEmail != null) {
    setState(() {
      emailController.text = savedEmail;
      rememberMe = true;
    });
  }
}

  // ============================================================

  // DISPOSE

  // ============================================================

  @override

  void dispose() {

    emailController.dispose();

    passwordController.dispose();

    emailFocusNode.dispose();

    passwordFocusNode.dispose();

    super.dispose();

  }

  // ============================================================

  // SHOW MESSAGE

  // ============================================================

  void showMessage(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

      ),

    );

  }

  // ============================================================

  // CLEAR ERROR

  // ============================================================

  void clearError() {

    if (activeError != null || errorField != null) {

      setState(() {

        activeError = null;

        errorField = null;

      });

    }

  }

  // ============================================================

  // VALIDATION ERROR

  // ============================================================

  void showValidationError(

    String field,

    String message,

    FocusNode focusNode,

  ) {

    setState(() {

      errorField = field;

      activeError = message;

    });

    FocusScope.of(context).requestFocus(focusNode);

  }

  // ============================================================

  // EMAIL VALIDATION

  // ============================================================

  bool isValidEmail(String email) {

    final emailRegex = RegExp(

      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',

    );

    return emailRegex.hasMatch(email);

  }

  // ============================================================

  // LOGIN

  // ============================================================

Future<void> handleSetPassword() async {

  if (isLoading) return;

  final email = emailController.text.trim().toLowerCase();

  if (email.isEmpty) {

    showMessage('Please enter your Gmail first.');

    return;

  }

  setState(() {

    isLoading = true;

    activeError = null;

    errorField = null;

  });

  try {

    final googleProvider = GoogleAuthProvider();

    final result =

        await FirebaseAuth.instance.signInWithPopup(googleProvider);

    final user = result.user;

    if (user == null ||

        user.email?.toLowerCase() != email) {

      await FirebaseAuth.instance.signOut();

      if (mounted) {

        showMessage('Please select the same Gmail address.');

      }

      return;

    }

    final passwordController = TextEditingController();

    final confirmController = TextEditingController();

    final passwords = await showDialog<List<String>>(

      context: context,

      builder: (dialogContext) {

        return AlertDialog(

          title: const Text('Set Your Login Password'),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              TextField(

                controller: passwordController,

                obscureText: true,

                decoration: const InputDecoration(

                  labelText: 'New Password',

                ),

              ),

              TextField(

                controller: confirmController,

                obscureText: true,

                decoration: const InputDecoration(

                  labelText: 'Confirm Password',

                ),

              ),

            ],

          ),

          actions: [

            TextButton(

              onPressed: () =>

                  Navigator.pop(dialogContext),

              child: const Text('Cancel'),

            ),

            ElevatedButton(

              onPressed: () {

                if (passwordController.text.length < 6) {

                  showMessage(

                    'Password must be at least 6 characters.',

                  );

                  return;

                }

                if (passwordController.text !=

                    confirmController.text) {

                  showMessage('Passwords do not match.');

                  return;

                }

                Navigator.pop(dialogContext, [

                  passwordController.text,

                  confirmController.text,

                ]);

              },

              child: const Text('Set Password'),

            ),

          ],

        );

      },

    );

    passwordController.dispose();

    confirmController.dispose();

    if (passwords == null) {

      await FirebaseAuth.instance.signOut();

      return;

    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.email == null) {

      throw Exception('Google sign-in session was lost.');

    }

    final emailCredential = EmailAuthProvider.credential(

      email: currentUser.email!,

      password: passwords[0],

    );

    await currentUser.linkWithCredential(emailCredential);

    await FirebaseAuth.instance.signOut();

    if (mounted) {

      showMessage(

        'Password set successfully! Now use normal LOGIN.',

      );

    }


    } on FirebaseAuthException catch (e) {
      debugPrint('GOOGLE FIREBASE ERROR CODE: ${e.code}');
      debugPrint('GOOGLE FIREBASE ERROR MESSAGE: ${e.message}');

      if (mounted) {
        showMessage(
          'Google login failed: ${e.code}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('GOOGLE SIGN-IN ERROR: $e');
      debugPrint('GOOGLE ERROR DETAILS: $stackTrace');

      if (mounted) {
        showMessage('Google login failed. Check Terminal.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }


}

  Future<void> handleLogin() async {

    if (isLoading) return;

    FocusScope.of(context).unfocus();

    final email = emailController.text.trim().toLowerCase();

    final password = passwordController.text;

    // EMPTY EMAIL

    if (email.isEmpty) {

      showValidationError(

        'email',

        'Please enter your email address',

        emailFocusNode,

      );

      return;

    }

    // EMAIL SPACE

    if (email.contains(' ')) {

      showValidationError(

        'email',

        'Email address cannot contain spaces',

        emailFocusNode,

      );

      return;

    }

    // INVALID EMAIL

    if (!isValidEmail(email)) {

      showValidationError(

        'email',

        'Please enter a valid email address',

        emailFocusNode,

      );

      return;

    }

    // EMPTY PASSWORD

    if (password.isEmpty) {

      showValidationError(

        'password',

        'Please enter your password',

        passwordFocusNode,

      );

      return;

    }

    setState(() {

      isLoading = true;

      activeError = null;

      errorField = null;

    });

    try {

      // ========================================================

      // FIREBASE AUTH

      // ========================================================

      final credential =

          await FirebaseAuth.instance.signInWithEmailAndPassword(

        email: email,

        password: password,

      );

      final user = credential.user;

      if (user == null) {

        if (!mounted) return;

        showMessage(

          'Unable to sign in. Please try again.',

        );

        return;

      }

      // ========================================================

      // GET USER ROLE

      // ========================================================

      final userDoc = await FirebaseFirestore.instance

          .collection('users')

          .doc(user.uid)

          .get();

      String role = 'user';

      if (userDoc.exists) {

        final data = userDoc.data();

        final storedRole = data?['role'];

        if (storedRole is String &&

            storedRole.trim().isNotEmpty) {

          role = storedRole.trim().toLowerCase();

        }

      }

      // ========================================================

      // ADMIN LOGIN

      // ========================================================

      if (selectedRole == 'Admin Login') {

        if (role != 'admin') {

          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          showMessage(

            'This account is not registered as Admin.',

          );

          return;

        }

        if (!mounted) return;

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) => const AdminDashboard(),

          ),

        );

        return;

      }

      // ========================================================

      // NHMP LOGIN

      // ========================================================

      if (selectedRole == 'NHMP Login') {

        if (role != 'nhmp' && role != 'admin') {

          await FirebaseAuth.instance.signOut();

          if (!mounted) return;

          showMessage(

            'This account is not registered as NHMP.',

          );

          return;

        }

        if (!mounted) return;

        Navigator.pushReplacement(

          context,

          MaterialPageRoute(

            builder: (_) => const NHMPDashboard(),

          ),

        );

        return;

      }

      // ========================================================

      // USER LOGIN

      // ========================================================


      // ========================================================
      // USER LOGIN
      // ========================================================

      if (role != 'user') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        showMessage(
          'This account is not registered as a User.',
        );

        return;
      }

    final prefs = await SharedPreferences.getInstance();

if (rememberMe) {
  await prefs.setString('remembered_email', email);
  await prefs.setBool('remember_me', true);
} else {
  await prefs.remove('remembered_email');
  await prefs.setBool('remember_me', false);
}

if (!mounted) return;

Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const UserDashboard(),
  ),
);

    }


    // ============================================================

    // FIREBASE AUTH ERROR

    // ============================================================

    on FirebaseAuthException catch (e) {

      if (!mounted) return;

      if (e.code == 'user-not-found') {

        showValidationError(

          'email',

          'No account found with this email.',

          emailFocusNode,

        );

      } else if (e.code == 'wrong-password') {

        showValidationError(

          'password',

          'Incorrect password.',

          passwordFocusNode,

        );

      } else if (e.code == 'invalid-credential') {

        showValidationError(

          'email',

          'Email or password is incorrect.',

          emailFocusNode,

        );

      } else if (e.code == 'invalid-email') {

        showValidationError(

          'email',

          'Please enter a valid email address.',

          emailFocusNode,

        );

      } else if (e.code == 'too-many-requests') {

        showMessage(

          'Too many attempts. Please try again later.',

        );

      } else if (e.code == 'user-disabled') {

        showMessage(

          'This account has been disabled.',

        );

      } else {

        showMessage(

          'Login failed. Please try again.',

        );

      }

    }

    // ============================================================

    // FIRESTORE ERROR

    // ============================================================

    on FirebaseException catch (e) {

      if (!mounted) return;

      if (e.code == 'permission-denied') {

        showMessage(

          'Firestore permission denied. Please check Firestore Rules.',

        );

      } else {

        showMessage(

          'Database error. Please try again.',

        );

      }

    }

    // ============================================================

    // OTHER ERROR

    // ============================================================

    catch (e) {

      if (!mounted) return;

      showMessage(

        'Something went wrong. Please try again.',

      );

    }

    // ============================================================

    // STOP LOADING

    // ============================================================

    finally {

      if (mounted) {

        setState(() {

          isLoading = false;

        });

      }

    }

  }

  // GOOGLE SIGN-IN FOR CHROME


Future<void> handleGoogleSignIn() async {
  if (isLoading) return;

  if (selectedRole != 'User Login') {
    showMessage('Google Sign-In is available for User Login only.');
    return;
  }

  setState(() {
    isLoading = true;
    activeError = null;
    errorField = null;
  });

  try {
    UserCredential credential;

    if (kIsWeb) {
      // Chrome / Web Google login
      final GoogleAuthProvider provider = GoogleAuthProvider();

      credential = await FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      // Android mobile Google login

await GoogleSignIn.instance.initialize(
  serverClientId:
      '715302354613-f39j4mk1fhesem8gqei8cqtevk39o6g6.apps.googleusercontent.com',
);


      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final OAuthCredential googleCredential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      credential = await FirebaseAuth.instance.signInWithCredential(
        googleCredential,
      );
    }

    final User? user = credential.user;

    if (user == null) {
      if (mounted) {
        showMessage('Google login failed. Please try again.');
      }
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String role = 'user';

    if (userDoc.exists) {
      final data = userDoc.data();
      final storedRole = data?['role'];

      if (storedRole is String && storedRole.trim().isNotEmpty) {
        role = storedRole.trim().toLowerCase();
      }
    }

    if (!mounted) return;

    if (role != 'user') {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        showMessage(
          'Google Sign-In is available for User accounts only.',
        );
      }
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const UserDashboard(),
      ),
    );
  } on FirebaseAuthException catch (e) {
    debugPrint('GOOGLE FIREBASE ERROR: ${e.code} - ${e.message}');

    if (mounted) {
      showMessage('Google login failed: ${e.code}');
    }
  } catch (e, stackTrace) {
    debugPrint('GOOGLE SIGN-IN ERROR: $e');
    debugPrint('GOOGLE ERROR DETAILS: $stackTrace');

    if (mounted) {
      showMessage('Google login failed. Check VS Code Terminal.');
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  // ============================================================

  // ROLE BUTTON

  // ============================================================

  Widget roleButton({

    required String title,

    required IconData icon,

  }) {

    final bool isSelected = selectedRole == title;

    return Expanded(

      child: GestureDetector(

        onTap: isLoading

            ? null

            : () {

                setState(() {

                  selectedRole = title;

                  activeError = null;

                  errorField = null;

                });

                // IMPORTANT:

                // Role select karte hi cursor Email field par.

                WidgetsBinding.instance.addPostFrameCallback((_) {

                  if (mounted) {

                    FocusScope.of(context).requestFocus(

                      emailFocusNode,

                    );

                  }

                });

              },

        child: AnimatedContainer(

          duration: const Duration(milliseconds: 220),

          margin: const EdgeInsets.symmetric(

            horizontal: 4,

          ),

          padding: const EdgeInsets.symmetric(

            vertical: 10,

            horizontal: 3,

          ),

          decoration: BoxDecoration(

            color: isSelected

                ? cyan

                : Colors.white.withAlpha(10),

            borderRadius: BorderRadius.circular(12),

            border: Border.all(

              color: isSelected

                  ? cyan

                  : Colors.white.withAlpha(25),

            ),

          ),

          child: Column(

            children: [

              Icon(

                icon,

                size: 21,

                color: isSelected

                    ? Colors.white

                    : Colors.white70,

              ),

              const SizedBox(height: 5),

              Text(

                title,

                textAlign: TextAlign.center,

                style: TextStyle(

                  color: isSelected

                      ? Colors.white

                      : Colors.white70,

                  fontSize: 10.5,

                  fontWeight: FontWeight.w600,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  // ============================================================

  // INPUT FIELD

  // ============================================================

  Widget inputField({

    required TextEditingController controller,

    required FocusNode focusNode,

    required String hint,

    required IconData icon,

    required String fieldName,

    TextInputType? keyboardType,

    TextInputAction? textInputAction,

    VoidCallback? onEditingComplete,

    bool obscureText = false,

    Widget? suffixIcon,

  }) {

    final bool hasError = errorField == fieldName;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        TextField(

          controller: controller,

          focusNode: focusNode,

          keyboardType: keyboardType,

          textInputAction: textInputAction,

          obscureText: obscureText,

          onEditingComplete: onEditingComplete,

          autocorrect: false,

          enableSuggestions: false,

          style: const TextStyle(

            color: dark,

            fontSize: 13,

            fontWeight: FontWeight.w500,

          ),

          cursorColor: blue,

          onChanged: (_) {

            if (hasError) {

              clearError();

            }

          },

          decoration: InputDecoration(

            hintText: hint,

            hintStyle: const TextStyle(

              color: Color(0xff7A8794),

              fontSize: 13,

            ),

            prefixIcon: Icon(

              icon,

              color: const Color(0xff526170),

              size: 20,

            ),

            suffixIcon: suffixIcon,

            filled: true,

            fillColor: Colors.white,

            contentPadding: const EdgeInsets.symmetric(

              horizontal: 16,

              vertical: 16,

            ),

            enabledBorder: OutlineInputBorder(

              borderRadius: BorderRadius.circular(13),

              borderSide: BorderSide(

                color: hasError

                    ? errorRed

                    : const Color(0xffD7E0E8),

                width: hasError ? 1.5 : 1,

              ),

            ),

            focusedBorder: OutlineInputBorder(

              borderRadius: BorderRadius.circular(13),

              borderSide: BorderSide(

                color: hasError ? errorRed : blue,

                width: 1.8,

              ),

            ),

            border: OutlineInputBorder(

              borderRadius: BorderRadius.circular(13),

            ),

          ),

        ),

        if (hasError && activeError != null) ...[

          const SizedBox(height: 5),

          Padding(

            padding: const EdgeInsets.only(left: 4),

            child: Text(

              activeError!,

              style: const TextStyle(

                color: errorRed,

                fontSize: 11.5,

                fontWeight: FontWeight.w500,

              ),

            ),

          ),

        ],

      ],

    );

  }

  // ============================================================

  // LOGIN CARD

  // ============================================================

  Widget buildLoginCard(double screenWidth) {


final double cardWidth =
    screenWidth < 520 ? screenWidth - 40 : 470;

final double cardPadding =
    screenWidth < 500 ? 20 : 32;


    return Container(

      width: cardWidth,

      margin: const EdgeInsets.symmetric(

        horizontal: 20,

      ),

      padding: EdgeInsets.all(cardPadding),

      decoration: BoxDecoration(

        color: card.withAlpha(248),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(

          color: Colors.white.withAlpha(25),

        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withAlpha(120),

            blurRadius: 35,

            offset: const Offset(0, 15),

          ),

        ],

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          // ======================================================

          // SMOG CLOUD ICON

          // ======================================================

          const Icon(

            Icons.cloud_queue_rounded,

            color: cyan,

            size: 43,

          ),

          const SizedBox(height: 8),

          // ======================================================

          // SMOG RISK TITLE

          // ======================================================

          const Text(

            'SMOG RISK',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.white,

              fontSize: 25,

              fontWeight: FontWeight.w900,

              letterSpacing: 3,

            ),

          ),

          const SizedBox(height: 2),

          const Text(

            'PREDICTION SYSTEM',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: cyan,

              fontSize: 13,

              fontWeight: FontWeight.w700,

              letterSpacing: 2,

            ),

          ),

          const SizedBox(height: 15),

          Divider(

            color: Colors.white.withAlpha(25),

            height: 1,

          ),

          const SizedBox(height: 18),

          // ======================================================

          // WELCOME

          // ======================================================

          const Text(

            'Welcome Back',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.white,

              fontSize: 27,

              fontWeight: FontWeight.w800,

            ),

          ),

          const SizedBox(height: 6),

          const Text(

            'Sign in to continue to the Smog Risk Prediction System',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.white70,

              fontSize: 12.5,

              height: 1.4,

            ),

          ),

          const SizedBox(height: 25),

          // ======================================================

          // LOGIN AS

          // ======================================================

          const Text(

            'Login As',

            style: TextStyle(

              color: Colors.white,

              fontSize: 13,

              fontWeight: FontWeight.w600,

            ),

          ),

          const SizedBox(height: 8),

          Row(

            children: [

              roleButton(

                title: 'User Login',

                icon: Icons.person_outline,

              ),

              roleButton(

                title: 'NHMP Login',

                icon: Icons.local_police_outlined,

              ),

              roleButton(

                title: 'Admin Login',

                icon: Icons.admin_panel_settings_outlined,

              ),

            ],

          ),

          const SizedBox(height: 20),

          // ======================================================

          // EMAIL

          // ======================================================

          const Text(

            'Email Address',

            style: TextStyle(

              color: Colors.white,

              fontSize: 13,

              fontWeight: FontWeight.w600,

            ),

          ),

          const SizedBox(height: 8),

          inputField(

            controller: emailController,

            focusNode: emailFocusNode,

            hint: 'Enter your email',

            icon: Icons.email_outlined,

            fieldName: 'email',

            keyboardType: TextInputType.emailAddress,

            textInputAction: TextInputAction.next,

            onEditingComplete: () {

              FocusScope.of(context).requestFocus(

                passwordFocusNode,

              );

            },

          ),

          const SizedBox(height: 18),

          // ======================================================

          // PASSWORD

          // ======================================================

          const Text(

            'Password',

            style: TextStyle(

              color: Colors.white,

              fontSize: 13,

              fontWeight: FontWeight.w600,

            ),

          ),

          const SizedBox(height: 8),

          inputField(

            controller: passwordController,

            focusNode: passwordFocusNode,

            hint: 'Enter your password',

            icon: Icons.lock_outline,

            fieldName: 'password',

            textInputAction: TextInputAction.done,

            obscureText: !isPasswordVisible,

            onEditingComplete: handleLogin,

            suffixIcon: IconButton(

              tooltip: isPasswordVisible

                  ? 'Hide password'

                  : 'Show password',

              onPressed: () {

                setState(() {

                  isPasswordVisible =

                      !isPasswordVisible;

                });

              },

              icon: Icon(

                isPasswordVisible

                    ? Icons.visibility_outlined

                    : Icons.visibility_off_outlined,

                color: const Color(0xff526170),

                size: 20,

              ),

            ),

          ),

          const SizedBox(height: 9),

          // ======================================================

          // REMEMBER ME + FORGOT PASSWORD

          // ======================================================

          Row(

            children: [

              SizedBox(

                width: 24,

                height: 24,

                child: Checkbox(

                  value: rememberMe,

                  onChanged: isLoading

                      ? null

                      : (value) {

                          setState(() {

                            rememberMe =

                                value ?? false;

                          });

                        },

                  activeColor: blue,

                  checkColor: Colors.white,

                  side: BorderSide(

                    color: Colors.white.withAlpha(100),

                  ),

                ),

              ),

              const SizedBox(width: 5),

              const Text(

                'Remember me',

                style: TextStyle(

                  color: Colors.white70,

                  fontSize: 12,

                ),

              ),

              const Spacer(),

              TextButton(

                onPressed: isLoading

                    ? null

                    : () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>

                                const ForgotPasswordPage(),

                          ),

                        );

                      },

                child: const Text(

                  'Forgot Password?',

                  style: TextStyle(

                    color: cyan,

                    fontSize: 12,

                    fontWeight: FontWeight.w600,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 8),

          // ======================================================

          // LOGIN BUTTON

          // ======================================================

          SizedBox(

            height: 52,

            child: ElevatedButton(

              onPressed: isLoading

                  ? null

                  : handleLogin,

              style: ElevatedButton.styleFrom(

                backgroundColor: blue,

                disabledBackgroundColor:

                    blue.withAlpha(100),

                elevation: 0,

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(13),

                ),

              ),

              child: isLoading

                  ? const SizedBox(

                      height: 22,

                      width: 22,

                      child: CircularProgressIndicator(

                        strokeWidth: 2.5,

                        color: Colors.white,

                      ),

                    )

                  : const Text(

                      'LOGIN',

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 15,

                        fontWeight: FontWeight.bold,

                        letterSpacing: 1,

                      ),

                    ),

            ),

          ),

          if (selectedRole == 'User Login') ...[
          const SizedBox(height: 20),

TextButton(

  onPressed: isLoading ? null : handleSetPassword,

  child: const Text('Set Password'),

),

          // GOOGLE SIGN-IN BUTTON

          const SizedBox(height: 16),

          Row(

            children: [

              Expanded(

                child: Divider(

                  color: Colors.white.withAlpha(45),

                ),

              ),

              const Padding(

                padding: EdgeInsets.symmetric(horizontal: 12),

                child: Text(

                  'OR',

                  style: TextStyle(

                    color: Colors.white70,

                    fontSize: 11,

                  ),

                ),

              ),

              Expanded(

                child: Divider(

                  color: Colors.white.withAlpha(45),

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),

          SizedBox(

            height: 50,

            width: double.infinity,

            child: OutlinedButton.icon(

              onPressed: isLoading ? null : handleGoogleSignIn,

              icon: const Icon(

                Icons.g_mobiledata_rounded,

                size: 30,

                color: Colors.white,

              ),

              label: const Text(

                'Continue with Google',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 13,

                  fontWeight: FontWeight.w600,

                ),

              ),

              style: OutlinedButton.styleFrom(

                side: BorderSide(

                  color: Colors.white.withAlpha(70),

                ),

                shape: RoundedRectangleBorder(

                  borderRadius: BorderRadius.circular(13),

                ),

              ),

            ),

          ),

          ],

          // ======================================================

          // CREATE ACCOUNT

          // ======================================================

          Row(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Text(

                "Don't have an account? ",

                style: TextStyle(

                  color: Colors.white70,

                  fontSize: 12.5,

                ),

              ),

              GestureDetector(

                onTap: isLoading

                    ? null

                    : () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(

                            builder: (_) =>

                                const SignupPage(),

                          ),

                        );

                      },

                child: const Text(

                  'Create Account',

                  style: TextStyle(

                    color: cyan,

                    fontSize: 12.5,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 20),

          // ======================================================

          // ORIGINAL FIREBASE FOOTER

          // ======================================================

          Center(

            child: Text(

              'Secure authentication powered by Firebase',

              style: TextStyle(

                color: Colors.white.withAlpha(76),

                fontSize: 10,

              ),

            ),

          ),

        ],

      ),

    );

  }

  // ============================================================

  // BUILD

  // ============================================================

  @override

  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(

      backgroundColor: dark,

      body: Stack(

        children: [

          // ======================================================

          // SAME BACKGROUND IMAGE AS SIGNUP PAGE

          // ======================================================

          Positioned.fill(

            child: Image.asset(

              'assets/images/cover-image-7.jpg',

              fit: BoxFit.cover,

            ),

          ),

          // ======================================================

          // DARK OVERLAY

          // ======================================================

          Positioned.fill(

            child: Container(

              color: dark.withAlpha(180),

            ),

          ),

          // ======================================================

          // CENTER LOGIN CARD

          // ======================================================

          SafeArea(

            child: Center(

              child: SingleChildScrollView(

                padding: const EdgeInsets.symmetric(

                  horizontal: 20,

                  vertical: 25,

                ),

                child: buildLoginCard(size.width),

              ),

            ),

          ),

        ],

      ),

    );

  }

}
