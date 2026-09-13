/// ObjectBox Store factory — opens or creates the local database.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../exceptions/engine_exceptions.dart';
import '../../objectbox.g.dart';

/// Opens (or creates) the ObjectBox [Store] for Pomniter.
///
/// The database is stored at:
///   `<appDocumentsDirectory>/pomniter_db/`
///
/// If [directory] is provided, it overrides the default location — useful
/// for isolate testing with temporary directories.
///
/// Throws [VectorStoreException] if the store cannot be opened.
Future<Store> openObjectBoxStore({String? directory}) async {
  try {
    final dir = directory ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'pomniter_db',
        );

    await Directory(dir).create(recursive: true);

    return await openStore(directory: dir);
  } catch (e, st) {
    throw VectorStoreException(
      'Failed to open ObjectBox store: $e',
      cause: e,
      stackTrace: st,
    );
  }
}
