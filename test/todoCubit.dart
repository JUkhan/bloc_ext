import 'package:bloc_ext/bloc_ext.dart';
import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'searchCategoryCubit.dart';

class Todo {
  Todo({required this.description, this.completed = false});

  final String description;
  final bool completed;

  Todo copyWith({
    String? description,
    bool? completed,
  }) {
    return Todo(
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }
}

final List<Todo> initTodos = [
  Todo(description: 'Hi'),
  Todo(description: 'Hello', completed: true),
  Todo(description: 'Learn Reactive Programming')
];

class TodoCubit extends Cubit<List<Todo>> with CubitEx {
  TodoCubit() : super(initTodos) {
    $initEx();
    registerEffects([
      action$
          .isA<SearchInputAction>()
          .debounceTime(const Duration(milliseconds: 10))
          .map((action) => SearchTodoAction(action.searchText))
    ]);
  }

  Stream<List<Todo>> get todo$ =>
      Rx.combineLatest3<List<Todo>, SearchCategory, String, List<Todo>>(
          stream$,
          remoteCubit<SearchCategoryCubit>().flatMap((event) => event.stream$),
          action$
              .isA<SearchTodoAction>()
              .map<String>((action) => action.searchText)
              .startWith(''), (todos, category, searchText) {
        if (searchText.isNotEmpty) {
          todos = todos
              .where((todo) => todo.description
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
      }).startWith(state);
}

class SearchTodoAction extends Action {
  final String searchText;
  SearchTodoAction(this.searchText);
}

class SearchInputAction extends Action {
  final String searchText;
  SearchInputAction(this.searchText);
}
