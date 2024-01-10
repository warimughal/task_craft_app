// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, override_on_non_overriding_member, annotate_overrides, sort_child_properties_last, sized_box_for_whitespace, prefer_final_fields, avoid_print, unused_local_variable, unused_element, avoid_function_literals_in_foreach_calls, unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:task_craft_app/FCM%20Notifications/notification_services.dart';
import 'package:task_craft_app/home/assignedProjectsScreen.dart';
import 'package:task_craft_app/home/notesScreen.dart';

import 'package:task_craft_app/home/taskScreen.dart';
import 'package:task_craft_app/home/trashScreen.dart';
import 'package:task_craft_app/on_boarding_screen/on_boarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotificationServices notificationServices = NotificationServices();

  List<String> projects = [];
  List<String> addedMembers = [];
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProjects();
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit(context);
    notificationServices.setupInteractMessage(context);

    // notificationServices.isTokenRefresh();
    notificationServices.getDeviceToken().then((value) {
      if (kDebugMode) {
        print('device token');
        print(value);
      }
    });
  }

  // Load User Data
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userSnapshot =
            await _firestore.collection("customers").doc(user.uid).get();

        setState(() {
          userName = userSnapshot['userName'] as String;
          userEmail = userSnapshot['userEmail'] as String;
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    } else {
      print('User is null');
    }
  }

  //load Projects
  Future<void> _loadProjects() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await _firestore
            .collection("projects")
            .where('userId', isEqualTo: user.uid)
            .get();

        List<String> userProjects = querySnapshot.docs
            .map((doc) => doc['projectName'] as String)
            .toList();

        setState(() {
          projects = userProjects;
        });
      } catch (e) {
        print('Error loading projects: $e');
      }
    }
  }

//Navigation screen using GridView
  void _navigateToTaskScreen(String projectName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(projectName: projectName),
      ),
    );
  }

// Add projects
  void _navigateToAddProjectScreen() async {
    String? result = await showDialog(
      context: context,
      builder: (context) {
        String projectName = '';

        return AlertDialog(
          title: Center(
            child: Text(
              'Add Project',
              style:
                  TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
          content: TextField(
            onChanged: (value) {
              projectName = value;
            },
            decoration: InputDecoration(
              label: Text(
                "Project Name",
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Colors.orange),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (projectName.isNotEmpty) {
                  Navigator.of(context).pop(projectName);

                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    try {
                      await _firestore.collection("projects").add({
                        'userId': user.uid,
                        'projectName': projectName,
                      });

                      await _loadProjects();

                      print('Project added to Firestore successfully.');
                    } catch (e) {
                      print('Error adding project to Firestore: $e');
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Center(
                        child: Text(
                          'Project name required',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        projects.add(result);
      });
    }
  }

// Long Press function
  void _showContextMenu(String projectName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              title: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Delete Project',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _deleteProject(projectName);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

// delete project
  void _deleteProject(String projectName) async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      List<Map<String, dynamic>> deletedProjects = [];

      await _firestore
          .collection("projects")
          .where('userId', isEqualTo: user!.uid)
          .where('projectName', isEqualTo: projectName)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          deletedProjects.add(doc.data() as Map<String, dynamic>);
          doc.reference.delete();
        });
      });

      // Move the deleted project data to the "trash" collection
      deletedProjects.forEach((deletedProject) async {
        await _firestore.collection("trash").add(deletedProject);
      });

      setState(() {
        projects.remove(projectName);
      });

      print('Project deleted successfully.');
    } catch (e) {
      print('Error deleting project: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          "Projects",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Center(
            child: Card(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Your Projects",
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            )),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: projects.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onTap: () {
                    _navigateToTaskScreen(projects[index]);
                  },
                  onLongPress: () {
                    _showContextMenu(projects[index]);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          projects[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.orange,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : '',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(
                "Home",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w900),
              ),
              leading: Icon(
                Icons.home,
                color: Colors.orange,
              ),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
            ),
            ListTile(
              title: Text(
                "Notes",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w900),
              ),
              leading: Icon(Icons.notes, color: Colors.orange),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => NotesScreen()));
              },
            ),
            ListTile(
              title: Text(
                "Trash",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w900),
              ),
              leading: Icon(Icons.delete, color: Colors.orange),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => TrashScreen()));
              },
            ),
            ListTile(
              title: Text(
                "Assigned Tasks",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w900,
                ),
              ),
              leading: Icon(
                Icons.assignment,
                color: Colors.orange,
              ),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AssignedProjectScreen()));
              },
            ),
            ListTile(
              title: Text(
                "LogOut",
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.w900),
              ),
              leading: Icon(Icons.logout, color: Colors.orange),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => OnBoardingScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddProjectScreen();
        },
        backgroundColor: Colors.orange,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: Icon(
            Icons.add,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }
}
