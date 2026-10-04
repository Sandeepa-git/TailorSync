import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Terms and Conditions',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
            boxShadow: AppTheme.softShadow,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/icon.png', height: 56),
                    const SizedBox(height: 10),
                    Text(
                      'TailorSync',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Terms and Conditions',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textBody,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last updated: October 2026',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              _buildSection(
                '1. Acceptance of Terms',
                'By creating an account, accessing, or using TailorSync ("the App"), you agree to be bound by these Terms and Conditions ("Terms"). If you do not agree to all of these Terms, you must not use the App.\n\n'
                'These Terms constitute a legally binding agreement between you ("User", "you", or "your") and TailorSync ("we", "us", or "our"). Your continued use of the App signifies your acceptance of any updated Terms.',
              ),

              _buildSection(
                '2. Description of Service',
                'TailorSync is a tailoring business management platform that provides the following services:\n\n'
                '• Customer management and record-keeping\n'
                '• Order creation, tracking, and management\n'
                '• Body measurement recording and storage\n'
                '• AI-powered measurement predictions and fabric recommendations\n'
                '• AI-powered style preview and virtual garment try-on\n'
                '• Staff management and task delegation\n'
                '• Business analytics and reporting\n'
                '• Notification and communication tools\n\n'
                'We reserve the right to modify, suspend, or discontinue any feature of the App at any time without prior notice.',
              ),

              _buildSection(
                '3. Account Registration',
                'To use TailorSync, you must create an account by providing accurate and complete information, including your business name, business registration number, email address, and other required details.\n\n'
                'You are responsible for:\n'
                '• Maintaining the confidentiality of your account credentials\n'
                '• All activities that occur under your account\n'
                '• Notifying us immediately of any unauthorized use of your account\n'
                '• Ensuring that all information provided is accurate and up to date\n\n'
                'We reserve the right to suspend or terminate accounts that contain false or misleading information, or that violate these Terms.',
              ),

              _buildSection(
                '4. Privacy and Data Protection',
                'Your privacy is important to us. By using TailorSync, you acknowledge and agree to the following:\n\n'
                '• We collect and store business information, customer data, measurements, and order details that you enter into the App.\n'
                '• Customer personal data (names, contact information, body measurements) is stored securely and is accessible only to authorized users within your organization.\n'
                '• Photos uploaded for the AI Style Preview feature are processed by third-party AI services (Google Gemini) and are not permanently stored by TailorSync.\n'
                '• We use industry-standard encryption and security measures to protect your data.\n'
                '• We do not sell, rent, or share your personal or business data with third parties for marketing purposes.\n'
                '• We may use anonymized, aggregated data for service improvement and analytics.\n'
                '• You may request deletion of your account and associated data at any time through the App settings.',
              ),

              _buildSection(
                '5. AI-Powered Features',
                'TailorSync includes AI-powered features such as measurement prediction, fabric recommendation, and style preview. By using these features, you acknowledge that:\n\n'
                '• AI predictions and recommendations are provided as suggestions only and should not be treated as exact or guaranteed results.\n'
                '• The Style Preview feature generates approximate visual representations and does not guarantee the final appearance of a garment.\n'
                '• You are responsible for verifying all AI-generated measurements and recommendations before using them for actual garment production.\n'
                '• AI features may use third-party services (such as Google Gemini and Azure AI), and their respective terms of service also apply.\n'
                '• We are not liable for any errors, inaccuracies, or damages resulting from reliance on AI-generated content.',
              ),

              _buildSection(
                '6. User Responsibilities',
                'As a user of TailorSync, you agree to:\n\n'
                '• Use the App only for lawful purposes related to tailoring business management.\n'
                '• Not upload inappropriate, offensive, or illegal content.\n'
                '• Not attempt to reverse-engineer, decompile, or disassemble the App.\n'
                '• Not use automated systems, bots, or scripts to access the App.\n'
                '• Not interfere with or disrupt the App\'s servers or networks.\n'
                '• Obtain proper consent from your customers before entering their personal data and measurements into the App.\n'
                '• Comply with all applicable local, national, and international laws and regulations.',
              ),

              _buildSection(
                '7. Staff Accounts',
                'If you create staff accounts under your business account:\n\n'
                '• You are responsible for the actions of all staff members using accounts under your organization.\n'
                '• Staff members will have access to customer data, orders, and other business information as permitted by their assigned role.\n'
                '• You may deactivate or remove staff accounts at any time.\n'
                '• Staff accounts are subject to the same Terms and Conditions.',
              ),

              _buildSection(
                '8. Intellectual Property',
                'All content, features, and functionality of TailorSync — including but not limited to the software, design, text, graphics, logos, icons, and AI models — are the exclusive property of TailorSync and are protected by intellectual property laws.\n\n'
                'You may not copy, modify, distribute, or create derivative works based on the App without our prior written consent.\n\n'
                'Content you create within the App (customer records, orders, measurements) remains your property. By using the App, you grant us a limited license to process and store this content solely for the purpose of providing the service.',
              ),

              _buildSection(
                '9. Payment and Subscription',
                'Certain features of TailorSync may require a paid subscription. If applicable:\n\n'
                '• Subscription fees will be clearly communicated before purchase.\n'
                '• Payments are non-refundable unless otherwise stated.\n'
                '• We reserve the right to change pricing with reasonable notice.\n'
                '• Failure to pay may result in restricted access to premium features.',
              ),

              _buildSection(
                '10. Service Availability',
                'We strive to maintain high availability of the App, but we do not guarantee uninterrupted access. The App may be temporarily unavailable due to:\n\n'
                '• Scheduled maintenance and updates\n'
                '• Server outages or technical issues\n'
                '• Force majeure events\n'
                '• Third-party service disruptions\n\n'
                'We are not liable for any losses or damages caused by service unavailability.',
              ),

              _buildSection(
                '11. Limitation of Liability',
                'To the maximum extent permitted by law:\n\n'
                '• TailorSync is provided "as is" and "as available" without any warranties of any kind, express or implied.\n'
                '• We do not warrant that the App will be error-free, secure, or meet your specific requirements.\n'
                '• We are not liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App.\n'
                '• Our total liability for any claims shall not exceed the amount you paid for the service in the preceding 12 months.\n'
                '• We are not responsible for any business decisions made based on data, predictions, or recommendations provided by the App.',
              ),

              _buildSection(
                '12. Termination',
                'We reserve the right to suspend or terminate your account at any time if:\n\n'
                '• You violate any of these Terms\n'
                '• You engage in fraudulent or illegal activities\n'
                '• Your account has been inactive for an extended period\n'
                '• We discontinue the service\n\n'
                'Upon termination, you may request an export of your data within 30 days. After this period, your data may be permanently deleted.',
              ),

              _buildSection(
                '13. Changes to Terms',
                'We may update these Terms from time to time. When we make significant changes, we will notify you through the App or via email. Your continued use of the App after such changes constitutes acceptance of the updated Terms.\n\n'
                'We encourage you to review these Terms periodically.',
              ),

              _buildSection(
                '14. Governing Law',
                'These Terms are governed by and construed in accordance with the laws of Sri Lanka. Any disputes arising from these Terms or your use of the App shall be subject to the exclusive jurisdiction of the courts of Sri Lanka.',
              ),

              _buildSection(
                '15. Contact Information',
                'If you have any questions, concerns, or feedback regarding these Terms and Conditions, please contact us:\n\n'
                '• Email: support@tailorsync.app\n'
                '• In-App: Settings > Help & Support',
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Footer
              Center(
                child: Text(
                  '© 2026 TailorSync. All rights reserved.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: AppTheme.textBody,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
