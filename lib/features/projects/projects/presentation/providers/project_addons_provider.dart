import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/project_addon.dart';

class ProjectAddonsNotifier extends Notifier<List<ProjectAddon>> {
  static const _prefKey = 'project_addons_list_v1';

  @override
  List<ProjectAddon> build() {
    _loadFromPrefs();
    return [];
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonStr);
        final loaded = decoded.map((item) => ProjectAddon.fromJson(item as Map<String, dynamic>)).toList();
        state = loaded;
      }
    } catch (e) {
      debugPrint('Failed to load project addons: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = state.map((a) => a.toJson()).toList();
      await prefs.setString(_prefKey, json.encode(serialized));
    } catch (e) {
      debugPrint('Failed to save project addons: $e');
    }
  }

  List<ProjectAddon> getAddonsForProject(String projectId) {
    return state.where((a) => a.projectId == projectId).toList();
  }

  double getTotalAddonsAmount(String projectId) {
    return getAddonsForProject(projectId).fold(0.0, (sum, a) => sum + a.amount);
  }

  double getTotalAddonsPaid(String projectId) {
    return getAddonsForProject(projectId).fold(0.0, (sum, a) => sum + a.amountPaid);
  }

  Future<void> addAddon(ProjectAddon addon) async {
    state = [...state, addon];
    await _saveToPrefs();
  }

  Future<void> updateAddon(ProjectAddon addon) async {
    state = [
      for (final a in state)
        if (a.id == addon.id) addon else a,
    ];
    await _saveToPrefs();
  }

  Future<void> deleteAddon(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _saveToPrefs();
  }

  Future<ProjectAddon?> recordPayment({
    required String addonId,
    required double paymentAmount,
    required String bankAccountId,
    required String bankAccountName,
    required String paymentMethod,
  }) async {
    final index = state.indexWhere((a) => a.id == addonId);
    if (index == -1) return null;

    final addon = state[index];
    final newPaid = addon.amountPaid + paymentAmount;
    final newPaymentStatus = newPaid >= addon.amount
        ? 'Paid'
        : (newPaid > 0 ? 'Partially Paid' : 'Unpaid');

    final updated = addon.copyWith(
      amountPaid: newPaid,
      paymentStatus: newPaymentStatus,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      paymentMethod: paymentMethod,
    );

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) updated else state[i],
    ];
    await _saveToPrefs();
    return updated;
  }
}

final projectAddonsProvider =
    NotifierProvider<ProjectAddonsNotifier, List<ProjectAddon>>(() {
  return ProjectAddonsNotifier();
});
