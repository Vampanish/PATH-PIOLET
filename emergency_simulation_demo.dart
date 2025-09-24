#!/usr/bin/env dart
/// Emergency Vehicle Detection System - Interactive Demo & Testing Script
/// This script allows you to simulate and test the emergency vehicle detection system
/// Run this with: dart emergency_simulation_demo.dart

import 'dart:io';
import 'dart:math';
import 'dart:async';

void main() async {
  print('🚨 PathPilot Emergency Vehicle Detection System - Simulation Demo 🚨');
  print('=' * 70);
  print('');
  
  while (true) {
    showMainMenu();
    String? choice = stdin.readLineSync();
    
    switch (choice?.toLowerCase()) {
      case '1':
        await simulateRFTransponderDetection();
        break;
      case '2':
        await simulateAudioSirenDetection();
        break;
      case '3':
        await simulateFullEmergencyScenario();
        break;
      case '4':
        showSensorNetworkStatus();
        break;
      case '5':
        await simulateTrafficSignalOverride();
        break;
      case '6':
        showSystemStatistics();
        break;
      case '7':
        await runContinuousMonitoring();
        break;
      case 'q':
      case 'quit':
        print('👋 Goodbye! Emergency system monitoring ended.');
        exit(0);
      default:
        print('❌ Invalid choice. Please try again.');
    }
    
    print('\nPress Enter to continue...');
    stdin.readLineSync();
  }
}

void showMainMenu() {
  print('\n🎯 Emergency Vehicle Detection - Testing Options:');
  print('=' * 50);
  print('1. 📡 Simulate RF Transponder Detection (5.9 GHz)');
  print('2. 🔊 Simulate Audio Siren Detection (Sound Sensors)');
  print('3. 🚑 Full Emergency Vehicle Scenario');
  print('4. 📊 View IoT Sensor Network Status');
  print('5. 🚦 Simulate Traffic Signal Override');
  print('6. 📈 Show System Statistics');
  print('7. 🔄 Run Continuous Monitoring Demo');
  print('Q. Quit');
  print('');
  print('Enter your choice (1-7 or Q): ');
}

Future<void> simulateRFTransponderDetection() async {
  print('\n📡 RF Transponder Detection Simulation');
  print('=' * 40);
  
  final sensors = [
    'RF_SENSOR_01 - Main Street & 1st Ave',
    'RF_SENSOR_05 - Downtown Intersection',
    'RF_SENSOR_09 - Hospital Route',
    'RF_SENSOR_12 - Fire Station Vicinity',
  ];
  
  final emergencyTypes = ['Ambulance', 'Fire Truck', 'Police Vehicle'];
  final random = Random();
  
  print('🔍 Scanning RF frequencies at 5.9 GHz...');
  await Future.delayed(Duration(seconds: 1));
  
  for (int i = 0; i < 3; i++) {
    print('⚪ Scanning... ${(i + 1) * 33}%');
    await Future.delayed(Duration(milliseconds: 500));
  }
  
  print('');
  print('🚨 EMERGENCY VEHICLE DETECTED! 🚨');
  print('');
  print('📍 Sensor: ${sensors[random.nextInt(sensors.length)]}');
  print('🚑 Vehicle Type: ${emergencyTypes[random.nextInt(emergencyTypes.length)]}');
  print('📶 Signal Strength: ${85 + random.nextInt(15)}%');
  print('⏱️  Detection Time: ${DateTime.now().toString().substring(11, 19)}');
  print('🚦 Traffic Signal Override: ACTIVATED');
  print('');
  print('✅ Emergency vehicle given priority passage!');
}

Future<void> simulateAudioSirenDetection() async {
  print('\n🔊 Audio Siren Detection Simulation');
  print('=' * 40);
  
  print('🎤 Audio sensors listening for emergency sirens...');
  print('🔇 Baseline noise level: 65-75 dB (normal traffic)');
  await Future.delayed(Duration(seconds: 1));
  
  print('');
  print('📈 Audio levels rising...');
  
  final decibelLevels = [68, 72, 78, 85, 92, 98, 105, 112, 108, 95];
  
  for (int db in decibelLevels) {
    if (db > 95) {
      print('🔊 ${db} dB - 🚨 SIREN DETECTED! 🚨');
    } else {
      print('🔉 ${db} dB - Normal traffic noise');
    }
    await Future.delayed(Duration(milliseconds: 300));
  }
  
  print('');
  print('🎯 Siren Pattern Analysis: CONFIRMED');
  print('📍 Location: Audio Sensor #3 - City Center');
  print('🚦 Preparing traffic signal for emergency vehicle...');
  print('✅ Audio detection successful!');
}

Future<void> simulateFullEmergencyScenario() async {
  print('\n🚑 Full Emergency Vehicle Scenario');
  print('=' * 40);
  
  print('📞 Emergency Call Received: Medical Emergency');
  print('🚑 Ambulance dispatched from City Hospital');
  await Future.delayed(Duration(seconds: 1));
  
  print('');
  print('📡 Stage 1: RF Transponder Activation');
  print('   └── 5.9 GHz signal detected at Sensor RF_07');
  await Future.delayed(Duration(seconds: 1));
  
  print('🔊 Stage 2: Audio Siren Detection');
  print('   └── 105 dB siren detected at Audio Sensor #2');
  await Future.delayed(Duration(seconds: 1));
  
  print('🚦 Stage 3: Traffic Signal Override');
  print('   └── Signal at Main St & 2nd Ave: RED → GREEN');
  print('   └── Cross traffic: GREEN → RED');
  await Future.delayed(Duration(seconds: 1));
  
  print('📱 Stage 4: Authority Notification');
  print('   └── Traffic control center alerted');
  print('   └── Route optimization activated');
  await Future.delayed(Duration(seconds: 1));
  
  print('🗺️  Stage 5: Real-time Tracking');
  print('   └── Vehicle position: Updating every 2 seconds');
  print('   └── ETA to destination: 4 minutes');
  await Future.delayed(Duration(seconds: 1));
  
  print('');
  print('✅ MISSION SUCCESSFUL!');
  print('🎯 Total response improvement: 35% faster');
  print('💾 Incident logged for analytics');
}

void showSensorNetworkStatus() {
  print('\n📊 IoT Sensor Network Status');
  print('=' * 35);
  
  print('📡 RF Emergency Vehicle Detectors:');
  for (int i = 1; i <= 15; i++) {
    final status = Random().nextBool() ? '🟢 Online' : '🟡 Standby';
    final battery = 75 + Random().nextInt(25);
    print('   RF_${i.toString().padLeft(2, '0')}: $status | Battery: $battery% | Signal: Strong');
  }
  
  print('');
  print('🔊 Audio Siren Detection Sensors:');
  for (int i = 1; i <= 8; i++) {
    final status = Random().nextBool() ? '🟢 Active' : '🟡 Idle';
    final noise = 60 + Random().nextInt(20);
    print('   AUDIO_${i}: $status | Ambient: ${noise} dB | Sensitivity: High');
  }
  
  print('');
  print('📈 Network Health: 96% (22/23 sensors operational)');
  print('⚡ Power Status: All sensors battery > 70%');
  print('📶 Connectivity: Strong signal across network');
}

Future<void> simulateTrafficSignalOverride() async {
  print('\n🚦 Traffic Signal Override Simulation');
  print('=' * 40);
  
  final intersections = [
    'Main St & 1st Ave',
    'Broadway & Central',
    'Hospital Rd & Oak St',
    'Fire Station & Elm Ave'
  ];
  
  final intersection = intersections[Random().nextInt(intersections.length)];
  
  print('📍 Target Intersection: $intersection');
  print('🚦 Current Status: Normal Operation');
  print('');
  
  print('🚨 Emergency Vehicle Approaching...');
  await Future.delayed(Duration(seconds: 1));
  
  print('⚡ Initiating Override Protocol...');
  await Future.delayed(Duration(milliseconds: 500));
  
  print('🔴 North-South: RED');  
  print('🔴 East-West: RED');
  await Future.delayed(Duration(milliseconds: 500));
  
  print('🟢 Emergency Route: GREEN');
  print('⏰ Override Duration: 45 seconds');
  await Future.delayed(Duration(seconds: 1));
  
  print('');
  print('🚑 Emergency Vehicle Passed Successfully!');
  print('🔄 Returning to Normal Operation...');
  await Future.delayed(Duration(milliseconds: 500));
  
  print('🟢 Traffic Flow Restored');
  print('📊 Override Logged: Success');
}

void showSystemStatistics() {
  print('\n📈 Emergency Detection System Statistics');
  print('=' * 45);
  
  final random = Random();
  
  print('📊 Today\'s Performance:');
  print('   🚑 Emergency Vehicles Detected: ${random.nextInt(15) + 5}');
  print('   🚦 Traffic Signals Overridden: ${random.nextInt(20) + 8}');
  print('   ⏱️  Average Response Time: ${1.2 + random.nextDouble() * 0.8} seconds');
  print('   ✅ Success Rate: ${95 + random.nextInt(5)}%');
  
  print('');
  print('📈 This Week:');
  print('   🚨 Total Emergencies: ${random.nextInt(50) + 80}');
  print('   🎯 False Positives: ${random.nextInt(3) + 1}');
  print('   💾 Data Points Collected: ${random.nextInt(10000) + 50000}');
  
  print('');
  print('🏆 System Achievements:');
  print('   ⚡ 99.7% Uptime This Month');
  print('   🚀 35% Faster Emergency Response');
  print('   🌟 Zero Critical Failures');
  print('   💡 15 AI Optimizations Applied');
}

Future<void> runContinuousMonitoring() async {
  print('\n🔄 Continuous Monitoring Demo');
  print('=' * 35);
  print('Press Ctrl+C to stop monitoring...\n');
  
  final random = Random();
  int cycleCount = 0;
  
  while (true) {
    cycleCount++;
    print('🔍 Monitoring Cycle #$cycleCount - ${DateTime.now().toString().substring(11, 19)}');
    
    // Simulate sensor readings
    for (int i = 1; i <= 5; i++) {
      final sensorType = random.nextBool() ? 'RF' : 'Audio';
      final reading = sensorType == 'RF' 
          ? '${(random.nextDouble() * 100).toStringAsFixed(1)}% signal'
          : '${(60 + random.nextInt(20))} dB';
      
      print('   📡 $sensorType Sensor $i: $reading');
      await Future.delayed(Duration(milliseconds: 200));
    }
    
    // Occasionally simulate emergency detection
    if (random.nextInt(10) == 0) {
      print('');
      print('🚨 EMERGENCY DETECTED! 🚨');
      print('📍 Location: Intersection ${random.nextInt(12) + 1}');
      print('🚦 Signal Override: ACTIVATED');
      print('');
    }
    
    await Future.delayed(Duration(seconds: 3));
    print('');
  }
}