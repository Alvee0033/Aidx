class NotificationService {
  Future<void> init() async {
    // Mock initialization
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> requestPermissions() async {
    // Mock permission request
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void showNewsNotification({required String title, required String body}) {
    // Mock notification display
  }
}
