// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps
import 'dart:convert';
import 'package:get/get.dart';
import 'dart:developer' show log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as net;
import 'package:safenetvpn/ui/widgets/customSnackBar.dart'
    show showCustomSnackBar;

import 'package:safenetvpn/utils/utils.dart';

import 'package:safenetvpn/domain/models/user.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:safenetvpn/view_model/homeGateModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safenetvpn/ui/core/ui/auth/auth.dart' show Auth;
import 'package:safenetvpn/ui/core/ui/bottomnav/bottomnav.dart' show Bottomnav;
import 'package:safenetvpn/services/analytics_service.dart';
import 'dart:io' show Platform;

class CipherGateModel extends GetxController {
  RxBool flux = false.obs;
  UserResponse? vault;
  User? get identity => vault?.user;

  RxBool modeShift = false.obs;

  TextEditingController idA = TextEditingController();
  TextEditingController idB = TextEditingController();

  // Helper method to get platform name
  String getPlatformName() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'desktop';
    }
  }

  TextEditingController idC = TextEditingController();
  TextEditingController idD = TextEditingController();
  TextEditingController idE = TextEditingController();
  TextEditingController idF = TextEditingController();

  void pivotView(bool m) {
    modeShift.value = m;
    update();
  }

  Future<void> invokeAlpha(BuildContext ctx) async {
    try {
      flux.value = true;
      update();

      // Validation
      if (idA.text.trim().isEmpty || idB.text.trim().isEmpty) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Error",
          "Email and password are required",
          Colors.red,
        );
        flux.value = false;
        update();
        return;
      }

      var hdr = {'Accept': 'application/json'};
      var rsp = await net.post(
        Uri.parse(Utils.LOGIN_URL),
        headers: hdr,
        body: {"email": idA.text.trim(), "password": idB.text},
      );

      var body = jsonDecode(rsp.body);
      log("Alpha Response: $body");

      if (rsp.statusCode == 200 || rsp.statusCode == 201) {
        if (body["status"] == true) {
          SharedPreferences box = await SharedPreferences.getInstance();
          await box.setBool('k', true);
          await box.setString('e', body['user']['email']);
          await box.setString('n', body['user']['slug']);
          await box.setString('r', body['user']['role']);
          await box.setString('p', idB.text);
          await box.setString('uid', body['user']['id'].toString());
          await box.setString('t', body["access_token"]);

          // Send user name to analytics
          AnalyticsService().setUserProperty('user_name', body['user']['slug']);
          AnalyticsService().trackLogin('email');

          // Set user platform
          AnalyticsService().setUserProperty(
            'user_platform',
            getPlatformName(),
          );

          idA.clear();
          idB.clear();
          flux.value = false;
          update();

          _flash(
            ctx,
            EvaIcons.checkmarkCircle,
            "Success",
            "Login successful",
            Colors.green,
          );

          var q = Get.find<HomeGateModel>();
          q.onItemTapped(0);

          Navigator.of(
            ctx,
          ).pushReplacement(MaterialPageRoute(builder: (_) => Bottomnav()));
        } else {
          // Server returned status false
          String errorMsg = body["message"] ?? "Login failed";
          _flash(
            ctx,
            EvaIcons.alertCircle,
            "Login Failed",
            errorMsg,
            Colors.red,
          );
          flux.value = false;
          update();
        }
      } else if (rsp.statusCode == 401) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Authentication Failed",
          "Invalid email or password",
          Colors.red,
        );
        flux.value = false;
        update();
      } else if (rsp.statusCode == 422) {
        String errorMsg = body["message"] ?? "Validation error";
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Validation Error",
          errorMsg,
          Colors.red,
        );
        flux.value = false;
        update();
      } else {
        String errorMsg = body["message"] ?? "Login failed. Please try again";
        _flash(ctx, EvaIcons.alertCircle, "Error", errorMsg, Colors.red);
        flux.value = false;
        update();
      }
    } catch (err) {
      log("AlphaErr: $err");
      flux.value = false;
      update();
      _flash(
        ctx,
        EvaIcons.alertCircle,
        "Connection Error",
        "Unable to connect to server. Please check your internet connection",
        Colors.red,
      );
    }
  }

  Future<void> invokeBeta(BuildContext ctx) async {
    try {
      flux.value = true;
      update();

      // Validation
      if (idC.text.trim().isEmpty ||
          idA.text.trim().isEmpty ||
          idB.text.trim().isEmpty) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Error",
          "All fields are required",
          Colors.red,
        );
        flux.value = false;
        update();
        return;
      }

      if (idB.text.length < 6) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Error",
          "Password must be at least 6 characters",
          Colors.red,
        );
        flux.value = false;
        update();
        return;
      }

      var hdr = {'Accept': 'application/json'};
      var rsp = await net.post(
        Uri.parse(Utils.SIGN_UP_URL),
        headers: hdr,
        body: {
          "name": idC.text.trim(),
          "email": idA.text.trim(),
          "password": idB.text,
        },
      );

      var body = jsonDecode(rsp.body);
      log("Beta Response: $body");

      if (body["status"] == true) {
        // Success
        idC.clear();
        idA.clear();
        idB.clear();
        flux.value = false;
        update();

        _flash(
          ctx,
          EvaIcons.checkmarkCircle,
          "Success",
          "Account created successfully! Please login",
          Colors.green,
        );

        // Switch to login mode after successful signup
        pivotView(false);
      } else {
        // Handle error response
        flux.value = false;
        update();

        String errorMsg = "Registration failed";

        // Check if errors array exists
        if (body["errors"] != null) {
          if (body["errors"] is List && (body["errors"] as List).isNotEmpty) {
            // errors is a List - get first error
            errorMsg = body["errors"][0].toString();
          } else if (body["errors"] is Map) {
            // errors is a Map - get first error message
            var errors = body["errors"] as Map;
            if (errors.isNotEmpty) {
              var firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMsg = firstError[0].toString();
              } else {
                errorMsg = firstError.toString();
              }
            }
          } else if (body["errors"] is String) {
            errorMsg = body["errors"];
          }
        } else if (body["message"] != null) {
          errorMsg = body["message"];
        }

        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Registration Failed",
          errorMsg,
          Colors.red,
        );
      }
    } catch (err) {
      log("BetaErr: $err");
      flux.value = false;
      update();
      _flash(
        ctx,
        EvaIcons.alertCircle,
        "Connection Error",
        "Unable to connect to server. Please check your internet connection",
        Colors.red,
      );
    }
  }

  Future<void> invokeGamma(BuildContext ctx) async {
    try {
      flux.value = true;
      update();

      // Validation
      if (idA.text.trim().isEmpty) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Error",
          "Email is required",
          Colors.red,
        );
        flux.value = false;
        update();
        return;
      }

      var hdr = {'Accept': 'application/json'};
      var rsp = await net.post(
        Uri.parse(Utils.FORGOT_PASSWORD_URL),
        headers: hdr,
        body: {"email": idA.text.trim()},
      );

      var body = jsonDecode(rsp.body);
      log("Gamma Response: $body");

      if (rsp.statusCode == 200 || rsp.statusCode == 201) {
        if (body["status"] == true) {
          idA.clear();
          flux.value = false;
          update();
          _flash(
            ctx,
            EvaIcons.checkmarkCircle,
            "Success",
            "Password reset link sent to your email",
            Colors.green,
          );
        } else {
          String errorMsg = body["message"] ?? "Failed to send reset link";
          _flash(ctx, EvaIcons.alertCircle, "Error", errorMsg, Colors.red);
          flux.value = false;
          update();
        }
      } else if (rsp.statusCode == 404) {
        _flash(
          ctx,
          EvaIcons.alertCircle,
          "Not Found",
          "Email not found. Please check and try again",
          Colors.red,
        );
        flux.value = false;
        update();
      } else {
        String errorMsg = body["message"] ?? "Failed to send reset link";
        _flash(ctx, EvaIcons.alertCircle, "Error", errorMsg, Colors.red);
        flux.value = false;
        update();
      }
    } catch (err) {
      log("GammaErr: $err");
      flux.value = false;
      update();
      _flash(
        ctx,
        EvaIcons.alertCircle,
        "Connection Error",
        "Unable to connect to server. Please check your internet connection",
        Colors.red,
      );
    }
  }

  void shatter(BuildContext ctx) {
    idA.clear();
    idB.clear();
    idC.clear();
    SharedPreferences.getInstance().then((x) => x.clear());
    Navigator.of(
      ctx,
    ).pushReplacement(MaterialPageRoute(builder: (_) => Auth()));
  }

  Future<void> probe(BuildContext ctx) async {
    try {
      SharedPreferences x = await SharedPreferences.getInstance();
      String? token = x.getString('t');

      var hdr = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Maze/1.0',
        'Authorization': 'Bearer $token',
      };

      var rsp = await net.get(Uri.parse(Utils.USER_URL), headers: hdr);
      var body = jsonDecode(rsp.body);
      log("Probe: $body");

      if (body['status'] == true) {
        vault = UserResponse.fromJson(body);
        update();
      } else {
        log("ProbeFail: ${body['message']}");
      }
    } catch (err) {
      log("ProbeErr: $err");
      // Silently log the error without showing snackbar
    }
  }

  Future<void> transmit(BuildContext ctx) async {
    try {
      flux.value = true;
      update();
      SharedPreferences x = await SharedPreferences.getInstance();
      String? token = x.getString('t');

      var hdr = {'Authorization': 'Bearer $token'};

      var rsp = await net.post(
        Uri.parse(Utils.FEEDBACK_URL),
        headers: hdr,
        body: {"subject": idE.text, "email": idD.text, "message": idF.text},
      );

      var body = jsonDecode(rsp.body);
      if (body != null) {
        idE.clear();
        idD.clear();
        idF.clear();
        flux.value = false;
        update();
        _flash(ctx, Icons.check_circle, "OK", "Feedback sent", Colors.green);
      } else {
        _flash(ctx, Icons.error, "Error", "Feedback failed", Colors.red);
      }
    } catch (err) {
      log("TransmitErr:$err");
      flux.value = false;
      update();
      _flash(ctx, Icons.error, "Error", "Feedback failed", Colors.red);
    }
  }

  void _flash(BuildContext c, IconData i, String t, String m, Color col) {
    showCustomSnackBar(c, i, t, m, col);
  }
}
