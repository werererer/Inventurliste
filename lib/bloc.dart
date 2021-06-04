import 'package:replay_bloc/replay_bloc.dart';

abstract class BlocEvent<Args> extends ReplayEvent {
  Future<Args> changeState(Args args);
}
