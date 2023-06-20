import 'package:flutter/material.dart';
import 'package:todo/services/todo_service.dart';
import 'package:todo/utils/snackbar_helper.dart';

class AddTodoPage extends StatefulWidget {
  final Map? todo;

  const AddTodoPage({Key? key, this.todo}) : super(key: key);

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
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
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: isEdit ? updateData : submitData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(isEdit ? 'Update' : "Submit"),
              ))
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
      showSuccessMessage(context, message: 'Update Success');
    } else {
      // ignore: use_build_context_synchronously
      showErrorMessage(context, message: 'Updation Failed');
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
      showSuccessMessage(context, message: 'Creation Success');
    } else {
      // ignore: use_build_context_synchronously
      showErrorMessage(context, message: 'Creation Failed');
    }
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
