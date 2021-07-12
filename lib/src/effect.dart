import 'dart:async';

typedef EffectCallback<S> = Stream<dynamic> Function(Stream<S> stream);
typedef EffectFun<S> = void Function(S arg);

///
///`Example`
///```dart
///EffectFun<int> get asyncIncBy => effect<int>((num$) => num$
///      .delay(const Duration(milliseconds: 10))
///      .doOnData((by) => emit(state + by)));
/// ```
///
EffectFun<S> effect<S>(EffectCallback<S> fx) {
  var sc = StreamController<S>();
  fx(sc.stream).listen((event) {});
  return (S arg) {
    sc.add(arg);
  };
}
