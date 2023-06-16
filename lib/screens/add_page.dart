import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddTodoPage extends StatefulWidget {
  final Map? todo;
  const AddTodoPage({Key? key,this.todo}) : super(key: key);

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isEdit=false;
  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    if (todo != null){
      isEdit=true;
      final title = todo ['title'];
      final description = todo ['description'];
      titleController.text= title;
      descriptionController.text=description;

    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text(
            isEdit ? 'Edit Todo':"Add Todo"),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(
              hintText: "Title"
            ),
          ),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(
                hintText: "Description"
            ),
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            maxLength: 8,
          ),
          SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed:isEdit ? updateData : submitData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                    isEdit ? 'Update':"Submit"),
              )
          )
        ],
      ),
    );
  }
  Future<void> updateData()async{
    final todo = widget.todo;
    if(todo ==null){
      print('you not call update without to do data');
      return;
    }
    final id = todo['_id'];
    final isCompleted= todo['is_completed'];
    final title = titleController.text;
    final description = descriptionController.text;
    final body = {
      "title" : title,
      "description" : description,
      "is_completed" : false,
    };
    final url = 'https://api.nstack.in/v1/todos/63236cbf2503b8760620387d';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body),headers: {'Content-Type': 'application/json'});

  }
  Future <void> submitData() async {
    // Get the Data From Form
    final title = titleController.text;
    final description = descriptionController.text;
    final body = {
      "title" : title,
      "description" : description,
      "is_completed" : false,
    };
    // Submit data to the Server
    final url = 'https://api.nstack.in/v1/todos';
    final uri = Uri.parse(url);
    final response = await http.post(uri, body: jsonEncode(body),headers: {'Content-Type': 'application/json'});
    // show success or failed message based on the success
    if(response.statusCode == 201){
      titleController.text='';
      descriptionController.text='';
      showSuccessMessage('Creation Success');
    }else{
      showErrorMessage('Creation Failed');
    }
  }
  void showSuccessMessage(String message){
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  void showErrorMessage(String message){
    final snackBar = SnackBar(content: Text(message,
    style: TextStyle(
      color: Colors.white
    ),
    ),
    backgroundColor: Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
