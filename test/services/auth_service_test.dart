import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agbc_app/services/auth_service.dart';
import 'package:agbc_app/models/user_model.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  FirebaseFirestore,
])
import 'auth_service_test.mocks.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  MockDocumentSnapshot({Map<String, dynamic>? data, bool exists = true})
      : _data = data,
        _exists = exists;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _exists;
}

class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {
  final Map<String, MockDocumentReference> _docs = {};

  @override
  MockDocumentReference doc([String? path]) {
    return _docs.putIfAbsent(path ?? '', () => MockDocumentReference());
  }
}

class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {
  MockDocumentSnapshot? _snapshot;

  void setData(Map<String, dynamic> data) {
    _snapshot = MockDocumentSnapshot(data: data, exists: true);
  }

  @override
  Future<MockDocumentSnapshot> get([GetOptions? options]) async {
    return _snapshot ?? MockDocumentSnapshot(exists: false);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _snapshot = MockDocumentSnapshot(data: data, exists: true);
    return Future<void>.value();
  }
}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();

    // Setup default mock behavior
    when(mockUser.uid).thenReturn('test-uid');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.emailVerified).thenReturn(true);
    when(mockUserCredential.user).thenReturn(mockUser);

    // Setup Firestore mock behavior
    when(mockFirestore.collection('users')).thenReturn(mockCollection);

    // Setup document data
    mockDocument.setData({
      'uid': 'test-uid',
      'email': 'test@example.com',
      'displayName': 'Test User',
      'role': 'member',
      'churchId': 'church-123',
      'location': 'Test Location',
    });

    authService = AuthService(
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
    );
  });

  group('Sign In Tests', () {
    test('successful sign in with email and password', () async {
      // Setup
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);

      // Act
      await authService.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      );

      // Assert
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'test@example.com');
      expect(authService.currentUser?.displayName, 'Test User');
      expect(authService.currentUser?.role, 'member');
    });

    test('sign in with unverified email throws error', () async {
      // Setup
      when(mockUser.emailVerified).thenReturn(false);
      when(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);

      // Act & Assert
      expect(
        () async => await authService.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Please verify your email before logging in.')),
      );
    });

    test('sign in with non-existent email throws error', () async {
      // Setup
      when(mockAuth.signInWithEmailAndPassword(
        email: 'nonexistent@example.com',
        password: 'password123',
      )).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      // Act & Assert
      expect(
        () async => await authService.signInWithEmailAndPassword(
          email: 'nonexistent@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'This email is not registered. Please create an account first.')),
      );
    });
  });

  group('Registration Tests', () {
    test('successful user registration', () async {
      // Setup
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password123',
      )).thenAnswer((_) async => mockUserCredential);

      when(mockUser.sendEmailVerification()).thenAnswer((_) async => null);
      when(mockUser.updateDisplayName('New User')).thenAnswer((_) async => null);

      // Act
      await authService.registerWithEmailAndPassword(
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
        location: 'New Location',
      );

      // Assert
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser?.email, 'new@example.com');
      expect(authService.currentUser?.displayName, 'New User');
      expect(authService.currentUser?.role, 'member');
      expect(authService.currentUser?.location, 'New Location');
    });

    test('registration with existing email throws error', () async {
      // Setup
      when(mockAuth.createUserWithEmailAndPassword(
        email: 'existing@example.com',
        password: 'password123',
      )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      // Act & Assert
      expect(
        () async => await authService.registerWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'password123',
          name: 'Existing User',
          location: 'Location',
        ),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'An account already exists with this email.')),
      );
    });
  });

  group('Logout Tests', () {
    test('successful logout', () async {
      // Setup
      when(mockAuth.signOut()).thenAnswer((_) async => null);

      // Act
      await authService.logout();

      // Assert
      expect(authService.currentUser, isNull);
    });
  });

  group('Authentication State Tests', () {
    test('isAuthenticated returns true for authenticated user', () async {
      // Setup
      when(mockAuth.currentUser).thenReturn(mockUser);

      // Act
      final isAuthenticated = await authService.isAuthenticated();

      // Assert
      expect(isAuthenticated, true);
      expect(authService.currentUser, isNotNull);
    });

    test('isAuthenticated returns false for unauthenticated user', () async {
      // Setup
      when(mockAuth.currentUser).thenReturn(null);

      // Act
      final isAuthenticated = await authService.isAuthenticated();

      // Assert
      expect(isAuthenticated, false);
      expect(authService.currentUser, isNull);
    });
  });
} 