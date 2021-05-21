import 'package:bloc_ext/bloc_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void useMonoEffect(
    Stream<Action> stream$, void Function(Action action) dispatch) {
  useEffect(() {
    final sub = stream$.listen((action) {
      dispatch(action);
    });
    return sub.cancel;
  }, []);
}
