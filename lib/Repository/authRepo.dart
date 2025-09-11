// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:convert';
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:safenetvpn/Models/user.dart';
import 'package:safenetvpn/Views/auth/auth.dart';
import 'package:safenetvpn/Defaults/defaults.dart';
import 'package:safenetvpn/Widgets/customSnackBar.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:safenetvpn/Views/bottomnav/bottomnav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safenetvpn/Repository/homeRepo.dart' show HomeRepo;

class AuthRepo extends GetxController {
  RxBool isloading = false.obs;
  UserResponse? user;
  User? get userInfo => user?.user;

  RxBool toggleAuthView = false.obs;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController feedbackSubjectController = TextEditingController();
  TextEditingController feedbackEmailController = TextEditingController();
  TextEditingController feedbackMessageController = TextEditingController();

  void setAuthView(bool isSignUp) {
    toggleAuthView.value = isSignUp;
    update();
  }

  void login(BuildContext context) async {
    try {
      isloading.value = true;
      update();
      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(Defaults.LOGIN_URL),
        headers: headers,
        body: {
          "email": emailController.text,
          "password": passwordController.text,
        },
      );

      var data = jsonDecode(response.body);
      log("login response $data");
      if (data["status"] == true) {
        // Handle successful login
        SharedPreferences preferences = await SharedPreferences.getInstance();
        preferences.setBool('isLoggedIn', true);
        await preferences.setString('email', data['user']['email']);
        await preferences.setString('name', data['user']['slug']);
        await preferences.setString('role', data['user']['role']);
        await preferences.setString('password', passwordController.text);
        await preferences.setString('user_id', data['user']['id'].toString());
        await preferences.setString('access_token', data["access_token"]);
        isloading.value = false;

        update();
        emailController.clear();
        passwordController.clear();
        var ref = Get.find<HomeRepo>();

        ref.onItemTapped(0);
        update();
        isloading.value = false;
        update();

        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => Bottomnav()));
      } else {
        // Handle login error
        showCustomSnackBar(
          context,
          EvaIcons.alertCircle,
          "Error",
          data["message"] ?? "Login failed",
          Colors.red,
        );
        isloading.value = false;
        update();
      }
    } catch (error) {
      log("Login failed: $error");
      isloading.value = false;
      update();
      showCustomSnackBar(
        context,
        EvaIcons.alertCircle,
        "Error",
        "An error occurred during login",
        Colors.red,
      );
    }
  }

  void signup(BuildContext context) async {
    try {
      isloading.value = true;
      update();

      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(Defaults.SIGN_UP_URL),
        headers: headers,
        body: {
          "name": usernameController.text,
          "email": emailController.text,
          "password": passwordController.text,
        },
      );
      log(response.body);
      var data = jsonDecode(response.body);
      log("Data $data");
      
      if (data["status"] == true) {
        log("Data $data");
        isloading.value = false;
        update();

        usernameController.clear();
        emailController.clear();
        passwordController.clear();

        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle,
          "Success",
          "Signup successful you can login now",
          Colors.green,
        );
      }
    } catch (error) {
      log("Signup failed: $error");
      isloading.value = false;
      update();
    }
  }

  void forgotPassword(BuildContext context) async {
    try {
      isloading.value = true;
      update();
      var headers = {'Accept': 'application/json'};
      var response = await http.post(
        Uri.parse(Defaults.FORGOT_PASSWORD_URL),
        headers: headers,
        body: {"email": emailController.text},
      );
      var data = jsonDecode(response.body);
      if (data["status"] == true) {
        isloading.value = false;
        update();
        emailController.clear();
        log("Forgot password email sent: $data");
        showCustomSnackBar(
          context,
          EvaIcons.checkmarkCircle,
          "Success",
          "Password reset email sent",
          Colors.green,
        );
      } else {
        isloading.value = false;
        update();
      }
    } catch (error) {
      log("Forgot password failed: $error");
      isloading.value = false;
      update();
    }
  }

  logout(BuildContext context) {
    emailController.clear();
    passwordController.clear();
    usernameController.clear();
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => Auth()));
  }

  Future<void> getUser(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      var headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:127.0) Gecko/20100101 Firefox/127.0',
        'Authorization': 'Bearer $token',
      };

      var res = await http.get(Uri.parse(Defaults.USER_URL), headers: headers);

      var data = jsonDecode(res.body);
      log("Data is that $data");

      if (data['status'] == true) {
        user = UserResponse.fromJson(data);
        log("User is that $user");
        update();
      } else {
        log("Failed to retrieve user data: ${data['message']}");
      }
    } catch (error) {
      log("Error getting user: $error");
      showCustomSnackBar(
        context,
        EvaIcons.alertCircle,
        "Error",
        "Failed to retrieve user information",
        Colors.red,
      );
    }
  }

  Future<void> feedbackStore(BuildContext context) async {
    try {
      isloading.value = true;
      update();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      var headers = {'Authorization': 'Bearer $token'};

      var response = await http.post(
        Uri.parse(Defaults.FEEDBACK_URL),
        headers: headers,
        body: {
          "subject": feedbackSubjectController.text,
          "email": feedbackEmailController.text,
          "message": feedbackMessageController.text,
        },
      );
      var data = jsonDecode(response.body);
      if (data != null) {
        feedbackSubjectController.clear();
        feedbackEmailController.clear();
        feedbackMessageController.clear();
        isloading.value = false;
        update();
        showCustomSnackBar(
          context,
          Icons.check_circle,
          'Success',
          'Feedback submitted successfully',
          Colors.green,
        );
      } else {
        showCustomSnackBar(
          context,
          Icons.error,
          'Error',
          'Failed to send feedback',
          Colors.red,
        );
      }
    } catch (error) {
      log("Error in feedbackStore: $error");
      isloading.value = false;
      update();
      showCustomSnackBar(
        context,
        Icons.error,
        'Error',
        'Failed to send feedback',
        Colors.red,
      );
    }
  }
}
