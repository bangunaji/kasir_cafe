// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasir_cafe/main.dart';
import 'package:kasir_cafe/presentation/blocs/auth/auth_bloc.dart';
import 'package:kasir_cafe/presentation/blocs/auth/auth_event.dart';
import 'package:kasir_cafe/presentation/blocs/auth/auth_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    // Stub initial state
    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set a tablet-sized surface for testing
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(MyApp(authBloc: mockAuthBloc));

    // Allow animations to finish
    await tester.pumpAndSettle();

    // Verify that the title is displayed
    expect(find.text('Kasir Cafe'), findsWidgets);
    
    // Reset view size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
