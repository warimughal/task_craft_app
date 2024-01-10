// ignore_for_file: prefer_const_constructors, avoid_unnecessary_containers, avoid_print, non_constant_identifier_names, sort_child_properties_last, unused_local_variable, no_leading_underscores_for_local_identifiers, unused_element, use_build_context_synchronously, prefer_const_literals_to_create_immutables, file_names

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_craft_app/FCM%20Notifications/notification_services.dart';
import 'package:task_craft_app/authentication/logInScreen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController userEmailController = TextEditingController();
  TextEditingController userPasswordController = TextEditingController();
  TextEditingController userConfirmPasswordController = TextEditingController();
  NotificationServices notificationServices = NotificationServices();

//For Form Validations
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  void validate() {
    if (formkey.currentState!.validate()) {
      print("Ok");
    } else {
      print("Error");
    }
  }

  bool passwordObscured = true;
  bool passwordObscured1 = true;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
        ),
        backgroundColor: Colors.orange,
        body: FocusScope(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30.0, left: 110),
                    child: Text(
                      "TaskCraft",
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 120.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      child: Form(
                        autovalidateMode: AutovalidateMode.always,
                        key: formkey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 25),
                              child: TextFormField(
                                controller: userNameController,
                                decoration: InputDecoration(
                                    suffixIcon: Icon(Icons.person,
                                        color: Colors.orange),
                                    label: Text(
                                      "Full Name",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.orange),
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(20))),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return "Required";
                                  } else {
                                    return null;
                                  }
                                },
                              ),
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: userEmailController,
                              decoration: InputDecoration(
                                  suffixIcon:
                                      Icon(Icons.email, color: Colors.orange),
                                  label: Text(
                                    "Email",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orange),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              validator: (val) {
                                if (val!.isEmpty) {
                                  return "Required";
                                } else if (!val.contains("@gmail.com")) {
                                  return "Please enter a valid Gmail address";
                                } else {
                                  return null;
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: userPasswordController,
                              obscureText: passwordObscured,
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        passwordObscured = !passwordObscured;
                                      });
                                    },
                                    icon: Icon(passwordObscured
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    color: Colors.orange,
                                  ),
                                  label: Text(
                                    "Password",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orange),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              validator: (val) {
                                if (val!.isEmpty) {
                                  return "Required";
                                } else if (val.length < 6) {
                                  return "At Least 6 characters required";
                                } else if (!RegExp(r'^(?=.*?[A-Z])')
                                    .hasMatch(val)) {
                                  return "At least 1 uppercase letter required";
                                } else if (!RegExp(r'^(?=.*?[0-9])')
                                    .hasMatch(val)) {
                                  return "At least 1 digit required";
                                } else if (!RegExp(r'^(?=.*?[!@#\$&*~])')
                                    .hasMatch(val)) {
                                  return "At least 1 special character required";
                                } else {
                                  return null;
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: userConfirmPasswordController,
                              obscureText: passwordObscured1,
                              decoration: InputDecoration(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        passwordObscured1 = !passwordObscured1;
                                      });
                                    },
                                    icon: Icon(passwordObscured1
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    color: Colors.orange,
                                  ),
                                  label: Text(
                                    "Confirm Password",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Colors.orange),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20))),
                              validator: (val) {
                                if (val!.isEmpty) {
                                  return "Required";
                                } else if (val.length < 6) {
                                  return "At Least 6 characters required";
                                } else if (val != userPasswordController.text) {
                                  return "Wrong Password";
                                } else if (!RegExp(r'^(?=.*?[A-Z])')
                                    .hasMatch(val)) {
                                  return "At least 1 uppercase letter required";
                                } else if (!RegExp(r'^(?=.*?[0-9])')
                                    .hasMatch(val)) {
                                  return "At least 1 digit required";
                                } else if (!RegExp(r'^(?=.*?[!@#\$&*~])')
                                    .hasMatch(val)) {
                                  return "At least 1 special character required";
                                } else {
                                  return null;
                                }
                              },
                            ),
                            SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () async {
                                if (formkey.currentState!.validate()) {
                                  setState(() {
                                    isLoading = true;
                                  });

                                  var userName = userNameController.text.trim();
                                  var userEmail =
                                      userEmailController.text.trim();
                                  var userPassword =
                                      userPasswordController.text.trim();
                                  var userConfirmPassword =
                                      userConfirmPasswordController.text.trim();

                                  try {
                                    var existingMethods = await FirebaseAuth
                                        .instance
                                        .fetchSignInMethodsForEmail(userEmail);

                                    if (existingMethods.isEmpty) {
                                      // Get the device token
                                      String deviceToken =
                                          await notificationServices
                                              .getDeviceToken();

                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                              email: userEmail,
                                              password: userPassword)
                                          .then((value) async {
                                        log("User Created");
                                        await SignUpUser(
                                          userName,
                                          userEmail,
                                          userPassword,
                                          userConfirmPassword,
                                          deviceToken, // Pass deviceToken to the function
                                          context,
                                        );
                                      });
                                    } else {
                                      print("Email already exists");
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    print("Error $e");
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(Colors.orange),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                    side: BorderSide(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                                elevation: MaterialStateProperty.all(4),
                                shadowColor:
                                    MaterialStateProperty.all(Colors.white),
                              ),
                              child: isLoading
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    )
                                  : Text(
                                      "Sign Up",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                            ),
                            SizedBox(height: 11),
                            Align(
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Already have an account?"),
                                  SizedBox(width: 5),
                                  GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LogInScreen()));
                                      },
                                      child: Text(
                                        "Log In",
                                        style: TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold),
                                      ))
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

SignUpUser(
  String userName,
  String userEmail,
  String userPassword,
  String userConfirmPassword,
  String deviceToken,
  BuildContext context,
) async {
  User? userid = FirebaseAuth.instance.currentUser;

  try {
    await FirebaseFirestore.instance.collection("users").doc(userid!.uid).set({
      'userName': userName,
      'userEmail': userEmail,
      'createdAt': DateTime.now(),
      'userId': userid.uid,
      'deviceToken': deviceToken,
    }).then((value) => {
          FirebaseAuth.instance.signOut(),
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LogInScreen()))
        });
  } on FirebaseAuthException catch (e) {
    print("Error $e");
  }
}
