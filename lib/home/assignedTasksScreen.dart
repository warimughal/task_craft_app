// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, unused_local_variable, file_names, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:task_craft_app/home/assignedtaskDetailsScreen.dart';

class AssignedTasksScreen extends StatefulWidget {
  final String projectName;

  const AssignedTasksScreen({required this.projectName});

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: true,
        centerTitle: true,
        title: Text(
          '${widget.projectName}',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
      body: FutureBuilder(
        future: _getProjectTasks(),
        builder: (context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks for ${widget.projectName}.'));
          } else {
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var taskName = snapshot.data![index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AssignedTaskDetailsScreen(taskName: taskName),
                      ),
                    );
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
                          taskName,
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

  Future<List<String>> _getProjectTasks() async {
    User? user = FirebaseAuth.instance.currentUser;

    // Query tasks where the project name matches and members include the user's email
    var querySnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('projectName', isEqualTo: widget.projectName)
        .where('members', arrayContains: user?.email)
        .get();

    // Extract task names from the tasks
    var taskNames =
        querySnapshot.docs.map((task) => task['taskName'].toString()).toList();

    return taskNames;
  }
}
