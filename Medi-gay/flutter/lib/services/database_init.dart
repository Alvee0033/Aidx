class DatabaseInitService {
  Future<bool> hasSampleData() async {
    // Mock check for sample data
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  Future<void> initializeSampleData() async {
    // Mock initialization of sample data
    await Future.delayed(const Duration(seconds: 1));
  }
}
