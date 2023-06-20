import 'package:flutter/material.dart';

class TodoCard extends StatelessWidget {
  final int index;
  final Map item;
  final Function(Map) navigateEdit;
  final Function(String) deleteById;

  const TodoCard(
      {Key? key,
      required this.index,
      required this.item,
      required this.navigateEdit,
      required this.deleteById})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = item['_id'] as String;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
        title: Text(item['title']),
        subtitle: Text(item['description']),
        trailing: PopupMenuButton(onSelected: (value) {
          if (value == 'edit') {
            // open edit page
            navigateEdit(item);
          } else if (value == 'delete') {
            // delete and remove the item
            deleteById(id);
          }
        }, itemBuilder: (context) {
          return [
            const PopupMenuItem(
              value: 'edit',
              child: Text("Edit"),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text("Delete"),
            ),
          ];
        }),
      ),
    );
  }
}
