// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, unused_label, avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_craft_app/authentication/logInScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  void validate() {
    if (formkey.currentState!.validate()) {
      print("Ok");
    } else {
      print("Error");
    }
  }

  bool isLoading = false;

  TextEditingController forgotPasswordController = TextEditingController();
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
                  child: Form(
                    autovalidateMode: AutovalidateMode.always,
                    key: formkey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 25),
                          child: TextFormField(
                            controller: forgotPasswordController,
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
                        ),
                        SizedBox(height: 50),
                        ElevatedButton(
                          onPressed: () async {
                            if (formkey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                              });
                              var forgotEmail =
                                  forgotPasswordController.text.trim();
                              try {
                                await FirebaseAuth.instance
                                    .sendPasswordResetEmail(email: forgotEmail)
                                    .then((value) => {
                                          print("Email Sent"),
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LogInScreen()))
                                        });
                              } on FirebaseAuthException catch (e) {
                                print("Error $e");
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
                                side: BorderSide(color: Colors.white, width: 2),
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
                                  "Forgot Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
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
        ));
  }
}
