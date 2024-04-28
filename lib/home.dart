import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tensorflow/result.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late File _image;
  dynamic _probability = 0;
  String? _result;
  List<String>? _labels;
  late tfl.Interpreter _interpreter;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadModel().then((_) {
      loadLabels().then((loadedLabels) {
        setState(() {
          _labels = loadedLabels;
        });
      });
    });
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  Future<void> loadModel() async {
    try {
      _interpreter = await tfl.Interpreter.fromAsset('assets/model.tflite');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 100, 101, 97),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          const Text(
            'Human Emotion Detection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 50),
          Center(
            child: const SizedBox(
                width: 350,
                child: Column(
                  children: [
                    Icon(
                      Icons.camera_alt,
                      size: 100,
                      color: Colors.white,
                    ),
                    SizedBox(height: 50),
                  ],
                )),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 50),
              ElevatedButton(
                onPressed: () {
                  pickImageFromCamera();
                },
                child: Text('Camera', style: TextStyle(color: Colors.black)),
              ),
              const SizedBox(width: 50),
              ElevatedButton(
                onPressed: () {
                  pickImageFromGallery();
                },
                child: Text('Gallery', style: TextStyle(color: Colors.black)),
              ),
            ],
          )
        ],
      ),
    );
  }

  void pickImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _setImage(File(pickedFile.path));
    }
  }

  void pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _setImage(File(pickedFile.path));
    }
  }

  void _setImage(File file) {
    setState(() {
      _image = file;
    });
    runInference();
  }

  Future<Uint8List> preprocessImage(File imageFile) async {
    // Decode the image to an Image object
    img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

    // Resize the image to the correct size
    img.Image resizedImage =
        img.copyResize(originalImage!, width: 224, height: 224);

    // convert the image in black and white
    // img.Image processedImage = img.grayscale(resizedImage);

    // Convert to a byte buffer in the format suitable for TensorFlow Lite (RGB)
    // The model expects a 4D tensor [1, 224, 224, 3]
    // Flatten the resized image to match this shape
    Uint8List bytes = resizedImage.getBytes();
    return bytes;
  }

  Future<void> runInference() async {
    if (_labels == null) {
      return;
    }

    try {
      Uint8List inputBytes = await preprocessImage(_image);
      var input = inputBytes.buffer.asUint8List().reshape([1, 224, 224, 3]);
      var outputBuffer = List<int>.filled(1 * 5, 0).reshape([1, 5]);

      _interpreter.run(input, outputBuffer);

      // Assuming output is now List<List<int>> after inference
      List<int> output = outputBuffer[0];

      // Print raw output for debugging
      debugPrint('Raw output: $output');

      // Calculate probability
      int maxScore = output.reduce(max);
      _probability = (maxScore / 255.0); // Convert to percentage
      // Get the classification result
      int highestProbIndex = output.indexOf(maxScore);
      String classificationResult = _labels![highestProbIndex];

      setState(() {
        _result = classificationResult;
        // _probability is updated with the calculated probability
      });

      navigateToResult();
    } catch (e) {
      debugPrint('Error during inference: $e');
    }
  }

  Future<List<String>> loadLabels() async {
    final labelsData =
        await DefaultAssetBundle.of(context).loadString('assets/labels.txt');
    return labelsData.split('\n');
  }

  String classifyImage(List<int> output) {
    int highestProbIndex = output.indexOf(output.reduce(max));
    return _labels![highestProbIndex];
  }

  void navigateToResult() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          image: _image,
          result: _result!,
          probability: _probability,
        ),
      ),
    );
  }
}
