// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:easy_pdf_viewer/easy_pdf_viewer.dart';

class PDFViewerScreen extends StatelessWidget {
  final PDFDocument document;

  const PDFViewerScreen({Key? key, required this.document}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'PDF Viewer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange,
        ),
        body: Center(
            child: PDFViewer(
          document: document,
          lazyLoad: false,
          zoomSteps: 1,
          numberPickerConfirmWidget: const Text(
            "Confirm",
          ),
        )));
  }
}
