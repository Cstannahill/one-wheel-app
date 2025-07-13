import 'lib/services/onewheel_api_service.dart';

void main() async {
  print('🧪 Testing OneWheel API Service...');
  
  // Test health check
  final isHealthy = await OneWheelApiService.checkHealth();
  print('Health check: ${isHealthy ? "✅ PASSED" : "❌ FAILED"}');
  
  // Test getRides
  final rides = await OneWheelApiService.getRides();
  print('Get rides: ${rides != null ? "✅ PASSED (${rides.length} rides)" : "❌ FAILED"}');
  
  print('🏁 API tests complete!');
}
