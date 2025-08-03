import '../../../core/constants/currencies.dart';

abstract class CurrencyState {}

class CurrencyInitial extends CurrencyState {}

class CurrencyLoading extends CurrencyState {}

class CurrencyLoaded extends CurrencyState {
  final Currency currentCurrency;
  final String searchQuery;
  final List<Currency> filteredCurrencies;

  CurrencyLoaded({
    required this.currentCurrency,
    required this.searchQuery,
    required this.filteredCurrencies,
  });

  CurrencyLoaded copyWith({
    Currency? currentCurrency,
    String? searchQuery,
    List<Currency>? filteredCurrencies,
  }) {
    return CurrencyLoaded(
      currentCurrency: currentCurrency ?? this.currentCurrency,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredCurrencies: filteredCurrencies ?? this.filteredCurrencies,
    );
  }
}

class CurrencyError extends CurrencyState {
  final String message;

  CurrencyError({required this.message});
}

class CurrencyChangedSuccess extends CurrencyState {
  final Currency newCurrency;

  CurrencyChangedSuccess({required this.newCurrency});
}
