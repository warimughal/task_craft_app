// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, prefer_const_literals_to_create_immutables, unused_local_variable, dead_code, use_build_context_synchronously, avoid_print, file_names

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_craft_app/authentication/forgotPasswordScreen.dart';
import 'package:task_craft_app/authentication/signUPScreen.dart';
import 'package:task_craft_app/home/homeScreen.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  void validate() {
    if (formkey.currentState!.validate()) {
      print("Ok");
    } else {
      print("Error");
    }
  }

  bool passwordObscured = true;
  bool isLoading = false;

  TextEditingController loginEmailController = TextEditingController();
  TextEditingController loginPasswordController = TextEditingController();

  //For Snackbar
  Color backgroundColor = Colors.white;
  Color textColor = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
        ),
        backgroundColor: Colors.orange,
        body: Stack(
          children: [
            Container(
              height: double.infinity,
              width: double.infinity,
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
                  child: SingleChildScrollView(
                    child: Form(
                      autovalidateMode: AutovalidateMode.always,
                      key: formkey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 25),
                            child: TextFormField(
                              controller: loginEmailController,
                              decoration: InputDecoration(
                                  suffixIcon: Icon(
                                    Icons.email,
                                    color: Colors.orange,
                                  ),
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
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            controller: loginPasswordController,
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ForgotPasswordScreen()));
                              },
                              child: Text(
                                "Forgot Password",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orange),
                              ),
                            ),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () async {
                              if (formkey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });

                                var loginEmail =
                                    loginEmailController.text.trim();
                                var loginPassword =
                                    loginPasswordController.text.trim();

                                try {
                                  final UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                    email: loginEmail,
                                    password: loginPassword,
                                  );
                                  if (userCredential.user != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => HomeScreen(),
                                      ),
                                    );
                                  }
                                } on FirebaseAuthException catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: backgroundColor,
                                      content: Center(
                                        child: Text(
                                          "Error: $e",
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      duration: Duration(seconds: 3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.orange),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side:
                                      BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(4),
                              shadowColor:
                                  MaterialStateProperty.all(Colors.white),
                            ),
                            child: isLoading
                                ? CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    "Sign In",
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
                                Text("Don't have an account?"),
                                SizedBox(width: 5),
                                GestureDetector(
                                    onTap: () {
                                      Navigator.pop(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  SignUpScreen()));
                                    },
                                    child: Text(
                                      "Sign Up",
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
            ),
          ],
        ));
  }
}
