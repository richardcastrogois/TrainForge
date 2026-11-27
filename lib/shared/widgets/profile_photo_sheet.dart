import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trainforge/core/theme/trainforge_theme.dart';
import 'package:trainforge/features/auth/data/auth_repository.dart';
import 'package:trainforge/features/auth/data/profile_photos.dart';
import 'package:trainforge/features/auth/presentation/auth_controller.dart';

import 'glass_sheet.dart';
import 'shell_labels.dart';

/// Change the profile picture: gallery, camera, the Google picture again,
/// or remove the chosen one. Everything stays on this device.
Future<void> chooseProfilePhoto(
  BuildContext context,
  AuthController controller,
) async {
  final id = controller.profile?.id;
  if (id == null) return;
  String l(String k) => shellLabel(context, k);
  final photos = ProfilePhotos.instance;
  final repository = controller.repository;
  final messenger = ScaffoldMessenger.maybeOf(context);

  Future<void> pick(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) await photos.setCustom(id, image.path);
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(l('photoFailed'))));
    }
  }

  await showGlassSheet<void>(
    context,
    title: l('photoTitle'),
    children: [
      GlassSheetOption(
        icon: Icons.photo_library_outlined,
        title: l('photoGallery'),
        color: context.tf.blue,
        onTap: () {
          Navigator.pop(context);
          pick(ImageSource.gallery);
        },
      ),
      GlassSheetOption(
        icon: Icons.photo_camera_outlined,
        title: l('photoCamera'),
        color: context.tf.yellow,
        onTap: () {
          Navigator.pop(context);
          pick(ImageSource.camera);
        },
      ),
      if (repository is AuthRepository)
        GlassSheetOption(
          icon: Icons.account_circle_outlined,
          title: l('photoGoogle'),
          color: context.tf.soft,
          onTap: () async {
            Navigator.pop(context);
            await photos.removeCustom(id);
            final url = await repository.googlePhotoUrl();
            if (url != null) {
              await photos.setGoogle(id, url);
            } else {
              messenger?.showSnackBar(
                SnackBar(content: Text(l('photoGoogleMissing'))),
              );
            }
          },
        ),
      if (photos.customPath(id) != null)
        GlassSheetOption(
          icon: Icons.delete_outline,
          title: l('photoRemove'),
          color: context.tf.nutrition,
          onTap: () {
            Navigator.pop(context);
            photos.removeCustom(id);
          },
        ),
    ],
  );
}
