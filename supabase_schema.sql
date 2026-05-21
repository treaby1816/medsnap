-- ====================================================================
-- VAILMEDS SUPABASE MASTER SCHEMA & POSTGIS MIGRATION SCRIPT
-- For Project: https://idoqnxtohgemwngcuqrw.supabase.co
-- ====================================================================

-- Enable PostGIS extension for high-performance geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;

-- ====================================================================
-- 1. USERS TABLE (Syncs with auth.users)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('patient', 'pharmacy', 'admin')),
    phone TEXT,
    "isVerified" BOOLEAN DEFAULT false,
    "isAdminApproved" BOOLEAN DEFAULT false,
    "pharmacyName" TEXT,
    "licenseNumber" TEXT,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOMETRY(Point, 4326), -- PostGIS Point geometry (SRID 4326 for WGS 84 GPS)
    "displayName" TEXT,
    "photoUrl" TEXT,
    "bio" TEXT,
    "licensePhotoUrl" TEXT,
    "accessToken" TEXT,
    "insuranceProvider" TEXT,
    "insuranceID" TEXT,
    "healthRecords" JSONB,
    "connectedDevices" TEXT[],
    "storeName" TEXT,
    "storeFrontImageUrl" TEXT,
    "storeInsideImageUrl" TEXT,
    "npiNumber" TEXT,
    "verificationStatus" TEXT DEFAULT 'none',
    "rejectionReason" TEXT,
    "approvedBy" UUID REFERENCES public.users(id),
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

-- Index for spatial indexing on location
CREATE INDEX IF NOT EXISTS users_location_idx ON public.users USING GIST(location);
CREATE INDEX IF NOT EXISTS users_role_idx ON public.users(role, "isAdminApproved");

-- Trigger function to automatically maintain the PostGIS location geometry column
CREATE OR REPLACE FUNCTION public.update_user_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_user_location_trigger
BEFORE INSERT OR UPDATE OF latitude, longitude ON public.users
FOR EACH ROW
EXECUTE FUNCTION public.update_user_location();


-- ====================================================================
-- 2. PRODUCTS TABLE (Inventory for Pharmacies)
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.products (
    id TEXT PRIMARY KEY,
    "pharmacyId" UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    "genericName" TEXT NOT NULL,
    category TEXT NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    "requiresPrescription" BOOLEAN DEFAULT false,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS products_search_idx ON public.products(name, "genericName");
CREATE INDEX IF NOT EXISTS products_pharmacy_idx ON public.products("pharmacyId");


-- ====================================================================
-- 3. ORDERS TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.orders (
    id TEXT PRIMARY KEY,
    "patientId" UUID NOT NULL REFERENCES public.users(id),
    "pharmacyId" UUID NOT NULL REFERENCES public.users(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'dispensed', 'delivered', 'cancelled')),
    "totalAmount" DOUBLE PRECISION NOT NULL,
    "deliveryAddress" TEXT NOT NULL,
    "prescriptionUrl" TEXT,
    items JSONB NOT NULL,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS orders_patient_idx ON public.orders("patientId");
CREATE INDEX IF NOT EXISTS orders_pharmacy_idx ON public.orders("pharmacyId");


-- ====================================================================
-- 4. CHAT CONVERSATIONS & MESSAGES
-- ====================================================================
CREATE TABLE IF NOT EXISTS public.conversations (
    id TEXT PRIMARY KEY,
    "patientId" UUID NOT NULL REFERENCES public.users(id),
    "pharmacyId" UUID NOT NULL REFERENCES public.users(id),
    "lastMessage" TEXT,
    "lastMessageTime" TIMESTAMPTZ DEFAULT NOW(),
    "unreadCount" INTEGER DEFAULT 0,
    "createdAt" TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.messages (
    id TEXT PRIMARY KEY,
    "conversationId" TEXT NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    "senderId" UUID NOT NULL REFERENCES public.users(id),
    text TEXT NOT NULL,
    "timestamp" TIMESTAMPTZ DEFAULT NOW(),
    "isRead" BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS messages_conv_idx ON public.messages("conversationId", "timestamp");


-- ====================================================================
-- 5. POSTGIS RPC FUNCTION: get_nearby_pharmacies
-- Used by GeoService (ST_DWithin for ultra-fast 5km radius lookups)
-- ====================================================================
CREATE OR REPLACE FUNCTION public.get_nearby_pharmacies(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION,
    drug_search TEXT
)
RETURNS TABLE (
    id UUID,
    name TEXT,
    "pharmacyName" TEXT,
    address TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    distance_meters DOUBLE PRECISION,
    available_products JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.name,
        u."pharmacyName",
        u.address,
        u.latitude,
        u.longitude,
        ST_DistanceSphere(u.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)) AS distance_meters,
        jsonb_agg(jsonb_build_object(
            'id', p.id,
            'name', p.name,
            'genericName', p."genericName",
            'price', p.price,
            'stock', p.stock
        )) AS available_products
    FROM public.users u
    INNER JOIN public.products p ON p."pharmacyId" = u.id
    WHERE u.role = 'pharmacy'
      AND u."isVerified" = true
      AND u."isAdminApproved" = true
      AND ST_DWithin(
          u.location::geography,
          ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
          radius_km * 1000
      )
      AND (
          drug_search IS NULL 
          OR drug_search = '' 
          OR p.name ILIKE '%' || drug_search || '%'
          OR p."genericName" ILIKE '%' || drug_search || '%'
      )
      AND p.stock > 0
    GROUP BY u.id, u.name, u."pharmacyName", u.address, u.latitude, u.longitude, u.location;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ====================================================================
-- 6. ENABLE REALTIME & ROW LEVEL SECURITY (RLS)
-- ====================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.users, public.products, public.orders, public.conversations, public.messages;

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access on pharmacies" ON public.users FOR SELECT USING (true);
CREATE POLICY "Allow users to update their own profile" ON public.users FOR ALL USING (auth.uid() = id);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public read access on products" ON public.products FOR SELECT USING (true);
CREATE POLICY "Allow pharmacies to manage their products" ON public.products FOR ALL USING (auth.uid() = "pharmacyId");

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow users to see their own orders" ON public.orders FOR SELECT USING (auth.uid() = "patientId" OR auth.uid() = "pharmacyId");
CREATE POLICY "Allow order creation" ON public.orders FOR INSERT WITH CHECK (auth.uid() = "patientId");


-- ====================================================================
-- 7. STORAGE BUCKET SETUP
-- ====================================================================
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('prescriptions', 'prescriptions', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('licenses', 'licenses', false) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('pharmacy_products', 'pharmacy_products', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('pharmacy_images', 'pharmacy_images', true) ON CONFLICT (id) DO NOTHING;
