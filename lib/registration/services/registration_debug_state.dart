class RegistrationDebugState {
  static String? lastCreatedUid;
  static String? lastProjectId;
  static String? lastRestaurantId;

  static void clear() {
    lastCreatedUid = null;
    lastProjectId = null;
    lastRestaurantId = null;
  }
}
