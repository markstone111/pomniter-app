-- Pomniter Schema Initialization
-- Architecture: Local-first with optional cloud sync and multi-device replication

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Screenshots
CREATE TABLE IF NOT EXISTS screenshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    file_path VARCHAR(512) NOT NULL,
    s3_key VARCHAR(512),
    thumbnail_key VARCHAR(512),
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    category VARCHAR(50) DEFAULT 'other',
    extracted_text TEXT,
    summary TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    is_archived BOOLEAN DEFAULT FALSE,
    captured_at TIMESTAMP WITH TIME ZONE NOT NULL,
    indexed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Text Blocks
CREATE TABLE IF NOT EXISTS text_blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    screenshot_id UUID REFERENCES screenshots(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    confidence REAL NOT NULL,
    box_left REAL,
    box_top REAL,
    box_width REAL,
    box_height REAL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Screenshot Tags
CREATE TABLE IF NOT EXISTS screenshot_tags (
    screenshot_id UUID REFERENCES screenshots(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    PRIMARY KEY (screenshot_id, tag)
);

-- Search Query Logs (Telemetry)
CREATE TABLE IF NOT EXISTS search_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    query_text TEXT NOT NULL,
    results_count INTEGER NOT NULL,
    execution_time_ms REAL NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indices for rapid query performance
CREATE INDEX IF NOT EXISTS idx_screenshots_user_captured ON screenshots(user_id, captured_at DESC);
CREATE INDEX IF NOT EXISTS idx_screenshots_category ON screenshots(category);
CREATE INDEX IF NOT EXISTS idx_text_blocks_screenshot ON text_blocks(screenshot_id);
CREATE INDEX IF NOT EXISTS idx_tags_tag ON screenshot_tags(tag);
