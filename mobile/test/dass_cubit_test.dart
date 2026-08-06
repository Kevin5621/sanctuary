import 'package:flutter_test/flutter_test.dart';
import 'package:sanctuary/features/mahasiswa/presentation/cubit/dass_cubit.dart';

import 'support/fake_repositories.dart';

void main() {
  test('memuat kuesioner beserta instruksi dan disclaimer', () async {
    final cubit = DassCubit(FakeDassRepository());

    await cubit.load();

    expect(cubit.state.status, DassStatus.ready);
    expect(cubit.state.totalQuestions, 3);
    expect(cubit.state.questionnaire.disclaimer, isNotEmpty,
        reason: 'instrumen skrining tanpa disclaimer mudah dibaca sebagai diagnosis');
    expect(cubit.state.view, DassView.questionnaire);
  });

  test('menjawab soal menaikkan progres', () async {
    final cubit = DassCubit(FakeDassRepository());
    await cubit.load();

    cubit.answer(1, 2);

    expect(cubit.state.answeredCount, 1);
    expect(cubit.state.progress, closeTo(1 / 3, 0.001));
    expect(cubit.state.isComplete, isFalse);
  });

  test('menjawab ulang soal yang sama tidak menambah hitungan', () async {
    final cubit = DassCubit(FakeDassRepository());
    await cubit.load();

    cubit.answer(1, 2);
    cubit.answer(1, 3);

    expect(cubit.state.answeredCount, 1);
    expect(cubit.state.answers[1], 3);
  });

  // Skor DASS-21 hanya bermakna bila seluruh item terjawab; pengisian sebagian
  // menghasilkan kategori yang terlihat sah padahal dihitung dari data kurang.
  test('pengiriman ditolak saat pengisian belum lengkap', () async {
    final repository = FakeDassRepository();
    final cubit = DassCubit(repository);
    await cubit.load();

    cubit.answer(1, 1);
    final submitted = await cubit.submit();

    expect(submitted, isFalse);
    expect(repository.submittedAnswers, isNull);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('pengisian lengkap terkirim urut sesuai nomor soal', () async {
    final repository = FakeDassRepository();
    final cubit = DassCubit(repository);
    await cubit.load();

    cubit.answer(1, 3);
    cubit.answer(2, 0);
    cubit.answer(3, 2);

    final submitted = await cubit.submit();

    expect(submitted, isTrue);
    expect(repository.submittedAnswers, [3, 0, 2]);
    expect(cubit.state.view, DassView.result);
    expect(cubit.state.result, isNotNull);
  });

  test('hasil menyertakan disclaimer dan saran tindak lanjut', () async {
    final cubit = DassCubit(FakeDassRepository());
    await cubit.load();

    cubit.answer(1, 0);
    cubit.answer(2, 0);
    cubit.answer(3, 0);
    await cubit.submit();

    expect(cubit.state.result?.disclaimer, isNotEmpty);
    expect(cubit.state.result?.copingSuggestions, isNotEmpty);
  });

  test('memulai skrining baru mengosongkan jawaban dan hasil sebelumnya', () async {
    final cubit = DassCubit(FakeDassRepository());
    await cubit.load();
    cubit.answer(1, 3);
    cubit.answer(2, 3);
    cubit.answer(3, 3);
    await cubit.submit();

    cubit.startNewScreening();

    expect(cubit.state.answers, isEmpty);
    expect(cubit.state.result, isNull);
    expect(cubit.state.view, DassView.questionnaire);
  });

  test('beralih ke riwayat mengubah tampilan', () async {
    final cubit = DassCubit(FakeDassRepository());
    await cubit.load();

    cubit.showHistory();

    expect(cubit.state.view, DassView.history);
  });
}
