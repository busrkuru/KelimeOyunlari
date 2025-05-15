# Kelime Oyunları – Çok Oyunculu Mobil Kelime Yarışması

**Kelime Oyunları**, SwiftUI ile geliştirilmiş, çok oyunculu ve stratejiye dayalı bir mobil kelime oyunudur. Oyuncular 15x15’lik bir oyun tahtasına sırayla harf yerleştirerek kelimeler oluşturur. Oyun; puanlama, özel kutular, sürükle-bırak, mayınlar ve ödüller gibi mekaniklerle zenginleştirilmiştir. Tüm oyun ilerlemesi Firebase Firestore üzerinden senkronize edilir ve gerçek zamanlı olarak güncellenir.

---

## Amaç

Oyuncular sırayla tahtaya harf yerleştirerek geçerli Türkçe kelimeler oluşturur. Her kelimenin puanı, harflerin değeri ve kutuların çarpanları dikkate alınarak hesaplanır. Oyunun sonunda en yüksek puana ulaşan oyuncu kazanır.

---

## Temel Özellikler

- **15x15 Oyun Tahtası** – Her oyuncu harfleri sürükleyerek tahtaya bırakır
- **Geçerli Türkçe Kelime Kontrolü**
- **Gerçek Zamanlı Çok Oyunculu** – Firebase Firestore ile senkronizasyon
- **Ödül Sistemi** – Fazladan hamle, harf engelleme, alan kısıtlama
- **Mayınlar** – Puan kaybı, harf kaybı, kelime iptali gibi cezalar
- **Sıra Sistemi ve Zamanlayıcı** – Her oyuncuya tanımlı süre
- **Skor Takibi** – Anlık ve toplam puanlar dinamik olarak gösterilir
- **Oyun Bitiş Kontrolü** – Hamle kalmaması, pes etme veya süresiz bekleme

---

## 🔧 Kullanılan Teknolojiler

| Teknoloji       | Açıklama                             |
|----------------|--------------------------------------|
| **SwiftUI**     | UI geliştirme ve sürükle-bırak sistemi |
| **Firebase**    | Gerçek zamanlı veritabanı ve eşleşme |
| **Firestore**   | Oyun tahtası, kullanıcılar ve skorlar |
| **Cloud Functions** | Harf havuzu kontrolü ve oyun yönetimi |
| **Xcode**       | iOS geliştirme ortamı                |

---

## Proje Yapısı

- `GameBoardView.swift`: Ana oyun tahtası arayüzü ve sürükle bırak sistemi
- `GameViewModel.swift`: Oyun mantığını yöneten ViewModel
- `FirebaseManager.swift`: Firestore ile bağlantı
- `CloudFunctions`: Harf havuzu kontrolü ve oyun eşleşmesi
- `Models/`: Oyun modeli (letter, cell, game)

---

