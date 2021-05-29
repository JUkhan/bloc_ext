import 'package:bloc/bloc.dart';
import 'package:bloc_ext/bloc_ext.dart';
import 'package:rxdart/rxdart.dart';

import '../widgets/StreamConsumer.dart';

class CounterState extends Cubit<int> with CubitEx {
  CounterState() : super(0) {
    $initEx();
  }
  @override
  void onInit() {
    mapEffectsToState([
      action$
          .whereType('asyncInc')
          .delay(const Duration(seconds: 1))
          .map((event) => state + 1),
    ]);
  }

  void inc() => emit(state + 1);

  void dec() => emit(state - 1);

  Stream<SCResponse> get count$ => Rx.merge([
        action$.whereType('asyncInc').mapTo(SCLoading()),
        stream$.map((data) => data > 10
            ? SCError('Counter is out of the range.')
            : SCData('$data')),
      ]);
}
