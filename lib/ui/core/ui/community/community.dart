import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Community extends StatelessWidget {
  const Community({super.key});

  Color get _bg => const Color(0xFF0F0F12);
  Color get _card => const Color(0xFF232326);
  Color get _muted => const Color(0xFFABABAF);

  @override
  Widget build(BuildContext context) {
    final posts = <Post>[
      Post(
        name: 'Alex_Secure',
        timeAgo: '2 hours ago',
        content:
            'Just switched to WireGuard protocol and the speed improvement is incredible! 🚀 Getting 95% of my original speed now. Highly recommend for anyone looking for better performance.',
        likes: 24,
        comments: 8,
        avatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=128',
      ),
      Post(
        name: 'PrivacyQueen',
        timeAgo: '4 hours ago',
        content:
            'PSA: Remember to enable kill switch when using public WiFi! 🛡️ It\'s saved me from potential data leaks multiple times. Stay safe out there, fellow privacy enthusiasts!',
        likes: 42,
        comments: 15,
        liked: true,
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=128',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Community',
                      style: GoogleFonts.daysOne(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40), // symmetry
                ],
              ),
            ),

            // Feed
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: posts.length,
                itemBuilder: (context, index) => PostCard(
                  post: posts[index],
                  cardColor: _card,
                  muted: _muted,
                ),
              ),
            ),

            // Composer
            Composer(bg: _bg, card: _card),
          ],
        ),
      ),
    );
  }
}

class Post {
  final String name;
  final String timeAgo;
  final String content;
  final int likes;
  final int comments;
  final bool liked;
  final String? avatarUrl;

  const Post({
    required this.name,
    required this.timeAgo,
    required this.content,
    required this.likes,
    required this.comments,
    this.liked = false,
    this.avatarUrl,
  });
}

class PostCard extends StatelessWidget {
  const PostCard({super.key, 
    required this.post,
    required this.cardColor,
    required this.muted,
  });

  final Post post;
  final Color cardColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey.shade700,
                  backgroundImage: post.avatarUrl != null
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  child: post.avatarUrl == null
                      ? Text(
                          post.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.timeAgo,
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              post.content,
              style: TextStyle(
                color: Colors.white,
                height: 1.4,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '${post.likes} likes',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${post.comments} comments',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(color: Colors.white.withOpacity(0.08), height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Action(
                    icon: post.liked ? EvaIcons.heart : EvaIcons.heartOutline,
                    label: post.liked ? 'Liked' : 'Like',
                    color: post.liked ? Colors.redAccent : Colors.white,
                  ),
                  Action(icon: EvaIcons.messageCircle, label: 'Comment'),
                  Action(icon: EvaIcons.share, label: 'Share'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Action extends StatelessWidget {
  const Action({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class Composer extends StatelessWidget {
  const Composer({super.key, required this.bg, required this.card});

  final Color bg;
  final Color card;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF252525),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  // Text input pill
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const TextField(
                        maxLines: 1,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        cursorColor: Colors.white70,
                        decoration: InputDecoration(
                          isCollapsed: true,
                          hintText: 'Share your thoughts',
                          hintStyle: TextStyle(color: Color(0xFF9A9AA0)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Separate gradient send button (outside the text field)
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFB84DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/send.png",
                        scale: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
