import 'package:sqflite/sqflite.dart';

abstract final class LocalSchema {
  static const version = 2;
  static const databaseName = 'teknoakis.db';

  /// Yeni kurulum da **migration yolundan** geçer.
  ///
  /// En güncel şemayı tek parça yazmak daha kısa olurdu ama iki ayrı gerçek
  /// üretirdi: sıfırdan kurulan cihaz ile yükseltilen cihaz farklı yollardan
  /// gelirdi ve aradaki fark ancak kullanıcıdaki bozuk sorguyla görünürdü.
  /// Aynı adımları izleyerek ikisinin **yakınsadığı** garanti edilir ve
  /// migration kodu her kurulumda çalıştığı için ölü kalmaz.
  static Future<void> createLatest(Database db) async {
    await createV1(db);
    for (var target = 2; target <= version; target++) {
      await upgradeTo(db, target);
    }
  }

  /// Tek bir sürüm adımı. `onUpgrade` ve [createLatest] aynı fonksiyonu çağırır.
  static Future<void> upgradeTo(Database db, int target) async {
    switch (target) {
      case 2:
        await _createFeedCacheV2(db);
    }
  }

  /// v2: uzaktan çekilen feed'in yerel kopyası.
  ///
  /// Tek satır: `CHECK (id = 1)` ikinci bir kaydın yazılmasını **veritabanı
  /// seviyesinde** engeller. "Son çekilen feed" tanımı gereği tekildir;
  /// bunu yalnız uygulama kodunda varsaymak, bir hata durumunda sessizce
  /// büyüyen bir tablo bırakırdı.
  static Future<void> _createFeedCacheV2(Database db) async {
    await db.execute('''
      CREATE TABLE ${FeedCacheTable.name} (
        ${FeedCacheTable.id} INTEGER PRIMARY KEY CHECK (${FeedCacheTable.id} = 1),
        ${FeedCacheTable.payload} TEXT NOT NULL,
        ${FeedCacheTable.fetchedAt} INTEGER NOT NULL,
        ${FeedCacheTable.generatedAt} INTEGER NOT NULL,
        ${FeedCacheTable.sourceUrl} TEXT NOT NULL
      )
    ''');
  }

  static Future<void> createV1(Database db) async {
    await db.execute('''
      CREATE TABLE ${InterestsTable.name} (
        ${InterestsTable.id} TEXT PRIMARY KEY,
        ${InterestsTable.label} TEXT NOT NULL,
        ${InterestsTable.createdAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${SavedItemsTable.name} (
        ${SavedItemsTable.id} TEXT PRIMARY KEY,
        ${SavedItemsTable.kind} TEXT NOT NULL,
        ${SavedItemsTable.title} TEXT NOT NULL,
        ${SavedItemsTable.sourceLabel} TEXT,
        ${SavedItemsTable.summary} TEXT,
        ${SavedItemsTable.savedAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${FavoritesTable.name} (
        ${FavoritesTable.itemId} TEXT PRIMARY KEY,
        ${FavoritesTable.createdAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${ReadHistoryTable.name} (
        ${ReadHistoryTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ReadHistoryTable.itemId} TEXT NOT NULL,
        ${ReadHistoryTable.itemKind} TEXT,
        ${ReadHistoryTable.readAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AssistantProjectsTable.name} (
        ${AssistantProjectsTable.id} TEXT PRIMARY KEY,
        ${AssistantProjectsTable.title} TEXT NOT NULL,
        ${AssistantProjectsTable.createdAt} INTEGER NOT NULL,
        ${AssistantProjectsTable.updatedAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AssistantConversationsTable.name} (
        ${AssistantConversationsTable.id} TEXT PRIMARY KEY,
        ${AssistantConversationsTable.projectId} TEXT NOT NULL,
        ${AssistantConversationsTable.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${AssistantConversationsTable.projectId})
          REFERENCES ${AssistantProjectsTable.name} (${AssistantProjectsTable.id})
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AssistantMessagesTable.name} (
        ${AssistantMessagesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${AssistantMessagesTable.conversationId} TEXT NOT NULL,
        ${AssistantMessagesTable.role} TEXT NOT NULL,
        ${AssistantMessagesTable.content} TEXT NOT NULL,
        ${AssistantMessagesTable.createdAt} INTEGER NOT NULL,
        FOREIGN KEY (${AssistantMessagesTable.conversationId})
          REFERENCES ${AssistantConversationsTable.name}
            (${AssistantConversationsTable.id})
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX ${LocalIndexes.readHistoryItemId} '
      'ON ${ReadHistoryTable.name} (${ReadHistoryTable.itemId})',
    );
    await db.execute(
      'CREATE INDEX ${LocalIndexes.assistantConversationsProjectId} '
      'ON ${AssistantConversationsTable.name} '
      '(${AssistantConversationsTable.projectId})',
    );
    await db.execute(
      'CREATE INDEX ${LocalIndexes.assistantMessagesConversationId} '
      'ON ${AssistantMessagesTable.name} '
      '(${AssistantMessagesTable.conversationId})',
    );
  }
}

abstract final class InterestsTable {
  static const name = 'interests';
  static const id = 'id';
  static const label = 'label';
  static const createdAt = 'created_at';
}

abstract final class SavedItemsTable {
  static const name = 'saved_items';
  static const id = 'id';
  static const kind = 'kind';
  static const title = 'title';
  static const sourceLabel = 'source_label';
  static const summary = 'summary';
  static const savedAt = 'saved_at';
}

abstract final class FavoritesTable {
  static const name = 'favorites';
  static const itemId = 'item_id';
  static const createdAt = 'created_at';
}

abstract final class ReadHistoryTable {
  static const name = 'read_history';
  static const id = 'id';
  static const itemId = 'item_id';
  static const itemKind = 'item_kind';
  static const readAt = 'read_at';
}

abstract final class AssistantProjectsTable {
  static const name = 'assistant_projects';
  static const id = 'id';
  static const title = 'title';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

abstract final class AssistantConversationsTable {
  static const name = 'assistant_conversations';
  static const id = 'id';
  static const projectId = 'project_id';
  static const createdAt = 'created_at';
}

abstract final class AssistantMessagesTable {
  static const name = 'assistant_messages';
  static const id = 'id';
  static const conversationId = 'conversation_id';
  static const role = 'role';
  static const content = 'content';
  static const createdAt = 'created_at';
}

abstract final class FeedCacheTable {
  static const name = 'feed_cache';
  static const id = 'id';

  /// Ham JSON. Ayrıştırılmış hâli değil: şema sürümü doğrulaması okuma anında
  /// yapılır, böylece uygulama güncellenip şema kuralları değiştiğinde
  /// önbellekteki kayıt da yeni kurallardan geçer.
  static const payload = 'payload';

  /// Çekme anı — **son başarılı senkronizasyon** budur.
  static const fetchedAt = 'fetched_at';

  /// Feed'in kendi üretim anı. Paketlenmiş dosyayla karşılaştırmak için
  /// ayrıca tutulur: 184 KB'lık JSON'u yalnız tarihe bakmak için ayrıştırmak
  /// gerekmesin.
  static const generatedAt = 'generated_at';

  /// Hangi adresten geldiği. Adres değişirse eski kopya kullanılmaz.
  static const sourceUrl = 'source_url';
}

abstract final class LocalIndexes {
  static const readHistoryItemId = 'idx_read_history_item_id';
  static const assistantConversationsProjectId =
      'idx_assistant_conversations_project_id';
  static const assistantMessagesConversationId =
      'idx_assistant_messages_conversation_id';
}

abstract final class LocalTables {
  static const all = <String>[
    InterestsTable.name,
    SavedItemsTable.name,
    FavoritesTable.name,
    ReadHistoryTable.name,
    AssistantProjectsTable.name,
    AssistantConversationsTable.name,
    AssistantMessagesTable.name,
    FeedCacheTable.name,
  ];

  /// `Verileri Sil` feed önbelleğini de boşaltır.
  ///
  /// İçerik kişisel veri değil ve silinmesi bir kayıp sayılmaz — uygulama
  /// paketlenmiş dosyaya düşer ve ilk tazelemede yeniden dolar. Ama satır
  /// **ne zaman senkronize edildiğini** taşır; "tüm yerel verileri sil"
  /// diyen bir kullanıcıya geriye kullanım zamanını gösteren bir kayıt
  /// bırakmak, verilen sözü tutmamaktır.
  static const deletionOrder = <String>[
    FeedCacheTable.name,
    AssistantMessagesTable.name,
    AssistantConversationsTable.name,
    ReadHistoryTable.name,
    FavoritesTable.name,
    SavedItemsTable.name,
    InterestsTable.name,
    AssistantProjectsTable.name,
  ];
}
