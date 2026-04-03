-- ============================================================
-- Sentio Community Schema
-- Execute in Supabase SQL Editor
-- ============================================================

-- Community Posts
CREATE TABLE IF NOT EXISTS community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_urls TEXT[] DEFAULT '{}',
  emotion TEXT,
  category TEXT DEFAULT 'general',
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Community Comments
CREATE TABLE IF NOT EXISTS community_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Community Likes (unique per user per post)
CREATE TABLE IF NOT EXISTS community_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(post_id, user_id)
);

-- Community Follows
CREATE TABLE IF NOT EXISTS community_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(follower_id, following_id),
  CHECK(follower_id != following_id)
);

-- Community Stories (24h expiry)
CREATE TABLE IF NOT EXISTS community_stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  text_overlay TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '24 hours')
);

-- Add community columns to profiles (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='bio') THEN
    ALTER TABLE profiles ADD COLUMN bio TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='posts_count') THEN
    ALTER TABLE profiles ADD COLUMN posts_count INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='followers_count') THEN
    ALTER TABLE profiles ADD COLUMN followers_count INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='following_count') THEN
    ALTER TABLE profiles ADD COLUMN following_count INT DEFAULT 0;
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_community_posts_user ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_created ON community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_comments_post ON community_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_community_likes_post ON community_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_community_likes_user ON community_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_community_follows_follower ON community_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_community_follows_following ON community_follows(following_id);
CREATE INDEX IF NOT EXISTS idx_community_stories_user ON community_stories(user_id);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_stories ENABLE ROW LEVEL SECURITY;

-- Posts: authenticated users can read visible posts, create own, update/delete own
CREATE POLICY "Posts visible to authenticated" ON community_posts
  FOR SELECT TO authenticated USING (is_visible = true);
CREATE POLICY "Users create own posts" ON community_posts
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own posts" ON community_posts
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users delete own posts" ON community_posts
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Comments: read all, create/delete own
CREATE POLICY "Comments readable by authenticated" ON community_comments
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users create own comments" ON community_comments
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own comments" ON community_comments
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Likes: read all, create/delete own
CREATE POLICY "Likes readable by authenticated" ON community_likes
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users create own likes" ON community_likes
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own likes" ON community_likes
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Follows: read all, create/delete own
CREATE POLICY "Follows readable by authenticated" ON community_follows
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users create own follows" ON community_follows
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users delete own follows" ON community_follows
  FOR DELETE TO authenticated USING (auth.uid() = follower_id);

-- Stories: read non-expired, create own
CREATE POLICY "Stories readable by authenticated" ON community_stories
  FOR SELECT TO authenticated USING (expires_at > now());
CREATE POLICY "Users create own stories" ON community_stories
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own stories" ON community_stories
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ============================================================
-- Triggers for denormalized counts
-- ============================================================

-- Auto-increment likes_count on community_posts
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_community_likes_count ON community_likes;
CREATE TRIGGER trg_community_likes_count
  AFTER INSERT OR DELETE ON community_likes
  FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Auto-increment comments_count on community_posts
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_community_comments_count ON community_comments;
CREATE TRIGGER trg_community_comments_count
  AFTER INSERT OR DELETE ON community_comments
  FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Auto-increment followers/following count on profiles
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_community_follow_counts ON community_follows;
CREATE TRIGGER trg_community_follow_counts
  AFTER INSERT OR DELETE ON community_follows
  FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- Auto-increment posts_count on profiles
CREATE OR REPLACE FUNCTION update_user_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET posts_count = GREATEST(posts_count - 1, 0) WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_community_posts_count ON community_posts;
CREATE TRIGGER trg_community_posts_count
  AFTER INSERT OR DELETE ON community_posts
  FOR EACH ROW EXECUTE FUNCTION update_user_posts_count();

-- ============================================================
-- Storage bucket for community images
-- ============================================================
-- Run in Supabase Dashboard > Storage:
-- Create bucket: community-images
-- Public: true
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp
