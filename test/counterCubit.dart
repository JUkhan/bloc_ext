import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';
import 'package:rxdart/rxdart.dart';

class CounterCubit extends Cubit<int> with CubitEx {
  CounterCubit() : super(0) {
    $initEx();
  }
  EffectFun<int> get asyncIncBy => effect<int>((num$) => num$
      .delay(const Duration(milliseconds: 10))
      .doOnData((by) => emit(state + by)));

  void inc() => emit(state + 1);
  void dec() => emit(state - 1);
  void asyncInc() async {
    dispatch(Action(type: 'asyncInc'));
    await Future.delayed(const Duration(milliseconds: 10));
    inc();
  }

  Stream<String> get count$ => Rx.merge([
        action$.whereType('asyncInc').mapTo('loading...'),
        stream.map((event) => '$event'),
      ]);
}
