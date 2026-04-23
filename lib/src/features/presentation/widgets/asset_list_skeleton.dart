import 'package:flutter/material.dart';

class AssetListSkeleton extends StatelessWidget {
  const AssetListSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Container(
        height: 92,
        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 180,
              height: 16,
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
            ),
            const SizedBox(height: 8),
            Container(
              width: 140,
              height: 12,
              decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }
}
