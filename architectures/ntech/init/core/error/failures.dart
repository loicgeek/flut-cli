class AppFailure implements Exception {
  const AppFailure._({required this.userMessage, this.debugMessage});
  final String userMessage;
  final String? debugMessage;

  factory AppFailure.noInternet() => const AppFailure._(userMessage: 'Pas de connexion internet.');
  factory AppFailure.timeout() => const AppFailure._(userMessage: 'La requete a expire. Reessayez.');
  factory AppFailure.unauthorized() => const AppFailure._(userMessage: 'Session expiree. Reconnectez-vous.');
  factory AppFailure.forbidden() => const AppFailure._(userMessage: 'Acces refuse.');
  factory AppFailure.notFound() => const AppFailure._(userMessage: 'Ressource introuvable.');
  factory AppFailure.serverError({required int code, String? message}) => AppFailure._(
        userMessage: 'Erreur serveur. Reessayez plus tard.',
        debugMessage: 'HTTP $code - $message',
      );
  factory AppFailure.validation({required Map<String, List<String>> errors}) => AppFailure._(
        userMessage: errors.values.expand((e) => e).join('\n'),
      );
  factory AppFailure.unexpected({String? message}) => AppFailure._(
        userMessage: 'Une erreur inattendue est survenue.',
        debugMessage: message,
      );

  @override
  String toString() => 'AppFailure($userMessage | debug: $debugMessage)';
}

