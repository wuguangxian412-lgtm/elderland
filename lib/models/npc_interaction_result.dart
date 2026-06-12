import 'interaction_record.dart';
import 'player.dart';

class NpcInteractionResult {
  final Player player;
  final InteractionRecord? record;

  const NpcInteractionResult({required this.player, required this.record});
}
