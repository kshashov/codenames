import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';

class UserBloc with ChangeNotifier, DiagnosticableTreeMixin {
  late SharedPreferences prefs;
  final user = BehaviorSubject<User>();

  UserBloc() {
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      String? userJson = prefs.getString('user');
      if (userJson != null) {
        // Get user from local storage
        Map userMap = jsonDecode(userJson);
        var userModel = User.fromJson(userMap);
        user.add(userModel);
      } else {
        // Create user and save to local storage
        var userModel = User(const Uuid().v1(), "NoName");
        prefs.setString('user', jsonEncode(userModel.toJson()));
        user.add(userModel);
      }
    });
  }

  rename(String name) {
    var userModel = user.valueOrNull;
    if (userModel == null) return;
    if (userModel.name == name) return;

    userModel.name = name;
    prefs.setString('user', jsonEncode(userModel.toJson()));
    user.add(userModel);
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties
// @override
// void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//   super.debugFillProperties(properties);
//   properties.add(StringProperty('user', user.first));
// }
}
