import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ===================== DATA MODELS =====================
class Flashcard {
  final String id;
  final String topicId;
  String question;
  String answer;
  String? imageUrl; // For network image
  String? imagePath; // For local gallery image
  bool learned;

  Flashcard({
    required this.id,
    required this.topicId,
    required this.question,
    required this.answer,
    this.imageUrl,
    this.imagePath,
    this.learned = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'topicId': topicId,
    'question': question,
    'answer': answer,
    'imageUrl': imageUrl,
    'imagePath': imagePath,
    'learned': learned,
  };

  static Flashcard fromMap(Map<String, dynamic> map) => Flashcard(
    id: map['id'],
    topicId: map['topicId'],
    question: map['question'],
    answer: map['answer'],
    imageUrl: map['imageUrl'],
    imagePath: map['imagePath'],
    learned: map['learned'] ?? false,
  );
}

class Topic {
  final String id;
  final String categoryId;
  String name;

  Topic({required this.id, required this.categoryId, required this.name});

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'name': name,
  };

  static Topic fromMap(Map<String, dynamic> map) => Topic(
    id: map['id'],
    categoryId: map['categoryId'],
    name: map['name'],
  );
}

class Category {
  final String id;
  String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };

  static Category fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'],
  );
}

// ===================== APP STATE + PERSISTENCE =====================
class AppState extends ChangeNotifier {
  static const _prefsKey = 'fliplearn_state_v2';
  ThemeMode themeMode = ThemeMode.system;
  int quizSeconds = 20;
  int quizCount = 10;
  bool showAnswerAfter = false;

  final Map<String, Category> categories = {};
  final Map<String, Topic> topics = {};
  final Map<String, Flashcard> flashcards = {};

  AppState() {
    _seedIfEmpty();
    load();
  }

  // Seed with a little sample for first run UX
  void _seedIfEmpty() {
    if (categories.isEmpty && topics.isEmpty && flashcards.isEmpty) {
      final catMath = Category(id: _id(), name: 'Math');
      final catHist = Category(id: _id(), name: 'History');
      categories[catMath.id] = catMath;
      categories[catHist.id] = catHist;

      final tAlgebra =
      Topic(id: _id(), categoryId: catMath.id, name: 'Algebra Basics');
      final tWW2 =
      Topic(id: _id(), categoryId: catHist.id, name: 'World War II');
      topics[tAlgebra.id] = tAlgebra;
      topics[tWW2.id] = tWW2;

      final f1 = Flashcard(
        id: _id(),
        topicId: tAlgebra.id,
        question: 'Solve: 2x + 3 = 7',
        answer: 'x = 2',
      );
      final f2 = Flashcard(
        id: _id(),
        topicId: tAlgebra.id,
        question: 'Slope-intercept form of a line?',
        answer: 'y = mx + b',
      );
      final f3 = Flashcard(
        id: _id(),
        topicId: tWW2.id,
        question: 'Start year of World War II?',
        answer: '1939',
      );
      final f4 = Flashcard(
        id: _id(),
        topicId: tWW2.id,
        question: 'What was the code name for the Allied invasion of Normandy on June 6, 1944?',
        answer: 'Operation Overlord',
      );
      final f5 = Flashcard(
        id: _id(),
        topicId: tWW2.id,
        question: 'Who was the Prime Minister of the United Kingdom during most of World War II?',
        answer: 'Winston Churchill',
      );
      final f6 = Flashcard(
        id: _id(),
        topicId: tWW2.id,
        question: 'The surprise military strike by the Imperial Japanese Navy Air Service upon the United States against the naval base at Pearl Harbor occurred in which year?',
        answer: '1941',
      );
      final f7 = Flashcard(
        id: _id(),
        topicId: tWW2.id,
        question: 'What battle is considered a major turning point on the Eastern Front, ending the German advance into the Soviet Union?',
        answer: 'Battle of Stalingrad',
      );

      flashcards[f1.id] = f1;
      flashcards[f2.id] = f2;
      flashcards[f3.id] = f3;
      flashcards[f4.id] = f4;
      flashcards[f5.id] = f5;
      flashcards[f6.id] = f6;
      flashcards[f7.id] = f7;
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'themeMode': themeMode.index,
      'quizSeconds': quizSeconds,
      'quizCount': quizCount,
      'showAnswerAfter': showAnswerAfter,
      'categories': categories.values.map((c) => c.toMap()).toList(),
      'topics': topics.values.map((t) => t.toMap()).toList(),
      'flashcards': flashcards.values.map((f) => f.toMap()).toList(),
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      await save();
      return;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      themeMode =
      ThemeMode.values[(map['themeMode'] ?? ThemeMode.system.index) as int];
      quizSeconds = map['quizSeconds'] as int? ?? 20;
      quizCount = map['quizCount'] as int? ?? 10;
      showAnswerAfter = map['showAnswerAfter'] as bool? ?? false;

      categories.clear();
      topics.clear();
      flashcards.clear();
      for (final c in (map['categories'] as List).cast<Map>()) {
        final cat = Category.fromMap(c.cast<String, dynamic>());
        categories[cat.id] = cat;
      }
      for (final t in (map['topics'] as List).cast<Map>()) {
        final top = Topic.fromMap(t.cast<String, dynamic>());
        topics[top.id] = top;
      }
      for (final f in (map['flashcards'] as List).cast<Map>()) {
        final fc = Flashcard.fromMap(f.cast<String, dynamic>());
        flashcards[fc.id] = fc;
      }
      notifyListeners();
    } catch (_) {
      // Ignore corrupt state
    }
  }

  // --- NEW METHOD FOR CLEARING DATA ---
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    categories.clear();
    topics.clear();
    flashcards.clear();
    _seedIfEmpty(); // Re-seed with initial data
    notifyListeners();
  }
  // --- END OF NEW METHOD ---

  // ---------- CRUD ----------
  String _id() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
          UniqueKey().toString();

  Category addCategory(String name) {
    final cat = Category(id: _id(), name: name.trim());
    categories[cat.id] = cat;
    save();
    notifyListeners();
    return cat;
  }

  Topic addTopic(String categoryId, String name) {
    final top = Topic(id: _id(), categoryId: categoryId, name: name.trim());
    topics[top.id] = top;
    save();
    notifyListeners();
    return top;
  }

  Flashcard addFlashcard({
    required String topicId,
    required String question,
    required String answer,
    String? imageUrl,
    String? imagePath,
  }) {
    final f = Flashcard(
      id: _id(),
      topicId: topicId,
      question: question.trim(),
      answer: answer.trim(),
      imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      imagePath: imagePath,
    );
    flashcards[f.id] = f;
    save();
    notifyListeners();
    return f;
  }

  void toggleLearned(String flashcardId) {
    final f = flashcards[flashcardId];
    if (f != null) {
      f.learned = !f.learned;
      save();
      notifyListeners();
    }
  }

  void updateTheme(ThemeMode mode) {
    themeMode = mode;
    save();
    notifyListeners();
  }

  void updateQuizSeconds(int seconds) {
    quizSeconds = seconds;
    save();
    notifyListeners();
  }

  void updateQuizCount(int count) {
    quizCount = count;
    save();
    notifyListeners();
  }

  void toggleShowAnswerAfter(bool value) {
    showAnswerAfter = value;
    save();
    notifyListeners();
  }

  // ---------- COMPUTED ----------
  List<Topic> topicsByCategory(String categoryId) =>
      topics.values.where((t) => t.categoryId == categoryId).toList();

  List<Flashcard> cardsByTopic(String topicId) =>
      flashcards.values.where((f) => f.topicId == topicId).toList();

  double topicProgress(String topicId) {
    final list = cardsByTopic(topicId);
    if (list.isEmpty) return 0.0;
    final learned = list.where((f) => f.learned).length;
    return learned / list.length;
  }

  double categoryProgress(String categoryId) {
    final t = topicsByCategory(categoryId);
    if (t.isEmpty) return 0.0;
    final vals = t.map((e) => topicProgress(e.id)).toList();
    if (vals.isEmpty) return 0.0;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  List<Topic> inProgressTopics() {
    final all = topics.values.toList();
    all.sort((a, b) => topicProgress(b.id).compareTo(topicProgress(a.id)));
    return all
        .where((t) => cardsByTopic(t.id).isNotEmpty && topicProgress(t.id) < 1.0)
        .toList();
  }
}

// Provide AppState down the tree without external packages
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope(
      {super.key, required AppState notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null,
    'AppStateScope.of() called with no AppStateScope in context');
    return scope!.notifier!;
  }
}

// ===================== MAIN APP =====================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FlipLearnApp());
}

class FlipLearnApp extends StatefulWidget {
  @override
  State<FlipLearnApp> createState() => _FlipLearnAppState();
}

class _FlipLearnAppState extends State<FlipLearnApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final seed = Colors.indigo;
        return AppStateScope(
          notifier: _state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false, // remove debug banner
            title: 'FlipLearn',
            themeMode: _state.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(seedColor: seed),
              useMaterial3: true,
              cardTheme: const CardTheme(
                elevation: 1,
                margin: EdgeInsets.zero,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme:
              ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
              useMaterial3: true,
            ),
            home: const RootScaffold(),
          ),
        );
      },
    );
  }
}

// ===================== ROOT WITH BOTTOM NAV =====================
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0; // 0 Home, 1 Add, 2 Cards, 3 Quiz, 4 Settings

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomePage(),
      const AddPage(),
      const CardsPage(),
      const QuizPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const _HeaderTitle(),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Add'),
          NavigationDestination(
              icon: Icon(Icons.style_outlined),
              selectedIcon: Icon(Icons.style),
              label: 'Cards'),
          NavigationDestination(
              icon: Icon(Icons.quiz_outlined),
              selectedIcon: Icon(Icons.quiz),
              label: 'Quiz'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (r) => LinearGradient(
            colors: [cs.primary, cs.tertiary],
          ).createShader(r),
          child: const Icon(Icons.flash_auto, size: 26, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          'FlipLearn',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

// ===================== HOME =====================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final inProgress = state.inProgressTopics();
    return RefreshIndicator(
      onRefresh: () async => state.load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroPanel(),
          const SizedBox(height: 16),
          _SectionHeader(
              title: 'Recent / In Progress', icon: Icons.play_circle_fill_outlined),
          const SizedBox(height: 12),
          if (inProgress.isEmpty)
            _EmptyCard(
              icon: Icons.hourglass_empty_rounded,
              message:
              'No in-progress topics yet. Add some cards to get started!',
            ),
          ...inProgress.map((t) => _TopicProgressCard(topic: t)),
        ],
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study smarter',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Create cards, track progress, and quiz yourself.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: const [
                  _ChipBadge(icon: Icons.style, label: 'Flashcards'),
                  _ChipBadge(icon: Icons.timeline, label: 'Progress'),
                  _ChipBadge(icon: Icons.quiz, label: 'Quiz Mode'),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.school, size: 56),
        ],
      ),
    );
  }
}

class _ChipBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.primary),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(icon, size: 28, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _TopicProgressCard extends StatelessWidget {
  final Topic topic;
  const _TopicProgressCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cat = state.categories[topic.categoryId]!;
    final progress = state.topicProgress(topic.id);
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TopicFlashcardsPage(topic: topic),
      )),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _RingPercent(percent: progress),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.category, size: 16),
                        const SizedBox(width: 4),
                        Text(cat.name,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color)),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${(progress * 100).toStringAsFixed(0)}% completed',
                          style: const TextStyle(fontSize: 12)),
                    ]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPercent extends StatelessWidget {
  final double percent;
  const _RingPercent({required this.percent});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: percent,
            strokeWidth: 6,
          ),
        ),
        Text('${(percent * 100).toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
      ]),
    );
  }
}

// ===================== ADD =====================
class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  String? _categoryId;
  String? _topicId;

  final _newCategoryCtrl = TextEditingController();
  final _newTopicCtrl = TextEditingController();
  final _questionCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String? _imagePath;

  @override
  void dispose() {
    _newCategoryCtrl.dispose();
    _newTopicCtrl.dispose();
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _categoryId = null;
      _topicId = null;
      _newCategoryCtrl.clear();
      _newTopicCtrl.clear();
      _questionCtrl.clear();
      _answerCtrl.clear();
      _imageUrlCtrl.clear();
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cats = state.categories.values.toList();
    cats.sort((a, b) => a.name.compareTo(b.name));

    final topicsForCategory = _categoryId != null
        ? state.topicsByCategory(_categoryId!)
        .where((t) => state.cardsByTopic(t.id).isNotEmpty)
        .toList()
        : [];
    topicsForCategory.sort((a, b) => a.name.compareTo(b.name));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionHeader(title: 'Add Flashcard', icon: Icons.add_box),
          const SizedBox(height: 16),
          _TipBanner(
            text: 'Choose an existing category/topic, or create a new one.',
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            decoration:
            const InputDecoration(labelText: 'Select Category (optional)'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('— Create new category —')),
              ...cats.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ],
            value: _categoryId,
            onChanged: (v) {
              setState(() {
                _categoryId = v;
                _topicId = null;
              });
            },
          ),
          if (_categoryId == null) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _newCategoryCtrl,
              decoration: const InputDecoration(labelText: 'New Category Name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter category name'
                  : null,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            decoration:
            const InputDecoration(labelText: 'Select Topic (optional)'),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('— Create new topic —')),
              ...topicsForCategory.map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
            ],
            value: _topicId,
            onChanged: (v) {
              setState(() => _topicId = v);
            },
            // Disable if no category is selected, and also if new category is being created
            isDense: false,
            //isExpanded: true,
          ),
          if (_topicId == null) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _newTopicCtrl,
              decoration: const InputDecoration(labelText: 'New Topic Name'),
              validator: (v) {
                if (_topicId == null && (v == null || v.trim().isEmpty)) {
                  return 'Enter topic name';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _questionCtrl,
            decoration: const InputDecoration(
                labelText: 'Question', prefixIcon: Icon(Icons.help_outline)),
            minLines: 1,
            maxLines: 4,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Enter a question' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _answerCtrl,
            decoration: const InputDecoration(
                labelText: 'Answer', prefixIcon: Icon(Icons.check_circle)),
            minLines: 1,
            maxLines: 4,
            validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Enter an answer' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _imageUrlCtrl,
            decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.link_outlined)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            ElevatedButton.icon(
              onPressed: () async {
                final ImagePicker picker = ImagePicker();
                final XFile? x = await picker.pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _imagePath = x.path);
              },
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick from Gallery'),
            ),
            const SizedBox(width: 12),
            if (_imagePath != null)
              Flexible(
                  child: Text('Selected: ${_imagePath!.split('/').last}',
                      overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    final cat = _categoryId != null
                        ? state.categories[_categoryId!]!
                        : state.addCategory(_newCategoryCtrl.text);

                    final topic = _topicId != null
                        ? state.topics[_topicId!]!
                        : state.addTopic(cat.id, _newTopicCtrl.text);

                    state.addFlashcard(
                      topicId: topic.id,
                      question: _questionCtrl.text,
                      answer: _answerCtrl.text,
                      imageUrl: _imageUrlCtrl.text,
                      imagePath: _imagePath,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flashcard added')));
                    _resetForm(); // ✅ reset to clean page after save
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Card'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  final String text;
  const _TipBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(.6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: cs.onSecondaryContainer))),
        ],
      ),
    );
  }
}

// ===================== CARDS (CATEGORIES) =====================
class CardsPage extends StatelessWidget {
  const CardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cats = state.categories.values.toList();
    cats.sort((a, b) => a.name.compareTo(b.name));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Categories', icon: Icons.apps),
        const SizedBox(height: 12),
        ...cats.map((c) => _CategoryCard(category: c)),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final topics = state.topicsByCategory(category.id);
    final progress = state.categoryProgress(category.id);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => TopicsPage(category: category),
      )),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _RingPercent(percent: progress),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${topics.length} topic(s)'),
                    ]),
              ),
              const Icon(Icons.chevron_right)
            ],
          ),
        ),
      ),
    );
  }
}

// ===== Topics page with filters: Completed / In Progress / Not Started
enum TopicFilter { all, completed, inProgress, notStarted }

class TopicsPage extends StatefulWidget {
  final Category category;
  const TopicsPage({super.key, required this.category});

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  TopicFilter filter = TopicFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final all = state.topicsByCategory(widget.category.id);
    all.sort((a, b) => a.name.compareTo(b.name));

    List<Topic> filtered = all.where((t) {
      final p = state.topicProgress(t.id);
      switch (filter) {
        case TopicFilter.completed:
          return p == 1.0 && state.cardsByTopic(t.id).isNotEmpty;
        case TopicFilter.inProgress:
          return p > 0 && p < 1.0;
        case TopicFilter.notStarted:
          return p == 0.0 && state.cardsByTopic(t.id).isNotEmpty;
        case TopicFilter.all:
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Topics',
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                PopupMenuButton<TopicFilter>(
                  initialValue: filter,
                  onSelected: (v) => setState(() => filter = v),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: TopicFilter.all, child: Text('All')),
                    PopupMenuItem(
                        value: TopicFilter.completed, child: Text('Completed')),
                    PopupMenuItem(
                        value: TopicFilter.inProgress, child: Text('In Progress')),
                    PopupMenuItem(
                        value: TopicFilter.notStarted,
                        child: Text('Not Started')),
                  ],
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list),
                      const SizedBox(width: 6),
                      Text(_filterText(filter)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No topics match this filter.'))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = filtered[i];
                final progress = state.topicProgress(t.id);
                return ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  tileColor: Theme.of(context).colorScheme.surfaceVariant,
                  leading: _StatusDot(progress: progress),
                  title: Text(t.name),
                  subtitle: Text(
                      'Progress: ${(progress * 100).toStringAsFixed(0)}%'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TopicFlashcardsPage(topic: t),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _filterText(TopicFilter f) {
    switch (f) {
      case TopicFilter.completed:
        return 'Completed';
      case TopicFilter.inProgress:
        return 'In Progress';
      case TopicFilter.notStarted:
        return 'Not Started';
      case TopicFilter.all:
      default:
        return 'All';
    }
  }
}

class _StatusDot extends StatelessWidget {
  final double progress;
  const _StatusDot({required this.progress});

  @override
  Widget build(BuildContext context) {
    Color c;
    if (progress == 1.0) {
      c = Colors.green;
    } else if (progress == 0.0) {
      c = Colors.orange;
    } else {
      c = Colors.blue;
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

// ===================== TOPIC FLASHCARDS VIEWER =====================
enum CardViewFilter { all, unlearned, learned }

class TopicFlashcardsPage extends StatefulWidget {
  final Topic topic;
  const TopicFlashcardsPage({super.key, required this.topic});

  @override
  State<TopicFlashcardsPage> createState() => _TopicFlashcardsPageState();
}

class _TopicFlashcardsPageState extends State<TopicFlashcardsPage> {
  int index = 0;
  bool showAnswer = false;
  CardViewFilter viewFilter = CardViewFilter.all;

  void _nextCard() {
    setState(() {
      index++;
      showAnswer = false;
    });
  }

  void _previousCard() {
    setState(() {
      index--;
      showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final allCards = state.cardsByTopic(widget.topic.id);
    List<Flashcard> cards = switch (viewFilter) {
      CardViewFilter.all => allCards,
      CardViewFilter.unlearned => allCards.where((c) => !c.learned).toList(),
      CardViewFilter.learned => allCards.where((c) => c.learned).toList(),
    };

    if (index >= cards.length) index = 0;
    if (cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topic.name)),
        body: const Center(
            child: Text(
                'No cards in this view. Try changing the filter or add cards from Add tab.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.topic.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(
            children: [
              Text('Card ${index + 1} of ${cards.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              _FilterPill<CardViewFilter>(
                current: viewFilter,
                onChanged: (v) => setState(() {
                  viewFilter = v;
                  index = 0;
                  showAnswer = false;
                }),
                items: const [
                  (CardViewFilter.all, 'All'),
                  (CardViewFilter.unlearned, 'To Review'),
                  (CardViewFilter.learned, 'Learned'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0 && index > 0) {
                  _previousCard();
                } else if (details.primaryVelocity! < 0 && index < cards.length - 1) {
                  _nextCard();
                }
              },
              child: _FlipCard(
                front: _CardFace(card: cards[index], showAnswer: false),
                back: _CardFace(card: cards[index], showAnswer: true),
                flipped: showAnswer,
                onTap: () {
                  setState(() {
                    showAnswer = !showAnswer;
                    // Automatically mark card as learned when answer is revealed
                    if (showAnswer) {
                      final card = cards[index];
                      if (!card.learned) {
                        state.toggleLearned(card.id);
                      }
                    }
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: index > 0 ? _previousCard : null,
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              FilledButton.icon(
                onPressed: index < cards.length - 1 ? _nextCard : null,
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          )
        ]),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final Flashcard card;
  final bool showAnswer;
  const _CardFace({required this.card, required this.showAnswer});

  @override
  Widget build(BuildContext context) {
    final text = showAnswer ? card.answer : card.question;
    final title = showAnswer ? 'Answer' : 'Question';
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(showAnswer ? Icons.check : Icons.help_outline),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleMedium),
            ]),
            const SizedBox(height: 12),
            if (card.imagePath != null || card.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildImage(card),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap card to flip or swipe to navigate',
                textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(Flashcard c) {
    if (c.imagePath != null && File(c.imagePath!).existsSync()) {
      return Image.file(File(c.imagePath!), height: 180, fit: BoxFit.cover);
    }
    if (c.imageUrl != null && c.imageUrl!.trim().isNotEmpty) {
      return Image.network(c.imageUrl!,
          height: 180,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) {
            return const SizedBox(
                height: 180, child: Center(child: Text('Image failed to load')));
          });
    }
    return const SizedBox.shrink();
  }
}

class _FlipCard extends StatelessWidget {
  final Widget front;
  final Widget back;
  final bool flipped;
  final VoidCallback onTap;
  const _FlipCard(
      {required this.front,
        required this.back,
        required this.flipped,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: flipped ? 1 : 0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final isUnder = (value > 0.5);
          final display = isUnder ? back : front;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value * math.pi),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(isUnder ? math.pi : 0),
              child: display,
            ),
          );
        },
      ),
    );
  }
}

class _FilterPill<T> extends StatelessWidget {
  final T current;
  final void Function(T) onChanged;
  final List<(T, String)> items;
  const _FilterPill(
      {required this.current, required this.onChanged, required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: items.map((it) {
          final selected = it.$1 == current;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(it.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                it.$2,
                style: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===================== QUIZ =====================
class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  String? _categoryId;
  String? _topicId;

  Future<void> _startQuiz(BuildContext context) async {
    // Add a robust check to prevent crash if state is out of sync
    if (_categoryId == null || _topicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category and topic.')),
      );
      return;
    }

    final state = AppStateScope.of(context);
    List<Flashcard> cards;

    if (_topicId == 'all') {
      cards = state
          .topicsByCategory(_categoryId!)
          .expand((t) => state.cardsByTopic(t.id))
          .toList();
    } else {
      cards = state.cardsByTopic(_topicId!);
    }

    if (cards.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Not enough flashcards. A minimum of 4 cards are required to build a quiz.')),
      );
      return;
    }

    // Show quick preparing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 12),
              Text('Preparing quiz…'),
            ],
          ),
        ),
      ),
    );

    // Build questions and navigate
    final questions = _buildQuestions(cards, state.quizCount);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.of(context).pop(); // close dialog
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizRunner(questions: questions),
    ));
  }

  List<_QuizQ> _buildQuestions(List<Flashcard> cards, int count) {
    final List<Flashcard> shuffledCards = List.from(cards)..shuffle();
    final qs = <_QuizQ>[];

    final cardsForQuiz = shuffledCards.take(count).toList();

    for (final c in cardsForQuiz) {
      final others = cards
          .where((o) => o.id != c.id && o.answer.trim().isNotEmpty)
          .toList();
      others.shuffle();
      final distractors = others.take(3).map((e) => e.answer).toList();
      while (distractors.length < 3) {
        distractors.add('None of the above');
      }
      final options = [...distractors, c.answer];
      options.shuffle();
      final correctIdx = options.indexOf(c.answer);
      qs.add(_QuizQ(
          question: c.question, options: options, correctIndex: correctIdx));
    }
    return qs;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cats = state.categories.values.toList();
    final tops = _categoryId == null ? <Topic>[] : state.topicsByCategory(_categoryId!);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Quiz Mode', icon: Icons.quiz),
        const SizedBox(height: 12),
        const _TipBanner(
          text:
          'Questions come from your flashcards. Each question is timed. Your score and time will be shown at the end.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Select Category'),
          items: cats
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
              .toList(),
          value: _categoryId,
          onChanged: (v) => setState(() {
            _categoryId = v;
            _topicId = null;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          decoration: const InputDecoration(labelText: 'Select Topic'),
          items: [
            const DropdownMenuItem(
                value: 'all', child: Text('— Any Topic in Category —')),
            ...tops
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
          ],
          value: _topicId,
          onChanged: _categoryId != null
              ? (v) => setState(() => _topicId = v)
              : null,
          isDense: false,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: (_categoryId != null && _topicId != null)
              ? () => _startQuiz(context)
              : null,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Quiz'),
        ),
      ],
    );
  }
}

class QuizRunner extends StatefulWidget {
  final List<_QuizQ> questions;
  const QuizRunner({super.key, required this.questions});

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int _idx = 0;
  int _score = 0;
  final Stopwatch _sw = Stopwatch();
  int? _selected;
  late final Timer _questionTimer;
  double _timeProgress = 1.0;
  bool _timerStarted = false; // Add a flag to ensure the timer starts once.

  @override
  void initState() {
    super.initState();
    _sw.start();
  }

  // This is the correct place to access inherited widgets like AppStateScope
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timerStarted) {
      _startQuestionTimer();
      _timerStarted = true;
    }
  }

  void _startQuestionTimer() {
    final state = AppStateScope.of(context);
    final totalSeconds = state.quizSeconds;
    final tick = 50;
    _questionTimer = Timer.periodic(Duration(milliseconds: tick), (timer) {
      setState(() {
        final elapsedMs = timer.tick * tick;
        _timeProgress = 1.0 - (elapsedMs / (totalSeconds * 1000));
        if (_timeProgress <= 0) {
          _questionTimer.cancel();
          _selected = -1; // Indicate a timeout
          _nextQuestion();
        }
      });
    });
  }

  void _nextQuestion() {
    if (!mounted) return;
    _questionTimer.cancel();
    if (_selected == widget.questions[_idx].correctIndex) {
      _score++;
    }

    if (_idx < widget.questions.length - 1) {
      setState(() {
        _idx++;
        _selected = null;
        _timeProgress = 1.0;
      });
      _startQuestionTimer();
    } else {
      _sw.stop();
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => QuizResult(
            score: _score,
            total: widget.questions.length,
            elapsed: _sw.elapsed),
      ));
    }
  }

  @override
  void dispose() {
    _sw.stop();
    _questionTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
          appBar: AppBar(title: const Text('Quiz')),
          body: const Center(
              child: Text(
                  'Not enough flashcards to build a quiz.\nAdd more cards to this topic.')));
    }
    final q = widget.questions[_idx];
    final state = AppStateScope.of(context);
    final timeLeft = (state.quizSeconds * _timeProgress).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz in Progress'), actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
              child: Text('Q ${_idx + 1}/${widget.questions.length}')),
        )
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: _timeProgress, minHeight: 8),
              const SizedBox(height: 8),
              Flexible(child: Text('Time left: ${timeLeft}s', textAlign: TextAlign.center)),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center( // Added Center here to handle text alignment better
                      child: Text(
                        q.question,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(q.options.length, (i) {
                final isCorrect = i == q.correctIndex;
                final isSelected = i == _selected;
                final showCorrect = state.showAnswerAfter && _selected != null && isCorrect;
                Color? color;
                if (isSelected && _selected != q.correctIndex) {
                  color = Colors.red;
                } else if (showCorrect) {
                  color = Colors.green;
                }

                return RadioListTile<int>(
                  value: i,
                  groupValue: _selected,
                  onChanged: _selected == null ? (v) => setState(() => _selected = v) : null,
                  title: Text(   // ✅ correct way
                    q.options[i],
                    style: TextStyle(color: color),
                    overflow: TextOverflow.ellipsis, // optional: handles long text
                    maxLines: 2,                      // optional: wraps to 2 lines
                  ),
                );
              }),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Score: $_score', style: Theme.of(context).textTheme.titleSmall),
                FilledButton.icon(
                  onPressed: _selected == null ? null : _nextQuestion,
                  icon: Icon(_idx < widget.questions.length - 1
                      ? Icons.play_arrow
                      : Icons.check),
                  label: Text(
                      _idx < widget.questions.length - 1 ? 'Next' : 'Finish'),
                )
              ])
            ]),
      ),
    );
  }
}

class _QuizQ {
  final String question;
  final List<String> options;
  final int correctIndex;
  _QuizQ(
      {required this.question,
        required this.options,
        required this.correctIndex});
}

class QuizResult extends StatelessWidget {
  final int score;
  final int total;
  final Duration elapsed;
  const QuizResult(
      {super.key,
        required this.score,
        required this.total,
        required this.elapsed});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : score / total;
    String badge;
    if (pct >= 0.9) {
      badge = '🎉 Perfect!';
    } else if (pct >= 0.7) {
      badge = '👏 Great job!';
    } else if (pct >= 0.5) {
      badge = '👍 Keep going!';
    } else {
      badge = '💪 Practice makes perfect!';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz Result')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: pct, strokeWidth: 10),
                Text('${(pct * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleLarge),
              ]),
            ),
            const SizedBox(height: 16),
            Flexible(child: FittedBox(child: Text(badge, style: Theme.of(context).textTheme.headlineSmall))),
            const SizedBox(height: 8),
            Flexible(child: FittedBox(child: Text('Score: $score / $total',
                style: Theme.of(context).textTheme.titleLarge))),
            const SizedBox(height: 8),
            Flexible(child: FittedBox(child: Text('Time: ${elapsed.inMinutes}m ${(elapsed.inSeconds % 60)}s'))),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Try Again'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate back to the root, which is the Home page
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Home'),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

// ===================== SETTINGS =====================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Appearance', icon: Icons.brightness_6),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: state.themeMode,
                title: const Text('System default'),
                onChanged: (v) => state.updateTheme(v!),
              ),
              const Divider(height: 0),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: state.themeMode,
                title: const Text('Light'),
                onChanged: (v) => state.updateTheme(v!),
              ),
              const Divider(height: 0),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: state.themeMode,
                title: const Text('Dark'),
                onChanged: (v) => state.updateTheme(v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Quiz Settings', icon: Icons.quiz),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              ListTile(
                title: const Text('Number of questions'),
                trailing: DropdownButton<int>(
                  value: state.quizCount,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5')),
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 15, child: Text('15')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      state.updateQuizCount(value);
                    }
                  },
                ),
              ),
              const Divider(height: 0),
              ListTile(
                title: const Text('Time per question'),
                trailing: DropdownButton<int>(
                  value: state.quizSeconds,
                  items: const [
                    DropdownMenuItem(value: 10, child: Text('10 seconds')),
                    DropdownMenuItem(value: 15, child: Text('15 seconds')),
                    DropdownMenuItem(value: 20, child: Text('20 seconds')),
                    DropdownMenuItem(value: 30, child: Text('30 seconds')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      state.updateQuizSeconds(value);
                    }
                  },
                ),
              ),
              const Divider(height: 0),
              SwitchListTile(
                title: const Text('Show correct answer after each question'),
                value: state.showAnswerAfter,
                onChanged: (value) => state.toggleShowAnswerAfter(value),
              ),
            ],
          ),
        ),
        // --- NEW DATA MANAGEMENT SECTION ---
        const SizedBox(height: 16),
        _SectionHeader(title: 'Data Management', icon: Icons.storage),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: const Text('Clear All Flashcards'),
            subtitle: const Text('This will permanently delete all categories, topics, and flashcards.'),
            onTap: () {
              // Show a confirmation dialog
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Deletion'),
                    content: const Text(
                        'Are you sure you want to delete all your flashcards? This action cannot be undone.'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          state.reset(); // Call the new reset method
                          Navigator.of(context).pop(); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All flashcard data has been cleared.')),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        // --- END OF NEW SECTION ---
        const SizedBox(height: 16),
        _SectionHeader(title: 'About', icon: Icons.info_outline),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: cs.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'FlipLearn is a simple flashcards & quiz app built for learning quickly.\n\n'
                        'Create categories, add topics, and study with flip cards. Mark cards as learned to track progress, '
                        'and quiz yourself with multiple-choice generated from your own cards.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}