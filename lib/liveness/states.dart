import 'dart:developer';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tes/liveness/utils.dart';

abstract class LivenessState {
  void handle(LivenessContext context, Face face);
}

abstract class FramesLimitState implements LivenessState {
  final int limit;
  int _currentFrame = 0;

  FramesLimitState(this.limit);

  @override
  void handle(LivenessContext context, Face face) {
    if (isPass(face)) {
      _currentFrame++;
      if (_currentFrame > limit) {
        _currentFrame = 0;
        context._next();
      }
    } else {
      _currentFrame = 0;
    }
  }

  bool isPass(Face face);
}

class FrontFaceState extends FramesLimitState {
  FrontFaceState(super.limit);

  @override
  bool isPass(Face face) {
    return DetectionUtils.isFrontFace(face);
  }
}

class isRightSideFaceState extends FramesLimitState {
  isRightSideFaceState(super.limit);

  @override
  bool isPass(Face face) {
    return DetectionUtils.isRightSideFace(face);
  }
}

class isLeftSideFaceState extends FramesLimitState {
  isLeftSideFaceState(super.limit);

  @override
  bool isPass(Face face) {
    return DetectionUtils.isLeftSideFace(face);
  }
}

class SmileState extends FramesLimitState {
  SmileState(super.limit);

  @override
  bool isPass(Face face) {
    return DetectionUtils.isSmiling(face);
  }
}                            

class BlinkState extends FramesLimitState {
  BlinkState(super.limit);

  @override
  bool isPass(Face face) {
    return DetectionUtils.isBlink(face);
  }
}

class _CompleteState extends LivenessState {
  @override
  void handle(LivenessContext context, Face face) {    
    log("completed");
  }
}

class LivenessContext {
  final List<LivenessState> _states;
  final void Function(
      {required void Function() next,
      required void Function() retry}) stateChangeCallback;
  final void Function(int photoCount) onCompleted;

  LivenessContext(
      {required List<LivenessState> states,
      required this.stateChangeCallback,
      required this.onCompleted}) : _states = List.of(states) {
    _states.add(_CompleteState());
  }

  int _stateIndex = 0;
  bool _transitioning = false;

  void handle(Face face) {
    if (_transitioning) return;
    currentState.handle(this, face);
  }

  void _next() {
    if (_transitioning) {
      return;
    }
    _transitioning = true;
    stateChangeCallback(
        next: () {
          if (_transitioning) {
            _transitioning = false;
            _stateIndex++;
            if (_stateIndex == _states.length - 1) {
              onCompleted(_states.length - 1);
            }
          }
        },
        retry: () => _transitioning = false);
  }

  void reset() {
    _transitioning = false;
    _stateIndex = 0;
  }

  LivenessState get currentState => _states[_stateIndex];

  bool get isCompleted => _stateIndex == _states.length - 1;
}