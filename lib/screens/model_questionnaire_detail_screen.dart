import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/model_questions_part1.dart';
import 'package:panchayat_mitra/data/model_questions_part2.dart';
import 'package:panchayat_mitra/data/model_questions_part3.dart';
import 'package:panchayat_mitra/screens/image_view_screen.dart';
import 'package:panchayat_mitra/data/model_questions.dart';

class ModelQuestionnaireDetailScreen extends StatelessWidget {
  final String documentId;

  const ModelQuestionnaireDetailScreen({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Questionnaire Details'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Part 1'),
              Tab(text: 'Part 2'),
              Tab(text: 'Part 3'),
            ],
          ),
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('model_answers')
              .doc(documentId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Data not found.'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final answers = data['answers'] as List<dynamic>?;

            return TabBarView(
              children: [
                _buildQuestionList(
                  context,
                  modelQuestionsPart1,
                  answers,
                  0,
                  data,
                ),
                _buildQuestionList(
                  context,
                  modelQuestionsPart2,
                  answers,
                  modelQuestionsPart1.length,
                  data,
                ),
                _buildQuestionList(
                  context,
                  modelQuestionsPart3,
                  answers,
                  modelQuestionsPart1.length + modelQuestionsPart2.length,
                  data,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestionList(
    BuildContext context,
    List<Question> questions,
    List<dynamic>? answers,
    int offset,
    Map<String, dynamic> data,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (offset == 0) ...[
              Text(
                'Block: ${data['block'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Panchayat: ${data['panchayat'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final overallIndex = offset + index;
                final answerData =
                    (answers != null && overallIndex < answers.length)
                    ? answers[overallIndex]
                    : null;

                String? answer;
                List<String> imageUrls = [];

                if (answerData is Map<String, dynamic>) {
                  final rawAnswer = answerData['answer'];
                  if (rawAnswer is bool) {
                    answer = rawAnswer ? 'हाँ' : 'नहीं';
                  } else {
                    answer = rawAnswer as String?;
                  }
                  imageUrls = List<String>.from(answerData['imageUrls'] ?? []);
                } else if (answerData is String) {
                  answer = answerData;
                } else if (answerData is bool) {
                  answer = answerData ? 'हाँ' : 'नहीं';
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        '${overallIndex + 1}. ${questions[index].questionText}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                      child: Text(
                        answer ?? 'Not Answered',
                        style: TextStyle(
                          fontSize: 16,
                          color: answer == null
                              ? Colors.grey
                              : (answer == 'हाँ'
                                    ? Colors.green
                                    : (answer == 'नहीं'
                                          ? Colors.red
                                          : Colors.black)),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (imageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: imageUrls
                              .map(
                                (url) => GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ImageViewScreen(imageUrl: url),
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (
                                          BuildContext context,
                                          Widget child,
                                          ImageChunkEvent? loadingProgress,
                                        ) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    const Divider(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
