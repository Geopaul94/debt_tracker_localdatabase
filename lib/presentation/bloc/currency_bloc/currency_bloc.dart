import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/currencies.dart';
import '../../../core/services/currency_service.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyService _currencyService;

  CurrencyBloc({required CurrencyService currencyService})
    : _currencyService = currencyService,
      super(CurrencyInitial()) {
    on<LoadCurrentCurrencyEvent>(_onLoadCurrentCurrency);
    on<ChangeCurrencyEvent>(_onChangeCurrency);
    on<UpdateSearchQueryEvent>(_onUpdateSearchQuery);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onLoadCurrentCurrency(
    LoadCurrentCurrencyEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoading());
    try {
      final currentCurrency = _currencyService.currentCurrency;
      final filteredCurrencies = await _getFilteredCurrencies('');

      emit(
        CurrencyLoaded(
          currentCurrency: currentCurrency,
          searchQuery: '',
          filteredCurrencies: filteredCurrencies,
        ),
      );
    } catch (e) {
      emit(CurrencyError(message: 'Failed to load currency: ${e.toString()}'));
    }
  }

  Future<void> _onChangeCurrency(
    ChangeCurrencyEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    try {
      await _currencyService.setCurrency(event.currency);

      if (state is CurrencyLoaded) {
        final currentState = state as CurrencyLoaded;
        emit(currentState.copyWith(currentCurrency: event.currency));
      }

      emit(CurrencyChangedSuccess(newCurrency: event.currency));
    } catch (e) {
      emit(
        CurrencyError(message: 'Failed to change currency: ${e.toString()}'),
      );
    }
  }

  void _onUpdateSearchQuery(
    UpdateSearchQueryEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      final filteredCurrencies = await _getFilteredCurrencies(event.query);

      emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredCurrencies: filteredCurrencies,
        ),
      );
    }
  }

  void _onClearSearch(
    ClearSearchEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      final filteredCurrencies = await _getFilteredCurrencies('');

      emit(
        currentState.copyWith(
          searchQuery: '',
          filteredCurrencies: filteredCurrencies,
        ),
      );
    }
  }

  Future<List<Currency>> _getFilteredCurrencies(String searchQuery) async {
    List<Currency> currencies = await CurrencyConstants.supportedCurrencies;

    if (searchQuery.isNotEmpty) {
      currencies =
          currencies.where((currency) {
            return currency.name.toLowerCase().contains(
                  searchQuery.toLowerCase(),
                ) ||
                currency.code.toLowerCase().contains(searchQuery.toLowerCase());
          }).toList();
    }

    return currencies;
  }
}
