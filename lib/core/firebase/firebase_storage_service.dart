import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseStorageService {
  Future<String> uploadPdfReport({
    required final String filePath,
    required final String destinationPath,
  });
}

@LazySingleton(as: IFirebaseStorageService)
class FirebaseStorageService implements IFirebaseStorageService {
  FirebaseStorageService() : _storage = FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<String> uploadPdfReport({
    required final String filePath,
    required final String destinationPath,
  }) async {
    final File file = File(filePath);
    final Reference ref = _storage.ref().child(destinationPath);
    final UploadTask uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
