import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_icons_background.dart';
import '../login/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  UserModel? _currentUser;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getCurrentUser();
    final users = await _authService.getAllUsers();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _allUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF0088CC)),
        ),
        title: const Text('Logout', style: TextStyle(color: Color(0xFF2D3748))),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.student;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF0088CC)),
              SizedBox(width: 8),
              Text('Add New User', style: TextStyle(color: Color(0xFF2D3748))),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration('Full Name', Icons.person),
                    validator: (v) => v == null || v.trim().length < 2 ? 'Enter valid name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration('Email', Icons.email),
                    validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: _inputDecoration('Password', Icons.lock),
                    obscureText: true,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: selectedRole,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(value: UserRole.student, child: _roleItem(UserRole.student)),
                          DropdownMenuItem(value: UserRole.staff, child: _roleItem(UserRole.staff)),
                          DropdownMenuItem(value: UserRole.admin, child: _roleItem(UserRole.admin)),
                        ],
                        onChanged: (role) {
                          if (role != null) setDialogState(() => selectedRole = role);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _authService.registerUser(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: selectedRole,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (result.success) {
                      _loadData();
                      _showSnackBar('User created successfully!', Colors.green);
                    } else {
                      _showSnackBar(result.errorMessage ?? 'Failed', Colors.red);
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC)),
              child: const Text('Add User', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: const TextStyle(color: Color(0xFF2D3748), fontSize: 18)),
                  Text(_getRoleLabel(user.role), style: TextStyle(color: _getRoleColor(user.role), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.email, 'Email', user.email),
            const SizedBox(height: 8),
            _detailRow(Icons.calendar_today, 'Created', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            const SizedBox(height: 8),
            _detailRow(Icons.badge, 'Role', _getRoleLabel(user.role)),
          ],
        ),
        actions: [
          if (user.email != 'admin@uni.com')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete User?'),
                    content: Text('Delete ${user.fullName}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Delete', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _authService.deleteUser(user.email);
                  _loadData();
                  _showSnackBar('User deleted', Colors.orange);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0088CC)),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0088CC)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF4A5568), fontWeight: FontWeight.w500)),
        Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF2D3748)))),
      ],
    );
  }

  Widget _roleItem(UserRole role) {
    return Row(
      children: [
        Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
        const SizedBox(width: 8),
        Text(_getRoleLabel(role), style: const TextStyle(color: Color(0xFF2D3748))),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0088CC)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0088CC), width: 2),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin: return const Color(0xFFE53E3E);
      case UserRole.staff: return const Color(0xFF38A169);
      case UserRole.student: return const Color(0xFF3182CE);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin: return Icons.admin_panel_settings;
      case UserRole.staff: return Icons.work;
      case UserRole.student: return Icons.school;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin: return 'Administrator';
      case UserRole.staff: return 'Staff';
      case UserRole.student: return 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8EDF5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0088CC))),
      );
    }

    final students = _allUsers.where((u) => u.role == UserRole.student).toList();
    final staff = _allUsers.where((u) => u.role == UserRole.staff).toList();
    final admins = _allUsers.where((u) => u.role == UserRole.admin).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Admin Dashboard', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0088CC)),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0088CC)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF0088CC),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
      body: FloatingIconsBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF0088CC), const Color(0xFF0088CC).withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: const Color(0xFF0088CC).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.admin_panel_settings, size: 35, color: const Color(0xFF0088CC)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome, ${_currentUser?.fullName ?? 'Admin'}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Administrator Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Cards
                Row(
                  children: [
                    Expanded(child: _statsCard('Students', students.length, Icons.school, const Color(0xFF3182CE))),
                    const SizedBox(width: 12),
                    Expanded(child: _statsCard('Staff', staff.length, Icons.work, const Color(0xFF38A169))),
                    const SizedBox(width: 12),
                    Expanded(child: _statsCard('Admins', admins.length, Icons.admin_panel_settings, const Color(0xFFE53E3E))),
                  ],
                ),
                const SizedBox(height: 24),

                // Users List
                const Text('All Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                const SizedBox(height: 12),

                if (_allUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No users yet', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                else
                  ..._allUsers.map((user) => _userCard(user)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _userCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: () => _showUserDetails(user),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
          child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
        ),
        title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
        subtitle: Text(user.email, style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_getRoleLabel(user.role), style: TextStyle(color: _getRoleColor(user.role), fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}
