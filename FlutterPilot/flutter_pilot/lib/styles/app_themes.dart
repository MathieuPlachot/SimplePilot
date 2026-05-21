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
    inputDecorationTheme: InputDecorationTheme(
      // Floating label color
      floatingLabelStyle: TextStyle(
        color: AppColors.muted,
        fontWeight: FontWeight.w600,
      ),

      // Label color (when not floating)
      labelStyle: TextStyle(color: Colors.grey),

      // Text field borders
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: AppColors.muted, // unfocused border
          width: 1.4,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(
          color: Colors.blueAccent, // focused border
          width: 2,
        ),
      ),

      // Text style inside input
      hintStyle: TextStyle(color: Colors.red),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 16)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 22),
        ),
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.muted, width: 1.5),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        foregroundColor: WidgetStateProperty.all(AppColors.textDark),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(double.infinity, 16)),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 22)),

        // Remove selected background
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return Colors.transparent;
        }),

        // Border color
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return BorderSide(color: AppColors.primary, width: 1.5);
          }
          return BorderSide(color: AppColors.muted, width: 1.5);
        }),

        // Rounded left/right corners
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),

        // Text color for selected + non-selected
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textDark;
        }),
      ),
    ),
  );
}
