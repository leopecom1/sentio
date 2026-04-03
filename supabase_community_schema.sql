-- ============================================================
-- Sentio Community Schema
-- Run this in Supabase SQL Editor
-- ============================================================

-- 1. Community Posts
CREATE TABLE IF NOT EXISTS community_posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
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

CREATE INDEX idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX idx_community_posts_created_at ON community_posts(created_at DESC);
CREATE INDEX idx_community_posts_category ON community_posts(category);

-- 2. Community Likes
CREATE TABLE IF NOT EXISTS community_likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX idx_community_likes_post_id ON community_likes(post_id);
CREATE INDEX idx_community_likes_user_id ON community_likes(user_id);

-- 3. Community Comments
CREATE TABLE IF NOT EXISTS community_comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_community_comments_post_id ON community_comments(post_id);

-- 4. Community Follows
CREATE TABLE IF NOT EXISTS community_follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(follower_id, following_id)
);

CREATE INDEX idx_community_follows_follower ON community_follows(follower_id);
CREATE INDEX idx_community_follows_following ON community_follows(following_id);

-- 5. Community Stories (24h expiry)
CREATE TABLE IF NOT EXISTS community_stories (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  image_url TEXT DEFAULT '',
  text_overlay TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_community_stories_user_id ON community_stories(user_id);
CREATE INDEX idx_community_stories_expires_at ON community_stories(expires_at);

-- 6. Add community columns to profiles (if not exist)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'bio') THEN
    ALTER TABLE profiles ADD COLUMN bio TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'followers_count') THEN
    ALTER TABLE profiles ADD COLUMN followers_count INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'following_count') THEN
    ALTER TABLE profiles ADD COLUMN following_count INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'posts_count') THEN
    ALTER TABLE profiles ADD COLUMN posts_count INT DEFAULT 0;
  END IF;
END $$;

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_stories ENABLE ROW LEVEL SECURITY;

-- Posts: anyone can read visible, owner can insert/update/delete
CREATE POLICY "community_posts_select" ON community_posts FOR SELECT USING (is_visible = true);
CREATE POLICY "community_posts_insert" ON community_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "community_posts_update" ON community_posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "community_posts_delete" ON community_posts FOR DELETE USING (auth.uid() = user_id);

-- Likes: anyone can read, owner can insert/delete
CREATE POLICY "community_likes_select" ON community_likes FOR SELECT USING (true);
CREATE POLICY "community_likes_insert" ON community_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "community_likes_delete" ON community_likes FOR DELETE USING (auth.uid() = user_id);

-- Comments: anyone can read, owner can insert/delete
CREATE POLICY "community_comments_select" ON community_comments FOR SELECT USING (true);
CREATE POLICY "community_comments_insert" ON community_comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "community_comments_delete" ON community_comments FOR DELETE USING (auth.uid() = user_id);

-- Follows: anyone can read, follower can insert/delete
CREATE POLICY "community_follows_select" ON community_follows FOR SELECT USING (true);
CREATE POLICY "community_follows_insert" ON community_follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "community_follows_delete" ON community_follows FOR DELETE USING (auth.uid() = follower_id);

-- Stories: anyone can read non-expired, owner can insert/delete
CREATE POLICY "community_stories_select" ON community_stories FOR SELECT USING (expires_at > now());
CREATE POLICY "community_stories_insert" ON community_stories FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "community_stories_delete" ON community_stories FOR DELETE USING (auth.uid() = user_id);

-- ============================================================
-- Triggers: auto-update counters
-- ============================================================

-- Like count on posts
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

CREATE TRIGGER trg_community_likes_count
AFTER INSERT OR DELETE ON community_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Comment count on posts
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

CREATE TRIGGER trg_community_comments_count
AFTER INSERT OR DELETE ON community_comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Posts count on profiles
CREATE OR REPLACE FUNCTION update_profile_posts_count()
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

CREATE TRIGGER trg_profile_posts_count
AFTER INSERT OR DELETE ON community_posts
FOR EACH ROW EXECUTE FUNCTION update_profile_posts_count();

-- Followers/Following count on profiles
CREATE OR REPLACE FUNCTION update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
    UPDATE profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
    UPDATE profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_community_follow_counts
AFTER INSERT OR DELETE ON community_follows
FOR EACH ROW EXECUTE FUNCTION update_follow_counts();

-- ============================================================
-- Storage bucket for community images
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('community-images', 'community-images', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "community_images_select" ON storage.objects FOR SELECT USING (bucket_id = 'community-images');
CREATE POLICY "community_images_insert" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'community-images' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "community_images_delete" ON storage.objects FOR DELETE USING (bucket_id = 'community-images' AND auth.uid()::text = (storage.foldername(name))[1]);
