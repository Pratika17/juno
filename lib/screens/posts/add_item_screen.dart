import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/my_posts_provider.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  ItemCategory? _selectedCategory;
  ItemType _selectedType = ItemType.lost;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

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
          _selectedImage = File(pickedFile.path);
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitById() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      var user = authProvider.currentUserModel;

      if (user == null) {
        await authProvider.fetchCurrentUserModel();
        user = authProvider.currentUserModel;
      }

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'User profile not found. Please check your internet.',
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Generate ID first
      final String itemId = const Uuid().v4();

      String imageUrl = '';
      if (_selectedImage != null) {
        imageUrl = await StorageService()
            .uploadItemImage(_selectedImage!, itemId)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw Exception(
                  'Image upload timed out. Please check your internet connection.',
                );
              },
            );
      }

      final newItem = ItemModel(
        itemId: itemId,
        userId: user.userId,
        userName: user.name,
        userContact: '${user.email} / ${user.phone}',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        itemType: _selectedType,
        date: _selectedDate,
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
        status: ItemStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await DatabaseService()
          .createItem(newItem)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Posting item timed out. Please check your internet connection.',
              );
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item posted successfully!')),
        );

        // Refresh feeds
        Provider.of<ItemProvider>(context, listen: false).refreshItems();
        Provider.of<MyPostsProvider>(
          context,
          listen: false,
        ).fetchMyPosts(user.userId, forceRefresh: true);

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _locationController.clear();
        setState(() {
          _selectedImage = null;
          _selectedCategory = null;
          _selectedType = ItemType.lost;
          _selectedDate = DateTime.now();
        });

        // Only pop if we can (e.g., if this screen was pushed).
        // If it's a tab, we stay here or user manually switches.
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          // Optionally, we could try to switch to Home tab if we had access to a NavigationProvider.
          // For now, staying on the fresh form is safe.
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selection
              SegmentedButton<ItemType>(
                segments: const [
                  ButtonSegment(
                    value: ItemType.lost,
                    label: Text('Lost Object'),
                    icon: Icon(Icons.search),
                  ),
                  ButtonSegment(
                    value: ItemType.found,
                    label: Text('Found Object'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<ItemType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return _selectedType == ItemType.lost
                          ? Colors.red.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2);
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Image Picker
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                              });
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              CustomTextField(
                controller: _titleController,
                labelText: 'Title',
                hintText: 'e.g. Red iPhone 13',
                prefixIcon: const Icon(Icons.title),
                validator: (value) {
                  final reqErr = Validators.validateRequired(value, 'Title');
                  if (reqErr != null) return reqErr;
                  if (value!.length > 50)
                    return 'Title too long (max 50 chars)';
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
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Location
              CustomTextField(
                controller: _locationController,
                labelText: 'Location',
                hintText: 'e.g. Library 2nd Floor',
                prefixIcon: const Icon(Icons.location_on),
                validator: (value) =>
                    Validators.validateRequired(value, 'Location'),
              ),
              const SizedBox(height: 16),

              // Date Picker
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Describe the item in detail...',
                prefixIcon: const Icon(Icons.description),
                maxLines: 4,
                validator: (value) {
                  final reqErr = Validators.validateRequired(
                    value,
                    'Description',
                  );
                  if (reqErr != null) return reqErr;
                  if (value!.length > 500)
                    return 'Description too long (max 500 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Post Item',
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
