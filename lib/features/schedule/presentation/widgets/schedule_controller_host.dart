import 'package:flutter/material.dart';

import '../controllers/schedule_controller.dart';

class ScheduleControllerHost extends StatefulWidget {
  const ScheduleControllerHost({
    required this.builder,
    super.key,
    this.controller,
  });

  final ScheduleController? controller;
  final Widget Function(BuildContext context, ScheduleController controller)
  builder;

  @override
  State<ScheduleControllerHost> createState() => _ScheduleControllerHostState();
}

class _ScheduleControllerHostState extends State<ScheduleControllerHost> {
  late final ScheduleController controller =
      widget.controller ?? ScheduleController();
  late final bool ownsController = widget.controller == null;

  @override
  void dispose() {
    if (ownsController) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => widget.builder(context, controller),
    );
  }
}
