import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Generate a random 6-character family join code
  String _generateJoinCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    int temp = random;
    for (int i = 0; i < 6; i++) {
      code += chars[temp % chars.length];
      temp ~/= chars.length;
    }
    return code;
  }

  Future<Map<String, dynamic>> createFamily({
  required String familyName,
  required String name,
  required String email,
  required String password,
  required String avatar,
}) async {
  try {
    // 1. Create auth account
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (authResponse.user == null) {
      return {'success': false, 'message': 'Failed to create account'};
    }

    // 2. Wait a moment for auth to settle
    await Future.delayed(const Duration(seconds: 1));

    // 3. Create family record
    final joinCode = _generateJoinCode();
    final familyResponse = await _supabase
        .from('families')
        .insert({'name': familyName, 'join_code': joinCode})
        .select()
        .single();

    // 4. Create user profile
    await _supabase.from('users').insert({
      'id': authResponse.user!.id,
      'family_id': familyResponse['id'],
      'name': name,
      'role': 'Parent',
      'avatar': avatar,
      'points': 0,
    });

    return {
      'success': true,
      'join_code': joinCode,
      'message': 'Family created successfully!'
    };
  } catch (e) {
    return {'success': false, 'message': e.toString()};
  }
}

  // JOIN EXISTING FAMILY (member joins with code)
  Future<Map<String, dynamic>> joinFamily({
    required String joinCode,
    required String name,
    required String email,
    required String password,
    required String avatar,
  }) async {
    try {
      // 1. Find family by join code
      final familyResponse = await _supabase
          .from('families')
          .select()
          .eq('join_code', joinCode.toUpperCase())
          .maybeSingle();

      if (familyResponse == null) {
        return {'success': false, 'message': 'Invalid family code'};
      }

      // 2. Create auth account
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Failed to create account'};
      }

      // 3. Create user profile
      await _supabase.from('users').insert({
        'id': authResponse.user!.id,
        'family_id': familyResponse['id'],
        'name': name,
        'role': 'Child',
        'avatar': avatar,
        'points': 0,
      });

      return {'success': true, 'message': 'Joined family successfully!'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // SIGN IN
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return {'success': false, 'message': 'Invalid email or password'};
      }

      return {'success': true, 'message': 'Signed in successfully!'};
    } catch (e) {
      return {'success': false, 'message': 'Invalid email or password'};
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // GET CURRENT USER
  User? get currentUser => _supabase.auth.currentUser;
}