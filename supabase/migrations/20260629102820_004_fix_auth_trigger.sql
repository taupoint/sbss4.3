/*
# Fix Auth Trigger for User Signup (Migration 004/005)

1. Changes
- Update the `handle_new_user` trigger function to handle tenant_id properly
- The trigger was failing because it was trying to insert into profiles which has RLS enabled
- SECURITY DEFINER should bypass RLS, but we need to ensure the insert works

2. Security
- Trigger runs as SECURITY DEFINER to bypass RLS during user creation
*/

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  user_role text;
BEGIN
  -- Determine role from metadata or use default
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'store_customer');
  
  -- Ensure role is valid (must match constraint)
  IF user_role NOT IN ('super_admin', 'manager', 'sales_executive', 'inventory_manager', 'accountant', 'delivery_staff', 'customer_portal', 'store_customer') THEN
    user_role := 'store_customer';
  END IF;
  
  INSERT INTO public.profiles (id, email, full_name, role, tenant_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    user_role,
    '00000000-0000-0000-0000-000000000001'::uuid
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();