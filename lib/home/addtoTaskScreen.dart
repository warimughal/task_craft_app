// ignore_for_file: prefer_const_constructors, file_names, use_build_context_synchronously, avoid_print, unused_element, dead_code, no_leading_underscores_for_local_identifiers, unused_field, prefer_final_fields, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, prefer_collection_literals, body_might_complete_normally_nullable, unused_local_variable, non_constant_identifier_names, unnecessary_null_comparison, deprecated_member_use, avoid_function_literals_in_foreach_calls

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_craft_app/FCM%20Notifications/notification_services.dart';
import 'package:task_craft_app/home/taskScreen.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class AddToTaskScreen extends StatefulWidget {
  final String projectName;

  const AddToTaskScreen({super.key, required this.projectName});

  @override
  State<AddToTaskScreen> createState() => _AddToTaskScreenState();
}

class _AddToTaskScreenState extends State<AddToTaskScreen> {
  NotificationServices notificationServices = NotificationServices();
  DateTime? startDate;
  DateTime? endDate;
  String? _firstLetter;
  List<String> addedMembers = [];
  Map<String, String> usersData = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateTimer();

    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);

    // notificationServices.isTokenRefresh();
    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
      }
    });
    _fetchUsersData();
  }

  Future<void> _fetchUsersData() async {
    Map<String, String> data = await notificationServices.fetchUsersData();

    setState(() {
      usersData = data;
    });
  }

  late Timer _timer;
  int _elapsedTimeInSeconds = 0;

  // Function to update the timer
  void _updateTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTimeInSeconds++;
      });
    });
  }

//Add Tasks
  Future<void> _addTaskToFirestore(String projectName) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (startDate == null || endDate == null) {
      print('Select start and end dates');
      return;
    }

    try {
      final remainingTimeInSeconds =
          endDate!.difference(DateTime.now()).inSeconds;

      String? pdfDownloadLink;
      if (pdfFileName != null) {
        pdfDownloadLink = await _fetchPdfDownloadLink(pdfFileName!);
        if (pdfDownloadLink == null) {
          pdfDownloadLink = await uploadPdf(pdfFileName!, File(pdfFileName!));
          await savePdfUrlToFirestore(pdfFileName!, pdfDownloadLink);
        }
      }

      String taskAssigneeToken =
          usersData[FirebaseAuth.instance.currentUser!.email] ?? '';

      DocumentReference taskReference =
          await _firestore.collection("tasks").add({
        'userId': user!.uid,
        'projectName': projectName,
        'taskName': _taskNameController.text,
        'taskDescription': _taskDescriptionController.text,
        'employeeNames': _employeeNameController.text,
        'startDate': startDate,
        'endDate': endDate,
        'remainingTimeInSeconds': remainingTimeInSeconds,
        'imageUrl': imageUrl,
        'pdfFileName': pdfFileName,
        'pdfDownloadLink': pdfDownloadLink,
        'members': addedMembersSet.toList(),
        'taskassignee': FirebaseAuth.instance.currentUser!.email,
        'taskAssigneeToken': taskAssigneeToken,
        'timestamp': FieldValue.serverTimestamp(),
      });

      String taskId = taskReference.id;

      await _firestore.collection("tasks").doc(taskId).update({
        'taskId': taskId,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskScreen(projectName: projectName),
        ),
      );
    } catch (e) {
      print('Error creating task: $e');
    }
  }

//Add members to firebase
  Set<String> addedMembersSet = Set<String>();

  String taskId = '';

  Future<void> _addMemberToFirestore(String userEmail, String taskId) async {
    try {
      if (addedMembersSet.contains(userEmail)) {
        print('User with email $userEmail is already added to the project');
        return;
      }

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userEmail', isEqualTo: userEmail)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userName = userSnapshot.docs.first['userName'];
        _firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : null;
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        String taskAssigneeToken =
            usersData[FirebaseAuth.instance.currentUser!.email] ?? '';

        // Save the member document
        DocumentReference taskReference =
            await _firestore.collection("members").add({
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'userEmail': userEmail,
          'userName': userName,
          'taskassignee': FirebaseAuth.instance.currentUser!.email,
          'taskAssigneeToken': taskAssigneeToken, // Save task assignee's token
        });

        String taskId = taskReference.id;
        String memberId = taskReference.id;

        await taskReference.update({
          'taskId': taskId,
          'memberId': memberId,
        });

        addedMembersSet.add(userEmail);
      } else {
        print('User with email $userEmail does not exist');
      }
    } catch (e) {
      print('Error adding member: $e');
    }
  }

  // Function to save the pending invitation to Firestore
  Future<void> _savePendingInvitation(String userEmail) async {
    try {
      await _firestore.collection("pendingInvitations").add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'userEmail': userEmail,
      });
    } catch (e) {
      print('Error saving pending invitation: $e');
    }
  }

// show dialog and add member
  bool isLoading = false;

  // show dialog and add member
  Future<void> _showAddMemberDialog(String taskId) async {
    String? email;
    final _formKey = GlobalKey<FormState>();
    bool isEmailRegistered = true;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Add Members',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              content: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            onChanged: (value) {
                              email = value;
                            },
                            decoration: InputDecoration(
                              suffixIcon:
                                  Icon(Icons.email, color: Colors.orange),
                              label: Text(
                                "Email",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.orange,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            validator: (val) {
                              if (val!.isEmpty) {
                                return "Email is required";
                              } else if (!val.contains("@gmail.com")) {
                                return "Please enter a valid Gmail address";
                              } else {
                                return null;
                              }
                            },
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() {
                                  isLoading = true;
                                });

                                bool isUserExists =
                                    await _checkUserExistence(email);

                                if (isUserExists) {
                                  print('Send invitation to $email');
                                  isEmailRegistered = true;

                                  await _addMemberToFirestore(email!, taskId);

                                  setState(() {
                                    addedMembers.add(email!);
                                  });

                                  // Fetch the user's device token from the users collection
                                  String? userToken = usersData[email];

                                  // Now you can use userToken in your FCM message
                                  var data = {
                                    'to': userToken,
                                    'priority': 'high',
                                    'notification': {
                                      'title': 'Task Invitation',
                                      'body':
                                          'You are invited to join the task',
                                      'click_action':
                                          'FLUTTER_NOTIFICATION_CLICK',
                                    },
                                    'data': {
                                      'type': 'message',
                                      'id': '12345',
                                    }
                                  };

                                  await http.post(
                                    Uri.parse(
                                        'https://fcm.googleapis.com/fcm/send'),
                                    body: jsonEncode(data),
                                    headers: {
                                      'Content-Type':
                                          'application/json; charset=UTF-8',
                                      'Authorization':
                                          'key=AAAAFDyLdDU:APA91bEswim0ELNIhWbb2Pl7MY1ss8jtLV4LfQgICIeqln7WFCVQ09VX2O9DNE6Ssi9VIJymqC6CQJiw0VXOkU-AcdXQ86903RvAraIV2-IdDQtNsIIjImoSOHdgK0BUnIB7y2mxYoqC',
                                    },
                                  );
                                } else {
                                  print(
                                      'User with email $email does not exist');
                                  isEmailRegistered = false;

                                  await _savePendingInvitation(email!);

                                  _showEmailNotRegisteredDialog();
                                }

                                setState(() {
                                  isLoading = false;
                                });

                                _formKey.currentState?.reset();
                                if (isEmailRegistered) {
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            icon: const Icon(Icons.send),
                            label: const Text('Send Invitation'),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.orange),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }

// Function to show a dialog indicating that the email is not registered
  void _showEmailNotRegisteredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Email Not Registered',
            style: TextStyle(color: Colors.orange),
          ),
          content: Text(
            'The entered email is not registered. Please register before sending an invitation.',
            style: TextStyle(color: Colors.orange),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.orange),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              ),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Function to check if the user exists in the Firestore users' collection
  Future<bool> _checkUserExistence(String? email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userEmail', isEqualTo: email)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // Function to fetch download link of PDF from Firestore
  Future<String?> _fetchPdfDownloadLink(String pdfFileName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('pdfFileName', isEqualTo: pdfFileName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['downloadLink'];
      } else {
        print('PDF with filename $pdfFileName not found');
        return null;
      }
    } catch (e) {
      print('Error fetching PDF download link: $e');
      return null;
    }
  }

// Start Date
  Future<void> _selectStartDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && pickedDate != startDate) {
      setState(() {
        startDate = pickedDate;
        _elapsedTimeInSeconds = 0;
        _updateTimer();
      });
    }
  }

// End Date
  Future<void> _selectEndDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
    );

    if (pickedDate != null && pickedDate != endDate) {
      setState(() {
        endDate = pickedDate;
      });
    }
  }

  Future<void> _showAttachmentOptionsDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Select Attachment Type',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                  fontSize: 20),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  pickFile();
                },
                child: Text(
                  'Files',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
                child: Text(
                  'Images',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //For image Picker
  bool isLoadingImage = false;
  bool isImageUploaded = false;
  String? imageUrl;

  Future<void> uploadImageToFirebase(File imageFile) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    Reference storageReference =
        FirebaseStorage.instance.ref().child('images/$fileName');

    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

    if (snapshot.state == TaskState.success) {
      final downloadUrl = await storageReference.getDownloadURL();
      setState(() {
        imageUrl = downloadUrl;
        isImageUploaded = true;
      });
    } else {
      print('Image upload failed');
      setState(() {
        isImageUploaded = false;
      });
    }
  }

  File? image;
  Future<void> pickImage(source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage == null) {
      return;
    }
    setState(() {
      isLoadingImage = true;
      image = File(pickedImage.path);
    });

    await uploadImageToFirebase(image!);

    setState(() {
      isLoadingImage = false;
    });
  }

  final Reference _storage = FirebaseStorage.instance.ref().child('images');

  Future<List<String>> fetchImages() async {
    try {
      ListResult result = await _storage.list();

      List<String> downloadUrls = [];
      for (Reference ref in result.items) {
        String downloadUrl = await ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      print('Error fetching images: $e');
      return [];
    }
  }

// For File Picker
  Future<String> uploadPdf(String fileName, File file) async {
    final reference =
        FirebaseStorage.instance.ref().child("pdfs/$fileName.pdf");
    final UploadTask = reference.putFile(file);
    await UploadTask.whenComplete(() => {});
    final downloadLink = await reference.getDownloadURL();
    return downloadLink;
  }

  String? pdfFileName;
  bool isLoadingPdf = false;
  void pickFile() async {
    final pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (pickedFile != null) {
      String fileName = pickedFile.files[0].name;
      File file = File(pickedFile.files[0].path!);

      setState(() {
        pdfFileName = fileName;
        isLoadingPdf = true;
      });

      final downloadLink = await uploadPdf(fileName, file);

      await savePdfUrlToFirestore(fileName, downloadLink);

      setState(() {
        isLoadingPdf = false;
      });

      print("pdf uploaded successfully");
    }
  }

// Function to save download link to Firestore
  Future<void> savePdfUrlToFirestore(
      String pdfFileName, String downloadLink) async {
    try {
      CollectionReference tasks =
          FirebaseFirestore.instance.collection('tasks');

      await tasks.add({
        'pdfFileName': pdfFileName,
        'downloadLink': downloadLink,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Download link saved to Firestore");
    } catch (e) {
      print("Error saving download link: $e");
    }
  }

// Function to validate required fields
  bool _validateFields() {
    if (_taskNameController.text.isEmpty ||
        _taskDescriptionController.text.isEmpty ||
        _employeeNameController.text.isEmpty ||
        startDate == null ||
        endDate == null) {
      return false;
    }
    return true;
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Center(
                child: Text('Are you sure you want to go back?',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold))),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          centerTitle: true,
          title: Text(
            widget.projectName,
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          automaticallyImplyLeading: true,
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 0),
                  child: TextFormField(
                    controller: _taskNameController,
                    decoration: InputDecoration(
                      label: Text(
                        "Task Title",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.orange,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.orange,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        minLines: 2,
                        maxLines: 20,
                        keyboardType: TextInputType.multiline,
                        controller: _taskDescriptionController,
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            icon: Icon(Icons.attach_file, color: Colors.orange),
                            onPressed: () {
                              _showAttachmentOptionsDialog();
                            },
                          ),
                          label: Text(
                            "Task Description",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.orange,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: Colors.orange,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (image != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.file(
                            image!,
                            height: 100,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isLoadingPdf)
                  Center(child: CircularProgressIndicator())
                else if (pdfFileName != null)
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pdfFileName!,
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 15,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                SizedBox(
                  height: 10,
                ),
                TextFormField(
                  minLines: 2,
                  maxLines: 20,
                  keyboardType: TextInputType.multiline,
                  controller: _employeeNameController,
                  decoration: InputDecoration(
                    label: Text(
                      "Employee Names",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.orange,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.orange,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Card(
                  elevation: 2.0,
                  child: ListTile(
                    leading: Icon(
                      Icons.group,
                      color: Colors.orange,
                    ),
                    title: Text(
                      'Add Members',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.orange,
                      ),
                    ),
                    onTap: () {
                      _showAddMemberDialog(
                        taskId,
                      );
                    },
                  ),
                ),
                Card(
                  child: Row(
                    children: addedMembers.map((member) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            member[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Card(
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
                              fontSize: 18.0,
                              color: Colors.orange,
                            ),
                          ),
                          subtitle: startDate != null
                              ? Text(
                                  '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 15.0,
                                  ),
                                )
                              : null,
                          onTap: () {
                            _selectStartDate();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Card(
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
                              fontSize: 18.0,
                              color: Colors.orange,
                            ),
                          ),
                          subtitle: endDate != null
                              ? Text(
                                  '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 15.0,
                                  ),
                                )
                              : null,
                          onTap: () {
                            _selectEndDate();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  elevation: 2.0,
                  color: Colors.orange,
                  child: ListTile(
                    leading: Icon(
                      Icons.timer,
                      color: Colors.white,
                    ),
                    title: Text(
                      'Remaining Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      _calculateRemainingTime(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      if (_validateFields()) {
                        // Show loading indicator
                        setState(() {
                          isLoading = true;
                        });

                        await _addTaskToFirestore(widget.projectName);

                        // Hide loading indicator
                        setState(() {
                          isLoading = false;
                        });

                        // Navigate to the next screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskScreen(projectName: widget.projectName),
                          ),
                        );
                      } else {
                        print('Please fill in all required fields');
                      }
                    } catch (e) {
                      print('Error adding task: $e');

                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.orange),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          "Add Task",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to format elapsed time
  String _formatElapsedTime() {
    final days = _elapsedTimeInSeconds ~/ 86400;
    final hours = (_elapsedTimeInSeconds % 86400) ~/ 3600;
    final minutes = (_elapsedTimeInSeconds % 3600) ~/ 60;
    final seconds = _elapsedTimeInSeconds % 60;
    return '$days days $hours hours $minutes minutes $seconds seconds';
  }

  // Helper function to calculate remaining time
  String _calculateRemainingTime() {
    if (startDate == null || endDate == null) {
      return 'Select start and end dates';
    }

    final remainingTimeInSeconds =
        endDate!.difference(DateTime.now()).inSeconds;
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
}
