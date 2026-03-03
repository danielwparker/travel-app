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

  DateTime? _assignedAt;
  bool _isUploading = false; // To show a loading indicator during upload

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    _captionController = TextEditingController(text: widget.existing?.caption ?? '');
    _descriptionController = TextEditingController(text: widget.existing?.description ?? '');
    _assignedAt = widget.existing?.assignedAt;

    if (widget.existing?.localImagePath.trim().isNotEmpty ?? false) {
      _pickedImage = XFile(widget.existing!.localImagePath);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _descriptionController.dispose();
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
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img == null) return;

    setState(() {
      _pickedImage = img;
    });
  }

  Future<void> _pickFromCamera() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img == null) return;

    setState(() {
      _pickedImage = img;
    });
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Tap to choose';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Widget _buildImagePreview() {
    if (_isUploading) {
      return Container(
        height: 200,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const CircularProgressIndicator(),
      );
    }

    if (_pickedImage != null && File(_pickedImage!.path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_pickedImage!.path),
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_isEdit && (widget.existing!.imageUrl.isNotEmpty)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.existing!.imageUrl,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder('Could not load image'),
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
        const SnackBar(content: Text('Please choose a memory date')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final provider = context.read<MemoryProvider>();
    final now = DateTime.now();
    final memoryId = _isEdit ? widget.existing!.id : now.millisecondsSinceEpoch.toString();

    final memory = Memory(
      id: memoryId,
      caption: _captionController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: _isEdit ? widget.existing!.createdAt : now,
      assignedAt: _assignedAt!,
      localImagePath: _pickedImage?.path ?? '',
      imageUrl: widget.existing?.imageUrl ?? '',
    );

    try {
      // Handles image upload (if local path exists) and Firestore update
      await provider.addOrUpdateMemory(memory);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving memory: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save memory')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Memory' : 'Add Memory'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
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
              TextFormField(
                controller: _captionController,
                decoration: const InputDecoration(labelText: 'Caption'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Caption is required' : null,
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