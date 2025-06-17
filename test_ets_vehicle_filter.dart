// Test file to verify ETS vehicle filtering logic
// This demonstrates how the fixed logic should work

import 'dart:convert';

void main() {
  print('=== ETS Vehicle Filter Fix Test ===\n');
  
  // Simulate API response from /schedule/etsCab1
  final mockApiResponse = {
    "distance": "20",
    "hatchback": 650,
    "sedan": 700,
    "sedanpremium": 0,
    "suv": 2500,
    "suvplus": 0,
    "ertiga": 0
  };
  
  // Simulate booking data that would be passed to EtsSelectVehicleScreen
  final bookingData = {
    'pickup': 'Electronic City, Bangalore',
    'destination': 'Whitefield, Bangalore',
    'distance': mockApiResponse['distance'].toString(),
    'hatchback': mockApiResponse['hatchback'].toString(),
    'sedan': mockApiResponse['sedan'].toString(),
    'sedanpremium': mockApiResponse['sedanpremium'].toString(),
    'suv': mockApiResponse['suv'].toString(),
    'suvplus': mockApiResponse['suvplus'].toString(),
    'ertiga': mockApiResponse['ertiga'].toString(),
  };
  
  print('Mock API Response:');
  print(json.encode(mockApiResponse));
  print('\nBooking Data Passed to Vehicle Screen:');
  print(json.encode(bookingData));
  
  // Test the vehicle filtering logic
  testVehicleFiltering(bookingData);
}

void testVehicleFiltering(Map<String, dynamic> bookingData) {
  print('\n=== Testing Vehicle Filtering Logic ===\n');
  
  final distance = double.tryParse(bookingData['distance'] ?? '0') ?? 0;
  final vehicleTypes = ['hatchback', 'sedan', 'sedanpremium', 'suv', 'suvplus', 'ertiga'];
  final vehicleNames = ['HatchBack', 'Sedan', 'SedanPremium', 'SUV', 'SUVPlus', 'Ertiga'];
  
  List<String> availableVehicles = [];
  List<String> hiddenVehicles = [];
  
  for (int i = 0; i < vehicleTypes.length; i++) {
    final vehicleType = vehicleTypes[i];
    final vehicleName = vehicleNames[i];
    final rate = double.tryParse(bookingData[vehicleType]?.toString() ?? '0') ?? 0;
    
    if (rate > 0) {
      final totalPrice = (distance * rate).round();
      availableVehicles.add(vehicleName);
      print('✅ $vehicleName: ₹$totalPrice (₹${rate.round()}/km × ${distance}km)');
    } else {
      hiddenVehicles.add(vehicleName);
      print('❌ $vehicleName: Hidden (rate = $rate)');
    }
  }
  
  print('\n=== Summary ===');
  print('Available Vehicles: ${availableVehicles.join(', ')}');
  print('Hidden Vehicles: ${hiddenVehicles.join(', ')}');
  print('First Selected Category: ${availableVehicles.isNotEmpty ? availableVehicles.first : 'None'}');
  
  // Test different scenarios
  print('\n=== Testing Different Scenarios ===\n');
  
  // Scenario 1: All vehicles available
  testScenario('All Available', {
    'distance': '25',
    'hatchback': '600',
    'sedan': '750',
    'sedanpremium': '900',
    'suv': '1200',
    'suvplus': '1500',
    'ertiga': '800',
  });
  
  // Scenario 2: Only premium vehicles
  testScenario('Premium Only', {
    'distance': '30',
    'hatchback': '0',
    'sedan': '0',
    'sedanpremium': '1000',
    'suv': '1300',
    'suvplus': '1600',
    'ertiga': '0',
  });
  
  // Scenario 3: No vehicles available
  testScenario('None Available', {
    'distance': '15',
    'hatchback': '0',
    'sedan': '0',
    'sedanpremium': '0',
    'suv': '0',
    'suvplus': '0',
    'ertiga': '0',
  });
}

void testScenario(String scenarioName, Map<String, String> data) {
  print('--- $scenarioName ---');
  
  final distance = double.tryParse(data['distance'] ?? '0') ?? 0;
  final vehicleTypes = ['hatchback', 'sedan', 'sedanpremium', 'suv', 'suvplus', 'ertiga'];
  final vehicleNames = ['HatchBack', 'Sedan', 'SedanPremium', 'SUV', 'SUVPlus', 'Ertiga'];
  
  List<String> available = [];
  
  for (int i = 0; i < vehicleTypes.length; i++) {
    final rate = double.tryParse(data[vehicleTypes[i]] ?? '0') ?? 0;
    if (rate > 0) {
      available.add(vehicleNames[i]);
    }
  }
  
  print('Distance: ${distance}km');
  print('Available: ${available.isNotEmpty ? available.join(', ') : 'None'}');
  print('UI State: ${available.isNotEmpty ? 'Show vehicles' : 'Show "No vehicles available" message'}');
  print('');
}
