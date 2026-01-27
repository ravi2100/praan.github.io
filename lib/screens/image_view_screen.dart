import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(imageUrl))) {
                await launchUrl(Uri.parse(imageUrl));
              }
            },
          ),
        ],
      ),
      body: Center(child: Image.network(imageUrl)),
    );
  }
}
