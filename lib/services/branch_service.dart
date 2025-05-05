import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/church_branch_model.dart';

class BranchService {
  static final _supabase = Supabase.instance.client;

  static Future<List<ChurchBranch>> getBranches() async {
    try {
      final response = await _supabase.from('branches').select().order('name');

      return response.map((data) => ChurchBranch.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to load branches: $e');
    }
  }

  static Future<ChurchBranch> getBranch(String id) async {
    try {
      final response =
          await _supabase.from('branches').select().eq('id', id).single();

      return ChurchBranch.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load branch: $e');
    }
  }
}
