import 'package:flutter/material.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/screens/login/login_screen.dart';
import 'package:my_app/widgets/floating_icons_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
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
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF0088CC), Color(0xFF00AADD)],
          ).createShader(bounds),
          child: const Text(
            'Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Color(0xFF0088CC)),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FloatingIconsBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0088CC)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF0088CC), Color(0xFF00AADD)],
                      ).createShader(bounds),
                      child: Text(
                        'Quick Access',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0088CC).withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0088CC).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0088CC).withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0088CC),
            child: Text(
              _currentUser?.fullName.isNotEmpty == true
                  ? _currentUser!.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.fullName ?? 'User',
                  style: const TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    final items = [
      DashboardItem(
        icon: Icons.notifications_rounded,
        title: 'Notices',
        color: const Color(0xFF00d4ff),
        onTap: () => _showFeatureMessage('Notices'),
      ),
      DashboardItem(
        icon: Icons.school_rounded,
        title: 'Departments',
        color: const Color(0xFF7B68EE),
        onTap: () => _showFeatureMessage('Departments'),
      ),
      DashboardItem(
        icon: Icons.person_rounded,
        title: 'Profile',
        color: const Color(0xFF00CED1),
        onTap: () => _showFeatureMessage('Profile'),
      ),
      DashboardItem(
        icon: Icons.settings_rounded,
        title: 'Settings',
        color: const Color(0xFFFF6B6B),
        onTap: () => _showFeatureMessage('Settings'),
      ),
      DashboardItem(
        icon: Icons.calendar_today_rounded,
        title: 'Calendar',
        color: const Color(0xFF4ECDC4),
        onTap: () => _showFeatureMessage('Calendar'),
      ),
      DashboardItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        color: const Color(0xFFFF4757),
        onTap: _handleLogout,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _DashboardCard(item: items[index]),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0088CC).withOpacity(0.2),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            accountName: Text(
              _currentUser?.fullName ?? 'User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2D3748)),
            ),
            accountEmail: Text(
              _currentUser?.email ?? '',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: const Color(0xFF0088CC),
              child: Text(
                _currentUser?.fullName.isNotEmpty == true
                    ? _currentUser!.fullName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Menu Items
          _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
          _buildDrawerItem(
            Icons.notifications,
            'Notices',
            () => _showFeatureMessage('Notices'),
          ),
          _buildDrawerItem(
            Icons.school,
            'Departments',
            () => _showFeatureMessage('Departments'),
          ),
          _buildDrawerItem(
            Icons.person,
            'Profile',
            () => _showFeatureMessage('Profile'),
          ),
          _buildDrawerItem(
            Icons.settings,
            'Settings',
            () => _showFeatureMessage('Settings'),
          ),

          const Spacer(),

          // Logout
          const Divider(color: Color(0xFF0088CC)),
          _buildDrawerItem(Icons.logout, 'Logout', () {
            Navigator.pop(context);
            _handleLogout();
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF0088CC)),
      title: Text(title, style: const TextStyle(color: Color(0xFF2D3748))),
      onTap: onTap,
    );
  }

  void _showFeatureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0088CC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class DashboardItem {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  DashboardItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.color.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 32, color: item.color),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                style: const TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
