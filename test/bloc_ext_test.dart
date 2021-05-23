import 'package:ajwah_bloc_test/ajwah_bloc_test.dart';
import 'package:bloc_ext/bloc_ext.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import 'counterCubit.dart';
import 'searchCategoryCubit.dart';
import 'todoCubit.dart';

void main() {
  group('Counter Cubit', () {
    late CounterCubit todoCubit;

    setUp(() {
      todoCubit = CounterCubit();
    });

    tearDown(() {
      todoCubit.close();
    });

    ajwahTest<int>(
      'emit [1] when todoCubit.inc',
      build: () => todoCubit.stream,
      act: () => todoCubit.inc(),
      expect: [1],
    );

    ajwahTest<int>(
      'emit [-1] when todoCubit.inc',
      build: () => todoCubit.stream,
      act: () => todoCubit.dec(),
      expect: [-1],
    );
    ajwahTest<String>(
      "emit ['loading...', '1'] when todoCubit.asyncInc",
      build: () => todoCubit.count$,
      act: () => todoCubit.asyncInc(),
      expect: ['loading...', '1'],
    );
  });
  group('todos - ', () {
    late TodoCubit todoCubit;
    late SearchCategoryCubit searchCubit;
    setUp(() {
      todoCubit = TodoCubit();
      searchCubit = SearchCategoryCubit();
    });

    tearDown(() {
      todoCubit.close();
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
        build: () => todoCubit
            .remoteCubit<SearchCategoryCubit>()
            .flatMap((value) => value.stream$),
        verify: (states) {
          expect(states[0], SearchCategory.All);
        });

    ajwahTest<SearchCategory>('Remote cubic- Active',
        build: () => todoCubit
            .remoteCubit<SearchCategoryCubit>()
            .flatMap((value) => value.stream$),
        act: () => searchCubit.setCategory(SearchCategory.Active),
        verify: (states) {
          expect(states[0], SearchCategory.Active);
        });
    ajwahTest<List<Todo>>('3 todos initialized.',
        build: () => todoCubit.todo$,
        verify: (states) {
          expect(states[0].length, 3);
        });
    ajwahTest<List<Todo>>('2 active todos.',
        build: () => todoCubit.todo$,
        act: () => searchCubit.setCategory(SearchCategory.Active),
        skip: 1,
        verify: (states) {
          expect(states[0].length, 2);
        });

    ajwahTest<SearchInputAction>('check action',
        build: () => todoCubit.action$.isA<SearchInputAction>(),
        act: () {
          todoCubit.dispatch(SearchInputAction('h'));
        },
        verify: (states) {
          expect(states[0].searchText, 'h');
        });

    ajwahTest<List<Todo>>('searching by hel',
        build: () => todoCubit.todo$,
        act: () {
          todoCubit.dispatch(SearchInputAction('h'));
          todoCubit.dispatch(SearchInputAction('he'));
          todoCubit.dispatch(SearchInputAction('hel'));
        },
        wait: Duration(milliseconds: 200),
        skip: 2,
        verify: (states) {
          expect(states[0].length, 1);
        });
    test('get remote state', () async {
      final state =
          await todoCubit.remoteState<SearchCategoryCubit, SearchCategory>();

      expect(state, SearchCategory.All);
    });
    ajwahTest<SearchCategory>('Remote Stream(SearchCategoryCubit)- Active',
        build: () =>
            todoCubit.remoteStream<SearchCategoryCubit, SearchCategory>(),
        act: () => searchCubit.setCategory(SearchCategory.Active),
        verify: (states) {
          expect(states[0], SearchCategory.Active);
        });
  });

  group('Filter Actiions', () {
    late CounterCubit controller;
    setUp(() {
      controller = CounterCubit();
    });

    tearDown(() {
      controller.close();
    });

    ajwahTest<SearchInputAction>(
      'action handler isA',
      build: () => controller.action$.isA<SearchInputAction>(),
      act: () {
        controller.dispatch(SearchInputAction('hi'));
      },
      expect: [isA<SearchInputAction>()],
      verify: (models) {
        expect(models[0].searchText, 'hi');
      },
    );
    ajwahTest<Action>(
      'action handler whereType',
      build: () => controller.action$.whereType('mono'),
      act: () {
        controller.dispatch(Action(type: 'mono'));
      },
      log: (states) {
        print(states);
      },
      expect: [isA<Action>()],
      verify: (models) {
        expect(models[0].type, 'mono');
      },
    );

    ajwahTest<Action>(
      'action handler whereTypes',
      build: () => controller.action$.whereTypes(['monoX', 'monoc']),
      act: () {
        controller.dispatch(Action(type: 'monoc'));
      },
      expect: [isA<Action>()],
      verify: (models) {
        expect(models[0].type, 'monoc');
      },
    );
    ajwahTest<Action>(
      'action handler where',
      build: () => controller.action$.where((action) => action.type == 'mono'),
      act: () {
        controller.dispatch(Action(type: 'mono'));
      },
      expect: [isA<Action>()],
      verify: (models) {
        expect(models[0].type, 'mono');
      },
    );
  });
}
