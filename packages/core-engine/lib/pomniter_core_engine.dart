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

// Implementations
export 'src/implementations/in_memory_screenshot_repository.dart';
export 'src/implementations/in_memory_search_repository.dart';
export 'src/implementations/mock_ocr_engine.dart';
export 'src/implementations/mock_embedding_engine.dart';

// Use Cases
export 'src/usecases/process_screenshot_usecase.dart';
export 'src/usecases/search_screenshots_usecase.dart';
