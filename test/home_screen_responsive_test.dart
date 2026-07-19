import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:iunity/screens/home_screen.dart';

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  // Mock FirebaseAuth Channel
  const MethodChannel authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(authChannel, (MethodCall methodCall) async {
    if (methodCall.method == 'Auth#registerStateListener') {
      return null;
    }
    return null;
  });
}

void main() {
  setUpAll(() async {
    setupFirebaseMocks();
    await Firebase.initializeApp();
  });

  group('HomeScreen Responsiveness Tests', () {
    final widths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0, 600.0, 768.0, 1024.0, 1440.0, 1920.0];
    final textScales = [1.0, 1.25, 1.5, 2.0];

    for (final width in widths) {
      for (final textScale in textScales) {
        testWidgets('Width: ${width}px, Scale: $textScale, Portrait', (WidgetTester tester) async {
          await _runResponsiveTest(tester, width, 800.0, textScale);
        });

        testWidgets('Width: ${width}px, Scale: $textScale, Landscape', (WidgetTester tester) async {
          await _runResponsiveTest(tester, width, 480.0, textScale);
        });
      }
    }
  });
}

Future<void> _runResponsiveTest(WidgetTester tester, double width, double height, double textScale) async {
  final dpi = 1.0;
  tester.view.physicalSize = Size(width * dpi, height * dpi);
  tester.view.devicePixelRatio = dpi;
  
  // Set text scale factor
  tester.platformDispatcher.textScaleFactorTestValue = textScale;

  await tester.pumpWidget(
    const MaterialApp(
      home: HomeScreen(),
    ),
  );

  // Pump multiple times to ensure full layout resolution
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  // Verify that the HomeScreen widget is present
  expect(find.byType(HomeScreen), findsOneWidget);

  // Reset values
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
  tester.platformDispatcher.clearTextScaleFactorTestValue();
}
