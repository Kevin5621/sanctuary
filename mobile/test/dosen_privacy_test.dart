import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/dosen/domain/entities/advisee.dart';
import 'package:sanctuary/features/dosen/domain/entities/group_condition.dart';
import 'package:sanctuary/features/kaprodi/domain/entities/program_dashboard.dart';

/// Pendamping klien untuk test kebocoran privasi backend (C-15).
///
/// Test backend menjamin server tidak MENGIRIM data terlarang. Test ini
/// menjamin klien tidak MENGARANG data yang tidak dikirim — dua kegagalan
/// berbeda yang sama-sama berakhir pada mahasiswa menyesal telah jujur.
void main() {
  group('L-BIM-05 — CLOSED tidak pernah menjadi "Normal"', () {
    test('mahasiswa Tertutup tidak punya EWS maupun tanggal check-in', () {
      // Bentuk response nyata untuk mahasiswa CLOSED (diverifikasi terhadap
      // GET /mentors/me/students pada backend).
      final advisee = Advisee.fromJson(const {
        'student_id': 'student-closed',
        'full_name': 'Fajar Ramadhan',
        'share_level': 'CLOSED',
        'share_level_label': 'Tertutup',
        'privacy_notice': 'Mahasiswa memilih untuk tidak membagikan data kondisi.',
        'has_open_contact_request': true,
        'contact_requested_at': '2026-08-06T04:30:50+07:00',
        'ews': null,
      });

      expect(advisee.shareLevel, ShareLevel.closed);
      expect(advisee.ews, isNull);
      expect(advisee.hasEws, isFalse);
      expect(advisee.lastCheckinDate, isNull);

      // Inti aturannya: level TIDAK boleh punya nilai default yang terbaca
      // sebagai kondisi baik-baik saja.
      expect(advisee.ewsLevel, isNull);
      expect(advisee.ewsLevel, isNot('NORMAL'));

      expect(advisee.privacyNotice, isNotEmpty);
    });

    test('D-7 — permintaan dihubungi tetap muncul walau Tertutup', () {
      final advisee = Advisee.fromJson(const {
        'student_id': 'student-closed',
        'full_name': 'Fajar Ramadhan',
        'share_level': 'CLOSED',
        'share_level_label': 'Tertutup',
        'has_open_contact_request': true,
        'contact_requested_at': '2026-08-06T04:30:50+07:00',
        'ews': null,
      });

      expect(advisee.hasOpenContactRequest, isTrue);
      expect(advisee.contactRequestedAt, isNotNull);
      // Tetap tanpa satu indikator pun.
      expect(advisee.ews, isNull);
    });

    test('share_level tak dikenal jatuh ke CLOSED, bukan ke yang paling terbuka',
        () {
      // Bila backend menambah level baru, klien lama harus menampilkan LEBIH
      // SEDIKIT, bukan lebih banyak.
      expect(ShareLevel.fromCode('LEVEL_BARU'), ShareLevel.closed);
      expect(ShareLevel.fromCode(null), ShareLevel.closed);
      expect(ShareLevel.fromCode(''), ShareLevel.closed);
    });

    test('SUMMARY tidak mengizinkan tren, SUMMARY_TREND mengizinkan', () {
      expect(ShareLevel.summary.allowsTrend, isFalse);
      expect(ShareLevel.summaryTrend.allowsTrend, isTrue);
      expect(ShareLevel.closed.allowsTrend, isFalse);
    });
  });

  group('D-6 — alasan permintaan dihubungi tidak pernah diurai klien', () {
    test('ContactRequest mengabaikan field note walau server mengirimkannya',
        () {
      // Simulasi terburuk: seandainya regresi backend membocorkan `note`,
      // klien tetap tidak boleh punya tempat menyimpannya.
      final request = ContactRequest.fromJson(const {
        'request_id': 'req-1',
        'student_id': 'student-1',
        'full_name': 'Gita Anindya',
        'requested_at': '2026-08-06T04:29:22+07:00',
        'note': 'Ingin berdiskusi soal beban tugas minggu ini.',
      });

      expect(request.fullName, 'Gita Anindya');
      expect(request.requestedAt, isNotEmpty);

      // Entitas hanya membawa 5 properti; tidak ada slot untuk alasan.
      expect(request.props.length, 5);
      for (final value in request.props) {
        expect(
          value?.toString() ?? '',
          isNot(contains('beban tugas')),
          reason: 'alasan mahasiswa tidak boleh tersimpan di entitas klien',
        );
      }
    });
  });

  group('I-4 — k-anonymity: angka null tidak boleh menjadi nol', () {
    test('GroupCondition di bawah ambang tidak membawa angka apa pun', () {
      // Bentuk response nyata dosen2 (3 bimbingan) dari backend.
      final condition = GroupCondition.fromJson(const {
        'is_sufficient': false,
        'group_size': 0,
        'minimum_group_size': 5,
        'message': 'Data belum cukup',
        'period_days': 30,
        'avg_mood': null,
        'avg_stress': null,
        'avg_sleep_hours': null,
      });

      expect(condition.isSufficient, isFalse);
      expect(condition.avgMood, isNull);
      expect(condition.avgStress, isNull);
      expect(condition.avgSleepHours, isNull);
      expect(condition.hasEwsDistribution, isFalse);
      expect(condition.hasEmotionDistribution, isFalse);

      // Nilai nullable-nya TIDAK boleh punya default 0 — nol adalah pernyataan
      // ("rata-rata mood mereka nol"), sedangkan tidak ada data bukan.
      expect(condition.avgMood, isNot(0));
    });

    test('MetricCard tanpa nilai dirender "—", bukan "0"', () {
      final metric = MetricCard.fromJson(const {
        'key': 'need_intervention',
        'label': 'Perlu intervensi',
        'value': null,
        'unit': '%',
      });

      expect(metric.hasValue, isFalse);
      expect(metric.displayValue, '—');
      expect(metric.displayValue, isNot('0'));
      expect(metric.displayValue, isNot('0%'));
    });
  });

  group('D-9 — metrik intervensi adalah persentase', () {
    test('kartu bersatuan % ditandai persentase dan diformat dengan %', () {
      final metric = MetricCard.fromJson(const {
        'key': 'need_intervention',
        'label': 'Perlu intervensi',
        'value': 12.5,
        'unit': '%',
        'hint': 'dari mahasiswa yang datanya cukup dievaluasi',
      });

      expect(metric.isPercentage, isTrue);
      expect(metric.displayValue, '13%');
      // Satuan sudah menyatu ke nilai, jadi tidak dicetak dua kali.
      expect(metric.displayUnit, isEmpty);
    });

    test('kartu berjumlah orang tidak ikut diformat sebagai persentase', () {
      final metric = MetricCard.fromJson(const {
        'key': 'active_7_days',
        'label': 'Aktif 7 hari terakhir',
        'value': 8,
        'unit': 'mahasiswa',
      });

      expect(metric.isPercentage, isFalse);
      expect(metric.displayValue, '8');
      expect(metric.displayUnit, 'mahasiswa');
    });

    test('sebaran EWS kaprodi hanya membawa persentase, tanpa jumlah', () {
      final share = EwsShare.fromJson(const {
        'level': 'INTERVENTION',
        'level_label': 'Perlu Intervensi',
        'percentage': 12.5,
      });

      expect(share.percentage, 12.5);
      // Tiga properti saja: level, label, persentase. Tidak ada `total`,
      // karena jumlah mentah akan membatalkan D-9 lewat pintu belakang.
      expect(share.props.length, 3);
    });
  });

  group('L-KON-03 — sebaran emosi hanya label', () {
    test('label diterjemahkan tanpa membawa teks jurnal', () {
      final share = EmotionShare.fromJson(const {
        'emotion_label': 'ANXIOUS',
        'total': 9,
        'percentage': 9.18,
      });

      expect(share.displayLabel, 'Cemas');
      expect(share.isNegative, isTrue);
      // Hanya tiga properti: label, jumlah, persentase — tidak ada isi jurnal.
      expect(share.props.length, 3);
    });

    test('emosi positif & netral tidak ditandai negatif', () {
      for (final label in ['JOY', 'CALM', 'NEUTRAL']) {
        final share = EmotionShare.fromJson({
          'emotion_label': label,
          'total': 1,
          'percentage': 10.0,
        });
        expect(share.isNegative, isFalse, reason: '$label bukan emosi negatif');
      }
    });
  });

  group('EWS "Data belum cukup" bukan level aman', () {
    test('INSUFFICIENT_DATA punya prioritas terendah & is_sufficient false', () {
      final ews = EwsSummary.fromJson(const {
        'level': 'INSUFFICIENT_DATA',
        'level_label': 'Data belum cukup',
        'score': 0,
        'is_sufficient': false,
        'data_points': 2,
        'window_days': 14,
        'indicators': <Map<String, dynamic>>[],
      });

      expect(ews.isSufficient, isFalse);
      expect(ews.level, isNot('NORMAL'));
      expect(ews.levelLabel, 'Data belum cukup');
      expect(ews.priority, 0);
    });

    test('EWS tanpa level yang dikenal default ke Data belum cukup', () {
      final ews = EwsSummary.fromJson(const <String, dynamic>{});

      expect(ews.level, 'INSUFFICIENT_DATA');
      expect(ews.level, isNot('NORMAL'));
    });
  });
}
