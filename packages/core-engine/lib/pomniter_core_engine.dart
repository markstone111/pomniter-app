/// Pomniter Core Engine
///
/// Business logic, repository interfaces, use cases, and pipeline engines
/// for the Pomniter screenshot memory engine.
library;

// Interfaces
export 'src/interfaces/screenshot_repository.dart';
export 'src/interfaces/search_repository.dart';
export 'src/interfaces/ocr_engine.dart';
export 'src/interfaces/embedding_engine.dart';
export 'src/interfaces/auth_repository.dart';

// In-memory / Mock implementations (for testing and initial seeding)
export 'src/implementations/in_memory_screenshot_repository.dart';
export 'src/implementations/in_memory_search_repository.dart';
export 'src/implementations/mock_ocr_engine.dart';
export 'src/implementations/mock_embedding_engine.dart';

// Phase 1.6 — On-Device ONNX ML Pipeline
export 'src/implementations/onnx_tokenizer.dart';
export 'src/implementations/onnx_ocr_engine.dart';
export 'src/implementations/onnx_clip_embedding_engine.dart';

// Phase 1.7 — ObjectBox Local Vector Database
export 'src/objectbox/objectbox_entities.dart';
export 'src/objectbox/objectbox_screenshot_repository.dart';
export 'src/objectbox/objectbox_search_repository.dart';
export 'src/objectbox/objectbox_store_provider.dart';

// Typed Exceptions
export 'src/exceptions/engine_exceptions.dart';

// Use Cases
export 'src/usecases/process_screenshot_usecase.dart';
export 'src/usecases/search_screenshots_usecase.dart';

