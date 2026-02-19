import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/styles.dart';
import '../../functions/functions.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';

/// Tela Esqueci senha (novo fluxo auth). Só usada quando loginEmailPswd == 1.
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  String _error = '';
  String _success = '';
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = languages[choosenLanguage]['text_enter_email'] ?? 'Digite seu e-mail';
        _success = '';
      });
      return;
    }
    setState(() {
      _error = '';
      _success = '';
      _loading = true;
    });
    final result = await forgotPasswordAuth(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result == 'success') {
      setState(() {
        _success = languages[choosenLanguage]['text_forgot_password_sent'] ??
            'Se o e-mail estiver cadastrado, você receberá as instruções para redefinir sua senha.';
      });
    } else {
      setState(() => _error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Material(
      color: page,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: media.width * 0.05,
                vertical: media.height * 0.02,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: textColor,
                      size: media.height * 0.024,
                    ),
                  ),
                  SizedBox(width: media.width * 0.02),
                  Text(
                    languages[choosenLanguage]['text_forgot_password'] ??
                        'Esqueci minha senha',
                    style: GoogleFonts.poppins(
                      fontSize: media.width * 0.05,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: media.width * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: media.height * 0.04),
                    MyText(
                      text: languages[choosenLanguage]['text_forgot_password_desc'] ??
                          'Informe seu e-mail para receber o link de redefinição de senha.',
                      size: media.width * 0.038,
                      color: textColor.withOpacity(0.8),
                    ),
                    SizedBox(height: media.height * 0.03),
                    MyText(
                      text: languages[choosenLanguage]['text_enter_email'] ?? 'E-mail',
                      size: media.width * 0.038,
                      color: textColor.withOpacity(0.8),
                    ),
                    SizedBox(height: media.height * 0.01),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emailFocus.hasFocus ? buttonColor : textColor.withOpacity(0.3),
                          width: _emailFocus.hasFocus ? 2.0 : 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: languages[choosenLanguage]['text_enter_email'] ?? 'Digite seu e-mail',
                          hintStyle: GoogleFonts.poppins(color: hintColor, fontSize: media.width * 0.038),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: media.width * 0.04,
                            vertical: media.height * 0.02,
                          ),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(color: textColor, fontSize: media.width * 0.04),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      SizedBox(height: media.height * 0.02),
                      Container(
                        padding: EdgeInsets.all(media.width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: media.width * 0.06),
                            SizedBox(width: media.width * 0.03),
                            Expanded(
                              child: Text(
                                _error,
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade800,
                                  fontSize: media.width * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_success.isNotEmpty) ...[
                      SizedBox(height: media.height * 0.02),
                      Container(
                        padding: EdgeInsets.all(media.width * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: media.width * 0.06),
                            SizedBox(width: media.width * 0.03),
                            Expanded(
                              child: Text(
                                _success,
                                style: GoogleFonts.poppins(
                                  color: Colors.green.shade800,
                                  fontSize: media.width * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: media.height * 0.04),
                    Button(
                      onTap: _loading ? null : _submit,
                      text: _loading
                          ? (languages[choosenLanguage]['text_please_wait'] ?? 'Aguarde...')
                          : (languages[choosenLanguage]['text_send'] ?? 'Enviar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
