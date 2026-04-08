import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithPinEvent>(_onSignInWithPin);
    on<SignOutEvent>(_onSignOut);
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatus event, Emitter<AuthState> emit) async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      emit(AuthenticatedAsOwner(uid: currentUser.uid, email: currentUser.email ?? ''));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onSignInWithGoogle(SignInWithGoogleEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        emit(AuthInitial());
        return;
      }
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Save UID to Hive for Kasir login reference
        final box = Hive.box('settings');
        await box.put('lastOwnerId', user.uid);
        
        emit(AuthenticatedAsOwner(uid: user.uid, email: user.email ?? ''));
      } else {
        emit(const AuthError("Failed to login with Google."));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignInWithPin(SignInWithPinEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final box = Hive.box('settings');
      final String? lastOwnerId = box.get('lastOwnerId');
      
      if (lastOwnerId == null) {
        emit(const AuthError("Owner harus login sekali di perangkat ini terlebih dahulu."));
        return;
      }

      // Get PIN from the OWNER'S settings document
      final doc = await _firestore
          .collection('users')
          .doc(lastOwnerId)
          .collection('settings')
          .doc('config')
          .get();
          
      String correctPin = '1234'; // default
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('pin')) {
        correctPin = doc.data()!['pin'].toString();
      }

      if (event.pin == correctPin) {
        emit(AuthenticatedAsKasir(ownerId: lastOwnerId));
      } else {
        emit(const AuthError("PIN Salah"));
      }
    } catch (e) {
      emit(AuthError("Gagal memvalidasi PIN: ${e.toString()}"));
    }
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
