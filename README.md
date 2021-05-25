# bloc_ext

An extension package for bloc `Cubit`. `CubitEx` introduces some cool features for `Cubit`. Now every `Cubit` would have the following features:

- Dispatching actions
- Filtering actions
- Adding effects
- Communications among Cubits
- RxDart full features

Please go through the [example](https://github.com/JUkhan/bloc_ext/tree/master/example). This example contains `counter` and `todo` pages those demonstrate `CubitEx` out of the box.

`CounterCubit`

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';
import 'package:rxdart/rxdart.dart';

import '../widgets/StreamConsumer.dart';

class CounterCubit extends Cubit<int> with CubitEx {
  CounterCubit() : super(0) {
    $initEx();
  }
  void inc() => emit(state + 1);

  void dec() => emit(state - 1);

  void asyncInc() async {
    dispatch(Action(type: 'asyncInc'));
    await Future.delayed(const Duration(seconds: 1));
    inc();
  }

  Stream<SCResponse> get count$ => Rx.merge([
        action$.whereType('asyncInc').mapTo(SCLoading()),
        stream$.map((data) => data > 10
            ? SCError('Counter is out of the range.')
            : SCData('$data')),
      ]);
}

```

`TodoCubit`

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';
import 'package:rxdart/rxdart.dart';

import '../api/todoApi.dart';
import './searchCategory.dart';

class TodoCubit extends Cubit<List<Todo>> with CubitEx {
  TodoState() : super([]) {
    $initEx();
  }

  @override
  void onInit() {
    loadTodos();
    /**
     * Effect for todo search input. For each key strokes AddTodo widget dispatching
     * SearchInputAction. But effect throttles it for 320 mills to collect the subsequent
     * actions and then finally dispatching SearchTodoAction.
     */
    registerEffects([
      action$
          .isA<SearchInputAction>()
          .debounceTime(const Duration(milliseconds: 320))
          .map((action) => SearchTodoAction(action.searchText))
    ]);
  }

  void loadTodos() {
    getTodos().listen(emit);
  }

  void add(String description) {
    addTodo(Todo(description: description))
        .listen((todo) => emit([...state, todo]));
  }

  void update(Todo todo) {
    updateTodo(todo).listen(
        (todo) => emit([
              for (var item in state)
                if (item.id == todo.id) todo else item,
            ]), onError: (error) {
      dispatch(TodoErrorAction(error));
    });
  }

  void remove(Todo todo) {
    removeTodo(todo).listen(
        (todo) => emit(state.where((item) => item.id != todo.id).toList()));
  }

  Stream<String> get activeTodosInfo$ => stream$
      .map((todos) => todos.where((todo) => !todo.completed).toList())
      .map((todos) => '${todos.length} items left');

  ///Here is an example - combining multiplle cubits(TodoCubit, SearchCategoryCubit)
  ///with SearchTodoAction and returns single todos stream.
  Stream<List<Todo>> get todo$ =>
      Rx.combineLatest3<List<Todo>, SearchCategory, String, List<Todo>>(
          stream$,
          remoteStream<SearchCategoryCubit, SearchCategory>(),
          action$
              .isA<SearchTodoAction>()
              .map((action) => action.searchText)
              .startWith(''),
          (todos, category, searchText) {
              if (searchText.isNotEmpty) {
                  todos = todos.where((todo) => todo.description
                            .toLowerCase()
                            .contains(searchText.toLowerCase()))
                            .toList();
              }
              switch (category) {
                case SearchCategory.Active:
                  return todos.where((todo) => !todo.completed).toList();
                case SearchCategory.Completed:
                  return todos.where((todo) => todo.completed).toList();
                default:
                  return todos;
              }
      });
}

class TodoErrorAction extends Action {
  final dynamic error;
  TodoErrorAction(this.error);
}

class SearchInputAction extends Action {
  final String searchText;
  SearchInputAction(this.searchText);
}

class SearchTodoAction extends Action {
  final String searchText;
  SearchTodoAction(this.searchText);
}

```

`SearchCategoryCubit`

```dart
import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';

enum SearchCategory { All, Active, Completed }

class SearchCategoryCubit extends Cubit<SearchCategory> with CubitEx {
  SearchCategoryCubit() : super(SearchCategory.All) {
    $initEx();
  }

  void setCategory(SearchCategory category) => emit(category);
}

```
