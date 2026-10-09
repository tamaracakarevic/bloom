/// Web nema pristup aplikaciji Zdravlje — koraci se upisuju ručno.
class StepsService {
  bool get available => false;

  Future<bool> requestAccess() async => false;

  Future<int?> stepsFor(int epochDay) async => null;
}
