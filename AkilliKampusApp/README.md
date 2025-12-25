# 🎓 Akıllı Kampüs Uygulaması (Atatürk Üniversitesi)

Akıllı Kampüs Uygulaması, Atatürk Üniversitesi kampüsü içerisinde karşılaşılan sorunların (teknik arıza, güvenlik riski, sağlık durumu vb.) hızlıca raporlanmasını ve takip edilmesini sağlayan modern bir iOS uygulamasıdır.

## 🚀 Özellikler

- **📍 Harita Entegrasyonu:** Kampüs haritası üzerinde tüm olayları canlı olarak görüntüleyin.
- **📸 Fotoğraflı Raporlama:** Olayın fotoğrafını çekip anında sisteme yükleyin (Ücretsiz Base64 depolama teknolojisi ile).
- **🔐 Güvenli Giriş:** Atatürk Üniversitesi e-posta adresleri (`@atauni.edu.tr` ve `@ogr.atauni.edu.tr`) ile kayıt ve giriş.
- **📱 Google Sign-In:** Google hesabınızla tek tıkla oturum açma seçeneği.
- **📢 Acil Durum Yayınları:** Belediye veya kampüs yönetimi tarafından gönderilen acil durum duyurularını anlık olarak görün.
- **🛠 Admin Paneli:** Olayları yönetme, silme ve durum güncelleme (Açık, İşlemde, Çözüldü) yetkisi.

## 🛠 Kullanılan Teknolojiler

- **Dil:** Swift (SwiftUI)
- **Backend:** Firebase (Auth & Firestore)
- **Harita:** MapKit & CoreLocation
- **Görsel İşleme:** PhotosUI (Base64 Encoding/Decoding)

## 📦 Kurulum

1. Bu projeyi klonlayın:
   ```bash
   git clone https://github.com/feyzackgzglu/AkilliKampusApp.git
   ```
2. Projeyi Xcode ile açın (`AkilliKampusApp.xcodeproj`).
3. `GoogleService-Info.plist` dosyanızın projenize eklendiğinden emin olun.
4. Gerekli paketleri (Firebase, GoogleSignIn) Xcode Swift Package Manager ile yükleyin.
5. Simülatörü seçin ve `Run` (CMD + R) tuşuna basın.

## 🤝 Katkıda Bulunma

1. Bu projeyi forklayın.
2. Yeni bir branch oluşturun: `git checkout -b ozellik/yeni-ozellik`
3. Değişikliklerinizi commit edin: `git commit -m 'Yeni özellik eklendi'`
4. Branch'inizi push edin: `git push origin ozellik/yeni-ozellik`
5. Bir Pull Request oluşturun.

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.

---
**📍 Erzurum, Türkiye**  
**Atatürk Üniversitesi Akıllı Kampüs Projesi**
