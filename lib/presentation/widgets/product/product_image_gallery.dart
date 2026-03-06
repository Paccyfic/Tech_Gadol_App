import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_theme.dart';
import '../design_system/app_network_image.dart';

class ProductImageGallery extends StatefulWidget {
  final List<String> images;
  final int productId;
  final double height;

  const ProductImageGallery({
    super.key,
    required this.images,
    required this.productId,
    this.height = 320,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return AppNetworkImage(
        imageUrl: null,
        width: double.infinity,
        height: widget.height,
        heroTag: 'product-image-${widget.productId}',
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return AppNetworkImage(
                imageUrl: widget.images[index],
                width: double.infinity,
                height: widget.height,
                fit: BoxFit.cover,
                heroTag: index == 0 ? 'product-image-${widget.productId}' : null,
              );
            },
          ),
        ),

        // Page indicator
        if (widget.images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: widget.images.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: Theme.of(context).colorScheme.primary,
                  dotColor: Colors.white.withOpacity(0.6),
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
