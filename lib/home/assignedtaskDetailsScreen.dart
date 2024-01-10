// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_print, unused_element, avoid_function_literals_in_foreach_calls, unused_field, avoid_unnecessary_containers, unused_local_variable, unused_import, prefer_final_fields, use_rethrow_when_possible, sized_box_for_whitespace, unnecessary_string_interpolations, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_craft_app/home/commentsScreen.dart';
import 'dart:io';
import 'package:task_craft_app/home/pdfviewerscreen.dart';

class AssignedTaskDetailsScreen extends StatefulWidget {
  final String taskName;

  const AssignedTaskDetailsScreen({
    Key? key,
    required this.taskName,
  }) : super(key: key);

  @override
  State<AssignedTaskDetailsScreen> createState() =>
      _AssignedTaskDetailsScreenState();
}

class _AssignedTaskDetailsScreenState extends State<AssignedTaskDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  String imageUrl = '';
  String taskDescription = '';
  String employeeNames = '';
  String? pdfFileName;
  String? pdfDownloadLink;

  DateTime? startDate;
  DateTime? endDate;
  String remainingTime = '';
  late Timer _timer;
  int _elapsedTimeInSeconds = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTaskDescription();
    _fetchPdfFileName();
    _startTimer();
  }

  Future<void> _fetchPdfFileName() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("tasks")
          .where('taskName', isEqualTo: widget.taskName)
          .where('members', arrayContains: user?.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          pdfFileName = querySnapshot.docs.first['pdfFileName'] ?? '';
          pdfDownloadLink = querySnapshot.docs.first['pdfDownloadLink'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching pdfFileName: $e");
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTimeInSeconds > 0) {
          _elapsedTimeInSeconds--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _fetchTaskDescription() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("tasks")
          .where('taskName', isEqualTo: widget.taskName)
          .where('members', arrayContains: user?.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          taskDescription =
              querySnapshot.docs.first['taskDescription'] as String;

          // Fetch image URL
          imageUrl = querySnapshot.docs.first['imageUrl'] ?? '';

          if (querySnapshot.docs.first['startDate'] != null) {
            startDate =
                (querySnapshot.docs.first['startDate'] as Timestamp).toDate();
          }

          if (querySnapshot.docs.first['endDate'] != null) {
            endDate =
                (querySnapshot.docs.first['endDate'] as Timestamp).toDate();
          }

          // Fetch employee names
          if (querySnapshot.docs.first['employeeNames'] != null) {
            employeeNames = querySnapshot.docs.first['employeeNames'];
          }

          // Fetch members
          if (querySnapshot.docs.first['members'] != null) {
            List<dynamic> membersList = querySnapshot.docs.first['members'];
            print("Members: $membersList");
          }
        });
      }
    } catch (e) {
      print("Error fetching task details: $e");
    }
  }

  Future<List<dynamic>> _fetchMembers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("tasks")
          .where('taskName', isEqualTo: widget.taskName)
          .where('members', arrayContains: user?.email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<dynamic> membersList = querySnapshot.docs.first['members'];
        return membersList;
      }

      return [];
    } catch (e) {
      print("Error fetching members: $e");
      return [];
    }
  }

  // Add a method to load the image from the URL
  Widget _buildImageWidget() {
    if (imageUrl.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          _showFullScreenImage();
        },
        child: Image.network(imageUrl, width: 100, height: 50),
      );
    } else {
      return Container();
    }
  }

  void _showFullScreenImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  // save comments
  TextEditingController commentController = TextEditingController();
  List<String> comments = [];

  Future<void> _saveComment() async {
    try {
      String commentText = commentController.text;

      if (commentText.isNotEmpty) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        String userId = currentUser?.uid ?? '';

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        String userName = userSnapshot['userName'] ?? '';

        await FirebaseFirestore.instance.collection("comments").add({
          'text': commentText,
          'userId': userId,
          'userName': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        commentController.clear();
      }
    } catch (e) {
      print("Error saving comment: $e");
    }
  }

  Future<void> _openPdfView() async {
    setState(() {
      isLoading = true;
    });

    if (pdfDownloadLink != null) {
      try {
        PDFDocument doc = await PDFDocument.fromURL(pdfDownloadLink!);

        setState(() {
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(document: doc),
          ),
        );
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print("Error loading PDF: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          widget.taskName,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 2.0,
                    child: ListTile(
                      leading: Icon(
                        Icons.note_add,
                        color: Colors.orange,
                      ),
                      title: Text(
                        'Task Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                          color: Colors.orange,
                        ),
                      ),
                      subtitle: taskDescription.isNotEmpty
                          ? GestureDetector(
                              child: Text(
                                taskDescription,
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13.0,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                _buildImageWidget(),
              ],
            ),
            GestureDetector(
              onTap: () {
                _openPdfView();
              },
              child: Card(
                elevation: 2.0,
                child: ListTile(
                  leading: Icon(
                    Icons.file_copy,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'PDF File Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                      color: Colors.orange,
                    ),
                  ),
                  subtitle: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Text(
                          pdfFileName != null && pdfFileName!.isNotEmpty
                              ? pdfFileName!
                              : "Pdf File Not available",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                          ),
                        ),
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              child: ListTile(
                leading: Icon(
                  Icons.person,
                  color: Colors.orange,
                ),
                title: Text(
                  'Employee Names',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                    color: Colors.orange,
                  ),
                ),
                subtitle: GestureDetector(
                  child: Text(
                    employeeNames,
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              child: ListTile(
                leading: Icon(
                  Icons.person_add,
                  color: Colors.orange,
                ),
                title: Text(
                  'Added Members',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                    color: Colors.orange,
                  ),
                ),
                // onTap: () {},
                subtitle: FutureBuilder<List<dynamic>>(
                  future: _fetchMembers(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error fetching members: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text(
                        'No members available',
                        style: TextStyle(color: Colors.orange),
                      );
                    } else {
                      List<dynamic> members = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: members.map((member) {
                          return Text(
                            member,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13.0,
                            ),
                          );
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
            ),
            Card(
              elevation: 2.0,
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: Colors.orange,
                ),
                title: Text(
                  'Start Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                    color: Colors.orange,
                  ),
                ),
                subtitle: startDate != null
                    ? Text(
                        '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13.0,
                        ),
                      )
                    : null,
              ),
            ),
            Card(
              elevation: 2.0,
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: Colors.orange,
                ),
                title: Text(
                  'End Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                    color: Colors.orange,
                  ),
                ),
                subtitle: endDate != null
                    ? Text(
                        '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13.0,
                        ),
                      )
                    : null,
              ),
            ),
            Card(
              elevation: 2.0,
              child: ListTile(
                leading: Icon(
                  Icons.timer,
                  color: Colors.orange,
                ),
                title: Text(
                  'Remaining Time',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.0,
                    color: Colors.orange,
                  ),
                ),
                subtitle: Text(
                  _calculateRemainingTime(),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13.0,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(
                      taskName: widget.taskName,
                    ),
                  ),
                );
              },
              child: Card(
                color: Colors.orange,
                elevation: 2.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Add Comments',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to format remaining time
  String _formatRemainingTime(int remainingTimeInSeconds) {
    final remainingDays = remainingTimeInSeconds ~/ 86400;
    final remainingHours = (remainingTimeInSeconds % 86400) ~/ 3600;
    final remainingMinutes = (remainingTimeInSeconds % 3600) ~/ 60;
    final remainingSeconds = remainingTimeInSeconds % 60;

    if (remainingTimeInSeconds <= 0) {
      return 'Task has ended';
    } else {
      return '$remainingDays days $remainingHours hours $remainingMinutes minutes $remainingSeconds seconds';
    }
  }

  String _calculateRemainingTime() {
    if (startDate == null || endDate == null) {
      return 'Select start and end dates';
    }

    final storedRemainingTimeInSeconds = remainingTime.isNotEmpty
        ? int.parse(remainingTime.split(' ')[0]) * 86400 +
            int.parse(remainingTime.split(' ')[2]) * 3600 +
            int.parse(remainingTime.split(' ')[4]) * 60 +
            int.parse(remainingTime.split(' ')[6])
        : 0;

    final remainingTimeInSeconds =
        endDate!.difference(DateTime.now()).inSeconds - _elapsedTimeInSeconds;

    final totalRemainingTimeInSeconds =
        storedRemainingTimeInSeconds + remainingTimeInSeconds;

    final remainingDays = totalRemainingTimeInSeconds ~/ 86400;
    final remainingHours = (totalRemainingTimeInSeconds % 86400) ~/ 3600;
    final remainingMinutes = (totalRemainingTimeInSeconds % 3600) ~/ 60;
    final remainingSeconds = totalRemainingTimeInSeconds % 60;

    if (totalRemainingTimeInSeconds <= 0) {
      return 'Task has ended';
    } else {
      return '$remainingDays days $remainingHours hours $remainingMinutes minutes $remainingSeconds seconds';
    }
  }
}
