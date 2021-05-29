import '../widgets/StreamConsumer.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:get/instance_manager.dart';
import 'package:bloc_ext/bloc_ext.dart';

import '../states/counter.dart';
import './nav.dart';

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final csCtl = Get.find<CounterState>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Counter'),
        actions: nav(),
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => csCtl.inc(),
                child: const Text('Inc'),
              ),
              ElevatedButton(
                onPressed: () => csCtl.dec(),
                child: const Text('Dec'),
              ),
              ElevatedButton(
                onPressed: () => csCtl.dispatch(Action(type: 'asyncInc')),
                child: const Text('Async Inc'),
              ),
            ],
          ),
          StreamConsumer<String>(
            stream: csCtl.count$,
            builder: (context, count) => Text(
              count,
              style: Theme.of(context).textTheme.headline4,
            ),
          ),
          StreamConsumer<String>(
            stream: csCtl.select((state) => '${state * 2}'),
            builder: (context, count) => Text(
              count,
              style: Theme.of(context).textTheme.headline4,
            ),
          )
        ],
      )),
    );
  }
}
