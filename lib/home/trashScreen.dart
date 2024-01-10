// ignore_for_file: use_key_in_widget_constructors, file_names, prefer_final_fields, library_private_types_in_public_api, prefer_const_constructors, avoid_print, unused_element, prefer_const_literals_to_create_immutables, avoid_function_literals_in_foreach_calls

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_craft_app/home/homeScreen.dart';

class TrashScreen extends StatefulWidget {
  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> deletedProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchDeletedProjects();
  }

  Future<void> _fetchDeletedProjects() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection("trash")
            .where('userId', isEqualTo: user.uid)
            .get();

        setState(() {
          deletedProjects = querySnapshot.docs
              .map((doc) => doc["projectName"] as String)
              .toList();
        });

        print("Deleted Projects: $deletedProjects");
      }
    } catch (e) {
      print("Error fetching deleted projects: $e");
    }
  }

  //long press
  void _showContextMenu(int index) {
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
                      Icons.delete_forever,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Permanently Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                _permanentlyDeleteProject(deletedProjects[index]);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _permanentlyDeleteProject(String projectName) async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      await _firestore
          .collection("trash")
          .where('userId', isEqualTo: user!.uid)
          .where('projectName', isEqualTo: projectName)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete();
        });
      });

      setState(() {
        deletedProjects.remove(projectName);
      });

      print('Project permanently deleted successfully.');
    } catch (e) {
      print('Error permanently deleting project: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trash",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => HomeScreen()));
          },
        ),
      ),
      body: Column(
        children: [
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Deleted Projects",
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: deletedProjects.length,
              itemBuilder: (BuildContext context, int index) {
                return GestureDetector(
                  onLongPress: () {
                    _showContextMenu(index);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          deletedProjects[index],
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
    );
  }
}
