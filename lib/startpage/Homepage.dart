import 'package:flutter/material.dart';

import '../Onboardingpage/Login.dart';
import '../Onboardingpage/Signup.dart';

/* -------------------------- HOME PAGE -------------------------- */
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LoginPopup(),
    );
  }

  void _showSignupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const SignupPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const kGreen = Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'EcoFlow',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.notifications_none, color: Colors.black87),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 820;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 16,
              vertical: 16,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: isWide ? 1200 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroBanner(
                      isWide: isWide,
                      kGreen: kGreen,
                      onStartJourney: () => _showLoginDialog(context),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(child: RevenueExpenseCard(isWide: isWide)),
                    const SizedBox(height: 18),
                    const SectionTitle('Discover Local Shops'),
                    const SizedBox(height: 12),
                    AnimatedShopList(isWide: isWide),
                    const SizedBox(height: 18),
                    SectionCard(child: ShopOwnerTools()),
                    const SizedBox(height: 24),
                    const FooterAdsAndLinks(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* -------------------------- HERO BANNER -------------------------- */
class HeroBanner extends StatelessWidget {
  final bool isWide;
  final Color kGreen;
  final VoidCallback onStartJourney;

  const HeroBanner({
    super.key,
    required this.isWide,
    required this.kGreen,
    required this.onStartJourney,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 32 : 20,
        vertical: isWide ? 28 : 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7F3EA)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.energy_savings_leaf, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'EcoFlow',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Demo Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://picsum.photos/800/300?random=1",
              height: isWide ? 250 : 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sustainable Living,\nSimplified',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your energy, discover local, empower your business.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: isWide ? 320 : double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onStartJourney,
              child: const Text(
                'Start Your EcoFlow Journey',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------- SECTION CARD -------------------------- */
class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

/* -------------------------- SECTION TITLE -------------------------- */
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

/* -------------------------- REVENUE & EXPENSE CARD -------------------------- */
class RevenueExpenseCard extends StatelessWidget {
  final bool isWide;
  const RevenueExpenseCard({super.key, required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.show_chart, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Revenue & Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          '\$2,450.00',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track your income and outflows easily to understand your financial health.',
          style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.3),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: isWide ? 90 : 70,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFBBF7D0), Color(0xFFDCFCE7)]),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Chart Preview',
              style:
                  TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: const Text('View Full Report'),
          ),
        ),
      ],
    );
  }
}

/* -------------------------- SHOP OWNER TOOLS -------------------------- */
class ShopOwnerTools extends StatelessWidget {
  const ShopOwnerTools({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.storefront, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Shop Owner Tools',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const BulletText('Manage products & inventory seamlessly.'),
        const BulletText('Access detailed sales analytics.'),
        const BulletText('Connect with your local customers.'),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2F4F7),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'Manage My Shop',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

/* -------------------------- BULLET TEXT -------------------------- */
class BulletText extends StatelessWidget {
  final String text;
  const BulletText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, height: 1.55)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/* -------------------------- ANIMATED SHOP LIST -------------------------- */
class AnimatedShopList extends StatelessWidget {
  final bool isWide;
  const AnimatedShopList({super.key, required this.isWide});

  @override
  Widget build(BuildContext context) {
    final shopItems = List.generate(6, (index) => 'Shop ${index + 1}');
    return SizedBox(
      height: 140,
      child: isWide
          ? GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: shopItems
                  .map((shop) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFBF4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(shop)),
                      ))
                  .toList(),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shopItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, index) => Container(
                width: 120,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFBF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(shopItems[index])),
              ),
            ),
    );
  }
}

/* -------------------------- FOOTER -------------------------- */
class FooterAdsAndLinks extends StatelessWidget {
  const FooterAdsAndLinks({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.grey),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('© 2025 EcoFlow. All rights reserved.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    );
  }
}
