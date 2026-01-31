-- Daily Vaibe Production Schema
-- Generated: 2026-01-25T20:10:42.375Z
-- Optimized for Render PostgreSQL

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- PostgreSQL Extensions
-- Required extensions for Daily Vaibe

CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- Custom ENUM Types

CREATE TYPE public.admin_role AS ENUM ('super_admin', 'admin', 'editor', 'moderator');

CREATE TYPE public.attendance_status AS ENUM ('registered', 'attended', 'cancelled', 'no_show');

CREATE TYPE public.availability_type AS ENUM ('weekdays', 'weekends', 'both', 'flexible');

CREATE TYPE public.breaking_priority AS ENUM ('low', 'medium', 'high', 'urgent');

CREATE TYPE public.comment_status AS ENUM ('pending', 'approved', 'rejected', 'spam');

CREATE TYPE public.donation_status AS ENUM ('pending', 'completed', 'failed', 'refunded');

CREATE TYPE public.media_type AS ENUM ('image', 'video', 'document');

CREATE TYPE public.news_status AS ENUM ('draft', 'published', 'archived', 'pending');

CREATE TYPE public.notification_priority AS ENUM ('low', 'medium', 'high', 'urgent');

CREATE TYPE public.notification_type AS ENUM ('new_user', 'new_comment', 'content_report', 'system_alert', 'breaking_news', 'donation_received');

CREATE TYPE public.payment_method AS ENUM ('mpesa', 'card', 'paypal', 'bank');

CREATE TYPE public.pin_type_enum AS ENUM ('gold', 'silver', 'bronze');

CREATE TYPE public.reaction_type AS ENUM ('like');

CREATE TYPE public.referral_status AS ENUM ('pending', 'completed', 'expired');

CREATE TYPE public.share_platform AS ENUM ('facebook', 'twitter', 'linkedin', 'whatsapp', 'telegram', 'email', 'copy');

CREATE TYPE public.subscriber_status AS ENUM ('active', 'inactive', 'pending');

CREATE TYPE public.target_type AS ENUM ('news', 'user', 'comment', 'category', 'system', 'settings');

CREATE TYPE public.user_status AS ENUM ('active', 'suspended', 'deactivated');

CREATE TYPE public.video_status AS ENUM ('draft', 'scheduled', 'live', 'ended', 'published', 'archived');

CREATE TYPE public.video_visibility AS ENUM ('public', 'unlisted', 'private');

CREATE TYPE public.volunteer_status AS ENUM ('active', 'inactive', 'pending');

-- Database Functions

CREATE OR REPLACE FUNCTION public.archive_cookie_stats_monthly()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    archived_count INTEGER := 0;
BEGIN
    INSERT INTO cookie_stats_monthly (
        year, month, county, category,
        total_consents, accepted_count, rejected_count, avg_acceptance_rate
    )
    SELECT 
        EXTRACT(YEAR FROM stat_date)::INTEGER,
        EXTRACT(MONTH FROM stat_date)::INTEGER,
        county,
        category,
        SUM(total_consents),
        SUM(accepted_count),
        SUM(rejected_count),
        CASE 
            WHEN SUM(total_consents) > 0 
            THEN ROUND((SUM(accepted_count)::DECIMAL / SUM(total_consents)::DECIMAL) * 100, 2)
            ELSE 0 
        END
    FROM cookie_stats_daily
    WHERE stat_date < CURRENT_DATE - INTERVAL '60 days'
    GROUP BY EXTRACT(YEAR FROM stat_date), EXTRACT(MONTH FROM stat_date), county, category
    ON CONFLICT (year, month, county, category) 
    DO UPDATE SET
        total_consents = EXCLUDED.total_consents,
        accepted_count = EXCLUDED.accepted_count,
        rejected_count = EXCLUDED.rejected_count,
        avg_acceptance_rate = EXCLUDED.avg_acceptance_rate;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    DELETE FROM cookie_stats_daily WHERE stat_date < CURRENT_DATE - INTERVAL '60 days';
    
    RETURN archived_count;
END;
$function$


CREATE OR REPLACE FUNCTION public.archive_daily_stats()
 RETURNS TABLE(archived_count integer)
 LANGUAGE plpgsql
AS $function$
      DECLARE
        v_archived INTEGER := 0;
      BEGIN
        INSERT INTO monthly_location_summary (
          year, month, county, town, category,
          total_devices, unique_devices, avg_daily_devices, peak_daily_devices
        )
        SELECT 
          EXTRACT(YEAR FROM stat_date)::INTEGER,
          EXTRACT(MONTH FROM stat_date)::INTEGER,
          county, town, category,
          SUM(total_devices),
          COUNT(DISTINCT stat_date),
          ROUND(AVG(total_devices))::INTEGER,
          MAX(total_devices)
        FROM daily_location_stats
        WHERE stat_date < CURRENT_DATE - INTERVAL '60 days'
        GROUP BY EXTRACT(YEAR FROM stat_date), EXTRACT(MONTH FROM stat_date), county, town, category
        ON CONFLICT (year, month, county, town, category) 
        DO UPDATE SET
          total_devices = EXCLUDED.total_devices,
          unique_devices = EXCLUDED.unique_devices,
          avg_daily_devices = EXCLUDED.avg_daily_devices,
          peak_daily_devices = EXCLUDED.peak_daily_devices;
        
        GET DIAGNOSTICS v_archived = ROW_COUNT;
        
        DELETE FROM daily_location_stats WHERE stat_date < CURRENT_DATE - INTERVAL '60 days';
        
        RETURN QUERY SELECT v_archived;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.auto_end_expired_live()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
      DECLARE
        ended_count INTEGER := 0;
      BEGIN
        UPDATE public.social_videos
        SET 
          status = 'ended',
          is_live = FALSE,
          live_ended_at = CURRENT_TIMESTAMP
        WHERE 
          is_live = TRUE
          AND status = 'live'
          AND live_started_at < CURRENT_TIMESTAMP - INTERVAL '24 hours';
        
        GET DIAGNOSTICS ended_count = ROW_COUNT;
        
        UPDATE public.live_broadcast_sessions
        SET session_ended_at = CURRENT_TIMESTAMP
        WHERE session_ended_at IS NULL
        AND session_started_at < CURRENT_TIMESTAMP - INTERVAL '24 hours';
        
        RETURN ended_count;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.cleanup_old_devices()
 RETURNS TABLE(deleted_count integer)
 LANGUAGE plpgsql
AS $function$
      DECLARE
        v_deleted INTEGER;
      BEGIN
        DELETE FROM device_registry WHERE last_seen < NOW() - INTERVAL '90 days';
        GET DIAGNOSTICS v_deleted = ROW_COUNT;
        RETURN QUERY SELECT v_deleted;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.generate_oembed_url()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        IF NEW.post_url IS NOT NULL AND NEW.oembed_url IS NULL THEN
          IF NEW.platform LIKE 'facebook%' THEN
            NEW.oembed_url := 'https://www.facebook.com/plugins/post/oembed.json/?url=' || NEW.post_url;
          ELSIF NEW.platform LIKE 'twitter%' OR NEW.platform LIKE 'x_%' THEN
            NEW.oembed_url := 'https://publish.twitter.com/oembed?url=' || NEW.post_url;
          ELSIF NEW.platform LIKE 'instagram%' THEN
            NEW.oembed_url := 'https://api.instagram.com/oembed/?url=' || NEW.post_url;
          ELSIF NEW.platform LIKE 'tiktok%' THEN
            NEW.oembed_url := 'https://www.tiktok.com/oembed?url=' || NEW.post_url;
          ELSIF NEW.platform LIKE 'youtube%' THEN
            NEW.oembed_url := 'https://www.youtube.com/oembed?url=' || NEW.post_url || '&format=json';
          END IF;
        END IF;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.get_promotion_stats()
 RETURNS TABLE(featured_count bigint, breaking_count bigint, pinned_count bigint)
 LANGUAGE plpgsql
AS $function$
      BEGIN
        RETURN QUERY
        SELECT 
          (SELECT COUNT(*) FROM featured_news WHERE manually_removed = false 
           AND (ends_at IS NULL OR ends_at > NOW())) as featured_count,
          (SELECT COUNT(*) FROM breaking_news WHERE manually_removed = false 
           AND (ends_at IS NULL OR ends_at > NOW())) as breaking_count,
          (SELECT COUNT(*) FROM pinned_news WHERE manually_removed = false 
           AND (ends_at IS NULL OR ends_at > NOW())) as pinned_count;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_extract_query_trgm$function$


CREATE OR REPLACE FUNCTION public.gin_extract_value_trgm(text, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_extract_value_trgm$function$


CREATE OR REPLACE FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_trgm_consistent$function$


CREATE OR REPLACE FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal)
 RETURNS "char"
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gin_trgm_triconsistent$function$


CREATE OR REPLACE FUNCTION public.gtrgm_compress(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_compress$function$


CREATE OR REPLACE FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal)
 RETURNS boolean
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_consistent$function$


CREATE OR REPLACE FUNCTION public.gtrgm_decompress(internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_decompress$function$


CREATE OR REPLACE FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal)
 RETURNS double precision
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_distance$function$


CREATE OR REPLACE FUNCTION public.gtrgm_in(cstring)
 RETURNS gtrgm
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_in$function$


CREATE OR REPLACE FUNCTION public.gtrgm_options(internal)
 RETURNS void
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE
AS '$libdir/pg_trgm', $function$gtrgm_options$function$


CREATE OR REPLACE FUNCTION public.gtrgm_out(gtrgm)
 RETURNS cstring
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_out$function$


CREATE OR REPLACE FUNCTION public.gtrgm_penalty(internal, internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_penalty$function$


CREATE OR REPLACE FUNCTION public.gtrgm_picksplit(internal, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_picksplit$function$


CREATE OR REPLACE FUNCTION public.gtrgm_same(gtrgm, gtrgm, internal)
 RETURNS internal
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_same$function$


CREATE OR REPLACE FUNCTION public.gtrgm_union(internal, internal)
 RETURNS gtrgm
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$gtrgm_union$function$


CREATE OR REPLACE FUNCTION public.reset_daily_counts()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
      BEGIN
        UPDATE active_location_counts SET active_today = 0 WHERE last_updated < CURRENT_DATE;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.set_limit(real)
 RETURNS real
 LANGUAGE c
 STRICT
AS '$libdir/pg_trgm', $function$set_limit$function$


CREATE OR REPLACE FUNCTION public.show_limit()
 RETURNS real
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$show_limit$function$


CREATE OR REPLACE FUNCTION public.show_trgm(text)
 RETURNS text[]
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$show_trgm$function$


CREATE OR REPLACE FUNCTION public.similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity$function$


CREATE OR REPLACE FUNCTION public.similarity_dist(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity_dist$function$


CREATE OR REPLACE FUNCTION public.similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$similarity_op$function$


CREATE OR REPLACE FUNCTION public.strict_word_similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity$function$


CREATE OR REPLACE FUNCTION public.strict_word_similarity_commutator_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_commutator_op$function$


CREATE OR REPLACE FUNCTION public.strict_word_similarity_dist_commutator_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_dist_commutator_op$function$


CREATE OR REPLACE FUNCTION public.strict_word_similarity_dist_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_dist_op$function$


CREATE OR REPLACE FUNCTION public.strict_word_similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$strict_word_similarity_op$function$


CREATE OR REPLACE FUNCTION public.update_cookie_stats_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.update_mpesa_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.update_news_quotes_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.update_social_media_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.update_social_videos_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.update_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $function$


CREATE OR REPLACE FUNCTION public.uuid_generate_v1()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1$function$


CREATE OR REPLACE FUNCTION public.uuid_generate_v1mc()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v1mc$function$


CREATE OR REPLACE FUNCTION public.uuid_generate_v3(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v3$function$


CREATE OR REPLACE FUNCTION public.uuid_generate_v4()
 RETURNS uuid
 LANGUAGE c
 PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v4$function$


CREATE OR REPLACE FUNCTION public.uuid_generate_v5(namespace uuid, name text)
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_generate_v5$function$


CREATE OR REPLACE FUNCTION public.uuid_nil()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_nil$function$


CREATE OR REPLACE FUNCTION public.uuid_ns_dns()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_dns$function$


CREATE OR REPLACE FUNCTION public.uuid_ns_oid()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_oid$function$


CREATE OR REPLACE FUNCTION public.uuid_ns_url()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_url$function$


CREATE OR REPLACE FUNCTION public.uuid_ns_x500()
 RETURNS uuid
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/uuid-ossp', $function$uuid_ns_x500$function$


CREATE OR REPLACE FUNCTION public.word_similarity(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity$function$


CREATE OR REPLACE FUNCTION public.word_similarity_commutator_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_commutator_op$function$


CREATE OR REPLACE FUNCTION public.word_similarity_dist_commutator_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_dist_commutator_op$function$


CREATE OR REPLACE FUNCTION public.word_similarity_dist_op(text, text)
 RETURNS real
 LANGUAGE c
 IMMUTABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_dist_op$function$


CREATE OR REPLACE FUNCTION public.word_similarity_op(text, text)
 RETURNS boolean
 LANGUAGE c
 STABLE PARALLEL SAFE STRICT
AS '$libdir/pg_trgm', $function$word_similarity_op$function$


-- Database Tables
-- Clean schema for production deployment

CREATE TABLE public.active_location_counts (
    location_id INTEGER DEFAULT nextval('active_location_counts_location_id_seq') NOT NULL,
    county CHARACTER VARYING(255),
    town CHARACTER VARYING(255),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    active_now INTEGER DEFAULT 0,
    active_today INTEGER DEFAULT 0,
    total_registered INTEGER DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT active_counts_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text]))),
    CONSTRAINT active_location_counts_pkey PRIMARY KEY (location_id),
    CONSTRAINT active_location_counts_county_town_category_key UNIQUE (county, town, category)
);

CREATE TABLE public.activity_log (
    activity_id INTEGER DEFAULT nextval('activity_log_activity_id_seq') NOT NULL,
    user_id INTEGER,
    admin_id INTEGER,
    action CHARACTER VARYING(255) NOT NULL,
    details TEXT,
    ip_address INET,
    user_agent CHARACTER VARYING(255),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT activity_log_pkey PRIMARY KEY (activity_id)
);

CREATE TABLE public.ad_clicks (
    click_id INTEGER DEFAULT nextval('ad_clicks_click_id_seq') NOT NULL,
    ad_id INTEGER NOT NULL,
    session_id CHARACTER VARYING(255),
    county CHARACTER VARYING(100),
    town CHARACTER VARYING(100),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT ad_clicks_pkey PRIMARY KEY (click_id)
);

CREATE TABLE public.ad_impressions (
    impression_id INTEGER DEFAULT nextval('ad_impressions_impression_id_seq') NOT NULL,
    ad_id INTEGER NOT NULL,
    session_id CHARACTER VARYING(255),
    county CHARACTER VARYING(100),
    town CHARACTER VARYING(100),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT ad_impressions_pkey PRIMARY KEY (impression_id)
);

CREATE TABLE public.ad_survey_questions (
    question_id INTEGER NOT NULL,
    survey_id INTEGER NOT NULL,
    question TEXT NOT NULL,
    question_type CHARACTER VARYING(20),
    options JSONB DEFAULT '{}'::jsonb,
    required BOOLEAN DEFAULT false,
    order_index INTEGER,
    CONSTRAINT ad_survey_questions_question_type_check CHECK (((question_type)::text = ANY (ARRAY[('text'::character varying)::text, ('radio'::character varying)::text, ('checkbox'::character varying)::text, ('rating'::character varying)::text]))),
    CONSTRAINT ad_survey_questions_pkey PRIMARY KEY (question_id)
);

CREATE TABLE public.ad_survey_responses (
    response_id INTEGER NOT NULL,
    survey_id INTEGER NOT NULL,
    user_id INTEGER,
    ip_address CHARACTER VARYING(64),
    responses JSONB DEFAULT '{}'::jsonb,
    submitted_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ad_survey_responses_pkey PRIMARY KEY (response_id)
);

CREATE TABLE public.ad_surveys (
    survey_id INTEGER NOT NULL,
    client_name CHARACTER VARYING(255),
    campaign_name CHARACTER VARYING(255),
    survey_title CHARACTER VARYING(255),
    survey_description TEXT,
    target_url CHARACTER VARYING(512),
    status CHARACTER VARYING(20) DEFAULT 'draft'::character varying,
    starts_at TIMESTAMP WITHOUT TIME ZONE,
    ends_at TIMESTAMP WITHOUT TIME ZONE,
    budget NUMERIC,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ad_surveys_status_check CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('active'::character varying)::text, ('paused'::character varying)::text, ('completed'::character varying)::text]))),
    CONSTRAINT ad_surveys_pkey PRIMARY KEY (survey_id)
);

CREATE TABLE public.ad_tiers (
    tier_id INTEGER DEFAULT nextval('ad_tiers_tier_id_seq') NOT NULL,
    tier_name CHARACTER VARYING(50) NOT NULL,
    price_per_month NUMERIC NOT NULL,
    price_per_year NUMERIC NOT NULL,
    max_ads INTEGER NOT NULL,
    priority_level INTEGER NOT NULL,
    features JSONB DEFAULT '{}'::jsonb,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT ad_tiers_pkey PRIMARY KEY (tier_id),
    CONSTRAINT ad_tiers_tier_name_key UNIQUE (tier_name)
);

CREATE TABLE public.admin_activity_log (
    log_id INTEGER DEFAULT nextval('admin_activity_log_log_id_seq') NOT NULL,
    admin_id INTEGER NOT NULL,
    action CHARACTER VARYING(100) NOT NULL,
    target_type public.target_type NOT NULL,
    target_id INTEGER,
    details TEXT,
    ip_address INET,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admin_activity_log_pkey PRIMARY KEY (log_id)
);

CREATE TABLE public.admin_chat_messages (
    message_id INTEGER DEFAULT nextval('admin_chat_messages_message_id_seq') NOT NULL,
    sender_id INTEGER NOT NULL,
    sender_name CHARACTER VARYING(200) NOT NULL,
    receiver_id INTEGER,
    message_text TEXT NOT NULL,
    is_broadcast BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admin_chat_messages_pkey PRIMARY KEY (message_id)
);

CREATE TABLE public.admin_notifications (
    notification_id INTEGER DEFAULT nextval('admin_notifications_notification_id_seq') NOT NULL,
    admin_id INTEGER,
    type public.notification_type NOT NULL,
    title CHARACTER VARYING(200) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    priority public.notification_priority DEFAULT 'medium'::notification_priority,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admin_notifications_pkey PRIMARY KEY (notification_id)
);

CREATE TABLE public.admin_online_status (
    admin_id INTEGER NOT NULL,
    last_active TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_online BOOLEAN DEFAULT true,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admin_online_status_pkey PRIMARY KEY (admin_id)
);

CREATE TABLE public.admin_permissions (
    permission_id INTEGER DEFAULT nextval('admin_permissions_permission_id_seq') NOT NULL,
    admin_id INTEGER NOT NULL,
    permission_name CHARACTER VARYING(100) NOT NULL,
    resource_type CHARACTER VARYING(50),
    can_create BOOLEAN DEFAULT false,
    can_read BOOLEAN DEFAULT true,
    can_update BOOLEAN DEFAULT false,
    can_delete BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admin_permissions_pkey PRIMARY KEY (permission_id),
    CONSTRAINT admin_permissions_admin_id_permission_name_resource_type_key UNIQUE (admin_id, permission_name, resource_type)
);

CREATE TABLE public.admins (
    admin_id INTEGER DEFAULT nextval('admins_admin_id_seq') NOT NULL,
    first_name CHARACTER VARYING(100) NOT NULL,
    last_name CHARACTER VARYING(100) NOT NULL,
    email CHARACTER VARYING(150) NOT NULL,
    phone CHARACTER VARYING(20) NOT NULL,
    username CHARACTER VARYING(50),
    role public.admin_role DEFAULT 'admin'::admin_role,
    password_hash CHARACTER VARYING(255) NOT NULL,
    permissions JSONB DEFAULT '{}'::jsonb,
    last_login TIMESTAMP WITHOUT TIME ZONE,
    status public.user_status DEFAULT 'active'::user_status,
    role_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT admins_pkey PRIMARY KEY (admin_id),
    CONSTRAINT admins_email_key UNIQUE (email),
    CONSTRAINT admins_phone_key UNIQUE (phone),
    CONSTRAINT admins_username_key UNIQUE (username)
);

CREATE TABLE public.advertisements (
    ad_id INTEGER DEFAULT nextval('advertisements_ad_id_seq') NOT NULL,
    advertiser_id INTEGER NOT NULL,
    title CHARACTER VARYING(200) NOT NULL,
    description TEXT,
    image_url CHARACTER VARYING(500),
    link_url CHARACTER VARYING(500),
    target_counties varchar[],
    target_towns varchar[],
    placement CHARACTER VARYING(50) NOT NULL,
    priority INTEGER DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    status CHARACTER VARYING(20) DEFAULT 'active'::character varying,
    start_date TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    end_date TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT advertisements_placement_check CHECK (((placement)::text = ANY (ARRAY[('banner'::character varying)::text, ('sidebar'::character varying)::text, ('inline'::character varying)::text, ('popup'::character varying)::text, ('floating'::character varying)::text]))),
    CONSTRAINT advertisements_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('paused'::character varying)::text, ('expired'::character varying)::text, ('rejected'::character varying)::text]))),
    CONSTRAINT advertisements_pkey PRIMARY KEY (ad_id)
);

CREATE TABLE public.advertisers (
    advertiser_id INTEGER DEFAULT nextval('advertisers_advertiser_id_seq') NOT NULL,
    company_name CHARACTER VARYING(200) NOT NULL,
    contact_person CHARACTER VARYING(200) NOT NULL,
    email CHARACTER VARYING(150) NOT NULL,
    phone CHARACTER VARYING(20) NOT NULL,
    county CHARACTER VARYING(100),
    town CHARACTER VARYING(100),
    address TEXT,
    tier_id INTEGER,
    subscription_start TIMESTAMP WITHOUT TIME ZONE,
    subscription_end TIMESTAMP WITHOUT TIME ZONE,
    auto_renew BOOLEAN DEFAULT false,
    status CHARACTER VARYING(20) DEFAULT 'active'::character varying,
    total_spent NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    CONSTRAINT advertisers_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('suspended'::character varying)::text, ('expired'::character varying)::text]))),
    CONSTRAINT advertisers_pkey PRIMARY KEY (advertiser_id),
    CONSTRAINT advertisers_email_key UNIQUE (email)
);

CREATE TABLE public.analytics_daily (
    analytics_id INTEGER DEFAULT nextval('analytics_daily_analytics_id_seq') NOT NULL,
    date DATE NOT NULL,
    total_views INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    total_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    total_news INTEGER DEFAULT 0,
    published_news INTEGER DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT analytics_daily_pkey PRIMARY KEY (analytics_id),
    CONSTRAINT analytics_daily_date_key UNIQUE (date)
);

CREATE TABLE public.analytics_monthly (
    analytics_id INTEGER DEFAULT nextval('analytics_monthly_analytics_id_seq') NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    total_views INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    total_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    total_news INTEGER DEFAULT 0,
    published_news INTEGER DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT analytics_monthly_pkey PRIMARY KEY (analytics_id),
    CONSTRAINT analytics_monthly_year_month_key UNIQUE (year, month)
);

CREATE TABLE public.bookmarks (
    bookmark_id INTEGER DEFAULT nextval('bookmarks_bookmark_id_seq') NOT NULL,
    user_id INTEGER NOT NULL,
    news_id INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bookmarks_pkey PRIMARY KEY (bookmark_id),
    CONSTRAINT bookmarks_user_id_news_id_key UNIQUE (user_id, news_id)
);

CREATE TABLE public.breaking_news (
    breaking_id INTEGER DEFAULT nextval('breaking_news_breaking_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    priority CHARACTER VARYING(10) NOT NULL,
    starts_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITHOUT TIME ZONE,
    activated_by INTEGER,
    manually_removed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT breaking_news_priority_check CHECK (((priority)::text = ANY ((ARRAY['high'::character varying, 'medium'::character varying, 'low'::character varying])::text[]))),
    CONSTRAINT breaking_news_pkey PRIMARY KEY (breaking_id)
);

CREATE TABLE public.categories (
    category_id INTEGER DEFAULT nextval('categories_category_id_seq') NOT NULL,
    name CHARACTER VARYING(100) NOT NULL,
    slug CHARACTER VARYING(100) NOT NULL,
    description TEXT,
    color CHARACTER VARYING(7),
    icon CHARACTER VARYING(50),
    parent_id INTEGER,
    order_index INTEGER DEFAULT 0,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT categories_pkey PRIMARY KEY (category_id),
    CONSTRAINT categories_slug_key UNIQUE (slug)
);

CREATE TABLE public.cleanup_history (
    cleanup_id INTEGER DEFAULT nextval('cleanup_history_cleanup_id_seq') NOT NULL,
    type CHARACTER VARYING(20) NOT NULL,
    public_sessions INTEGER DEFAULT 0,
    admin_sessions INTEGER DEFAULT 0,
    user_sessions INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    duration INTEGER,
    status CHARACTER VARYING(20),
    error_message TEXT,
    triggered_by CHARACTER VARYING(50),
    cleaned_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT cleanup_history_pkey PRIMARY KEY (cleanup_id)
);

CREATE TABLE public.cookie_stats_daily (
    stat_id INTEGER DEFAULT nextval('cookie_stats_daily_stat_id_seq') NOT NULL,
    stat_date DATE DEFAULT CURRENT_DATE NOT NULL,
    county CHARACTER VARYING(100),
    town CHARACTER VARYING(100),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying,
    total_consents INTEGER DEFAULT 0,
    accepted_count INTEGER DEFAULT 0,
    rejected_count INTEGER DEFAULT 0,
    functional_enabled INTEGER DEFAULT 0,
    analytics_enabled INTEGER DEFAULT 0,
    marketing_enabled INTEGER DEFAULT 0,
    personalization_enabled INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT cookie_stats_daily_pkey PRIMARY KEY (stat_id),
    CONSTRAINT unique_daily_location UNIQUE (stat_date, county, town, category)
);

CREATE TABLE public.cookie_stats_monthly (
    stat_id INTEGER DEFAULT nextval('cookie_stats_monthly_stat_id_seq') NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    county CHARACTER VARYING(100),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying,
    total_consents INTEGER DEFAULT 0,
    accepted_count INTEGER DEFAULT 0,
    rejected_count INTEGER DEFAULT 0,
    avg_acceptance_rate NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT month_check CHECK (((month >= 1) AND (month <= 12))),
    CONSTRAINT cookie_stats_monthly_pkey PRIMARY KEY (stat_id),
    CONSTRAINT unique_monthly_location UNIQUE (year, month, county, category)
);

CREATE TABLE public.daily_location_stats (
    stat_id INTEGER DEFAULT nextval('daily_location_stats_stat_id_seq') NOT NULL,
    stat_date DATE NOT NULL,
    county CHARACTER VARYING(255),
    town CHARACTER VARYING(255),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    new_devices INTEGER DEFAULT 0,
    returning_devices INTEGER DEFAULT 0,
    total_devices INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT daily_stats_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text]))),
    CONSTRAINT daily_location_stats_pkey PRIMARY KEY (stat_id),
    CONSTRAINT daily_location_stats_stat_date_county_town_category_key UNIQUE (stat_date, county, town, category)
);

CREATE TABLE public.device_registry (
    device_id CHARACTER VARYING(255) NOT NULL,
    county CHARACTER VARYING(255),
    town CHARACTER VARYING(255),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT device_registry_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text]))),
    CONSTRAINT device_registry_pkey PRIMARY KEY (device_id)
);

CREATE TABLE public.donations (
    donation_id INTEGER DEFAULT nextval('donations_donation_id_seq') NOT NULL,
    user_id INTEGER,
    donor_name CHARACTER VARYING(200),
    donor_email CHARACTER VARYING(150),
    amount NUMERIC NOT NULL,
    payment_method public.payment_method NOT NULL,
    transaction_ref CHARACTER VARYING(100),
    status public.donation_status DEFAULT 'pending'::donation_status,
    donated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT donations_pkey PRIMARY KEY (donation_id)
);

CREATE TABLE public.editor_pick (
    pick_id INTEGER DEFAULT nextval('editor_pick_pick_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    picked_by INTEGER,
    picked_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    manually_removed BOOLEAN DEFAULT false,
    CONSTRAINT editor_pick_pkey PRIMARY KEY (pick_id)
);

CREATE TABLE public.email_queue (
    queue_id INTEGER DEFAULT nextval('email_queue_queue_id_seq') NOT NULL,
    recipient_email CHARACTER VARYING(255) NOT NULL,
    subject CHARACTER VARYING(255) NOT NULL,
    body TEXT NOT NULL,
    status CHARACTER VARYING(20) DEFAULT 'pending'::character varying,
    attempts INTEGER DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    sent_at TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT email_queue_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('sent'::character varying)::text, ('failed'::character varying)::text]))),
    CONSTRAINT email_queue_pkey PRIMARY KEY (queue_id)
);

CREATE TABLE public.featured_news (
    featured_id INTEGER DEFAULT nextval('featured_news_featured_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    tier CHARACTER VARYING(10) NOT NULL,
    starts_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITHOUT TIME ZONE,
    activated_by INTEGER,
    manually_removed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT featured_news_tier_check CHECK (((tier)::text = ANY ((ARRAY['gold'::character varying, 'silver'::character varying, 'bronze'::character varying])::text[]))),
    CONSTRAINT featured_news_pkey PRIMARY KEY (featured_id)
);

CREATE TABLE public.image_variants (
    variant_id INTEGER DEFAULT nextval('image_variants_variant_id_seq') NOT NULL,
    parent_image_id INTEGER,
    variant_name CHARACTER VARYING(50) NOT NULL,
    variant_url TEXT NOT NULL,
    width INTEGER,
    height INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT image_variants_pkey PRIMARY KEY (variant_id)
);

CREATE TABLE public.media_files (
    file_id INTEGER DEFAULT nextval('media_files_file_id_seq') NOT NULL,
    filename CHARACTER VARYING(255) NOT NULL,
    original_name CHARACTER VARYING(255),
    file_path TEXT NOT NULL,
    file_type CHARACTER VARYING(50),
    file_size BIGINT,
    mime_type CHARACTER VARYING(100),
    storage_provider CHARACTER VARYING(50) DEFAULT 'local'::character varying,
    cloudflare_id CHARACTER VARYING(255),
    created_by INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT media_files_pkey PRIMARY KEY (file_id)
);

CREATE TABLE public.monthly_location_summary (
    summary_id INTEGER DEFAULT nextval('monthly_location_summary_summary_id_seq') NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    county CHARACTER VARYING(255),
    town CHARACTER VARYING(255),
    category CHARACTER VARYING(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    total_devices INTEGER DEFAULT 0,
    unique_devices INTEGER DEFAULT 0,
    avg_daily_devices INTEGER DEFAULT 0,
    peak_daily_devices INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    CONSTRAINT monthly_summary_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text]))),
    CONSTRAINT monthly_summary_month_check CHECK (((month >= 1) AND (month <= 12))),
    CONSTRAINT monthly_location_summary_pkey PRIMARY KEY (summary_id),
    CONSTRAINT monthly_location_summary_year_month_county_town_category_key UNIQUE (year, month, county, town, category)
);

CREATE TABLE public.mpesa_b2c_transactions (
    b2c_id INTEGER DEFAULT nextval('mpesa_b2c_transactions_b2c_id_seq') NOT NULL,
    advertiser_id INTEGER,
    conversation_id CHARACTER VARYING(100),
    originator_conversation_id CHARACTER VARYING(100),
    mpesa_receipt_number CHARACTER VARYING(50),
    phone_number CHARACTER VARYING(15) NOT NULL,
    amount NUMERIC NOT NULL,
    transaction_type CHARACTER VARYING(50),
    result_code INTEGER,
    result_desc TEXT,
    status CHARACTER VARYING(20) DEFAULT 'pending'::character varying,
    callback_received BOOLEAN DEFAULT false,
    callback_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_b2c_transactions_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('success'::character varying)::text, ('failed'::character varying)::text, ('queued'::character varying)::text]))),
    CONSTRAINT mpesa_b2c_transactions_pkey PRIMARY KEY (b2c_id),
    CONSTRAINT mpesa_b2c_transactions_conversation_id_key UNIQUE (conversation_id),
    CONSTRAINT mpesa_b2c_transactions_mpesa_receipt_number_key UNIQUE (mpesa_receipt_number),
    CONSTRAINT mpesa_b2c_transactions_originator_conversation_id_key UNIQUE (originator_conversation_id)
);

CREATE TABLE public.mpesa_callback_log (
    callback_id INTEGER DEFAULT nextval('mpesa_callback_log_callback_id_seq') NOT NULL,
    callback_type CHARACTER VARYING(50) NOT NULL,
    reference_id CHARACTER VARYING(100),
    raw_payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT false,
    processing_error TEXT,
    ip_address INET,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_callback_log_callback_type_check CHECK (((callback_type)::text = ANY (ARRAY[('stk_push'::character varying)::text, ('b2c'::character varying)::text, ('c2b'::character varying)::text, ('validation'::character varying)::text, ('confirmation'::character varying)::text]))),
    CONSTRAINT mpesa_callback_log_pkey PRIMARY KEY (callback_id)
);

CREATE TABLE public.mpesa_stk_push_log (
    log_id INTEGER DEFAULT nextval('mpesa_stk_push_log_log_id_seq') NOT NULL,
    transaction_id INTEGER,
    merchant_request_id CHARACTER VARYING(100),
    checkout_request_id CHARACTER VARYING(100),
    response_code CHARACTER VARYING(10),
    response_description TEXT,
    customer_message TEXT,
    request_payload JSONB DEFAULT '{}'::jsonb,
    response_payload JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_stk_push_log_pkey PRIMARY KEY (log_id)
);

CREATE TABLE public.mpesa_transactions (
    transaction_id INTEGER DEFAULT nextval('mpesa_transactions_transaction_id_seq') NOT NULL,
    advertiser_id INTEGER,
    merchant_request_id CHARACTER VARYING(100),
    checkout_request_id CHARACTER VARYING(100),
    mpesa_receipt_number CHARACTER VARYING(50),
    phone_number CHARACTER VARYING(15) NOT NULL,
    amount NUMERIC NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE,
    result_code INTEGER,
    result_desc TEXT,
    status CHARACTER VARYING(20) DEFAULT 'pending'::character varying,
    callback_received BOOLEAN DEFAULT false,
    callback_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_transactions_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('success'::character varying)::text, ('failed'::character varying)::text, ('cancelled'::character varying)::text]))),
    CONSTRAINT mpesa_transactions_pkey PRIMARY KEY (transaction_id),
    CONSTRAINT mpesa_transactions_checkout_request_id_key UNIQUE (checkout_request_id),
    CONSTRAINT mpesa_transactions_merchant_request_id_key UNIQUE (merchant_request_id),
    CONSTRAINT mpesa_transactions_mpesa_receipt_number_key UNIQUE (mpesa_receipt_number)
);

CREATE TABLE public.news (
    news_id INTEGER DEFAULT nextval('news_news_id_seq') NOT NULL,
    title CHARACTER VARYING(200) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    slug CHARACTER VARYING(200),
    category_id INTEGER,
    author_id INTEGER,
    image_url CHARACTER VARYING(500),
    processed_content TEXT,
    quote_sayer TEXT,
    quote_position INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    share_count INTEGER DEFAULT 0,
    status public.news_status DEFAULT 'draft'::news_status,
    priority CHARACTER VARYING(10) DEFAULT 'medium'::character varying,
    tags TEXT,
    meta_description TEXT,
    seo_keywords TEXT,
    reading_time INTEGER,
    published_at TIMESTAMP WITHOUT TIME ZONE,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    uuid UUID DEFAULT gen_random_uuid(),
    fact_checked BOOLEAN DEFAULT false,
    fact_checked_by INTEGER,
    content_warning TEXT,
    sensitive BOOLEAN DEFAULT false,
    reading_level CHARACTER VARYING(20),
    ai_summary TEXT,
    last_edited_by INTEGER,
    last_edited_at TIMESTAMP WITHOUT TIME ZONE,
    revision INTEGER DEFAULT 1,
    primary_category_id INTEGER,
    quotes_data JSONB DEFAULT '[]'::jsonb NOT NULL,
    sources JSONB DEFAULT '[]'::jsonb NOT NULL,
    editor_pick BOOLEAN DEFAULT false,
    CONSTRAINT news_priority_check CHECK (((priority)::text = ANY (ARRAY[('high'::character varying)::text, ('medium'::character varying)::text, ('low'::character varying)::text]))),
    CONSTRAINT news_pkey PRIMARY KEY (news_id),
    CONSTRAINT news_slug_key UNIQUE (slug),
    CONSTRAINT news_uuid_key UNIQUE (uuid)
);

CREATE TABLE public.news_approval (
    approval_record_id INTEGER DEFAULT nextval('news_approval_approval_record_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    workflow_status CHARACTER VARYING(20) DEFAULT 'draft'::character varying,
    requires_approval BOOLEAN DEFAULT false,
    submitted_at TIMESTAMP WITHOUT TIME ZONE,
    submitted_by INTEGER NOT NULL,
    approved_by INTEGER,
    approved_at TIMESTAMP WITHOUT TIME ZONE,
    rejected_by INTEGER,
    rejected_at TIMESTAMP WITHOUT TIME ZONE,
    rejection_reason TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_approval_workflow_status_check CHECK (((workflow_status)::text = ANY ((ARRAY['draft'::character varying, 'pending_review'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying, 'published'::character varying])::text[]))),
    CONSTRAINT news_approval_pkey PRIMARY KEY (approval_record_id),
    CONSTRAINT news_approval_news_id_key UNIQUE (news_id)
);

CREATE TABLE public.news_approval_history (
    approval_id INTEGER DEFAULT nextval('news_approval_history_approval_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    reviewer_id INTEGER NOT NULL,
    action CHARACTER VARYING(20) NOT NULL,
    comments TEXT,
    previous_status CHARACTER VARYING(20),
    new_status CHARACTER VARYING(20),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_approval_history_action_check CHECK (((action)::text = ANY (ARRAY[('submit'::character varying)::text, ('approve'::character varying)::text, ('reject'::character varying)::text, ('request_changes'::character varying)::text]))),
    CONSTRAINT news_approval_history_pkey PRIMARY KEY (approval_id)
);

CREATE TABLE public.news_categories (
    news_category_id INTEGER DEFAULT nextval('news_categories_news_category_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_categories_pkey PRIMARY KEY (news_category_id),
    CONSTRAINT news_categories_news_id_category_id_key UNIQUE (news_id, category_id)
);

CREATE TABLE public.news_comments (
    comment_id INTEGER DEFAULT nextval('news_comments_comment_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    user_id INTEGER,
    parent_id INTEGER,
    author_name CHARACTER VARYING(100),
    author_email CHARACTER VARYING(150),
    comment_text TEXT NOT NULL,
    status public.comment_status DEFAULT 'pending'::comment_status,
    ip_address INET,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_comments_pkey PRIMARY KEY (comment_id)
);

CREATE TABLE public.news_content_blocks (
    block_id INTEGER NOT NULL,
    news_id INTEGER NOT NULL,
    block_type CHARACTER VARYING(20) NOT NULL,
    block_data JSONB NOT NULL,
    order_index INTEGER NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_content_blocks_block_type_check CHECK (((block_type)::text = ANY (ARRAY[('paragraph'::character varying)::text, ('heading'::character varying)::text, ('quote'::character varying)::text, ('highlight'::character varying)::text, ('timeline'::character varying)::text, ('interview'::character varying)::text, ('image'::character varying)::text, ('video'::character varying)::text, ('embed'::character varying)::text]))),
    CONSTRAINT news_content_blocks_pkey PRIMARY KEY (block_id)
);

CREATE TABLE public.news_images (
    image_id INTEGER DEFAULT nextval('news_images_image_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    image_url CHARACTER VARYING(500) NOT NULL,
    image_caption TEXT,
    alt_text TEXT,
    display_order INTEGER DEFAULT 5,
    is_featured BOOLEAN DEFAULT false,
    width INTEGER,
    height INTEGER,
    file_size BIGINT,
    mime_type CHARACTER VARYING(100),
    storage_provider CHARACTER VARYING(20) DEFAULT 'local'::character varying,
    cloudflare_id CHARACTER VARYING(255),
    cloudflare_variant CHARACTER VARYING(50),
    uploaded_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_images_storage_provider_check CHECK (((storage_provider)::text = ANY (ARRAY[('local'::character varying)::text, ('cloudflare'::character varying)::text, ('s3'::character varying)::text]))),
    CONSTRAINT news_images_pkey PRIMARY KEY (image_id),
    CONSTRAINT news_images_news_id_image_url_key UNIQUE (news_id, image_url)
);

CREATE TABLE public.news_quotes (
    quote_id INTEGER DEFAULT nextval('news_quotes_quote_id_seq') NOT NULL,
    quote_text TEXT NOT NULL,
    sayer_name CHARACTER VARYING(255) NOT NULL,
    sayer_title CHARACTER VARYING(255),
    image_url CHARACTER VARYING(500),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    editor_pick BOOLEAN DEFAULT false,
    CONSTRAINT news_quotes_pkey PRIMARY KEY (quote_id)
);

CREATE TABLE public.news_quotes_images (
    image_id INTEGER DEFAULT nextval('news_quotes_images_image_id_seq') NOT NULL,
    quote_id INTEGER NOT NULL,
    image_url CHARACTER VARYING(500) NOT NULL,
    cloudflare_id CHARACTER VARYING(255),
    storage_provider CHARACTER VARYING(20) DEFAULT 'cloudflare'::character varying,
    width INTEGER,
    height INTEGER,
    file_size BIGINT,
    mime_type CHARACTER VARYING(100),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    storage_mode CHARACTER VARYING(20) DEFAULT 'production'::character varying,
    local_path CHARACTER VARYING(500),
    metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_quotes_images_storage_mode_check CHECK (((storage_mode)::text = ANY (ARRAY[('development'::character varying)::text, ('production'::character varying)::text]))),
    CONSTRAINT news_quotes_images_pkey PRIMARY KEY (image_id)
);

CREATE TABLE public.news_reactions (
    reaction_id INTEGER DEFAULT nextval('news_reactions_reaction_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    user_id INTEGER,
    reaction_type public.reaction_type DEFAULT 'like'::reaction_type,
    ip_address INET,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_reactions_pkey PRIMARY KEY (reaction_id),
    CONSTRAINT news_reactions_news_id_user_id_key UNIQUE (news_id, user_id)
);

CREATE TABLE public.news_shares (
    share_id INTEGER DEFAULT nextval('news_shares_share_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    platform public.share_platform NOT NULL,
    user_id INTEGER,
    ip_address INET,
    shared_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_shares_pkey PRIMARY KEY (share_id)
);

CREATE TABLE public.news_social_media (
    social_media_id INTEGER DEFAULT nextval('news_social_media_social_media_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    platform CHARACTER VARYING(50) NOT NULL,
    post_type CHARACTER VARYING(50) NOT NULL,
    post_url TEXT NOT NULL,
    post_id CHARACTER VARYING(255),
    embed_code TEXT,
    embed_html TEXT,
    oembed_url TEXT,
    author_name CHARACTER VARYING(255),
    author_handle CHARACTER VARYING(255),
    author_avatar_url TEXT,
    post_text TEXT,
    post_date TIMESTAMP WITH TIME ZONE,
    thumbnail_url TEXT,
    media_url TEXT,
    media_urls JSONB DEFAULT '[]'::jsonb,
    duration INTEGER,
    dimensions JSONB DEFAULT '{}'::jsonb,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    saves_count INTEGER DEFAULT 0,
    display_order INTEGER DEFAULT 2,
    is_featured BOOLEAN DEFAULT false,
    show_full_embed BOOLEAN DEFAULT true,
    auto_embed BOOLEAN DEFAULT true,
    caption TEXT,
    hashtags text[] DEFAULT '{}'::text[],
    mentions text[] DEFAULT '{}'::text[],
    location CHARACTER VARYING(255),
    oembed_data JSONB DEFAULT '{}'::jsonb,
    raw_api_response JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_fetched_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_social_media_platform_check CHECK (((platform)::text = ANY (ARRAY[('youtube_video'::character varying)::text, ('youtube_short'::character varying)::text, ('twitter_post'::character varying)::text, ('twitter_video'::character varying)::text, ('x_post'::character varying)::text, ('x_video'::character varying)::text, ('instagram_post'::character varying)::text, ('instagram_reel'::character varying)::text, ('instagram_video'::character varying)::text, ('facebook_post'::character varying)::text, ('facebook_video'::character varying)::text, ('facebook_reel'::character varying)::text, ('tiktok_video'::character varying)::text, ('tiktok_reel'::character varying)::text, ('linkedin_post'::character varying)::text, ('threads_post'::character varying)::text, ('whatsapp_status'::character varying)::text]))),
    CONSTRAINT news_social_media_post_type_check CHECK (((post_type)::text = ANY (ARRAY[('post'::character varying)::text, ('reel'::character varying)::text, ('video'::character varying)::text, ('short'::character varying)::text, ('story'::character varying)::text, ('status'::character varying)::text]))),
    CONSTRAINT news_social_media_pkey PRIMARY KEY (social_media_id),
    CONSTRAINT news_social_media_news_id_platform_post_id_key UNIQUE (news_id, platform, post_id),
    CONSTRAINT news_social_media_news_id_post_url_key UNIQUE (news_id, post_url)
);

CREATE TABLE public.news_videos (
    video_id INTEGER DEFAULT nextval('news_videos_video_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    platform CHARACTER VARYING(50) NOT NULL,
    video_url TEXT NOT NULL,
    embed_code TEXT,
    caption TEXT,
    thumbnail_url CHARACTER VARYING(500),
    duration INTEGER,
    display_order INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_videos_platform_check CHECK (((platform)::text = ANY (ARRAY[('facebook'::character varying)::text, ('twitter'::character varying)::text, ('youtube'::character varying)::text, ('instagram'::character varying)::text, ('tiktok'::character varying)::text]))),
    CONSTRAINT news_videos_pkey PRIMARY KEY (video_id),
    CONSTRAINT news_videos_news_id_video_url_key UNIQUE (news_id, video_url)
);

CREATE TABLE public.newsletters (
    newsletter_id INTEGER DEFAULT nextval('newsletters_newsletter_id_seq') NOT NULL,
    title CHARACTER VARYING(255) NOT NULL,
    content TEXT NOT NULL,
    sent_to INTEGER DEFAULT 0,
    status CHARACTER VARYING(20) DEFAULT 'draft'::character varying,
    scheduled_at TIMESTAMP WITHOUT TIME ZONE,
    sent_at TIMESTAMP WITHOUT TIME ZONE,
    created_by INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT newsletters_status_check CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('scheduled'::character varying)::text, ('sent'::character varying)::text, ('failed'::character varying)::text]))),
    CONSTRAINT newsletters_pkey PRIMARY KEY (newsletter_id)
);

CREATE TABLE public.page_views (
    view_id INTEGER DEFAULT nextval('page_views_view_id_seq') NOT NULL,
    page_url TEXT NOT NULL,
    news_id INTEGER,
    user_id INTEGER,
    ip_address INET,
    user_agent TEXT,
    referer TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT page_views_pkey PRIMARY KEY (view_id)
);

CREATE TABLE public.pinned_news (
    pinned_id INTEGER DEFAULT nextval('pinned_news_pinned_id_seq') NOT NULL,
    news_id INTEGER NOT NULL,
    tier CHARACTER VARYING(10) NOT NULL,
    position INTEGER,
    starts_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ends_at TIMESTAMP WITHOUT TIME ZONE,
    activated_by INTEGER,
    manually_removed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pinned_news_position_check CHECK (("position" > 0)),
    CONSTRAINT pinned_news_tier_check CHECK (((tier)::text = ANY ((ARRAY['gold'::character varying, 'silver'::character varying, 'bronze'::character varying])::text[]))),
    CONSTRAINT pinned_news_pkey PRIMARY KEY (pinned_id)
);

CREATE TABLE public.referrals (
    referral_id INTEGER DEFAULT nextval('referrals_referral_id_seq') NOT NULL,
    referrer_id INTEGER NOT NULL,
    referred_id INTEGER NOT NULL,
    status public.referral_status DEFAULT 'pending'::referral_status,
    reward_given BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT referrals_pkey PRIMARY KEY (referral_id)
);

CREATE TABLE public.role_permissions (
    permission_id INTEGER DEFAULT nextval('role_permissions_permission_id_seq') NOT NULL,
    role_id INTEGER NOT NULL,
    resource_type CHARACTER VARYING(50) NOT NULL,
    resource_name CHARACTER VARYING(100) NOT NULL,
    can_create BOOLEAN DEFAULT false,
    can_read BOOLEAN DEFAULT true,
    can_update BOOLEAN DEFAULT false,
    can_delete BOOLEAN DEFAULT false,
    can_publish BOOLEAN DEFAULT false,
    can_approve BOOLEAN DEFAULT false,
    additional_permissions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT role_permissions_pkey PRIMARY KEY (permission_id),
    CONSTRAINT role_permissions_role_id_resource_type_resource_name_key UNIQUE (role_id, resource_type, resource_name)
);

CREATE TABLE public.scheduler_logs (
    log_id INTEGER DEFAULT nextval('scheduler_logs_log_id_seq') NOT NULL,
    event_type CHARACTER VARYING(50) NOT NULL,
    event_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    CONSTRAINT scheduler_logs_pkey PRIMARY KEY (log_id)
);

CREATE TABLE public.session_store (
    sid CHARACTER VARYING NOT NULL,
    expire TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    sess JSON DEFAULT '{}'::json NOT NULL,
    CONSTRAINT session_pkey PRIMARY KEY (sid)
);

CREATE TABLE public.social_embed_cache (
    cache_id INTEGER DEFAULT nextval('social_embed_cache_cache_id_seq') NOT NULL,
    post_url TEXT NOT NULL,
    embed_html TEXT,
    oembed_data JSONB DEFAULT '{}'::jsonb,
    fetched_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT social_embed_cache_pkey PRIMARY KEY (cache_id),
    CONSTRAINT social_embed_cache_post_url_key UNIQUE (post_url)
);

CREATE TABLE public.social_videos (
    video_id INTEGER DEFAULT nextval('social_videos_video_id_seq') NOT NULL,
    title CHARACTER VARYING(300) NOT NULL,
    description TEXT,
    platform CHARACTER VARYING(50) NOT NULL,
    video_type CHARACTER VARYING(50) NOT NULL,
    video_url TEXT NOT NULL,
    video_id_external CHARACTER VARYING(255),
    embed_code TEXT,
    embed_html TEXT,
    oembed_url TEXT,
    thumbnail_url TEXT,
    duration INTEGER,
    channel_name CHARACTER VARYING(255),
    channel_id CHARACTER VARYING(255),
    channel_url TEXT,
    channel_avatar_url TEXT,
    is_live BOOLEAN DEFAULT false,
    live_started_at TIMESTAMP WITH TIME ZONE,
    live_ended_at TIMESTAMP WITH TIME ZONE,
    scheduled_start_time TIMESTAMP WITH TIME ZONE,
    concurrent_viewers INTEGER DEFAULT 0,
    peak_viewers INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    dislikes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    status public.video_status DEFAULT 'draft'::video_status,
    visibility public.video_visibility DEFAULT 'public'::video_visibility,
    featured BOOLEAN DEFAULT false,
    featured_until TIMESTAMP WITH TIME ZONE,
    display_order INTEGER DEFAULT 0,
    tags text[] DEFAULT ARRAY[]::text[],
    categories int4[] DEFAULT ARRAY[]::integer[],
    auto_refresh BOOLEAN DEFAULT true,
    refresh_interval INTEGER DEFAULT 300,
    last_refreshed_at TIMESTAMP WITH TIME ZONE,
    created_by INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    editor_pick BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb NOT NULL,
    oembed_data JSONB DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT video_platform_check CHECK (((platform)::text = ANY (ARRAY[('youtube'::character varying)::text, ('youtube_live'::character varying)::text, ('facebook'::character varying)::text, ('facebook_live'::character varying)::text, ('instagram'::character varying)::text, ('instagram_live'::character varying)::text, ('twitter'::character varying)::text, ('twitter_live'::character varying)::text, ('tiktok'::character varying)::text, ('tiktok_live'::character varying)::text, ('twitch'::character varying)::text, ('vimeo'::character varying)::text, ('dailymotion'::character varying)::text]))),
    CONSTRAINT video_type_check CHECK (((video_type)::text = ANY (ARRAY[('live'::character varying)::text, ('recorded'::character varying)::text, ('premiere'::character varying)::text, ('short'::character varying)::text, ('reel'::character varying)::text, ('story'::character varying)::text]))),
    CONSTRAINT social_videos_pkey PRIMARY KEY (video_id),
    CONSTRAINT social_videos_video_url_key UNIQUE (video_url)
);

CREATE TABLE public.social_videos_analytics (
    analytics_id INTEGER DEFAULT nextval('social_videos_analytics_analytics_id_seq') NOT NULL,
    video_id INTEGER NOT NULL,
    stat_date DATE NOT NULL,
    views_count INTEGER DEFAULT 0,
    unique_viewers INTEGER DEFAULT 0,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    watch_time_minutes INTEGER DEFAULT 0,
    avg_watch_duration INTEGER DEFAULT 0,
    peak_concurrent_viewers INTEGER DEFAULT 0,
    total_concurrent_viewers INTEGER DEFAULT 0,
    engagement_rate NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT social_videos_analytics_pkey PRIMARY KEY (analytics_id),
    CONSTRAINT social_videos_analytics_video_id_stat_date_key UNIQUE (video_id, stat_date)
);

CREATE TABLE public.subscribers (
    subscriber_id INTEGER DEFAULT nextval('subscribers_subscriber_id_seq') NOT NULL,
    email CHARACTER VARYING(150) NOT NULL,
    name CHARACTER VARYING(200),
    status public.subscriber_status DEFAULT 'pending'::subscriber_status,
    preferences JSONB DEFAULT '{}'::jsonb,
    subscribed_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP WITHOUT TIME ZONE,
    unsubscribed_at TIMESTAMP WITHOUT TIME ZONE,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT subscribers_pkey PRIMARY KEY (subscriber_id),
    CONSTRAINT subscribers_email_key UNIQUE (email)
);

CREATE TABLE public.system_logs (
    log_id INTEGER DEFAULT nextval('system_logs_log_id_seq') NOT NULL,
    log_level CHARACTER VARYING(20) NOT NULL,
    log_message TEXT NOT NULL,
    log_source CHARACTER VARYING(100),
    log_data JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT system_logs_pkey PRIMARY KEY (log_id)
);

CREATE TABLE public.system_settings (
    setting_id INTEGER DEFAULT nextval('system_settings_setting_id_seq') NOT NULL,
    setting_key CHARACTER VARYING(100) NOT NULL,
    setting_value TEXT,
    setting_type CHARACTER VARYING(20) DEFAULT 'string'::character varying,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT system_settings_pkey PRIMARY KEY (setting_id),
    CONSTRAINT system_settings_setting_key_key UNIQUE (setting_key)
);

CREATE TABLE public.user_notifications (
    notification_id INTEGER DEFAULT nextval('user_notifications_notification_id_seq') NOT NULL,
    user_id INTEGER NOT NULL,
    title CHARACTER VARYING(255) NOT NULL,
    message TEXT NOT NULL,
    type CHARACTER VARYING(50) DEFAULT 'general'::character varying,
    link TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_notifications_pkey PRIMARY KEY (notification_id)
);

CREATE TABLE public.user_preferences (
    preference_id INTEGER DEFAULT nextval('user_preferences_preference_id_seq') NOT NULL,
    user_id INTEGER NOT NULL,
    preferred_categories int4[],
    notification_settings JSONB DEFAULT '{"sms": false, "push": true, "email": true}'::jsonb,
    language CHARACTER VARYING(10) DEFAULT 'en'::character varying,
    theme CHARACTER VARYING(20) DEFAULT 'light'::character varying,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_preferences_pkey PRIMARY KEY (preference_id),
    CONSTRAINT user_preferences_user_id_key UNIQUE (user_id)
);

CREATE TABLE public.user_reading_history (
    history_id INTEGER DEFAULT nextval('user_reading_history_history_id_seq') NOT NULL,
    user_id INTEGER NOT NULL,
    news_id INTEGER NOT NULL,
    read_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    read_duration INTEGER,
    read_percentage INTEGER DEFAULT 0,
    CONSTRAINT user_reading_history_pkey PRIMARY KEY (history_id)
);

CREATE TABLE public.user_roles (
    role_id INTEGER DEFAULT nextval('user_roles_role_id_seq') NOT NULL,
    role_name CHARACTER VARYING(50) NOT NULL,
    role_slug CHARACTER VARYING(50) NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '{}'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_roles_pkey PRIMARY KEY (role_id),
    CONSTRAINT user_roles_role_name_key UNIQUE (role_name),
    CONSTRAINT user_roles_role_slug_key UNIQUE (role_slug)
);

CREATE TABLE public.user_saved_articles (
    saved_id INTEGER DEFAULT nextval('user_saved_articles_saved_id_seq') NOT NULL,
    user_id INTEGER NOT NULL,
    news_id INTEGER NOT NULL,
    saved_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_saved_articles_pkey PRIMARY KEY (saved_id),
    CONSTRAINT user_saved_articles_user_id_news_id_key UNIQUE (user_id, news_id)
);

CREATE TABLE public.users (
    user_id INTEGER DEFAULT nextval('users_user_id_seq') NOT NULL,
    first_name CHARACTER VARYING(100) NOT NULL,
    last_name CHARACTER VARYING(100) NOT NULL,
    email CHARACTER VARYING(150) NOT NULL,
    phone CHARACTER VARYING(20) NOT NULL,
    county CHARACTER VARYING(100) NOT NULL,
    constituency CHARACTER VARYING(100),
    referral_code CHARACTER VARYING(50),
    referred_by INTEGER,
    volunteer_interest BOOLEAN DEFAULT false,
    sms_updates BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    password_hash CHARACTER VARYING(255),
    last_login TIMESTAMP WITHOUT TIME ZONE,
    status public.user_status DEFAULT 'active'::user_status,
    role_id INTEGER,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT users_pkey PRIMARY KEY (user_id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_phone_key UNIQUE (phone),
    CONSTRAINT users_referral_code_key UNIQUE (referral_code)
);

CREATE TABLE public.volunteers (
    volunteer_id INTEGER DEFAULT nextval('volunteers_volunteer_id_seq') NOT NULL,
    full_name CHARACTER VARYING(200) NOT NULL,
    nickname CHARACTER VARYING(100),
    phone CHARACTER VARYING(20) NOT NULL,
    email CHARACTER VARYING(150),
    county CHARACTER VARYING(100) NOT NULL,
    constituency CHARACTER VARYING(100),
    expertise CHARACTER VARYING(200),
    availability public.availability_type DEFAULT 'flexible'::availability_type,
    status public.volunteer_status DEFAULT 'pending'::volunteer_status,
    assigned_tasks TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT volunteers_pkey PRIMARY KEY (volunteer_id),
    CONSTRAINT volunteers_email_key UNIQUE (email),
    CONSTRAINT volunteers_phone_key UNIQUE (phone)
);

-- Foreign Key Constraints
-- Added separately for clean dependency resolution

ALTER TABLE ONLY public.activity_log
    ADD CONSTRAINT activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.activity_log
    ADD CONSTRAINT activity_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.ad_clicks
    ADD CONSTRAINT ad_clicks_ad_id_fkey FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ad_impressions
    ADD CONSTRAINT ad_impressions_ad_id_fkey FOREIGN KEY (ad_id) REFERENCES advertisements(ad_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ad_survey_questions
    ADD CONSTRAINT ad_survey_questions_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES ad_surveys(survey_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ad_survey_responses
    ADD CONSTRAINT ad_survey_responses_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES ad_surveys(survey_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.ad_survey_responses
    ADD CONSTRAINT ad_survey_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id);

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_notifications
    ADD CONSTRAINT admin_notifications_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_online_status
    ADD CONSTRAINT admin_online_status_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_role_id_fkey FOREIGN KEY (role_id) REFERENCES user_roles(role_id);

ALTER TABLE ONLY public.advertisements
    ADD CONSTRAINT advertisements_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.advertisers
    ADD CONSTRAINT advertisers_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES ad_tiers(tier_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.editor_pick
    ADD CONSTRAINT editor_pick_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.editor_pick
    ADD CONSTRAINT editor_pick_picked_by_fkey FOREIGN KEY (picked_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.featured_news
    ADD CONSTRAINT featured_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.featured_news
    ADD CONSTRAINT featured_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.live_broadcast_sessions
    ADD CONSTRAINT live_broadcast_sessions_video_id_fkey FOREIGN KEY (video_id) REFERENCES social_videos(video_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_created_by_fkey FOREIGN KEY (created_by) REFERENCES admins(admin_id);

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.mpesa_stk_push_log
    ADD CONSTRAINT mpesa_stk_push_log_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES mpesa_transactions(transaction_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES advertisers(advertiser_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news
    ADD CONSTRAINT fk_primary_category FOREIGN KEY (primary_category_id) REFERENCES categories(category_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_author_id_fkey FOREIGN KEY (author_id) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_fact_checked_by_fkey FOREIGN KEY (fact_checked_by) REFERENCES admins(admin_id);

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_last_edited_by_fkey FOREIGN KEY (last_edited_by) REFERENCES admins(admin_id);

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES admins(admin_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES news_comments(comment_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_content_blocks
    ADD CONSTRAINT news_content_blocks_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_images
    ADD CONSTRAINT news_images_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_quotes_images
    ADD CONSTRAINT fk_news_quotes_images_quote FOREIGN KEY (quote_id) REFERENCES news_quotes(quote_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_quotes_images
    ADD CONSTRAINT news_quotes_images_quote_id_fkey FOREIGN KEY (quote_id) REFERENCES news_quotes(quote_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_shares
    ADD CONSTRAINT news_shares_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_shares
    ADD CONSTRAINT news_shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.news_social_media
    ADD CONSTRAINT news_social_media_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.news_videos
    ADD CONSTRAINT news_videos_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.newsletters
    ADD CONSTRAINT newsletters_created_by_fkey FOREIGN KEY (created_by) REFERENCES admins(admin_id);

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.pinned_news
    ADD CONSTRAINT pinned_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.pinned_news
    ADD CONSTRAINT pinned_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES user_roles(role_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.social_videos
    ADD CONSTRAINT social_videos_created_by_fkey FOREIGN KEY (created_by) REFERENCES admins(admin_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.social_videos_analytics
    ADD CONSTRAINT social_videos_analytics_video_id_fkey FOREIGN KEY (video_id) REFERENCES social_videos(video_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_reading_history
    ADD CONSTRAINT user_reading_history_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_reading_history
    ADD CONSTRAINT user_reading_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_news_id_fkey FOREIGN KEY (news_id) REFERENCES news(news_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_fkey FOREIGN KEY (referred_by) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES user_roles(role_id);

-- Indexes for Performance
-- Optimized for production queries

CREATE UNIQUE INDEX active_location_counts_county_town_category_key ON public.active_location_counts USING btree (county, town, category);
CREATE INDEX idx_active_counts_active_now ON public.active_location_counts USING btree (active_now DESC);
CREATE INDEX idx_active_counts_activity ON public.active_location_counts USING btree (last_activity DESC);
CREATE INDEX idx_active_counts_category ON public.active_location_counts USING btree (category);
CREATE INDEX idx_active_counts_county ON public.active_location_counts USING btree (county);
CREATE INDEX idx_ad_clicks_ad ON public.ad_clicks USING btree (ad_id);
CREATE INDEX idx_ad_impressions_ad ON public.ad_impressions USING btree (ad_id);
CREATE INDEX idx_survey_questions_survey ON public.ad_survey_questions USING btree (survey_id, order_index);
CREATE INDEX idx_survey_responses_survey ON public.ad_survey_responses USING btree (survey_id);
CREATE INDEX idx_survey_responses_user ON public.ad_survey_responses USING btree (user_id);
CREATE INDEX idx_surveys_dates ON public.ad_surveys USING btree (starts_at, ends_at);
CREATE INDEX idx_surveys_status ON public.ad_surveys USING btree (status);
CREATE UNIQUE INDEX ad_tiers_tier_name_key ON public.ad_tiers USING btree (tier_name);
CREATE INDEX idx_chat_created ON public.admin_chat_messages USING btree (created_at DESC);
CREATE INDEX idx_chat_receiver ON public.admin_chat_messages USING btree (receiver_id, is_read);
CREATE INDEX idx_chat_sender ON public.admin_chat_messages USING btree (sender_id);
CREATE INDEX idx_admin_notifications_admin ON public.admin_notifications USING btree (admin_id, is_read);
CREATE UNIQUE INDEX admin_permissions_admin_id_permission_name_resource_type_key ON public.admin_permissions USING btree (admin_id, permission_name, resource_type);
CREATE INDEX idx_admin_session_expire ON public.admin_session_store USING btree (expire);
CREATE INDEX idx_admin_sessions_expires ON public.admin_sessions USING btree (expires_at) WHERE (is_active = true);
CREATE UNIQUE INDEX admins_email_key ON public.admins USING btree (email);
CREATE UNIQUE INDEX admins_phone_key ON public.admins USING btree (phone);
CREATE UNIQUE INDEX admins_username_key ON public.admins USING btree (username);
CREATE INDEX idx_admins_email ON public.admins USING btree (email);
CREATE INDEX idx_admins_role_id ON public.admins USING btree (role_id);
CREATE INDEX idx_admins_status ON public.admins USING btree (status);
CREATE INDEX idx_admins_username ON public.admins USING btree (username);
CREATE INDEX idx_advertisements_advertiser ON public.advertisements USING btree (advertiser_id);
CREATE INDEX idx_advertisements_dates ON public.advertisements USING btree (start_date, end_date);
CREATE INDEX idx_advertisements_status ON public.advertisements USING btree (status);
CREATE UNIQUE INDEX advertisers_email_key ON public.advertisers USING btree (email);
CREATE UNIQUE INDEX analytics_daily_date_key ON public.analytics_daily USING btree (date);
CREATE UNIQUE INDEX analytics_monthly_year_month_key ON public.analytics_monthly USING btree (year, month);
CREATE UNIQUE INDEX bookmarks_user_id_news_id_key ON public.bookmarks USING btree (user_id, news_id);
CREATE INDEX idx_bookmarks_news_id ON public.bookmarks USING btree (news_id);
CREATE INDEX idx_bookmarks_user_id ON public.bookmarks USING btree (user_id);
CREATE INDEX idx_breaking_active ON public.breaking_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_breaking_news_active ON public.breaking_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_breaking_priority ON public.breaking_news USING btree (priority, starts_at DESC) WHERE (manually_removed = false);
CREATE UNIQUE INDEX categories_slug_key ON public.categories USING btree (slug);
CREATE INDEX idx_categories_active ON public.categories USING btree (active) WHERE (active = true);
CREATE INDEX idx_categories_active_order ON public.categories USING btree (active, order_index) WHERE (active = true);
CREATE INDEX idx_categories_order ON public.categories USING btree (order_index);
CREATE INDEX idx_categories_parent_active ON public.categories USING btree (parent_id, active, order_index);
CREATE INDEX idx_categories_parent_id ON public.categories USING btree (parent_id);
CREATE INDEX idx_categories_slug ON public.categories USING btree (slug);
CREATE INDEX idx_cookie_stats_category ON public.cookie_stats_daily USING btree (category);
CREATE INDEX idx_cookie_stats_county ON public.cookie_stats_daily USING btree (county);
CREATE INDEX idx_cookie_stats_date ON public.cookie_stats_daily USING btree (stat_date DESC);
CREATE UNIQUE INDEX unique_daily_location ON public.cookie_stats_daily USING btree (stat_date, county, town, category);
CREATE INDEX idx_cookie_stats_monthly_county ON public.cookie_stats_monthly USING btree (county);
CREATE INDEX idx_cookie_stats_monthly_date ON public.cookie_stats_monthly USING btree (year DESC, month DESC);
CREATE UNIQUE INDEX unique_monthly_location ON public.cookie_stats_monthly USING btree (year, month, county, category);
CREATE UNIQUE INDEX daily_location_stats_stat_date_county_town_category_key ON public.daily_location_stats USING btree (stat_date, county, town, category);
CREATE INDEX idx_daily_stats_category ON public.daily_location_stats USING btree (category);
CREATE INDEX idx_daily_stats_county ON public.daily_location_stats USING btree (county);
CREATE INDEX idx_daily_stats_date ON public.daily_location_stats USING btree (stat_date DESC);
CREATE INDEX idx_daily_stats_date_county ON public.daily_location_stats USING btree (stat_date DESC, county);
CREATE INDEX idx_device_registry_category ON public.device_registry USING btree (category);
CREATE INDEX idx_device_registry_county ON public.device_registry USING btree (county);
CREATE INDEX idx_device_registry_last_seen ON public.device_registry USING btree (last_seen DESC);
CREATE INDEX idx_device_registry_registered ON public.device_registry USING btree (registered_at DESC);
CREATE INDEX idx_editor_pick_active ON public.editor_pick USING btree (news_id, manually_removed);
CREATE INDEX idx_featured_active ON public.featured_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_featured_news_active ON public.featured_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_featured_tier ON public.featured_news USING btree (tier, starts_at DESC) WHERE (manually_removed = false);
CREATE INDEX idx_broadcast_sessions_active ON public.live_broadcast_sessions USING btree (session_started_at DESC) WHERE (session_ended_at IS NULL);
CREATE INDEX idx_broadcast_sessions_video ON public.live_broadcast_sessions USING btree (video_id);
CREATE INDEX idx_live_broadcast_active ON public.live_broadcast_sessions USING btree (session_started_at DESC) WHERE (session_ended_at IS NULL);
CREATE INDEX idx_live_broadcast_video_id ON public.live_broadcast_sessions USING btree (video_id);
CREATE INDEX idx_media_files_cloudflare ON public.media_files USING btree (cloudflare_id);
CREATE INDEX idx_media_files_storage ON public.media_files USING btree (storage_provider);
CREATE INDEX idx_monthly_summary_county ON public.monthly_location_summary USING btree (county);
CREATE INDEX idx_monthly_summary_date ON public.monthly_location_summary USING btree (year DESC, month DESC);
CREATE UNIQUE INDEX monthly_location_summary_year_month_county_town_category_key ON public.monthly_location_summary USING btree (year, month, county, town, category);
CREATE INDEX idx_mpesa_b2c_advertiser ON public.mpesa_b2c_transactions USING btree (advertiser_id);
CREATE INDEX idx_mpesa_b2c_status ON public.mpesa_b2c_transactions USING btree (status);
CREATE UNIQUE INDEX mpesa_b2c_transactions_conversation_id_key ON public.mpesa_b2c_transactions USING btree (conversation_id);
CREATE UNIQUE INDEX mpesa_b2c_transactions_mpesa_receipt_number_key ON public.mpesa_b2c_transactions USING btree (mpesa_receipt_number);
CREATE UNIQUE INDEX mpesa_b2c_transactions_originator_conversation_id_key ON public.mpesa_b2c_transactions USING btree (originator_conversation_id);
CREATE INDEX idx_mpesa_callback_processed ON public.mpesa_callback_log USING btree (processed);
CREATE INDEX idx_mpesa_callback_type ON public.mpesa_callback_log USING btree (callback_type);
CREATE INDEX idx_mpesa_trans_advertiser ON public.mpesa_transactions USING btree (advertiser_id);
CREATE INDEX idx_mpesa_trans_date ON public.mpesa_transactions USING btree (transaction_date DESC);
CREATE INDEX idx_mpesa_trans_phone ON public.mpesa_transactions USING btree (phone_number);
CREATE INDEX idx_mpesa_trans_status ON public.mpesa_transactions USING btree (status);
CREATE UNIQUE INDEX mpesa_transactions_checkout_request_id_key ON public.mpesa_transactions USING btree (checkout_request_id);
CREATE UNIQUE INDEX mpesa_transactions_merchant_request_id_key ON public.mpesa_transactions USING btree (merchant_request_id);
CREATE UNIQUE INDEX mpesa_transactions_mpesa_receipt_number_key ON public.mpesa_transactions USING btree (mpesa_receipt_number);
CREATE INDEX idx_news_author ON public.news USING btree (author_id);
CREATE INDEX idx_news_category ON public.news USING btree (category_id);
CREATE INDEX idx_news_category_status ON public.news USING btree (category_id, status, published_at DESC);
CREATE INDEX idx_news_combined_search ON public.news USING gin (to_tsvector('english'::regconfig, (((title)::text || ' '::text) || content)));
CREATE INDEX idx_news_content_search ON public.news USING gin (to_tsvector('english'::regconfig, content));
CREATE INDEX idx_news_editor_pick ON public.news USING btree (editor_pick) WHERE (editor_pick = true);
CREATE INDEX idx_news_fact_checked ON public.news USING btree (fact_checked) WHERE (fact_checked = true);
CREATE INDEX idx_news_last_edited_at ON public.news USING btree (last_edited_at DESC);
CREATE INDEX idx_news_last_edited_by ON public.news USING btree (last_edited_by);
CREATE INDEX idx_news_performance ON public.news USING btree (views, likes_count, comments_count);
CREATE INDEX idx_news_priority ON public.news USING btree (priority, published_at DESC) WHERE (status = 'published'::news_status);
CREATE INDEX idx_news_published ON public.news USING btree (published_at DESC) WHERE (status = 'published'::news_status);
CREATE INDEX idx_news_quotes_data_gin ON public.news USING gin (quotes_data);
CREATE INDEX idx_news_reading_level ON public.news USING btree (reading_level);
CREATE INDEX idx_news_revision ON public.news USING btree (revision DESC);
CREATE INDEX idx_news_sensitive ON public.news USING btree (sensitive) WHERE (sensitive = true);
CREATE INDEX idx_news_slug ON public.news USING btree (slug);
CREATE INDEX idx_news_sources_gin ON public.news USING gin (sources);
CREATE INDEX idx_news_status ON public.news USING btree (status);
CREATE INDEX idx_news_status_published ON public.news USING btree (status, published_at DESC) WHERE (status = 'published'::news_status);
CREATE INDEX idx_news_title_search ON public.news USING gin (to_tsvector('english'::regconfig, (title)::text));
CREATE INDEX idx_news_trending ON public.news USING btree (status, published_at DESC, views, likes_count, comments_count, share_count) WHERE (status = 'published'::news_status);
CREATE INDEX idx_news_uuid ON public.news USING btree (uuid);
CREATE UNIQUE INDEX news_slug_key ON public.news USING btree (slug);
CREATE UNIQUE INDEX news_uuid_key ON public.news USING btree (uuid);
CREATE INDEX idx_news_approval_news ON public.news_approval USING btree (news_id);
CREATE INDEX idx_news_approval_workflow ON public.news_approval USING btree (workflow_status);
CREATE UNIQUE INDEX news_approval_news_id_key ON public.news_approval USING btree (news_id);
CREATE INDEX idx_approval_history_news ON public.news_approval_history USING btree (news_id, created_at DESC);
CREATE INDEX idx_approval_history_reviewer ON public.news_approval_history USING btree (reviewer_id);
CREATE INDEX idx_news_categories_category ON public.news_categories USING btree (category_id);
CREATE INDEX idx_news_categories_news ON public.news_categories USING btree (news_id);
CREATE INDEX idx_news_categories_primary ON public.news_categories USING btree (is_primary) WHERE (is_primary = true);
CREATE UNIQUE INDEX news_categories_news_id_category_id_key ON public.news_categories USING btree (news_id, category_id);
CREATE INDEX idx_comments_news_id ON public.news_comments USING btree (news_id, status, created_at DESC);
CREATE INDEX idx_comments_parent_id ON public.news_comments USING btree (parent_id);
CREATE INDEX idx_comments_status ON public.news_comments USING btree (status);
CREATE INDEX idx_comments_user_id ON public.news_comments USING btree (user_id);
CREATE INDEX idx_content_blocks_data ON public.news_content_blocks USING gin (block_data);
CREATE INDEX idx_content_blocks_news ON public.news_content_blocks USING btree (news_id, order_index);
CREATE INDEX idx_content_blocks_type ON public.news_content_blocks USING btree (block_type);
CREATE INDEX idx_news_images_cloudflare ON public.news_images USING btree (cloudflare_id);
CREATE INDEX idx_news_images_display_order ON public.news_images USING btree (news_id, display_order);
CREATE INDEX idx_news_images_featured ON public.news_images USING btree (is_featured) WHERE (is_featured = true);
CREATE INDEX idx_news_images_metadata_gin ON public.news_images USING gin (metadata);
CREATE INDEX idx_news_images_news_id ON public.news_images USING btree (news_id);
CREATE INDEX idx_news_images_storage ON public.news_images USING btree (storage_provider);
CREATE UNIQUE INDEX news_images_news_id_image_url_key ON public.news_images USING btree (news_id, image_url);
CREATE INDEX idx_news_quotes_active ON public.news_quotes USING btree (active);
CREATE INDEX idx_news_quotes_editor_pick ON public.news_quotes USING btree (editor_pick) WHERE (editor_pick = true);
CREATE INDEX news_quotes_active_idx ON public.news_quotes USING btree (active);
CREATE INDEX news_quotes_created_at_idx ON public.news_quotes USING btree (created_at DESC);
CREATE INDEX idx_quotes_images_cloudflare ON public.news_quotes_images USING btree (cloudflare_id);
CREATE INDEX idx_quotes_images_metadata_gin ON public.news_quotes_images USING gin (metadata);
CREATE INDEX idx_quotes_images_quote_id ON public.news_quotes_images USING btree (quote_id);
CREATE INDEX news_quotes_images_quote_id_idx ON public.news_quotes_images USING btree (quote_id);
CREATE INDEX idx_reactions_news_id ON public.news_reactions USING btree (news_id);
CREATE INDEX idx_reactions_user_id ON public.news_reactions USING btree (user_id);
CREATE UNIQUE INDEX news_reactions_news_id_user_id_key ON public.news_reactions USING btree (news_id, user_id);
CREATE INDEX idx_shares_news_id ON public.news_shares USING btree (news_id);
CREATE INDEX idx_shares_platform ON public.news_shares USING btree (platform);
CREATE INDEX idx_news_social_auto_embed ON public.news_social_media USING btree (auto_embed) WHERE (auto_embed = true);
CREATE INDEX idx_news_social_display_order ON public.news_social_media USING btree (news_id, display_order);
CREATE INDEX idx_news_social_featured ON public.news_social_media USING btree (is_featured) WHERE (is_featured = true);
CREATE INDEX idx_news_social_media_news ON public.news_social_media USING btree (news_id, is_featured, display_order);
CREATE INDEX idx_news_social_metadata_gin ON public.news_social_media USING gin (metadata);
CREATE INDEX idx_news_social_news_id ON public.news_social_media USING btree (news_id);
CREATE INDEX idx_news_social_platform ON public.news_social_media USING btree (platform);
CREATE INDEX idx_news_social_post_date ON public.news_social_media USING btree (post_date DESC);
CREATE INDEX idx_news_social_post_type ON public.news_social_media USING btree (post_type);
CREATE UNIQUE INDEX news_social_media_news_id_platform_post_id_key ON public.news_social_media USING btree (news_id, platform, post_id);
CREATE UNIQUE INDEX news_social_media_news_id_post_url_key ON public.news_social_media USING btree (news_id, post_url);
CREATE INDEX idx_news_videos_display_order ON public.news_videos USING btree (news_id, display_order);
CREATE INDEX idx_news_videos_news_id ON public.news_videos USING btree (news_id);
CREATE INDEX idx_news_videos_platform ON public.news_videos USING btree (platform);
CREATE UNIQUE INDEX news_videos_news_id_video_url_key ON public.news_videos USING btree (news_id, video_url);
CREATE INDEX idx_page_views_created ON public.page_views USING btree (created_at DESC);
CREATE INDEX idx_page_views_news_id ON public.page_views USING btree (news_id);
CREATE INDEX idx_pinned_active ON public.pinned_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_pinned_news_active ON public.pinned_news USING btree (news_id, manually_removed, ends_at);
CREATE INDEX idx_pinned_position ON public.pinned_news USING btree ("position", starts_at DESC) WHERE (manually_removed = false);
CREATE INDEX idx_public_session_expire ON public.public_session_store USING btree (expire);
CREATE UNIQUE INDEX role_permissions_role_id_resource_type_resource_name_key ON public.role_permissions USING btree (role_id, resource_type, resource_name);
CREATE INDEX "IDX_session_expire" ON public.session_store USING btree (expire);
CREATE UNIQUE INDEX social_embed_cache_post_url_key ON public.social_embed_cache USING btree (post_url);
CREATE INDEX idx_social_videos_created ON public.social_videos USING btree (created_at DESC);
CREATE INDEX idx_social_videos_created_by ON public.social_videos USING btree (created_by);
CREATE INDEX idx_social_videos_display_order ON public.social_videos USING btree (display_order, created_at DESC);
CREATE INDEX idx_social_videos_editor_pick ON public.social_videos USING btree (editor_pick) WHERE (editor_pick = true);
CREATE INDEX idx_social_videos_featured ON public.social_videos USING btree (featured, featured_until) WHERE (featured = true);
CREATE INDEX idx_social_videos_is_live ON public.social_videos USING btree (is_live) WHERE (is_live = true);
CREATE INDEX idx_social_videos_metadata_gin ON public.social_videos USING gin (metadata);
CREATE INDEX idx_social_videos_oembed_gin ON public.social_videos USING gin (oembed_data);
CREATE INDEX idx_social_videos_platform ON public.social_videos USING btree (platform);
CREATE INDEX idx_social_videos_scheduled ON public.social_videos USING btree (scheduled_start_time) WHERE (scheduled_start_time IS NOT NULL);
CREATE INDEX idx_social_videos_status ON public.social_videos USING btree (status);
CREATE INDEX idx_social_videos_status_visibility ON public.social_videos USING btree (status, visibility);
CREATE UNIQUE INDEX social_videos_video_url_key ON public.social_videos USING btree (video_url);
CREATE INDEX idx_video_analytics_date ON public.social_videos_analytics USING btree (stat_date DESC);
CREATE INDEX idx_video_analytics_video ON public.social_videos_analytics USING btree (video_id, stat_date DESC);
CREATE UNIQUE INDEX social_videos_analytics_video_id_stat_date_key ON public.social_videos_analytics USING btree (video_id, stat_date);
CREATE UNIQUE INDEX subscribers_email_key ON public.subscribers USING btree (email);
CREATE UNIQUE INDEX system_settings_setting_key_key ON public.system_settings USING btree (setting_key);
CREATE INDEX idx_user_notifications_user ON public.user_notifications USING btree (user_id, is_read);
CREATE UNIQUE INDEX user_preferences_user_id_key ON public.user_preferences USING btree (user_id);
CREATE UNIQUE INDEX user_roles_role_name_key ON public.user_roles USING btree (role_name);
CREATE UNIQUE INDEX user_roles_role_slug_key ON public.user_roles USING btree (role_slug);
CREATE UNIQUE INDEX user_saved_articles_user_id_news_id_key ON public.user_saved_articles USING btree (user_id, news_id);
CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at) WHERE (is_active = true);
CREATE INDEX idx_users_created_status ON public.users USING btree (created_at DESC, status);
CREATE INDEX idx_users_email ON public.users USING btree (email);
CREATE INDEX idx_users_phone ON public.users USING btree (phone);
CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);
CREATE INDEX idx_users_status ON public.users USING btree (status);
CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);
CREATE UNIQUE INDEX users_phone_key ON public.users USING btree (phone);
CREATE UNIQUE INDEX users_referral_code_key ON public.users USING btree (referral_code);
CREATE UNIQUE INDEX volunteers_email_key ON public.volunteers USING btree (email);
CREATE UNIQUE INDEX volunteers_phone_key ON public.volunteers USING btree (phone);

-- Triggers


-- Seed Data: Categories
-- Essential category structure for the platform

INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (1, 'World', 'world', 'International news coverage', '#2563eb', 'globe', NULL, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (2, 'National', 'national', 'National news from Kenya', '#c0392b', 'flag', 1, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (3, 'East Africa', 'east-africa', 'News from East African region', '#e67e22', 'compass', 1, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (4, 'Africa', 'africa', 'News from across Africa', '#f39c12', 'globe-africa', 1, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (5, 'Sports Vybe', 'sports-vybe', 'Sports discussions and opinions', '#0891b2', 'comments', 18, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (6, 'Bloggers', 'bloggers', 'Insights and opinions from top bloggers', '#e67e22', 'pen-nib', 17, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (7, 'Investment', 'investment', 'Investment insights and opportunities', '#d4af37', 'coins', 16, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (14, 'Counties', 'counties', 'News from Kenyan counties', '#3498db', 'map-marker', NULL, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (15, 'Politics', 'politics', 'Political news and governance', '#e74c3c', 'landmark', NULL, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (16, 'Business', 'business', 'Business and economic news', '#2ecc71', 'briefcase', NULL, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (17, 'Opinion', 'opinion', 'Opinion pieces and analysis', '#9b59b6', 'comment', NULL, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (18, 'Sports', 'sports', 'Sports news and updates', '#f39c12', 'football', NULL, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (19, 'Life & Style', 'lifestyle', 'Lifestyle and culture', '#e91e63', 'heart', NULL, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (20, 'Entertainment', 'entertainment', 'Entertainment and celebrity news', '#ff6b6b', 'star', NULL, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (21, 'Technology', 'tech', 'Technology and innovation', '#1abc9c', 'laptop', NULL, 9, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (22, 'Other', 'other', 'Other news and features', '#34495e', 'newspaper', NULL, 10, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (26, 'International', 'international', 'Global news coverage', '#3498db', 'earth', 1, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (27, 'Live Updates', 'live', 'Real-time news updates', '#ff6b6b', 'broadcast', 1, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (28, 'Nairobi', 'nairobi', 'News from Nairobi', '#3498db', 'city', 14, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (29, 'Coast Region', 'coast', 'Coastal counties news', '#16a085', 'umbrella-beach', 14, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (30, 'Mountain Region', 'mountain', 'Mt. Kenya region news', '#8e44ad', 'mountain', 14, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (31, 'Lake Region', 'lake-region', 'Western Kenya news', '#2980b9', 'water', 14, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (32, 'Rift Valley', 'rift-valley', 'Rift Valley news', '#d35400', 'hill', 14, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (33, 'Northern Kenya', 'northern', 'Northern counties news', '#c0392b', 'compass-north', 14, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (34, 'Eastern Kenya', 'eastern', 'Eastern counties news', '#f39c12', 'compass-east', 14, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (35, 'Governance', 'governance', 'Government and policy', '#7f8c8d', 'building-columns', 15, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (36, 'Legal Affairs', 'legal', 'Legal and judicial news', '#34495e', 'gavel', 15, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (37, 'Elections', 'elections', 'Electoral news and updates', '#e74c3c', 'vote', 15, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (38, 'Parliament', 'parliament', 'Parliamentary affairs', '#9b59b6', 'users', 15, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (39, 'Companies', 'companies', 'Corporate news', '#2ecc71', 'building', 16, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (40, 'Finance & Markets', 'finance-markets', 'Financial markets', '#27ae60', 'chart-line', 16, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (42, 'Enterprise', 'enterprise', 'Business enterprise', '#16a085', 'handshake', 16, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (43, 'Economy', 'economy', 'Economic analysis', '#1abc9c', 'chart-pie', 16, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (44, 'Banking', 'banking', 'Banking and finance', '#2c3e50', 'bank', 16, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (45, 'Editorials', 'editorials', 'Editorial opinions', '#9b59b6', 'pen', 17, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (46, 'Columnists', 'columnists', 'Column writers', '#8e44ad', 'user-pen', 17, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (48, 'Letters', 'letters', 'Readers letters', '#2980b9', 'envelope', 17, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (49, 'Trail Blazing', 'trail-blazing', 'Innovative perspectives and insights', '#e74c3c', 'fire', 17, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (50, 'AI Graphics', 'ai-graphics', 'AI-generated visual commentary', '#f39c12', 'robot', 17, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (51, 'Analysis', 'analysis', 'In-depth analysis', '#34495e', 'microscope', 17, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (52, 'Football', 'football', 'Football news', '#2ecc71', 'futbol', 18, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (53, 'Athletics', 'athletics', 'Track and field', '#f39c12', 'running', 18, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (54, 'Rugby', 'rugby', 'Rugby news', '#e74c3c', 'football', 18, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (55, 'Motorsport', 'motorsport', 'Motor racing', '#e67e22', 'flag-checkered', 18, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (57, 'Cricket', 'cricket', 'Cricket news', '#16a085', 'baseball', 18, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (58, 'Basketball', 'basketball', 'Basketball news', '#e91e63', 'basketball', 18, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (59, 'Other Sports', 'other-sports', 'Other sporting events', '#9b59b6', 'trophy', 18, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (60, 'Motoring', 'motoring', 'Automotive news', '#34495e', 'car', 19, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (61, 'Culture', 'culture', 'Cultural news', '#9b59b6', 'palette', 19, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (62, 'Family', 'family', 'Family matters', '#e91e63', 'home-heart', 19, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (63, 'Relationships', 'relationships', 'Relationship advice', '#e74c3c', 'heart-circle', 19, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (64, 'Travel', 'travel', 'Travel and tourism', '#3498db', 'plane', 19, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (65, 'Wellness', 'wellness', 'Health and wellness', '#2ecc71', 'spa', 19, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (66, 'Fashion', 'fashion', 'Fashion and style', '#e91e63', 'shirt', 19, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (67, 'Food', 'food', 'Food and dining', '#f39c12', 'utensils', 19, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (68, 'Buzz', 'buzz', 'Entertainment buzz', '#e91e63', 'bell', 20, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (69, 'Trending', 'trending', 'Trending stories', '#ff6b6b', 'fire', 20, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (70, 'Gossip', 'gossip', 'Celebrity gossip', '#e74c3c', 'comment-dots', 20, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (71, 'Life Stories', 'life-stories', 'Inspiring stories', '#9b59b6', 'book-open', 20, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (72, 'Music', 'music', 'Music news', '#3498db', 'music', 20, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (73, 'Movies', 'movies', 'Film and cinema', '#e67e22', 'film', 20, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (74, 'Celebrity', 'celebrity', 'Celebrity news', '#f39c12', 'star', 20, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (75, 'Innovations', 'innovations', 'Tech innovations', '#1abc9c', 'lightbulb', 21, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (76, 'Gadgets', 'gadgets', 'Latest gadgets', '#3498db', 'mobile', 21, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (77, 'Startups', 'startups', 'Tech startups', '#2ecc71', 'rocket', 21, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (78, 'Digital Life', 'digital-life', 'Digital lifestyle', '#9b59b6', 'wifi', 21, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (79, 'AI & ML', 'ai', 'Artificial Intelligence', '#e74c3c', 'brain', 21, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (80, 'Mobile Tech', 'mobile', 'Mobile technology', '#f39c12', 'mobile-screen', 21, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (81, 'Gaming', 'gaming', 'Gaming news', '#e91e63', 'gamepad', 21, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (82, 'Human Rights', 'human-rights', 'Human rights issues', '#e74c3c', 'hand-holding-heart', 22, 1, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (83, 'Climate Crisis', 'climate-crisis', 'Environmental news', '#16a085', 'leaf', 22, 2, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (84, 'Investigations', 'investigations', 'Investigative journalism', '#8e44ad', 'magnifying-glass', 22, 3, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (85, 'Interactives', 'interactives', 'Interactive features', '#3498db', 'sliders', 22, 4, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (86, 'Features', 'features', 'Special features', '#f39c12', 'bookmark', 22, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (87, 'Trending', 'trending-pics', 'Trending visual stories', '#e67e22', 'camera', 22, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (88, 'Reports', 'world-reports', 'In-depth world reports', '#34495e', 'file-text', 1, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (89, 'Reports', 'county-reports', 'County investigation reports', '#34495e', 'file-text', 14, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (90, 'Reports', 'political-reports', 'Political analysis reports', '#34495e', 'file-text', 15, 5, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (91, 'Reports', 'business-reports', 'Business and economic reports', '#34495e', 'file-text', 16, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (92, 'Reports', 'tech-reports', 'Technology research reports', '#34495e', 'file-text', 21, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (93, 'Reports', 'special-reports', 'Special investigation reports', '#34495e', 'file-text', 22, 7, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (94, 'Others', 'sports-others', 'Other sports categories', '#95a5a6', 'ellipsis', 18, 9, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (95, 'Others', 'lifestyle-others', 'Other lifestyle topics', '#95a5a6', 'ellipsis', 19, 9, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (96, 'Others', 'politics-others', 'Other political topics', '#95a5a6', 'ellipsis', 15, 6, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (97, 'Others', 'entertainment-others', 'Other entertainment topics', '#95a5a6', 'ellipsis', 20, 8, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');
INSERT INTO public.categories (category_id, name, slug, description, color, icon, parent_id, order_index, active, created_at, updated_at) VALUES (98, 'Others', 'tech-others', 'Other technology topics', '#95a5a6', 'ellipsis', 21, 9, true, '2026-01-15T11:37:19.661Z', '2026-01-15T11:37:19.661Z');

-- Seed Data: Admin Users
-- All administrative users with full credentials

INSERT INTO public.admins (admin_id, first_name, last_name, email, phone, username, role, password_hash, permissions, last_login, status, role_id, created_at, updated_at) VALUES (4, 'Elijah', 'Kariuki', 'karis@dailyvaibe.com', '0720758470', 'elijah_kariuku', 'super_admin'::public.admin_role, '$2a$10$GWP7Y0FrV3NslrhQCOsAxu4Y3s8dSqXb84qZ3Q5xD.oOnmfDCI6fW', '{"can_delete_any":true,"all_permissions":true,"can_manage_admins":true}'::jsonb, NULL, 'active'::public.user_status, 1, '2025-12-07T23:57:30.556Z'::timestamp, '2025-12-07T23:57:30.556Z'::timestamp);
INSERT INTO public.admins (admin_id, first_name, last_name, email, phone, username, role, password_hash, permissions, last_login, status, role_id, created_at, updated_at) VALUES (5, 'Rahab', 'Waithera', 'rahab@dailyvaibe.com', '0795785304', 'Rheyna', 'super_admin'::public.admin_role, '$2a$10$PD7gyx3K9BayI91eULyHtOxrcOVMNejiikI3bYGnUh83UBSmy8KI6', '{"can_delete_any":true,"all_permissions":true,"can_manage_admins":true}'::jsonb, '2026-01-22T21:03:53.701Z'::timestamp, 'active'::public.user_status, 1, '2025-12-07T23:57:30.765Z'::timestamp, '2025-12-07T23:57:30.765Z'::timestamp);
INSERT INTO public.admins (admin_id, first_name, last_name, email, phone, username, role, password_hash, permissions, last_login, status, role_id, created_at, updated_at) VALUES (6, 'Derrick', 'Wamathai', 'derrick@dailyvaibe.com', '0710146734', NULL, 'moderator'::public.admin_role, '$2a$12$v8y1p9A6KAD.kLf.W5YtnOLMj.GD/RWuFtixTSSUJEWKodPxzQV4m', '{}'::jsonb, '2026-01-18T06:47:08.565Z'::timestamp, 'active'::public.user_status, NULL, '2026-01-18T06:46:40.838Z'::timestamp, '2026-01-18T06:46:40.838Z'::timestamp);
INSERT INTO public.admins (admin_id, first_name, last_name, email, phone, username, role, password_hash, permissions, last_login, status, role_id, created_at, updated_at) VALUES (10, 'Genevieve', 'Hildah', 'hildah@dailyvaibe.com', '0734699433', NULL, 'moderator'::public.admin_role, '$2a$12$Jas31fk0T9AQKu41UJp6qOWId.g30j8jIQCfNQM2Ip.JGkEeggk/O', '{}'::jsonb, NULL, 'active'::public.user_status, NULL, '2026-01-22T18:28:46.502Z'::timestamp, '2026-01-24T17:05:14.496Z'::timestamp);

-- Update Sequences
-- Reset sequences to continue from current max values

SELECT setval('public.categories_category_id_seq', (SELECT COALESCE(MAX(category_id), 1) FROM public.categories), true);
SELECT setval('public.admins_admin_id_seq', (SELECT COALESCE(MAX(admin_id), 1) FROM public.admins), true);
