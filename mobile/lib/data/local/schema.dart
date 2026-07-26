import 'package:sqflite/sqflite.dart';

abstract final class LocalSchema {
  static const version = 1;
  static const databaseName = 'teknoakis.db';

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
  ];

  static const deletionOrder = <String>[
    AssistantMessagesTable.name,
    AssistantConversationsTable.name,
    ReadHistoryTable.name,
    FavoritesTable.name,
    SavedItemsTable.name,
    InterestsTable.name,
    AssistantProjectsTable.name,
  ];
}
