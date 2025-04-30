String getErrorMessage(String errorCode) {
  switch (errorCode) {
    case 'email-already-in-use':
      return 'Bu e-posta zaten kullanılıyor.';
    case 'invalid-email':
      return 'Geçersiz e-posta adresi.';
    case 'weak-password':
      return 'Şifre en az 6 karakter olmalıdır';
    case 'user-not-found':
      return 'Bu e-posta ile kayıtlı bir kullanıcı bulunamadı.';
    case 'invalid-credential':
      return 'Şifre veya e-posta hatalı.';
    default:
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
  }
}
