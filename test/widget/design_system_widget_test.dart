import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tech_gadol_catalog/core/theme/app_theme.dart';
import 'package:tech_gadol_catalog/data/models/product_model.dart';
import 'package:tech_gadol_catalog/presentation/widgets/design_system/app_badges.dart';
import 'package:tech_gadol_catalog/presentation/widgets/design_system/app_search_bar.dart';
import 'package:tech_gadol_catalog/presentation/widgets/design_system/app_states.dart';
import 'package:tech_gadol_catalog/presentation/widgets/design_system/category_chip.dart';
import 'package:tech_gadol_catalog/presentation/widgets/product/product_card.dart';

Widget _wrapWithMaterial(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

const _mockProduct = ProductModel(
  id: 1,
  title: 'Test Product',
  description: 'Description',
  price: 99.99,
  discountPercentage: 10.0,
  rating: 4.5,
  stock: 20,
  brand: 'Test Brand',
  category: 'electronics',
  thumbnail: '',
  images: [],
);

void main() {
  group('AppSearchBar', () {
    testWidgets('renders with hint text', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppSearchBar(hintText: 'Search something...')),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search something...'), findsOneWidget);
    });

    testWidgets('calls onChanged when text is entered', (tester) async {
      String? captured;
      await tester.pumpWidget(
        _wrapWithMaterial(AppSearchBar(
          hintText: 'Search',
          onChanged: (val) => captured = val,
        )),
      );

      await tester.enterText(find.byType(TextField), 'phone');
      expect(captured, 'phone');
    });

    testWidgets('shows clear icon when text is entered', (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(const AppSearchBar()));

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('clears text when clear button is tapped', (tester) async {
      String? clearedVal;
      await tester.pumpWidget(
        _wrapWithMaterial(AppSearchBar(
          onChanged: (val) => clearedVal = val,
          onClear: () {},
        )),
      );

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pump();

      expect(clearedVal, '');
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });

    testWidgets('does not show clear icon when empty', (tester) async {
      await tester.pumpWidget(_wrapWithMaterial(const AppSearchBar()));
      await tester.pump();
      expect(find.byIcon(Icons.cancel_rounded), findsNothing);
    });
  });

  group('CategoryChip', () {
    testWidgets('renders label correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(CategoryChip(
          label: 'smartphones',
          isSelected: false,
          onTap: () {},
        )),
      );

      expect(find.text('Smartphones'), findsOneWidget);
    });

    testWidgets('hyphenated label is formatted correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(CategoryChip(
          label: 'skin-care',
          isSelected: false,
          onTap: () {},
        )),
      );

      expect(find.text('Skin Care'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrapWithMaterial(CategoryChip(
          label: 'laptops',
          isSelected: false,
          onTap: () => tapped = true,
        )),
      );

      await tester.tap(find.byType(FilterChip));
      expect(tapped, isTrue);
    });
  });

  group('AppPriceBadge', () {
    testWidgets('shows price unavailable for negative price', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppPriceBadge(price: -1)),
      );

      expect(find.text('Price unavailable'), findsOneWidget);
    });

    testWidgets('shows price unavailable for null price', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppPriceBadge(price: null)),
      );

      expect(find.text('Price unavailable'), findsOneWidget);
    });

    testWidgets('shows formatted price without discount', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppPriceBadge(price: 99.99)),
      );

      expect(find.text('\$99.99'), findsOneWidget);
    });

    testWidgets('shows discounted and original price when discount > 0', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(
          const AppPriceBadge(price: 100.0, discountPercentage: 20.0),
        ),
      );

      expect(find.text('\$80.00'), findsOneWidget);
      expect(find.text('\$100.00'), findsOneWidget);
      expect(find.text('-20%'), findsOneWidget);
    });
  });

  group('AppStockBadge', () {
    testWidgets('shows "In Stock" for high stock', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppStockBadge(stock: 100)),
      );

      expect(find.text('In Stock'), findsOneWidget);
    });

    testWidgets('shows low stock warning for < 10 items', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppStockBadge(stock: 4)),
      );

      expect(find.text('Only 4 left'), findsOneWidget);
    });

    testWidgets('shows "Out of Stock" for 0 stock', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppStockBadge(stock: 0)),
      );

      expect(find.text('Out of Stock'), findsOneWidget);
    });
  });

  group('AppRatingBadge', () {
    testWidgets('displays rating value', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppRatingBadge(rating: 4.7)),
      );

      expect(find.text('4.7'), findsOneWidget);
    });
  });

  group('ProductCard', () {
    testWidgets('displays product title and brand', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(ProductCard(
          product: _mockProduct,
          onTap: () {},
        )),
      );

      expect(find.text('Test Product'), findsOneWidget);
      expect(find.text('Test Brand'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _wrapWithMaterial(ProductCard(
          product: _mockProduct,
          onTap: () => tapped = true,
        )),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('highlights when selected', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(ProductCard(
          product: _mockProduct,
          onTap: () {},
          isSelected: true,
        )),
      );

      // Selected state: AnimatedContainer should have border
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect((decoration.border as Border).top.width, 1.5);
    });
  });

  group('AppErrorState', () {
    testWidgets('shows message and retry button', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        _wrapWithMaterial(AppErrorState(
          message: 'Connection failed',
          onAction: () => retried = true,
        )),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);
    });

    testWidgets('shows no button when onAction is null', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppErrorState(
          message: 'Error occurred',
        )),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('AppEmptyState', () {
    testWidgets('shows title and subtitle', (tester) async {
      await tester.pumpWidget(
        _wrapWithMaterial(const AppEmptyState(
          title: 'No results',
          subtitle: 'Try different terms',
        )),
      );

      expect(find.text('No results'), findsOneWidget);
      expect(find.text('Try different terms'), findsOneWidget);
    });

    testWidgets('action button calls onAction', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrapWithMaterial(AppEmptyState(
          title: 'Empty',
          actionLabel: 'Clear All',
          onAction: () => called = true,
        )),
      );

      await tester.tap(find.text('Clear All'));
      expect(called, isTrue);
    });
  });
}
