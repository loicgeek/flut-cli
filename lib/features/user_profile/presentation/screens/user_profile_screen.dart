import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../business_logic/user_profile_cubit.dart';
import '../../business_logic/user_profile_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<UserProfileCubit>()..load(),
      child: const _UserProfileView(),
    );
  }
}

class _UserProfileView extends StatelessWidget {
  const _UserProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('user_profile.title'.tr())),
      body: BlocConsumer<UserProfileCubit, UserProfileState>(
        listener: (context, state) {
          if (state is UserProfileError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          UserProfileInitial() => const SizedBox.shrink(),
          UserProfileLoading() => const Center(child: LoadingShimmer()),
          UserProfileError()   => ErrorState(
              message: (state as UserProfileError).message,
              onRetry: () => context.read<UserProfileCubit>().load(),
            ),
          UserProfileLoaded()  => _UserProfileList(
              items: (state as UserProfileLoaded).items,
            ),
        },
      ),
    );
  }
}

class _UserProfileList extends StatelessWidget {
  const _UserProfileList({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: 'user_profile.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
