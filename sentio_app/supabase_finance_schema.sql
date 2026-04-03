-- ============================================================
-- Sentio Finance Module Schema
-- Execute in Supabase SQL Editor
-- ============================================================

-- Financial Accounts
CREATE TABLE IF NOT EXISTS financial_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  account_type TEXT NOT NULL DEFAULT 'cash', -- bank, credit_card, cash, wallet, investment
  currency TEXT NOT NULL DEFAULT 'ARS',
  balance DECIMAL(15,2) DEFAULT 0,
  icon TEXT DEFAULT 'account_balance_wallet',
  color TEXT DEFAULT '#3D5A80',
  is_active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Financial Transactions
CREATE TABLE IF NOT EXISTS financial_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES financial_accounts(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'expense', -- income, expense, transfer
  amount DECIMAL(15,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'ARS',
  category TEXT NOT NULL DEFAULT 'otros',
  description TEXT,
  receipt_image_url TEXT,
  is_from_scan BOOLEAN DEFAULT false,
  emotional_context TEXT, -- last check-in emotion at time of transaction
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add finance columns to profiles (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='total_transactions') THEN
    ALTER TABLE profiles ADD COLUMN total_transactions INT DEFAULT 0;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='profiles' AND column_name='preferred_currency') THEN
    ALTER TABLE profiles ADD COLUMN preferred_currency TEXT DEFAULT 'ARS';
  END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_financial_accounts_user ON financial_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_user ON financial_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_account ON financial_transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_date ON financial_transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_financial_transactions_type ON financial_transactions(type);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE financial_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_transactions ENABLE ROW LEVEL SECURITY;

-- Accounts: CRUD own only
CREATE POLICY "Users read own accounts" ON financial_accounts
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users create own accounts" ON financial_accounts
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own accounts" ON financial_accounts
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users delete own accounts" ON financial_accounts
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Transactions: CRUD own only
CREATE POLICY "Users read own transactions" ON financial_transactions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users create own transactions" ON financial_transactions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own transactions" ON financial_transactions
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "Users delete own transactions" ON financial_transactions
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ============================================================
-- Triggers
-- ============================================================

-- Auto-recalculate account balance on transaction insert/delete
CREATE OR REPLACE FUNCTION update_account_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.type = 'income' THEN
      UPDATE financial_accounts SET balance = balance + NEW.amount, updated_at = now() WHERE id = NEW.account_id;
    ELSIF NEW.type = 'expense' THEN
      UPDATE financial_accounts SET balance = balance - NEW.amount, updated_at = now() WHERE id = NEW.account_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.type = 'income' THEN
      UPDATE financial_accounts SET balance = balance - OLD.amount, updated_at = now() WHERE id = OLD.account_id;
    ELSIF OLD.type = 'expense' THEN
      UPDATE financial_accounts SET balance = balance + OLD.amount, updated_at = now() WHERE id = OLD.account_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_account_balance ON financial_transactions;
CREATE TRIGGER trg_update_account_balance
  AFTER INSERT OR DELETE ON financial_transactions
  FOR EACH ROW EXECUTE FUNCTION update_account_balance();

-- Auto-increment total_transactions on profiles
CREATE OR REPLACE FUNCTION update_user_transactions_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE profiles SET total_transactions = COALESCE(total_transactions, 0) + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE profiles SET total_transactions = GREATEST(COALESCE(total_transactions, 0) - 1, 0) WHERE id = OLD.user_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_user_transactions_count ON financial_transactions;
CREATE TRIGGER trg_user_transactions_count
  AFTER INSERT OR DELETE ON financial_transactions
  FOR EACH ROW EXECUTE FUNCTION update_user_transactions_count();

-- ============================================================
-- Storage bucket for receipt images
-- ============================================================
-- Run in Supabase Dashboard > Storage:
-- Create bucket: receipt-images
-- Public: true
-- File size limit: 5MB
-- Allowed MIME types: image/jpeg, image/png, image/webp
