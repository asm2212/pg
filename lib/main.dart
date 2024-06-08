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
      });
    }
  }

  bool imageConstraints(File image) {
    final validExtensions = ['jpg', 'jpeg', 'bmp'];

    if (!validExtensions.contains(image.path.split('.').last.toLowerCase())) {
      _showAlertDialog(
        title: "Error Uploading!",
        content: "Image format should be jpg/jpeg/bmp.",
      );
      return false;
    }

    if (image.lengthSync() > 100000) {
      _showAlertDialog(
        title: "Error Uploading!",
        content: "Image Size should be less than 100KB.",
      );
      return false;
    }

    return true;
  }

  void _showAlertDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  Future<void> _uploadImage() async {
    if (_image == null) {
      _showAlertDialog(
        title: "Error Uploading!",
        content: "No Image was selected.",
      );
      return;
    }

    setState(() {
      _uploading = true;
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
        _showAlertDialog(
          title: "Image Sent!",
          content: result['message'],
        );
      } else {
        _showAlertDialog(
          title: "Error Uploading!",
          content: "Server Side Error.",
        );
      }
    } catch (e) {
      _showAlertDialog(
        title: "Error Uploading!",
        content: "An error occurred: $e",
      );
    }

    setState(() {
      _uploading = false;
    });
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
          child: _uploading
              ? CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _getImage(ImageSource.camera);
                      },
                      child: CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 6,
                        backgroundColor: Colors.grey,
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : AssetImage('assets/camera_img.png') as ImageProvider,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        bottomPickerSheet(context, _getImage, _getImageFromGallery);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate),
                            SizedBox(width: 5),
                            Text('Select Image'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _uploadImage,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.file_upload),
                            SizedBox(width: 5),
                            Text('Upload Image'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

void bottomPickerSheet(BuildContext context, Function _imageFromCamera,
    Function _imageFromGallery) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
            child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera),
              title: Text('Camera'),
              onTap: () {
                _imageFromCamera();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () {
                _imageFromGallery();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.image),
              title: Text('Local Machine'),
              onTap: () {
                // Implement selecting image from local machine
                Navigator.pop(context);
              },
            ),
          ],
        ));
      });
}

Future<void> _getImageFromGallery() async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
  if (pickedFile == null) {
    print('No image selected.');
    return;
  }

  final File file = File(pickedFile.path);
  // You can handle the picked image file here
}
