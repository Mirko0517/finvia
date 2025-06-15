String getCurrencySymbol(String currencyCode) {
  switch (currencyCode) {
    case 'CLP':
      return '\$';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'ARS':
      return '\$';
    default:
      return currencyCode;
  }
}
