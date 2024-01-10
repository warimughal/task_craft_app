// ignore_for_file: file_names, prefer_const_constructors, avoid_unnecessary_containers, unnecessary_null_comparison, unused_local_variable, avoid_print, use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors_in_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:get_time_ago/get_time_ago.dart';

import 'package:task_craft_app/home/homeScreen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  User? userId = FirebaseAuth.instance.currentUser;
  void _showEditNoteDialog(BuildContext context, String docId, String note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit Note",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: EditNoteDialogContent(docId: docId, initialNote: note),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Personal Notes",
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
      body: Container(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("notes")
              .where("userId", isEqualTo: userId?.uid)
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text(
                "Something went wrong",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                  child: Text(
                "No Data Found,",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ));
            }
            if (snapshot != null && snapshot.data != null) {
              return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var note = snapshot.data!.docs[index]['note'];
                    var noteId = snapshot.data!.docs[index]['userId'];
                    var docId = snapshot.data!.docs[index].id;
                    Timestamp date = snapshot.data!.docs[index]['CreatedAt'];
                    var finalDate = DateTime.parse(date.toDate().toString());
                    return Card(
                      child: ListTile(
                        title: Text(
                          note,
                          style: TextStyle(color: Colors.orange),
                        ),
                        // subtitle: Text(noteId),
                        subtitle: Text(
                          GetTimeAgo.parse(
                            finalDate,
                          ),
                          style: TextStyle(color: Colors.orange),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                                onTap: () {
                                  _showEditNoteDialog(context, docId, note);
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                )),
                            SizedBox(
                              width: 5.0,
                            ),
                            GestureDetector(
                                onTap: () async {
                                  await FirebaseFirestore.instance
                                      .collection("notes")
                                      .doc(docId)
                                      .delete();
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.orange,
                                )),
                          ],
                        ),
                      ),
                    );
                  });
            }
            return Container();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateNoteDialog(context);
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

  void _showCreateNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Create Note",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: CreateNoteDialogContent(),
        );
      },
    );
  }
}

class CreateNoteDialogContent extends StatefulWidget {
  @override
  _CreateNoteDialogContentState createState() =>
      _CreateNoteDialogContentState();
}

class _CreateNoteDialogContentState extends State<CreateNoteDialogContent> {
  TextEditingController createNoteController = TextEditingController();
  User? userId = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: createNoteController,
          maxLines: null,
          decoration: InputDecoration(
            label: Text(
              "Add Note",
              style:
                  TextStyle(fontWeight: FontWeight.w900, color: Colors.orange),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () async {
            var note = createNoteController.text.trim();

            if (note.isNotEmpty) {
              try {
                await FirebaseFirestore.instance.collection("notes").add({
                  'CreatedAt': DateTime.now(),
                  'note': note,
                  'userId': userId?.uid,
                });

                // Close the dialog
                Navigator.of(context).pop();
              } on FirebaseAuthException catch (e) {
                print("Firebase Authentication Error: $e");
              } catch (e) {
                print("Error: $e");
              }
            } else {
              print("Note cannot be empty");
            }
          },
          child: Text(
            "Add Note",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    createNoteController.dispose();
    super.dispose();
  }
}

class EditNoteDialogContent extends StatefulWidget {
  final String docId;
  final String initialNote;

  EditNoteDialogContent({
    required this.docId,
    required this.initialNote,
  });

  @override
  _EditNoteDialogContentState createState() => _EditNoteDialogContentState();
}

class _EditNoteDialogContentState extends State<EditNoteDialogContent> {
  TextEditingController editNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    editNoteController.text = widget.initialNote;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: editNoteController,
          maxLines: null,
          decoration: InputDecoration(
            label: Text(
              "Edit Note",
              style:
                  TextStyle(fontWeight: FontWeight.w900, color: Colors.orange),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () async {
            var editedNote = editNoteController.text.trim();

            if (editedNote.isNotEmpty) {
              try {
                await FirebaseFirestore.instance
                    .collection("notes")
                    .doc(widget.docId)
                    .update({
                  'note': editedNote,
                });

                // Close the dialog
                Navigator.of(context).pop();
              } catch (e) {
                print("Error updating note: $e");
              }
            } else {
              print("Note cannot be empty");
            }
          },
          child: Text(
            "Save Changes",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    editNoteController.dispose();
    super.dispose();
  }
}
