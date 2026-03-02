import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/models/memory.dart';
import 'package:travel_app/provider/memory_provider.dart';

class AddMemoryPage extends StatefulWidget {
  final Memory? existing;
  const AddMemoryPage({super.key, this.existing});

  @override
  State<AddMemoryPage> createState() => _AddMemoryPageState();
}

class _AddMemoryPageState extends State<AddMemoryPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;

  late final TextEditingController _captionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _localImagePathController;
  late final TextEditingController _imageUrlController;

  DateTime? _assignedAt;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    _captionController = TextEditingController(text: widget.existing?.caption ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    _localImagePathController = TextEditingController(text: widget.existing?.localImagePath ?? '');
    _imageUrlController = TextEditingController(text: widget.existing?.imageUrl ?? '');
    _assignedAt = widget.existing?.assignedAt;

    // preload a local preview if editing and local path exists
    if (_localImagePathController.text.trim().isNotEmpty) {
      _pickedImage = XFile(_localImagePathController.text.trim());
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
    _localImagePathController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickAssignedDate() async {
    final initial = _assignedAt ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _assignedAt = picked);
  }

  Future<void> _pickFromGallery() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (img == null) return;

    setState(() {
      _pickedImage = img;
      _localImagePathController.text = img.path;
      _imageUrlController.text = ''; // local overrides url for now
    });
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (img == null) return;

    setState(() {
      _pickedImage = img;
      _localImagePathController.text = img.path;
      _imageUrlController.text = '';
    });
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Tap to choose';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildImagePreview() {
    final url = _imageUrlController.text.trim();
    final path = _localImagePathController.text.trim();

    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder('Could not load imageUrl'),
        ),
      );
    }

    if (path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return _placeholder('No image selected');
  }

  Widget _placeholder(String text) {
    return Container(
      height: 200,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_assignedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date.')),
      );
      return;
    }

    // Require either local image or url
    final hasLocal = _localImagePathController.text.trim().isNotEmpty;
    final hasUrl = _imageUrlController.text.trim().isNotEmpty;
    if (!hasLocal && !hasUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image.')),
      );
      return;
    }

    final provider = context.read<MemoryProvider>();
    final now = DateTime.now();

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        caption: _captionController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedAt: _assignedAt!,
        localImagePath: _localImagePathController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      );

      provider.updateMemoryLocal(updated);

      // Later: upload image if localImagePath changed, then set imageUrl and clear local path if you want.
    } else {
      final created = Memory(
        id: now.millisecondsSinceEpoch.toString(),
        caption: _captionController.text.trim(),
        description: _descriptionController.text.trim(),
        createdAt: now,
        assignedAt: _assignedAt!,
        localImagePath: _localImagePathController.text.trim(),
        imageUrl: _imageUrlController.text.trim(), // probably '' for now
      );

      provider.addMemoryLocal(created);

      // Optional: Firestore now (you may want to store both fields)
      // await provider.addEntryToFirestore(created);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Memory' : 'Add Memory'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImagePreview(),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo),
                      label: const Text('Choose Photo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // keep these read-only for now (you can hide them entirely if you want)
              TextFormField(
                controller: _localImagePathController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Local image path (temporary)',
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _imageUrlController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Firebase later)',
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(labelText: 'Caption'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Caption is required' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 5,
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Memory date'),
                subtitle: Text(_dateLabel(_assignedAt)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickAssignedDate,
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'Save Changes' : 'Create Memory'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
