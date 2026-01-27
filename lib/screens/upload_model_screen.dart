import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:panchayat_mitra/data/model_questions.dart';
import 'package:panchayat_mitra/data/model_questions_part1.dart';
import 'package:panchayat_mitra/data/model_questions_part2.dart';
import 'package:panchayat_mitra/data/model_questions_part3.dart';
import 'package:panchayat_mitra/widgets/location_selector.dart';
import 'package:path_provider/path_provider.dart';

class QuestionAnswer {
  String? answer;
  List<XFile> images = [];
  List<String> imageUrls = [];

  QuestionAnswer({this.answer});
}

class UploadModelScreen extends StatefulWidget {
  const UploadModelScreen({super.key});

  @override
  State<UploadModelScreen> createState() => _UploadModelScreenState();
}

class _UploadModelScreenState extends State<UploadModelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<QuestionAnswer> _answers = List.generate(
    modelQuestions.length,
    (_) => QuestionAnswer(),
  );
  bool _isLoading = false;
  String? _selectedBlock;
  String? _selectedPanchayat;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = userDoc.data();
        _selectedBlock = _userData?['block'];
        _selectedPanchayat = _userData?['panchayat'];
      });
    }
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

  Future<void> _uploadAnswers() async {
    if (_selectedBlock == null || _selectedPanchayat == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }

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

      await FirebaseFirestore.instance.collection('model_answers').add({
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
      ).showSnackBar(SnackBar(content: Text('Failed to upload answers: $e')));
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
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      if (kIsWeb) {
        final imageBytes = await image.readAsBytes();
        if (imageBytes.length > 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image exceeds the 1 MB size limit.')),
          );
        } else {
          setState(() {
            _answers[index].images.add(image);
          });
        }
      } else {
        final dir = await getTemporaryDirectory();
        final targetPath =
            '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        final result = await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          quality: 80,
        );

        if (result != null) {
          final imageBytes = await result.readAsBytes();
          if (imageBytes.length > 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${result.name} exceeds the 1 MB size limit after compression.',
                ),
              ),
            );
          } else {
            setState(() {
              _answers[index].images.add(XFile(result.path));
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 20.0),
          child: Text('Model Questionnaire'),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
          Padding(
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
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _uploadAnswers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ],
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
              const SizedBox(height: 20),
              if (_userData != null)
                LocationSelector(
                  initialBlock: _userData!['block'],
                  initialPanchayat: _userData!['panchayat'],
                  onLocationChanged: (block, panchayat) {
                    setState(() {
                      _selectedBlock = block;
                      _selectedPanchayat = panchayat;
                    });
                  },
                  isEnabled: false,
                ),
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
                        (overallIndex == 30 &&
                            _answers[overallIndex].answer ==
                                modelQuestions[overallIndex].options[0]) ||
                        (overallIndex == 31 &&
                            (modelQuestions[overallIndex].options.isNotEmpty &&
                                    _answers[overallIndex].answer ==
                                        modelQuestions[overallIndex]
                                            .options[0] ||
                                modelQuestions[overallIndex].options.length >
                                        1 &&
                                    _answers[overallIndex].answer ==
                                        modelQuestions[overallIndex]
                                            .options[1] ||
                                modelQuestions[overallIndex].options.length >
                                        2 &&
                                    _answers[overallIndex].answer ==
                                        modelQuestions[overallIndex]
                                            .options[2] ||
                                modelQuestions[overallIndex].options.length >
                                        3 &&
                                    _answers[overallIndex].answer ==
                                        modelQuestions[overallIndex]
                                            .options[3])) ||
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
                                ..._answers[overallIndex].imageUrls.map(
                                  (url) => Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                ..._answers[overallIndex].images.map((file) {
                                  return Stack(
                                    children: [
                                      FutureBuilder<Uint8List>(
                                        future: file.readAsBytes(),
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
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _answers[overallIndex].images
                                                  .remove(file);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
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
