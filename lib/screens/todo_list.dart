import 'dart:async';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:todo/services/todo_service.dart';
import 'package:todo/sql_helper.dart';
import 'package:todo/utils/snackbar_helper.dart';
import 'package:todo/widgets/todo_card.dart';
import 'add_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _refreshJournals();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  TextEditingController titleController = TextEditingController();

  TextEditingController descriptionController = TextEditingController();
  List<Map<String, dynamic>> _journals = [];

  bool isLoading = false;

  void _refreshJournals() async {
    List<Map<String, dynamic>> data;
    if (_connectionStatus == ConnectivityResult.none) {
      data = await SQLHelper.getItems();
    } else {
      data = List<Map<String, dynamic>>.from(items);
    }
    setState(() {
      _journals = data;
      isLoading = false;
    });
  }

  List items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Visibility(
        visible: isLoading,
        replacement: RefreshIndicator(
          onRefresh: fetchTodo,
          child: Visibility(
            visible: items.isNotEmpty,
            replacement: Center(
              child: Text(
                'No Todo Item',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final item = items[index] as Map;
                  return TodoCard(
                      index: index,
                      item: item,
                      navigateEdit: navigateToEditPage,
                      deleteById: deleteById);
                }),
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: navigateToAddPage, label: const Text("Add Todo")),
    );
  }

  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      setState(() {
        _connectionStatus = result;
      });

      if (result == ConnectivityResult.none) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: this.context,
          builder: (BuildContext context) {
            return const NoInternetDialog();
          },
        );
        await fetchTodoFromDb();
      } else {
        setState(() {
          isLoading = true;
        });
        await fetchTodo();
      }
      _connectivitySubscription?.cancel(); // Cancel any existing subscription

      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen((result) async {
        if (result != _connectionStatus) {
          setState(() {
            _connectionStatus = result;
          });

          if (result == ConnectivityResult.none) {
            showDialog(
              context: this.context,
              builder: (BuildContext context) {
                return const NoInternetDialog();
              },
            );
          } else {
            setState(() {
              isLoading = true;
            });
            await fetchTodo();
          }
        }
      });
    } on PlatformException catch (e) {
      developer.log('Could not check connectivity status', error: e);
    }
  }

  Future<void> navigateToEditPage(Map item) async {
    final route =
        MaterialPageRoute(builder: (context) => AddTodoPage(todo: item));
    await Navigator.push(this.context, route);
    setState(() {
      isLoading = true;
    });
    fetchTodo();
  }

  Future<void> navigateToAddPage() async {
    final route = MaterialPageRoute(builder: (context) => const AddTodoPage());
    await Navigator.push(this.context, route);
    setState(() {
      isLoading = true;
    });
    fetchTodo();
  }

  Future<void> deleteById(String id) async {
    if (_connectionStatus == ConnectivityResult.none) {
      await SQLHelper.deleteItem(int.parse(id)); // Delete from local database
      final filtered = items.where((element) => element['_id'] != id).toList();
      setState(() {
        items = filtered;
      });
    } else {
      final isSuccess =
          await TodoService.deleteById(id); // Delete from the server
      if (isSuccess) {
        final filtered =
            items.where((element) => element['_id'] != id).toList();
        setState(() {
          items = filtered;
        });
      } else {
        showErrorMessage(this.context, message: 'Deletion Failed');
      }
    }
  }

  Future<void> fetchTodo() async {
    final todos = await TodoService.fetchTodos();
    debugPrint(todos.toString());
    if (todos != null) {
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

      final abc = await database.delete("todos");

      debugPrint(abc.toString());

      for (final todo in todos) {
        final Map<String, dynamic> todoData = {
          '_id': todo['_id'],
          'title': todo['title'],
          'description': todo['description'],
          'date_time': todo['date_time'],
          'completed':
              todo['completed'] != null ? (todo['completed'] ? 1 : 0) : 0,
        };
        await database.insert('todos', todoData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      List<Map> result = await database.query("todos");

      setState(() {
        items = result;
      });

      await database.close();
    } else {
      // ignore: use_build_context_synchronously
      showErrorMessage(this.context, message: 'Something Went Wrong');
    }
    _refreshJournals();
  }

  Future<void> fetchTodoFromDb() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      join(databasePath, 'my_database.db'),
    );

    List<Map> result = await database.query("todos");

    setState(() {
      items = result;
    });

    await database.close();
  }

  void showSuccessMessage(String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(this.context).showSnackBar(snackBar);
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
