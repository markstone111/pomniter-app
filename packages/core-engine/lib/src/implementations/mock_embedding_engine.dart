import '../interfaces/embedding_engine.dart';

/// Mock embedding engine generating deterministic vector embeddings for testing.
class MockEmbeddingEngine implements EmbeddingEngine {
  final int dimension;
  bool _isInitialized = false;

  MockEmbeddingEngine({this.dimension = 384});

  @override
  int get vectorDimension => dimension;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<List<double>> embedText(String text) async {
    if (!_isInitialized) {
      throw StateError('EmbeddingEngine must be initialized before embedding');
    }
    // Generate deterministic pseudo-embedding based on string hash
    final hash = text.hashCode;
    return List.generate(dimension, (i) => ((hash + i) % 100) / 100.0);
  }

  @override
  Future<List<double>> embedImage(String imagePath) async {
    if (!_isInitialized) {
      throw StateError('EmbeddingEngine must be initialized before embedding');
    }
    final hash = imagePath.hashCode;
    return List.generate(dimension, (i) => ((hash + i * 2) % 100) / 100.0);
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
