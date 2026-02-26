import 'package:flutter/material.dart';

import '../../../theme/avoo_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    required this.children,
    this.padding = const EdgeInsets.all(20),
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AvooColors.softShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AvooColors.ink,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class ExpansionSection extends StatelessWidget {
  const ExpansionSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.leadingIcon,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvooColors.line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          iconColor: AvooColors.green,
          collapsedIconColor: AvooColors.muted,
          leading: leadingIcon != null
              ? Icon(leadingIcon, color: AvooColors.muted)
              : null,
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
          ),
          childrenPadding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 20,
            top: 4,
          ),
          children: children,
        ),
      ),
    );
  }
}
