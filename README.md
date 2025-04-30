
# 📚 My Bookcase

**My Bookcase**, kitapları, serileri ve bölümleri yönetmeni sağlayan, her birine notlar ekleyebileceğin, okuma durumuna göre filtreleme yapabileceğin ve verileri kullanıcıya özel olarak Firebase ile senkronize eden bir Flutter uygulamasıdır.

---

## 🚀 Özellikler

- 🔐 Firebase Authentication ile kullanıcı girişi
- 📖 Kitap ve seri (birden fazla kitabı içeren yapı) yönetimi
- ✍️ Her kitap/seri/ bölüm için özel notlar ekleyebilme
- ⭐ Kitaplara favori ekleme
- 📅 Yıla ve aya göre okunan kitapları filtreleme
- 🔍 Okunmuş, okunmamış ve yıldızlı kitaplara filtreleme
- 🔍 Kitap, seri ve yazar ismi ile arama
- 🖼️ Cihaza özel resim ekleme (yerel dosya depolama ile), URL ile resim ekleme
- 🌗 Karanlık ve aydınlık tema desteği
- ⚙️ Font büyüklüğü ve tipi ayarlanabilir

---

## 🛠️ Teknolojiler

| Teknoloji     | Açıklama                      |
|---------------|-------------------------------|
| Flutter       | Arayüz geliştirme              |
| Firebase Auth | Kullanıcı oturumu              |
| Firebase Firestore | Gerçek zamanlı veritabanı |
| Riverpod      | Durum yönetimi                 |
| SharedPreferences | Yerel ayarların saklanması |
| image_picker + path_provider | Yerel resim seçme ve kaydetme |

---

## 📸 Ekran Görüntüleri

### 📂 Ana Sayfa
![Ana Sayfa](screenshots/home.png)

### 📚 Kitap Detay
![Kitap Detay](screenshots/book_detail.png)

### 🗂️ Notlar Sayfası
![Notlar](screenshots/notes_page.png)

### 📅 Filtreleme Seçenekleri
![Filtreler](screenshots/filters.png)

---

## 🧠 Notlar

- Kamera ile çekilen veya galeriden seçilen görseller yalnızca o cihazda görünür.
- Tüm filtreleme işlemleri, gerçek zamanlı olarak Firestore üzerinden gerçekleşir.
- Notlar ve kitap verileri kullanıcıya özeldir.

---

## 📄 Lisans

MIT Lisansı. Daha fazla bilgi için [LICENSE](LICENSE) dosyasını inceleyin.

---

## ✍️ Geliştirici

**[Nihan Ertuğ]**  
GitHub: [github.com/NihanErtug](https://github.com/NihanErtug)  


