import '../../domain/entities/{{name}}.dart';

sealed class {{Pascal}}State { const {{Pascal}}State(); }

final class {{Pascal}}Initial extends {{Pascal}}State { const {{Pascal}}Initial(); }
final class {{Pascal}}Loading extends {{Pascal}}State { const {{Pascal}}Loading(); }
final class {{Pascal}}Loaded  extends {{Pascal}}State {
  const {{Pascal}}Loaded(this.items);
  final List<{{Pascal}}> items;
}
final class {{Pascal}}Error extends {{Pascal}}State {
  const {{Pascal}}Error(this.message);
  final String message;
}
