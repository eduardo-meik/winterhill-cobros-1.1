/*
  # Fix Fee Table Structure

  1. Changes
    - Drop and recreate fee table with proper foreign key relationships
    - Add proper indexes and constraints
    - Ensure proper data handling

  2. Security
    - Maintain RLS policies
    - Ensure proper access control
*/

-- Drop existing table if it exists
DROP TABLE IF EXISTS fee;

-- Create new fee table
CREATE TABLE fee (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  student_id uuid REFERENCES students(id) ON DELETE CASCADE NOT NULL,
  guardian_id uuid REFERENCES guardians(id) ON DELETE SET NULL,
  amount decimal(10,2) NOT NULL,
  due_date date NOT NULL DEFAULT CURRENT_DATE,
  payment_date date,
  status text CHECK (status IN ('paid', 'pending', 'overdue')) DEFAULT 'pending',
  payment_method text CHECK (payment_method IN ('efectivo', 'transferencia', 'tarjeta', 'cheque')),
  num_boleta text,
  mov_bancario text,
  notes text,
  owner_id uuid REFERENCES auth.users(id) NOT NULL
);

-- Enable RLS
ALTER TABLE fee ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view all fees"
  ON fee FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert their own fees"
  ON fee FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own fees"
  ON fee FOR UPDATE
  TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own fees"
  ON fee FOR DELETE
  TO authenticated
  USING (auth.uid() = owner_id);

-- Create indexes
CREATE INDEX idx_fee_student_id ON fee(student_id);
CREATE INDEX idx_fee_guardian_id ON fee(guardian_id);
CREATE INDEX idx_fee_due_date ON fee(due_date);
CREATE INDEX idx_fee_status ON fee(status);
CREATE INDEX idx_fee_owner_id ON fee(owner_id);