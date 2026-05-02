import 'package:supabase_flutter/supabase_flutter.dart';

class DataService {
  final _supabase = Supabase.instance.client;
  SupabaseClient get supabase => _supabase;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ─── FAMILY ───
  Future<Map<String, dynamic>?> getCurrentFamily() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id, families(*)')
          .eq('id', currentUserId!)
          .single();
      return user['families'];
    } catch (e) {
      return null;
    }
  }

  // ─── USERS ───
  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final members = await _supabase
          .from('users')
          .select()
          .eq('family_id', user['family_id']);

      return List<Map<String, dynamic>>.from(members);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = await _supabase
          .from('users')
          .select()
          .eq('id', currentUserId!)
          .single();
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUserName(String newName) async {
    try {
      await _supabase
          .from('users')
          .update({'name': newName})
          .eq('id', currentUserId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserAvatar(String newAvatar) async {
    try {
      await _supabase
          .from('users')
          .update({'avatar': newAvatar})
          .eq('id', currentUserId!);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFamilyName(String familyId, String newName) async {
    try {
      await _supabase
          .from('families')
          .update({'name': newName})
          .eq('id', familyId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── TASKS ───
  Future<List<Map<String, dynamic>>> getTodaysTasks() async {
  try {
    final user = await _supabase
        .from('users')
        .select('family_id')
        .eq('id', currentUserId!)
        .single();

    final tasks = await _supabase
        .from('tasks')
        .select('*, assigned_user:users!assigned_to(name, avatar)')
        .eq('family_id', user['family_id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(tasks);
  } catch (e) {
    return [];
  }
}

  Future<List<Map<String, dynamic>>> getAllTasks() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final tasks = await _supabase
          .from('tasks')
          .select('*, assigned_user:users!assigned_to(name, avatar)')
          .eq('family_id', user['family_id'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(tasks);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required String assignedTo,
    required DateTime dueDate,
    required String difficulty,
    required String recurrence,
    required int points,
  }) async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      // Find assigned user by name
      final assignedUser = await _supabase
          .from('users')
          .select('id')
          .eq('family_id', user['family_id'])
          .eq('name', assignedTo)
          .single();

      await _supabase.from('tasks').insert({
        'family_id': user['family_id'],
        'title': title,
        'description': description,
        'assigned_to': assignedUser['id'],
        'created_by': currentUserId,
        'due_date': dueDate.toIso8601String(),
        'difficulty': difficulty,
        'recurrence': recurrence,
        'points': points,
        'status': 'Pending',
      });

      // Add to activity feed
      await _supabase.from('activity_feed').insert({
        'family_id': user['family_id'],
        'user_id': currentUserId,
        'type': 'assigned',
        'content': 'New task "$title" assigned to $assignedTo',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    try {
      await _supabase
          .from('tasks')
          .update({'status': status})
          .eq('id', taskId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── MESSAGES ───
  Future<List<Map<String, dynamic>>> getMessages() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final messages = await _supabase
          .from('messages')
          .select('*, sender:users!user_id(name, avatar)')
          .eq('family_id', user['family_id'])
          .order('created_at');

      return List<Map<String, dynamic>>.from(messages);
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendMessage(String content) async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      await _supabase.from('messages').insert({
        'family_id': user['family_id'],
        'user_id': currentUserId,
        'content': content,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── REWARDS ───
  Future<List<Map<String, dynamic>>> getRewards() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final rewards = await _supabase
          .from('rewards')
          .select()
          .eq('family_id', user['family_id']);

      return List<Map<String, dynamic>>.from(rewards);
    } catch (e) {
      return [];
    }
  }

  // ─── ACTIVITY FEED ───
  Future<List<Map<String, dynamic>>> getActivityFeed() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final feed = await _supabase
          .from('activity_feed')
          .select('*, user:users!user_id(name, avatar)')
          .eq('family_id', user['family_id'])
          .order('created_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(feed);
    } catch (e) {
      return [];
    }
  }

  // ─── REQUESTS (Done tasks pending approval) ───
  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final tasks = await _supabase
          .from('tasks')
          .select('*, assigned_user:users!assigned_to(name, avatar)')
          .eq('family_id', user['family_id'])
          .eq('status', 'Done');

      return List<Map<String, dynamic>>.from(tasks);
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveTask(String taskId, int points, String userId) async {
    try {
      // Update task status
      await _supabase
          .from('tasks')
          .update({'status': 'Completed'})
          .eq('id', taskId);

      // Add points to user
      await _supabase.rpc('increment_points',
          params: {'user_id': userId, 'points_to_add': points});

      return true;
    } catch (e) {
      return false;
    }
  }
}
