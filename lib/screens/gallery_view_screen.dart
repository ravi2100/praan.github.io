import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GalleryViewScreen extends StatelessWidget {
  final List<dynamic> imageUrls;
  final int initialIndex;

  const GalleryViewScreen({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              if (await canLaunchUrl(Uri.parse(imageUrls[initialIndex]))) {
                await launchUrl(Uri.parse(imageUrls[initialIndex]));
              }
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Center(child: Image.network(imageUrls[index]));
        },
      ),
    );
  }
}
