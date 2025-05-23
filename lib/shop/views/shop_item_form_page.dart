import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/l10n/l10n.dart';

import 'package:my_app/shop/shop.dart';

class ShopItemFormPage extends StatelessWidget {
  const ShopItemFormPage({
    required this.onSaved,
    required this.shop,
    required this.category,
    this.existingItem,
    super.key,
  });

  final ShopItemModel? existingItem;
  final void Function(ShopItemModel) onSaved;
  final ShopBloc shop;
  final CategoryBloc category;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: shop),
        BlocProvider.value(value: category),
      ],
      child: _ShopItemFormPageContent(
        onSaved: onSaved,
        existingItem: existingItem,
      ),
    );
  }
}

class _ShopItemFormPageContent extends StatefulWidget {
  const _ShopItemFormPageContent({
    required this.onSaved,
    this.existingItem,
  });

  final ShopItemModel? existingItem;
  final void Function(ShopItemModel) onSaved;

  @override
  State<_ShopItemFormPageContent> createState() => _ShopItemFormPageState();
}

class _ShopItemFormPageState extends State<_ShopItemFormPageContent>
    with ClipboardImageMixin<_ShopItemFormPageContent> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  CategoryItemModel? _categoryFilter;
  bool _hasChanges = false;

  late Map<String, String> _initialTextValues;
  late CategoryItemModel? _initialCategory;

  @override
  void initState() {
    super.initState();

    registerClipboardObserver();

    _controllers = {
      'name': TextEditingController(),
      'defaultPrice': TextEditingController(),
      'customerPrice': TextEditingController(),
      'sellerPrice': TextEditingController(),
      'note': TextEditingController(),
    };

    _initialTextValues = {};
    _initialCategory = null;

    context.read<ShopBloc>().upload.add(ClearImageEvent());

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _controllers['name']!.text = item.name;
      _controllers['defaultPrice']!.text = item.defaultPrice?.toString() ?? '';
      _controllers['customerPrice']!.text = item.customerPrice?.toString() ?? '';
      _controllers['sellerPrice']!.text = item.sellerPrice?.toString() ?? '';
      _controllers['note']!.text = item.note ?? '';
      _categoryFilter = item.category;

      _initialTextValues['name'] = item.name;
      _initialTextValues['defaultPrice'] = item.defaultPrice?.toString() ?? '';
      _initialTextValues['customerPrice'] = item.customerPrice?.toString() ?? '';
      _initialTextValues['sellerPrice'] = item.sellerPrice?.toString() ?? '';
      _initialTextValues['note'] = item.note ?? '';
      _initialCategory = item.category;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (item.imageUrl?.isNotEmpty ?? false) {
          context.read<ShopBloc>().upload.add(
                LoadExistingImageEvent(
                  imageUrl: item.imageUrl,
                ),
              );
        }
      });
    } else {
      _initialTextValues['name'] = '';
      _initialTextValues['defaultPrice'] = '';
      _initialTextValues['customerPrice'] = '';
      _initialTextValues['sellerPrice'] = '';
      _initialTextValues['note'] = '';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      forceCheckClipboardForImage();
    });

    _controllers.forEach((key, controller) {
      controller.addListener(_detectChanges);
    });
  }

  @override
  void onImageFound(File file) => showImagePreviewSnackBar(file);

  @override
  void onImageSelected(File file) {
    context.read<ShopBloc>().upload.add(SelectUiImageEvent(image: file));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _detectChanges();
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    unregisterClipboardObserver();
    super.dispose();
  }

  void _detectChanges() {
    final hasTextChanges = _controllers.entries.any(
      (entry) => entry.value.text != _initialTextValues[entry.key],
    );
    final hasCategoryChanges = _categoryFilter != _initialCategory;

    _hasChanges = hasTextChanges || hasCategoryChanges;
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final l10n = AppLocalizations.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.unsavedChanges, style: AppTextTheme.title),
        content: Text(l10n.confirmDiscardChanges, style: AppTextTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel, style: AppTextTheme.caption),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.discard, style: AppTextTheme.caption),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _submitItem() {
    if (!_formKey.currentState!.validate()) return;

    final shopBloc = context.read<ShopBloc>();
    final uploadBloc = shopBloc.upload;
    final item = ShopItemModel(
      id: widget.existingItem?.id ?? 0,
      name: _controllers['name']!.text,
      defaultPrice:
          _controllers['defaultPrice']!.text.isNotEmpty ? int.tryParse(_controllers['defaultPrice']!.text) : null,
      customerPrice:
          _controllers['customerPrice']!.text.isNotEmpty ? int.tryParse(_controllers['customerPrice']!.text) : null,
      sellerPrice:
          _controllers['sellerPrice']!.text.isNotEmpty ? int.tryParse(_controllers['sellerPrice']!.text) : null,
      note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
      imageUrl: uploadBloc.selectedImage?.path,
      category: _categoryFilter,
    );

    if (uploadBloc.selectedImage != null) {
      uploadBloc.add(UploadImageEvent(uploadBloc.selectedImage!));
    } else {
      if (widget.existingItem != null) {
        shopBloc.add(ShopEditItemEvent(body: item));
      } else {
        shopBloc.add(ShopCreateItemEvent(body: item));
      }
    }
  }

  Widget _buildTextField({
    required String key,
    required String label,
    bool required = false,
    bool isPrice = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLines,
    TextCapitalization? textCapitalization,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomTextFormField(
        onTapOutside: (_) {},
        controller: _controllers[key]!,
        hintText: '',
        textCapitalization: textCapitalization,
        labelText: required ? '$label *' : label,
        keyboardType: maxLines != null ? TextInputType.multiline : (isPrice ? TextInputType.number : keyboardType),
        action: textInputAction,
        useCustomBorder: false,
        validator: required ? (value) => value!.isEmpty ? l10n.nameRequired(label) : null : null,
        maxLines: maxLines ?? 1,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          labelStyle: AppTextTheme.body,
          suffixText: isPrice ? 'រៀល' : null,
          suffixStyle: isPrice ? AppTextTheme.caption : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existingItem != null ? l10n.editItem : l10n.addNewItem,
            style: AppTextTheme.title,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (!_hasChanges) {
                context.pop();
                return;
              }
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) context.pop();
            },
          ),
        ),
        body: Stack(
          children: [
            MultiBlocListener(
              listeners: [
                BlocListener<UploadBloc, UploadState>(
                  bloc: context.read<ShopBloc>().upload,
                  listener: (context, state) {
                    if (state is UploadSuccess) {
                      final shopBloc = context.read<ShopBloc>();
                      final item = ShopItemModel(
                        id: widget.existingItem?.id ?? 0,
                        name: _controllers['name']!.text,
                        defaultPrice: int.tryParse(_controllers['defaultPrice']!.text) ?? 0,
                        customerPrice: _controllers['customerPrice']!.text.isNotEmpty
                            ? int.tryParse(_controllers['customerPrice']!.text)
                            : null,
                        sellerPrice: _controllers['sellerPrice']!.text.isNotEmpty
                            ? int.tryParse(_controllers['sellerPrice']!.text)
                            : null,
                        note: _controllers['note']!.text.isEmpty ? null : _controllers['note']!.text,
                        imageUrl: state.imageUrl, // Use uploaded URL
                        category: _categoryFilter,
                      );
                      if (widget.existingItem != null) {
                        shopBloc.add(ShopEditItemEvent(body: item));
                      } else {
                        shopBloc.add(ShopCreateItemEvent(body: item));
                      }
                    } else if (state is UploadFailure) {
                      showErrorSnackBar(context, 'Upload failed: ${state.error}');
                    }
                  },
                ),
                BlocListener<ShopBloc, ShopState>(
                  listener: (context, state) {
                    if (state is ShopLoaded) context.pop();
                  },
                ),
              ],
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        textCapitalization: TextCapitalization.sentences,
                        key: 'name',
                        label: l10n.name,
                        required: true,
                      ),
                      _buildTextField(
                        key: 'customerPrice',
                        label: l10n.customerPrice,
                        isPrice: true,
                        required: true,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        key: 'defaultPrice',
                        isPrice: true,
                        label: l10n.defaultPrice,
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        key: 'sellerPrice',
                        label: l10n.sellerPrice,
                        isPrice: true,
                        keyboardType: TextInputType.number,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CategoryDropdown(
                          initialValue: widget.existingItem?.category,
                          onChanged: (value) {
                            _categoryFilter = value;
                            _detectChanges();
                          },
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 20,
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                        ),
                      ),
                      _buildTextField(
                        key: 'note',
                        maxLines: 3,
                        label: l10n.note,
                        textInputAction: TextInputAction.newline,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.image,
                              style: AppTextTheme.body,
                            ),
                            const SizedBox(height: 8),
                            BlocBuilder<UploadBloc, UploadState>(
                              bloc: context.read<ShopBloc>().upload,
                              builder: (context, state) {
                                final uploadBloc = context.read<ShopBloc>().upload;
                                return Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (state is UploadInProgress) return;
                                        uploadBloc.showImageSourceDialog(
                                          context,
                                          onTakePhoto: () => uploadBloc.add(
                                            SelectImageEvent(ImageSource.camera),
                                          ),
                                          onChoseFromGallery: () => uploadBloc.add(
                                            SelectImageEvent(ImageSource.gallery),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.upload),
                                      label: Text(
                                        l10n.uploadImage,
                                        style: AppTextTheme.body,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: colorScheme.onSurface,
                                        backgroundColor: colorScheme.surface,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    switch (state) {
                                      UploadImageSelected() => Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                state.selectedImage,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: .5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    uploadBloc.add(ClearImageEvent());
                                                    _detectChanges();
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      UploadImageUrlLoaded() => Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                state.imageUrl,
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                              ),
                                            ),
                                            Positioned(
                                              top: 5,
                                              right: 5,
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: .5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    uploadBloc.add(ClearImageEvent());
                                                    _detectChanges();
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      _ => const SizedBox.shrink(),
                                    },
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80), // Extra space for FAB
                      // Button removed from here
                    ],
                  ),
                ),
              ),
            ),
            KeyboardVisibilityBuilder(
              builder: (context, isKeyboardVisible) {
                if (!isKeyboardVisible) {
                  return Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: ElevatedButton(
                      onPressed: _submitItem,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(
                        widget.existingItem != null ? l10n.saveChanges : l10n.addItem,
                        style: AppTextTheme.body,
                      ),
                    ),
                  );
                } else {
                  return Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _submitItem,
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      label: Text(
                        widget.existingItem != null ? l10n.saveChanges : l10n.addItem,
                        style: AppTextTheme.body,
                      ),
                      icon: const Icon(Icons.save),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
