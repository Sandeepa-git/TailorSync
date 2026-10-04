import 'package:flutter/material.dart';

import '../../../../ui/ui.dart';

/// Full privacy policy. Opened from Profile > Privacy Policy and from the
/// Terms & Conditions screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = <(String, String)>[
    (
      '1. About this policy',
      'This Privacy Policy explains how TailorSync ("we", "us", "our") collects, uses, stores, shares and protects '
          'personal data when you use the TailorSync mobile and web app ("the App").\n\n'
          'TailorSync is used by tailoring businesses ("Business Owners") and their staff to manage customers, orders, '
          'measurements, fabric stock and reports. It applies to:\n'
          '• Business Owners and staff who have an account, and\n'
          '• Customers of those businesses whose details are entered into the App.\n\n'
          'We aim to handle personal data in line with the Personal Data Protection Act No. 9 of 2022 of Sri Lanka (PDPA) '
          'and generally accepted data-protection practices.',
    ),
    (
      '2. Who is responsible for the data',
      '• Account data (owners and staff): TailorSync is responsible for this data.\n'
          '• Customer data entered by a tailoring business (names, contact details, measurements, orders, photos): the '
          'tailoring business is the "controller" and decides why this data is collected. TailorSync acts as a '
          '"processor" and only handles it to provide the App to that business.\n\n'
          'If you are a customer of a tailoring business and have a question about your data, please contact that business '
          'first. We will help them respond to your request.',
    ),
    (
      '3. Information we collect',
      'a) Account information\n'
          '• Full name, email address, phone number and role (owner or staff)\n'
          '• Business name, business registration number, address and business contact details\n'
          '• Your password, which is stored only as a secure one-way hash (we cannot read it)\n\n'
          'b) Customer information (entered by the business)\n'
          '• Name, phone number, email address, address and gender\n'
          '• Body measurements (for example chest, waist, hip, shoulder, sleeve and inseam), height and weight\n'
          '• Notes and preferences recorded by the tailor\n\n'
          'c) Order and business information\n'
          '• Garment type, selected fabric, fabric quantity, prices, due dates, status and order history\n'
          '• Fabric inventory levels, restocks and usage history\n'
          '• Staff task assignments and progress\n'
          '• Reports and statistics calculated from the above\n\n'
          'd) Photos (Virtual Try-On)\n'
          '• A photo you take or choose, and the dress description you select, when you use the Virtual Try-On feature\n\n'
          'e) Technical and security information\n'
          '• Login times, IP address, device and browser type, app version and error logs\n'
          '• A security check token from Google reCAPTCHA when you sign in or sign up\n'
          '• Counts of how many Virtual Try-On images were generated (to manage free usage limits)',
    ),
    (
      '4. How we use information',
      'We use personal data only to:\n'
          '• Create and manage accounts, sign you in and keep your account secure\n'
          '• Store customers, measurements and orders so the business can make garments\n'
          '• Predict missing measurements and estimate fabric quantities using AI\n'
          '• Recommend suitable fabrics and show their stock level\n'
          '• Generate Virtual Try-On preview images\n'
          '• Track fabric stock, send low-stock alerts and produce business reports\n'
          '• Assign and track staff tasks\n'
          '• Prevent fraud, spam and automated abuse (reCAPTCHA)\n'
          '• Fix errors, monitor performance and improve the App\n'
          '• Meet legal obligations\n\n'
          'We do not sell personal data, we do not use it for advertising, and we do not use customer data to build '
          'marketing profiles.',
    ),
    (
      '5. Legal basis for processing',
      'We process personal data on the following grounds:\n'
          '• Performance of a contract: to provide the App you signed up for\n'
          '• Consent: for example when you upload a photo for Virtual Try-On, or when a customer agrees to give their '
          'measurements to a tailor. Consent can be withdrawn at any time\n'
          '• Legitimate interests: keeping the App secure, preventing abuse and improving features\n'
          '• Legal obligations: where the law requires us to keep or disclose information',
    ),
    (
      '6. AI features and what they receive',
      'TailorSync uses artificial intelligence in three places:\n\n'
          '• Measurement prediction and fabric recommendation: these use Microsoft Azure AI Foundry and our own '
          'machine-learning model. Only the garment type, the measurements already entered, height/weight and order '
          'preferences are sent. Customer names, phone numbers, emails and addresses are not sent to the AI service.\n\n'
          '• Virtual Try-On: the photo and dress description are sent to Cloudflare Workers AI (an image-generation '
          'model) to create a preview. The photo is processed only to generate that image and is not saved on '
          'TailorSync servers. The generated image is returned to your device. You must have the permission of the '
          'person in the photo before using this feature.\n\n'
          '• AI results are suggestions only. A tailor should always check AI measurements before cutting fabric.\n\n'
          'Our AI providers process this data under their own terms and security commitments and do not use it to '
          'advertise to you.',
    ),
    (
      '7. Sharing with service providers',
      'We share data only with trusted providers that help us run the App, and only as much as they need:\n\n'
          '• Microsoft Azure: application hosting and AI services\n'
          '• Neon (PostgreSQL): secure cloud database storage\n'
          '• Cloudflare Workers AI: Virtual Try-On image generation\n'
          '• Google (reCAPTCHA and Firebase): bot protection and account authentication services\n\n'
          'We may also disclose information if required by law, court order or a government authority, or to protect '
          'the rights, safety and property of our users or the public.\n\n'
          'If TailorSync is merged or sold, personal data may transfer to the new owner, who must continue to protect it '
          'under this policy.',
    ),
    (
      '8. International data transfers',
      'Our servers and service providers may be located outside Sri Lanka (for example in the United States or the '
          'European Union). When data is transferred abroad we rely on providers that offer strong security and '
          'contractual protections, and we transfer only what is needed to provide the App.',
    ),
    (
      '9. How long we keep data',
      '• Account, customer, order and inventory data: kept while the business account is active\n'
          '• After an account is closed: data can be exported within 30 days, then it is deleted or anonymised, unless '
          'the law requires us to keep it longer\n'
          '• Virtual Try-On photos: not stored on our servers; only a usage count is kept\n'
          '• Security and error logs: normally kept for up to 90 days\n'
          '• Anonymised statistics (which cannot identify anyone) may be kept to improve the App',
    ),
    (
      '10. How we protect data',
      '• All data sent between the App and our servers is encrypted with HTTPS (TLS)\n'
          '• Data is stored in managed cloud databases with encryption at rest\n'
          '• Passwords are hashed and never stored in plain text\n'
          '• Access is protected with secure tokens and role-based permissions: staff only see what their role allows, '
          'and inventory and reports are limited to Business Owners\n'
          '• Each business can only access its own customers, orders and stock\n'
          '• Secret keys are kept in secure server settings, not inside the App\n\n'
          'No system is completely secure. If a data breach affects your personal data, we will notify you and the '
          'relevant authority as required by law.',
    ),
    (
      '11. Your rights',
      'Under the PDPA and similar laws you have the right to:\n'
          '• Access the personal data we hold about you\n'
          '• Correct inaccurate or incomplete data\n'
          '• Request deletion of your data\n'
          '• Withdraw consent at any time (this does not affect earlier processing)\n'
          '• Object to or restrict certain processing\n'
          '• Receive a copy of your data in a common format (data portability)\n'
          '• Make a complaint to the Data Protection Authority of Sri Lanka\n\n'
          'Business Owners can view, edit and delete customer records directly in the App. To make any other request, '
          'contact us using the details below. We will respond within 21 working days and may need to verify your '
          'identity first.',
    ),
    (
      '12. Responsibilities of tailoring businesses',
      'If you are a Business Owner, you agree to:\n'
          '• Tell your customers that their details and measurements are recorded in TailorSync\n'
          '• Get the customer\'s permission before taking or uploading their photo\n'
          '• Enter only data that is needed for their orders\n'
          '• Keep your staff accounts secure and remove staff who leave\n'
          '• Delete customer data when it is no longer needed or when a customer asks',
    ),
    (
      '13. Children',
      'TailorSync accounts are for adults running or working in a tailoring business. A business may record '
          'measurements for a customer under 18 (for example a school uniform) only with the consent of a parent or '
          'guardian. We do not knowingly collect children\'s data for any other purpose.',
    ),
    (
      '14. Cookies and local storage',
      'The App stores a sign-in token and basic settings (such as theme) on your device so you stay logged in. The '
          'web version may use cookies required for sign-in and for Google reCAPTCHA. We do not use advertising or '
          'tracking cookies.',
    ),
    (
      '15. Changes to this policy',
      'We may update this policy when the App or the law changes. The "Last updated" date at the top shows the latest '
          'version. If the changes are significant we will notify you in the App or by email before they take effect.',
    ),
    (
      '16. Contact us',
      'For privacy questions, requests or complaints:\n\n'
          '• Email: privacy@tailorsync.app\n'
          '• Support: support@tailorsync.app\n'
          '• In the App: Profile > Contact Support\n\n'
          'If you are not satisfied with our response, you may contact the Data Protection Authority of Sri Lanka.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return TsScrollPage(
      title: 'Privacy Policy',
      maxWidth: MaxWidth.form + 120,
      slivers: [
        SliverToBoxAdapter(
          child: EntranceFade(
            child: TsCard(
              padding: const EdgeInsets.all(Space.lg),
              gradient: Gradients.hero(cs),
              shadow: true,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: Radii.brMd,
                    ),
                    child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your privacy matters', style: context.text.titleLarge?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                          'Last updated: October 2026',
                          style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        SliverToBoxAdapter(
          child: TsCard(
            shadow: false,
            color: cs.primary.withValues(alpha: 0.07),
            padding: const EdgeInsets.all(Space.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('In short', style: context.text.titleSmall?.copyWith(color: cs.primary)),
                const SizedBox(height: Space.xs),
                Text(
                  '• We only collect what is needed to run your tailoring business.\n'
                  '• We never sell your data or use it for ads.\n'
                  '• AI services never receive customer names or contact details.\n'
                  '• Try-on photos are not stored on our servers.\n'
                  '• You can view, correct, export or delete your data.',
                  style: context.text.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        SliverList.list(
          children: [
            for (final s in _sections) _PolicySection(title: s.$1, content: s.$2),
            const SizedBox(height: Space.md),
            Center(
              child: Text(
                '© 2026 TailorSync. All rights reserved.',
                style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Expandable section card.
class _PolicySection extends StatefulWidget {
  final String title;
  final String content;
  const _PolicySection({required this.title, required this.content});

  @override
  State<_PolicySection> createState() => _PolicySectionState();
}

class _PolicySectionState extends State<_PolicySection> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TsCard(
        padding: EdgeInsets.zero,
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: Radii.brLg,
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(widget.title, style: context.text.titleSmall?.copyWith(color: cs.primary))),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: Motion.of(context, Motion.short),
                      curve: Motion.standard,
                      child: const Padding(
                        padding: EdgeInsets.all(Space.sm),
                        child: Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.emphasized,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
                      child: Text(widget.content, style: context.text.bodyMedium?.copyWith(height: 1.6)),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
