import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../bloc/{{blImport}}';
import '../bloc/{{name}}_state.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

@RoutePage()
class {{Pascal}}Screen extends StatelessWidget {
  const {{Pascal}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      {{blProvide}},
      child: const _{{Pascal}}View(),
    );
  }
}

class _{{Pascal}}View extends StatelessWidget {
  const _{{Pascal}}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('{{name}}.title'.tr())),
      body: BlocConsumer<{{blType}}, {{Pascal}}State>(
        listener: (context, state) {
          if (state is {{Pascal}}Error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => switch (state) {
          {{Pascal}}Initial() => const SizedBox.shrink(),
          {{Pascal}}Loading() => const Center(child: LoadingShimmer()),
          {{Pascal}}Error()   => ErrorState(
              message: (state as {{Pascal}}Error).message,
              onRetry: () => {{blRetry}},
            ),
          {{Pascal}}Loaded()  => _{{Pascal}}List(
              items: (state as {{Pascal}}Loaded).items,
            ),
        },
      ),
    );
  }
}

class _{{Pascal}}List extends StatelessWidget {
  const _{{Pascal}}List({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return EmptyState(message: '{{name}}.empty'.tr());
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].id)),
      // TODO: build item UI
    );
  }
}
