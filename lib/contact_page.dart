import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme_controller.dart';

class ContactPage extends StatelessWidget {
  final VoidCallback? onOpenDrawer;

  const ContactPage({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget infoTile({
      required IconData icon,
      required String title,
      required String value,
    }) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: scheme.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(value),
          onTap: () {
            HapticFeedback.selectionClick();
          },
        ),
      );
    }

    Widget themeOption({
      required BuildContext context,
      required ThemeMode value,
      required IconData icon,
      required String title,
      required String subtitle,
    }) {
      return ValueListenableBuilder<ThemeMode>(
        valueListenable: AppThemeController.themeMode,
        builder: (context, selectedMode, _) {
          final selected = selectedMode == value;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.65),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                AppThemeController.setThemeMode(value);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selected
                          ? scheme.primary.withValues(alpha: 0.15)
                          : scheme.surfaceContainerHighest,
                      child: Icon(
                        icon,
                        color: selected ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(
                              Icons.check_circle,
                              key: ValueKey(value.name),
                              color: scheme.primary,
                            )
                          : const SizedBox(
                              key: ValueKey('empty'),
                              width: 24,
                              height: 24,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () {
            Navigator.of(context).pop();
            onOpenDrawer?.call();
          },
        ),
        title: const Text('Contact'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: scheme.primary.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.support_agent,
                      size: 34,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Contact Wealtha",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Reach out to us for help, support, or questions about your expenses.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose light mode, dark mode, or follow the device setting.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  themeOption(
                    context: context,
                    value: ThemeMode.light,
                    icon: Icons.light_mode_rounded,
                    title: 'Light Mode',
                    subtitle: 'Bright, clean interface',
                  ),
                  const SizedBox(height: 10),
                  themeOption(
                    context: context,
                    value: ThemeMode.dark,
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: 'Low-light, higher contrast look',
                  ),
                  const SizedBox(height: 10),
                  themeOption(
                    context: context,
                    value: ThemeMode.system,
                    icon: Icons.settings_suggest_rounded,
                    title: 'Use Device Setting',
                    subtitle: 'Automatically follow system theme',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          infoTile(
            icon: Icons.email_outlined,
            title: "Email",
            value: "support@wealthaapp.com",
          ),
          infoTile(
            icon: Icons.phone_outlined,
            title: "Phone",
            value: "(416) 555-0142",
          ),
          infoTile(
            icon: Icons.phone_in_talk_outlined,
            title: "Alternate Phone",
            value: "(647) 555-0198",
          ),
          infoTile(
            icon: Icons.location_on_outlined,
            title: "Address",
            value: "120 Simcoe Street, Toronto, ON, Canada",
          ),
        ],
      ),
    );
  }
}