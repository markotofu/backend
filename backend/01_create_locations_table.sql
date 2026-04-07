-- Create locations table for map feature
CREATE TABLE IF NOT EXISTS public.locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    address TEXT,
    category VARCHAR(100),
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create index for user_id for faster queries
CREATE INDEX IF NOT EXISTS idx_locations_user_id ON public.locations(user_id);

-- Create index for geographic queries
CREATE INDEX IF NOT EXISTS idx_locations_coordinates ON public.locations(latitude, longitude);

-- Enable Row Level Security (RLS)
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can view all locations
CREATE POLICY "Anyone can view locations" ON public.locations
    FOR SELECT USING (true);

-- Create policy: Users can insert their own locations
CREATE POLICY "Users can insert their own locations" ON public.locations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can update their own locations
CREATE POLICY "Users can update their own locations" ON public.locations
    FOR UPDATE USING (auth.uid() = user_id);

-- Create policy: Users can delete their own locations
CREATE POLICY "Users can delete their own locations" ON public.locations
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_locations_updated_at BEFORE UPDATE ON public.locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
