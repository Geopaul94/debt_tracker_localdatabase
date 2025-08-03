
import 'package:debt_tracker/domain/entities/transaction_entity.dart';
import 'package:debt_tracker/injection/injection_container.dart';
import 'package:debt_tracker/presentation/bloc/transacton_bloc/transaction_bloc.dart';
import 'package:debt_tracker/presentation/pages/add_transaction_page.dart';
import 'package:debt_tracker/presentation/pages/currency_selection_page.dart';
import 'package:debt_tracker/presentation/pages/debt_detail_page.dart';
import 'package:debt_tracker/presentation/pages/first_time_setup_page.dart';
import 'package:debt_tracker/presentation/pages/home_page.dart';
import 'package:debt_tracker/presentation/pages/splash_screen.dart';
import 'package:debt_tracker/presentation/pages/transaction_history.dart';
import 'package:debt_tracker/presentation/pages/auth_screen.dart';
import 'package:debt_tracker/presentation/pages/trash_page.dart';
import 'package:debt_tracker/presentation/pages/premium_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OweTrackerApp extends StatelessWidget {
  const OweTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Design size based on iPhone X
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return BlocProvider(
          create: (context) => serviceLocator<TransactionBloc>(),
          child: MaterialApp(
            title: 'Debt Tracker',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal, // Primary color for the app
                brightness: Brightness.light,
              ),
              primarySwatch: Colors.teal,
              textTheme: TextTheme(
                titleLarge: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
                titleMedium: TextStyle(fontSize: 16.sp),
                bodyMedium: TextStyle(fontSize: 14.sp),
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.teal, // AppBar background
                foregroundColor: Colors.white, // AppBar text and icon color
                elevation: 4.0,
                titleTextStyle: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700], // Button background
                  foregroundColor: Colors.white, // Button text color
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              cardTheme: CardTheme(
                elevation: 3.0,
                margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 5.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const   BorderSide(color: Colors.teal),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Colors.teal, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.teal[800]),
              ),
              useMaterial3: true,
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/first-time-setup': (context) => const FirstTimeSetupPage(),
              '/auth': (context) => const AuthScreen(),
              '/home': (context) => const HomePage(),
              '/add-transaction': (context) => const AddTransactionPage(),
              '/currency-selection': (context) => const CurrencySelectionPage(),
          //    '/cloud-backup': (context) => CloudBackupPage(),
              '/trash': (context) => const TrashPage(),
              '/premium': (context) => const PremiumPage(),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/debt-detail':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder:
                        (context) => DebtDetailPage(
                          type: args?['type'] ?? TransactionType.iOwe,
                        ),
                  );
                case '/transaction-history':
                  final args = settings.arguments as Map<String, dynamic>?;
                  return MaterialPageRoute(
                    builder:
                        (context) => TransactionHistoryPage(
                          transaction: args?['transaction'],
                        ),
                  );
                default:
                  return MaterialPageRoute(builder: (context) => const HomePage());
              }
            },
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}
