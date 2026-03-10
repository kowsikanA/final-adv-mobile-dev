import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
            backgroundColor: scheme.primary.withOpacity(0.12),
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

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: scheme.primary.withOpacity(0.15),
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
    );
  }
}