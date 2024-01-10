// ignore_for_file: file_names, library_private_types_in_public_api, prefer_const_constructors, avoid_unnecessary_containers, prefer_const_literals_to_create_immutables, override_on_non_overriding_member, unused_element, prefer_final_fields, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:task_craft_app/home/addtoTaskScreen.dart';
import 'package:task_craft_app/home/homeScreen.dart';
import 'package:task_craft_app/home/taskDetails.dart';

class TaskScreen extends StatefulWidget {
  final String projectName;

  const TaskScreen({Key? key, required this.projectName}) : super(key: key);

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<String> projects = [];
  @override
  void _navigateToAddTaskScreen() async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AddToTaskScreen(projectName: widget.projectName),
        ));

    if (result != null && result is String) {
      setState(() {
        projects.add(result);
      });
    }
  }

  //Fetch Tasks
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("tasks")
          .where('userId', isEqualTo: user!.uid)
          .where('projectName', isEqualTo: widget.projectName)
          .get();

      setState(() {
        projects =
            querySnapshot.docs.map((doc) => doc["taskName"] as String).toList();
      });
    } catch (e) {
      print("Error fetching projects: $e");
    }
  }

// Long Press function
  void _showContextMenu(String projectName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      'Delete Task',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        centerTitle: true,
        title: Text(
          widget.projectName,
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          },
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
                "Project Tasks",
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailsScreen(
                          taskName: projects[index],
                        ),
                      ),
                    );
                  },
                  // onLongPress: () {
                  //   _showContextMenu(projects[index]);
                  // },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddTaskScreen();
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
