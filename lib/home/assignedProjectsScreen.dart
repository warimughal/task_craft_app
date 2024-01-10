// ignore_for_file: file_names, prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_element, avoid_function_literals_in_foreach_calls, unnecessary_cast, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_craft_app/home/assignedTasksScreen.dart';

class AssignedProjectScreen extends StatefulWidget {
  const AssignedProjectScreen({Key? key}) : super(key: key);

  @override
  State<AssignedProjectScreen> createState() => _AssignedProjectScreenState();
}

class _AssignedProjectScreenState extends State<AssignedProjectScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> projects = [];

  Future<List<String>> _getAssignedProjects() async {
    User? user = _auth.currentUser;

    // Query tasks where the current user's email is in the 'members' field
    var querySnapshot = await _firestore
        .collection('tasks')
        .where('members', arrayContains: user?.email)
        .get();

    // Extract unique project names from the tasks
    var projectNames = querySnapshot.docs
        .map((task) => task['projectName'].toString())
        .toSet()
        .toList();

    return projectNames;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          "Assigned Tasks",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder(
        future: _getAssignedProjects(),
        builder: (context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              'No assigned projects.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ));
          } else {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var projectName = snapshot.data![index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignedTasksScreen(projectName: projectName),
                      ),
                    );
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
                          projectName,
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
            );
          }
        },
      ),
    );
  }
}
