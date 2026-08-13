import 'package:flutter/material.dart';
import 'package:provider_kit/provider_kit.dart';

class MutationDemo extends StatefulWidget {
  const MutationDemo({super.key});

  @override
  State<MutationDemo> createState() => _MutationDemoState();
}

class _MutationDemoState extends State<MutationDemo> {
  final mutation = Mutation<String>();

  @override
  void dispose() {
    mutation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await mutation.run(
      () async {
        await Future<void>.delayed(const Duration(seconds: 2));

        throw Exception('Something went wrong');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutation Demo'),
      ),
      body: Center(
        child: StateBuilder<MutationState<String>>(
          provider: mutation,
          builder: (context, state, child) {
            final isLoading = state.isLoading;
            final isError = state.isError;

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isError ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isError ? 'Failed' : 'Submit',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w500),
                    ),
            );
          },
        ),
      ),
    );
  }
}
