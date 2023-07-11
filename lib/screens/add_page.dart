import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo/services/notification_service.dart';
import 'package:todo/services/todo_service.dart';
import 'package:todo/utils/snackbar_helper.dart';
import 'package:timezone/timezone.dart' as tz;

import '../main.dart';

class AddTodoPage extends StatefulWidget {
  final Map? todo;

  const AddTodoPage({Key? key, this.todo}) : super(key: key);

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final NotificationService _notificationService = NotificationService();

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  // TextEditingController _dateTimeController = TextEditingController();
  DateTime? _selectedDateTime;

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDateTime = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDateTime != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDateTime.year,
            pickedDateTime.month,
            pickedDateTime.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  bool isEdit = false;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    if (todo != null) {
      isEdit = true;
      final title = todo['title'];
      final description = todo['description'];
      titleController.text = title;
      descriptionController.text = description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(isEdit ? 'Edit Todo' : "Add Todo"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: "Title"),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: "Description"),
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            maxLength: 100,
          ),
          TextField(
            readOnly: true,
            onTap: () => _selectDateTime(context),
            controller: TextEditingController(
              text:
                  _selectedDateTime != null ? _selectedDateTime.toString() : '',
            ),
            decoration: const InputDecoration(
              labelText: 'Select Date and Time',
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () async {
              if (isEdit) {
                if (await checkInternetConnectivity()) {
                  updateData();
                } else {
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const NoInternetDialog();
                    },
                  );
                }
              } else {
                if (await checkInternetConnectivity()) {
                  // submitData();
                  saveTodo();
                } else {
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const NoInternetDialog();
                    },
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(isEdit ? 'Update' : 'Submit'),
            ),
          )
        ],
      ),
    );
  }

  Future<void> updateData() async {
    final todo = widget.todo;
    if (todo == null) {
      print('you not call update without to do data');
      return;
    }
    final id = todo['_id'];
    final isSuccess = await TodoService.updateTodo(id, body);
    if (isSuccess) {
      // ignore: use_build_context_synchronously
      showSuccessMessage(this.context, message: 'Update Success');
    } else {
      // ignore: use_build_context_synchronously
      showErrorMessage(this.context, message: 'Update Failed');
    }
  }

  Future<void> submitData() async {
    // Submit data to the Server
    final isSuccess = await TodoService.addTodo(body);
    // show success or failed message based on the success
    if (isSuccess) {
      titleController.text = '';
      descriptionController.text = '';
      // ignore: use_build_context_synchronously
      showSuccessMessage(this.context, message: 'Creation Success');
    } else {
      // ignore: use_build_context_synchronously
      showErrorMessage(this.context, message: 'Creation Failed');
    }
  }

  Future<void> saveTodo() async {
    try {
      final databasePath = await getDatabasesPath();
      final database = await openDatabase(
        join(databasePath, 'my_database.db'),
        onCreate: (db, version) {
          db.execute('''
          CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY,
            _id TEXT,
            title TEXT,
            description TEXT,
            date_time DATETIME,
            completed INTEGER)''');
          print("Baber");
        },
        version: 1,
      );

      // Create a new DateTime object using the UTC values
      DateTime utcDateTime = DateTime.utc(
        _selectedDateTime!.year,
        _selectedDateTime!.month,
        _selectedDateTime!.day,
        _selectedDateTime!.hour,
        _selectedDateTime!.minute,
        _selectedDateTime!.second,
      );

      final Map<String, dynamic> todoData = {
        'title': titleController.text,
        'description': descriptionController.text,
        'date_time': utcDateTime.toIso8601String(),
        // Convert to ISO 8601 string
        'completed': 0,
      };
      await database.insert('todos', todoData,
          conflictAlgorithm: ConflictAlgorithm.replace);
      final todoId = await getRecentlyInsertedTodo(); // Await the function call

      await _notificationService.showNotifications()

      await _notificationService.scheduleNotifications(
          id: todoId as int,
          title: titleController.text,
          body: descriptionController.text,
          time: utcDateTime);

      await database.close();

      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text("Done!"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text("Shit"),
        ),
      );
    }
  }

  Future<int?> getRecentlyInsertedTodo() async {
    // Run a query to fetch the most recently inserted todo
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      join(databasePath, 'my_database.db'),
    );
    List<Map<String, dynamic>> results = await database.query(
      'todos',
      orderBy: '_id DESC',
      limit: 1,
    );

    await database.close();

    // Return the ID value as an int
    if (results.isNotEmpty) {
      return results.first['id'] as int?;
    }

    return null;
  }

  Future<bool> checkInternetConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Map get body {
    final title = titleController.text;
    final description = descriptionController.text;
    return {
      "title": title,
      "description": description,
      "is_completed": false,
    };
  }
}

class NoInternetDialog extends StatelessWidget {
  const NoInternetDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      title: const Text('No Internet Connection'),
      content: const Text('Please check your internet connection.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Update the context parameter
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
