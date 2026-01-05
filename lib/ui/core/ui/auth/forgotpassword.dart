import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:safenetvpn/view_model/cipherGateModel.dart';
import 'package:safenetvpn/ui/core/ui/auth/auth.dart' show Auth;

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Get.put<CipherGateModel>(CipherGateModel());
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SizedBox(height: 30),
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF232326),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Text(
              'Forgot Password?',
              style: GoogleFonts.daysOne(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),
            Text(
              "Please enter your email we will send you password reset link to your email",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Email",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),

                GradientTextField(
                  hintText: "Enter your email",
                  controller: provider.idA,
                ),
              ],
            ),
            SizedBox(height: 15),

            Obx(() => GestureDetector(
              onTap: () {
                provider.invokeGamma(context);
              },
              child: Container(
                height: 60,
                width: double.infinity,
                padding: EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
                child: provider.flux.value
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 5,
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
              ),
            )),

            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Auth()),
                );
              },
              child: ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ).createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  "Back to login ? ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
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

  @override
  void initState() {
    super.initState();
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
          border: Border.all(
            width: 2,
            color: Colors.white, // this will be replaced by shader
          ),
        ),
        child: TextField(
          focusNode: _focusNode,
          controller: widget.controller,
          obscureText: widget.obscureText,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Colors.white),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
