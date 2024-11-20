import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_atp/core/constants/colors.dart';
import 'package:test_atp/core/services/auth_service.dart';
import 'package:test_atp/core/utils/rand_art.dart';
import 'package:test_atp/feed/screens/feed_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController(text: 'https://bsky.social');
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedServer = 'https://bsky.social';
  bool _showAdvancedOptions = false;

  final List<String> _commonServers = [
    'https://bsky.social',
    'https://skyfeed.app',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _loadLastServer();
  }

  Future<void> _loadLastServer() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final lastServer = await authService.getLastServer();
    setState(() {
      _selectedServer = lastServer;
      _serverController.text = lastServer;
    });
  }

  Future<void> _login() async {
    if (!_serverController.text.startsWith('https://')) {
      setState(() {
        _errorMessage = 'Server URL must start with https://';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final success = await authService.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
        //service: _serverController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        );
      } else {
        setState(() {
          _errorMessage = authService.errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Login failed. Please check your credentials and server.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: RandomArtPainter(
              primaryColor: AppColors.blue.withOpacity(0.1),
              secondaryColor: AppColors.extraLightGray,
              patternType: PatternType.curves,
              layers: 5,
              numPoints: 50,
              opacity: 0.1,
              strokeWidth: 2.0,
            ),
            size: MediaQuery.of(context).size,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud,
                        size: 50,
                        color: AppColors.blue,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Sign in to Cumulus',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _identifierController,
                        decoration: InputDecoration(
                          hintText: 'Handle or email',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Log in',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAdvancedOptions = !_showAdvancedOptions;
                          });
                        },
                        child: Text(
                          'Advanced options',
                          style: TextStyle(
                            color: AppColors.darkGray,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_showAdvancedOptions) ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedServer,
                          decoration: InputDecoration(
                            labelText: 'Server',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          items: _commonServers.map((String server) {
                            return DropdownMenuItem<String>(
                              value: server,
                              child: Text(server),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedServer = newValue!;
                              if (newValue != 'Custom') {
                                _serverController.text = newValue;
                              } else {
                                _serverController.text = '';
                              }
                            });
                          },
                        ),
                        if (_selectedServer == 'Custom') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _serverController,
                            decoration: InputDecoration(
                              labelText: 'Custom Server URL',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    super.dispose();
  }
}
