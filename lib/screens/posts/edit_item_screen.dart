import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/item_model.dart';
import '../../providers/item_provider.dart';
import '../../providers/my_posts_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditItemScreen extends StatefulWidget {
  final ItemModel item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late ItemCategory _selectedCategory;
  late ItemStatus _selectedStatus;
  File? _newImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _locationController = TextEditingController(text: widget.item.location);
    _selectedCategory = widget.item.category;
    _selectedStatus = widget.item.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _newImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitById() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String imageUrl = widget.item.imageUrl;

      // If new image selected, upload it
      if (_newImage != null) {
        // Delete old image if exists
        if (imageUrl.isNotEmpty) {
          await StorageService().deleteImage(imageUrl);
        }
        // Upload new
        imageUrl = await StorageService().uploadItemImage(
          _newImage!,
          widget.item.itemId,
        );
      }

      final updatedItem = widget.item.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory,
        status: _selectedStatus,
        imageUrl: imageUrl,
      );

      // Pass itemId and complete map or just the fields needed.
      // UpdateItem in service takes map.
      await DatabaseService().updateItem(
        updatedItem.itemId,
        updatedItem.toFirestore(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully!')),
        );

        // Refresh feeds
        Provider.of<ItemProvider>(context, listen: false).refreshItems();
        Provider.of<MyPostsProvider>(
          context,
          listen: false,
        ).fetchMyPosts(widget.item.userId);

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _newImage != null
                      ? Image.file(_newImage!, fit: BoxFit.cover)
                      : (widget.item.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.item.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Change Photo',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                prefixIcon: const Icon(Icons.title),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a title';
                  if (value.length > 50) return 'Title too long';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<ItemCategory>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(
                      category.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),

              // Location
              CustomTextField(
                controller: _locationController,
                labelText: 'Location',
                prefixIcon: const Icon(Icons.location_on),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a location';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<ItemStatus>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ItemStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.toString().split('.').last.toUpperCase(),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                prefixIcon: const Icon(Icons.description),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a description';
                  if (value.length > 500) return 'Description too long';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Update Item',
                onPressed: _submitById,
                isLoading: _isLoading,
                backgroundColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
