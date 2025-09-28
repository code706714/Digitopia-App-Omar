import 'package:digitopia_app/presentation/pages/main_navigation.dart';
import 'package:digitopia_app/presentation/widgets/location_picker.dart';
import 'package:digitopia_app/services/django_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class ShareMealScreen extends StatefulWidget {
  const ShareMealScreen({super.key});

  @override
  State<ShareMealScreen> createState() => _ShareMealScreenState();
}

class _ShareMealScreenState extends State<ShareMealScreen> {
  int _quantity = 1;
  String _selectedPrivacy = 'عام';
  File? _selectedImage;
  final TextEditingController _mealNameController = TextEditingController();
  String _selectedLocation = 'اختر الموقع من الخريطة';
  double? _selectedLat;
  double? _selectedLng;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  /// Robust Supabase upload:
  /// - tries upload(file) first
  /// - if fails, falls back to uploadBinary using bytes
  /// - returns the public URL (or null on failure)
  Future<String?> _uploadImageToSupabase(File file, String ownerId) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    // path inside the bucket (you can change structure)
    final path = 'meals/$ownerId/meal_$ts.jpg';
    final storage = Supabase.instance.client.storage;
    const bucket = 'meals'; // تأكد أن اسم البَكِت matches في Supabase

    try {
      // 1) try upload as File (works on mobile)
      await storage.from(bucket).upload(path, file, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
    } catch (e) {
      debugPrint('Supabase upload(file) failed: $e — trying bytes fallback');
      try {
        // 2) fallback: read bytes and use uploadBinary (some environments require bytes)
        final bytes = await file.readAsBytes();
        // The API name may be uploadBinary in some supabase versions; if not available the previous upload likely works.
        await storage.from(bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true));
      } catch (e2) {
        debugPrint('Supabase uploadBinary also failed: $e2');
        return null;
      }
    }

    try {
      // getPublicUrl returns a map-like object in some versions; but in supabase_flutter it's a string
      final publicUrl = Supabase.instance.client.storage.from(bucket).getPublicUrl(path);
      debugPrint('Supabase publicUrl: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error getting publicUrl: $e');
      return null;
    }
  }

  Future<void> uploadMeal() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // لو تستخدم FirebaseAuth في مشروعك استبدل السطر فوق بفحص FirebaseAuth.instance.currentUser
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يجب تسجيل الدخول لرفع وجبة")),
      );
      return;
    }

    if (_mealNameController.text.isEmpty || _selectedLocation == 'اختر الموقع من الخريطة') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("من فضلك املأ كل الحقول واختر الموقع")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        // ارفع الصورة إلى Supabase
        imageUrl = await _uploadImageToSupabase(_selectedImage!, user.id);
        if (imageUrl == null) {
          throw Exception('فشل رفع الصورة إلى Supabase');
        }
      }

      final mealData = {
        'name': _mealNameController.text.trim(),
        'quantity': _quantity,
        'location': _selectedLocation,
        'latitude': _selectedLat,
        'longitude': _selectedLng,
        'privacy': _selectedPrivacy,
        'imageUrl': imageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'userName': user.userMetadata?['full_name'] ?? user.email ?? 'مستخدم',
        'ownerId': user.id,
        'status': 'مُتاح',
      };

      await FirebaseFirestore.instance.collection('meals').add(mealData);

      // (اختياري) إرسال إشعار عبر Django
      await DjangoNotificationService.sendMealNotification(
        userName: mealData['userName'],
        mealName: mealData['name'],
        location: mealData['location'],
        imageUrl: imageUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("تمت إضافة الوجبة بنجاح")),
      );

      // تنظيف الحقول
      _mealNameController.clear();
      setState(() {
        _quantity = 1;
        _selectedPrivacy = 'عام';
        _selectedImage = null;
        _selectedLocation = 'اختر الموقع من الخريطة';
        _selectedLat = null;
        _selectedLng = null;
      });
    } catch (e) {
      debugPrint('Error uploading meal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في رفع الوجبة: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'رفع طعام',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                        builder: (context) => const MainNavigation(currentUserId: '', currentUserName: '',),
                        ),
                 ),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('إضافة صورة الطعام', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            const Text('اسم الوجبة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _mealNameController, textAlign: TextAlign.right, decoration: InputDecoration(hintText: 'على سبيل المثال: كبسة دجاج', hintStyle: TextStyle(color: Colors.grey[400]), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)))),
            const SizedBox(height: 24),
            const Text('الكمية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('عدد الأشخاص', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const Spacer(),
                IconButton(onPressed: () { if (_quantity > 1) setState(() => _quantity--); }, icon: const Icon(Icons.remove)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)), child: Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                IconButton(onPressed: () { setState(() => _quantity++); }, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('الموقع', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationPickerScreen()));
                if (result != null) {
                  setState(() {
                    _selectedLocation = result['address'];
                    _selectedLat = result['lat'];
                    _selectedLng = result['lng'];
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: _selectedLocation == 'اختر الموقع من الخريطة' ? Colors.grey[400] : const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_selectedLocation, style: TextStyle(color: _selectedLocation == 'اختر الموقع من الخريطة' ? Colors.grey[400] : Colors.black, fontSize: 16))),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ... بقية الواجهة بدون تغيير
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : uploadMeal,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('رفع الوجبة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
