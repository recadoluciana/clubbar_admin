import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clubbar_gestao/modules/manuais/manuais_page.dart';

void main() {
  final docs =
      jsonDecode(File('test/fixtures/manuais.json').readAsStringSync()) as List;
  final boundaryKey = GlobalKey();

  Future<void> screenshot(WidgetTester tester, String name) async {
    final directory = Platform.environment['MANUAL_SCREENSHOT_DIR'];
    if (directory == null) return;
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Widget app(Widget home) => RepaintBoundary(
    key: boundaryKey,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'ManualTest',
        colorSchemeSeed: const Color(0xFFF4B740),
      ),
      home: home,
    ),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({'admin_auth_token': 'test-token'});
  });

  testWidgets('catálogo mostra os três públicos e abre o guia', (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(1100, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fontPath = Platform.environment['MANUAL_TEST_FONT'];
    if (fontPath != null) {
      final bytes = File(fontPath).readAsBytesSync();
      await (FontLoader(
        'ManualTest',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      final icons = Platform.environment['MANUAL_TEST_ICONS'];
      if (icons != null) {
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(File(icons).readAsBytesSync())),
            ))
            .load();
      }
    }
    await http.runWithClient(
      () async {
        await tester.pumpWidget(app(const ManuaisPage()));
        await tester.pumpAndSettle();
        expect(find.text('Negociação e Venda'), findsOneWidget);
        expect(find.text('Roteiro de Implantação'), findsOneWidget);
        expect(find.text('Manual do Parceiro'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'catalogo-desktop');
        await tester.tap(find.text('Negociação e Venda'));
        await tester.pumpAndSettle();
        expect(find.text('Editar e publicar nova versão'), findsOneWidget);
        expect(find.text('Fluxo de trabalho'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'negociacao-desktop');
      },
      () => MockClient(
        (r) async => http.Response(
          jsonEncode(r.url.path == '/manuais' ? docs : docs.first),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
  });

  testWidgets(
    'filtro separa lead e busca não altera o público do PDF em tela estreita',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            app(const ManualDetalhePage(slug: 'negociacao-venda')),
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.widgetWithText(ChoiceChip, 'Lead / Interessado'),
          );
          await tester.tap(
            find.widgetWithText(ChoiceChip, 'Lead / Interessado'),
          );
          await tester.pumpAndSettle();
          expect(find.text('Iniciar o atendimento'), findsNothing);
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          expect(find.text('Gerar PDF • Lead / Interessado'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.byType(TextField),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.enterText(
            find.byType(TextField),
            'não existe esta etapa',
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Nenhuma etapa encontrada para este filtro.'),
            findsOneWidget,
          );
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          final button = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Gerar PDF • Lead / Interessado'),
          );
          expect(button.onPressed, isNotNull);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.byType(TextField),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.enterText(find.byType(TextField), '');
          await tester.pumpAndSettle();
          tester
              .state<ScrollableState>(find.byType(Scrollable).first)
              .position
              .jumpTo(0);
          await tester.pumpAndSettle();
          await screenshot(tester, 'negociacao-mobile');
        },
        () => MockClient(
          (r) async => http.Response(
            jsonEncode(docs.first),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
    },
  );
}
