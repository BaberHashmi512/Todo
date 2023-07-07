// void _showForm(int? id) async {
//   if (id != null) {
//     final existingJournal =
//         _journals.firstWhere((element) => element['id'] == id);
//     titleController.text = existingJournal['title'];
//     descriptionController.text = existingJournal['description'];
//   }
// }

// Future<void> _addItem() async {
//   await SQLHelper.createItem(
//     titleController.text,
//     descriptionController.text,
//   );
//   _refreshJournals();
//   print("..number of items ${_journals.length}");
// }

// Future<void> fetchDataAndSaveToDatabase() async {
//   final response = await http
//       .get(Uri.parse('https://api.nstack.in/v1/todos?page=1&limit=10'));
//
//   if (response.statusCode == 200) {
//     final Map<String, dynamic> responseData = jsonDecode(response.body);
//
//     if (responseData.containsKey('items')) {
//       final List<dynamic> todos = responseData['items'];
//
//       final databasePath = await getDatabasesPath();
//       final database = await openDatabase(
//         join(databasePath, 'my_database.db'),
//         onCreate: (db, version) {
//           db.execute('''
//           CREATE TABLE IF NOT EXISTS todos (
//             id INTEGER PRIMARY KEY,
//             _id TEXT,
//             title TEXT,
//             description TEXT,
//             completed INTEGER)''');
//           print("Baber");
//         },
//         version: 1,
//       );
//
//       database.delete("todos");
//
//       for (final todo in todos) {
//         final Map<String, dynamic> todoData = {
//           '_id': todo['_id'],
//           'title': todo['title'],
//           'description': todo['description'],
//           'completed':
//               todo['completed'] != null ? (todo['completed'] ? 1 : 0) : 0,
//         };
//         await database.insert('todos', todoData,
//             conflictAlgorithm: ConflictAlgorithm.replace);
//       }
//
//       await database.close();
//       print("Ali");
//     } else {
//       print('No "data" key found in the API response.');
//     }
//   } else {
//     print(
//         'Failed to fetch data from the API. Status code: ${response.statusCode}');
//   }
// }
// ................

// Future<void> _updateConnectionStatus(ConnectivityResult result) async {
//   if (result != _connectionStatus) {
//     setState(() {
//       _connectionStatus = result;
//     });
//
//     if (result == ConnectivityResult.none) {
//       showDialog(
//         context: this.context,
//         builder: (
//             BuildContext context) {
//           return const NoInternetDialog();
//         },
//       );
//     } else {
//       setState(() {
//         isLoading = true;
//       });
//       await fetchTodo();
//     }
//   }
// }

