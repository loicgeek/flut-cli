import '../data/models/{{Feature}}_model.dart';

sealed class {{FeaturePascal}}State { const {{FeaturePascal}}State(); }

final class {{FeaturePascal}}Initial extends {{FeaturePascal}}State { const {{FeaturePascal}}Initial(); }
final class {{FeaturePascal}}Loading extends {{FeaturePascal}}State { const {{FeaturePascal}}Loading(); }
final class {{FeaturePascal}}Loaded  extends {{FeaturePascal}}State {
  const {{FeaturePascal}}Loaded(this.items);
  final List<{{FeaturePascal}}Model> items;
}
final class {{FeaturePascal}}Error extends {{FeaturePascal}}State {
  const {{FeaturePascal}}Error(this.message);
  final String message;
}

