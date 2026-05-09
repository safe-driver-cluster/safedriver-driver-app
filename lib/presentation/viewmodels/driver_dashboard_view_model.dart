import 'package:flutter/foundation.dart';

import '../../data/models/driver_models.dart';
import '../../data/services/driver_data_service.dart';

class DriverDashboardViewModel extends ChangeNotifier {
  DriverDashboardViewModel({DriverDataService? dataService})
    : dataService = dataService ?? DriverDataService();

  final DriverDataService dataService;

  Stream<List<AttendanceRecord>> attendance(String driverId) =>
      dataService.attendance(driverId);

  Stream<List<DriverAlert>> alerts(String driverId) =>
      dataService.alerts(driverId);

  Stream<List<DriverFeedback>> feedback(String driverId) =>
      dataService.feedback(driverId);

  Stream<List<DriverBus>> buses(DriverProfile driver) =>
      dataService.buses(driver);
}
