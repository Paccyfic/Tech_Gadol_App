# Tech Gadol – Product Catalog App

A Flutter assessment submission demonstrating a production-grade product catalog application with a custom design system, Bloc state management, responsive layout, deep linking, offline support, animations, and comprehensive test coverage.

---

## 1. Setup & Run Instructions

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | `3.19.x` (stable) |
| Dart | `3.3.x` |
| Xcode (iOS) | `15.x` |
| Android SDK | API 34+ |

### Steps
```bash
# 1. Clone the repository
git clone https://github.com/Paccyfic/tech_gadol_catalog.git
cd tech_gadol_catalog

# 2. Install dependencies
flutter pub get

# 3. Generate Hive type adapters (required once before first run)
dart run build_runner build --delete-conflicting-outputs

# 4. Run the app (debug)
flutter run

# 5. Run on a specific device
flutter run -d chrome           # Web
flutter run -d ios              # iOS Simulator
flutter run -d android          # Android Emulator

# 6. Run in release mode
flutter run --release
```

### Running Tests
```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Building
```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 2. Architecture Overview

### Folder Structure
```
lib/
├── main.dart                          # App entry point (Hive init + flutter_animate config)
├── core/
│   ├── constants/
│   │   └── api_constants.dart         # Base URL, endpoints, debounce ms
│   ├── di/
│   │   ├── hive_init.dart             # Hive initialisation + box opening
│   │   └── injection.dart             # GetIt service locator registration
│   ├── errors/
│   │   ├── exceptions.dart            # AppException hierarchy
│   │   └── failures.dart              # Failure hierarchy (for Either)
│   ├── network/
│   │   └── network_client.dart        # Dio client with interceptors
│   ├── router/
│   │   └── app_router.dart            # GoRouter config + deep linking
│   └── theme/
│       └── app_theme.dart             # ThemeData + design tokens
│
├── data/
│   ├── datasources/
│   │   ├── product_remote_datasource.dart
│   │   └── local/
│   │       ├── hive_constants.dart          # Box names, TTL, type IDs
│   │       ├── product_hive_model.dart      # Hive-annotated model
│   │       ├── product_hive_model.g.dart    # Generated type adapter
│   │       └── product_local_datasource.dart # Cache read/write abstraction
│   ├── models/
│   │   └── product_model.dart         # JSON serialization + validation
│   └── repositories/
│       └── product_repository_impl.dart # Cache-first + stale-while-revalidate
│
├── domain/
│   └── repositories/
│       └── product_repository.dart    # Abstract interface
│
└── presentation/
    ├── bloc/
    │   ├── category/                  # CategoryCubit
    │   ├── product_detail/            # ProductDetailBloc
    │   ├── product_list/              # ProductListBloc (cache-aware)
    │   └── theme/                     # ThemeCubit
    ├── pages/
    │   ├── product_list_page.dart     # Cache banner + animated list
    │   ├── product_detail_page.dart   # Staggered entrance animations
    │   └── showcase_page.dart         # Design system component showcase
    └── widgets/
        ├── design_system/
        │   ├── app_badges.dart        # AppPriceBadge, AppRatingBadge, AppStockBadge
        │   ├── app_network_image.dart # Cached image with Hero support
        │   ├── app_search_bar.dart    # Search input with animated clear
        │   ├── app_states.dart        # AppErrorState, AppEmptyState
        │   ├── cache_banner.dart      # Offline / stale cache indicator
        │   ├── category_chip.dart     # CategoryChip + CategoryChipRow
        │   └── skeleton_loader.dart   # Shimmer skeleton
        ├── product/
        │   ├── product_card.dart      # Staggered animated list card
        │   └── product_image_gallery.dart # Swipeable gallery with Hero
        └── responsive_layout.dart     # MasterDetailLayout + breakpoints
```

### State Management – Bloc/Cubit

| Bloc/Cubit | Responsibility |
|---|---|
| `ProductListBloc` | Products list, search, category filter, pagination, pull-to-refresh, cache state |
| `ProductDetailBloc` | Single product fetch and error/refresh handling |
| `CategoryCubit` | Fetch and cache category list |
| `ThemeCubit` | Light/dark/system theme toggle |

All states explicitly model: `initial`, `loading`, `loaded`, `error`, and `empty`. Events are sealed via abstract classes. States use `Equatable` for efficient rebuilds.

`ProductListState` carries two additional cache fields:
```dart
final bool isFromCache;   // true when data was served from Hive
final bool isCacheStale;  // true when TTL has expired
```

The `_ProductListSilentRefreshRequested` event is an internal-only event that triggers a background network call after stale data is shown — the user sees instant data while a fresh fetch happens invisibly.

### Dependency Injection

`GetIt` is used as the service locator. All registrations live in `core/di/injection.dart`:

- **Singletons**: `Logger`, `NetworkClient`, `ProductRepository`, `ProductLocalDataSource`, `ThemeCubit`
- **Factories**: All Blocs (a new instance per page/use)

### Navigation

`GoRouter` handles:
- Declarative routing via named routes
- Deep linking: `/products/:id`
- Responsive routing: on tablet (≥768px), list and detail are shown side-by-side without push navigation

---

## 3. Screenshots

| Screen | Description |
|---|---|
| ![Product list – light theme](assets/images/Catalog.png) | Main product catalog showing category chips, search bar, pricing badges, and pagination in light mode. |
| ![Product list – dark theme](assets/images/dark_mode.png) | Main product catalog in dark mode. |
| ![Product detail – dark theme](assets/images/Product_detail.png) | Detailed product view with gallery, pricing, rating, stock status, and metadata. |
| ![Design system showcase](assets/images/component_showcase.png) | Showcase page demonstrating all design system components. |

---

## 4. Design System Rationale

### Design Tokens (`app_theme.dart`)

All visual constants are centralized:
```dart
AppRadius.md            // Border radii
AppSpacing.lg           // Spacing grid (4pt base)
AppDuration.fast        // Animation durations
AppTheme.primaryColor   // Brand palette
AppTheme.warningColor   // Semantic colour (ratings, stale banner)
AppTheme.infoColor      // Semantic colour (fresh cache banner)
```

### Component API Decisions

**`AppNetworkImage`**
- Wraps `CachedNetworkImage` for lazy loading and disk caching
- Validates URL format before attempting fetch; logs warning if invalid
- Graceful degradation: shimmer → image → broken image placeholder
- Accepts optional `heroTag` for shared element transitions (Hero source is set on navigation, not statically in the list — prevents duplicate tag errors when multiple cards share a subtree)

**`AppSearchBar`**
- Debouncing is handled at the Bloc layer via `Timer`; the widget is stateless
- Animated clear button that appears/disappears on text change

**`CategoryChipRow`**
- Stateless; selected state driven by the parent Bloc
- "All" chip at index 0 deselects any active filter

**`AppPriceBadge`**
- Handles `null` and negative price → "Price unavailable"
- Shows original + discounted price with % badge when discount > 0

**`AppStockBadge`**
- Green ≥10, amber <10, red 0
- Copy: "In Stock", "Only N left", "Out of Stock"

**`CacheBanner`**
- Blue info banner when data is fresh-from-cache
- Amber warning banner when stale (tappable to force refresh)
- Slides in from top with `flutter_animate` on first render

**`ProductCard`**
- `isSelected` prop for tablet master-detail highlight
- `index` prop drives stagger delay for entrance animation
- No Hero tag on the card itself — tag is applied at navigation time to the gallery's first image

### Theming

Both `lightTheme` and `darkTheme` are defined from a `ColorScheme.fromSeed` base (Material 3). All components use `Theme.of(context)` — zero hardcoded colors inside widgets.

---

## 5. Optional Enhancements

### Enhancement A: Component Showcase ✅

Accessible via the book icon (📖) in the AppBar at `/showcase`. Displays every design system component with all variants:

- `AppSearchBar`
- `CategoryChips` (horizontal scrollable)
- `ProductCard` (default + selected state)
- `AppNetworkImage` (valid URL / invalid URL / null)
- `CacheBanner` (fresh / stale)
- `AppPriceBadge` (with discount / without / unavailable)
- `AppRatingBadge` (green / amber / red thresholds)
- `AppStockBadge` (in stock / low / out)
- Skeleton Loader
- `AppErrorState` (with retry action)
- `AppEmptyState` (with clear action)

Includes a live light/dark theme toggle in the AppBar.

---

### Enhancement B: Offline Support ✅

**Technology chosen: Hive**

| Criterion | Hive | Isar | Drift (sqflite) |
|---|---|---|---|
| Setup complexity | Low | Medium | High (SQL schema + migrations) |
| Performance | Excellent (binary key-value) | Excellent | Good |
| Dart-native | ✅ | ✅ | ❌ |
| Bundle size | ~150KB | ~1.5MB | ~300KB |
| Schema migrations | Not needed for a cache | Built-in | SQL migrations |

For a product **cache** (not a relational store), Hive's flat key-value binary format is the cleanest fit. If the app grew to need complex queries across entities (e.g. orders joining products), Drift or Isar would be the right migration path.

**Architecture**
```
ProductLocalDataSource (abstract interface)
└── ProductLocalDataSourceImpl
      ├── Box<ProductHiveModel>  ← products keyed by product.id
      └── Box<dynamic>           ← lastFetched timestamp, total count
```

`ProductHiveModel` is deliberately separate from `ProductModel` — the domain model stays free of Hive annotations. The generated adapter is committed to the repo so `build_runner` does not need to be re-run after cloning.

**Cache strategy: stale-while-revalidate**
```
App open
  └─ hasCachedData?
        ├─ No  → fetch from network → cache page 0 → show
        └─ Yes → isCacheExpired (TTL = 1 hour)?
                    ├─ No  → serve fresh cache immediately (no network call)
                    └─ Yes → serve stale cache immediately (instant UI)
                                └─ trigger _SilentRefreshRequested (background)
                                      └─ on success → update list silently
```

Pull-to-refresh always forces a network call and replaces the cache.

**Visual indicators**

- `CacheBanner` slides in at the top of the list whenever data is served locally
- Fresh: blue pin icon — "Loaded from cache"
- Stale: amber sync icon — "Showing cached data · tap to refresh" (tappable)

---

### Enhancement C: Animation & Polish ✅

**Staggered list item entrance**

Each `ProductCard` uses `flutter_animate` with `40ms × (index % 20)` delay. The modulo cap prevents excessive delays on large lists. Cards fade in and slide up 12% of their height.
```dart
.animate()
.fadeIn(delay: Duration(milliseconds: 40 * (index % 20)), duration: AppDuration.slow)
.slideY(begin: 0.12, end: 0, delay: ..., curve: Curves.easeOutCubic)
```

**Hero / shared element transitions**

The first image in `ProductImageGallery` carries `heroTag: 'product-image-${product.id}'`. Flutter's Hero system animates this image between its card position and the full-width gallery on navigation. The tag is absent from `ProductCard` itself — placed only on the destination — to avoid the duplicate-tag assertion that occurs when multiple cards are visible in the same subtree simultaneously.

**Product detail staggered entrance**

After the Hero transition completes, six content sections cascade in with 60ms stagger: category badge → title/brand → price → rating/stock → description → details table.
```dart
Widget animSection(Widget child, int step) => child
    .animate()
    .fadeIn(delay: Duration(milliseconds: 60 * step), duration: 350.ms)
    .slideY(begin: 0.08, end: 0, delay: ..., curve: Curves.easeOutCubic);
```

**Smooth theme toggle**

The AppBar theme icon uses `AnimatedSwitcher` with `RotationTransition (0.75→1.0 turns)` combined with `FadeTransition` — a smooth spinning fade between sun and moon icons rather than an instant swap.

**Pull-to-refresh polish**

`RefreshIndicator` uses the app's `colorScheme.primary` and `colorScheme.surface` so the spinner feels integrated rather than defaulting to system green.

**`CacheBanner` entrance**

The banner slides down from the top (`slideY(begin: -0.5)`) with a fade-in when cache data is detected, drawing attention without being disruptive.

---

## 6. Limitations & Known Trade-offs

**Search + category combined**: When both a search query and a category filter are active, search takes priority (calls the search endpoint). True intersection would require either a backend query parameter or client-side filtering of search results.

**No paginated search**: The DummyJSON search endpoint supports `skip`/`limit` but paginated search was deprioritized in favor of correctness on the base list case.

**Cache scope**: Only the default (no filter, no search) product list is cached. Search results and category-filtered results are always fetched fresh — intentional, as these are ephemeral queries and caching them would require keying by `{query}:{category}:{skip}`.

**No integration / golden tests**: Unit and widget tests are comprehensive but golden image tests and full integration tests were out of scope for the assessment timeline.

**No accessibility Semantics wrappers**: `Semantics` nodes have not been added to badges and cards. This would be the next accessibility pass.

---

## 7. AI Tools Usage

**Claude (Anthropic)** was used during this assessment as follows:

| Area | Usage |
|---|---|
| Boilerplate scaffolding | Generated initial Dio interceptor structure and GetIt registration pattern; reviewed and modified for this project's specific error hierarchy |
| Test case outlines | Suggested initial Bloc test scaffolding; all edge cases (negative price, 404 vs general error, debounce, stale cache silent refresh) were written manually |
| README structure | Section headings suggested by AI; all content written from actual implementation decisions |

**What was changed or refined from AI suggestions**

- The `_ErrorInterceptor` was refactored from a generic catch-all to map each `DioExceptionType` to the correct custom exception
- The responsive layout uses `LayoutBuilder` + `MasterDetailLayout` rather than nested navigators — a deliberate decision to avoid GoRouter `ShellRoute` complexity
- Hero tag placement (destination-only, not on list card) was a manual fix after the duplicate-tag assertion crash
- The stale-while-revalidate pattern using an internal `_ProductListSilentRefreshRequested` event was designed from scratch
- All token values, component API shapes, and animation timings reflect personal design decisions

---

## API Reference

**Base URL**: `https://dummyjson.com`

| Endpoint | Usage |
|---|---|
| `GET /products?limit=20&skip=0` | Paginated product list |
| `GET /products/search?q=...` | Server-side search |
| `GET /products/categories` | All categories |
| `GET /products/category/{name}` | Filter by category |
| `GET /products/{id}` | Single product detail |