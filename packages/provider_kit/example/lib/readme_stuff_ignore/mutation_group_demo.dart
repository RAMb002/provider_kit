import 'package:example/readme_stuff_ignore/demos/widgets/demo_card.dart';
import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MutationGroupDemo extends StatefulWidget {
  const MutationGroupDemo({
    super.key,
  });

  @override
  State<MutationGroupDemo> createState() => _MutationGroupDemoState();
}

class _MutationGroupDemoState extends State<MutationGroupDemo> {
  final MutationGroup<void> _likeGroup = MutationGroup<void>();

  late final List<DemoUser> _users;

  final Map<int, bool> _likedUsers = {};

  @override
  void initState() {
    super.initState();

    _users = List.generate(
      20,
      (index) => DemoUser(
        id: index + 1,
        name: _names[index % _names.length],
        username: '@${_names[index % _names.length].toLowerCase()}',
      ),
    );
  }

  @override
  void dispose() {
    _likeGroup.dispose();
    super.dispose();
  }

  Mutation<void> _mutationFor(DemoUser user) {
    return _likeGroup(user.id);
  }

  Future<void> _toggleLike(DemoUser user) async {
    final currentlyLiked = _likedUsers[user.id] ?? false;
    final shouldLike = !currentlyLiked;

    final mutation = _mutationFor(user);

    mutation.reset();

    await mutation.run(() async {
      await Future<void>.delayed(
        const Duration(milliseconds: 900),
      );
    });

    if (!mounted) return;

    setState(() {
      _likedUsers[user.id] = shouldLike;
    });

    // 🔁 Reset mutation to idle so the button becomes interactive again
    mutation.reset();
  }

  static const _names = [
    'Alex',
    'Sarah',
    'David',
    'Emma',
    'Noah',
    'Mia',
    'Liam',
    'Olivia',
    'Ethan',
    'Ava',
  ];

  @override
  Widget build(BuildContext context) {
    return DemoCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: SizedBox(
          height: 320,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final user = _users[index];

              return _UserLikeItem(
                key: ValueKey(user.id),
                user: user,
                mutation: _mutationFor(user),
                isLiked: _likedUsers[user.id] ?? false,
                onToggleLike: () => _toggleLike(user),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _UserLikeItem extends StatelessWidget {
  const _UserLikeItem({
    super.key,
    required this.user,
    required this.mutation,
    required this.isLiked,
    required this.onToggleLike,
  });

  final DemoUser user;
  final Mutation<void> mutation;
  final bool isLiked;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<MutationState<void>>(
      provider: mutation,
      builder: (_, state, __) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE7E9EE),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  user.name.substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF3D7EFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _LikeAction(
                state: state,
                isLiked: isLiked,
                onPressed: onToggleLike,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LikeAction extends StatelessWidget {
  const _LikeAction({
    required this.state,
    required this.isLiked,
    required this.onPressed,
  });

  final MutationState<void> state;
  final bool isLiked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return state.when(
      idle: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 19,
              color:
                  isLiked ? const Color(0xFFE05270) : const Color(0xFF6B7280),
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  isLiked ? const Color(0xFFFFEEF2) : const Color(0xFFEEF1F5),
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
            tooltip: isLiked ? 'Unlike' : 'Like',
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Color(0xFFE05270),
            ),
          ),
        ),
      ),
      success: (_) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLiked ? 'Liked' : 'Unliked',
            style: TextStyle(
              color:
                  isLiked ? const Color(0xFFE05270) : const Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 19,
            color: isLiked ? const Color(0xFFE05270) : const Color(0xFF6B7280),
          ),
        ],
      ),
      error: (_, __) => IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.refresh_rounded,
          size: 18,
          color: Color(0xFFE05270),
        ),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFFFEEF2),
          minimumSize: const Size(32, 32),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        tooltip: 'Retry',
      ),
    );
  }
}

class DemoUser {
  const DemoUser({
    required this.id,
    required this.name,
    required this.username,
  });

  final int id;
  final String name;
  final String username;
}
