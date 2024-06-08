import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Uploader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _uploading = false;
  String? _imageUrl;
  String? _errorMessage;

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile == null) {
      print('No image selected.');
      return;
    }

    final File file = File(pickedFile.path);

    if (imageConstraints(file)) {
      setState(() {
        _image = file;
        _errorMessage = null; // Clear error message if any
      });
    }
  }

  bool imageConstraints(File image) {
    final validExtensions = ['jpg', 'jpeg', 'bmp'];

    if (!validExtensions.contains(image.path.split('.').last.toLowerCase())) {
      setState(() {
        _errorMessage = "Image format should be jpg/jpeg/bmp.";
      });
      return false;
    }

    if (image.lengthSync() > 100000) {
      setState(() {
        _errorMessage = "Image Size should be less than 100KB.";
      });
      return false;
    }

    return true;
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      setState(() {
        _errorMessage = "No Image was selected.";
      });
      return;
    }

    setState(() {
      _uploading = true;
      _errorMessage = null; // Clear error message if any
    });

    try {
      final response = await http.post(
        Uri.parse('https://pcc.edu.pk/ws/file_upload.php'),
        body: {
          "image": base64Encode(await _image!.readAsBytes()),
          "name": _image!.path.split('/').last,
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _imageUrl = result['imageUrl'];
          _errorMessage = null; // Clear error message if any
        });
        _showSuccessDialog(result['message']);
      } else {
        setState(() {
          _errorMessage = "Server Side Error.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
      });
    }

    setState(() {
      _uploading = false;
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Image Sent!"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
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
        title: Text('Image Uploader'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 6,
                      backgroundColor: Colors.grey,
                      backgroundImage: FileImage(_image!),
                    )
                  : CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 6,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.camera_alt, size: 50),
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.camera);
                },
                child: Text('Take Photo'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.gallery);
                },
                child: Text('Choose from Gallery'),
              ),
              SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: _uploading
                    ? CircularProgressIndicator()
                    : Text('Upload Image'),
              ),
              SizedBox(height: 20),
              if (_imageUrl != null)
                Image.network(
                  _imageUrl!,
                  height: 200,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
