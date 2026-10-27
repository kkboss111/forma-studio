import 'command.dart';
import '../../domain/models/project_model.dart';

class HistoryManager {
  final int maxHistoryLength;
  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  HistoryManager({this.maxHistoryLength = 100});

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  String? get undoDescription =>
      _undoStack.isNotEmpty ? _undoStack.last.description : null;
  String? get redoDescription =>
      _redoStack.isNotEmpty ? _redoStack.last.description : null;

  ProjectModel executeCommand(Command command, ProjectModel project) {
    final updated = command.execute(project);
    _undoStack.add(command);
    if (_undoStack.length > maxHistoryLength) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    return updated;
  }

  ProjectModel undo(ProjectModel project) {
    if (!canUndo) return project;
    final cmd = _undoStack.removeLast();
    final updated = cmd.undo(project);
    _redoStack.add(cmd);
    return updated;
  }

  ProjectModel redo(ProjectModel project) {
    if (!canRedo) return project;
    final cmd = _redoStack.removeLast();
    final updated = cmd.redo(project);
    _undoStack.add(cmd);
    return updated;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
