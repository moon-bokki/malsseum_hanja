import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/local/bible_database.dart';
import 'data/datasources/local/local_bible_datasource.dart';
import 'data/datasources/remote/stdict_api.dart';
import 'data/repositories/bible_repository.dart';
import 'data/repositories/dictionary_repository.dart';
import 'data/repositories/wordbook_repository.dart';
import 'services/push_notification_service.dart';

/// 의존성 주입(DI). 테스트에서는 ProviderScope(overrides: ...) 로 교체한다.

final dioProvider = Provider<Dio>((ref) => createDioClient());

final bibleDatabaseProvider = Provider<BibleDatabase>((ref) {
  final db = BibleDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final bibleRepositoryProvider = Provider<BibleRepository>(
  (ref) => SqliteBibleRepository(
    ref.watch(bibleDatabaseProvider),
    LocalBibleDataSource(),
  ),
);

final dictionaryRepositoryProvider = Provider<DictionaryRepository>(
  (ref) => DictionaryRepositoryImpl(StdictApi(ref.watch(dioProvider))),
);

final wordbookRepositoryProvider = Provider<WordbookRepository>(
  (ref) => AppConfig.useFirebase
      ? FirestoreWordbookRepository(
          FirebaseFirestore.instance,
          FirebaseAuth.instance,
        )
      : InMemoryWordbookRepository(),
);

final pushNotificationServiceProvider = Provider<PushNotificationService?>(
  (ref) => AppConfig.useFirebase ? PushNotificationService() : null,
);
