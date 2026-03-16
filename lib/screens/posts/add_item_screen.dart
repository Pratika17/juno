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

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
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

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: AppTextStyles.bodyTextSecondary.copyWith(
          color: isDark ? Colors.white70 : Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create ad', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection
              _buildFieldLabel('Category', isDark),
              DropdownButtonFormField<ItemCategory>(
                value: _selectedCategory,
                hint: Text('Select category', style: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 13)),
                items: ItemCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                decoration: const InputDecoration(), // Uses standard theme
              ),
              const SizedBox(height: 24),

              // Post Type (Lost / Found)
              _buildFieldLabel('Post Type', isDark),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == ItemType.lost ? AppColors.primary : (isDark ? AppColors.darkSurface : Colors.grey[200]),
                        foregroundColor: _selectedType == ItemType.lost ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Slightly pill
                      ),
                      onPressed: () {
                        setState(() => _selectedType = ItemType.lost);
                      },
                      child: const Text('Lost'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == ItemType.found ? AppColors.secondary : (isDark ? AppColors.darkSurface : Colors.grey[200]),
                        foregroundColor: _selectedType == ItemType.found ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() => _selectedType = ItemType.found);
                      },
                      child: const Text('Found'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title
              _buildFieldLabel('Title', isDark),
              CustomTextField(
                controller: _titleController,
                hintText: 'A title needs at least 10 characters',
                validator: (value) {
                  final reqErr = Validators.validateRequired(value, 'Title');
                  if (reqErr != null) return reqErr;
                  if (value!.length > 50) return 'Title too long';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description
              _buildFieldLabel('Description', isDark),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'How to get in contact with the owner etc',
                maxLines: 3,
                validator: (value) {
                  return Validators.validateRequired(value, 'Description');
                },
              ),
              const SizedBox(height: 24),

              // Location (Mislabelled as Category in image, but using proper label)
              _buildFieldLabel('Location', isDark),
              CustomTextField(
                controller: _locationController,
                hintText: 'Where item was found or lost',
                validator: (value) => Validators.validateRequired(value, 'Location'),
              ),
              const SizedBox(height: 24),

              // Image Picker Box
              _buildFieldLabel('Photo', isDark),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
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
                            Icon(Icons.camera_alt_outlined, size: 40, color: isDark ? Colors.white54 : Colors.black45),
                            const SizedBox(height: 8),
                            Text(
                              'Take a photo or upload an image',
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(backgroundColor: Colors.black45),
                            onPressed: () {
                              setState(() => _selectedImage = null);
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Date Picker (Optional if needed, but keeping it)
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('Date', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                   TextButton(
                     onPressed: _selectDate,
                     child: Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                   ),
                 ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _submitById,
                  child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
