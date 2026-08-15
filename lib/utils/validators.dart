class Validators {
  // Verhoeff algorithm tables for Aadhaar validation
  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
  ];

  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
  ];


  /// Validates Aadhaar number using Verhoeff algorithm
  static bool validateAadhaar(String aadhaar) {
    // Strip spaces/hyphens
    final cleaned = aadhaar.replaceAll(RegExp(r'\s+|-'), '');
    
    // Must be exactly 12 digits, must not start with 0 or 1
    if (cleaned.length != 12 || !RegExp(r'^[2-9][0-9]{11}$').hasMatch(cleaned)) {
      return false;
    }

    int c = 0;
    List<int> digits = cleaned.split('').map(int.parse).toList();
    
    // Verhoeff checksum calculation (iterating in reverse order)
    for (int i = 0; i < digits.length; i++) {
      final index = digits.length - 1 - i;
      final digit = digits[index];
      c = _d[c][_p[i % 8][digit]];
    }

    return c == 0;
  }

  /// Validates PAN Card format
  static bool validatePAN(String pan) {
    final cleaned = pan.trim().toUpperCase();
    if (cleaned.isEmpty) return true;
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(cleaned);
  }
}
