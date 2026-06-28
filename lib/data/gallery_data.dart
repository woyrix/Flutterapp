// lib/data/gallery_data.dart

import 'package:flutter/material.dart';

class GalleryItem {
  final String id;
  final String title;
  final Color placeholderColor;
  final String? assetPath;
  final bool isPlaceholder;

  const GalleryItem({
    required this.id,
    required this.title,
    required this.placeholderColor,
    this.assetPath,
    this.isPlaceholder = true,
  });
}

class GalleryData {
  static const List<GalleryItem> items = [
    GalleryItem(id: 'g1', title: 'इन महादेवकी मैं भी अब हूँ नित्य महादेवी, प्रियतम !', placeholderColor: Color(0xFF8D3B2F), assetPath: 'assets/images/gallery/gallery_001.jpg', isPlaceholder: false),
    GalleryItem(id: 'g2', title: 'ग्रीवा में प्रतिमा के पहना, चरणों में लुढ़क पड़ी, प्रियतम', placeholderColor: Color(0xFF9B6B2F), assetPath: 'assets/images/gallery/gallery_002.jpg', isPlaceholder: false),
    GalleryItem(id: 'g3', title: 'जो महाभाव है, वह बनता रसराज एक पल में प्रियतम', placeholderColor: Color(0xFF1D3F4F), assetPath: 'assets/images/gallery/gallery_003.jpg', isPlaceholder: false),
    GalleryItem(id: 'g4', title: 'देवी के बदले प्यारे को वह महादेव दीखे, प्रियतम !', placeholderColor: Color(0xFF2A5C6B), assetPath: 'assets/images/gallery/gallery_004.jpg', isPlaceholder: false),
    GalleryItem(id: 'g5', title: 'नीलम निर्मित थी मूर्त्ति एक मानो बस, बोल चली, प्रियतम !', placeholderColor: Color(0xFF455A92), assetPath: 'assets/images/gallery/gallery_005.png', isPlaceholder: false),
    GalleryItem(id: 'g6', title: 'प्रक्षालित किये तरंगों ने फिर पद हम दोनों के, प्रियतम', placeholderColor: Color(0xFF456D91), assetPath: 'assets/images/gallery/gallery_006.jpg', isPlaceholder: false),
    GalleryItem(id: 'g7', title: 'प्राणेश्वरी ! तुम रचना करो तो सही !', placeholderColor: Color(0xFF4C8A68), assetPath: 'assets/images/gallery/gallery_007.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g8', title: 'प्राणेश्वरी ! तुम रचना करो तो सही !', placeholderColor: Color(0xFF32644E), assetPath: 'assets/images/gallery/gallery_008.jpg', isPlaceholder: false),
    GalleryItem(id: 'g9', title: 'प्रियतम', placeholderColor: Color(0xFF3D438A), assetPath: 'assets/images/gallery/gallery_009.jpg', isPlaceholder: false),
    GalleryItem(id: 'g10', title: 'प्रिया-प्रियतम', placeholderColor: Color(0xFF6D5F4A), assetPath: 'assets/images/gallery/gallery_010.png', isPlaceholder: false),
    GalleryItem(id: 'g11', title: 'प्रिया-प्रियतम', placeholderColor: Color(0xFF6D5F4A), assetPath: 'assets/images/gallery/gallery_011.png', isPlaceholder: false),
    GalleryItem(id: 'g12', title: 'प्रिया-प्रीतम', placeholderColor: Color(0xFF6F8A55), assetPath: 'assets/images/gallery/gallery_012.png', isPlaceholder: false),
    GalleryItem(id: 'g13', title: 'बालाको उसी सहेली ने भर लिया भुजाओं में, प्रियतम !', placeholderColor: Color(0xFF5D8CAD), assetPath: 'assets/images/gallery/gallery_013.png', isPlaceholder: false),
    GalleryItem(id: 'g14', title: 'बिनोदिनी रूप में ।', placeholderColor: Color(0xFF2E7D6B), assetPath: 'assets/images/gallery/gallery_014.jpg', isPlaceholder: false),
    GalleryItem(id: 'g15', title: 'भाई जी द्वारा भगवान्नाम संकीर्तन स्थापना ll', placeholderColor: Color(0xFF555555), assetPath: 'assets/images/gallery/gallery_015.jpg', isPlaceholder: false),
    GalleryItem(id: 'g16', title: 'भाई जी द्वारा भगवान्नाम संकीर्तन स्थापना ll', placeholderColor: Color(0xFF555555), assetPath: 'assets/images/gallery/gallery_016.jpg', isPlaceholder: false),
    GalleryItem(id: 'g17', title: 'महाभाव-रसराज', placeholderColor: Color(0xFF2E6B42), assetPath: 'assets/images/gallery/gallery_017.jpg', isPlaceholder: false),
    GalleryItem(id: 'g18', title: 'मेरे प्राणों की रानीके पदमें जो चिपक गयीं, प्रियतम !', placeholderColor: Color(0xFF226D88), assetPath: 'assets/images/gallery/gallery_018.jpg', isPlaceholder: false),
    GalleryItem(id: 'g19', title: 'रसमय श्रीयंत्र', placeholderColor: Color(0xFF4E6BAA), assetPath: 'assets/images/gallery/gallery_019.png', isPlaceholder: false),
    GalleryItem(id: 'g20', title: 'वह उजड़ गया वन था जिसमें बहती रसकी धारा, प्रियतम !', placeholderColor: Color(0xFF8C8748), assetPath: 'assets/images/gallery/gallery_020.png', isPlaceholder: false),
    GalleryItem(id: 'g21', title: 'विवाह मंडप प्रिया-प्रीतम', placeholderColor: Color(0xFF9B6238), assetPath: 'assets/images/gallery/gallery_021.jpg', isPlaceholder: false),
    GalleryItem(id: 'g22', title: 'श्री इन्दुलेखा जी', placeholderColor: Color(0xFF7C3F64), assetPath: 'assets/images/gallery/gallery_022.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g23', title: 'श्रीइन्दुलेखाजी', placeholderColor: Color(0xFF6D8B6A), assetPath: 'assets/images/gallery/gallery_023.png', isPlaceholder: false),
    GalleryItem(id: 'g24', title: 'श्रीकीर्तिदा मैया, श्री श्रीदाम, श्रीराधा एवं श्रीमंजुश्यामा', placeholderColor: Color(0xFF8C4D3A), assetPath: 'assets/images/gallery/gallery_024.jpg', isPlaceholder: false),
    GalleryItem(id: 'g25', title: 'श्रीकृष्ण चंद्र', placeholderColor: Color(0xFF5F3F7A), assetPath: 'assets/images/gallery/gallery_025.jpg', isPlaceholder: false),
    GalleryItem(id: 'g26', title: 'श्रीचम्पकलता जी', placeholderColor: Color(0xFF304F8F), assetPath: 'assets/images/gallery/gallery_026.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g27', title: 'श्रीचम्पकलताजी', placeholderColor: Color(0xFF8A7047), assetPath: 'assets/images/gallery/gallery_027.png', isPlaceholder: false),
    GalleryItem(id: 'g28', title: 'श्रीचित्रा जी', placeholderColor: Color(0xFF6C6C78), assetPath: 'assets/images/gallery/gallery_028.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g29', title: 'श्रीचित्राजी', placeholderColor: Color(0xFF8C704D), assetPath: 'assets/images/gallery/gallery_029.png', isPlaceholder: false),
    GalleryItem(id: 'g30', title: 'श्रीतुंगविद्या जी', placeholderColor: Color(0xFF8D653A), assetPath: 'assets/images/gallery/gallery_030.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g31', title: 'श्रीतुंगविद्याजी', placeholderColor: Color(0xFFC06B73), assetPath: 'assets/images/gallery/gallery_031.png', isPlaceholder: false),
    GalleryItem(id: 'g32', title: 'श्रीमंजुश्यामा जी', placeholderColor: Color(0xFF6D84A0), assetPath: 'assets/images/gallery/gallery_032.png', isPlaceholder: false),
    GalleryItem(id: 'g33', title: 'श्रीमंजुश्यामाजी', placeholderColor: Color(0xFFB38336), assetPath: 'assets/images/gallery/gallery_033.png', isPlaceholder: false),
    GalleryItem(id: 'g34', title: 'श्रीयशोदा मैया, श्रीकृष्ण एवं श्रीबलराम', placeholderColor: Color(0xFF865A79), assetPath: 'assets/images/gallery/gallery_034.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g35', title: 'श्रीरंगदेवी जी', placeholderColor: Color(0xFF8C3F4E), assetPath: 'assets/images/gallery/gallery_035.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g36', title: 'श्रीरंगदेवीजी', placeholderColor: Color(0xFF8B7653), assetPath: 'assets/images/gallery/gallery_036.png', isPlaceholder: false),
    GalleryItem(id: 'g37', title: 'श्रीराधा', placeholderColor: Color(0xFF5F753D), assetPath: 'assets/images/gallery/gallery_037.png', isPlaceholder: false),
    GalleryItem(id: 'g38', title: 'श्रीललिता जी', placeholderColor: Color(0xFF7F7048), assetPath: 'assets/images/gallery/gallery_038.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g39', title: 'श्रीललिताजी', placeholderColor: Color(0xFF8B735F), assetPath: 'assets/images/gallery/gallery_039.png', isPlaceholder: false),
    GalleryItem(id: 'g40', title: 'श्रीविशाखा जी', placeholderColor: Color(0xFF465A3D), assetPath: 'assets/images/gallery/gallery_040.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g41', title: 'श्रीविशाखाजी', placeholderColor: Color(0xFF756C53), assetPath: 'assets/images/gallery/gallery_041.png', isPlaceholder: false),
    GalleryItem(id: 'g42', title: 'श्रीसुदेवी जी', placeholderColor: Color(0xFF7F3E49), assetPath: 'assets/images/gallery/gallery_042.jpeg', isPlaceholder: false),
    GalleryItem(id: 'g43', title: 'श्रीसुदेवीजी', placeholderColor: Color(0xFF81755B), assetPath: 'assets/images/gallery/gallery_043.png', isPlaceholder: false),
    GalleryItem(id: 'g44', title: 'सर्प लीला चित्र', placeholderColor: Color(0xFF4C846F), assetPath: 'assets/images/gallery/gallery_044.jpg', isPlaceholder: false),
  ];
}
