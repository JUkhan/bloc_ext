import 'package:ajwah_bloc_test/ajwah_bloc_test.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'counterCubit.dart';
import 'searchCategoryCubit.dart';
import 'todoCubit.dart';

void main() {
  group('Counter Cubit', () {
    late CounterCubit cubit;

    setUp(() {
      cubit = CounterCubit();
    });

    tearDown(() {
      cubit.close();
    });

    ajwahTest<int>(
      'emit [1] when cubit.inc',
      build: () => cubit.stream,
      act: () => cubit.inc(),
      expect: [1],
    );

    ajwahTest<int>(
      'emit [-1] when cubit.inc',
      build: () => cubit.stream,
      act: () => cubit.dec(),
      expect: [-1],
    );
    ajwahTest<String>(
      "emit ['loading...', '1'] when cubit.asyncInc",
      build: () => cubit.count$,
      act: () => cubit.asyncInc(),
      expect: ['loading...', '1'],
    );
  });
  group('todos - ', () {
    late TodoCubit cubit;
    late SearchCategoryCubit searchCubit;
    setUp(() {
      cubit = TodoCubit();
      searchCubit = SearchCategoryCubit();
    });

    tearDown(() {
      cubit.close();
      searchCubit.close();
    });

    ajwahTest<SearchCategory>('search category.All.',
        build: () => searchCubit.stream$,
        verify: (states) {
          expect(states[0], SearchCategory.All);
        });
    ajwahTest<SearchCategory>('search category.Active.',
        build: () => searchCubit.stream,
        act: () => searchCubit.setCategory(SearchCategory.Active),
        verify: (states) {
          expect(states[0], SearchCategory.Active);
        });

    ajwahTest<SearchCategory>('Remote cubic -All',
        build: () => cubit
            .remoteCubit<SearchCategoryCubit>()
            .flatMap((value) => value.stream$),
        verify: (states) {
          expect(states[0], SearchCategory.All);
        });

    ajwahTest<SearchCategory>('Remote cubic- Active',
        build: () => cubit
            .remoteCubit<SearchCategoryCubit>()
            .flatMap((value) => value.stream$),
        act: () => searchCubit.setCategory(SearchCategory.Active),
        verify: (states) {
          expect(states[0], SearchCategory.Active);
        });
    ajwahTest<List<Todo>>('3 todos initialized.',
        build: () => cubit.todo$,
        verify: (states) {
          expect(states[0].length, 3);
        });
    ajwahTest<List<Todo>>('2 active todos.',
        build: () => cubit.todo$,
        act: () => searchCubit.setCategory(SearchCategory.Active),
        skip: 1,
        verify: (states) {
          expect(states[0].length, 2);
        });

    ajwahTest<SearchInputAction>('check action',
        build: () => cubit.action$.isA<SearchInputAction>(),
        act: () {
          cubit.dispatch(SearchInputAction('h'));
        },
        verify: (states) {
          expect(states[0].searchText, 'h');
        });

    ajwahTest<List<Todo>>('searching by hel',
        build: () => cubit.todo$,
        act: () {
          cubit.dispatch(SearchInputAction('h'));
          cubit.dispatch(SearchInputAction('he'));
          cubit.dispatch(SearchInputAction('hel'));
        },
        wait: Duration(milliseconds: 200),
        skip: 2,
        verify: (states) {
          expect(states[0].length, 1);
        });
  });
}
