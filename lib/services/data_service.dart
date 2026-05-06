import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

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
        .neq('status', 'Pending Approval')
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
          .neq('status', 'Pending Approval')
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
          .select('family_id, role')
          .eq('id', currentUserId!)
          .single();

      final isParent = user['role'] == 'Parent';
      final status = isParent ? 'Pending' : 'Pending Approval';

      await _supabase.from('tasks').insert({
        'family_id': user['family_id'],
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'created_by': currentUserId,
        'due_date': dueDate.toIso8601String(),
        'difficulty': difficulty,
        'recurrence': recurrence,
        'points': points,
        'status': status,
      });

      if (isParent) {
        await _supabase.from('activity_feed').insert({
          'family_id': user['family_id'],
          'user_id': currentUserId,
          'type': 'assigned',
          'content': 'New task "$title" was assigned',
        });
      }

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

  Future<String?> uploadPhotoProof(String taskId, XFile imageFile) async {
    try {
      final fileName = '${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();

      // ignore: avoid_print
      print('Uploading photo: $fileName (${bytes.length} bytes)');
      await _supabase.storage
          .from('task-proofs')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('task-proofs')
          .getPublicUrl(fileName);

      // Update task with photo URL
      await _supabase
          .from('tasks')
          .update({'photo_proof_url': publicUrl})
          .eq('id', taskId);

      return publicUrl;
    } catch (e) {
      // ignore: avoid_print
      print('uploadPhotoProof ERROR: $e');
      return null;
    }
  }

  Future<bool> updateTaskWithPhotoProof(String taskId, String photoUrl) async {
    try {
      await _supabase
          .from('tasks')
          .update({'photo_proof_url': photoUrl})
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
          .order('created_at', ascending: false);

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

  Future<bool> createReward({
    required String emoji,
    required String title,
    required String description,
    required int pointsCost,
  }) async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      await _supabase.from('rewards').insert({
        'family_id': user['family_id'],
        'emoji': emoji,
        'title': title,
        'description': description,
        'points_cost': pointsCost,
      });
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('createReward ERROR: $e');
      return false;
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

  // ─── REQUESTS (Child-created tasks pending parent approval) ───
  Future<List<Map<String, dynamic>>> getPendingTaskApprovals() async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id')
          .eq('id', currentUserId!)
          .single();

      final tasks = await _supabase
          .from('tasks')
          .select('*, assigned_user:users!assigned_to(name, avatar), creator:users!created_by(name, avatar)')
          .eq('family_id', user['family_id'])
          .eq('status', 'Pending Approval')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(tasks);
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveTaskCreation(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .update({'status': 'Pending'})
          .eq('id', taskId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTaskCreation(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
      return true;
    } catch (e) {
      return false;
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
      final task = await _supabase
          .from('tasks')
          .select('title, family_id, assigned_user:users!assigned_to(name)')
          .eq('id', taskId)
          .single();

      await _supabase
          .from('tasks')
          .update({'status': 'Completed'})
          .eq('id', taskId);

      await _supabase.rpc('increment_points',
          params: {'user_id': userId, 'points_to_add': points});

      final assignedName = task['assigned_user']?['name'] ?? 'Someone';
      await _supabase.from('activity_feed').insert({
        'family_id': task['family_id'],
        'user_id': userId,
        'type': 'completed',
        'content': '$assignedName completed "${task['title']}" and earned $points pts! 🎉',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── TRANSFER TASK ───
  Future<bool> transferTask(String taskId, String newAssignedToId) async {
    try {
      final task = await _supabase
          .from('tasks')
          .select('title, family_id')
          .eq('id', taskId)
          .single();

      final newUser = await _supabase
          .from('users')
          .select('name')
          .eq('id', newAssignedToId)
          .single();

      await _supabase
          .from('tasks')
          .update({'assigned_to': newAssignedToId})
          .eq('id', taskId);

      await _supabase.from('activity_feed').insert({
        'family_id': task['family_id'],
        'user_id': currentUserId,
        'type': 'transfer',
        'content': 'Task "${task['title']}" was transferred to ${newUser['name']}',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── REDEEM REWARD ───
  Future<bool> redeemReward({
    required String rewardTitle,
    required int pointsCost,
  }) async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id, points, name')
          .eq('id', currentUserId!)
          .single();

      final currentPoints = (user['points'] ?? 0) as int;
      if (currentPoints < pointsCost) return false;

      await _supabase
          .from('users')
          .update({'points': currentPoints - pointsCost})
          .eq('id', currentUserId!);

      await _supabase.from('activity_feed').insert({
        'family_id': user['family_id'],
        'user_id': currentUserId,
        'type': 'reward',
        'content': '${user['name']} redeemed "$rewardTitle" for $pointsCost pts 🎁',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── TIME EXTENSION ───
  Future<bool> requestTimeExtension(String taskId, String taskTitle, String reason) async {
    try {
      final user = await _supabase
          .from('users')
          .select('family_id, name')
          .eq('id', currentUserId!)
          .single();

      await _supabase.from('tasks').update({
        'extension_requested': true,
        'extension_reason': reason,
      }).eq('id', taskId);

      await _supabase.from('activity_feed').insert({
        'family_id': user['family_id'],
        'user_id': currentUserId,
        'type': 'time_extension',
        'content': '${user['name']} requested more time for "$taskTitle": $reason',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTimeExtensionRequests() async {
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
          .eq('extension_requested', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(tasks);
    } catch (e) {
      return [];
    }
  }

  Future<bool> approveTimeExtension(String taskId, DateTime currentDueDate) async {
    try {
      final newDueDate = currentDueDate.add(const Duration(days: 2));
      await _supabase.from('tasks').update({
        'due_date': newDueDate.toIso8601String(),
        'extension_requested': false,
        'extension_reason': null,
      }).eq('id', taskId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectTimeExtension(String taskId) async {
    try {
      await _supabase.from('tasks').update({
        'extension_requested': false,
        'extension_reason': null,
      }).eq('id', taskId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
