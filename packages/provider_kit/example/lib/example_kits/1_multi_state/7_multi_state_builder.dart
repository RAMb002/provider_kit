import 'package:example/example_kits/providers/0_state_notifier.dart';
import 'package:example/scaffold_with_multi_button.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiStateBuilderExample extends StatefulWidget {
  const MultiStateBuilderExample({super.key});

  @override
  State<MultiStateBuilderExample> createState() =>
      _MultiStateBuilderExampleState();
}

class _MultiStateBuilderExampleState extends State<MultiStateBuilderExample> {
  late ProfileProvider profileProvider;
  late CartProvider cartProvider;
  late NotificationProvider notificationProvider;

  @override
  void initState() {
    super.initState();
    profileProvider = ProfileProvider();
    cartProvider = CartProvider();
    notificationProvider = NotificationProvider();
  }

  @override
  void dispose() {
    profileProvider.dispose();
    cartProvider.dispose();
    notificationProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(
      StateBuilder.multi(
        providers: () => (
          profile: profileProvider.watch,
          cart: cartProvider.watch,
          notifications: notificationProvider.watch,
        ),
        builder: (context, state, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Profile: ${state.profile}'),
              Text('Cart items: ${state.cart}'),
              Text('Unread notifications: ${state.notifications}'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScaffold(Widget child) {
    return ScaffoldWithMultiButton(
      title: 'Multi State Builder',
      onTap1: cartProvider.addItem,
      onTap2: notificationProvider.addNotification,
      onTap3: profileProvider.updateName,
      label1: 'Cart',
      label2: 'Notifications',
      label3: 'Profile',
      icon1: Icons.shopping_cart,
      icon2: Icons.notifications,
      icon3: Icons.person,
      child: child,
    );
  }
}
