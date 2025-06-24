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
    on<UpdateSelectedRegionEvent>(_onUpdateSelectedRegion);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onLoadCurrentCurrency(
    LoadCurrentCurrencyEvent event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoading());
    try {
      final currentCurrency = _currencyService.currentCurrency;
      final filteredCurrencies = _getFilteredCurrencies('', 'All Regions');

      emit(
        CurrencyLoaded(
          currentCurrency: currentCurrency,
          searchQuery: '',
          selectedRegion: 'All Regions',
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
  ) {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      final filteredCurrencies = _getFilteredCurrencies(
        event.query,
        currentState.selectedRegion,
      );

      emit(
        currentState.copyWith(
          searchQuery: event.query,
          filteredCurrencies: filteredCurrencies,
        ),
      );
    }
  }

  void _onUpdateSelectedRegion(
    UpdateSelectedRegionEvent event,
    Emitter<CurrencyState> emit,
  ) {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      final filteredCurrencies = _getFilteredCurrencies(
        currentState.searchQuery,
        event.region,
      );

      emit(
        currentState.copyWith(
          selectedRegion: event.region,
          filteredCurrencies: filteredCurrencies,
        ),
      );
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<CurrencyState> emit) {
    if (state is CurrencyLoaded) {
      final currentState = state as CurrencyLoaded;
      final filteredCurrencies = _getFilteredCurrencies(
        '',
        currentState.selectedRegion,
      );

      emit(
        currentState.copyWith(
          searchQuery: '',
          filteredCurrencies: filteredCurrencies,
        ),
      );
    }
  }

  List<Currency> _getFilteredCurrencies(
    String searchQuery,
    String selectedRegion,
  ) {
    List<Currency> currencies =
        selectedRegion == 'All Regions'
            ? CurrencyConstants.supportedCurrencies
            : CurrencyConstants.getCurrenciesByRegion(selectedRegion);

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
