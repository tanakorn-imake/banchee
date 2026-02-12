import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/view_preference_provider.dart';
import '../../config/theme.dart';

class ViewToggleWidget extends StatelessWidget {
  const ViewToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pref = context.watch<ViewPreferenceProvider>();
    final isFamily = pref.isFamilyView;

    return GestureDetector(
      onTap: () => pref.toggleView(!isFamily),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon ส่วนตัว
            Icon(
              Icons.person,
              size: 16,
              color: !isFamily ? AppColors.primaryGold : Colors.white24,
            ),

            const SizedBox(width: 8),

            // Switch เล็กๆ (วาดเองเพื่อให้สวย)
            Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: isFamily ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icon ครอบครัว
            Icon(
              Icons.home,
              size: 16,
              color: isFamily ? AppColors.primaryGold : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}