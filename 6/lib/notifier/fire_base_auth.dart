import 'dart:io';

import 'package:CWCFlutter/model/word.dart';
import 'package:CWCFlutter/model/user.dart';
import 'package:CWCFlutter/notifier/auth_notifier.dart';
import 'package:CWCFlutter/notifier/word_notifier.dart';
import 'package:CWCFlutter/screens/Homepage.dart';
import 'package:CWCFlutter/screens/login.dart';
import 'package:CWCFlutter/screens/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

login(User user, AuthNotifier authNotifier, Function onSuccess,
    Function(String) onSignInError) async {
  AuthResult authResult = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: user.email, password: user.password)
      .then((user) {
    onSuccess();
  })
      .catchError((error) {
    onSignInError("Sign-In fail, please try again");
  });
  AuthResult authResult1 = await FirebaseAuth.instance
      .signInWithEmailAndPassword(email: user.email, password: user.password)
      .catchError((error) {
    onSignInError("Sign-In fail, please try again");
  });
  print(authResult1.user.email);
  if (authResult1 != null) {
    FirebaseUser firebaseUser = authResult1.user;
    print("1");
    if (firebaseUser != null) {
      print("Log In: $firebaseUser");
      authNotifier.setUser(firebaseUser);
    }
  }
}

resetemail(
    String email, AuthNotifier authNotifier, BuildContext context) async {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  signout(authNotifier, context);
  return _firebaseAuth.sendPasswordResetEmail(email: email);
}

signup(User user, AuthNotifier authNotifier, Function onSuccess,
    Function(String) onRegisterError,BuildContext context) async {
  AuthResult authResult = await FirebaseAuth.instance
      .createUserWithEmailAndPassword(
          email: user.email, password: user.password)
.catchError((err) {
    print("err: " + err.toString());
    _onSignUpErr(err.code, onRegisterError);
  });

  if (authResult != null) {
    print("VC");
    UserUpdateInfo updateInfo = UserUpdateInfo();
    updateInfo.displayName = user.displayName;

    FirebaseUser firebaseUser = authResult.user;

    if (firebaseUser != null) {
      await firebaseUser.updateProfile(updateInfo);

      await firebaseUser.reload();

      print("Sign up: $firebaseUser");

      FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
      authNotifier.setUser(currentUser);
    }

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Homepage()));
  }
}

signout(AuthNotifier authNotifier, BuildContext context) async {
  await FirebaseAuth.instance
      .signOut()
      .catchError((error) => print(error.code));
  authNotifier.setUser(null);
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login()));
}

initializeCurrentUser(AuthNotifier authNotifier) async {
  FirebaseUser firebaseUser = await FirebaseAuth.instance.currentUser();

  if (firebaseUser != null) {
    print(firebaseUser);
    authNotifier.setUser(firebaseUser);
  }
}

_createUser(String userId, String name, String email, Function onSuccess,
    Function(String) onRegisterError) {
  var user = Map<String, String>();
  user["name"] = name;
  user["email"] = email;
  var ref = FirebaseDatabase.instance.reference().child("users");
  ref.child(userId).set(user).then((vl) {
    print("on value: SUCCESSED");
    onSuccess();
  }).catchError((err) {
    print("err: " + err.toString());
    onRegisterError("SignUp fail, please try again");
  }).whenComplete(() {
    print("completed");
  });
}

_onSignUpErr(String code, Function(String) onRegisterError) {
  print(code);
  switch (code) {
    case "ERROR_INVALID_EMAIL":
    case "ERROR_INVALID_CREDENTIAL":
      onRegisterError("Invalid email");
      break;
    case "ERROR_EMAIL_ALREADY_IN_USE":
      onRegisterError("Email has existed");
      break;
    case "ERROR_WEAK_PASSWORD":
      onRegisterError("The password is not strong enough");
      break;
    default:
      onRegisterError("SignUp fail, please try again");
      break;
  }
}
