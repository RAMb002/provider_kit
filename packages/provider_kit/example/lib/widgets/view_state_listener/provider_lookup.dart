import 'package:example/toast.dart';
import 'package:example/widgets/shared/notifiers/direct_movie_notifier.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:provider_kit/provider_kit.dart';

/// Demonstrates resolving a Provider-managed notifier with .of.
class ViewStateListenerProviderExample extends StatelessWidget {
  const ViewStateListenerProviderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MoviesNotifier(),
      builder: (context, _) =>
          ViewStateListener.of<MoviesNotifier, List<String>>(
        dataStateListener: (context, movies) {
          context.showSnackBar(
            'Provider loaded ${movies.length} movies.',
          );
        },
        child: const Text("Listening to movies notifier"),
      ),
    );
  }
}
