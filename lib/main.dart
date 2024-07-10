import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:intl/intl.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? image;
  String? imageMetadata;
  String? imageStatus;
  int? originalFileSize;
  int? compressedFileSize;

  Future pickImage(ImageSource source) async {
    try {
      XFile? pickedFile =
          await ImagePicker().pickImage(source: source, imageQuality: 22);

      if (pickedFile == null) return;

      // Save original file size
      originalFileSize = await File(pickedFile.path).length();

      // Compress the image
      pickedFile = await compressImage(pickedFile);

      // Save the compressed image if picked from the camera
      if (source == ImageSource.camera) {
        await saveCompressedImage(pickedFile, true);
      }

      // Save compressed file size
      compressedFileSize = await File(pickedFile.path).length();

      final imageTemp = File(pickedFile.path);
      final metadata = await getImageMetadata(pickedFile);
      final status = await getImageStatus(pickedFile);

      setState(() {
        image = imageTemp;
        imageMetadata = metadata;
        imageStatus = status;
      });
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  Future<String> getImageMetadata(XFile pickedFile) async {
    final List<int> imageBytes = await File(pickedFile.path).readAsBytes();
    final Map<String, IfdTag> data =
        await readExifFromBytes(Uint8List.fromList(imageBytes));

    if (data.isNotEmpty) {
      return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    } else {
      return 'No EXIF metadata found';
    }
  }

  Future<String> getImageStatus(XFile pickedFile) async {
    final List<int> imageBytes = await File(pickedFile.path).readAsBytes();
    final Map<String, IfdTag> data =
        await readExifFromBytes(Uint8List.fromList(imageBytes));

    String? date;

    if (data.containsKey('EXIF DateTimeOriginal')) {
      date = data['EXIF DateTimeOriginal']?.toString();
    } else if (data.containsKey('Image DateTime')) {
      date = data['Image DateTime']?.toString();
    }

    if (date != null) {
      try {
        DateTime parsedDate = DateFormat('yyyy:MM:dd HH:mm:ss').parse(date);
        DateTime currentDate = DateTime.now();
        Duration difference = currentDate.difference(parsedDate);

        if (difference.isNegative) {
          difference = Duration.zero;
        }

        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(parsedDate);

        String status;

        if (difference.inSeconds < 60) {
          status = '$formattedDate - ${difference.inSeconds} Detik Yang Lalu';
        } else if (difference.inMinutes < 60) {
          status = '$formattedDate - ${difference.inMinutes} Menit Yang Lalu';
        } else if (difference.inHours < 24) {
          status = '$formattedDate - ${difference.inHours} Jam Yang Lalu';
        } else {
          int days = difference.inDays;
          int remainingHours = difference.inHours - days * 24;
          status =
              '$formattedDate - $days Hari dan $remainingHours Jam Yang Lalu';
        }

        if (difference.inHours > 6) {
          return '$status - 1';
        } else {
          return '$status - 0';
        }
      } catch (e) {
        return 'Tanggal Foto Tidak di Temukan, Terindikasi Foto Download / Screenshot - 2';
      }
    } else {
      return 'Tanggal Foto Tidak di Temukan, Terindikasi Foto Download / Screenshot - 2';
    }
  }

  String trimEndText(String text, int count) {
    return text.length > count ? text.substring(0, text.length - count) : text;
  }

  bool endsWithZero(String text) {
    final RegExp regExp = RegExp(r'(\d+)$');
    final Match? match = regExp.firstMatch(text);

    if (match != null) {
      final int number = int.parse(match.group(0)!);
      return number == 0;
    }

    return false;
  }

  Future<XFile> compressImage(XFile? pickedFile,
      {int targetFileSize = 300 * 1024, int compressionQuality = 90}) async {
    if (pickedFile != null) {
      File file = File(pickedFile.path);

      int originalFileSize = await file.length();

      // Check if original file size is under target size
      if (originalFileSize <= targetFileSize) {
        return pickedFile;
      }

      Uint8List? compressedBytes;

      try {
        // Read image file
        Uint8List originalFileBytes = await file.readAsBytes();

        while (originalFileSize > targetFileSize && compressionQuality > 0) {
          // Compress image data
          compressedBytes = await FlutterImageCompress.compressWithList(
            originalFileBytes,
            quality: compressionQuality,
          );
          compressionQuality -= 10;

          // Check if compressed size is within target size
          if (compressedBytes.length <= targetFileSize) {
            break;
          }
        }

        if (compressedBytes != null && compressedBytes.isNotEmpty) {
          // Write compressed data to the original file
          await file.writeAsBytes(compressedBytes);

          // Return the same XFile object as it now represents the compressed file
          return pickedFile;
        }
      } catch (error) {
        // Handle compression errors
        print('Failed to compress image: $error');
      }
    }
    return pickedFile!;
  }

  Future<void> saveCompressedImage(
      XFile? pickedFile, bool compressImageBool) async {
    try {
      if (pickedFile == null) {
        throw Exception("Gagal menyimpan foto, mohon unggah kembali foto !!!");
      }

      XFile? tempFile;

      if (compressImageBool) {
        tempFile = await compressImage(pickedFile);
      }

      int? fileSize = await File(tempFile?.path ?? pickedFile.path).length();

      if (fileSize == null) {
        throw Exception("Gagal menyimpan foto, mohon unggah kembali foto !!!");
      }

      final result =
          await ImageGallerySaver.saveFile(tempFile?.path ?? pickedFile.path);

      if (!result['isSuccess']) {
        throw Exception("Gagal menyimpan foto, mohon unggah kembali foto !!!");
      }

      setState(() {
        compressedFileSize = fileSize;
      });
    } catch (error) {
      // Show error dialog
      print('Failed to save compressed image: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme myTextTheme = Theme.of(context).textTheme;
    final Color neutralBlack = Colors.black;
    final Color red900 = Colors.red[900]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aplikasi Check Meta Data"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              MaterialButton(
                color: Colors.blue,
                child: const Text("Unggah Foto dari Gallery",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                onPressed: () => pickImage(ImageSource.gallery),
              ),
              MaterialButton(
                color: Colors.blue,
                child: const Text("Unggah Foto dari Camera",
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
                onPressed: () => pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 24),
              image != null
                  ? Column(
                      children: [
                        const Text("Data Foto"),
                        const SizedBox(
                          height: 4.0,
                        ),
                        Text(imageMetadata ?? 'No metadata available'),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text("Status Image"),
                        const SizedBox(
                          height: 4.0,
                        ),
                        Text(
                          trimEndText(imageStatus ?? '', 3),
                          style: myTextTheme.labelSmall?.copyWith(
                            color: endsWithZero(imageStatus ?? '')
                                ? neutralBlack
                                : red900,
                          ),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Text(
                            "Ukuran Asli: ${originalFileSize ?? 'Unknown'} bytes"),
                        const SizedBox(
                          height: 4.0,
                        ),
                        Text(
                            "Ukuran Terkompres: ${compressedFileSize ?? 'Unknown'} bytes"),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Image.file(image!),
                      ],
                    )
                  : const Text("Tidak ada foto yang dipilih"),
            ],
          ),
        ),
      ),
    );
  }
}
