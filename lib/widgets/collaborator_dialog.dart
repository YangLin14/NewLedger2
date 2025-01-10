import 'package:flutter/material.dart';
import '../models/category.dart';
import '../providers/expense_store.dart';
import 'package:provider/provider.dart';

class CollaboratorDialog extends StatefulWidget {
  final ExpenseCategory category;
  final VoidCallback? onSaved;

  const CollaboratorDialog({
    Key? key,
    required this.category,
    this.onSaved,
  }) : super(key: key);

  @override
  State<CollaboratorDialog> createState() => _CollaboratorDialogState();
}

class _CollaboratorDialogState extends State<CollaboratorDialog> {
  final TextEditingController _nameController = TextEditingController();
  late List<String> _collaborators;

  @override
  void initState() {
    super.initState();
    _collaborators = List.from(widget.category.collaborators);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addCollaborator(String name) {
    if (name.isNotEmpty && !_collaborators.contains(name)) {
      setState(() {
        _collaborators.add(name);
      });
      _nameController.clear();
    }
  }

  void _removeCollaborator(String name) {
    setState(() {
      _collaborators.remove(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Collaborators for ${widget.category.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter collaborator name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addCollaborator(_nameController.text.trim()),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (value) => _addCollaborator(value.trim()),
            ),
            const SizedBox(height: 16),
            if (_collaborators.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No collaborators yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _collaborators.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          _collaborators[index][0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(_collaborators[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeCollaborator(_collaborators[index]),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final store = Provider.of<ExpenseStore>(context, listen: false);
            widget.category.collaborators = _collaborators;
            store.updateCategory(widget.category);
            widget.onSaved?.call();
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
} 