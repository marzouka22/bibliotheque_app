import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - widgets de base', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Bibliothèque App'),
          ),
        ),
      ),
    );
    expect(find.text('Bibliothèque App'), findsOneWidget);
  });

  testWidgets('AppBar se crée correctement', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: Center(child: Text('Bibliothèque de Quartier')),
          ),
          body: SizedBox(),
        ),
      ),
    );
    expect(find.text('Bibliothèque de Quartier'), findsOneWidget);
  });
}
