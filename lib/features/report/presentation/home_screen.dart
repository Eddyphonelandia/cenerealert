import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/disclaimer_bar.dart';
import '../../account/presentation/account_link_sheet.dart';
import '../../map/presentation/live_map.dart';
import '../../map/presentation/time_filter_chips.dart';
import '../../checklist/presentation/checklist_screen.dart';
import '../../notifications/presentation/notification_radius_sheet.dart';
import '../../saved_places/presentation/saved_places_screen.dart';
import '../../vona_feed/presentation/vona_feed_card.dart';
import 'report_button.dart';

// Schermata principale: la mappa è il cuore dell'app e occupa lo schermo
// intero (full-bleed), con la UI che ci galleggia sopra — niente cornici,
// niente chrome inutile, come da design system. Il disclaimer resta
// sempre visibile in basso, come richiesto dai vincoli non negoziabili.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      bottomNavigationBar: const DisclaimerBar(),
      body: Stack(
        children: [
          const LiveMap(),
          SafeArea(
            child: Stack(
              children: [
                const _StatusIndicator(),
                const Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(child: TimeFilterChips()),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _IconCircleButton(
                        icon: Icons.person_outline,
                        onTap: () => AccountLinkSheet.show(context),
                      ),
                      const SizedBox(height: 8),
                      _IconCircleButton(
                        icon: Icons.bookmark_outline,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SavedPlacesScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IconCircleButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => NotificationRadiusSheet.show(context),
                      ),
                      const SizedBox(height: 8),
                      _IconCircleButton(
                        icon: Icons.checklist_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChecklistScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  right: 20,
                  bottom: 32,
                  child: ReportButton(),
                ),
                const Positioned(
                  left: 16,
                  bottom: 32,
                  child: VonaFeedCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated.withOpacity(0.78),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.darkTextSecondary),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceElevated.withOpacity(0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Text(
          'CenereAlert · in linea',
          style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
        ),
      ),
    );
  }
}
