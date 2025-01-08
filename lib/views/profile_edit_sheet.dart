import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/expense_store.dart';

class ProfileEditSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ProfileEditSheet({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final store = Provider.of<ExpenseStore>(context, listen: false);
    _nameController = TextEditingController(text: store.profile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isProfilePicture) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final store = Provider.of<ExpenseStore>(context, listen: false);
      
      setState(() {
        if (isProfilePicture) {
          store.profile.imageData = bytes;
        } else {
          store.profile.backgroundImageData = bytes;
        }
      });
      
      store.synchronize();
    }
  }

  void _removeImage(bool isProfilePicture) {
    final store = Provider.of<ExpenseStore>(context, listen: false);
    setState(() {
      if (isProfilePicture) {
        store.profile.imageData = null;
      } else {
        store.profile.backgroundImageData = null;
      }
    });
    store.synchronize();
  }

  @override
  Widget build(BuildContext context) {
    final store = Provider.of<ExpenseStore>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name cannot be empty')),
                    );
                    return;
                  }
                  
                  final store = Provider.of<ExpenseStore>(context, listen: false);
                  store.profile.name = _nameController.text.trim();
                  store.synchronize();
                  widget.onClose();
                },
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Profile Picture Section
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: store.profile.imageData != null
                    ? MemoryImage(store.profile.imageData!)
                    : null,
                child: store.profile.imageData == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(true),
                    icon: const Icon(Icons.add_a_photo),
                    label: const Text('Change Profile Picture'),
                  ),
                  if (store.profile.imageData != null)
                    TextButton.icon(
                      onPressed: () => _removeImage(true),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Remove Picture',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Background Picture Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Background Picture',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (store.profile.backgroundImageData != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        store.profile.backgroundImageData!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        onPressed: () => _removeImage(false),
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => _pickImage(false),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Background Picture'),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Name Field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),

          // Add padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
} 