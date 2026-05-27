import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../services/sync_service.dart';

/// Login / Register screen.
/// Shown when user chooses "Cloud" in Settings and is not yet signed in.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true; // toggle between login & register
  bool _busy = false;
  String? _error;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      UserCredential cred;
      if (_isLogin) {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
      }

      if (!mounted) return;

      // Ask if user wants to migrate local data to cloud
      final uid = cred.user!.uid;
      await _offerMigration(uid);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e.code));
    } catch (e) {
      setState(() => _error = 'შეცდომა: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerMigration(String uid) async {
    final upload = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('ლოკალური მონაცემები'),
        content: const Text(
          'გსურთ ამ მოწყობილობაზე შენახული ჩანაწერები Cloud-ში ატვირთოთ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('არა'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ატვირთვა'),
          ),
        ],
      ),
    );

    if (upload == true) {
      setState(() => _busy = true);
      try {
        final count = await SyncService.uploadLocalToCloud(uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$count ჩანაწერი ატვირთულია ✓')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ატვირთვა ვერ მოხდა: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }

    // Activate cloud mode in settings
    await ref.read(settingsProvider.notifier).setStorageMode(StorageMode.cloud);

    if (mounted) Navigator.pop(context, true); // return to settings
  }

  String _authError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'მომხმარებელი ვერ მოიძებნა';
      case 'wrong-password':
        return 'პაროლი არასწორია';
      case 'email-already-in-use':
        return 'ეს ელ-ფოსტა უკვე გამოყენებულია';
      case 'weak-password':
        return 'პაროლი ძალიან სუსტია (მინ. 6 სიმბოლო)';
      case 'invalid-email':
        return 'ელ-ფოსტის ფორმატი არასწორია';
      case 'too-many-requests':
        return 'ძალიან ბევრი მცდელობა — ცოტა ხანი დაიცადეთ';
      case 'network-request-failed':
        return 'ქსელის შეცდომა — შეამოწმეთ ინტერნეტი';
      default:
        return 'შეცდომა ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'შესვლა' : 'რეგისტრაცია'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Icon ──────────────────────────────────────────────
                  Icon(
                    Icons.cloud_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cloud სინქრონიზაცია',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ჩანაწერები ინახება Firebase-ში\nდა ხელმისაწვდომია ნებისმიერი მოწყობილობიდან',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),

                  // ── Email ─────────────────────────────────────────────
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'ელ-ფოსტა',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'შეიყვანეთ ელ-ფოსტა';
                      }
                      if (!v.contains('@')) return 'ელ-ფოსტა არასწორია';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────────────────────
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: 'პაროლი',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'შეიყვანეთ პაროლი';
                      if (!_isLogin && v.length < 6) {
                        return 'მინიმუმ 6 სიმბოლო';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Error ─────────────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                  ],

                  const SizedBox(height: 16),

                  // ── Submit button ─────────────────────────────────────
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'შესვლა' : 'რეგისტრაცია'),
                  ),
                  const SizedBox(height: 12),

                  // ── Toggle login / register ────────────────────────────
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            }),
                    child: Text(
                      _isLogin
                          ? 'ანგარიში არ გაქვთ? რეგისტრაცია'
                          : 'უკვე გაქვთ ანგარიში? შესვლა',
                    ),
                  ),

                  // ── Forgot password ────────────────────────────────────
                  if (_isLogin)
                    TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text('პაროლი დამავიწყდა'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'ჯერ შეიყვანეთ ელ-ფოსტა');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('პაროლის აღდგენის ბმული გაიგზავნა ✓')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _authError(e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
