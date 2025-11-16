import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(bodyMedium: TextStyle(color: AppColors.textDark)),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navbarBackground,
      foregroundColor: AppColors.textDark,
      elevation: 0,
    ),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.navbarBackground,
      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          );
        }
        return TextStyle(color: AppColors.textDark);
      }),
      iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: AppColors.primary);
        }
        return IconThemeData(color: AppColors.textDark);
      }),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.navbarBackground,
      selectedItemColor: AppColors.navbarSelected,
      unselectedItemColor: AppColors.navbarUnselected,
    ),
  );
}
