import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/collection_record.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final CollectionStatus status;

  @override
  Widget build(BuildContext context) {
    final synced = status == CollectionStatus.synced;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: synced ? AppColors.successBg : AppColors.pendingBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: synced ? AppColors.success : AppColors.goldLink,
        ),
      ),
    );
  }
}
