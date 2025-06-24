import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/currencies.dart';
import '../../injection/injection_container.dart';
import '../bloc/currency_bloc/currency_bloc.dart';
import '../bloc/currency_bloc/currency_event.dart';
import '../bloc/currency_bloc/currency_state.dart';
import '../widgets/ad_banner_widget.dart';

class CurrencySelectionPage extends StatelessWidget {
  const CurrencySelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              serviceLocator<CurrencyBloc>()..add(LoadCurrentCurrencyEvent()),
      child: const _CurrencySelectionContent(),
    );
  }
}

class _CurrencySelectionContent extends StatefulWidget {
  const _CurrencySelectionContent();

  @override
  State<_CurrencySelectionContent> createState() =>
      _CurrencySelectionContentState();
}

class _CurrencySelectionContentState extends State<_CurrencySelectionContent> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _regions = [
    'All Regions',
    'North America',
    'Europe',
    'Asia',
    'Middle East & Africa',
    'Oceania',
    'South America',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Currency'),
        centerTitle: true,
        elevation: 2,
      ),
      body: BlocConsumer<CurrencyBloc, CurrencyState>(
        listener: (context, state) {
          if (state is CurrencyChangedSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text(state.newCurrency.flag),
                    SizedBox(width: 8.w),
                    Text('Currency changed to ${state.newCurrency.name}'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Go back to previous screen after a short delay
            Future.delayed(Duration(milliseconds: 500)).then((_) {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          } else if (state is CurrencyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CurrencyLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is CurrencyLoaded) {
            return _buildLoadedContent(context, state);
          } else if (state is CurrencyError) {
            return _buildErrorState(context, state);
          }

          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, CurrencyLoaded state) {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon:
                      state.searchQuery.isNotEmpty
                          ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CurrencyBloc>().add(
                                ClearSearchEvent(),
                              );
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                onChanged: (value) {
                  context.read<CurrencyBloc>().add(
                    UpdateSearchQueryEvent(query: value),
                  );
                },
              ),
              SizedBox(height: 16.h),

              // Region Filter
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.selectedRegion,
                    icon: Icon(Icons.expand_more),
                    isExpanded: true,
                    items:
                        _regions.map((region) {
                          return DropdownMenuItem(
                            value: region,
                            child: Text(region),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        context.read<CurrencyBloc>().add(
                          UpdateSelectedRegionEvent(region: value),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current Selection Display
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue),
              SizedBox(width: 12.w),
              Text(
                'Current: ',
                style: TextStyle(fontSize: 14.sp, color: Colors.blue[800]),
              ),
              Text(
                '${state.currentCurrency.flag} ${state.currentCurrency.name}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Spacer(),
              Text(
                state.currentCurrency.symbol,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ),

        // Ad Banner
        AdBannerWidget(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        ),

        // Currency List
        Expanded(
          child:
              state.filteredCurrencies.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: state.filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = state.filteredCurrencies[index];
                      final isSelected =
                          state.currentCurrency.code == currency.code;

                      return _buildCurrencyTile(context, currency, isSelected);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildCurrencyTile(
    BuildContext context,
    Currency currency,
    bool isSelected,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isSelected ? Colors.blue[300]! : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow:
            isSelected
                ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Center(
            child: Text(currency.flag, style: TextStyle(fontSize: 24.sp)),
          ),
        ),
        title: Text(
          currency.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.blue[800] : Colors.black87,
          ),
        ),
        subtitle: Text(
          currency.code,
          style: TextStyle(
            fontSize: 12.sp,
            color: isSelected ? Colors.blue[600] : Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currency.symbol,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue[800] : Colors.black54,
              ),
            ),
            SizedBox(width: 8.w),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.blue, size: 24.sp)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24.sp,
              ),
          ],
        ),
        onTap: () {
          context.read<CurrencyBloc>().add(
            ChangeCurrencyEvent(currency: currency),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No currencies found',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filter',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CurrencyError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.red[400]),
          SizedBox(height: 16.h),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            state.message,
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              context.read<CurrencyBloc>().add(LoadCurrentCurrencyEvent());
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
