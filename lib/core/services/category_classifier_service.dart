import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import '../models/category_prediction.dart';
import '../models/expense_group_with_items.dart';

class CategoryClassifierService {
  // Per-category word frequencies
  final Map<String, Map<String, int>> _wordCounts = {};
  // Documents per category
  final Map<String, int> _categoryCounts = {};
  // Total documents trained on
  int _totalDocuments = 0;
  // All unique words seen
  final Set<String> _vocabulary = {};
  // Whether the model has been initialized
  bool _isModelReady = false;

  bool get isModelReady => _isModelReady;

  /// Tokenizes text: lowercase, strip punctuation/numbers, split whitespace, drop single-char tokens.
  List<String> tokenize(String text) {
    final cleaned = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .trim();
    if (cleaned.isEmpty) return [];
    return cleaned
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1)
        .toList();
  }

  /// Initialize the classifier from persisted model or train from seed + expense groups.
  Future<void> initialize(List<ExpenseGroupWithItems> expenseGroups) async {
    final loaded = await _loadModel();
    void trainFromGroups() {
      for (final group in expenseGroups) {
        for (final item in group.items) {
          _trainSingle(item.description, item.category);
        }
      }
    }

    if (!loaded) {
      _loadSeedData();
      trainFromGroups();
      _isModelReady = true;
      await persistModel();
    } else {
      trainFromGroups();
      _isModelReady = true;
    }
  }

  /// Predict category from text, returning top N predictions.
  List<CategoryPrediction> predict(String text, {int topN = 3}) {
    if (!_isModelReady || _totalDocuments == 0) return [];

    final tokens = tokenize(text);
    if (tokens.isEmpty) return [];

    final vocabSize = _vocabulary.length;
    final Map<String, double> logProbs = {};

    for (final category in _categoryCounts.keys) {
      // Log prior: log(P(category))
      double logProb = log(_categoryCounts[category]! / _totalDocuments);

      // Total words in this category (for Laplace smoothing denominator)
      final categoryWordTotal = _wordCounts[category]!.values
          .fold<int>(0, (sum, count) => sum + count);

      for (final token in tokens) {
        final wordCount = _wordCounts[category]?[token] ?? 0;
        // Laplace smoothing: (count + 1) / (total + vocabSize)
        logProb += log((wordCount + 1) / (categoryWordTotal + vocabSize));
      }

      logProbs[category] = logProb;
    }

    // Convert log probabilities to normalized probabilities using log-sum-exp
    final maxLogProb = logProbs.values.reduce(max);
    final Map<String, double> expProbs = {};
    double sumExp = 0;

    for (final entry in logProbs.entries) {
      final expVal = exp(entry.value - maxLogProb);
      expProbs[entry.key] = expVal;
      sumExp += expVal;
    }

    final List<CategoryPrediction> predictions = [];
    for (final entry in expProbs.entries) {
      predictions.add(CategoryPrediction(
        category: entry.key,
        confidence: entry.value / sumExp,
      ));
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(topN).toList();
  }

  /// Incrementally train on a single expense.
  void trainOnExpense(String description, String category) {
    _trainSingle(description, category);
  }

  void _trainSingle(String description, String category) {
    final tokens = tokenize(description);
    if (tokens.isEmpty) return;

    _categoryCounts[category] = (_categoryCounts[category] ?? 0) + 1;
    _totalDocuments++;

    _wordCounts.putIfAbsent(category, () => {});
    for (final token in tokens) {
      _vocabulary.add(token);
      _wordCounts[category]![token] =
          (_wordCounts[category]![token] ?? 0) + 1;
    }
  }

  /// Persist the model to a JSON file.
  Future<void> persistModel() async {
    try {
      final file = await _getModelFile();
      final data = {
        'wordCounts': _wordCounts,
        'categoryCounts': _categoryCounts,
        'totalDocuments': _totalDocuments,
        'vocabulary': _vocabulary.toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Silently fail — persistence is best-effort
    }
  }

  Future<bool> _loadModel() async {
    try {
      final file = await _getModelFile();
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      _totalDocuments = data['totalDocuments'] as int;

      final wordCountsRaw =
          data['wordCounts'] as Map<String, dynamic>;
      _wordCounts.clear();
      for (final category in wordCountsRaw.keys) {
        final words = wordCountsRaw[category] as Map<String, dynamic>;
        _wordCounts[category] = words.map(
          (key, value) => MapEntry(key, value as int),
        );
      }

      final categoryCountsRaw =
          data['categoryCounts'] as Map<String, dynamic>;
      _categoryCounts.clear();
      for (final entry in categoryCountsRaw.entries) {
        _categoryCounts[entry.key] = entry.value as int;
      }

      final vocabRaw = data['vocabulary'] as List<dynamic>;
      _vocabulary.clear();
      _vocabulary.addAll(vocabRaw.cast<String>());

      _isModelReady = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<File> _getModelFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/classifier_model.json');
  }

  /// Load seed training data for cold start.
  void _loadSeedData() {
    const seedData = {
      'Food & Dining': [
        'lunch dinner breakfast restaurant mamak nasi lemak',
        'mcdonald kfc pizza hut subway food court',
        'coffee tea starbucks cafe bakery snack',
        'grab food foodpanda delivery meal',
        'rice chicken fish vegetable soup noodle mee',
      ],
      'Transportation': [
        'grab ride taxi uber car',
        'petrol fuel gas station shell petronas',
        'parking toll highway lpt plus',
        'bus train lrt mrt ktm rapid transit',
        'ewallet touch go tng topup reload',
      ],
      'Shopping': [
        'shopping mall clothes shoes fashion',
        'lazada shopee online purchase order',
        'electronics gadget phone accessories',
        'aeon parkson ikea mr diy daiso',
        'bag watch jewelry clothing apparel',
      ],
      'Entertainment': [
        'movie cinema gsc tgv popcorn',
        'netflix spotify disney streaming subscription',
        'game gaming playstation xbox steam',
        'concert show event ticket karaoke',
        'book magazine hobby leisure fun',
      ],
      'Bills & Utilities': [
        'electricity bill tenaga nasional tnb',
        'water bill air syabas indah',
        'internet wifi unifi maxis celcom digi',
        'phone mobile prepaid postpaid',
        'astro tv subscription monthly bill',
      ],
      'Auto & Transport': [
        'car service maintenance repair workshop',
        'insurance road tax renewal vehicle',
        'tyre battery engine oil change',
        'car wash detailing cleaning',
        'motorcycle scooter motorbike service',
      ],
      'Travel': [
        'flight airasia malaysia airlines ticket',
        'hotel booking accommodation resort stay',
        'holiday vacation trip tour travel',
        'airport luggage passport visa',
        'agoda booking expedia hotel resort',
      ],
      'Fees & Charges': [
        'bank fee service charge transaction',
        'atm withdrawal transfer processing fee',
        'late payment penalty interest charge',
        'government fee stamp duty tax',
        'commission brokerage agent fee',
      ],
      'Business Services': [
        'office supply printing stationery',
        'software license subscription saas',
        'domain hosting server cloud service',
        'advertising marketing promotion',
        'consulting professional service business',
      ],
      'Education': [
        'tuition fee school university college',
        'course class training workshop seminar',
        'book textbook learning material study',
        'exam registration certification test',
        'student education academic school supply',
      ],
      'Health & Medical': [
        'doctor clinic hospital medical checkup',
        'pharmacy medicine prescription drug',
        'dental dentist teeth cleaning',
        'specialist consultation treatment therapy',
        'supplement vitamin health product',
      ],
      'Home': [
        'rent mortgage housing loan payment',
        'furniture appliance household item',
        'renovation repair plumber electrician',
        'cleaning supply detergent household',
        'garden lawn maintenance property',
      ],
      'Personal Care': [
        'haircut salon barber grooming',
        'skincare beauty cosmetic makeup',
        'spa massage facial treatment wellness',
        'gym fitness workout membership',
        'perfume fragrance personal hygiene',
      ],
      'Gifts & Donations': [
        'gift present birthday anniversary',
        'donation charity zakat contribution',
        'wedding angpau duit raya celebration',
        'flower bouquet card souvenir',
        'volunteer fundraiser community',
      ],
      'Investments': [
        'stock share trading investment portfolio',
        'mutual fund unit trust amanah',
        'crypto bitcoin ethereum digital',
        'gold silver precious metal',
        'property real estate land deposit',
      ],
      'Other': [
        'miscellaneous expense general other',
        'cash withdrawal atm sundry',
        'uncategorized mixed various',
      ],
    };

    for (final entry in seedData.entries) {
      for (final doc in entry.value) {
        _trainSingle(doc, entry.key);
      }
    }
  }
}
