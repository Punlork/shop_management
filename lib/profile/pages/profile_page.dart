import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/l10n/l10n.dart';
import 'package:my_app/profile/profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        final bloc = context.read<ProfileBloc>();
        if (state is Authenticated && (bloc.state.asLoaded?.isSuccess ?? false)) {
          showSuccessSnackBar(
            context,
            context.l10n.profileUpdated,
          );
          bloc.add(ResetProfile());
        }
      },
      builder: (context, state) => _ProfilePageContent(state.asAuthenticated?.user),
    );
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent(this.user);
  final User? user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayNameController = TextEditingController(text: user?.name);
    final usernameController = TextEditingController(text: user?.username);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (user?.image?.isNotEmpty ?? false) {
          context.read<ProfileBloc>().upload.add(
                LoadExistingImageEvent(imageUrl: user?.image),
              );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.profile,
          style: AppTextTheme.headline,
        ),
      ),
      body: BlocListener<UploadBloc, UploadState>(
        bloc: context.read<ProfileBloc>().upload,
        listener: (context, state) {
          if (state is UploadSuccess) {
            final newDisplayName = displayNameController.text.trim();
            final newUsername = usernameController.text.trim();

            context.read<ProfileBloc>().add(
                  UpdateProfile(
                    name: newDisplayName,
                    image: state.imageUrl,
                    username: newUsername,
                  ),
                );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileStateData) {
                context.read<AuthBloc>().add(AuthCheckRequested());
              }
            },
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.editProfile,
                  style: AppTextTheme.title,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final bloc = context.read<ProfileBloc>().upload;
                      bloc.showImageSourceDialog(
                        context,
                        onChoseFromGallery: () => bloc.add(SelectImageEvent(ImageSource.gallery)),
                        onTakePhoto: () => bloc.add(SelectImageEvent(ImageSource.camera)),
                      );
                    },
                    child: Stack(
                      children: [
                        BlocBuilder<UploadBloc, UploadState>(
                          bloc: context.read<ProfileBloc>().upload,
                          builder: (context, uploadState) => switch (uploadState) {
                            UploadImageSelected() => ClipOval(
                                child: Image.file(
                                  uploadState.selectedImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                            UploadImageUrlLoaded() => ClipOval(
                                child: Image.network(
                                  uploadState.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                            _ => const CircleAvatar(
                                radius: 50,
                                child: Icon(Icons.person, size: 50),
                              ),
                          },
                        ),
                        Positioned(
                          right: 5,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  hintText: '',
                  labelText: l10n.displayName,
                  controller: displayNameController,
                  useCustomBorder: false,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextFormField(
                  hintText: '',
                  labelText: l10n.name,
                  controller: usernameController,
                  useCustomBorder: false,
                  decoration: const InputDecoration(
                    enabled: false,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final profileBloc = context.read<ProfileBloc>();
                    final uploadBloc = profileBloc.upload;

                    final newDisplayName = displayNameController.text.trim();
                    final newUsername = usernameController.text.trim();

                    if (uploadBloc.selectedImage != null) {
                      uploadBloc.add(UploadImageEvent(uploadBloc.selectedImage!));
                    } else {
                      if (newDisplayName.isEmpty || newUsername.isEmpty) return;
                      context.read<ProfileBloc>().add(
                            UpdateProfile(
                              name: newDisplayName,
                              image: user?.image,
                              username: newUsername,
                            ),
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text(
                    l10n.save,
                    style: AppTextTheme.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
