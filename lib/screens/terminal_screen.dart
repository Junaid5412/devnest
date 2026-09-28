import 'dart:io';
import 'package:flutter/material.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _output = ['DevNest Terminal Emulator (v1.0)', 'Type a command to execute...'];

  void _executeCommand(String command) async {
    if (command.trim().isEmpty) return;

    setState(() {
      _output.add('\$ $command');
    });

    _commandController.clear();

    // Basic implementation of running commands
    try {
      final parts = command.split(' ');
      final executable = parts.first;
      final args = parts.sublist(1);

      final result = await Process.run(executable, args);
      
      setState(() {
        if (result.stdout.toString().isNotEmpty) {
          _output.add(result.stdout.toString().trim());
        }
        if (result.stderr.toString().isNotEmpty) {
          _output.add(result.stderr.toString().trim());
        }
      });
    } catch (e) {
      setState(() {
        _output.add('Error: Command not found or failed to execute ($e)');
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _output.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    _output[index],
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Container(
            color: Colors.grey.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Text('\$ ', style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 16)),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter command...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    onSubmitted: _executeCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _executeCommand(_commandController.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
