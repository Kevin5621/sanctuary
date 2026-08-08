import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/core/widgets/privacy_states.dart';

/// Test render untuk komponen state kejujuran.
///
/// [dosen_privacy_test.dart] menjaga ENTITAS-nya benar; file ini menjaga apa
/// yang benar-benar TERBACA di layar. Keduanya perlu: entitas yang benar masih
/// bisa dirender menjadi kalimat yang menyesatkan.

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('InsufficientDataCard (I-4)', () {
    testWidgets('menyebut ambang, tanpa membocorkan ukuran kelompok',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const InsufficientDataCard(
          minimumGroupSize: 5,
          context: 'kelompok bimbingan Anda',
        ),
      ));

      expect(find.text('Data belum cukup'), findsOneWidget);
      expect(find.textContaining('minimal 5 mahasiswa'), findsOneWidget);

      // Tidak boleh ada angka lain yang bisa dibaca sebagai ukuran kelompok.
      expect(find.textContaining('0 mahasiswa'), findsNothing);
      expect(find.textContaining('3 mahasiswa'), findsNothing);
    });

    testWidgets('tanpa ambang pun tidak menampilkan angka apa pun',
        (tester) async {
      await tester.pumpWidget(_wrap(const InsufficientDataCard()));

      expect(find.text('Data belum cukup'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Text && (w.data ?? '').contains(RegExp(r'\d'))),
        findsNothing,
        reason: 'tidak satu pun angka boleh muncul saat di bawah ambang',
      );
    });
  });

  group('ClosedShareCard (L-BIM-05)', () {
    testWidgets('menyatakan pilihan mahasiswa, tidak pernah "Normal"',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ClosedShareCard(studentName: 'Fajar Ramadhan'),
      ));

      expect(find.text('Mahasiswa memilih tidak berbagi'), findsOneWidget);
      expect(find.textContaining('Fajar Ramadhan'), findsOneWidget);
      expect(find.textContaining('Normal'), findsNothing);
    });

    testWidgets('memakai kalimat server bila tersedia', (tester) async {
      await tester.pumpWidget(_wrap(
        const ClosedShareCard(
          notice: 'Mahasiswa memilih untuk tidak membagikan data kondisi.',
        ),
      ));

      expect(
        find.text('Mahasiswa memilih untuk tidak membagikan data kondisi.'),
        findsOneWidget,
      );
    });
  });

  group('EwsLevelBadge', () {
    testWidgets('level null dirender "Tidak dibagikan", bukan "Normal"',
        (tester) async {
      await tester.pumpWidget(_wrap(const EwsLevelBadge(level: null)));

      expect(find.text('Tidak dibagikan'), findsOneWidget);
      expect(find.text('Normal'), findsNothing);
    });

    testWidgets('INSUFFICIENT_DATA dirender "Data belum cukup"',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const EwsLevelBadge(level: 'INSUFFICIENT_DATA')),
      );

      expect(find.text('Data belum cukup'), findsOneWidget);
      expect(find.text('Normal'), findsNothing);
    });

    testWidgets('level nyata tetap tampil apa adanya', (tester) async {
      await tester.pumpWidget(
        _wrap(const EwsLevelBadge(level: 'INTERVENTION')),
      );
      expect(find.text('Perlu Intervensi'), findsOneWidget);
    });
  });

  group('VerificationBadge (A-BAN-04)', () {
    testWidgets('menyatakan status belum terverifikasi secara eksplisit',
        (tester) async {
      await tester.pumpWidget(_wrap(const VerificationBadge()));
      expect(find.text('Belum diverifikasi'), findsOneWidget);
    });
  });

  group('EmptyStateCard — daftar nomor kosong (A-BAN-03)', () {
    testWidgets('mengaku belum diatur tanpa menawarkan nomor tebakan',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyStateCard(
          title: 'Nomor layanan belum diatur',
          description:
              'Administrator kampus belum mengatur daftar nomor layanan bantuan.',
        ),
      ));

      expect(find.text('Nomor layanan belum diatur'), findsOneWidget);

      // Tidak boleh ada nomor darurat yang muncul sebagai "cadangan".
      for (final number in ['119', '112', '021']) {
        expect(
          find.textContaining(number),
          findsNothing,
          reason: 'nomor $number tidak boleh muncul sebagai tebakan',
        );
      }
    });
  });

  group('AccessLimitsCard (L-PRO-03 / K-PRO-01 / A-PRO-01)', () {
    testWidgets('menampilkan seluruh batas akses yang diberikan',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const AccessLimitsCard(limits: [
          'Anda tidak dapat membaca jurnal mahasiswa.',
          'Anda tidak dapat membaca percakapan Terapis AI mahasiswa.',
        ]),
      ));

      expect(find.text('Yang tidak dapat Anda lihat'), findsOneWidget);
      expect(find.textContaining('membaca jurnal mahasiswa'), findsOneWidget);
      expect(find.textContaining('Terapis AI'), findsOneWidget);
    });
  });
}
