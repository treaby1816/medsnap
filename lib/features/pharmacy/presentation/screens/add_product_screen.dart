import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/product_model.dart';
import '../../../../widgets/glass_app_bar.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? existingProduct;
  const AddProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _maxStockController = TextEditingController();
  Uint8List? _imageBytes;
  String _imageExt = 'jpg';
  bool _isUploading = false;

  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameController.text = p.name;
      _priceController.text = p.price.toString();
      _stockController.text = '100'; // Default, we aren't loading it yet
      _maxStockController.text = '100'; // Default
      _existingImageUrl = p.imageUrl;
    }
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      String ext = pickedFile.name.split('.').last.toLowerCase();
      if (ext != 'png' && ext != 'jpg' && ext != 'jpeg') ext = 'jpg';
      setState(() {
        _imageBytes = bytes;
        _imageExt = ext;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && _existingImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a product photo')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final user = ref.read(authProvider);
      if (user == null) throw Exception('User not authenticated');

      final pharmacyService = ref.read(pharmacyServiceProvider);
      
      // 1. Upload Image via Bytes if new image selected
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await pharmacyService.uploadProductImageBytes(_imageBytes!, user.id, _imageExt);
      }

      // 2. Save Product to Firestore/Supabase
      final userProfile = ref.read(userProfileProvider).value;
      final storeName = userProfile?.storeName ?? 'Verified Pharmacy';

      final pData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stockCount': int.parse(_stockController.text.trim()),
        'imageUrl': imageUrl,
        'pharmacyId': user.id,
      };

      if (widget.existingProduct != null) {
        await pharmacyService.updateProduct(widget.existingProduct!.id, pData);
      } else {
        await pharmacyService.addProduct(pData);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingProduct != null ? 'Product updated successfully!' : 'Product added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _maxStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add New Product',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Upload Area
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Surface-Variant
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                    image: _imageBytes != null
                        ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.textTertiaryColor),
                            const SizedBox(height: 12),
                            Text(
                              'Upload Product Photo',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              // Form Fields
              _buildLabel('Product Name'),
              TextFormField(
                controller: _nameController,
                decoration: _fieldDecoration('e.g., Paracetamol 500mg'),
                validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Description'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _fieldDecoration('Share details about dosage, usage, etc...'),
                validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 20),

               _buildLabel('Price (₦)'),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('0.00').copyWith(
                  prefixText: '₦ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Price required' : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Current Stock'),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('e.g., 50'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Max Capacity'),
                        TextFormField(
                          controller: _maxStockController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('e.g., 500'),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Product',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9), // Surface-Variant
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
