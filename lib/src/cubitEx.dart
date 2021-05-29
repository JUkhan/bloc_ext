import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'actions.dart';
import 'action.dart';
import 'package:meta/meta.dart';

typedef RemoteStateCallback<S> = void Function(S state);

class _RemoteControllerAction<S> extends Action {
  final Completer<S> completer;
  final Type controller;
  _RemoteControllerAction(this.controller, this.completer);
}

var _dispatcher = BehaviorSubject<Action>.seeded(Action(type: '@Init'));
var _action$ = Actions(_dispatcher);

///This is an extension pacckage for bloc `Cubit` ( enables - dispatching actions, adding effects, communications among cubits, rxDart full features etc. inside the cubits ).
mixin CubitEx<T> on Cubit<T> {
  StreamSubscription<Action>? _subscription;
  StreamSubscription<Action>? _effectSubscription;
  StreamSubscription<T>? _mapEffectsSubscription;

  ///You need to call this function to receive action
  ///on you cubit and to enable communications to the other cubits.
  @protected
  void $initEx() {
    _subscription?.cancel();
    _subscription = _dispatcher.listen(onAction);
    Future.delayed(Duration(milliseconds: 0)).then((_) => onInit());
  }

  ///This function calls after $initEx().
  @protected
  void onInit() {}

  ///This function registers the effect/s and also
  ///un-registers previous effeccts (if found any).
  ///
  /// [streams] param for one or more effects.
  ///
  /// `Example search effect:`
  ///
  /// This effect start working when SearchInputAction is dispatched
  /// then wait 320 mills to receive subsequent actions(SearchInputAction) -
  /// when reach out time limit it sends a request to server and then dispatches
  ///`SearchResultAction` when server response come back. Now any `cubit` can
  /// receive SearchResultAction who override `onAction` method / you can use
  /// action$.isA\<SearchResultAction\>().
  ///
  /// ```dart
  /// registerEffects([
  ///   action$.isA<SearchInputAction>()
  ///   .debounceTime(const Duration(milliseconds: 320))
  ///   .switchMap((action) => pullData(action.searchText))
  ///   .map((res) => SearchResultAction(res)),
  /// ]);
  /// ```
  @protected
  void registerEffects(Iterable<Stream<Action>> streams) {
    _effectSubscription?.cancel();
    _effectSubscription = Rx.merge(streams).listen(dispatch);
  }

  ///This function just like `registerEffects` but return `Stream<State>` instead of `Stream<Action>`.
  /// ```dart
  /// mapActionToState([
  ///   action$.isA<AsyncIncAction>()
  ///   .delay(const Duration(milliseconds: 500))
  ///   .map((action) => state+1),
  ///
  /// ]);
  /// ```
  @protected
  void mapActionToState(Iterable<Stream<T>> streams) {
    _mapEffectsSubscription?.cancel();
    _mapEffectsSubscription = Rx.merge(streams).listen(emit);
  }

  ///This function fired when action dispatches from the cubits.
  @protected
  @mustCallSuper
  void onAction(Action action) {
    if (action is _RemoteControllerAction &&
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

  ///Return a `Actions` instance.
  ///
  ///To filter the actions those are dispatches throughout
  ///the application. And also make effect/s on it/map to state.
  ///
  Actions get action$ => _action$;

  Future<C> _remoteData<C extends CubitEx>() {
    final completer = Completer<C>();
    dispatch(_RemoteControllerAction(C, completer));
    return completer.future;
  }

  ///This function returns the current state of a cubit as a `Future` value
  ///
  ///`Example`
  ///
  ///```dart
  ///final category = await remoteState<SearchCategoryCubit, SearchCategory>();
  ///```
  ///
  Future<S> remoteState<C extends CubitEx<S>, S>() =>
      _remoteData<C>().then((value) => value.state);

  ///This function returns the Cubit instance as a Steam depends on the generic type
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
  Stream<C> remoteCubit<C extends CubitEx>() =>
      Stream.fromFuture(_remoteData<C>());

  ///This function returns the state of a the Cubit instance as a Steam depends on the generic types
  ///you attached with the function.
  ///
  ///`Example`
  ///
  ///This example returns todo list filtered by searchCategory.
  ///We need `SearchCategoryCubit` stream combining with `TodoCubit's` stream:
  ///```dart
  ///Stream<List<Todo>> get todo$ =>
  ///    Rx.combineLates2<List<Todo>, SearchCategory, List<Todo>>(
  ///        stream$,
  ///        remoteStream<SearchCategoryCubit, SearchCategory>(),
  ///        (todos, category) {
  ///        switch (category) {
  ///           case SearchCategory.Active:
  ///             return todos.where((todo) => !todo.completed).toList();
  ///           case SearchCategory.Completed:
  ///             return todos.where((todo) => todo.completed).toList();
  ///           default:
  ///             return todos;
  ///         }
  ///    });
  ///```
  ///
  Stream<S> remoteStream<C extends CubitEx<S>, S>() =>
      remoteCubit<C>().flatMap((value) => value.stream$);

  ///Return the part of the current state of the cubit as a Stream<S>.
  Stream<S> select<S>(S Function(T state) mapCallback) =>
      stream.startWith(state).map<S>(mapCallback).distinct();

  ///Return the current state of the cubit as a Stream<S>.
  Stream<T> get stream$ => stream.startWith(state).distinct();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _effectSubscription?.cancel();
    await _mapEffectsSubscription?.cancel();
    return super.close();
  }
}
