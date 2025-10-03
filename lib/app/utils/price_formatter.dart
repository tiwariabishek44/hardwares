import 'dart:math';

class PriceFormatter {
  /// Formats a double price to string with proper comma separation
  /// Example: 1234.56 -> "1,234.56"
  /// Example: 1234567.89 -> "12,34,567.89" (Indian style)
  static String formatPrice(double price, {int decimalPlaces = 2}) {
    if (price.isNaN || price.isInfinite) {
      return "0.00";
    }

    // Handle negative numbers
    bool isNegative = price < 0;
    price = price.abs();

    // Round to specified decimal places
    double factor = pow(10, decimalPlaces).toDouble();
    price = (price * factor).round() / factor;

    // Split into integer and decimal parts
    String priceString = price.toStringAsFixed(decimalPlaces);
    List<String> parts = priceString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : "";

    // Format integer part with commas (Indian style: ##,##,###)
    String formattedInteger = _addCommas(integerPart);

    // Combine parts
    String result = decimalPart.isNotEmpty
        ? "$formattedInteger.$decimalPart"
        : formattedInteger;

    return isNegative ? "-$result" : result;
  }

  /// Formats price with "Rs." prefix
  /// Example: 1234.56 -> "Rs. 1,234.56"
  static String formatPriceWithCurrency(double price, {int decimalPlaces = 2}) {
    return "Rs. ${formatPrice(price, decimalPlaces: decimalPlaces)}";
  }

  /// Formats price for display without decimal places if it's a whole number
  /// Example: 1234.00 -> "Rs. 1,234"
  /// Example: 1234.50 -> "Rs. 1,234.50"
  static String formatPriceForDisplay(double price) {
    if (price % 1 == 0) {
      // It's a whole number, show without decimals
      return formatPriceWithCurrency(price, decimalPlaces: 0);
    } else {
      // Has decimal places, show with 2 decimal places
      return formatPriceWithCurrency(price, decimalPlaces: 2);
    }
  }

  /// Internal method to add commas in Indian style (##,##,###)
  static String _addCommas(String number) {
    if (number.length <= 3) {
      return number;
    }

    // Indian numbering system: group by 2 digits after first 3 digits from right
    String result = '';
    int length = number.length;

    // Process from right to left
    for (int i = 0; i < length; i++) {
      int position = length - 1 - i;
      result = number[position] + result;

      // Add comma after first 3 digits, then every 2 digits
      if (i == 2 && length > 3) {
        result = ',' + result;
      } else if (i > 2 && (i - 2) % 2 == 0 && position > 0) {
        result = ',' + result;
      }
    }

    return result;
  }

  /// Formats quantity with proper formatting
  /// Example: 1 -> "1 pc", 5 -> "5 pcs"
  static String formatQuantity(int quantity) {
    String formattedQty = formatPrice(quantity.toDouble(), decimalPlaces: 0);
    return quantity == 1 ? "$formattedQty" : "$formattedQty ";
  }

  /// Parse formatted price string back to double (utility method)
  /// Example: "1,234.56" -> 1234.56
  static double parseFormattedPrice(String formattedPrice) {
    // Remove "Rs." prefix if present
    String cleaned = formattedPrice.replaceAll(RegExp(r'Rs\.\s*'), '');
    // Remove commas
    cleaned = cleaned.replaceAll(',', '');
    // Parse to double
    return double.tryParse(cleaned) ?? 0.0;
  }
}
