import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/project_model.dart';

class ProjectRepository {
  static const String _indexKey = 'forma_projects_index';
  Timer? _debounceTimer;

  /// Lists all stored projects metadata.
  Future<List<ProjectModel>> listProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final indexJson = prefs.getString(_indexKey);
    final List<String> projectIds = [];

    if (indexJson != null) {
      try {
        final list = jsonDecode(indexJson) as List;
        projectIds.addAll(list.cast<String>());
      } catch (e) {
        debugPrint('Error reading project index: $e');
      }
    }

    final projects = <ProjectModel>[];
    for (final id in projectIds) {
      final p = await getProject(id);
      if (p != null) {
        projects.add(p);
      }
    }

    // Sort by updated descending
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return projects;
  }

  /// Retrieves a project by ID from SharedPreferences.
  Future<ProjectModel?> getProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('proj_$id');
    if (raw != null) {
      try {
        final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
        return ProjectModel.fromJson(jsonMap);
      } catch (e) {
        debugPrint('Error decoding project $id: $e');
      }
    }
    return null;
  }

  /// Saves project to persistent local storage.
  Future<void> saveProject(ProjectModel project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    final jsonStr = jsonEncode(updated.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proj_${project.id}', jsonStr);

    // Update index
    final indexJson = prefs.getString(_indexKey);
    final Set<String> ids = {};
    if (indexJson != null) {
      try {
        ids.addAll((jsonDecode(indexJson) as List).cast<String>());
      } catch (_) {}
    }
    ids.add(project.id);
    await prefs.setString(_indexKey, jsonEncode(ids.toList()));
  }

  /// Debounced autosave
  void scheduleAutosave(
    ProjectModel project, {
    Duration delay = const Duration(milliseconds: 600),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      await saveProject(project);
    });
  }

  /// Deletes a project.
  Future<void> deleteProject(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('proj_$id');

    final indexJson = prefs.getString(_indexKey);
    if (indexJson != null) {
      try {
        final list = (jsonDecode(indexJson) as List)
            .cast<String>()
            .where((x) => x != id)
            .toList();
        await prefs.setString(_indexKey, jsonEncode(list));
      } catch (_) {}
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
