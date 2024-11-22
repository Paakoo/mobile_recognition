import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectionUtils {
  DetectionUtils._();

  static const double _yawThreshold = 15;
  static const double _pitchThreshold = 15;
  static const double _rollThreshold = 15;
  static const double _sideYawMinThreshold = 30;
  static const double _sideYawMaxThreshold = 60;
  static const double _blinkThreshold = 0.7;

  static bool isWholeFace(Face face, double imageWidth, double imageHeight) {
    final boundingBox = face.boundingBox;
    final coutours = face.contours[FaceContourType.face];
    if (coutours == null) return false;
    final top = boundingBox.top;
    final bottom = boundingBox.bottom;
    final left = coutours.points[27].x;
    final right = coutours.points[9].x;
    return top > 0 && bottom < imageHeight && left > 0 && right < imageHeight;
  }

  static bool isFrontFace(Face face) {
    final yaw = face.headEulerAngleY; 
    final pitch = face.headEulerAngleX; 
    final roll = face.headEulerAngleZ; 
    if (yaw == null || pitch == null || roll == null) {
      return false;
    }
    return yaw < _yawThreshold &&
        yaw > -_yawThreshold &&
        pitch < _pitchThreshold &&
        pitch > -_pitchThreshold &&
        roll < _rollThreshold &&
        roll > -_rollThreshold;
  }

  static bool isLeftSideFace(Face face) {
    final yaw = face.headEulerAngleY;
    final pitch = face.headEulerAngleX;
    final roll = face.headEulerAngleZ;

    if (yaw == null || pitch == null || roll == null) {
      return false;
    }
    return yaw < -_sideYawMinThreshold && 
           yaw > -_sideYawMaxThreshold &&
           pitch.abs() < _pitchThreshold &&
           roll.abs() < _rollThreshold;
  }

  static bool isRightSideFace(Face face) {
    final yaw = face.headEulerAngleY;
    final pitch = face.headEulerAngleX;
    final roll = face.headEulerAngleZ;

    if (yaw == null || pitch == null || roll == null) {
      return false;
    }
    return yaw > _sideYawMinThreshold && 
           yaw < _sideYawMaxThreshold &&
           pitch.abs() < _pitchThreshold &&
           roll.abs() < _rollThreshold;
  }

  static bool isBlink(Face face) {  
    final leftEye = face.leftEyeOpenProbability;
    final rightEye = face.rightEyeOpenProbability;  
    if (leftEye == null || rightEye == null) {
      return false;
    }

    return leftEye < _blinkThreshold || rightEye < _blinkThreshold;
  }

  static bool isSmiling(Face face) {
    if (!isFrontFace(face)) return false;
    final smile = face.smilingProbability;
    if (smile == null) return false;
    return smile > 0.6;
  }

}