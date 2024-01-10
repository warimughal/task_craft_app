// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, unused_field, avoid_print, non_constant_identifier_names, unused_element, sized_box_for_whitespace, unused_local_variable, unnecessary_null_comparison, use_build_context_synchronously, unnecessary_string_interpolations, unnecessary_brace_in_string_interps
import 'dart:convert';
import 'dart:io';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:file_picker/file_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_craft_app/FCM%20Notifications/notification_services.dart';
import 'package:task_craft_app/home/pdfviewerscreen.dart';

class CommentsScreen extends StatefulWidget {
  final String taskName;

  const CommentsScreen({Key? key, required this.taskName}) : super(key: key);

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  NotificationServices notificationServices = NotificationServices();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isSendingComment = false;
  bool isLoading = false;
  bool isPdfLoading = false;
  // save comments
  TextEditingController commentController = TextEditingController();
  List<String> comments = [];
  File? selectedImage;

  Map<String, String> usersData = {};

  String? pdfDownloadLink;

  @override
  void initState() {
    super.initState();

    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);

    notificationServices.isTokenRefresh();
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

  Future<List<dynamic>> _fetchMembers(String taskName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection("tasks")
          .where('taskName', isEqualTo: taskName)
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

  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      Reference storageReference =
          FirebaseStorage.instance.ref().child('images/$fileName');

      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await storageReference.getDownloadURL();
        return downloadUrl;
      } else {
        print('Image upload failed');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
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
      selectedImage = File(pickedImage.path);
    });

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
          FirebaseFirestore.instance.collection('comments');

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

  // Function to fetch download link of PDF from Firestore
  Future<String?> _fetchPdfDownloadLink(String pdfFileName) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
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

  void _showFilesAndImagesDialog(String imageUrl, String pdfFileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isContentLoaded = false;

            Future<void> loadImageAndPdf() async {
              setState(() {
                isContentLoaded = true;
              });
            }

            // Load content
            loadImageAndPdf();

            return AlertDialog(
              title: Text(
                'Files and Images',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.orange,
                  fontSize: 20,
                ),
              ),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                if (imageUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _showImageDialog(imageUrl);
                    },
                    child: Image.network(
                      imageUrl,
                      height: 100,
                      width: 100,
                    ),
                  ),
                if (pdfFileName.isNotEmpty) ...[
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isPdfLoading = true;
                      });

                      String? pdfDownloadLink =
                          await _fetchPdfDownloadLink(pdfFileName);

                      if (pdfDownloadLink != null) {
                        _openPdfView(pdfDownloadLink);
                      }

                      setState(() {
                        isPdfLoading = false;
                      });
                    },
                    child: Card(
                      elevation: 2.0,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: isPdfLoading
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 13.0,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '${pdfFileName}',
                                      style: TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ]
              ]),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Function to open the PDF view screen
  Future<void> _openPdfView(String pdfDownloadLink) async {
    setState(() {
      isLoading = true;
    });

    try {
      PDFDocument doc = await PDFDocument.fromURL(pdfDownloadLink);

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

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.network(
            imageUrl,
            width: 100,
            height: 300,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  User? user = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getCommentsStream() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskName)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> _saveComment() async {
    try {
      setState(() {
        isSendingComment = true;
      });

      User? user = FirebaseAuth.instance.currentUser;
      String commentText = commentController.text;

      if (commentText.isNotEmpty) {
        String userId = user?.uid ?? '';

        // Fetch members from the "tasks" collection
        List<dynamic> members = await _fetchMembers(widget.taskName);

        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        String userName = userSnapshot['userName'] ?? '';
        String imageUrl = selectedImage != null
            ? await uploadImageToFirebase(selectedImage!) ?? ''
            : '';

        // Save the comment
        DocumentReference commentReference = await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.taskName)
            .collection('comments')
            .add({
          'text': commentText,
          'userId': userId,
          'userName': userName,
          'imageUrl': imageUrl,
          'pdfFileName': pdfFileName,
          'members': members,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Fetch the comment ID
        String commentId = commentReference.id;

        setState(() {
          selectedImage = null;
          pdfFileName = null;
        });

        // Send notifications to members
        for (var memberEmail in members) {
          String? userToken = usersData[memberEmail];

          if (userToken != null) {
            var data = {
              'to': userToken,
              'priority': 'high',
              'notification': {
                'title': '$userName added a new Comment on ${widget.taskName}',
                'body': '$commentText',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
              'data': {
                'type': 'comment',
                'commentId': commentId,
              }
            };

            await http.post(
              Uri.parse('https://fcm.googleapis.com/fcm/send'),
              body: jsonEncode(data),
              headers: {
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization':
                    'key=AAAAH76YJM4:APA91bFpjX_UmY9Gdud6nzYFgk6qWid9u216VWZ64YS4m51mY2H8UalGfNMdo8V5KIA4wl1bdAFaTlj8WgjX3VTsC15uPZbatRSGKr2UNbl2y0pas7WYYkkdyrkAUmfRfI31Iwgyi9yB',
              },
            );
          }
        }
        setState(() {
          commentController.text = '';
        });
      } else {
        // Show an error dialog if the comment is empty
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Empty Comment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              content: Text(
                'Please enter a comment before submitting.',
                style: TextStyle(color: Colors.orange),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

      setState(() {
        isSendingComment = false;
      });
    } catch (e) {
      print("Error saving comment: $e");
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 2.0,
                color: Colors.orange,
                child: Container(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getCommentsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        List<DocumentSnapshot> commentsData =
                            snapshot.data!.docs;
                        print("Number of comments: ${commentsData.length}");

                        return ListView.builder(
                          reverse: true,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: commentsData.length,
                          itemBuilder: (context, index) {
                            var comment = commentsData[index];
                            var commentText = comment['text'];
                            String userName =
                                comment['userName'] ?? 'DefaultUserName';
                            String imageUrl = comment['imageUrl'] ?? '';
                            String pdfFileName = comment['pdfFileName'] ?? '';

                            return Card(
                              child: ListTile(
                                title: Text(
                                  commentText,
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: GestureDetector(
                                  onTap: () {
                                    _showFilesAndImagesDialog(
                                        imageUrl, pdfFileName);
                                  },
                                  child: Text(
                                    "See Files and Images",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Center(
                          child: Text('No comments available.'),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: commentController,
                      decoration: InputDecoration(
                        suffixIcon: isSendingComment
                            ? Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange),
                                ),
                              )
                            : IconButton(
                                icon: Icon(
                                  Icons.send,
                                  color: Colors.orange,
                                ),
                                onPressed: () {
                                  _saveComment();
                                },
                              ),
                        label: Text(
                          "Comments",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.orange,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  GestureDetector(
                      onTap: () {
                        _showAttachmentOptionsDialog();
                      },
                      child: Icon(Icons.attach_file, color: Colors.orange)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
