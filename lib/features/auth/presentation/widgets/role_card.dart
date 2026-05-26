import 'package:flutter/material.dart';
import 'package:trueschoolapp/features/auth/data/models/user_role.dart';

class RoleCard extends StatelessWidget {
  final UserRole role;
  final VoidCallback onTap;

  const RoleCard({
    super.key,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: role.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              role.icon,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              role.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
