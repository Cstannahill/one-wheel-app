class UnitConverter {
  // Speed conversions
  static double kmhToMph(double kmh) => kmh * 0.621371;
  static double mphToKmh(double mph) => mph * 1.60934;
  
  // Distance conversions
  static double kmToMiles(double km) => km * 0.621371;
  static double milesToKm(double miles) => miles * 1.60934;
  static double metersToFeet(double meters) => meters * 3.28084;
  static double feetToMeters(double feet) => feet * 0.3048;
  
  // Temperature conversions
  static double celsiusToFahrenheit(double celsius) => (celsius * 9/5) + 32;
  static double fahrenheitToCelsius(double fahrenheit) => (fahrenheit - 32) * 5/9;
  
  // Formatting helpers for US units
  static String formatSpeed(double kmh) {
    return '${kmhToMph(kmh).toStringAsFixed(1)} mph';
  }
  
  static String formatDistance(double km) {
    final miles = kmToMiles(km);
    if (miles < 0.1) {
      // Show in feet for very short distances
      return '${(miles * 5280).toStringAsFixed(0)} ft';
    } else if (miles < 1) {
      return '${miles.toStringAsFixed(2)} mi';
    } else {
      return '${miles.toStringAsFixed(1)} mi';
    }
  }
  
  static String formatTemperature(double celsius) {
    return '${celsiusToFahrenheit(celsius).toStringAsFixed(1)}°F';
  }
  
  static String formatShortDistance(double meters) {
    final feet = metersToFeet(meters);
    if (feet < 1000) {
      return '${feet.toStringAsFixed(0)} ft';
    } else {
      return '${(feet / 5280).toStringAsFixed(2)} mi';
    }
  }
  
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
