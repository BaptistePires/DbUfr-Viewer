// HTTP related exceptions
class CantReachDbUfrError implements Exception{
  String cause;
  CantReachDbUfrError(this.cause);
}

class CredentialsError implements Exception{
  String cause;
  CredentialsError(this.cause);
}