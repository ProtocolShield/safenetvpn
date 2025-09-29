import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:safenetvpn/ui/core/ui/auth/forgotpassword.dart';

class Auth extends StatelessWidget {
  const Auth({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<CipherGateModel>(CipherGateModel());
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(
          () => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: 40,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title & subtitle
                Column(
                  children: [
                    Text(
                      provider.modeShift.value ? "Sign Up" : "Login",
                      style: GoogleFonts.daysOne(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.modeShift.value
                          ? "Signup to your account to continue"
                          : "Login to your account to continue",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Toggle Buttons
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // Login Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => provider.pivotView(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: !provider.modeShift.value
                                  ? const LinearGradient(
                                      colors: [Colors.blue, Colors.purple],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Login",
                                style: TextStyle(
                                  color: !provider.modeShift.value
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Sign Up Button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => provider.pivotView(true),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: provider.modeShift.value
                                  ? const LinearGradient(
                                      colors: [Colors.blue, Colors.purple],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: provider.modeShift.value
                                      ? Colors.white
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Animated Switch between SignIn & SignUp
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: provider.modeShift.value
                          ? const Offset(1, 0) // slide from right
                          : const Offset(-1, 0), // slide from left
                      end: Offset.zero,
                    ).animate(animation);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: provider.modeShift.value
                      ? const SignUp(key: ValueKey("SignUp"))
                      : const SignIn(key: ValueKey("SignIn")),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUp extends StatelessWidget {
  const SignUp({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<CipherGateModel>(CipherGateModel());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Username",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GradientTextField(
            hintText: "Enter your username",
            controller: provider.idC,
          ),
          const SizedBox(height: 20),
          const Text(
            "Email",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GradientTextField(
            hintText: "Enter your email",
            controller: provider.idA,
          ),
          const SizedBox(height: 20),
          const Text(
            "Password",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GradientTextField(
            hintText: "Enter your password",
            controller: provider.idB,
            obscureText: true,
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onTap: () {
              provider.invokeBeta(context);
            },
            child: Container(
              height: 53,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [Colors.blue, Colors.purple],
                ),
              ),
              child: provider.flux.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 5,
                        ),
                      ),
                    )
                  : const Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class SignIn extends StatelessWidget {
  const SignIn({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<CipherGateModel>(CipherGateModel());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Email",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GradientTextField(
            hintText: "Enter your email",
            controller: provider.idA,
          ),
          const SizedBox(height: 20),
          const Text(
            "Password",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),
          GradientTextField(
            hintText: "Enter your password",
            controller: provider.idB,
            obscureText: true,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => ForgotPassword()));
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Colors.white, // masked by shader
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              provider.invokeAlpha(context);
            },
            child: Obx(
              () => Container(
                height: 53,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
                child: provider.flux.value
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 5,
                          ),
                        ),
                      )
                    : const Center(
                        child: Text(
                          "Log In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Gradient Border TextField
class GradientTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;

  const GradientTextField({
    super.key,
    required this.hintText,
    this.obscureText = false,
    this.controller,
  });

  @override
  State<GradientTextField> createState() => _GradientTextFieldState();
}

class _GradientTextFieldState extends State<GradientTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return _isFocused
            ? const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ).createShader(bounds)
            : LinearGradient(
                colors: [Colors.grey.shade700, Colors.grey.shade700],
              ).createShader(bounds);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 2, color: Colors.white),
        ),
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          obscureText: _obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
