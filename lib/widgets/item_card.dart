import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/item_model.dart';
import '../utils/constants.dart';
import '../screens/home/item_detail_screen.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;

  const ItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLost = item.itemType == ItemType.lost;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailScreen(item: item),
              ),
            );
          },
      child: Card(
        elevation: 0,
        color: isDark ? AppColors.darkSurface : Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image,
                                size: 50, color: Colors.grey),
                          ),
                        ),
                ],
              ),
            ),
            // Content
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Heart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Optional Date / Timeago could be added here
                    const Spacer(),
                    // Bottom Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLost ? AppColors.primary : AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          // Tap triggers card tap
                          if (onTap != null) {
                            onTap!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ItemDetailScreen(item: item),
                              ),
                            );
                          }
                        },
                        child: Text(
                          isLost ? 'Lost' : 'Found',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
