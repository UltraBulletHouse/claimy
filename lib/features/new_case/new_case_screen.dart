import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:claimy/core/api/complaints_api.dart';
import 'package:claimy/core/api/uploads_api.dart';
import 'package:file_picker/file_picker.dart';

import 'package:claimy/core/theme/app_colors.dart';
import 'package:claimy/state/app_state.dart';

class NewCaseScreen extends StatefulWidget {
  const NewCaseScreen({super.key});

  @override
  State<NewCaseScreen> createState() => _NewCaseScreenState();
}

class _NewCaseScreenState extends State<NewCaseScreen> {
  static const int _stepsCount = 3;
  static const List<_StoreBrand> _storeBrands = [
    _StoreBrand(
      name: 'FreshMart Market',
      primaryColor: Color(0xFF34C759),
      icon: Icons.shopping_basket,
    ),
    _StoreBrand(
      name: 'TechTown',
      primaryColor: Color(0xFF0B84FF),
      icon: Icons.devices_other,
    ),
    _StoreBrand(
      name: 'HomeGoods Depot',
      primaryColor: Color(0xFFFF8C42),
      icon: Icons.weekend,
    ),
    _StoreBrand(
      name: 'Daily Grains',
      primaryColor: Color(0xFFB48A2C),
      icon: Icons.restaurant_menu,
    ),
    _StoreBrand(
      name: 'Beauty Loft',
      primaryColor: Color(0xFFFF6FB7),
      icon: Icons.spa,
    ),
  ];

  int _currentStep = 0;
  String? _selectedStore;
  bool _customStore = false;
  final TextEditingController _customStoreController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _productPhotoAdded = false;
  bool _receiptPhotoAdded = false;

  Uint8List? _productBytes;
  Uint8List? _receiptBytes;

  String? _productPreviewDataUrl;
  String? _receiptPreviewDataUrl;

  bool _uploading = false;

  @override
  void dispose() {
    _customStoreController.dispose();
    _productController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_validateCurrentStep()) {
      FocusScope.of(context).unfocus();
      setState(() => _currentStep++);
    }
  }

  void _goBack() {
    setState(() => _currentStep--);
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if ((_selectedStore == null || _selectedStore!.isEmpty) &&
            _customStoreController.text.trim().isEmpty) {
          _showMessage('Select a store to continue.');
          return false;
        }
        return true;
      case 1:
        if (_productController.text.trim().isEmpty) {
          _showMessage('Tell us the product name.');
          return false;
        }
        if (!_productPhotoAdded || !_receiptPhotoAdded) {
          _showMessage('Please add both photos before continuing.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSubmitting = false;

  void _handlePrimaryAction() {
    if (_currentStep == _stepsCount - 1) {
      _submit();
    } else {
      _goNext();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (!_validateCurrentStep()) {
        return;
      }
      final store = _customStore
          ? _customStoreController.text.trim()
          : _selectedStore!;
      final product = _productController.text.trim();
      final description = _descriptionController.text.trim();

      String? productUrl;
      String? receiptUrl;

      // Upload images first if present
      try {
        if (_productBytes != null || _receiptBytes != null) {
          setState(() => _uploading = true);
          final uploader = UploadsApi();
          final res = await uploader.uploadImages(
            productBytes: _productBytes,
            receiptBytes: _receiptBytes,
          );
          productUrl = res.productImageUrl;
          receiptUrl = res.receiptImageUrl;
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        return;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }

      // Submit to backend
      try {
        final api = ComplaintsApi();
        final images = <String>[
          if (productUrl != null) productUrl,
          if (receiptUrl != null) receiptUrl,
        ];
        final result = await api.submitComplaint(
          store: store,
          product: product,
          description: description.isEmpty ? null : description,
          images: images,
        );
        if (result.ok) {
          await context.read<AppState>().createCase(
            storeName: store,
            productName: product,
            description: description,
            includedProductPhoto: _productPhotoAdded,
            includedReceiptPhoto: _receiptPhotoAdded,
            alreadySubmitted: true,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Claim submitted successfully.')),
          );
          Navigator.of(context).pop(true);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Submission failed.')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New claim')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(
                currentStep: _currentStep,
                totalSteps: _stepsCount,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStepContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ).copyWith(bottom: 16),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goBack,
                    child: const Text('Back'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 12),
              Expanded(
                flex: _currentStep > 0 ? 2 : 1,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _uploading)
                      ? null
                      : _handlePrimaryAction,
                  child: (_isSubmitting || _uploading)
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _currentStep == _stepsCount - 1
                              ? 'Submit claim'
                              : 'Continue',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _StoreStep(
          stores: _storeBrands,
          selectedStore: _selectedStore,
          customStore: _customStore,
          customStoreController: _customStoreController,
          onStoreChanged: (value) {
            setState(() {
              if (value == '_custom_') {
                _selectedStore = null;
                _customStore = true;
              } else {
                _selectedStore = value;
                _customStore = false;
              }
            });
          },
        );
      case 1:
        return _ProductStep(
          controller: _productController,
          productPhotoAdded: _productPhotoAdded,
          receiptPhotoAdded: _receiptPhotoAdded,
          productPreviewDataUrl: _productPreviewDataUrl,
          receiptPreviewDataUrl: _receiptPreviewDataUrl,
          onPickProduct: (bytes, preview) {
            setState(() {
              _productBytes = bytes;
              _productPreviewDataUrl = preview;
              _productPhotoAdded = bytes != null;
            });
          },
          onPickReceipt: (bytes, preview) {
            setState(() {
              _receiptBytes = bytes;
              _receiptPreviewDataUrl = preview;
              _receiptPhotoAdded = bytes != null;
            });
          },
        );
      case 2:
        return _NotesStep(controller: _descriptionController);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StoreStep extends StatelessWidget {
  const _StoreStep({
    required this.stores,
    required this.selectedStore,
    required this.customStore,
    required this.customStoreController,
    required this.onStoreChanged,
  });

  final List<_StoreBrand> stores;
  final String? selectedStore;
  final bool customStore;
  final TextEditingController customStoreController;
  final ValueChanged<String> onStoreChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where did you buy it?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the store so we can route your claim to the right team.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final store in stores)
              _StoreSelectionButton(
                brand: store,
                isSelected: selectedStore == store.name,
                onTap: () => onStoreChanged(store.name),
              ),
            _OtherStoreButton(
              isSelected: customStore,
              onTap: () => onStoreChanged('_custom_'),
            ),
          ],
        ),
        if (customStore) ...[
          const SizedBox(height: 16),
          TextField(
            controller: customStoreController,
            decoration: const InputDecoration(
              labelText: 'Store name',
              hintText: 'Type the store name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StoreBrand {
  const _StoreBrand({
    required this.name,
    required this.primaryColor,
    required this.icon,
  });

  final String name;
  final Color primaryColor;
  final IconData icon;
}

class _StoreSelectionButton extends StatelessWidget {
  const _StoreSelectionButton({
    required this.brand,
    required this.isSelected,
    required this.onTap,
  });

  final _StoreBrand brand;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = brand.primaryColor;
    final Color background = isSelected ? accent : fadeColor(accent, 0.12);
    final Color foreground = isSelected ? Colors.white : accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: fadeColor(accent, 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isSelected
                    ? fadeColor(Colors.white, 0.18)
                    : Colors.white,
                child: Icon(brand.icon, color: foreground, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                brand.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OtherStoreButton extends StatelessWidget {
  const _OtherStoreButton({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = AppColors.primary;
    final Color background = isSelected ? accent : fadeColor(accent, 0.12);
    final Color foreground = isSelected ? Colors.white : accent;
    final Color avatarBackground = isSelected
        ? fadeColor(Colors.white, 0.18)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: background,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: fadeColor(accent, 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: avatarBackground,
                child: Icon(Icons.add, color: foreground, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Other store',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductStep extends StatelessWidget {
  const _ProductStep({
    required this.controller,
    required this.productPhotoAdded,
    required this.receiptPhotoAdded,
    required this.onPickProduct,
    required this.onPickReceipt,
    this.productPreviewDataUrl,
    this.receiptPreviewDataUrl,
  });

  final TextEditingController controller;
  final bool productPhotoAdded;
  final bool receiptPhotoAdded;
  final void Function(Uint8List? bytes, String? preview) onPickProduct;
  final void Function(Uint8List? bytes, String? preview) onPickReceipt;
  final String? productPreviewDataUrl;
  final String? receiptPreviewDataUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s the product?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Be specific so the store can identify it quickly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Product name',
            hintText: 'e.g. Organic almond milk 1L',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Add your photos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload a product photo and the receipt so we can verify your claim.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _PhotoBox(
                label: 'Product photo',
                added: productPhotoAdded,
                previewDataUrl: productPreviewDataUrl,
                onSelected: onPickProduct,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _PhotoBox(
                label: 'Receipt photo',
                added: receiptPhotoAdded,
                previewDataUrl: receiptPreviewDataUrl,
                onSelected: onPickReceipt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    required this.label,
    required this.added,
    required this.onSelected,
    this.previewDataUrl,
  });

  final String label;
  final bool added;
  final void Function(Uint8List? bytes, String? preview) onSelected;
  final String? previewDataUrl;

  bool _isValidImage(String name, int size) {
    final lower = name.toLowerCase();
    final okExt =
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
    if (!okExt) return false;
    // 5 MB limit
    if (size > 5 * 1024 * 1024) return false;
    return true;
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      if (!_isValidImage(file.name, file.size)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please choose an image under 5 MB (jpg, png, webp).',
            ),
          ),
        );
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to read the selected file.')),
        );
        return;
      }
      final preview = 'data:image/*;base64,${base64Encode(bytes)}';
      onSelected(bytes, preview);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _pickFile(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 150,
        decoration: BoxDecoration(
          color: added ? fadeColor(AppColors.success, 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: added
                ? AppColors.success
                : fadeColor(AppColors.textPrimary, 0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              added ? Icons.check_circle_rounded : Icons.add_a_photo_rounded,
              color: added ? AppColors.success : AppColors.textPrimary,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              added ? 'Photo added' : 'Tap to add',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: fadeColor(AppColors.textPrimary, 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesStep extends StatelessWidget {
  const _NotesStep({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anything else?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Let us know what happened. Keep it short and friendly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Optional note',
            hintText: 'Tell us what went wrong so we can fix it.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            height: 10,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : darkenColor(AppColors.surface, 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }),
    );
  }
}
