import '../../../core/constants/currencies.dart';

abstract class CurrencyEvent {}

class LoadCurrentCurrencyEvent extends CurrencyEvent {}

class ChangeCurrencyEvent extends CurrencyEvent {
  final Currency currency;

  ChangeCurrencyEvent({required this.currency});
}

class UpdateSearchQueryEvent extends CurrencyEvent {
  final String query;

  UpdateSearchQueryEvent({required this.query});
}

class UpdateSelectedRegionEvent extends CurrencyEvent {
  final String region;

  UpdateSelectedRegionEvent({required this.region});
}

class ClearSearchEvent extends CurrencyEvent {}
