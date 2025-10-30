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
  static const int _stepsCount = 2;
  List<_StoreBrand> _storeBrands = const [];

  int _currentStep = 0;
  String? _selectedStoreId;
  String? _selectedStoreName;
  bool _storesLoading = false;
  String? _storesError;
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
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    if (_storesLoading) {
      return;
    }
    setState(() {
      _storesLoading = true;
      _storesError = null;
    });

    List<_StoreBrand> nextStores = const [];
    String? loadError;

    try {
      final api = ComplaintsApi();
      final entries = await api.getStoreCatalog();
      nextStores = entries
          .map(
            (entry) => _StoreBrand(
              storeId: entry.storeId,
              name: entry.name,
              primaryColor: _parseColor(entry.primaryColor),
              secondaryColor: _parseColor(entry.secondaryColor),
              email: entry.email,
            ),
          )
          .toList(growable: false);
    } catch (err) {
      loadError = err.toString();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _storesLoading = false;
      if (loadError != null) {
        _storesError = loadError;
      } else {
        _storesError = null;
        _storeBrands = nextStores;
        if (_storeBrands.isEmpty) {
          _selectedStoreId = null;
          _selectedStoreName = null;
        } else if (_selectedStoreId != null) {
          final matches = _storeBrands
              .where((store) => store.storeId == _selectedStoreId)
              .toList();
          if (matches.isEmpty) {
            _selectedStoreId = null;
            _selectedStoreName = null;
          } else {
            _selectedStoreName = matches.first.name;
          }
        }
      }
    });

    if (loadError != null && mounted) {
      _showMessage('Failed to load stores: $loadError');
    }
  }

  Color _parseColor(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return AppColors.primary;
    }

    String hex = trimmed;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    } else if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }

    if (hex.length == 6) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(0xFF000000 | parsed);
      }
    } else if (hex.length == 8) {
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return AppColors.primary;
  }

  @override
  void dispose() {
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
        final hasSelection =
            _selectedStoreId != null &&
            (_selectedStoreName?.isNotEmpty ?? false);
        if (!hasSelection) {
          _showMessage('Select a store to continue.');
          return false;
        }
        if (_productController.text.trim().isEmpty) {
          _showMessage('Tell us the product name.');
          return false;
        }
        return true;
      case 1:
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
      final store = _selectedStoreName ?? '';
      if (store.isEmpty) {
        _showMessage('Select a store to continue.');
        return;
      }
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
          selectedStoreId: _selectedStoreId,
          productController: _productController,
          onStoreChanged: (value) {
            setState(() {
              final matches = _storeBrands
                  .where((store) => store.storeId == value)
                  .toList();
              if (matches.isEmpty) {
                _selectedStoreId = null;
                _selectedStoreName = null;
              } else {
                _selectedStoreId = value;
                _selectedStoreName = matches.first.name;
              }
            });
          },
          isLoading: _storesLoading,
          error: _storesError,
          onRetry: () {
            _loadStores();
          },
        );
      case 1:
        return _DetailsStep(
          descriptionController: _descriptionController,
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
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StoreStep extends StatelessWidget {
  const _StoreStep({
    required this.stores,
    required this.selectedStoreId,
    required this.productController,
    required this.onStoreChanged,
    required this.isLoading,
    required this.onRetry,
    this.error,
  });

  final List<_StoreBrand> stores;
  final String? selectedStoreId;
  final TextEditingController productController;
  final ValueChanged<String> onStoreChanged;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where did you buy it?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the store so we can route your claim to the right team.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        if (isLoading && stores.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (!isLoading && error == null && stores.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fadeColor(AppColors.info, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No stores are configured yet. Ask support to configure store options.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: fadeColor(AppColors.textPrimary, 0.8),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (error != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fadeColor(AppColors.danger, 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We couldn\'t refresh the store list. Please retry or try again shortly.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (isLoading && stores.isNotEmpty) ...[
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 16),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < stores.length; i++) ...[
              _StoreSelectionButton(
                brand: stores[i],
                isSelected: selectedStoreId == stores[i].storeId,
                onTap: () => onStoreChanged(stores[i].storeId),
                expand: true,
              ),
              if (i != stores.length - 1) const SizedBox(height: 12),
            ],
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'What did you buy?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Be specific so the store can identify the product quickly.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: productController,
          decoration: const InputDecoration(
            labelText: 'Product name',
            hintText: 'e.g. Organic almond milk 1L',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StoreBrand {
  const _StoreBrand({
    required this.storeId,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.email,
  });

  final String storeId;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final String email;

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _StoreSelectionButton extends StatelessWidget {
  const _StoreSelectionButton({
    required this.brand,
    required this.isSelected,
    required this.onTap,
    this.expand = false,
  });

  final _StoreBrand brand;
  final bool isSelected;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color primary = brand.primaryColor;
    final Color secondary = brand.secondaryColor;
    final Color background = primary;
    final Color foreground = secondary;
    final Color borderColor = isSelected
        ? secondary
        : fadeColor(secondary, 0.4);
    final double fontSize = isSelected ? 20 : 18;
    final TextStyle nameStyle =
        (textTheme.bodyMedium ?? TextStyle(fontSize: fontSize)).copyWith(
          fontSize: fontSize,
          color: foreground,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        );

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: isSelected ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: fadeColor(primary, isSelected ? 0.45 : 0.18),
            blurRadius: isSelected ? 18 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSelected ? 36 : 0),
            child: Text(
              brand.name,
              style: nameStyle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSelected)
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.check_circle, color: foreground, size: 22),
            ),
        ],
      ),
    );

    if (expand) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: button,
      ),
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.descriptionController,
    required this.productPhotoAdded,
    required this.receiptPhotoAdded,
    required this.onPickProduct,
    required this.onPickReceipt,
    this.productPreviewDataUrl,
    this.receiptPreviewDataUrl,
  });

  final TextEditingController descriptionController;
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
          'Describe what happened',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Let us know what went wrong. Keep it short and friendly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: fadeColor(AppColors.textPrimary, 0.7),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: descriptionController,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Describe the issue (optional)',
            hintText: 'Tell us what went wrong so we can fix it.',
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
