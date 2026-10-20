import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unpam_mobile/core/services/ai_service.dart';
import 'package:unpam_mobile/core/services/portal_ai_text.dart';
import 'package:unpam_mobile/core/services/storage_service.dart';
import 'package:unpam_mobile/models/seminar_certificate_model.dart';
import 'package:unpam_mobile/providers/ai_provider.dart';
import 'package:unpam_mobile/widgets/mini_ai_overlay_panel.dart';
import 'package:unpam_mobile/widgets/portal_ai_assist.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the Telaah pill and docks the split-screen AI panel', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.getInstance();
    await storage.resetAll();

    await tester.binding.setSurfaceSize(const Size(900, 900));
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AiProvider(AiService(storage), storage),
        child: MaterialApp(
          home: Scaffold(
            body: PortalAiAssist(
              aiContext: PortalAiContext(
                pageTitle: 'Rangkuman Nilai',
                label: 'Nilai',
                buildPageText: () => 'IPK: 3.77',
              ),
              child: const Center(child: Text('konten')),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Telaah Nilai'), findsOneWidget);
    expect(find.byType(MiniAiOverlayPanel), findsNothing);

    await tester.tap(find.byTooltip('Semua Menu The PAMs AI Tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka Split-Screen AI'));
    await tester.pumpAndSettle();

    expect(find.byType(MiniAiOverlayPanel), findsOneWidget);
    expect(find.text('konten'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  test('certificate summary never includes empty placeholders', () {
    final text = PortalAiText.certificates([
      SeminarCertificateItem(
        namaEvent: 'PKKMB',
        nomorBarcode: 'abc',
        tanggalKegiatan: '2025-03-03T00:00:00.000Z',
        jenisEvent: 'PKKMB',
        approvedSertifikat: true,
      ),
    ]);
    expect(text, contains('PKKMB'));
    expect(text, contains('terverifikasi'));
    expect(PortalAiText.certificates(null), isEmpty);
  });
}
