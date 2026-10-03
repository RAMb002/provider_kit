import 'package:example/example_kits/providers/0_state_notifier.dart';
import 'package:example/scaffold_with_multi_button.dart';
import 'package:example/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MultiStateListenerExample extends StatefulWidget {
  const MultiStateListenerExample({super.key});

  @override
  State<MultiStateListenerExample> createState() =>
      _MultiStateListenerExampleState();
}

class _MultiStateListenerExampleState extends State<MultiStateListenerExample> {
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
      MultiStateListener(
        providers: () => (
          profile: profileProvider.watch,
          cart: cartProvider.watch,
          notifications: notificationProvider.watch,
        ),
        listener: (context, state) {
          context.showToast(
            'Profile: ${state.profile}, '
            'Cart: ${state.cart}, '
            'Notifications: ${state.notifications}',
          );
        },
        child: const Text(
          'Listening to profile, cart, and notifications',
        ),
      ),
    );
  }

  Widget _buildScaffold(Widget child) {
    return ScaffoldWithMultiButton(
      title: 'Multi State Listener',
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
