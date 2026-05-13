import 'package:flutter/widgets.dart';

import '../../data/models/enums.dart';
import 'app_chip.dart';

class PoStatusPill extends StatelessWidget {
  const PoStatusPill(this.status, {super.key});
  final PoStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      PoStatus.newPo => const AppChip(label: 'New'),
      PoStatus.inProgress => const AppChip(label: 'In progress', tone: ChipTone.warn),
      PoStatus.fullyDelivered =>
        const AppChip(label: 'Fully delivered', tone: ChipTone.green),
      PoStatus.partiallyDelivered =>
        const AppChip(label: 'Partially delivered', tone: ChipTone.warn),
    };
  }
}

class ItemStatusPill extends StatelessWidget {
  const ItemStatusPill(this.status, {super.key});
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      ItemStatus.pending => const AppChip(label: 'Pending'),
      ItemStatus.inProgress => const AppChip(label: 'In progress', tone: ChipTone.warn),
      ItemStatus.delivered => const AppChip(label: 'Delivered', tone: ChipTone.green),
      ItemStatus.missing => const AppChip(label: 'Missing', tone: ChipTone.danger),
    };
  }
}
