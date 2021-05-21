import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'actions.dart';
import 'action.dart';
import 'package:meta/meta.dart';

typedef RemoteStateCallback<S> = void Function(S state);

class _RemoteStateAction<S> extends Action {
  final Completer<S> completer;
  final Type controller;
  _RemoteStateAction(this.controller, this.completer);
}

class _RemoteControllerAction<S> extends Action {
  final Completer<S> completer;
  final Type controller;
  _RemoteControllerAction(this.controller, this.completer);
}

var _dispatcher = BehaviorSubject<Action>.seeded(Action(type: '@Init'));
var _action$ = Actions(_dispatcher);

mixin CubitEx<T> on Cubit<T> {
  StreamSubscription<Action>? _subscription;
  StreamSubscription<Action>? _effectSubscription;

  ///You need to call this function to receive action
  ///on you cubit and to enable communications to the other cubits.
  @protected
  void $initEx() {
    _subscription?.cancel();
    _subscription = _dispatcher.distinct().listen((action) {
      onAction(action);
    });
  }

  @protected
  void registerEffects(Iterable<Stream<Action>> streams) {
    _effectSubscription?.cancel();
    _effectSubscription = Rx.merge(streams).listen(dispatch);
  }

  ///This function fired when action dispatches from the cubits.
  @protected
  @mustCallSuper
  void onAction(Action action) {
    if (action is _RemoteStateAction &&
        action.controller == runtimeType &&
        !action.completer.isCompleted) {
      action.completer.complete(state);
    } else if (action is _RemoteControllerAction &&
        action.controller == runtimeType &&
        !action.completer.isCompleted) {
      action.completer.complete(this);
    }
  }

  ///Dispatching an action is just like firing an event.
  ///
  ///Whenever the action is dispatched it notifies all the cubit
  ///those who override the `onAction(action Action)` method and also
  ///notifes all the effects - registered throughout the cubits.
  ///
  ///A easy way to communicate among the cubits.
  void dispatch(Action action) {
    _dispatcher.add(action);
  }

  ///Return a `Acctions` instance.
  ///
  ///So that you can filter the actions those are dispatches throughout
  ///the application. And also make effect/s on it.
  ///
  Actions get action$ => _action$;

  ///This function returns the current state of a cubit as a `Future` value
  ///
  ///`Example`
  ///
  ///```dart
  ///final category = await remoteState<SearchCategoryCubit, SearchCategory>();
  ///```
  ///
  Future<State> remoteState<Cubit, State>() {
    final completer = Completer<State>();
    dispatch(_RemoteStateAction(Cubit, completer));

    return completer.future;
  }

  ///This function returns Cubit instance as a Steam depends on the type
  ///you attached with the function.
  ///
  ///`Example`
  ///
  ///This example returns todo list filtered by searchCategory.
  ///We need `SearchCategoryCubit` stream combining with `TodoCubit's` stream:
  ///```dart
  ///Stream<List<Todo>> get todo$ =>
  ///    Rx.combineLates2<List<Todo>, SearchCategory, List<Todo>>(
  ///        stream$, remoteCubit<SearchCategoryCubit>()
  ///         .flatMap((event) => event.stream$),(todos, category) {
  ///      switch (category) {
  ///        case SearchCategory.Active:
  ///          return todos.where((todo) => !todo.completed).toList();
  ///        case SearchCategory.Completed:
  ///          return todos.where((todo) => todo.completed).toList();
  ///        default:
  ///          return todos;
  ///     }
  ///    });
  ///```
  ///
  Stream<Cubit> remoteCubit<Cubit>() {
    final completer = Completer<Cubit>();
    dispatch(_RemoteControllerAction(Cubit, completer));
    return Stream.fromFuture(completer.future);
  }

  ///Return the part of the current state of the cubit as a Stream<S>.
  Stream<S> select<S>(S Function(T state) mapCallback) {
    return stream.map<S>(mapCallback).distinct();
  }

  Stream<T> get stream$ => stream.startWith(state).distinct();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _effectSubscription?.cancel();
    return super.close();
  }
}
