import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/auth_cubit.dart';
import '../../business_logic/auth_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>()..load(),
      child: const _AuthView(),
    );
  }
}

class _AuthView extends StatelessWidget {
  const _AuthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('auth.title'.tr())),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          AuthInitial() => const SizedBox.shrink(),
          AuthLoading() => const Center(child: LoadingShimmer()),
          AuthError()   => ErrorState(
              message: (state as AuthError).message,
              onRetry: () => context.read<AuthCubit>().load(),
            ),
          AuthLoaded()  => _AuthList(
              items: (state as AuthLoaded).items,
            ),
        },
      ),
    );
  }
}

class _AuthList extends StatelessWidget {
  const _AuthList({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: 'auth.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
