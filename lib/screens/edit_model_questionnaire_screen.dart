import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:panchayat_mitra/data/model_questions.dart';
import 'package:panchayat_mitra/data/model_questions_part1.dart';
import 'package:panchayat_mitra/data/model_questions_part2.dart';
import 'package:panchayat_mitra/data/model_questions_part3.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';

class QuestionAnswer {
  String? answer;
  List<XFile> images = [];
  List<String> imageUrls = [];
  TextEditingController textController = TextEditingController();

  QuestionAnswer({this.answer});
}

class EditModelQuestionnaireScreen extends StatefulWidget {
  final String documentId;

  const EditModelQuestionnaireScreen({super.key, required this.documentId});

  @override
  State<EditModelQuestionnaireScreen> createState() =>
      _EditModelQuestionnaireScreenState();
}

class _EditModelQuestionnaireScreenState
    extends State<EditModelQuestionnaireScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<QuestionAnswer> _answers = List.generate(
    modelQuestions.length,
    (_) => QuestionAnswer(),
  );
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchQuestionnaireData();
  }

  Future<void> _fetchQuestionnaireData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('model_answers')
          .doc(widget.documentId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          final answersData = data['answers'] as List<dynamic>?;
          if (answersData != null) {
            for (int i = 0; i < _answers.length; i++) {
              if (i < answersData.length) {
                final answerMap = answersData[i] as Map<String, dynamic>;
                _answers[i].answer = answerMap['answer'] as String?;
                _answers[i].imageUrls = List<String>.from(
                  answerMap['imageUrls'] ?? [],
                );
                if (modelQuestions[i].type == 'number') {
                  _answers[i].textController.text = _answers[i].answer ?? '';
                }
              }
            }
          }
          _selectedBlock = data['block'] as String?;
          _selectedPanchayat = data['panchayat'] as String?;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching questionnaire data: $e');
      print(stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch data: $e')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var answer in _answers) {
      answer.textController.dispose();
    }
    super.dispose();
  }

  double get _percentage {
    int count = 0;
    final totalQuestionsForPercentage = modelQuestions.length - 2;

    for (int i = 0; i < modelQuestions.length; i++) {
      // Exclude questions 33 (index 32) and 49 (index 48)
      if (i == 32 || i == 48) {
        continue;
      }

      // Check if the first option is selected for multiple choice questions
      if (modelQuestions[i].options.isNotEmpty &&
          _answers[i].answer == modelQuestions[i].options[0]) {
        count++;
      }
    }

    if (totalQuestionsForPercentage <= 0) {
      return 0.0;
    }

    return (count / totalQuestionsForPercentage) * 100;
  }

  Color get _percentageColor {
    if (_percentage < 25) {
      return Colors.red;
    } else if (_percentage < 50) {
      return Colors.orange;
    } else if (_percentage < 75) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  Future<void> _updateAnswers() async {
    for (int i = 0; i < _answers.length; i++) {
      final answer = _answers[i];
      final question = modelQuestions[i];

      final canUploadPhoto =
          (answer.answer == 'हाँ' ||
          (i == 30 && answer.answer == question.options[0]) ||
          (i == 31 &&
              (question.options.isNotEmpty &&
                  answer.answer == question.options[0])) ||
          (i >= 33 &&
              i <= 59 &&
              i != 48 &&
              answer.answer == question.options[0]) ||
          (i >= 60 &&
              i <= 82 &&
              (answer.answer == question.options[0] ||
                  answer.answer == question.options[1])));

      if (canUploadPhoto &&
          (answer.images.length + answer.imageUrls.length) != 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please upload exactly 2 photos for question ${i + 1}',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      for (int i = 0; i < _answers.length; i++) {
        final answer = _answers[i];
        final question = modelQuestions[i];

        final canUploadPhoto =
            (answer.answer == 'हाँ' ||
            (i == 30 && answer.answer == question.options[0]) ||
            (i == 31 &&
                (question.options.isNotEmpty &&
                    answer.answer == question.options[0])) ||
            (i >= 33 &&
                i <= 59 &&
                i != 48 &&
                answer.answer == question.options[0]) ||
            (i >= 60 &&
                i <= 82 &&
                (answer.answer == question.options[0] ||
                    answer.answer == question.options[1])));

        if (canUploadPhoto && answer.images.isNotEmpty) {
          for (var imageFile in answer.images) {
            final storageRef = FirebaseStorage.instance.ref().child(
              'model_questionnaire_images/${DateTime.now().toIso8601String()}-${imageFile.name}',
            );
            UploadTask uploadTask;
            if (kIsWeb) {
              uploadTask = storageRef.putData(await imageFile.readAsBytes());
            } else {
              uploadTask = storageRef.putFile(File(imageFile.path));
            }
            final snapshot = await uploadTask;
            final downloadUrl = await snapshot.ref.getDownloadURL();
            answer.imageUrls.add(downloadUrl);
          }
          answer.images.clear();
        }
      }

      await FirebaseFirestore.instance
          .collection('model_answers')
          .doc(widget.documentId)
          .update({
            'answers': _answers
                .map((a) => {'answer': a.answer, 'imageUrls': a.imageUrls})
                .toList(),
            'percentage': _percentage,
            'block': _selectedBlock,
            'panchayat': _selectedPanchayat,
          });

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update answers: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    if (_answers[index].images.length + _answers[index].imageUrls.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only upload up to 2 images')),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      final imageBytes = await image.readAsBytes();
      if (imageBytes.length > 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${image.name} exceeds the 1 MB size limit.')),
        );
      } else {
        setState(() {
          _answers[index].images.add(image);
        });
      }
    }
  }

  void _removeImage(int questionIndex, int imageIndex) {
    setState(() {
      _answers[questionIndex].images.removeAt(imageIndex);
    });
  }

  void _removeImageUrl(int questionIndex, int imageUrlIndex) {
    setState(() {
      _answers[questionIndex].imageUrls.removeAt(imageUrlIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Model Questionnaire'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Part 1'),
            Tab(text: 'Part 2'),
            Tab(text: 'Part 3'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuestionList(modelQuestionsPart1, 0),
                _buildQuestionList(
                  modelQuestionsPart2,
                  modelQuestionsPart1.length,
                ),
                _buildQuestionList(
                  modelQuestionsPart3,
                  modelQuestionsPart1.length + modelQuestionsPart2.length,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${_percentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _percentageColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateAnswers,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text('Update'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList(List<Question> questions, int offset) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (offset == 0) ...[
              Text('Block: $_selectedBlock'),
              const SizedBox(height: 8),
              Text('Panchayat: $_selectedPanchayat'),
              const SizedBox(height: 16),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final overallIndex = offset + index;
                final question = questions[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                        '${overallIndex + 1}. ${question.questionText}',
                      ),
                    ),
                    if (question.type == 'multiple_choice')
                      Wrap(
                        spacing: 8.0,
                        children: question.options.map((option) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Radio<String>(
                                value: option,
                                groupValue: _answers[overallIndex].answer,
                                onChanged: (value) {
                                  setState(() {
                                    _answers[overallIndex].answer = value;
                                  });
                                },
                              ),
                              Text(option),
                            ],
                          );
                        }).toList(),
                      )
                    else if (question.type == 'number')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _answers[overallIndex].textController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'संख्या दर्ज करें',
                          ),
                          onChanged: (value) {
                            _answers[overallIndex].answer = value;
                          },
                        ),
                      ),
                    if (_answers[overallIndex].answer == 'हाँ' ||
                        (overallIndex >= 33 &&
                            overallIndex <= 59 &&
                            overallIndex != 48 &&
                            _answers[overallIndex].answer ==
                                modelQuestions[overallIndex].options[0]) ||
                        (overallIndex >= 60 &&
                            overallIndex <= 82 &&
                            (_answers[overallIndex].answer ==
                                    modelQuestions[overallIndex].options[0] ||
                                _answers[overallIndex].answer ==
                                    modelQuestions[overallIndex].options[1])))
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (kIsWeb)
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(
                                  overallIndex,
                                  ImageSource.gallery,
                                ),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              )
                            else
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(
                                      overallIndex,
                                      ImageSource.camera,
                                    ),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(
                                      overallIndex,
                                      ImageSource.gallery,
                                    ),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                ..._answers[overallIndex].imageUrls
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Stack(
                                        children: [
                                          Image.network(
                                            entry.value,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => _removeImageUrl(
                                                overallIndex,
                                                entry.key,
                                              ),
                                              child: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ..._answers[overallIndex].images
                                    .asMap()
                                    .entries
                                    .map(
                                      (entry) => Stack(
                                        children: [
                                          FutureBuilder<Uint8List>(
                                            future: entry.value.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return Image.memory(
                                                  snapshot.data!,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                );
                                              }
                                              return const CircularProgressIndicator();
                                            },
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(
                                                overallIndex,
                                                entry.key,
                                              ),
                                              child: const Icon(
                                                Icons.cancel,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ],
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
