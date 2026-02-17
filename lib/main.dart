import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:smart_thumbnail_generator_engine/logic/smart_thumbnail_generator_engine.dart';
import 'package:smart_thumbnail_generator_engine/models/frame_score.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Thumbnail Generator Engine',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Uint8List> carouselImages = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Smart Thumbnail Generator Engine"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : carouselImages.isEmpty
                ? const Text("No frames loaded yet")
                : SizedBox(
                    height: 400,
                    child: PageView.builder(
                      itemCount: carouselImages.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.memory(
                            carouselImages[index],
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            isLoading = true;
            carouselImages.clear();
          });

          // 1. Run video processing
          List<FrameInfos> topFrames = await SmartThumbnailGeneratorEngine.generateThumbnails(
            videoPath: "", // Your video path here
            topN: 10, // Number of desired thumbnails
          );

          // 2. Convert thumbnails images to Uint8List for Flutter display
          List<Uint8List> imagesBytes = topFrames.map((frameScore) {
            // Encode image.Image to bytes
            return Uint8List.fromList(img.encodeJpg(frameScore.frame.image));
          }).toList();

          // 3. Update carousel images
          setState(() {
            carouselImages = imagesBytes;
            isLoading = false;
          });
        },
        child: const Icon(Icons.video_call_outlined),
      ),
    );
  }
}