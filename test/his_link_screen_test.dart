import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spital_visu_upu/features/patient/presentation/screens/his_link_screen.dart';

/// Fake backend for /api/his-link; records requests for assertions.
class FakeHisApi {
  bool linked;
  final String validCode;
  final List<http.Request> requests = [];

  FakeHisApi({this.linked = false, this.validCode = '123456'});

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;

    if (request.method == 'GET' && path.endsWith('/his-link')) {
      return http.Response(json.encode({'linked': linked}), 200);
    }
    if (path.endsWith('/his-link/request')) {
      return http.Response(
          json.encode({'message': 'his_link_code_sent_if_found'}), 202);
    }
    if (path.endsWith('/his-link/confirm')) {
      final code = json.decode(request.body)['code'];
      if (code == validCode) {
        linked = true;
        return http.Response(
            json.encode({'message': 'his_linked', 'linked': true}), 200);
      }
      return http.Response(
          json.encode({'message': 'his_link_code_invalid'}), 422);
    }
    return http.Response('', 404);
  });
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'}));

  /// Opens the screen from a host route and returns a holder for the popped value.
  Future<List<bool?>> openScreen(WidgetTester tester) async {
    final popped = <bool?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => popped.add(await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const HisLinkScreen()))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('patient requests a code, confirms it and the screen pops true',
      (tester) async {
    final api = FakeHisApi();
    await http.runWithClient(() async {
      final popped = await openScreen(tester);

      expect(find.text('Trimite codul'), findsOneWidget);
      await tester.tap(find.text('Trimite codul'));
      await tester.pumpAndSettle();

      expect(find.textContaining('ți-am trimis un cod'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();

      expect(popped, [true]);
      final confirm =
          api.requests.firstWhere((r) => r.url.path.endsWith('/confirm'));
      expect(json.decode(confirm.body), {'code': '123456'});
      expect(confirm.headers['Authorization'], 'Bearer tok');
    }, () => api.client);
  });

  testWidgets('a wrong code shows an error and keeps the screen open',
      (tester) async {
    final api = FakeHisApi();
    await http.runWithClient(() async {
      final popped = await openScreen(tester);

      await tester.tap(find.text('Trimite codul'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '000000');
      await tester.pumpAndSettle();

      expect(find.textContaining('Cod greșit sau expirat'), findsOneWidget);
      expect(popped, isEmpty);
    }, () => api.client);
  });

  testWidgets('an already linked account shows the linked state',
      (tester) async {
    final api = FakeHisApi(linked: true);
    await http.runWithClient(() async {
      await openScreen(tester);

      expect(find.text('Contul tău este asociat cu dosarul spitalului'),
          findsOneWidget);
      expect(find.text('Trimite codul'), findsNothing);
    }, () => api.client);
  });
}
