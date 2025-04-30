String toLowerTurkish(String input) {
  final Map<String, String> turkishCharMap = {
    'I': 'ı',
    'İ': 'i',
    'Ş': 'ş',
    'Ğ': 'ğ',
    'Ü': 'ü',
    'Ö': 'ö',
    'Ç': 'ç',
  };
  return input.split('').map((char) {
    return turkishCharMap[char] ?? char.toLowerCase();
  }).join();
}

int turkishSort(String a, String b) {
  /* const turkishAlphabet = 'AÁÂÄBCÇDEÉÊËFGĞHIİÎÏJKLMNOÓÔÖPQRSŞTUÚÛÜVWXYZ'
      'aáâäbcçdeéêëfgğhıiîïjklmnoóôöpqrsştuúûüvwxyz'; */

  const turkishAlphabet = 'aáâäbcçdeéêëfgğhıiîïjklmnoóôöpqrsştuúûüvwxyz';

  String lowerA = toLowerTurkish(a);
  String lowerB = toLowerTurkish(b);

  for (int i = 0; i < lowerA.length && i < lowerB.length; i++) {
    int indexA = turkishAlphabet.indexOf(lowerA[i]);
    int indexB = turkishAlphabet.indexOf(lowerB[i]);

    if (indexA != indexB) {
      return indexA.compareTo(indexB);
    }
  }

  return lowerA.length.compareTo(lowerB.length);
}
