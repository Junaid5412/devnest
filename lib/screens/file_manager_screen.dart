import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  String _currentPath = '';
  List<FileSystemEntity> _entities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDirectory();
  }

  Future<void> _initDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() {
      _currentPath = dir.path;
    });
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = Directory(_currentPath);
      final List<FileSystemEntity> entities = await dir.list().toList();
      entities.sort((a, b) {
        if (a is Directory && b is File) return -1;
        if (a is File && b is Directory) return 1;
        return a.path.compareTo(b.path);
      });
      setState(() {
        _entities = entities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Ignore errors for now
    }
  }

  void _navigateUp() {
    final parent = Directory(_currentPath).parent;
    if (parent.path != _currentPath) {
      setState(() {
        _currentPath = parent.path;
      });
      _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Text(
              _currentPath,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _entities.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text('..'),
                    onTap: _navigateUp,
                  );
                }
                final entity = _entities[index - 1];
                final isDir = entity is Directory;
                final name = entity.path.split(Platform.pathSeparator).last;
                
                return ListTile(
                  leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file, color: isDir ? Colors.amber : Colors.blue),
                  title: Text(name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                    ],
                  ),
                  onTap: () {
                    if (isDir) {
                      setState(() {
                        _currentPath = entity.path;
                      });
                      _loadFiles();
                    } else {
                      // Open Code Editor logic
                      _showCodeEditor(context, entity as File);
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  void _showCodeEditor(BuildContext context, File file) async {
    final content = await file.readAsString().catchError((_) => 'Unable to read file.');
    final controller = TextEditingController(text: content);
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Scaffold(
            appBar: AppBar(
              title: Text(file.path.split(Platform.pathSeparator).last),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    file.writeAsStringSync(controller.text);
                    Navigator.pop(context);
                  },
                )
              ],
            ),
            body: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
        );
      },
    );
  }
}
