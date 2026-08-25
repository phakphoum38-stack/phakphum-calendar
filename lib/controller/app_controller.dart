  }

  Future<void> _ensureActiveSavedSheetPerAccount() async {
    final accountIds = savedSheets
        .map((sheet) => sheet.ownerAccountId)
        .where((id) => id.isNotEmpty)
        .toSet();
    var changed = false;
    for (final accountId in accountIds) {
      final accountSheets = savedSheets
          .where((sheet) => sheet.ownerAccountId == accountId)
          .toList()
        ..sort((left, right) => right.savedAt.compareTo(left.savedAt));
      final legacySheets = accountSheets
          .where((sheet) => !sheet.hasExplicitActiveState)
          .toList();
      if (accountSheets.any((sheet) => sheet.isActive) || legacySheets.isEmpty) {
        continue;
      }
      final activeKey = legacySheets.first.key;
      savedSheets = [
        for (final item in savedSheets)
          if (item.key == activeKey) item.copyWith(isActive: true) else item,
      ];
      changed = true;
    }
    if (changed) await _settingsService.saveSavedSheets(savedSheets);
  }

  Iterable<ToolDefinition> get pinnedTools =>
      toolCatalog.where((tool) => pinnedToolIds.contains(tool.id));

  List<SavedSheet> get savedSheetsForCurrentAccount {
    final accountId = auth.account?.id;
    if (accountId == null) return const [];
    return savedSheets
        .where((sheet) => sheet.ownerAccountId == accountId)
        .toList()
      ..sort((left, right) {
        if (left.isActive != right.isActive) return left.isActive ? -1 : 1;
        return right.savedAt.compareTo(left.savedAt);
      });
  }

  SavedSheet? get currentSourceSheet =>
      savedSheetsForCurrentAccount.where((sheet) => sheet.isActive).firstOrNull;

  String get currentSourceUrl => currentSourceSheet?.url ?? '';