/// Abstract contract for computing dense vector representations.
abstract interface class EmbeddingEngine {
  Future<void> initialize();
  Future<List<double>> embedText(String text);
  Future<List<double>> embedImage(String imagePath);
  int get vectorDimension;
  Future<void> dispose();
}
