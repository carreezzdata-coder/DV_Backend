--
-- PostgreSQL database dump
--

\restrict qUcv2lqXS2yXrPZEeXBqxRoaCFxoUlcqVwKekmfQktI37cN0EX7JzwsQO5Ybx9U

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'WIN1252';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: admin_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.admin_role AS ENUM (
    'super_admin',
    'admin',
    'editor',
    'moderator'
);


ALTER TYPE public.admin_role OWNER TO postgres;

--
-- Name: attendance_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.attendance_status AS ENUM (
    'registered',
    'attended',
    'cancelled',
    'no_show'
);


ALTER TYPE public.attendance_status OWNER TO postgres;

--
-- Name: availability_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.availability_type AS ENUM (
    'weekdays',
    'weekends',
    'both',
    'flexible'
);


ALTER TYPE public.availability_type OWNER TO postgres;

--
-- Name: breaking_priority; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.breaking_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


ALTER TYPE public.breaking_priority OWNER TO postgres;

--
-- Name: comment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.comment_status AS ENUM (
    'pending',
    'approved',
    'rejected',
    'spam'
);


ALTER TYPE public.comment_status OWNER TO postgres;

--
-- Name: donation_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.donation_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded'
);


ALTER TYPE public.donation_status OWNER TO postgres;

--
-- Name: media_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.media_type AS ENUM (
    'image',
    'video',
    'document'
);


ALTER TYPE public.media_type OWNER TO postgres;

--
-- Name: news_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.news_status AS ENUM (
    'draft',
    'published',
    'archived'
);


ALTER TYPE public.news_status OWNER TO postgres;

--
-- Name: notification_priority; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_priority AS ENUM (
    'low',
    'medium',
    'high',
    'urgent'
);


ALTER TYPE public.notification_priority OWNER TO postgres;

--
-- Name: notification_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.notification_type AS ENUM (
    'new_user',
    'new_comment',
    'content_report',
    'system_alert',
    'breaking_news',
    'donation_received'
);


ALTER TYPE public.notification_type OWNER TO postgres;

--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method AS ENUM (
    'mpesa',
    'card',
    'paypal',
    'bank'
);


ALTER TYPE public.payment_method OWNER TO postgres;

--
-- Name: pin_type_enum; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.pin_type_enum AS ENUM (
    'gold',
    'silver',
    'bronze'
);


ALTER TYPE public.pin_type_enum OWNER TO postgres;

--
-- Name: reaction_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.reaction_type AS ENUM (
    'like'
);


ALTER TYPE public.reaction_type OWNER TO postgres;

--
-- Name: referral_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.referral_status AS ENUM (
    'pending',
    'completed',
    'expired'
);


ALTER TYPE public.referral_status OWNER TO postgres;

--
-- Name: share_platform; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.share_platform AS ENUM (
    'facebook',
    'twitter',
    'linkedin',
    'whatsapp',
    'telegram',
    'email',
    'copy'
);


ALTER TYPE public.share_platform OWNER TO postgres;

--
-- Name: subscriber_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.subscriber_status AS ENUM (
    'active',
    'inactive',
    'pending'
);


ALTER TYPE public.subscriber_status OWNER TO postgres;

--
-- Name: target_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.target_type AS ENUM (
    'news',
    'user',
    'comment',
    'category',
    'system',
    'settings'
);


ALTER TYPE public.target_type OWNER TO postgres;

--
-- Name: user_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_status AS ENUM (
    'active',
    'suspended',
    'deactivated'
);


ALTER TYPE public.user_status OWNER TO postgres;

--
-- Name: volunteer_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.volunteer_status AS ENUM (
    'active',
    'inactive',
    'pending'
);


ALTER TYPE public.volunteer_status OWNER TO postgres;

--
-- Name: archive_cookie_stats_monthly(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.archive_cookie_stats_monthly() RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.archive_cookie_stats_monthly() OWNER TO postgres;

--
-- Name: FUNCTION archive_cookie_stats_monthly(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.archive_cookie_stats_monthly() IS 'Archive old daily stats to monthly summary and cleanup';


--
-- Name: archive_daily_stats(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.archive_daily_stats() RETURNS TABLE(archived_count integer)
    LANGUAGE plpgsql
    AS $$
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
      $$;


ALTER FUNCTION public.archive_daily_stats() OWNER TO postgres;

--
-- Name: cleanup_old_devices(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.cleanup_old_devices() RETURNS TABLE(deleted_count integer)
    LANGUAGE plpgsql
    AS $$
      DECLARE
        v_deleted INTEGER;
      BEGIN
        DELETE FROM device_registry WHERE last_seen < NOW() - INTERVAL '90 days';
        GET DIAGNOSTICS v_deleted = ROW_COUNT;
        RETURN QUERY SELECT v_deleted;
      END;
      $$;


ALTER FUNCTION public.cleanup_old_devices() OWNER TO postgres;

--
-- Name: generate_oembed_url(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generate_oembed_url() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
      $$;


ALTER FUNCTION public.generate_oembed_url() OWNER TO postgres;

--
-- Name: reset_daily_counts(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reset_daily_counts() RETURNS void
    LANGUAGE plpgsql
    AS $$
      BEGIN
        UPDATE active_location_counts SET active_today = 0 WHERE last_updated < CURRENT_DATE;
      END;
      $$;


ALTER FUNCTION public.reset_daily_counts() OWNER TO postgres;

--
-- Name: update_breaking_until(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_breaking_until() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF NEW.breaking = true AND NEW.breaking_until IS NULL AND NEW.published_at IS NOT NULL THEN
          NEW.breaking_until := NEW.published_at + INTERVAL '9 hours';
        END IF;
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_breaking_until() OWNER TO postgres;

--
-- Name: update_cookie_stats_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_cookie_stats_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_cookie_stats_timestamp() OWNER TO postgres;

--
-- Name: update_featured_until(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_featured_until() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF NEW.featured = true AND NEW.featured_until IS NULL AND NEW.published_at IS NOT NULL THEN
          NEW.featured_until := NEW.published_at + INTERVAL '72 hours';
        END IF;
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_featured_until() OWNER TO postgres;

--
-- Name: update_news_quotes_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_news_quotes_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_news_quotes_updated_at_column() OWNER TO postgres;

--
-- Name: update_social_media_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_social_media_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_social_media_timestamp() OWNER TO postgres;

--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_timestamp() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_location_counts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.active_location_counts (
    location_id integer NOT NULL,
    county character varying(255),
    town character varying(255),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    active_now integer DEFAULT 0,
    active_today integer DEFAULT 0,
    total_registered integer DEFAULT 0,
    last_activity timestamp with time zone DEFAULT now(),
    last_updated timestamp with time zone DEFAULT now(),
    CONSTRAINT active_counts_category_check CHECK (((category)::text = ANY ((ARRAY['KENYA'::character varying, 'EAST_AFRICA'::character varying, 'AFRICA'::character varying, 'GLOBAL'::character varying, 'UNKNOWN'::character varying])::text[])))
);


ALTER TABLE public.active_location_counts OWNER TO postgres;

--
-- Name: TABLE active_location_counts; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.active_location_counts IS 'Real-time location counts - updated not inserted';


--
-- Name: COLUMN active_location_counts.active_now; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.active_location_counts.active_now IS 'Devices active in last 15 minutes';


--
-- Name: COLUMN active_location_counts.active_today; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.active_location_counts.active_today IS 'Unique devices active today';


--
-- Name: COLUMN active_location_counts.total_registered; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.active_location_counts.total_registered IS 'All-time registered devices from this location';


--
-- Name: active_location_counts_location_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.active_location_counts_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.active_location_counts_location_id_seq OWNER TO postgres;

--
-- Name: active_location_counts_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.active_location_counts_location_id_seq OWNED BY public.active_location_counts.location_id;


--
-- Name: active_locations_now; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.active_locations_now AS
 SELECT county,
    town,
    category,
    active_now,
    active_today,
    last_activity
   FROM public.active_location_counts
  WHERE (active_now > 0)
  ORDER BY active_now DESC, county;


ALTER VIEW public.active_locations_now OWNER TO postgres;

--
-- Name: activity_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_log (
    activity_id integer NOT NULL,
    user_id integer,
    admin_id integer,
    action character varying(255) NOT NULL,
    details text,
    ip_address inet,
    user_agent character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.activity_log OWNER TO postgres;

--
-- Name: activity_log_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_log_activity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_log_activity_id_seq OWNER TO postgres;

--
-- Name: activity_log_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activity_log_activity_id_seq OWNED BY public.activity_log.activity_id;


--
-- Name: ad_clicks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_clicks (
    click_id integer NOT NULL,
    ad_id integer NOT NULL,
    session_id character varying(255),
    county character varying(100),
    town character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ad_clicks OWNER TO postgres;

--
-- Name: ad_clicks_click_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_clicks_click_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ad_clicks_click_id_seq OWNER TO postgres;

--
-- Name: ad_clicks_click_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_clicks_click_id_seq OWNED BY public.ad_clicks.click_id;


--
-- Name: ad_impressions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_impressions (
    impression_id integer NOT NULL,
    ad_id integer NOT NULL,
    session_id character varying(255),
    county character varying(100),
    town character varying(100),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ad_impressions OWNER TO postgres;

--
-- Name: ad_impressions_impression_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_impressions_impression_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ad_impressions_impression_id_seq OWNER TO postgres;

--
-- Name: ad_impressions_impression_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_impressions_impression_id_seq OWNED BY public.ad_impressions.impression_id;


--
-- Name: ad_tiers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_tiers (
    tier_id integer NOT NULL,
    tier_name character varying(50) NOT NULL,
    price_per_month numeric(10,2) NOT NULL,
    price_per_year numeric(10,2) NOT NULL,
    max_ads integer NOT NULL,
    priority_level integer NOT NULL,
    features jsonb DEFAULT '{}'::jsonb,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ad_tiers OWNER TO postgres;

--
-- Name: ad_tiers_tier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ad_tiers_tier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ad_tiers_tier_id_seq OWNER TO postgres;

--
-- Name: ad_tiers_tier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ad_tiers_tier_id_seq OWNED BY public.ad_tiers.tier_id;


--
-- Name: admin_activity_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_activity_log (
    log_id integer NOT NULL,
    admin_id integer NOT NULL,
    action character varying(100) NOT NULL,
    target_type public.target_type NOT NULL,
    target_id integer,
    details text,
    ip_address inet,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_activity_log OWNER TO postgres;

--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_activity_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_activity_log_log_id_seq OWNER TO postgres;

--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_activity_log_log_id_seq OWNED BY public.admin_activity_log.log_id;


--
-- Name: admin_chat_messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_chat_messages (
    message_id integer NOT NULL,
    sender_id integer NOT NULL,
    sender_name character varying(200) NOT NULL,
    receiver_id integer,
    message_text text NOT NULL,
    is_broadcast boolean DEFAULT false,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_chat_messages OWNER TO postgres;

--
-- Name: admin_chat_messages_message_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_chat_messages_message_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_chat_messages_message_id_seq OWNER TO postgres;

--
-- Name: admin_chat_messages_message_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_chat_messages_message_id_seq OWNED BY public.admin_chat_messages.message_id;


--
-- Name: admin_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_notifications (
    notification_id integer NOT NULL,
    admin_id integer,
    type public.notification_type NOT NULL,
    title character varying(200) NOT NULL,
    message text NOT NULL,
    data jsonb,
    is_read boolean DEFAULT false,
    priority public.notification_priority DEFAULT 'medium'::public.notification_priority,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_notifications OWNER TO postgres;

--
-- Name: admin_notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_notifications_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_notifications_notification_id_seq OWNER TO postgres;

--
-- Name: admin_notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_notifications_notification_id_seq OWNED BY public.admin_notifications.notification_id;


--
-- Name: admin_online_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_online_status (
    admin_id integer NOT NULL,
    last_active timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    is_online boolean DEFAULT true,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_online_status OWNER TO postgres;

--
-- Name: admin_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_permissions (
    permission_id integer NOT NULL,
    admin_id integer NOT NULL,
    permission_name character varying(100) NOT NULL,
    resource_type character varying(50),
    can_create boolean DEFAULT false,
    can_read boolean DEFAULT true,
    can_update boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admin_permissions OWNER TO postgres;

--
-- Name: admin_permissions_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admin_permissions_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_permissions_permission_id_seq OWNER TO postgres;

--
-- Name: admin_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admin_permissions_permission_id_seq OWNED BY public.admin_permissions.permission_id;


--
-- Name: admin_session_store; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_session_store (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.admin_session_store OWNER TO postgres;

--
-- Name: admin_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admin_sessions (
    session_id character varying(128) NOT NULL,
    admin_id integer NOT NULL,
    ip_address inet,
    user_agent character varying(500),
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE public.admin_sessions OWNER TO postgres;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.admins (
    admin_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    username character varying(50),
    role public.admin_role DEFAULT 'admin'::public.admin_role,
    password_hash character varying(255) NOT NULL,
    permissions jsonb,
    last_login timestamp without time zone,
    status public.user_status DEFAULT 'active'::public.user_status,
    role_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.admins OWNER TO postgres;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.admins_admin_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admins_admin_id_seq OWNER TO postgres;

--
-- Name: admins_admin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.admins_admin_id_seq OWNED BY public.admins.admin_id;


--
-- Name: advertisements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advertisements (
    ad_id integer NOT NULL,
    advertiser_id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    image_url character varying(500),
    link_url character varying(500),
    target_counties character varying(100)[],
    target_towns character varying(100)[],
    placement character varying(50) NOT NULL,
    priority integer DEFAULT 0,
    impressions integer DEFAULT 0,
    clicks integer DEFAULT 0,
    status character varying(20) DEFAULT 'active'::character varying,
    start_date timestamp without time zone DEFAULT now(),
    end_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT advertisements_placement_check CHECK (((placement)::text = ANY ((ARRAY['banner'::character varying, 'sidebar'::character varying, 'inline'::character varying, 'popup'::character varying, 'floating'::character varying])::text[]))),
    CONSTRAINT advertisements_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'paused'::character varying, 'expired'::character varying, 'rejected'::character varying])::text[])))
);


ALTER TABLE public.advertisements OWNER TO postgres;

--
-- Name: advertisements_ad_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advertisements_ad_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advertisements_ad_id_seq OWNER TO postgres;

--
-- Name: advertisements_ad_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advertisements_ad_id_seq OWNED BY public.advertisements.ad_id;


--
-- Name: advertisers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advertisers (
    advertiser_id integer NOT NULL,
    company_name character varying(200) NOT NULL,
    contact_person character varying(200) NOT NULL,
    email character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    county character varying(100),
    town character varying(100),
    address text,
    tier_id integer,
    subscription_start timestamp without time zone,
    subscription_end timestamp without time zone,
    auto_renew boolean DEFAULT false,
    status character varying(20) DEFAULT 'active'::character varying,
    total_spent numeric(12,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT advertisers_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'suspended'::character varying, 'expired'::character varying])::text[])))
);


ALTER TABLE public.advertisers OWNER TO postgres;

--
-- Name: advertisers_advertiser_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.advertisers_advertiser_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.advertisers_advertiser_id_seq OWNER TO postgres;

--
-- Name: advertisers_advertiser_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.advertisers_advertiser_id_seq OWNED BY public.advertisers.advertiser_id;


--
-- Name: analytics_daily; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytics_daily (
    analytics_id integer NOT NULL,
    date date NOT NULL,
    total_views integer DEFAULT 0,
    unique_visitors integer DEFAULT 0,
    total_users integer DEFAULT 0,
    new_users integer DEFAULT 0,
    total_news integer DEFAULT 0,
    published_news integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.analytics_daily OWNER TO postgres;

--
-- Name: analytics_daily_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytics_daily_analytics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analytics_daily_analytics_id_seq OWNER TO postgres;

--
-- Name: analytics_daily_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytics_daily_analytics_id_seq OWNED BY public.analytics_daily.analytics_id;


--
-- Name: analytics_monthly; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.analytics_monthly (
    analytics_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    total_views integer DEFAULT 0,
    unique_visitors integer DEFAULT 0,
    total_users integer DEFAULT 0,
    new_users integer DEFAULT 0,
    total_news integer DEFAULT 0,
    published_news integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.analytics_monthly OWNER TO postgres;

--
-- Name: analytics_monthly_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.analytics_monthly_analytics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.analytics_monthly_analytics_id_seq OWNER TO postgres;

--
-- Name: analytics_monthly_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.analytics_monthly_analytics_id_seq OWNED BY public.analytics_monthly.analytics_id;


--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.bookmarks (
    bookmark_id integer NOT NULL,
    user_id integer NOT NULL,
    news_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.bookmarks OWNER TO postgres;

--
-- Name: bookmarks_bookmark_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.bookmarks_bookmark_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.bookmarks_bookmark_id_seq OWNER TO postgres;

--
-- Name: bookmarks_bookmark_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.bookmarks_bookmark_id_seq OWNED BY public.bookmarks.bookmark_id;


--
-- Name: breaking_news; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.breaking_news (
    breaking_id integer NOT NULL,
    news_id integer NOT NULL,
    priority public.breaking_priority DEFAULT 'medium'::public.breaking_priority,
    display_until timestamp without time zone,
    active boolean DEFAULT true,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.breaking_news OWNER TO postgres;

--
-- Name: breaking_news_breaking_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.breaking_news_breaking_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.breaking_news_breaking_id_seq OWNER TO postgres;

--
-- Name: breaking_news_breaking_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.breaking_news_breaking_id_seq OWNED BY public.breaking_news.breaking_id;


--
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    category_id integer NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(100) NOT NULL,
    description text,
    color character varying(7),
    icon character varying(50),
    parent_id integer,
    order_index integer DEFAULT 0,
    active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- Name: categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categories_category_id_seq OWNER TO postgres;

--
-- Name: categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categories_category_id_seq OWNED BY public.categories.category_id;


--
-- Name: cleanup_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cleanup_history (
    cleanup_id integer NOT NULL,
    type character varying(20) NOT NULL,
    public_sessions integer DEFAULT 0,
    admin_sessions integer DEFAULT 0,
    user_sessions integer DEFAULT 0,
    total_sessions integer DEFAULT 0,
    duration integer,
    status character varying(20),
    error_message text,
    triggered_by character varying(50),
    cleaned_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.cleanup_history OWNER TO postgres;

--
-- Name: cleanup_history_cleanup_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cleanup_history_cleanup_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cleanup_history_cleanup_id_seq OWNER TO postgres;

--
-- Name: cleanup_history_cleanup_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cleanup_history_cleanup_id_seq OWNED BY public.cleanup_history.cleanup_id;


--
-- Name: cloudflare_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cloudflare_images (
    image_id integer NOT NULL,
    cloudflare_id character varying(255) NOT NULL,
    filename character varying(255) NOT NULL,
    original_url text,
    variants jsonb,
    uploaded_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.cloudflare_images OWNER TO postgres;

--
-- Name: cloudflare_images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cloudflare_images_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cloudflare_images_image_id_seq OWNER TO postgres;

--
-- Name: cloudflare_images_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cloudflare_images_image_id_seq OWNED BY public.cloudflare_images.image_id;


--
-- Name: cookie_stats_daily; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cookie_stats_daily (
    stat_id integer NOT NULL,
    stat_date date DEFAULT CURRENT_DATE NOT NULL,
    county character varying(100),
    town character varying(100),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying,
    total_consents integer DEFAULT 0,
    accepted_count integer DEFAULT 0,
    rejected_count integer DEFAULT 0,
    functional_enabled integer DEFAULT 0,
    analytics_enabled integer DEFAULT 0,
    marketing_enabled integer DEFAULT 0,
    personalization_enabled integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.cookie_stats_daily OWNER TO postgres;

--
-- Name: TABLE cookie_stats_daily; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cookie_stats_daily IS 'Aggregated daily cookie consent statistics - NO individual records';


--
-- Name: cookie_stats_daily_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cookie_stats_daily_stat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cookie_stats_daily_stat_id_seq OWNER TO postgres;

--
-- Name: cookie_stats_daily_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cookie_stats_daily_stat_id_seq OWNED BY public.cookie_stats_daily.stat_id;


--
-- Name: cookie_stats_monthly; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cookie_stats_monthly (
    stat_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    county character varying(100),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying,
    total_consents integer DEFAULT 0,
    accepted_count integer DEFAULT 0,
    rejected_count integer DEFAULT 0,
    avg_acceptance_rate numeric(5,2),
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT month_check CHECK (((month >= 1) AND (month <= 12)))
);


ALTER TABLE public.cookie_stats_monthly OWNER TO postgres;

--
-- Name: TABLE cookie_stats_monthly; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.cookie_stats_monthly IS 'Archived monthly cookie statistics';


--
-- Name: cookie_stats_monthly_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cookie_stats_monthly_stat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cookie_stats_monthly_stat_id_seq OWNER TO postgres;

--
-- Name: cookie_stats_monthly_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cookie_stats_monthly_stat_id_seq OWNED BY public.cookie_stats_monthly.stat_id;


--
-- Name: daily_location_stats; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.daily_location_stats (
    stat_id integer NOT NULL,
    stat_date date NOT NULL,
    county character varying(255),
    town character varying(255),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    new_devices integer DEFAULT 0,
    returning_devices integer DEFAULT 0,
    total_devices integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT daily_stats_category_check CHECK (((category)::text = ANY ((ARRAY['KENYA'::character varying, 'EAST_AFRICA'::character varying, 'AFRICA'::character varying, 'GLOBAL'::character varying, 'UNKNOWN'::character varying])::text[])))
);


ALTER TABLE public.daily_location_stats OWNER TO postgres;

--
-- Name: TABLE daily_location_stats; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.daily_location_stats IS 'Daily aggregated counts per location - no individual records';


--
-- Name: COLUMN daily_location_stats.new_devices; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.daily_location_stats.new_devices IS 'New unique devices that day';


--
-- Name: COLUMN daily_location_stats.returning_devices; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.daily_location_stats.returning_devices IS 'Previously seen devices that returned';


--
-- Name: COLUMN daily_location_stats.total_devices; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.daily_location_stats.total_devices IS 'Total unique devices that day';


--
-- Name: daily_location_stats_stat_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.daily_location_stats_stat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.daily_location_stats_stat_id_seq OWNER TO postgres;

--
-- Name: daily_location_stats_stat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.daily_location_stats_stat_id_seq OWNED BY public.daily_location_stats.stat_id;


--
-- Name: device_registry; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.device_registry (
    device_id character varying(255) NOT NULL,
    county character varying(255),
    town character varying(255),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    registered_at timestamp with time zone DEFAULT now(),
    last_seen timestamp with time zone DEFAULT now(),
    CONSTRAINT device_registry_category_check CHECK (((category)::text = ANY ((ARRAY['KENYA'::character varying, 'EAST_AFRICA'::character varying, 'AFRICA'::character varying, 'GLOBAL'::character varying, 'UNKNOWN'::character varying])::text[])))
);


ALTER TABLE public.device_registry OWNER TO postgres;

--
-- Name: TABLE device_registry; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.device_registry IS 'One-time device registration - stores device_id only, no session data';


--
-- Name: donations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.donations (
    donation_id integer NOT NULL,
    user_id integer,
    donor_name character varying(200),
    donor_email character varying(150),
    amount numeric(10,2) NOT NULL,
    payment_method public.payment_method NOT NULL,
    transaction_ref character varying(100),
    status public.donation_status DEFAULT 'pending'::public.donation_status,
    donated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.donations OWNER TO postgres;

--
-- Name: donations_donation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.donations_donation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.donations_donation_id_seq OWNER TO postgres;

--
-- Name: donations_donation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.donations_donation_id_seq OWNED BY public.donations.donation_id;


--
-- Name: email_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_queue (
    queue_id integer NOT NULL,
    recipient_email character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    body text NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying,
    attempts integer DEFAULT 0,
    last_error text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    sent_at timestamp without time zone,
    CONSTRAINT email_queue_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.email_queue OWNER TO postgres;

--
-- Name: email_queue_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_queue_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_queue_queue_id_seq OWNER TO postgres;

--
-- Name: email_queue_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_queue_queue_id_seq OWNED BY public.email_queue.queue_id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news (
    news_id integer NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    excerpt text,
    slug character varying(200),
    category_id integer,
    category_ids integer[],
    author_id integer,
    image_url character varying(500),
    processed_content text,
    quotes_data jsonb,
    quote_sayer text,
    quote_position integer DEFAULT 0,
    views integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    status public.news_status DEFAULT 'draft'::public.news_status,
    workflow_status character varying(20) DEFAULT 'draft'::character varying,
    requires_approval boolean DEFAULT true,
    priority character varying(10) DEFAULT 'medium'::character varying,
    featured boolean DEFAULT false,
    featured_until timestamp without time zone,
    submitted_at timestamp without time zone,
    approved_by integer,
    approved_at timestamp without time zone,
    rejected_by integer,
    rejected_at timestamp without time zone,
    rejection_reason text,
    tags text,
    meta_description text,
    seo_keywords text,
    reading_time integer,
    published_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    breaking boolean DEFAULT false,
    breaking_until timestamp without time zone,
    pinned boolean DEFAULT false,
    pin_type public.pin_type_enum,
    pin_until timestamp without time zone,
    featured_hours integer DEFAULT 72,
    breaking_hours integer DEFAULT 9,
    CONSTRAINT news_priority_check CHECK (((priority)::text = ANY ((ARRAY['high'::character varying, 'medium'::character varying, 'short'::character varying])::text[]))),
    CONSTRAINT news_workflow_status_check CHECK (((workflow_status)::text = ANY ((ARRAY['draft'::character varying, 'pending_review'::character varying, 'approved'::character varying, 'rejected'::character varying, 'published'::character varying])::text[])))
);


ALTER TABLE public.news OWNER TO postgres;

--
-- Name: COLUMN news.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.priority IS 'Article priority: high, medium, or low';


--
-- Name: COLUMN news.breaking; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.breaking IS 'Flag to mark article as breaking news';


--
-- Name: COLUMN news.breaking_until; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.breaking_until IS 'Timestamp when breaking news flag expires';


--
-- Name: COLUMN news.pinned; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.pinned IS 'Whether article is pinned to top of homepage';


--
-- Name: COLUMN news.pin_type; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.pin_type IS 'Pin tier: gold (72h, max 2), silver (48h, max 4), bronze (48h, max 6)';


--
-- Name: COLUMN news.pin_until; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.pin_until IS 'Timestamp when pin expires';


--
-- Name: COLUMN news.featured_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.featured_hours IS 'Duration in hours for featured status';


--
-- Name: COLUMN news.breaking_hours; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.breaking_hours IS 'Duration in hours for breaking news status';


--
-- Name: news_social_media; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_social_media (
    social_media_id integer NOT NULL,
    news_id integer NOT NULL,
    platform character varying(50) NOT NULL,
    post_type character varying(50) NOT NULL,
    post_url text NOT NULL,
    post_id character varying(255),
    embed_code text,
    embed_html text,
    oembed_url text,
    author_name character varying(255),
    author_handle character varying(255),
    author_avatar_url text,
    post_text text,
    post_date timestamp with time zone,
    thumbnail_url text,
    media_url text,
    media_urls jsonb DEFAULT '[]'::jsonb,
    duration integer,
    dimensions jsonb,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    shares_count integer DEFAULT 0,
    views_count integer DEFAULT 0,
    saves_count integer DEFAULT 0,
    display_order integer DEFAULT 0,
    is_featured boolean DEFAULT false,
    show_full_embed boolean DEFAULT true,
    auto_embed boolean DEFAULT true,
    caption text,
    hashtags text[] DEFAULT '{}'::text[],
    mentions text[] DEFAULT '{}'::text[],
    location character varying(255),
    metadata jsonb DEFAULT '{}'::jsonb,
    oembed_data jsonb,
    raw_api_response jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_fetched_at timestamp with time zone,
    CONSTRAINT news_social_media_platform_check CHECK (((platform)::text = ANY ((ARRAY['youtube_video'::character varying, 'youtube_short'::character varying, 'twitter_post'::character varying, 'twitter_video'::character varying, 'x_post'::character varying, 'x_video'::character varying, 'instagram_post'::character varying, 'instagram_reel'::character varying, 'instagram_video'::character varying, 'facebook_post'::character varying, 'facebook_video'::character varying, 'facebook_reel'::character varying, 'tiktok_video'::character varying, 'tiktok_reel'::character varying, 'linkedin_post'::character varying, 'threads_post'::character varying, 'whatsapp_status'::character varying])::text[]))),
    CONSTRAINT news_social_media_post_type_check CHECK (((post_type)::text = ANY ((ARRAY['post'::character varying, 'reel'::character varying, 'video'::character varying, 'short'::character varying, 'story'::character varying, 'status'::character varying])::text[])))
);


ALTER TABLE public.news_social_media OWNER TO postgres;

--
-- Name: embedded_social_posts; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.embedded_social_posts AS
 SELECT sm.social_media_id,
    sm.news_id,
    sm.platform,
    sm.post_type,
    sm.post_url,
    sm.post_id,
    sm.embed_code,
    sm.embed_html,
    sm.oembed_url,
    sm.author_name,
    sm.author_handle,
    sm.author_avatar_url,
    sm.post_text,
    sm.post_date,
    sm.thumbnail_url,
    sm.media_url,
    sm.media_urls,
    sm.duration,
    sm.dimensions,
    sm.likes_count,
    sm.comments_count,
    sm.shares_count,
    sm.views_count,
    sm.saves_count,
    sm.display_order,
    sm.is_featured,
    sm.show_full_embed,
    sm.auto_embed,
    sm.caption,
    sm.hashtags,
    sm.mentions,
    sm.location,
    sm.metadata,
    sm.oembed_data,
    sm.raw_api_response,
    sm.created_at,
    sm.updated_at,
    sm.last_fetched_at,
    n.title AS article_title,
    n.slug AS article_slug,
    COALESCE(sm.embed_html,
        CASE
            WHEN ((sm.platform)::text ~~ 'facebook%'::text) THEN (('<div class="fb-post" data-href="'::text || sm.post_url) || '"></div>'::text)
            WHEN (((sm.platform)::text ~~ 'twitter%'::text) OR ((sm.platform)::text ~~ 'x_%'::text)) THEN (('<blockquote class="twitter-tweet"><a href="'::text || sm.post_url) || '"></a></blockquote>'::text)
            WHEN ((sm.platform)::text ~~ 'instagram%'::text) THEN (('<blockquote class="instagram-media" data-instgrm-permalink="'::text || sm.post_url) || '"></blockquote>'::text)
            ELSE NULL::text
        END) AS generated_embed_html
   FROM (public.news_social_media sm
     JOIN public.news n ON ((sm.news_id = n.news_id)))
  WHERE (sm.show_full_embed = true);


ALTER VIEW public.embedded_social_posts OWNER TO postgres;

--
-- Name: event_registrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.event_registrations (
    registration_id integer NOT NULL,
    event_id integer NOT NULL,
    user_id integer,
    name character varying(200),
    email character varying(150),
    phone character varying(20),
    attendance_status public.attendance_status DEFAULT 'registered'::public.attendance_status,
    registered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.event_registrations OWNER TO postgres;

--
-- Name: event_registrations_registration_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.event_registrations_registration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.event_registrations_registration_id_seq OWNER TO postgres;

--
-- Name: event_registrations_registration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.event_registrations_registration_id_seq OWNED BY public.event_registrations.registration_id;


--
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    event_id integer NOT NULL,
    title character varying(200) NOT NULL,
    description text,
    event_date date NOT NULL,
    event_time time without time zone,
    location character varying(200),
    image_url character varying(500),
    max_attendees integer,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: events_event_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.events_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.events_event_id_seq OWNER TO postgres;

--
-- Name: events_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.events_event_id_seq OWNED BY public.events.event_id;


--
-- Name: image_variants; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.image_variants (
    variant_id integer NOT NULL,
    parent_image_id integer,
    variant_name character varying(50) NOT NULL,
    variant_url text NOT NULL,
    width integer,
    height integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.image_variants OWNER TO postgres;

--
-- Name: image_variants_variant_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.image_variants_variant_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.image_variants_variant_id_seq OWNER TO postgres;

--
-- Name: image_variants_variant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.image_variants_variant_id_seq OWNED BY public.image_variants.variant_id;


--
-- Name: media_files; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.media_files (
    file_id integer NOT NULL,
    filename character varying(255) NOT NULL,
    original_name character varying(255),
    file_path text NOT NULL,
    file_type character varying(50),
    file_size bigint,
    mime_type character varying(100),
    storage_provider character varying(50) DEFAULT 'local'::character varying,
    cloudflare_id character varying(255),
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.media_files OWNER TO postgres;

--
-- Name: media_files_file_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.media_files_file_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.media_files_file_id_seq OWNER TO postgres;

--
-- Name: media_files_file_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.media_files_file_id_seq OWNED BY public.media_files.file_id;


--
-- Name: monthly_location_summary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.monthly_location_summary (
    summary_id integer NOT NULL,
    year integer NOT NULL,
    month integer NOT NULL,
    county character varying(255),
    town character varying(255),
    category character varying(50) DEFAULT 'UNKNOWN'::character varying NOT NULL,
    total_devices integer DEFAULT 0,
    unique_devices integer DEFAULT 0,
    avg_daily_devices integer DEFAULT 0,
    peak_daily_devices integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT monthly_summary_category_check CHECK (((category)::text = ANY ((ARRAY['KENYA'::character varying, 'EAST_AFRICA'::character varying, 'AFRICA'::character varying, 'GLOBAL'::character varying, 'UNKNOWN'::character varying])::text[]))),
    CONSTRAINT monthly_summary_month_check CHECK (((month >= 1) AND (month <= 12)))
);


ALTER TABLE public.monthly_location_summary OWNER TO postgres;

--
-- Name: TABLE monthly_location_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.monthly_location_summary IS 'Monthly archives - compressed daily stats';


--
-- Name: monthly_location_summary_summary_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.monthly_location_summary_summary_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.monthly_location_summary_summary_id_seq OWNER TO postgres;

--
-- Name: monthly_location_summary_summary_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.monthly_location_summary_summary_id_seq OWNED BY public.monthly_location_summary.summary_id;


--
-- Name: news_approval_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_approval_history (
    approval_id integer NOT NULL,
    news_id integer NOT NULL,
    reviewer_id integer NOT NULL,
    action character varying(20) NOT NULL,
    comments text,
    previous_status character varying(20),
    new_status character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_approval_history_action_check CHECK (((action)::text = ANY ((ARRAY['submit'::character varying, 'approve'::character varying, 'reject'::character varying, 'request_changes'::character varying])::text[])))
);


ALTER TABLE public.news_approval_history OWNER TO postgres;

--
-- Name: news_approval_history_approval_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_approval_history_approval_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_approval_history_approval_id_seq OWNER TO postgres;

--
-- Name: news_approval_history_approval_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_approval_history_approval_id_seq OWNED BY public.news_approval_history.approval_id;


--
-- Name: news_categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_categories (
    news_category_id integer NOT NULL,
    news_id integer NOT NULL,
    category_id integer NOT NULL,
    is_primary boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.news_categories OWNER TO postgres;

--
-- Name: news_categories_news_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_categories_news_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_categories_news_category_id_seq OWNER TO postgres;

--
-- Name: news_categories_news_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_categories_news_category_id_seq OWNED BY public.news_categories.news_category_id;


--
-- Name: news_comments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_comments (
    comment_id integer NOT NULL,
    news_id integer NOT NULL,
    user_id integer,
    parent_id integer,
    author_name character varying(100),
    author_email character varying(150),
    comment_text text NOT NULL,
    status public.comment_status DEFAULT 'pending'::public.comment_status,
    ip_address inet,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.news_comments OWNER TO postgres;

--
-- Name: news_comments_comment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_comments_comment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_comments_comment_id_seq OWNER TO postgres;

--
-- Name: news_comments_comment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_comments_comment_id_seq OWNED BY public.news_comments.comment_id;


--
-- Name: news_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_images (
    image_id integer NOT NULL,
    news_id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    image_caption text,
    alt_text text,
    display_order integer DEFAULT 0,
    is_featured boolean DEFAULT false,
    width integer,
    height integer,
    file_size bigint,
    mime_type character varying(100),
    storage_provider character varying(20) DEFAULT 'local'::character varying,
    cloudflare_id character varying(255),
    cloudflare_variant character varying(50),
    metadata jsonb DEFAULT '{}'::jsonb,
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_images_storage_provider_check CHECK (((storage_provider)::text = ANY ((ARRAY['local'::character varying, 'cloudflare'::character varying, 's3'::character varying])::text[])))
);


ALTER TABLE public.news_images OWNER TO postgres;

--
-- Name: news_images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_images_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_images_image_id_seq OWNER TO postgres;

--
-- Name: news_images_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_images_image_id_seq OWNED BY public.news_images.image_id;


--
-- Name: news_news_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_news_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_news_id_seq OWNER TO postgres;

--
-- Name: news_news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_news_id_seq OWNED BY public.news.news_id;


--
-- Name: news_quotes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_quotes (
    quote_id integer NOT NULL,
    quote_text text NOT NULL,
    sayer_name character varying(255) NOT NULL,
    sayer_title character varying(255),
    image_url character varying(500),
    active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.news_quotes OWNER TO postgres;

--
-- Name: news_quotes_quote_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_quotes_quote_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_quotes_quote_id_seq OWNER TO postgres;

--
-- Name: news_quotes_quote_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_quotes_quote_id_seq OWNED BY public.news_quotes.quote_id;


--
-- Name: news_reactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_reactions (
    reaction_id integer NOT NULL,
    news_id integer NOT NULL,
    user_id integer,
    reaction_type public.reaction_type DEFAULT 'like'::public.reaction_type,
    ip_address inet,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.news_reactions OWNER TO postgres;

--
-- Name: news_reactions_reaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_reactions_reaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_reactions_reaction_id_seq OWNER TO postgres;

--
-- Name: news_reactions_reaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_reactions_reaction_id_seq OWNED BY public.news_reactions.reaction_id;


--
-- Name: news_shares; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_shares (
    share_id integer NOT NULL,
    news_id integer NOT NULL,
    platform public.share_platform NOT NULL,
    user_id integer,
    ip_address inet,
    shared_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.news_shares OWNER TO postgres;

--
-- Name: news_shares_share_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_shares_share_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_shares_share_id_seq OWNER TO postgres;

--
-- Name: news_shares_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_shares_share_id_seq OWNED BY public.news_shares.share_id;


--
-- Name: news_social_media_social_media_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_social_media_social_media_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_social_media_social_media_id_seq OWNER TO postgres;

--
-- Name: news_social_media_social_media_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_social_media_social_media_id_seq OWNED BY public.news_social_media.social_media_id;


--
-- Name: news_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_videos (
    video_id integer NOT NULL,
    news_id integer NOT NULL,
    platform character varying(50) NOT NULL,
    video_url text NOT NULL,
    embed_code text,
    caption text,
    thumbnail_url character varying(500),
    duration integer,
    display_order integer DEFAULT 0,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_videos_platform_check CHECK (((platform)::text = ANY ((ARRAY['facebook'::character varying, 'twitter'::character varying, 'youtube'::character varying, 'instagram'::character varying, 'tiktok'::character varying])::text[])))
);


ALTER TABLE public.news_videos OWNER TO postgres;

--
-- Name: news_videos_video_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_videos_video_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_videos_video_id_seq OWNER TO postgres;

--
-- Name: news_videos_video_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_videos_video_id_seq OWNED BY public.news_videos.video_id;


--
-- Name: newsletters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.newsletters (
    newsletter_id integer NOT NULL,
    title character varying(255) NOT NULL,
    content text NOT NULL,
    sent_to integer DEFAULT 0,
    status character varying(20) DEFAULT 'draft'::character varying,
    scheduled_at timestamp without time zone,
    sent_at timestamp without time zone,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT newsletters_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'scheduled'::character varying, 'sent'::character varying, 'failed'::character varying])::text[])))
);


ALTER TABLE public.newsletters OWNER TO postgres;

--
-- Name: newsletters_newsletter_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.newsletters_newsletter_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.newsletters_newsletter_id_seq OWNER TO postgres;

--
-- Name: newsletters_newsletter_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.newsletters_newsletter_id_seq OWNED BY public.newsletters.newsletter_id;


--
-- Name: page_views; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.page_views (
    view_id integer NOT NULL,
    page_url text NOT NULL,
    news_id integer,
    user_id integer,
    ip_address inet,
    user_agent text,
    referer text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.page_views OWNER TO postgres;

--
-- Name: page_views_view_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.page_views_view_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.page_views_view_id_seq OWNER TO postgres;

--
-- Name: page_views_view_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.page_views_view_id_seq OWNED BY public.page_views.view_id;


--
-- Name: pinned_articles; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.pinned_articles AS
 SELECT news_id,
    title,
    slug,
    excerpt,
    image_url,
    pinned,
    pin_type,
    pin_until,
    priority,
    published_at,
    views,
    likes_count,
    comments_count,
        CASE pin_type
            WHEN 'gold'::public.pin_type_enum THEN 1
            WHEN 'silver'::public.pin_type_enum THEN 2
            WHEN 'bronze'::public.pin_type_enum THEN 3
            ELSE 4
        END AS pin_order
   FROM public.news n
  WHERE ((status = 'published'::public.news_status) AND (pinned = true) AND ((pin_until IS NULL) OR (pin_until > now())))
  ORDER BY
        CASE pin_type
            WHEN 'gold'::public.pin_type_enum THEN 1
            WHEN 'silver'::public.pin_type_enum THEN 2
            WHEN 'bronze'::public.pin_type_enum THEN 3
            ELSE 4
        END, published_at DESC;


ALTER VIEW public.pinned_articles OWNER TO postgres;

--
-- Name: public_session_store; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.public_session_store (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.public_session_store OWNER TO postgres;

--
-- Name: referrals; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.referrals (
    referral_id integer NOT NULL,
    referrer_id integer NOT NULL,
    referred_id integer NOT NULL,
    status public.referral_status DEFAULT 'pending'::public.referral_status,
    reward_given boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.referrals OWNER TO postgres;

--
-- Name: referrals_referral_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.referrals_referral_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.referrals_referral_id_seq OWNER TO postgres;

--
-- Name: referrals_referral_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.referrals_referral_id_seq OWNED BY public.referrals.referral_id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role_permissions (
    permission_id integer NOT NULL,
    role_id integer NOT NULL,
    resource_type character varying(50) NOT NULL,
    resource_name character varying(100) NOT NULL,
    can_create boolean DEFAULT false,
    can_read boolean DEFAULT true,
    can_update boolean DEFAULT false,
    can_delete boolean DEFAULT false,
    can_publish boolean DEFAULT false,
    can_approve boolean DEFAULT false,
    additional_permissions jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.role_permissions OWNER TO postgres;

--
-- Name: role_permissions_permission_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_permissions_permission_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_permissions_permission_id_seq OWNER TO postgres;

--
-- Name: role_permissions_permission_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_permissions_permission_id_seq OWNED BY public.role_permissions.permission_id;


--
-- Name: scheduler_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scheduler_logs (
    log_id integer NOT NULL,
    event_type character varying(50) NOT NULL,
    event_data jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.scheduler_logs OWNER TO postgres;

--
-- Name: scheduler_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scheduler_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scheduler_logs_log_id_seq OWNER TO postgres;

--
-- Name: scheduler_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scheduler_logs_log_id_seq OWNED BY public.scheduler_logs.log_id;


--
-- Name: session_store; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.session_store (
    sid character varying NOT NULL,
    sess json NOT NULL,
    expire timestamp(6) without time zone NOT NULL
);


ALTER TABLE public.session_store OWNER TO postgres;

--
-- Name: social_embed_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.social_embed_cache (
    cache_id integer NOT NULL,
    post_url text NOT NULL,
    embed_html text,
    oembed_data jsonb,
    fetched_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp with time zone
);


ALTER TABLE public.social_embed_cache OWNER TO postgres;

--
-- Name: social_embed_cache_cache_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.social_embed_cache_cache_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.social_embed_cache_cache_id_seq OWNER TO postgres;

--
-- Name: social_embed_cache_cache_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.social_embed_cache_cache_id_seq OWNED BY public.social_embed_cache.cache_id;


--
-- Name: subscribers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers (
    subscriber_id integer NOT NULL,
    email character varying(150) NOT NULL,
    name character varying(200),
    status public.subscriber_status DEFAULT 'pending'::public.subscriber_status,
    preferences jsonb,
    subscribed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    confirmed_at timestamp without time zone,
    unsubscribed_at timestamp without time zone,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.subscribers OWNER TO postgres;

--
-- Name: subscribers_subscriber_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscribers_subscriber_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subscribers_subscriber_id_seq OWNER TO postgres;

--
-- Name: subscribers_subscriber_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscribers_subscriber_id_seq OWNED BY public.subscribers.subscriber_id;


--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_logs (
    log_id integer NOT NULL,
    log_level character varying(20) NOT NULL,
    log_message text NOT NULL,
    log_source character varying(100),
    log_data jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_logs OWNER TO postgres;

--
-- Name: system_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.system_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_logs_log_id_seq OWNER TO postgres;

--
-- Name: system_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.system_logs_log_id_seq OWNED BY public.system_logs.log_id;


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_settings (
    setting_id integer NOT NULL,
    setting_key character varying(100) NOT NULL,
    setting_value text,
    setting_type character varying(20) DEFAULT 'string'::character varying,
    description text,
    is_public boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_settings OWNER TO postgres;

--
-- Name: system_settings_setting_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.system_settings_setting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.system_settings_setting_id_seq OWNER TO postgres;

--
-- Name: system_settings_setting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.system_settings_setting_id_seq OWNED BY public.system_settings.setting_id;


--
-- Name: todays_location_stats; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.todays_location_stats AS
 SELECT county,
    town,
    category,
    sum(new_devices) AS new_today,
    sum(returning_devices) AS returning_today,
    sum(total_devices) AS total_today
   FROM public.daily_location_stats
  WHERE (stat_date = CURRENT_DATE)
  GROUP BY county, town, category
  ORDER BY (sum(total_devices)) DESC;


ALTER VIEW public.todays_location_stats OWNER TO postgres;

--
-- Name: top_counties; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.top_counties AS
 SELECT county,
    category,
    sum(total_registered) AS total_devices,
    sum(active_today) AS active_today,
    sum(active_now) AS active_now,
    count(DISTINCT town) AS unique_towns
   FROM public.active_location_counts
  WHERE ((county IS NOT NULL) AND ((county)::text <> 'Unknown'::text))
  GROUP BY county, category
  ORDER BY (sum(total_registered)) DESC
 LIMIT 50;


ALTER VIEW public.top_counties OWNER TO postgres;

--
-- Name: user_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_notifications (
    notification_id integer NOT NULL,
    user_id integer NOT NULL,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    type character varying(50) DEFAULT 'general'::character varying,
    link text,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_notifications OWNER TO postgres;

--
-- Name: user_notifications_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_notifications_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_notifications_notification_id_seq OWNER TO postgres;

--
-- Name: user_notifications_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_notifications_notification_id_seq OWNED BY public.user_notifications.notification_id;


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_preferences (
    preference_id integer NOT NULL,
    user_id integer NOT NULL,
    preferred_categories integer[],
    notification_settings jsonb DEFAULT '{"sms": false, "push": true, "email": true}'::jsonb,
    language character varying(10) DEFAULT 'en'::character varying,
    theme character varying(20) DEFAULT 'light'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_preferences OWNER TO postgres;

--
-- Name: user_preferences_preference_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_preferences_preference_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_preferences_preference_id_seq OWNER TO postgres;

--
-- Name: user_preferences_preference_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_preferences_preference_id_seq OWNED BY public.user_preferences.preference_id;


--
-- Name: user_reading_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_reading_history (
    history_id integer NOT NULL,
    user_id integer NOT NULL,
    news_id integer NOT NULL,
    read_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    read_duration integer,
    read_percentage integer DEFAULT 0
);


ALTER TABLE public.user_reading_history OWNER TO postgres;

--
-- Name: user_reading_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_reading_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_reading_history_history_id_seq OWNER TO postgres;

--
-- Name: user_reading_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_reading_history_history_id_seq OWNED BY public.user_reading_history.history_id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_roles (
    role_id integer NOT NULL,
    role_name character varying(50) NOT NULL,
    role_slug character varying(50) NOT NULL,
    description text,
    permissions jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_roles OWNER TO postgres;

--
-- Name: user_roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_roles_role_id_seq OWNER TO postgres;

--
-- Name: user_roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_roles_role_id_seq OWNED BY public.user_roles.role_id;


--
-- Name: user_saved_articles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_saved_articles (
    saved_id integer NOT NULL,
    user_id integer NOT NULL,
    news_id integer NOT NULL,
    saved_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_saved_articles OWNER TO postgres;

--
-- Name: user_saved_articles_saved_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_saved_articles_saved_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_saved_articles_saved_id_seq OWNER TO postgres;

--
-- Name: user_saved_articles_saved_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_saved_articles_saved_id_seq OWNED BY public.user_saved_articles.saved_id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_sessions (
    session_id character varying(128) NOT NULL,
    user_id integer NOT NULL,
    ip_address inet,
    user_agent character varying(255),
    last_activity timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    is_active boolean DEFAULT true
);


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    phone character varying(20) NOT NULL,
    county character varying(100) NOT NULL,
    constituency character varying(100),
    referral_code character varying(50),
    referred_by integer,
    volunteer_interest boolean DEFAULT false,
    sms_updates boolean DEFAULT false,
    email_verified boolean DEFAULT false,
    phone_verified boolean DEFAULT false,
    password_hash character varying(255),
    last_login timestamp without time zone,
    status public.user_status DEFAULT 'active'::public.user_status,
    role_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: volunteers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.volunteers (
    volunteer_id integer NOT NULL,
    full_name character varying(200) NOT NULL,
    nickname character varying(100),
    phone character varying(20) NOT NULL,
    email character varying(150),
    county character varying(100) NOT NULL,
    constituency character varying(100),
    expertise character varying(200),
    availability public.availability_type DEFAULT 'flexible'::public.availability_type,
    status public.volunteer_status DEFAULT 'pending'::public.volunteer_status,
    assigned_tasks text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.volunteers OWNER TO postgres;

--
-- Name: volunteers_volunteer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.volunteers_volunteer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.volunteers_volunteer_id_seq OWNER TO postgres;

--
-- Name: volunteers_volunteer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.volunteers_volunteer_id_seq OWNED BY public.volunteers.volunteer_id;


--
-- Name: weekly_trends; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.weekly_trends AS
 SELECT stat_date,
    county,
    category,
    sum(new_devices) AS new_devices,
    sum(total_devices) AS total_devices
   FROM public.daily_location_stats
  WHERE (stat_date >= (CURRENT_DATE - '7 days'::interval))
  GROUP BY stat_date, county, category
  ORDER BY stat_date DESC, (sum(total_devices)) DESC;


ALTER VIEW public.weekly_trends OWNER TO postgres;

--
-- Name: active_location_counts location_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_location_counts ALTER COLUMN location_id SET DEFAULT nextval('public.active_location_counts_location_id_seq'::regclass);


--
-- Name: activity_log activity_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_log ALTER COLUMN activity_id SET DEFAULT nextval('public.activity_log_activity_id_seq'::regclass);


--
-- Name: ad_clicks click_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_clicks ALTER COLUMN click_id SET DEFAULT nextval('public.ad_clicks_click_id_seq'::regclass);


--
-- Name: ad_impressions impression_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_impressions ALTER COLUMN impression_id SET DEFAULT nextval('public.ad_impressions_impression_id_seq'::regclass);


--
-- Name: ad_tiers tier_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_tiers ALTER COLUMN tier_id SET DEFAULT nextval('public.ad_tiers_tier_id_seq'::regclass);


--
-- Name: admin_activity_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log ALTER COLUMN log_id SET DEFAULT nextval('public.admin_activity_log_log_id_seq'::regclass);


--
-- Name: admin_chat_messages message_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_chat_messages ALTER COLUMN message_id SET DEFAULT nextval('public.admin_chat_messages_message_id_seq'::regclass);


--
-- Name: admin_notifications notification_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.admin_notifications_notification_id_seq'::regclass);


--
-- Name: admin_permissions permission_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions ALTER COLUMN permission_id SET DEFAULT nextval('public.admin_permissions_permission_id_seq'::regclass);


--
-- Name: admins admin_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins ALTER COLUMN admin_id SET DEFAULT nextval('public.admins_admin_id_seq'::regclass);


--
-- Name: advertisements ad_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisements ALTER COLUMN ad_id SET DEFAULT nextval('public.advertisements_ad_id_seq'::regclass);


--
-- Name: advertisers advertiser_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisers ALTER COLUMN advertiser_id SET DEFAULT nextval('public.advertisers_advertiser_id_seq'::regclass);


--
-- Name: analytics_daily analytics_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_daily ALTER COLUMN analytics_id SET DEFAULT nextval('public.analytics_daily_analytics_id_seq'::regclass);


--
-- Name: analytics_monthly analytics_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_monthly ALTER COLUMN analytics_id SET DEFAULT nextval('public.analytics_monthly_analytics_id_seq'::regclass);


--
-- Name: bookmarks bookmark_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks ALTER COLUMN bookmark_id SET DEFAULT nextval('public.bookmarks_bookmark_id_seq'::regclass);


--
-- Name: breaking_news breaking_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breaking_news ALTER COLUMN breaking_id SET DEFAULT nextval('public.breaking_news_breaking_id_seq'::regclass);


--
-- Name: categories category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories ALTER COLUMN category_id SET DEFAULT nextval('public.categories_category_id_seq'::regclass);


--
-- Name: cleanup_history cleanup_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleanup_history ALTER COLUMN cleanup_id SET DEFAULT nextval('public.cleanup_history_cleanup_id_seq'::regclass);


--
-- Name: cloudflare_images image_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cloudflare_images ALTER COLUMN image_id SET DEFAULT nextval('public.cloudflare_images_image_id_seq'::regclass);


--
-- Name: cookie_stats_daily stat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_daily ALTER COLUMN stat_id SET DEFAULT nextval('public.cookie_stats_daily_stat_id_seq'::regclass);


--
-- Name: cookie_stats_monthly stat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_monthly ALTER COLUMN stat_id SET DEFAULT nextval('public.cookie_stats_monthly_stat_id_seq'::regclass);


--
-- Name: daily_location_stats stat_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_location_stats ALTER COLUMN stat_id SET DEFAULT nextval('public.daily_location_stats_stat_id_seq'::regclass);


--
-- Name: donations donation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations ALTER COLUMN donation_id SET DEFAULT nextval('public.donations_donation_id_seq'::regclass);


--
-- Name: email_queue queue_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue ALTER COLUMN queue_id SET DEFAULT nextval('public.email_queue_queue_id_seq'::regclass);


--
-- Name: event_registrations registration_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations ALTER COLUMN registration_id SET DEFAULT nextval('public.event_registrations_registration_id_seq'::regclass);


--
-- Name: events event_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events ALTER COLUMN event_id SET DEFAULT nextval('public.events_event_id_seq'::regclass);


--
-- Name: image_variants variant_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_variants ALTER COLUMN variant_id SET DEFAULT nextval('public.image_variants_variant_id_seq'::regclass);


--
-- Name: media_files file_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_files ALTER COLUMN file_id SET DEFAULT nextval('public.media_files_file_id_seq'::regclass);


--
-- Name: monthly_location_summary summary_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_location_summary ALTER COLUMN summary_id SET DEFAULT nextval('public.monthly_location_summary_summary_id_seq'::regclass);


--
-- Name: news news_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news ALTER COLUMN news_id SET DEFAULT nextval('public.news_news_id_seq'::regclass);


--
-- Name: news_approval_history approval_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history ALTER COLUMN approval_id SET DEFAULT nextval('public.news_approval_history_approval_id_seq'::regclass);


--
-- Name: news_categories news_category_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_categories ALTER COLUMN news_category_id SET DEFAULT nextval('public.news_categories_news_category_id_seq'::regclass);


--
-- Name: news_comments comment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_comments ALTER COLUMN comment_id SET DEFAULT nextval('public.news_comments_comment_id_seq'::regclass);


--
-- Name: news_images image_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_images ALTER COLUMN image_id SET DEFAULT nextval('public.news_images_image_id_seq'::regclass);


--
-- Name: news_quotes quote_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes ALTER COLUMN quote_id SET DEFAULT nextval('public.news_quotes_quote_id_seq'::regclass);


--
-- Name: news_reactions reaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_reactions ALTER COLUMN reaction_id SET DEFAULT nextval('public.news_reactions_reaction_id_seq'::regclass);


--
-- Name: news_shares share_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_shares ALTER COLUMN share_id SET DEFAULT nextval('public.news_shares_share_id_seq'::regclass);


--
-- Name: news_social_media social_media_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_social_media ALTER COLUMN social_media_id SET DEFAULT nextval('public.news_social_media_social_media_id_seq'::regclass);


--
-- Name: news_videos video_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_videos ALTER COLUMN video_id SET DEFAULT nextval('public.news_videos_video_id_seq'::regclass);


--
-- Name: newsletters newsletter_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.newsletters ALTER COLUMN newsletter_id SET DEFAULT nextval('public.newsletters_newsletter_id_seq'::regclass);


--
-- Name: page_views view_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_views ALTER COLUMN view_id SET DEFAULT nextval('public.page_views_view_id_seq'::regclass);


--
-- Name: referrals referral_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals ALTER COLUMN referral_id SET DEFAULT nextval('public.referrals_referral_id_seq'::regclass);


--
-- Name: role_permissions permission_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN permission_id SET DEFAULT nextval('public.role_permissions_permission_id_seq'::regclass);


--
-- Name: scheduler_logs log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduler_logs ALTER COLUMN log_id SET DEFAULT nextval('public.scheduler_logs_log_id_seq'::regclass);


--
-- Name: social_embed_cache cache_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_embed_cache ALTER COLUMN cache_id SET DEFAULT nextval('public.social_embed_cache_cache_id_seq'::regclass);


--
-- Name: subscribers subscriber_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers ALTER COLUMN subscriber_id SET DEFAULT nextval('public.subscribers_subscriber_id_seq'::regclass);


--
-- Name: system_logs log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN log_id SET DEFAULT nextval('public.system_logs_log_id_seq'::regclass);


--
-- Name: system_settings setting_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_settings ALTER COLUMN setting_id SET DEFAULT nextval('public.system_settings_setting_id_seq'::regclass);


--
-- Name: user_notifications notification_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications ALTER COLUMN notification_id SET DEFAULT nextval('public.user_notifications_notification_id_seq'::regclass);


--
-- Name: user_preferences preference_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences ALTER COLUMN preference_id SET DEFAULT nextval('public.user_preferences_preference_id_seq'::regclass);


--
-- Name: user_reading_history history_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_reading_history ALTER COLUMN history_id SET DEFAULT nextval('public.user_reading_history_history_id_seq'::regclass);


--
-- Name: user_roles role_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN role_id SET DEFAULT nextval('public.user_roles_role_id_seq'::regclass);


--
-- Name: user_saved_articles saved_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_saved_articles ALTER COLUMN saved_id SET DEFAULT nextval('public.user_saved_articles_saved_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: volunteers volunteer_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.volunteers ALTER COLUMN volunteer_id SET DEFAULT nextval('public.volunteers_volunteer_id_seq'::regclass);


--
-- Data for Name: active_location_counts; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: activity_log; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: ad_clicks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: ad_impressions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: ad_tiers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_activity_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.admin_activity_log VALUES (2, 5, 'create_published_news', 'news', 1, 'Created news: Sakaja Impeachment Ongoing', '127.0.0.1', '2025-12-10 15:28:53.497976');
INSERT INTO public.admin_activity_log VALUES (3, 5, 'create_published_news', 'news', 2, 'Created news: 15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case', '127.0.0.1', '2025-12-10 23:11:01.176903');
INSERT INTO public.admin_activity_log VALUES (4, 5, 'create_published_news', 'news', 3, 'Created news: President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act', '127.0.0.1', '2025-12-15 16:59:14.302738');
INSERT INTO public.admin_activity_log VALUES (5, 5, 'create_published_news', 'news', 4, 'Created news: Cyrus Jirongo Alleges Ruto Was Involved in KANU 1992 Tender Irregularities', '127.0.0.1', '2025-12-15 17:06:14.012383');
INSERT INTO public.admin_activity_log VALUES (6, 5, 'create_published_news', 'news', 5, 'Created news: Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto', '127.0.0.1', '2025-12-15 17:10:33.204395');
INSERT INTO public.admin_activity_log VALUES (7, 5, 'create_published_news', 'news', 6, 'Created news: Accusations Stir Debate Around Kenyan Anti-GBV Organisation Usikimye', '127.0.0.1', '2025-12-15 17:20:12.162694');
INSERT INTO public.admin_activity_log VALUES (8, 5, 'disapprove_article', 'news', 5, 'Disapproved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:22:33.155368');
INSERT INTO public.admin_activity_log VALUES (9, 5, 'approve_article', 'news', 5, 'Approved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:22:37.452266');
INSERT INTO public.admin_activity_log VALUES (10, 5, 'disapprove_article', 'news', 6, 'Disapproved article: "Accusations Stir Debate Around Kenyan Anti-GBV Organisation Usikimye"', '127.0.0.1', '2025-12-16 08:23:46.928373');
INSERT INTO public.admin_activity_log VALUES (11, 5, 'disapprove_article', 'news', 5, 'Disapproved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:23:50.481283');
INSERT INTO public.admin_activity_log VALUES (12, 5, 'disapprove_article', 'news', 4, 'Disapproved article: "Cyrus Jirongo Alleges Ruto Was Involved in KANU 1992 Tender Irregularities"', '127.0.0.1', '2025-12-16 08:23:54.409269');
INSERT INTO public.admin_activity_log VALUES (13, 5, 'disapprove_article', 'news', 3, 'Disapproved article: "President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act"', '127.0.0.1', '2025-12-16 08:23:57.631272');
INSERT INTO public.admin_activity_log VALUES (14, 5, 'disapprove_article', 'news', 2, 'Disapproved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:24:01.012114');
INSERT INTO public.admin_activity_log VALUES (15, 5, 'disapprove_article', 'news', 1, 'Disapproved article: "Sakaja Impeachment Ongoing"', '127.0.0.1', '2025-12-16 08:24:03.562876');
INSERT INTO public.admin_activity_log VALUES (16, 5, 'approve_article', 'news', 5, 'Approved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:24:31.388226');
INSERT INTO public.admin_activity_log VALUES (17, 5, 'disapprove_article', 'news', 5, 'Disapproved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:24:55.079801');
INSERT INTO public.admin_activity_log VALUES (18, 5, 'approve_article', 'news', 2, 'Approved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:25:22.08583');
INSERT INTO public.admin_activity_log VALUES (19, 5, 'approve_article', 'news', 3, 'Approved article: "President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act"', '127.0.0.1', '2025-12-16 08:25:26.23794');
INSERT INTO public.admin_activity_log VALUES (20, 5, 'approve_article', 'news', 4, 'Approved article: "Cyrus Jirongo Alleges Ruto Was Involved in KANU 1992 Tender Irregularities"', '127.0.0.1', '2025-12-16 08:25:31.089737');
INSERT INTO public.admin_activity_log VALUES (21, 5, 'disapprove_article', 'news', 3, 'Disapproved article: "President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act"', '127.0.0.1', '2025-12-16 08:25:38.512944');
INSERT INTO public.admin_activity_log VALUES (22, 5, 'disapprove_article', 'news', 2, 'Disapproved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:25:43.067945');
INSERT INTO public.admin_activity_log VALUES (23, 5, 'approve_article', 'news', 5, 'Approved article: "Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto"', '127.0.0.1', '2025-12-16 08:25:52.416144');
INSERT INTO public.admin_activity_log VALUES (24, 5, 'approve_article', 'news', 6, 'Approved article: "Accusations Stir Debate Around Kenyan Anti-GBV Organisation Usikimye"', '127.0.0.1', '2025-12-16 08:25:57.809816');
INSERT INTO public.admin_activity_log VALUES (25, 5, 'approve_article', 'news', 2, 'Approved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:26:14.50992');
INSERT INTO public.admin_activity_log VALUES (26, 5, 'disapprove_article', 'news', 2, 'Disapproved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:26:31.666734');
INSERT INTO public.admin_activity_log VALUES (27, 5, 'create_published_news', 'news', 7, 'Created news: Blow to Manchester United’s Top-Four Push After Eight-Goal Premier League Thriller', '127.0.0.1', '2025-12-16 08:37:49.665402');
INSERT INTO public.admin_activity_log VALUES (28, 5, 'create_published_news', 'news', 8, 'Created news: Kenyan Activist Charged Over Social Media Post Allegedly Inciting Violence', '127.0.0.1', '2025-12-16 08:48:06.364263');
INSERT INTO public.admin_activity_log VALUES (29, 5, 'approve_article', 'news', 1, 'Approved article: "Sakaja Impeachment Ongoing"', '127.0.0.1', '2025-12-16 08:50:17.385216');
INSERT INTO public.admin_activity_log VALUES (30, 5, 'approve_article', 'news', 2, 'Approved article: "15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case"', '127.0.0.1', '2025-12-16 08:50:23.976529');
INSERT INTO public.admin_activity_log VALUES (31, 5, 'approve_article', 'news', 3, 'Approved article: "President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act"', '127.0.0.1', '2025-12-16 08:50:28.219614');
INSERT INTO public.admin_activity_log VALUES (32, 5, 'update_news', 'news', 5, 'Updated news: Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto', '127.0.0.1', '2025-12-16 08:53:33.219201');
INSERT INTO public.admin_activity_log VALUES (33, 5, 'update_news', 'news', 8, 'Updated news: Kenyan Activist Charged Over Social Media Post Allegedly Inciting Violence', '127.0.0.1', '2025-12-16 10:10:43.790241');
INSERT INTO public.admin_activity_log VALUES (34, 5, 'create_published_news', 'news', 9, 'Created news: President Ruto Condoles With Family of Late Cyrus Jirongo at Gigiri Home', '127.0.0.1', '2025-12-19 10:22:21.606837');
INSERT INTO public.admin_activity_log VALUES (35, 5, 'update_news', 'news', 9, 'Updated news: President Ruto Condoles With Family of Late Cyrus Jirongo at Gigiri Home', '127.0.0.1', '2025-12-19 10:37:31.470758');
INSERT INTO public.admin_activity_log VALUES (36, 5, 'update_news', 'news', 9, 'Updated news:  President Ruto Condoles With Family of Late Cyrus Jirongo at Gigiri Home', '127.0.0.1', '2025-12-19 10:39:20.585506');
INSERT INTO public.admin_activity_log VALUES (37, 5, 'create_published_news', 'news', 10, 'Created news: Court Allows Detectives to Detain Lolgorian Ward MCA Michael Seme for 21 Days Over Deadly Trans Mara Clashes', '127.0.0.1', '2025-12-24 23:57:49.824858');


--
-- Data for Name: admin_chat_messages; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_online_status; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_session_store; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admin_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.admins VALUES (4, 'Elijah', 'Kariuki', 'karis@dailyvaibe.com', '0720758470', 'elijah_kariuku', 'super_admin', '$2a$10$GWP7Y0FrV3NslrhQCOsAxu4Y3s8dSqXb84qZ3Q5xD.oOnmfDCI6fW', '{"can_delete_any": true, "all_permissions": true, "can_manage_admins": true}', NULL, 'active', 1, '2025-12-08 02:57:30.556246', '2025-12-08 02:57:30.556246');
INSERT INTO public.admins VALUES (5, 'Rahab', 'Waithera', 'rahab@dailyvaibe.com', '0795785304', 'Rheyna', 'super_admin', '$2a$10$PD7gyx3K9BayI91eULyHtOxrcOVMNejiikI3bYGnUh83UBSmy8KI6', '{"can_delete_any": true, "all_permissions": true, "can_manage_admins": true}', '2025-12-25 01:23:14.049536', 'active', 1, '2025-12-08 02:57:30.765289', '2025-12-08 02:57:30.765289');


--
-- Data for Name: advertisements; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: advertisers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: analytics_daily; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: analytics_monthly; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: bookmarks; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: breaking_news; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.categories VALUES (1, 'World', 'world', 'International news coverage', '#2563eb', 'globe', NULL, 1, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (14, 'Counties', 'counties', 'News from Kenyan counties', '#3498db', 'map-marker', NULL, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (15, 'Politics', 'politics', 'Political news and governance', '#e74c3c', 'landmark', NULL, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (16, 'Business', 'business', 'Business and economic news', '#2ecc71', 'briefcase', NULL, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (17, 'Opinion', 'opinion', 'Opinion pieces and analysis', '#9b59b6', 'comment', NULL, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (18, 'Sports', 'sports', 'Sports news and updates', '#f39c12', 'football', NULL, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (19, 'Life & Style', 'lifestyle', 'Lifestyle and culture', '#e91e63', 'heart', NULL, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (20, 'Entertainment', 'entertainment', 'Entertainment and celebrity news', '#ff6b6b', 'star', NULL, 8, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (21, 'Technology', 'tech', 'Technology and innovation', '#1abc9c', 'laptop', NULL, 9, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (22, 'Other', 'other', 'Other news and features', '#34495e', 'newspaper', NULL, 10, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (2, 'National', 'national', 'National news from Kenya', '#c0392b', 'flag', 1, 1, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (3, 'East Africa', 'east-africa', 'News from East African region', '#e67e22', 'compass', 1, 2, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (4, 'Africa', 'africa', 'News from across Africa', '#f39c12', 'globe-africa', 1, 3, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (26, 'International', 'international', 'Global news coverage', '#3498db', 'earth', 1, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (27, 'Live Updates', 'live', 'Real-time news updates', '#ff6b6b', 'broadcast', 1, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (28, 'Nairobi', 'nairobi', 'News from Nairobi', '#3498db', 'city', 14, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (29, 'Coast Region', 'coast', 'Coastal counties news', '#16a085', 'umbrella-beach', 14, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (30, 'Mountain Region', 'mountain', 'Mt. Kenya region news', '#8e44ad', 'mountain', 14, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (31, 'Lake Region', 'lake-region', 'Western Kenya news', '#2980b9', 'water', 14, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (32, 'Rift Valley', 'rift-valley', 'Rift Valley news', '#d35400', 'hill', 14, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (33, 'Northern Kenya', 'northern', 'Northern counties news', '#c0392b', 'compass-north', 14, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (34, 'Eastern Kenya', 'eastern', 'Eastern counties news', '#f39c12', 'compass-east', 14, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (35, 'Governance', 'governance', 'Government and policy', '#7f8c8d', 'building-columns', 15, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (36, 'Legal Affairs', 'legal', 'Legal and judicial news', '#34495e', 'gavel', 15, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (37, 'Elections', 'elections', 'Electoral news and updates', '#e74c3c', 'vote', 15, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (38, 'Parliament', 'parliament', 'Parliamentary affairs', '#9b59b6', 'users', 15, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (39, 'Companies', 'companies', 'Corporate news', '#2ecc71', 'building', 16, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (40, 'Finance & Markets', 'finance-markets', 'Financial markets', '#27ae60', 'chart-line', 16, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (7, 'Investment', 'investment', 'Investment insights and opportunities', '#d4af37', 'coins', 16, 3, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (42, 'Enterprise', 'enterprise', 'Business enterprise', '#16a085', 'handshake', 16, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (43, 'Economy', 'economy', 'Economic analysis', '#1abc9c', 'chart-pie', 16, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (44, 'Banking', 'banking', 'Banking and finance', '#2c3e50', 'bank', 16, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (45, 'Editorials', 'editorials', 'Editorial opinions', '#9b59b6', 'pen', 17, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (46, 'Columnists', 'columnists', 'Column writers', '#8e44ad', 'user-pen', 17, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (6, 'Bloggers', 'bloggers', 'Insights and opinions from top bloggers', '#e67e22', 'pen-nib', 17, 3, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (48, 'Letters', 'letters', 'Readers letters', '#2980b9', 'envelope', 17, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (49, 'Trail Blazing', 'trail-blazing', 'Innovative perspectives and insights', '#e74c3c', 'fire', 17, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (50, 'AI Graphics', 'ai-graphics', 'AI-generated visual commentary', '#f39c12', 'robot', 17, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (51, 'Analysis', 'analysis', 'In-depth analysis', '#34495e', 'microscope', 17, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (52, 'Football', 'football', 'Football news', '#2ecc71', 'futbol', 18, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (53, 'Athletics', 'athletics', 'Track and field', '#f39c12', 'running', 18, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (54, 'Rugby', 'rugby', 'Rugby news', '#e74c3c', 'football', 18, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (55, 'Motorsport', 'motorsport', 'Motor racing', '#e67e22', 'flag-checkered', 18, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (5, 'Sports Vybe', 'sports-vybe', 'Sports discussions and opinions', '#0891b2', 'comments', 18, 5, true, '2025-12-08 16:49:35.382045', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (57, 'Cricket', 'cricket', 'Cricket news', '#16a085', 'baseball', 18, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (58, 'Basketball', 'basketball', 'Basketball news', '#e91e63', 'basketball', 18, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (59, 'Other Sports', 'other-sports', 'Other sporting events', '#9b59b6', 'trophy', 18, 8, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (60, 'Motoring', 'motoring', 'Automotive news', '#34495e', 'car', 19, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (61, 'Culture', 'culture', 'Cultural news', '#9b59b6', 'palette', 19, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (62, 'Family', 'family', 'Family matters', '#e91e63', 'home-heart', 19, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (63, 'Relationships', 'relationships', 'Relationship advice', '#e74c3c', 'heart-circle', 19, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (64, 'Travel', 'travel', 'Travel and tourism', '#3498db', 'plane', 19, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (65, 'Wellness', 'wellness', 'Health and wellness', '#2ecc71', 'spa', 19, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (66, 'Fashion', 'fashion', 'Fashion and style', '#e91e63', 'shirt', 19, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (67, 'Food', 'food', 'Food and dining', '#f39c12', 'utensils', 19, 8, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (68, 'Buzz', 'buzz', 'Entertainment buzz', '#e91e63', 'bell', 20, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (69, 'Trending', 'trending', 'Trending stories', '#ff6b6b', 'fire', 20, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (70, 'Gossip', 'gossip', 'Celebrity gossip', '#e74c3c', 'comment-dots', 20, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (71, 'Life Stories', 'life-stories', 'Inspiring stories', '#9b59b6', 'book-open', 20, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (72, 'Music', 'music', 'Music news', '#3498db', 'music', 20, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (73, 'Movies', 'movies', 'Film and cinema', '#e67e22', 'film', 20, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (74, 'Celebrity', 'celebrity', 'Celebrity news', '#f39c12', 'star', 20, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (75, 'Innovations', 'innovations', 'Tech innovations', '#1abc9c', 'lightbulb', 21, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (76, 'Gadgets', 'gadgets', 'Latest gadgets', '#3498db', 'mobile', 21, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (77, 'Startups', 'startups', 'Tech startups', '#2ecc71', 'rocket', 21, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (78, 'Digital Life', 'digital-life', 'Digital lifestyle', '#9b59b6', 'wifi', 21, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (79, 'AI & ML', 'ai', 'Artificial Intelligence', '#e74c3c', 'brain', 21, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (80, 'Mobile Tech', 'mobile', 'Mobile technology', '#f39c12', 'mobile-screen', 21, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (81, 'Gaming', 'gaming', 'Gaming news', '#e91e63', 'gamepad', 21, 7, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (82, 'Human Rights', 'human-rights', 'Human rights issues', '#e74c3c', 'hand-holding-heart', 22, 1, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (83, 'Climate Crisis', 'climate-crisis', 'Environmental news', '#16a085', 'leaf', 22, 2, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (84, 'Investigations', 'investigations', 'Investigative journalism', '#8e44ad', 'magnifying-glass', 22, 3, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (85, 'Interactives', 'interactives', 'Interactive features', '#3498db', 'sliders', 22, 4, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (86, 'Features', 'features', 'Special features', '#f39c12', 'bookmark', 22, 5, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (87, 'Trending', 'trending-pics', 'Trending visual stories', '#e67e22', 'camera', 22, 6, true, '2025-12-08 21:38:57.622598', '2025-12-08 21:38:57.622598');
INSERT INTO public.categories VALUES (88, 'Reports', 'world-reports', 'In-depth world reports', '#34495e', 'file-text', 1, 6, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (89, 'Reports', 'county-reports', 'County investigation reports', '#34495e', 'file-text', 14, 8, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (90, 'Reports', 'political-reports', 'Political analysis reports', '#34495e', 'file-text', 15, 5, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (91, 'Reports', 'business-reports', 'Business and economic reports', '#34495e', 'file-text', 16, 7, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (92, 'Reports', 'tech-reports', 'Technology research reports', '#34495e', 'file-text', 21, 8, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (93, 'Reports', 'special-reports', 'Special investigation reports', '#34495e', 'file-text', 22, 7, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (94, 'Others', 'sports-others', 'Other sports categories', '#95a5a6', 'ellipsis', 18, 9, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (95, 'Others', 'lifestyle-others', 'Other lifestyle topics', '#95a5a6', 'ellipsis', 19, 9, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (96, 'Others', 'politics-others', 'Other political topics', '#95a5a6', 'ellipsis', 15, 6, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (97, 'Others', 'entertainment-others', 'Other entertainment topics', '#95a5a6', 'ellipsis', 20, 8, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');
INSERT INTO public.categories VALUES (98, 'Others', 'tech-others', 'Other technology topics', '#95a5a6', 'ellipsis', 21, 9, true, '2025-12-23 03:33:22.048944', '2025-12-23 03:33:22.048944');


--
-- Data for Name: cleanup_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: cloudflare_images; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: cookie_stats_daily; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: cookie_stats_monthly; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: daily_location_stats; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: device_registry; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: donations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: email_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: event_registrations; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: image_variants; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: media_files; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: monthly_location_summary; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.news VALUES (9, ' President Ruto Condoles With Family of Late Cyrus Jirongo at Gigiri Home', '[HEADING]President Visits Jirongo’s Family in Gigiri[/HEADING]

President William Ruto on Thursday, December 18, paid a condolence visit to the Gigiri home of the late former Lugari Member of Parliament Cyrus Jirongo, where he met and comforted the bereaved family.

The president was received by Jirongo’s three widows alongside members of the extended family, as he joined them in mourning the passing of the veteran politician and businessman.

During the visit, President Ruto signed the condolence book before addressing the family and offering words of comfort drawn from scripture.

[QUOTE]“Condoled with the family of my friend, the late Hon. Cyrus Jirongo, at their Gigiri home, Nairobi County. May we be comforted by the word of the Lord in Psalm 46:1 — ‘God is our refuge and strength, an ever-present help in trouble,’”[/QUOTE] the president wrote.

[HEADING]Ruto’s Tribute to Jirongo[/HEADING]

Earlier, President Ruto had paid glowing tribute to Jirongo, describing him as a determined leader, accomplished entrepreneur, and seasoned politician whose influence shaped Kenya’s political and economic landscape over several decades.

He highlighted Jirongo’s generosity, resilience, and commitment to uplifting others, noting that he remained steadfast both in public service and private life.

[HIGHLIGHT]Ruto described Jirongo as a relentless go-getter and a fighter who never allowed life’s challenges to define or defeat him.[/HIGHLIGHT]

The president added that despite his toughness in politics and business, Jirongo remained warm, approachable, and deeply committed to those around him.

[HEADING]Political Journey and Legacy[/HEADING]

Cyrus Jirongo rose to national prominence in the early 1990s through the influential Youth for KANU ’92 movement, which played a key role in mobilising support for the late President Daniel arap Moi.

He served as the Member of Parliament for Lugari for a total of ten years, holding office between 1997 and 2002, and later from 2007 to 2013. In the final year of Moi’s administration, Jirongo also served as a cabinet minister.

In 2013, Jirongo contested the presidency but was unsuccessful. He later sought the Kakamega governorship in the 2022 General Election, a bid that also did not bear fruit.

Jirongo passed away at the age of 64, leaving behind a legacy marked by political influence, entrepreneurship, and decades of public engagement.', 'President William Ruto visited the Nairobi home of the late former lawmaker Cyrus Jirongo to condole with his family, praising him as a resilient leader, entrepreneur, and politician whose generosity touched many lives.', 'president-ruto-condoles-with-family-of-late-cyrus-jirongo-at-gigiri-home', 2, NULL, 5, '/uploads/images/image-png-1766128941542-308344215.png', '<h3 class="content-heading">President Visits Jirongo’s Family in Gigiri</h3>

President William Ruto on Thursday, December 18, paid a condolence visit to the Gigiri home of the late former Lugari Member of Parliament Cyrus Jirongo, where he met and comforted the bereaved family.

The president was received by Jirongo’s three widows alongside members of the extended family, as he joined them in mourning the passing of the veteran politician and businessman.

During the visit, President Ruto signed the condolence book before addressing the family and offering words of comfort drawn from scripture.

<blockquote class="news-large-quote">“Condoled with the family of my friend, the late Hon. Cyrus Jirongo, at their Gigiri home, Nairobi County. May we be comforted by the word of the Lord in Psalm 46:1 — ‘God is our refuge and strength, an ever-present help in trouble,’”</blockquote> the president wrote.

<h3 class="content-heading">Ruto’s Tribute to Jirongo</h3>

Earlier, President Ruto had paid glowing tribute to Jirongo, describing him as a determined leader, accomplished entrepreneur, and seasoned politician whose influence shaped Kenya’s political and economic landscape over several decades.

He highlighted Jirongo’s generosity, resilience, and commitment to uplifting others, noting that he remained steadfast both in public service and private life.

<span class="news-highlight">Ruto described Jirongo as a relentless go-getter and a fighter who never allowed life’s challenges to define or defeat him.</span>

The president added that despite his toughness in politics and business, Jirongo remained warm, approachable, and deeply committed to those around him.

<h3 class="content-heading">Political Journey and Legacy</h3>

Cyrus Jirongo rose to national prominence in the early 1990s through the influential Youth for KANU ’92 movement, which played a key role in mobilising support for the late President Daniel arap Moi.

He served as the Member of Parliament for Lugari for a total of ten years, holding office between 1997 and 2002, and later from 2007 to 2013. In the final year of Moi’s administration, Jirongo also served as a cabinet minister.

In 2013, Jirongo contested the presidency but was unsuccessful. He later sought the Kakamega governorship in the 2022 General Election, a bid that also did not bear fruit.

Jirongo passed away at the age of 64, leaving behind a legacy marked by political influence, entrepreneurship, and decades of public engagement.', '[{"text": "“Condoled with the family of my friend, the late Hon. Cyrus Jirongo, at their Gigiri home, Nairobi County. May we be comforted by the word of the Lord in Psalm 46:1 — ‘God is our refuge and strength, an ever-present help in trouble,’”", "sayer": null, "position": 598}]', NULL, 0, 86, 0, 0, 0, 'published', 'published', false, 'medium', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'President William Ruto visits the Gigiri home of the late Cyrus Jirongo to condole with his family and honour his political legacy.', 'President William Ruto visits the Gigiri home of the late Cyrus Jirongo to condole with his family and honour his political legacy.', 'William Ruto Jirongo condolence, Cyrus Jirongo death, Gigiri home visit, Kenyan political leaders, YK’92 founder', 2, '2025-12-19 10:39:20.59', '2025-12-19 10:22:21.606837', '2025-12-20 10:49:49.032351', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (1, 'Sakaja Impeachment Ongoing', '
A total of 96 out of 122 MCAs met at City Hall and agreed to begin the process to remove the governor and his deputy from office. The meeting was attended by senior county leaders, including Speaker Ken Ng’ondi, Majority Leader Peter Imwatok, and Minority Whip Mark Mugambi. Deputy Minority Whip Waithera Chege, who introduced the proposal, confirmed that the motion had cross-party support and would proceed once the assembly resumes in September.


Among the key concerns raised by MCAs are claims of mismanagement, exclusion of elected leaders from ward-level development decisions, and violations of the Constitution. The governor is accused of sidelining MCAs by appointing unelected coordinators to oversee local projects, including the distribution of motorbikes provided by the State House. Legislators also cited delayed bursary disbursements, unpaid contractors, and stalled development programmes as evidence of administrative failure.

Although the assembly is currently in recess until 9 September, the impeachment process is expected to advance during a planned retreat in Naivasha next week. MCAs are preparing to collect at least 41 signatures, the minimum required to formally table the motion. If the motion passes, the Speaker would assume the role of acting governor for up to 60 days, during which a by-election would be held to fill the vacant position.

This is not the first attempt to impeach Governor Sakaja. A previous effort led by the late Kariobangi North MCA Joel Munuve did not succeed, amid reports of intimidation. More recently, a petition by former Korogocho MCA Maxwell Achar accused the governor of gross misconduct, including sponsoring violence and unlawful evictions. However, the Speaker dismissed the petition on procedural grounds, noting that only sitting MCAs are allowed to initiate an impeachment motion.', 'Nairobi Governor Johnson Sakaja and his deputy James Muchiri are facing a renewed impeachment push, with over 90 Members of the County Assembly backing the move.
', 'sakaja-impeachment-ongoing', 28, NULL, 5, '/uploads/images/Sakaja-jpg-1765369733473-660383003.jpg', '
A total of 96 out of 122 MCAs met at City Hall and agreed to begin the process to remove the governor and his deputy from office. The meeting was attended by senior county leaders, including Speaker Ken Ng’ondi, Majority Leader Peter Imwatok, and Minority Whip Mark Mugambi. Deputy Minority Whip Waithera Chege, who introduced the proposal, confirmed that the motion had cross-party support and would proceed once the assembly resumes in September.


Among the key concerns raised by MCAs are claims of mismanagement, exclusion of elected leaders from ward-level development decisions, and violations of the Constitution. The governor is accused of sidelining MCAs by appointing unelected coordinators to oversee local projects, including the distribution of motorbikes provided by the State House. Legislators also cited delayed bursary disbursements, unpaid contractors, and stalled development programmes as evidence of administrative failure.

Although the assembly is currently in recess until 9 September, the impeachment process is expected to advance during a planned retreat in Naivasha next week. MCAs are preparing to collect at least 41 signatures, the minimum required to formally table the motion. If the motion passes, the Speaker would assume the role of acting governor for up to 60 days, during which a by-election would be held to fill the vacant position.

This is not the first attempt to impeach Governor Sakaja. A previous effort led by the late Kariobangi North MCA Joel Munuve did not succeed, amid reports of intimidation. More recently, a petition by former Korogocho MCA Maxwell Achar accused the governor of gross misconduct, including sponsoring violence and unlawful evictions. However, the Speaker dismissed the petition on procedural grounds, noting that only sitting MCAs are allowed to initiate an impeachment motion.', '[]', NULL, 0, 12, 0, 0, 0, 'published', 'published', false, 'high', true, '2025-12-17 15:28:53.576', NULL, NULL, NULL, NULL, NULL, NULL, '', 'A total of 96 out of 122 MCAs met at City Hall and agreed to begin the process to remove the governor and his deputy from office. T', 'Sakaja, Senate, MCAs, Impeachment, UDA, Ruto', 2, '2025-12-10 15:28:53.586', '2025-12-10 15:28:53.497976', '2025-12-18 11:54:40.840338', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (4, 'Cyrus Jirongo Alleges Ruto Was Involved in KANU 1992 Tender Irregularities', 'Former Youth for KANU ’92 (YK’92) Secretary-General Cyrus Jirongo has made fresh allegations against President William Samoei Ruto, accusing him of involvement in irregular tender practices during the run-up to the 1992 General Election.

According to Jirongo, he awarded Ruto a contract worth KSh 1.2 million to supply 10,000 campaign T-shirts for the then ruling KANU party.

[QUOTE]“I gave Ruto a 1.2 million tender to supply 10,000 T-shirts for KANU in the 1992 elections. Ruto colluded with the storekeeper and instead supplied the same 1,000 T-shirts ten times,”[/QUOTE] Jirongo claimed.

[HEADING]Power and Influence in the YK’92 Era[/HEADING]

Jirongo, who was widely regarded as one of the most powerful political operatives during President Daniel arap Moi’s regime, served as Ruto’s superior within the YK’92 structure. The organisation was instrumental in mobilising resources and campaign logistics for KANU ahead of the historic multiparty elections.

[HIGHLIGHT]So influential was Jirongo at the time that the KSh 500 note, allegedly used extensively for voter inducement, was popularly nicknamed after him.[/HIGHLIGHT]

The 1992 elections period remains one of the most controversial chapters in Kenya’s political history, marked by accusations of state-sponsored intimidation, bribery, and manipulation.

[HEADING]Other Key Figures Named[/HEADING]

Jirongo’s recollections also place several senior leaders at the centre of the Moi-era power structure. During the same period, current Deputy President Rigathi Gachagua served as a District Officer in Molo, a region that witnessed significant political tension and violence.

Meanwhile, Kalonzo Musyoka held multiple influential positions, serving as KANU National Organising Secretary, Member of Parliament for Kitui North, and Deputy Speaker of the National Assembly.

[HEADING]Unresolved Questions From Kenya’s Past[/HEADING]

While the allegations raised by Jirongo have not been independently verified and no court findings were cited, they add to the long-standing public debate over accountability and political conduct during Kenya’s transition to multiparty democracy.

The claims have resurfaced amid renewed scrutiny of the country’s political history and the roles played by leaders who continue to shape Kenya’s present-day governance.', 'Former KANU power broker Cyrus Jirongo has reignited debate over Kenya’s 1992 elections, alleging that President William Ruto was involved in tender fraud during the YK’92 era.', 'cyrus-jirongo-alleges-ruto-was-involved-in-kanu-1992-tender-irregularities', 37, NULL, 5, '/uploads/images/image-png-1765807573992-747793618.png', 'Former Youth for KANU ’92 (YK’92) Secretary-General Cyrus Jirongo has made fresh allegations against President William Samoei Ruto, accusing him of involvement in irregular tender practices during the run-up to the 1992 General Election.

According to Jirongo, he awarded Ruto a contract worth KSh 1.2 million to supply 10,000 campaign T-shirts for the then ruling KANU party.

<blockquote class="news-large-quote">“I gave Ruto a 1.2 million tender to supply 10,000 T-shirts for KANU in the 1992 elections. Ruto colluded with the storekeeper and instead supplied the same 1,000 T-shirts ten times,”</blockquote> Jirongo claimed.

<h3 class="content-heading">Power and Influence in the YK’92 Era</h3>

Jirongo, who was widely regarded as one of the most powerful political operatives during President Daniel arap Moi’s regime, served as Ruto’s superior within the YK’92 structure. The organisation was instrumental in mobilising resources and campaign logistics for KANU ahead of the historic multiparty elections.

<span class="news-highlight">So influential was Jirongo at the time that the KSh 500 note, allegedly used extensively for voter inducement, was popularly nicknamed after him.</span>

The 1992 elections period remains one of the most controversial chapters in Kenya’s political history, marked by accusations of state-sponsored intimidation, bribery, and manipulation.

<h3 class="content-heading">Other Key Figures Named</h3>

Jirongo’s recollections also place several senior leaders at the centre of the Moi-era power structure. During the same period, current Deputy President Rigathi Gachagua served as a District Officer in Molo, a region that witnessed significant political tension and violence.

Meanwhile, Kalonzo Musyoka held multiple influential positions, serving as KANU National Organising Secretary, Member of Parliament for Kitui North, and Deputy Speaker of the National Assembly.

<h3 class="content-heading">Unresolved Questions From Kenya’s Past</h3>

While the allegations raised by Jirongo have not been independently verified and no court findings were cited, they add to the long-standing public debate over accountability and political conduct during Kenya’s transition to multiparty democracy.

The claims have resurfaced amid renewed scrutiny of the country’s political history and the roles played by leaders who continue to shape Kenya’s present-day governance.', '[{"text": "“I gave Ruto a 1.2 million tender to supply 10,000 T-shirts for KANU in the 1992 elections. Ruto colluded with the storekeeper and instead supplied the same 1,000 T-shirts ten times,”", "sayer": null, "position": 382}]', NULL, 0, 27, 0, 0, 0, 'published', 'published', false, 'medium', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'William Ruto, Cyrus Jirongo, KANU, YK’92, Kenya politics, 1992 elections, Moi era, political history', 'Cyrus Jirongo alleges President William Ruto was involved in irregularities in a KANU tender during the 1992 YK’92 election period.', 'Cyrus Jirongo allegations, Ruto YK’92, KANU 1992 elections, Moi era politics, Kenya political history, Rigathi Gachagua Moi era', 2, '2025-12-15 17:06:14.128', '2025-12-15 17:06:14.012383', '2025-12-19 15:39:58.279853', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (5, 'Oburu Odinga Says ODM Will Remain in Broad-Based Government With Ruto', 'Orange Democratic Movement (ODM) party leader Oburu Oginga has stated that the party will continue cooperating with President William Samoei Ruto’s government under the existing broad-based political arrangement.

Speaking in Eldoret on Monday, December 15, Oburu addressed party supporters during an outreach meeting in Uasin Gishu County, his first public engagement in the region since the death of his brother, former Prime Minister Raila Odinga.

[QUOTE]“This is our first visit to Eldoret since Raila passed on. I want to ask you to continue the work of uniting Kenyans, just as he envisioned when he joined the broad-based government,”[/QUOTE] Oburu said.

[HEADING]Commitment Until 2027[/HEADING]

Oburu dismissed claims that ODM could withdraw from the cooperation agreement, stressing that the party remains firmly anchored in the partnership with Kenya Kwanza.

[HIGHLIGHT]He insisted that ODM would work alongside President Ruto until the end of the current political cycle in 2027.[/HIGHLIGHT]

Using Kiswahili to emphasise his message, Oburu told supporters that ODM is not a party known for abandoning political commitments, adding that the decision taken by Raila Odinga to join the broad-based government would be respected.

[HEADING]Call to the Youth[/HEADING]

The ODM leader also urged young people to register as voters and actively participate in the country’s democratic process, cautioning that political influence comes through the ballot.

[QUOTE]“Young people, I urge you to register and vote. Do not just claim ODM membership without using your vote. Your vote is your voice,”[/QUOTE] he told the gathering.

[HEADING]Wanga Echoes Unity Message[/HEADING]

ODM National Chairperson Gladys Wanga, who attended the meeting alongside Deputy Party Leader Simba Arati, supported Oburu’s remarks, saying the broad-based government has helped stabilise the country and promote national unity.

Wanga said the decision by Raila Odinga and President Ruto to work together came at a critical moment for the country and remains essential to Kenya’s progress.

In a statement shared on her X account later on Monday, Wanga confirmed that the party leadership held extensive discussions with ODM delegates and grassroots officials from Uasin Gishu County.

[HIGHLIGHT]She noted that the meeting focused on strengthening cooperation within the party and ensuring inclusive participation at all levels.[/HIGHLIGHT]

TAGS

ODM, Oburu Odinga, William Ruto, broad-based government, Kenya politics, Uasin Gishu, Gladys Wanga, Simba Arati

META DESCRIPTION (SEO – 160 chars)

ODM leader Oburu Odinga says the party will continue working with President William Ruto under the broad-based government until 2027.', 'ODM leader Oburu Odinga has reaffirmed the party’s commitment to working with President William Ruto’s administration, insisting the broad-based government arrangement will continue until 2027.', 'oburu-odinga-says-odm-will-remain-in-broad-based-government-with-ruto', 37, NULL, 5, '/uploads/images/image-png-1765807833195-88072398.png', 'Orange Democratic Movement (ODM) party leader Oburu Oginga has stated that the party will continue cooperating with President William Samoei Ruto’s government under the existing broad-based political arrangement.

Speaking in Eldoret on Monday, December 15, Oburu addressed party supporters during an outreach meeting in Uasin Gishu County, his first public engagement in the region since the death of his brother, former Prime Minister Raila Odinga.

<blockquote class="news-large-quote">“This is our first visit to Eldoret since Raila passed on. I want to ask you to continue the work of uniting Kenyans, just as he envisioned when he joined the broad-based government,”</blockquote> Oburu said.

<h3 class="content-heading">Commitment Until 2027</h3>

Oburu dismissed claims that ODM could withdraw from the cooperation agreement, stressing that the party remains firmly anchored in the partnership with Kenya Kwanza.

<span class="news-highlight">He insisted that ODM would work alongside President Ruto until the end of the current political cycle in 2027.</span>

Using Kiswahili to emphasise his message, Oburu told supporters that ODM is not a party known for abandoning political commitments, adding that the decision taken by Raila Odinga to join the broad-based government would be respected.

<h3 class="content-heading">Call to the Youth</h3>

The ODM leader also urged young people to register as voters and actively participate in the country’s democratic process, cautioning that political influence comes through the ballot.

<blockquote class="news-large-quote">“Young people, I urge you to register and vote. Do not just claim ODM membership without using your vote. Your vote is your voice,”</blockquote> he told the gathering.

<h3 class="content-heading">Wanga Echoes Unity Message</h3>

ODM National Chairperson Gladys Wanga, who attended the meeting alongside Deputy Party Leader Simba Arati, supported Oburu’s remarks, saying the broad-based government has helped stabilise the country and promote national unity.

Wanga said the decision by Raila Odinga and President Ruto to work together came at a critical moment for the country and remains essential to Kenya’s progress.

In a statement shared on her X account later on Monday, Wanga confirmed that the party leadership held extensive discussions with ODM delegates and grassroots officials from Uasin Gishu County.

<span class="news-highlight">She noted that the meeting focused on strengthening cooperation within the party and ensuring inclusive participation at all levels.</span>

TAGS

ODM, Oburu Odinga, William Ruto, broad-based government, Kenya politics, Uasin Gishu, Gladys Wanga, Simba Arati

META DESCRIPTION (SEO – 160 chars)

ODM leader Oburu Odinga says the party will continue working with President William Ruto under the broad-based government until 2027.', '[{"text": "“This is our first visit to Eldoret since Raila passed on. I want to ask you to continue the work of uniting Kenyans, just as he envisioned when he joined the broad-based government,”", "sayer": null, "position": 456}, {"text": "“Young people, I urge you to register and vote. Do not just claim ODM membership without using your vote. Your vote is your voice,”", "sayer": null, "position": 1485}]', NULL, 0, 88, 0, 0, 0, 'published', 'published', false, 'high', true, '2025-12-19 08:53:33.223', NULL, NULL, NULL, NULL, NULL, NULL, 'ODM, Oburu Odinga, William Ruto, broad-based government, Kenya politics, Uasin Gishu, Gladys Wanga, Simba Arati', 'ODM leader Oburu Odinga says the party will continue working with President William Ruto under the broad-based government until 2027.', 'Oburu Odinga news, ODM and Ruto, broad-based government Kenya, ODM politics, Kenya political cooperation, Uasin Gishu ODM', 2, '2025-12-16 08:53:33.223', '2025-12-15 17:10:33.204395', '2025-12-20 08:34:44.463894', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (6, 'Accusations Stir Debate Around Kenyan Anti-GBV Organisation Usikimye', '[HEADING]Social Media Claims Target Usikimye[/HEADING]

A wave of accusations circulating on social media has put Usikimye, a Kenyan organisation working with survivors of gender-based violence (GBV), at the centre of an intense public debate.

The claims, attributed to activist Stella Khachina, accuse Usikimye co-founder Njeri wa Migwi of fabricating or exaggerating GBV cases to solicit donations, failing to deliver promised support such as menstrual products, and allegedly shielding her son from grooming allegations involving an adopted sister.

The allegations have been shared alongside screenshots, audio recordings, and private messages, though they have not been independently verified.

[HEADING]Migwi Yet to Respond Publicly[/HEADING]

Njeri wa Migwi, herself a survivor of gender-based violence and a prominent advocate in the space, has so far not issued a public response addressing the claims.

Supporters note that Usikimye has previously stated it assisted more than 1,200 survivors this year alone, with cases reportedly backed by verified police reports and on-the-ground interventions.

[HIGHLIGHT]The organisation has been widely known for operating safe houses and providing emergency support to women and children facing violence.[/HIGHLIGHT]

[HEADING]Supporters Defend Organisation’s Work[/HEADING]

Several activists, donors, and members of the public have come out in defence of Usikimye, dismissing the accusations as a personal dispute and pointing to tangible work witnessed on the ground.

Human rights activist Boniface Mwangi warned against what he described as a coordinated attempt to damage Migwi’s reputation, while others shared personal accounts of visiting Usikimye facilities, donating resources, and interacting directly with survivors.

Some supporters stressed that in many GBV cases, grassroots organisations like Usikimye often step in where formal systems fail.

[HEADING]Calls for Accountability and Audits[/HEADING]

At the same time, sceptics have urged for transparency, with calls for independent audits and clear documentation to address the concerns being raised online.

Others have cautioned against trial by social media, arguing that allegations should be verified before conclusions are drawn.

[QUOTE]Several commentators have maintained that while accountability is important, discrediting an entire organisation without verified evidence risks undermining support systems for GBV survivors,[/QUOTE] one user noted.

[HEADING]A Broader National Conversation[/HEADING]

The unfolding debate comes amid growing concern over gender-based violence in Kenya, where cases continue to rise and support services remain strained.

As the story continues to evolve, observers have urged both restraint and responsibility, noting the delicate balance between demanding accountability and protecting critical services for vulnerable women and children.', 'Claims circulating on social media have placed Kenyan anti-gender-based violence organisation Usikimye under scrutiny, sparking a heated public debate over accountability, credibility, and the fight against GBV.', 'accusations-stir-debate-around-kenyan-anti-gbv-organisation-usikimye', 2, NULL, 5, '/uploads/images/image-png-1765808412152-834383348.png', '<h3 class="content-heading">Social Media Claims Target Usikimye</h3>

A wave of accusations circulating on social media has put Usikimye, a Kenyan organisation working with survivors of gender-based violence (GBV), at the centre of an intense public debate.

The claims, attributed to activist Stella Khachina, accuse Usikimye co-founder Njeri wa Migwi of fabricating or exaggerating GBV cases to solicit donations, failing to deliver promised support such as menstrual products, and allegedly shielding her son from grooming allegations involving an adopted sister.

The allegations have been shared alongside screenshots, audio recordings, and private messages, though they have not been independently verified.

<h3 class="content-heading">Migwi Yet to Respond Publicly</h3>

Njeri wa Migwi, herself a survivor of gender-based violence and a prominent advocate in the space, has so far not issued a public response addressing the claims.

Supporters note that Usikimye has previously stated it assisted more than 1,200 survivors this year alone, with cases reportedly backed by verified police reports and on-the-ground interventions.

<span class="news-highlight">The organisation has been widely known for operating safe houses and providing emergency support to women and children facing violence.</span>

<h3 class="content-heading">Supporters Defend Organisation’s Work</h3>

Several activists, donors, and members of the public have come out in defence of Usikimye, dismissing the accusations as a personal dispute and pointing to tangible work witnessed on the ground.

Human rights activist Boniface Mwangi warned against what he described as a coordinated attempt to damage Migwi’s reputation, while others shared personal accounts of visiting Usikimye facilities, donating resources, and interacting directly with survivors.

Some supporters stressed that in many GBV cases, grassroots organisations like Usikimye often step in where formal systems fail.

<h3 class="content-heading">Calls for Accountability and Audits</h3>

At the same time, sceptics have urged for transparency, with calls for independent audits and clear documentation to address the concerns being raised online.

Others have cautioned against trial by social media, arguing that allegations should be verified before conclusions are drawn.

<blockquote class="news-large-quote">Several commentators have maintained that while accountability is important, discrediting an entire organisation without verified evidence risks undermining support systems for GBV survivors,</blockquote> one user noted.

<h3 class="content-heading">A Broader National Conversation</h3>

The unfolding debate comes amid growing concern over gender-based violence in Kenya, where cases continue to rise and support services remain strained.

As the story continues to evolve, observers have urged both restraint and responsibility, noting the delicate balance between demanding accountability and protecting critical services for vulnerable women and children.', '[{"text": "Several commentators have maintained that while accountability is important, discrediting an entire organisation without verified evidence risks undermining support systems for GBV survivors,", "sayer": null, "position": 2288}]', NULL, 0, 2, 0, 0, 0, 'published', 'published', false, 'medium', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Usikimye, gender-based violence, Njeri wa Migwi, GBV Kenya, human rights, civil society, women’s rights, social media debate', 'Usikimye, a Kenyan anti-GBV organisation, faces social media accusations as supporters defend its work and critics call for audits.', 'Usikimye allegations, Njeri wa Migwi news, GBV organisations Kenya, gender-based violence support, Kenya human rights groups', 2, '2025-12-15 17:20:12.178', '2025-12-15 17:20:12.162694', '2025-12-17 14:33:46.768951', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (3, 'President Ruto Honours Truphena Muthoni for Historic Environmental Conservation Act', 'President William Samoei Ruto has lauded young Kenyan environmentalist Truphena Muthoni for her extraordinary dedication to environmental conservation, following her record-breaking feat of spending 72 continuous hours embracing an indigenous tree.

[QUOTE]“Truphena Muthoni is an exemplary young Kenyan whose dedication and determination embody the very best of our nation’s spirit,”[/QUOTE] President Ruto said after hosting her at his office.

The symbolic act, which drew national and international attention, was aimed at raising awareness on environmental conservation and the urgent challenge of climate change. Her initiative has been widely praised for spotlighting the importance of protecting indigenous trees as part of Kenya’s broader environmental agenda.

In recognition of her courage, resilience, and leadership, President Ruto appointed Truphena Muthoni as an Ambassador of the 15 Billion Tree Planting Campaign, a flagship national programme designed to enhance forest cover and safeguard Kenya’s environmental future.

[HIGHLIGHT]The 15 Billion Tree Planting Campaign is a key government initiative aimed at restoring degraded landscapes and strengthening climate resilience across the country.[/HIGHLIGHT]

Further acknowledging her inspiring contribution, the Kenya Wildlife Service (KWS) and the Kenya Tourism Board (KTB) have awarded Truphena and her team a fully sponsored holiday experience. The gesture is intended to celebrate her commitment to environmental stewardship while promoting eco-tourism and conservation awareness.

Additionally, the Ministry of Environment, Climate Change and Forestry has pledged to support the realization of her dream to visit Brazil. The visit will provide her with an opportunity to gain exposure to global conservation initiatives and strengthen her environmental leadership on the international stage.

As a mark of national honour for her exemplary service, President Ruto also conferred upon Truphena Muthoni the Head of State Commendation (HSC) Medal, recognizing her outstanding contribution to environmental protection and climate advocacy.

Her achievement has inspired many Kenyans, particularly young people, to take an active role in environmental conservation and sustainable development.', 'President William Ruto has honoured young environmentalist Truphena Muthoni for her record-breaking 72-hour tree conservation act, appointing her as an ambassador of the 15 Billion Tree Planting Campaign and awarding her the Head of State Commendation Medal.', 'president-ruto-honours-truphena-muthoni-for-historic-environmental-conservation-act', 2, NULL, 5, '/uploads/images/image-png-1765807154247-785692613.png', 'President William Samoei Ruto has lauded young Kenyan environmentalist Truphena Muthoni for her extraordinary dedication to environmental conservation, following her record-breaking feat of spending 72 continuous hours embracing an indigenous tree.

<blockquote class="news-large-quote">“Truphena Muthoni is an exemplary young Kenyan whose dedication and determination embody the very best of our nation’s spirit,”</blockquote> President Ruto said after hosting her at his office.

The symbolic act, which drew national and international attention, was aimed at raising awareness on environmental conservation and the urgent challenge of climate change. Her initiative has been widely praised for spotlighting the importance of protecting indigenous trees as part of Kenya’s broader environmental agenda.

In recognition of her courage, resilience, and leadership, President Ruto appointed Truphena Muthoni as an Ambassador of the 15 Billion Tree Planting Campaign, a flagship national programme designed to enhance forest cover and safeguard Kenya’s environmental future.

<span class="news-highlight">The 15 Billion Tree Planting Campaign is a key government initiative aimed at restoring degraded landscapes and strengthening climate resilience across the country.</span>

Further acknowledging her inspiring contribution, the Kenya Wildlife Service (KWS) and the Kenya Tourism Board (KTB) have awarded Truphena and her team a fully sponsored holiday experience. The gesture is intended to celebrate her commitment to environmental stewardship while promoting eco-tourism and conservation awareness.

Additionally, the Ministry of Environment, Climate Change and Forestry has pledged to support the realization of her dream to visit Brazil. The visit will provide her with an opportunity to gain exposure to global conservation initiatives and strengthen her environmental leadership on the international stage.

As a mark of national honour for her exemplary service, President Ruto also conferred upon Truphena Muthoni the Head of State Commendation (HSC) Medal, recognizing her outstanding contribution to environmental protection and climate advocacy.

Her achievement has inspired many Kenyans, particularly young people, to take an active role in environmental conservation and sustainable development.', '[{"text": "“Truphena Muthoni is an exemplary young Kenyan whose dedication and determination embody the very best of our nation’s spirit,”", "sayer": null, "position": 252}]', NULL, 0, 49, 0, 0, 0, 'published', 'published', false, 'high', true, '2025-12-22 16:59:14.487', NULL, NULL, NULL, NULL, NULL, NULL, 'environment, climate change, tree planting, William Ruto, Truphena Muthoni, conservation, Kenya news, environment ministry', 'President Ruto honours environmentalist Truphena Muthoni for her 72-hour tree conservation act, appointing her ambassador and awarding HSC medal.', 'Truphena Muthoni, William Ruto news, 15 billion tree campaign, Kenya environment news, climate change Kenya, tree planting initiative', 2, '2025-12-15 16:59:14.494', '2025-12-15 16:59:14.302738', '2025-12-20 07:52:37.379156', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (10, 'Court Allows Detectives to Detain Lolgorian Ward MCA Michael Seme for 21 Days Over Deadly Trans Mara Clashes', '[Heading]Court Allows Detectives to Detain Lolgorian Ward MCA Michael Seme for 21 Days Over Deadly Trans Mara Clashes[/Heading]

Detectives have been granted 21 days to detain Lolgorian Ward MCA Michael Seme as investigations continue into the recent deadly clashes in Trans Mara, Narok County.

The court order comes amid heightened security operations in Trans Mara South and Trans Mara West, following violence that has left at least four people dead and displaced over 1,800 residents.

[Heading]Curfew Imposed as Areas Gazetted Dangerous[/Heading]

The government has gazetted parts of Trans Mara as “security disturbed and dangerous areas”, allowing the deployment of enhanced security measures to contain the unrest.

[Quote]Speaking on Saturday, Deputy Inspector General of Police Eliud Lagat said a curfew starting at 6:00pm has been imposed in the affected regions as a special security operation gets underway to restore calm.[/Quote]

[Heading]Areas Affected by the Curfew[/Heading]

In Trans Mara West, the curfew applies to:

Nkararu

In Trans Mara South, the curfew covers:

Oldonyo-Orok

Siteti

Ololoma

Corner

Ratiki

Isokon

Kerinkani

Kondamet

Olkiloriti

Angata Barakoi

Kapkeres

Lolgorian town

Mashangwa

Sachangwan

[Heading]Deaths, Displacement and Property Destruction[/Heading]

Tribal clashes in the region have resulted in the death of civilians, destruction of property, and the burning of homes, forcing thousands of residents to flee.

[Quote]The Kenya Red Cross Society reported that clashes in Angata Barikkoi have displaced more than 1,800 people in just three days, as families sought safety in neighboring areas.[/Quote]

The violence is linked to renewed tensions between the Maasai and Kipsigis communities.

[Heading]Ultimatum Issued on Illegal Firearms[/Heading]

[Quote]DIG Lagat issued a 72-hour ultimatum to individuals in possession of illegal firearms to surrender the weapons voluntarily, warning that decisive action will be taken against those who fail to comply.[/Quote]

[Heading]Warning Against Incitement[/Heading]

The Deputy Inspector General warned politicians and individuals accused of inciting or financing the violence, stating that security agencies are pursuing all leads and those responsible will be held accountable.

Authorities say security operations will continue in Trans Mara as efforts intensify to restore stability and prevent further loss of life.

[Highlights]

Court allows police to detain Lolgorian Ward MCA Michael Seme for 21 days

At least four people killed in renewed Trans Mara clashes

More than 1,800 residents displaced following violence in Narok County

Government imposes 6:00pm curfew in Trans Mara South and West

Several areas gazetted as security disturbed and dangerous

Police issue 72-hour ultimatum for surrender of illegal firearms

Leaders warned against inciting or financing violence
[/Highlights]', 'Detectives have been granted 21 days to detain Lolgorian Ward MCA Michael Seme as investigations continue into deadly Trans Mara clashes that have left several people dead and displaced over 1,800 residents.', 'court-allows-detectives-to-detain-lolgorian-ward-mca-michael-seme-for-21-days-over-deadly-trans-mara-clashes', 32, NULL, 5, '/uploads/images/image-png-1766609869807-377716517.png', '[Heading]Court Allows Detectives to Detain Lolgorian Ward MCA Michael Seme for 21 Days Over Deadly Trans Mara Clashes[/Heading]

Detectives have been granted 21 days to detain Lolgorian Ward MCA Michael Seme as investigations continue into the recent deadly clashes in Trans Mara, Narok County.

The court order comes amid heightened security operations in Trans Mara South and Trans Mara West, following violence that has left at least four people dead and displaced over 1,800 residents.

[Heading]Curfew Imposed as Areas Gazetted Dangerous[/Heading]

The government has gazetted parts of Trans Mara as “security disturbed and dangerous areas”, allowing the deployment of enhanced security measures to contain the unrest.

[Quote]Speaking on Saturday, Deputy Inspector General of Police Eliud Lagat said a curfew starting at 6:00pm has been imposed in the affected regions as a special security operation gets underway to restore calm.[/Quote]

[Heading]Areas Affected by the Curfew[/Heading]

In Trans Mara West, the curfew applies to:

Nkararu

In Trans Mara South, the curfew covers:

Oldonyo-Orok

Siteti

Ololoma

Corner

Ratiki

Isokon

Kerinkani

Kondamet

Olkiloriti

Angata Barakoi

Kapkeres

Lolgorian town

Mashangwa

Sachangwan

[Heading]Deaths, Displacement and Property Destruction[/Heading]

Tribal clashes in the region have resulted in the death of civilians, destruction of property, and the burning of homes, forcing thousands of residents to flee.

[Quote]The Kenya Red Cross Society reported that clashes in Angata Barikkoi have displaced more than 1,800 people in just three days, as families sought safety in neighboring areas.[/Quote]

The violence is linked to renewed tensions between the Maasai and Kipsigis communities.

[Heading]Ultimatum Issued on Illegal Firearms[/Heading]

[Quote]DIG Lagat issued a 72-hour ultimatum to individuals in possession of illegal firearms to surrender the weapons voluntarily, warning that decisive action will be taken against those who fail to comply.[/Quote]

[Heading]Warning Against Incitement[/Heading]

The Deputy Inspector General warned politicians and individuals accused of inciting or financing the violence, stating that security agencies are pursuing all leads and those responsible will be held accountable.

Authorities say security operations will continue in Trans Mara as efforts intensify to restore stability and prevent further loss of life.

[Highlights]

Court allows police to detain Lolgorian Ward MCA Michael Seme for 21 days

At least four people killed in renewed Trans Mara clashes

More than 1,800 residents displaced following violence in Narok County

Government imposes 6:00pm curfew in Trans Mara South and West

Several areas gazetted as security disturbed and dangerous

Police issue 72-hour ultimatum for surrender of illegal firearms

Leaders warned against inciting or financing violence
[/Highlights]', '[]', NULL, 0, 1, 0, 0, 0, 'published', 'published', false, 'medium', true, '2025-12-27 23:57:49.844', NULL, NULL, NULL, NULL, NULL, NULL, 'Narok, Trans Mara, Lolgorian, MCA Michael Seme, Tribal Clashes, Curfew, Kenya Police, DIG Eliud Lagat, Security', 'Police have been granted 21 days to detain Lolgorian Ward MCA Michael Seme as investigations continue into deadly Trans Mara clashes that have killed four people and displaced over 1,800 residents.', 'Trans Mara clashes, Lolgorian MCA detained, Michael Seme arrest, Narok County violence, Kenya curfew news, DIG Eliud Lagat, tribal clashes Kenya, Trans Mara security', 3, '2025-12-24 23:57:49.844', '2025-12-24 23:57:49.824858', '2025-12-24 23:57:49.824858', true, '2025-12-25 08:57:49.844', true, 'gold', '2025-12-27 23:57:49.844', 72, 9);
INSERT INTO public.news VALUES (8, 'Kenyan Activist Charged Over Social Media Post Allegedly Inciting Violence', 'The Directorate of Criminal Investigations (DCI) on Monday arraigned activist Boniface Mulinge Muteti before the Milimani Law Courts, charging him under Kenya’s 2018 Computer Misuse and Cybercrimes Act.

According to prosecutors, Muteti published a post on December 6 calling on citizens to seize property belonging to politicians, arm themselves, and prepare for an uprising. Authorities allege that the activist knowingly disseminated false information with the intention of inciting violence.

The DCI said the charges were approved following investigations by the Special Crime Unit, adding that the content posed a risk to public order and national security.

[HEADING]Supporters Decry Arrest[/HEADING]

Muteti, who describes himself as a human rights activist, has drawn significant public support online, with allies portraying him as a vocal critic of corruption, economic hardship, and governance under President William Ruto’s administration.

[HIGHLIGHT]Supporters insist that activism is not a crime and argue that the charges are intended to silence dissent.[/HIGHLIGHT]

Several social justice groups and activists have shared messages of solidarity, calling for his immediate release and questioning the use of cybercrime laws against political speech.

[HEADING]Previous Confrontations With Authorities[/HEADING]

Muteti has previously made headlines after disrupting court proceedings in Kibera while protesting alleged police killings, actions that elevated his profile among activist circles but also placed him in frequent confrontation with law enforcement agencies.

His critics, however, argue that the language used in his December post crossed the line from activism into incitement.

[HEADING]Awaiting Pretrial Hearing[/HEADING]

The court released Muteti pending further proceedings, with a pretrial hearing scheduled for December 30.

As the case unfolds, it has reignited debate over freedom of expression, the limits of political activism, and the state’s response to rising public frustration amid Kenya’s ongoing economic and social challenges.

Observers have urged both restraint and due process, noting the importance of balancing public safety with constitutional protections for free speech.', 'Human rights activist Boniface Mulinge Muteti has been charged under Kenya’s cybercrimes law over a social media post prosecutors say incited violence, a move supporters have condemned as political intimidation.', 'kenyan-activist-charged-over-social-media-post-allegedly-inciting-violence', 38, NULL, 5, '/uploads/images/image-png-1765864086346-719370676.png', 'The Directorate of Criminal Investigations (DCI) on Monday arraigned activist Boniface Mulinge Muteti before the Milimani Law Courts, charging him under Kenya’s 2018 Computer Misuse and Cybercrimes Act.

According to prosecutors, Muteti published a post on December 6 calling on citizens to seize property belonging to politicians, arm themselves, and prepare for an uprising. Authorities allege that the activist knowingly disseminated false information with the intention of inciting violence.

The DCI said the charges were approved following investigations by the Special Crime Unit, adding that the content posed a risk to public order and national security.

<h3 class="content-heading">Supporters Decry Arrest</h3>

Muteti, who describes himself as a human rights activist, has drawn significant public support online, with allies portraying him as a vocal critic of corruption, economic hardship, and governance under President William Ruto’s administration.

<span class="news-highlight">Supporters insist that activism is not a crime and argue that the charges are intended to silence dissent.</span>

Several social justice groups and activists have shared messages of solidarity, calling for his immediate release and questioning the use of cybercrime laws against political speech.

<h3 class="content-heading">Previous Confrontations With Authorities</h3>

Muteti has previously made headlines after disrupting court proceedings in Kibera while protesting alleged police killings, actions that elevated his profile among activist circles but also placed him in frequent confrontation with law enforcement agencies.

His critics, however, argue that the language used in his December post crossed the line from activism into incitement.

<h3 class="content-heading">Awaiting Pretrial Hearing</h3>

The court released Muteti pending further proceedings, with a pretrial hearing scheduled for December 30.

As the case unfolds, it has reignited debate over freedom of expression, the limits of political activism, and the state’s response to rising public frustration amid Kenya’s ongoing economic and social challenges.

Observers have urged both restraint and due process, noting the importance of balancing public safety with constitutional protections for free speech.', '[]', NULL, 0, 3, 0, 0, 0, 'published', 'published', false, 'high', false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Boniface Mulinge Muteti, DCI Kenya, cybercrimes law, activism, Kenya politics, freedom of expression, social justice', 'Kenyan activist Boniface Mulinge Muteti is charged under cybercrimes law over a social media post prosecutors say incited violence.', 'Boniface Mulinge Muteti arrest, Kenya cybercrimes law, DCI charges activist, freedom of speech Kenya, political activism', 2, '2025-12-16 10:10:43.814', '2025-12-16 08:48:06.364263', '2025-12-16 10:10:43.790241', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (2, '15 Kenyans Listed in High-Profile U.S. Deportation Report as DHS Publishes “Worst of the Worst” Criminal Case', '15 Kenyans Listed on High-Profile U.S. Deportation Roll as DHS Publishes “Worst of the Worst” Criminal Cases

Fifteen Kenyan nationals have been listed in a new high-profile deportation report released by the United States Department of Homeland Security (DHS). The individuals appear among thousands of foreign nationals categorized by the agency as part of the “worst of the worst” criminal illegal immigrants arrested across the country.

The list was published on Monday, December 8, following the launch of a dedicated DHS enforcement transparency portal that allows the public to search, view, and track arrest records of non-U.S. citizens detained across all 50 states. The portal includes data dating back to intensified immigration operations that began under former President Donald Trump’s administration.

DHS says the platform is meant to enhance visibility around immigration enforcement and make key arrest information accessible to the public.

Crimes Linked to the Kenyan Nationals

According to DHS records, the 15 Kenyans listed face a range of serious allegations similar to cases involving individuals from other countries. The most common offences are assault-related crimes, including cases that involve the use of weapons.

Other accusations include:

Aggravated assault with a weapon

Possession of stolen property

Terroristic threat-related offences

Simple assault

Money laundering

Forgery of checks

Driving under the influence (DUI)

Domestic violence

Robbery

Fighting to avoid prosecution

Fraud-related offences

Kidnapping of a minor

Violation of court orders

Receiving stolen property

DHS classifies these charges as major public safety concerns, placing the Kenyans among individuals flagged for priority removal under tightened immigration and security policies.

Push for Transparency

The publication of the list is part of DHS’s broader effort to increase transparency around immigration enforcement. The agency says the portal illustrates the scale of operations carried out under stricter immigration directives, and offers the public a clearer understanding of what types of cases lead to deportation proceedings.

The move comes amid ongoing national debates in the U.S. on immigration, deportation practices, and public safety. The newly released data highlights the continually evolving intersection between crime and immigration policy — a topic that remains politically sensitive and widely discussed.', 'Fifteen Kenyan nationals have been listed in a new U.S. Homeland Security deportation report that labels them among the “worst of the worst” criminal illegal immigrants facing removal for serious offences.', '15-kenyans-listed-in-high-profile-us-deportation-report-as-dhs-publishes-worst-of-the-worst-criminal-case', 26, NULL, 5, '/uploads/images/Trumpdeportation-jpg-1765397461112-27192083.jpg', '15 Kenyans Listed on High-Profile U.S. Deportation Roll as DHS Publishes “Worst of the Worst” Criminal Cases

Fifteen Kenyan nationals have been listed in a new high-profile deportation report released by the United States Department of Homeland Security (DHS). The individuals appear among thousands of foreign nationals categorized by the agency as part of the “worst of the worst” criminal illegal immigrants arrested across the country.

The list was published on Monday, December 8, following the launch of a dedicated DHS enforcement transparency portal that allows the public to search, view, and track arrest records of non-U.S. citizens detained across all 50 states. The portal includes data dating back to intensified immigration operations that began under former President Donald Trump’s administration.

DHS says the platform is meant to enhance visibility around immigration enforcement and make key arrest information accessible to the public.

Crimes Linked to the Kenyan Nationals

According to DHS records, the 15 Kenyans listed face a range of serious allegations similar to cases involving individuals from other countries. The most common offences are assault-related crimes, including cases that involve the use of weapons.

Other accusations include:

Aggravated assault with a weapon

Possession of stolen property

Terroristic threat-related offences

Simple assault

Money laundering

Forgery of checks

Driving under the influence (DUI)

Domestic violence

Robbery

Fighting to avoid prosecution

Fraud-related offences

Kidnapping of a minor

Violation of court orders

Receiving stolen property

DHS classifies these charges as major public safety concerns, placing the Kenyans among individuals flagged for priority removal under tightened immigration and security policies.

Push for Transparency

The publication of the list is part of DHS’s broader effort to increase transparency around immigration enforcement. The agency says the portal illustrates the scale of operations carried out under stricter immigration directives, and offers the public a clearer understanding of what types of cases lead to deportation proceedings.

The move comes amid ongoing national debates in the U.S. on immigration, deportation practices, and public safety. The newly released data highlights the continually evolving intersection between crime and immigration policy — a topic that remains politically sensitive and widely discussed.', '[]', NULL, 0, 28, 0, 0, 0, 'published', 'published', false, 'medium', true, '2025-12-17 23:11:01.375', NULL, NULL, NULL, NULL, NULL, NULL, 'DHS deportation list, Kenyan nationals U.S., worst of worst immigrants, U.S. immigration enforcement, DHS crime report, deportation Kenya, immigration news, U.S. arrests DHS', 'Kenya, United States, Deportation, DHS, Immigration, Crime, International News, Diaspora', 'Deportation Kenya', 2, '2025-12-10 23:11:01.375', '2025-12-10 23:11:01.176903', '2025-12-19 16:05:13.737805', false, NULL, false, NULL, NULL, 72, 9);
INSERT INTO public.news VALUES (7, 'Blow to Manchester United’s Top-Four Push After Eight-Goal Premier League Thriller', 'Manchester United and Bournemouth produced one of the Premier League’s most entertaining matches of the season, sharing the points in a pulsating 4-4 draw that swung repeatedly from one side to the other.

The result dented United’s push toward the top four, despite a bold tactical experiment from head coach Ruben Amorim, who moved away from his trusted 3-4-3 formation. The Portuguese coach began with a modified back four and later took further risks, briefly deploying a 4-2-4 as the match opened up.

[HEADING]Fast Start and First-Half Dominance[/HEADING]

United were dominant in the opening stages, registering 17 shots in the first half — the most by any Premier League side before the break this season.

Their pressure paid off in the 13th minute when Amad Diallo headed home in what was his final appearance before departing for the Africa Cup of Nations. After a VAR check involving Matheus Cunha, the goal was allowed to stand.

Despite controlling the game, defensive lapses again proved costly. Luke Shaw was outmuscled in midfield, allowing Antoine Semenyo to break through and finish clinically for Bournemouth’s equaliser against the run of play.

United regained the lead just before half-time when Casemiro rose highest to nod in from a corner, marking their seventh set-piece goal of the campaign.

[HEADING]Second-Half Chaos and Momentum Swings[/HEADING]

The match turned dramatically after the interval. Bournemouth struck just 38 seconds into the second half as Evanilson fired in a fine finish to make it 2-2. Moments later, Marcus Tavernier curled a superb free-kick into the bottom corner to put the visitors ahead.

United responded in kind, producing two goals in quick succession. Bruno Fernandes levelled with a brilliant free-kick before Cunha reacted quickest inside the box to restore United’s advantage.

[HIGHLIGHT]With both sides refusing to settle, another goal always felt inevitable.[/HIGHLIGHT]

That moment came late on when substitute Eli Junior Kroupi burst through United’s central defence and calmly slotted home to complete an extraordinary eight-goal contest.

[HEADING]Table Impact and Post-Match Reaction[/HEADING]

The draw leaves Manchester United sixth in the Premier League on 26 points, level with Crystal Palace, Liverpool, and Sunderland. Bournemouth move up to 13th place following an impressive away performance.

Sky Sports pundit Jamie Carragher described the encounter as the best Premier League game of the season so far, praising United’s first-half display as their most convincing under Amorim.

[QUOTE]“That was Manchester United at their best — fast, aggressive, attacking football. It felt like a throwback to the Ferguson era,”[/QUOTE] Carragher said.

[HEADING]Managers Reflect on Missed Opportunity[/HEADING]

Speaking after the match, Amorim admitted his side should have taken all three points.

[QUOTE]“We played very well, especially in the first half. The result should be different,”[/QUOTE] he said, adding that game management and concentration remain areas for improvement.

Bournemouth manager Andoni Iraola also reflected on a match filled with momentum shifts, saying both sides attacked far better than they defended.

[QUOTE]“It had everything. At times we thought we might lose it, then win it. In the end, a point feels fair,”[/QUOTE] Iraola noted.', 'Manchester United’s hopes of closing in on the Premier League top four suffered a setback after a dramatic 4-4 draw with Bournemouth, as Ruben Amorim’s experimental setup delivered attacking flair but exposed defensive frailties.', 'blow-to-manchester-uniteds-top-four-push-after-eight-goal-premier-league-thriller', 52, NULL, 5, '/uploads/images/image-png-1765863469628-555038776.png', 'Manchester United and Bournemouth produced one of the Premier League’s most entertaining matches of the season, sharing the points in a pulsating 4-4 draw that swung repeatedly from one side to the other.

The result dented United’s push toward the top four, despite a bold tactical experiment from head coach Ruben Amorim, who moved away from his trusted 3-4-3 formation. The Portuguese coach began with a modified back four and later took further risks, briefly deploying a 4-2-4 as the match opened up.

<h3 class="content-heading">Fast Start and First-Half Dominance</h3>

United were dominant in the opening stages, registering 17 shots in the first half — the most by any Premier League side before the break this season.

Their pressure paid off in the 13th minute when Amad Diallo headed home in what was his final appearance before departing for the Africa Cup of Nations. After a VAR check involving Matheus Cunha, the goal was allowed to stand.

Despite controlling the game, defensive lapses again proved costly. Luke Shaw was outmuscled in midfield, allowing Antoine Semenyo to break through and finish clinically for Bournemouth’s equaliser against the run of play.

United regained the lead just before half-time when Casemiro rose highest to nod in from a corner, marking their seventh set-piece goal of the campaign.

<h3 class="content-heading">Second-Half Chaos and Momentum Swings</h3>

The match turned dramatically after the interval. Bournemouth struck just 38 seconds into the second half as Evanilson fired in a fine finish to make it 2-2. Moments later, Marcus Tavernier curled a superb free-kick into the bottom corner to put the visitors ahead.

United responded in kind, producing two goals in quick succession. Bruno Fernandes levelled with a brilliant free-kick before Cunha reacted quickest inside the box to restore United’s advantage.

<span class="news-highlight">With both sides refusing to settle, another goal always felt inevitable.</span>

That moment came late on when substitute Eli Junior Kroupi burst through United’s central defence and calmly slotted home to complete an extraordinary eight-goal contest.

<h3 class="content-heading">Table Impact and Post-Match Reaction</h3>

The draw leaves Manchester United sixth in the Premier League on 26 points, level with Crystal Palace, Liverpool, and Sunderland. Bournemouth move up to 13th place following an impressive away performance.

Sky Sports pundit Jamie Carragher described the encounter as the best Premier League game of the season so far, praising United’s first-half display as their most convincing under Amorim.

<blockquote class="news-large-quote">“That was Manchester United at their best — fast, aggressive, attacking football. It felt like a throwback to the Ferguson era,”</blockquote> Carragher said.

<h3 class="content-heading">Managers Reflect on Missed Opportunity</h3>

Speaking after the match, Amorim admitted his side should have taken all three points.

<blockquote class="news-large-quote">“We played very well, especially in the first half. The result should be different,”</blockquote> he said, adding that game management and concentration remain areas for improvement.

Bournemouth manager Andoni Iraola also reflected on a match filled with momentum shifts, saying both sides attacked far better than they defended.

<blockquote class="news-large-quote">“It had everything. At times we thought we might lose it, then win it. In the end, a point feels fair,”</blockquote> Iraola noted.', '[{"text": "“That was Manchester United at their best — fast, aggressive, attacking football. It felt like a throwback to the Ferguson era,”", "sayer": null, "position": 2594}, {"text": "“We played very well, especially in the first half. The result should be different,”", "sayer": null, "position": 2908}, {"text": "“It had everything. At times we thought we might lose it, then win it. In the end, a point feels fair,”", "sayer": null, "position": 3246}]', NULL, 0, 34, 0, 0, 0, 'published', 'published', false, 'high', true, '2025-12-19 08:37:49.746', NULL, NULL, NULL, NULL, NULL, NULL, 'Manchester United, Bournemouth, Premier League, Ruben Amorim, Bruno Fernandes, Amad Diallo, football news, EPL highlights', 'Manchester United draw 4-4 with Bournemouth in a thrilling Premier League clash, denting top-four hopes despite an attacking display.', 'Man Utd vs Bournemouth, Premier League results, Ruben Amorim tactics, Manchester United top four, EPL match report', 3, '2025-12-16 08:37:49.746', '2025-12-16 08:37:49.665402', '2025-12-19 20:26:06.730681', false, NULL, false, NULL, NULL, 72, 9);


--
-- Data for Name: news_approval_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news_categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.news_categories VALUES (1, 1, 28, true, '2025-12-10 15:28:53.497976');
INSERT INTO public.news_categories VALUES (2, 1, 37, false, '2025-12-10 15:28:53.497976');
INSERT INTO public.news_categories VALUES (3, 2, 26, true, '2025-12-10 23:11:01.176903');
INSERT INTO public.news_categories VALUES (4, 2, 85, false, '2025-12-10 23:11:01.176903');
INSERT INTO public.news_categories VALUES (5, 3, 2, true, '2025-12-15 16:59:14.302738');
INSERT INTO public.news_categories VALUES (6, 3, 26, false, '2025-12-15 16:59:14.302738');
INSERT INTO public.news_categories VALUES (7, 3, 83, false, '2025-12-15 16:59:14.302738');
INSERT INTO public.news_categories VALUES (8, 3, 82, false, '2025-12-15 16:59:14.302738');
INSERT INTO public.news_categories VALUES (9, 4, 37, true, '2025-12-15 17:06:14.012383');
INSERT INTO public.news_categories VALUES (10, 4, 45, false, '2025-12-15 17:06:14.012383');
INSERT INTO public.news_categories VALUES (14, 6, 2, true, '2025-12-15 17:20:12.162694');
INSERT INTO public.news_categories VALUES (15, 6, 27, false, '2025-12-15 17:20:12.162694');
INSERT INTO public.news_categories VALUES (16, 6, 6, false, '2025-12-15 17:20:12.162694');
INSERT INTO public.news_categories VALUES (17, 7, 52, true, '2025-12-16 08:37:49.665402');
INSERT INTO public.news_categories VALUES (18, 7, 5, false, '2025-12-16 08:37:49.665402');
INSERT INTO public.news_categories VALUES (19, 7, 26, false, '2025-12-16 08:37:49.665402');
INSERT INTO public.news_categories VALUES (20, 7, 27, false, '2025-12-16 08:37:49.665402');
INSERT INTO public.news_categories VALUES (22, 5, 37, true, '2025-12-16 08:53:33.219201');
INSERT INTO public.news_categories VALUES (23, 5, 38, false, '2025-12-16 08:53:33.219201');
INSERT INTO public.news_categories VALUES (24, 5, 45, false, '2025-12-16 08:53:33.219201');
INSERT INTO public.news_categories VALUES (25, 5, 48, false, '2025-12-16 08:53:33.219201');
INSERT INTO public.news_categories VALUES (26, 8, 38, true, '2025-12-16 10:10:43.790241');
INSERT INTO public.news_categories VALUES (27, 8, 37, false, '2025-12-16 10:10:43.790241');
INSERT INTO public.news_categories VALUES (28, 8, 6, false, '2025-12-16 10:10:43.790241');
INSERT INTO public.news_categories VALUES (35, 9, 2, true, '2025-12-19 10:39:20.585506');
INSERT INTO public.news_categories VALUES (36, 9, 38, false, '2025-12-19 10:39:20.585506');
INSERT INTO public.news_categories VALUES (37, 9, 27, false, '2025-12-19 10:39:20.585506');
INSERT INTO public.news_categories VALUES (38, 10, 88, false, '2025-12-24 23:57:49.824858');
INSERT INTO public.news_categories VALUES (39, 10, 89, false, '2025-12-24 23:57:49.824858');
INSERT INTO public.news_categories VALUES (40, 10, 2, false, '2025-12-24 23:57:49.824858');
INSERT INTO public.news_categories VALUES (41, 10, 32, true, '2025-12-24 23:57:49.824858');


--
-- Data for Name: news_comments; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.news_images VALUES (1, 1, '/uploads/images/Sakaja-jpg-1765369733473-660383003.jpg', '', NULL, 0, true, NULL, NULL, 109940, 'image/jpeg', 'local', NULL, NULL, '{"size": 109940, "mimetype": "image/jpeg", "variants": null, "originalName": "Sakaja.jpg"}', '2025-12-10 15:28:53.497976');
INSERT INTO public.news_images VALUES (2, 1, '/uploads/images/OIP--1--webp-1765369733486-78511688.webp', '', NULL, 1, false, NULL, NULL, 22112, 'image/webp', 'local', NULL, NULL, '{"size": 22112, "mimetype": "image/webp", "variants": null, "originalName": "OIP (1).webp"}', '2025-12-10 15:28:53.497976');
INSERT INTO public.news_images VALUES (3, 2, '/uploads/images/Trumpdeportation-jpg-1765397461112-27192083.jpg', '', NULL, 0, true, NULL, NULL, 33119, 'image/jpeg', 'local', NULL, NULL, '{"size": 33119, "mimetype": "image/jpeg", "variants": null, "originalName": "Trumpdeportation.jpg"}', '2025-12-10 23:11:01.176903');
INSERT INTO public.news_images VALUES (4, 2, '/uploads/images/Trumpdata-jpg-1765397461114-320371137.jpg', '', NULL, 1, false, NULL, NULL, 174636, 'image/jpeg', 'local', NULL, NULL, '{"size": 174636, "mimetype": "image/jpeg", "variants": null, "originalName": "Trumpdata.jpg"}', '2025-12-10 23:11:01.176903');
INSERT INTO public.news_images VALUES (5, 2, '/uploads/images/85acbd70-9d11-11ef-ba27-436d7cb83cab-jpg-1765397461163-443397063.jpg', '', NULL, 2, false, NULL, NULL, 113677, 'image/jpeg', 'local', NULL, NULL, '{"size": 113677, "mimetype": "image/jpeg", "variants": null, "originalName": "85acbd70-9d11-11ef-ba27-436d7cb83cab.jpg"}', '2025-12-10 23:11:01.176903');
INSERT INTO public.news_images VALUES (6, 3, '/uploads/images/image-png-1765807154247-785692613.png', '', NULL, 0, true, NULL, NULL, 1817788, 'image/png', 'local', NULL, NULL, '{"size": 1817788, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 16:59:14.302738');
INSERT INTO public.news_images VALUES (7, 3, '/uploads/images/image-png-1765807154265-769270799.png', '', NULL, 1, false, NULL, NULL, 3302216, 'image/png', 'local', NULL, NULL, '{"size": 3302216, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 16:59:14.302738');
INSERT INTO public.news_images VALUES (8, 3, '/uploads/images/image-png-1765807154292-387288980.png', '', NULL, 2, false, NULL, NULL, 1454822, 'image/png', 'local', NULL, NULL, '{"size": 1454822, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 16:59:14.302738');
INSERT INTO public.news_images VALUES (9, 4, '/uploads/images/image-png-1765807573992-747793618.png', '', NULL, 0, true, NULL, NULL, 722776, 'image/png', 'local', NULL, NULL, '{"size": 722776, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:06:14.012383');
INSERT INTO public.news_images VALUES (10, 4, '/uploads/images/image-png-1765807574000-896800041.png', '', NULL, 1, false, NULL, NULL, 407872, 'image/png', 'local', NULL, NULL, '{"size": 407872, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:06:14.012383');
INSERT INTO public.news_images VALUES (11, 4, '/uploads/images/image-png-1765807574004-129772125.png', '', NULL, 2, false, NULL, NULL, 467888, 'image/png', 'local', NULL, NULL, '{"size": 467888, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:06:14.012383');
INSERT INTO public.news_images VALUES (12, 5, '/uploads/images/image-png-1765807833195-88072398.png', '', NULL, 0, true, NULL, NULL, 886687, 'image/png', 'local', NULL, NULL, '{"size": 886687, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:10:33.204395');
INSERT INTO public.news_images VALUES (13, 5, '/uploads/images/image-png-1765807833202-792004822.png', '', NULL, 1, false, NULL, NULL, 121930, 'image/png', 'local', NULL, NULL, '{"size": 121930, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:10:33.204395');
INSERT INTO public.news_images VALUES (14, 6, '/uploads/images/image-png-1765808412152-834383348.png', '', NULL, 0, true, NULL, NULL, 143557, 'image/png', 'local', NULL, NULL, '{"size": 143557, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:20:12.162694');
INSERT INTO public.news_images VALUES (15, 6, '/uploads/images/image-png-1765808412158-757295710.png', '', NULL, 1, false, NULL, NULL, 55716, 'image/png', 'local', NULL, NULL, '{"size": 55716, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:20:12.162694');
INSERT INTO public.news_images VALUES (16, 6, '/uploads/images/image-png-1765808412159-460387633.png', '', NULL, 2, false, NULL, NULL, 127690, 'image/png', 'local', NULL, NULL, '{"size": 127690, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-15 17:20:12.162694');
INSERT INTO public.news_images VALUES (17, 7, '/uploads/images/image-png-1765863469628-555038776.png', '', NULL, 0, true, NULL, NULL, 1252599, 'image/png', 'local', NULL, NULL, '{"size": 1252599, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-16 08:37:49.665402');
INSERT INTO public.news_images VALUES (18, 7, '/uploads/images/image-png-1765863469644-716375671.png', '', NULL, 1, false, NULL, NULL, 1304350, 'image/png', 'local', NULL, NULL, '{"size": 1304350, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-16 08:37:49.665402');
INSERT INTO public.news_images VALUES (19, 8, '/uploads/images/image-png-1765864086346-719370676.png', '', NULL, 0, true, NULL, NULL, 481461, 'image/png', 'local', NULL, NULL, '{"size": 481461, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-16 08:48:06.364263');
INSERT INTO public.news_images VALUES (20, 8, '/uploads/images/image-png-1765864086359-922854394.png', '', NULL, 1, false, NULL, NULL, 653805, 'image/png', 'local', NULL, NULL, '{"size": 653805, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-16 08:48:06.364263');
INSERT INTO public.news_images VALUES (21, 9, '/uploads/images/image-png-1766128941542-308344215.png', '', NULL, 0, true, NULL, NULL, 1999091, 'image/png', 'local', NULL, NULL, '{"size": 1999091, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-19 10:22:21.606837');
INSERT INTO public.news_images VALUES (22, 9, '/uploads/images/image-png-1766128941559-8275572.png', '', NULL, 1, false, NULL, NULL, 1725998, 'image/png', 'local', NULL, NULL, '{"size": 1725998, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-19 10:22:21.606837');
INSERT INTO public.news_images VALUES (23, 9, '/uploads/images/image-png-1766128941569-890768249.png', '', NULL, 2, false, NULL, NULL, 1971079, 'image/png', 'local', NULL, NULL, '{"size": 1971079, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-19 10:22:21.606837');
INSERT INTO public.news_images VALUES (24, 9, '/uploads/images/image-png-1766128941578-358833521.png', '', NULL, 3, false, NULL, NULL, 1777770, 'image/png', 'local', NULL, NULL, '{"size": 1777770, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-19 10:22:21.606837');
INSERT INTO public.news_images VALUES (25, 10, '/uploads/images/image-png-1766609869807-377716517.png', '', NULL, 0, true, NULL, NULL, 113251, 'image/png', 'local', NULL, NULL, '{"size": 113251, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-24 23:57:49.824858');
INSERT INTO public.news_images VALUES (26, 10, '/uploads/images/image-png-1766609869810-825345492.png', '', NULL, 1, false, NULL, NULL, 670485, 'image/png', 'local', NULL, NULL, '{"size": 670485, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-24 23:57:49.824858');
INSERT INTO public.news_images VALUES (27, 10, '/uploads/images/image-png-1766609869820-796913326.png', '', NULL, 2, false, NULL, NULL, 108770, 'image/png', 'local', NULL, NULL, '{"size": 108770, "mimetype": "image/png", "variants": null, "originalName": "image.png"}', '2025-12-24 23:57:49.824858');


--
-- Data for Name: news_quotes; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news_shares; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: news_social_media; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.news_social_media VALUES (1, 10, 'youtube_video', 'video', 'https://www.youtube.com/watch?v=2K47A4Vs4qA', NULL, NULL, NULL, 'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=2K47A4Vs4qA&format=json', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '[]', NULL, NULL, 0, 0, 0, 0, 0, 0, true, true, true, '', '{}', '{}', NULL, '{}', NULL, NULL, '2025-12-24 23:57:49.824858+03', '2025-12-24 23:57:49.824858+03', NULL);


--
-- Data for Name: news_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: newsletters; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: page_views; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: public_session_store; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: referrals; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: scheduler_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: session_store; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.session_store VALUES ('fCyW992pyWqx6kDoVkK7tLJcDHkhL_Ym', '{"cookie":{"originalMaxAge":86400000,"expires":"2025-12-22T06:51:41.447Z","secure":false,"httpOnly":true,"path":"/","sameSite":"lax"},"adminId":5,"loginTime":"2025-12-21T06:51:41.424Z","csrfToken":"8b97d619a559cb71c644f38b473cbe31181c54718332dff20533f501a3e7bbef"}', '2025-12-26 01:14:12');
INSERT INTO public.session_store VALUES ('7WFfMk3Z7wnHZuf9mWxdRcJzGyAeb7MJ', '{"cookie":{"originalMaxAge":86400000,"expires":"2025-12-25T22:23:14.049Z","secure":false,"httpOnly":true,"path":"/","sameSite":"lax"},"adminId":5,"loginTime":"2025-12-24T22:23:14.045Z","csrfToken":"02eea78219e577c97c1d21c1bb032ffae7f62efbabac693bf6c59805ba801c00"}', '2025-12-26 02:17:21');


--
-- Data for Name: social_embed_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: subscribers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.system_settings VALUES (1, 'social_embed_enabled', 'true', 'boolean', 'Enable social media embedding', false, '2025-12-19 09:10:35.793779', '2025-12-19 09:10:35.793779');
INSERT INTO public.system_settings VALUES (2, 'social_embed_cache_duration', '3600', 'number', 'Embed cache duration in seconds', false, '2025-12-19 09:10:35.793779', '2025-12-19 09:10:35.793779');


--
-- Data for Name: user_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_reading_history; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.user_roles VALUES (1, 'Super Administrator', 'super_admin', 'Full system access with all permissions', '{"global": true, "manage_ads": true, "manage_roles": true, "manage_users": true, "manage_admins": true, "manage_system": true, "manage_content": true, "view_analytics": true, "manage_settings": true}', true, '2025-12-07 12:18:11.133695', '2025-12-07 12:18:11.133695');
INSERT INTO public.user_roles VALUES (2, 'Contributor', 'contributor', 'Can submit content for review', '{"create_content": true, "edit_own_content": true}', true, '2025-12-07 15:10:13.143432', '2025-12-07 15:10:13.143432');


--
-- Data for Name: user_saved_articles; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Data for Name: volunteers; Type: TABLE DATA; Schema: public; Owner: postgres
--



--
-- Name: active_location_counts_location_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.active_location_counts_location_id_seq', 1, false);


--
-- Name: activity_log_activity_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_log_activity_id_seq', 1, false);


--
-- Name: ad_clicks_click_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_clicks_click_id_seq', 1, false);


--
-- Name: ad_impressions_impression_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_impressions_impression_id_seq', 1, false);


--
-- Name: ad_tiers_tier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_tiers_tier_id_seq', 1, false);


--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_activity_log_log_id_seq', 37, true);


--
-- Name: admin_chat_messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_chat_messages_message_id_seq', 1, false);


--
-- Name: admin_notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_notifications_notification_id_seq', 1, false);


--
-- Name: admin_permissions_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_permissions_permission_id_seq', 1, false);


--
-- Name: admins_admin_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admins_admin_id_seq', 5, true);


--
-- Name: advertisements_ad_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advertisements_ad_id_seq', 1, false);


--
-- Name: advertisers_advertiser_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.advertisers_advertiser_id_seq', 1, false);


--
-- Name: analytics_daily_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.analytics_daily_analytics_id_seq', 1, false);


--
-- Name: analytics_monthly_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.analytics_monthly_analytics_id_seq', 1, false);


--
-- Name: bookmarks_bookmark_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.bookmarks_bookmark_id_seq', 1, false);


--
-- Name: breaking_news_breaking_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.breaking_news_breaking_id_seq', 1, false);


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 98, true);


--
-- Name: cleanup_history_cleanup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cleanup_history_cleanup_id_seq', 1, false);


--
-- Name: cloudflare_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cloudflare_images_image_id_seq', 1, false);


--
-- Name: cookie_stats_daily_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cookie_stats_daily_stat_id_seq', 1, false);


--
-- Name: cookie_stats_monthly_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cookie_stats_monthly_stat_id_seq', 1, false);


--
-- Name: daily_location_stats_stat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.daily_location_stats_stat_id_seq', 1, false);


--
-- Name: donations_donation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.donations_donation_id_seq', 1, false);


--
-- Name: email_queue_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_queue_queue_id_seq', 1, false);


--
-- Name: event_registrations_registration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.event_registrations_registration_id_seq', 1, false);


--
-- Name: events_event_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.events_event_id_seq', 1, false);


--
-- Name: image_variants_variant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.image_variants_variant_id_seq', 1, false);


--
-- Name: media_files_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_files_file_id_seq', 1, false);


--
-- Name: monthly_location_summary_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.monthly_location_summary_summary_id_seq', 1, false);


--
-- Name: news_approval_history_approval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_approval_history_approval_id_seq', 1, false);


--
-- Name: news_categories_news_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_categories_news_category_id_seq', 41, true);


--
-- Name: news_comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_comments_comment_id_seq', 1, false);


--
-- Name: news_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_images_image_id_seq', 27, true);


--
-- Name: news_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_news_id_seq', 10, true);


--
-- Name: news_quotes_quote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_quotes_quote_id_seq', 67, true);


--
-- Name: news_reactions_reaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_reactions_reaction_id_seq', 1, false);


--
-- Name: news_shares_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_shares_share_id_seq', 1, false);


--
-- Name: news_social_media_social_media_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_social_media_social_media_id_seq', 1, true);


--
-- Name: news_videos_video_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_videos_video_id_seq', 1, false);


--
-- Name: newsletters_newsletter_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.newsletters_newsletter_id_seq', 1, false);


--
-- Name: page_views_view_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.page_views_view_id_seq', 1, false);


--
-- Name: referrals_referral_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.referrals_referral_id_seq', 1, false);


--
-- Name: role_permissions_permission_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_permissions_permission_id_seq', 1, false);


--
-- Name: scheduler_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scheduler_logs_log_id_seq', 1, false);


--
-- Name: social_embed_cache_cache_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.social_embed_cache_cache_id_seq', 1, false);


--
-- Name: subscribers_subscriber_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscribers_subscriber_id_seq', 1, false);


--
-- Name: system_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_logs_log_id_seq', 1, false);


--
-- Name: system_settings_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_settings_setting_id_seq', 2, true);


--
-- Name: user_notifications_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_notifications_notification_id_seq', 1, false);


--
-- Name: user_preferences_preference_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_preferences_preference_id_seq', 1, false);


--
-- Name: user_reading_history_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_reading_history_history_id_seq', 1, false);


--
-- Name: user_roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_roles_role_id_seq', 2, true);


--
-- Name: user_saved_articles_saved_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_saved_articles_saved_id_seq', 1, false);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 1, false);


--
-- Name: volunteers_volunteer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.volunteers_volunteer_id_seq', 1, false);


--
-- Name: active_location_counts active_location_counts_county_town_category_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_location_counts
    ADD CONSTRAINT active_location_counts_county_town_category_key UNIQUE (county, town, category);


--
-- Name: active_location_counts active_location_counts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.active_location_counts
    ADD CONSTRAINT active_location_counts_pkey PRIMARY KEY (location_id);


--
-- Name: activity_log activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_log
    ADD CONSTRAINT activity_log_pkey PRIMARY KEY (activity_id);


--
-- Name: ad_clicks ad_clicks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_clicks
    ADD CONSTRAINT ad_clicks_pkey PRIMARY KEY (click_id);


--
-- Name: ad_impressions ad_impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_impressions
    ADD CONSTRAINT ad_impressions_pkey PRIMARY KEY (impression_id);


--
-- Name: ad_tiers ad_tiers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_tiers
    ADD CONSTRAINT ad_tiers_pkey PRIMARY KEY (tier_id);


--
-- Name: ad_tiers ad_tiers_tier_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_tiers
    ADD CONSTRAINT ad_tiers_tier_name_key UNIQUE (tier_name);


--
-- Name: admin_activity_log admin_activity_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_pkey PRIMARY KEY (log_id);


--
-- Name: admin_chat_messages admin_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_pkey PRIMARY KEY (message_id);


--
-- Name: admin_notifications admin_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notifications
    ADD CONSTRAINT admin_notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: admin_online_status admin_online_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_online_status
    ADD CONSTRAINT admin_online_status_pkey PRIMARY KEY (admin_id);


--
-- Name: admin_permissions admin_permissions_admin_id_permission_name_resource_type_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_admin_id_permission_name_resource_type_key UNIQUE (admin_id, permission_name, resource_type);


--
-- Name: admin_permissions admin_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_pkey PRIMARY KEY (permission_id);


--
-- Name: admin_session_store admin_session_store_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_session_store
    ADD CONSTRAINT admin_session_store_pkey PRIMARY KEY (sid);


--
-- Name: admin_sessions admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: admins admins_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_email_key UNIQUE (email);


--
-- Name: admins admins_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_phone_key UNIQUE (phone);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (admin_id);


--
-- Name: admins admins_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_username_key UNIQUE (username);


--
-- Name: advertisements advertisements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisements
    ADD CONSTRAINT advertisements_pkey PRIMARY KEY (ad_id);


--
-- Name: advertisers advertisers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisers
    ADD CONSTRAINT advertisers_email_key UNIQUE (email);


--
-- Name: advertisers advertisers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisers
    ADD CONSTRAINT advertisers_pkey PRIMARY KEY (advertiser_id);


--
-- Name: analytics_daily analytics_daily_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_daily
    ADD CONSTRAINT analytics_daily_date_key UNIQUE (date);


--
-- Name: analytics_daily analytics_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_daily
    ADD CONSTRAINT analytics_daily_pkey PRIMARY KEY (analytics_id);


--
-- Name: analytics_monthly analytics_monthly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_monthly
    ADD CONSTRAINT analytics_monthly_pkey PRIMARY KEY (analytics_id);


--
-- Name: analytics_monthly analytics_monthly_year_month_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.analytics_monthly
    ADD CONSTRAINT analytics_monthly_year_month_key UNIQUE (year, month);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (bookmark_id);


--
-- Name: bookmarks bookmarks_user_id_news_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_news_id_key UNIQUE (user_id, news_id);


--
-- Name: breaking_news breaking_news_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_pkey PRIMARY KEY (breaking_id);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (category_id);


--
-- Name: categories categories_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_slug_key UNIQUE (slug);


--
-- Name: cleanup_history cleanup_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cleanup_history
    ADD CONSTRAINT cleanup_history_pkey PRIMARY KEY (cleanup_id);


--
-- Name: cloudflare_images cloudflare_images_cloudflare_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cloudflare_images
    ADD CONSTRAINT cloudflare_images_cloudflare_id_key UNIQUE (cloudflare_id);


--
-- Name: cloudflare_images cloudflare_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cloudflare_images
    ADD CONSTRAINT cloudflare_images_pkey PRIMARY KEY (image_id);


--
-- Name: cookie_stats_daily cookie_stats_daily_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_daily
    ADD CONSTRAINT cookie_stats_daily_pkey PRIMARY KEY (stat_id);


--
-- Name: cookie_stats_monthly cookie_stats_monthly_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_monthly
    ADD CONSTRAINT cookie_stats_monthly_pkey PRIMARY KEY (stat_id);


--
-- Name: daily_location_stats daily_location_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_location_stats
    ADD CONSTRAINT daily_location_stats_pkey PRIMARY KEY (stat_id);


--
-- Name: daily_location_stats daily_location_stats_stat_date_county_town_category_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.daily_location_stats
    ADD CONSTRAINT daily_location_stats_stat_date_county_town_category_key UNIQUE (stat_date, county, town, category);


--
-- Name: device_registry device_registry_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.device_registry
    ADD CONSTRAINT device_registry_pkey PRIMARY KEY (device_id);


--
-- Name: donations donations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_pkey PRIMARY KEY (donation_id);


--
-- Name: email_queue email_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue
    ADD CONSTRAINT email_queue_pkey PRIMARY KEY (queue_id);


--
-- Name: event_registrations event_registrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_pkey PRIMARY KEY (registration_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: image_variants image_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_variants
    ADD CONSTRAINT image_variants_pkey PRIMARY KEY (variant_id);


--
-- Name: media_files media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_pkey PRIMARY KEY (file_id);


--
-- Name: monthly_location_summary monthly_location_summary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_location_summary
    ADD CONSTRAINT monthly_location_summary_pkey PRIMARY KEY (summary_id);


--
-- Name: monthly_location_summary monthly_location_summary_year_month_county_town_category_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_location_summary
    ADD CONSTRAINT monthly_location_summary_year_month_county_town_category_key UNIQUE (year, month, county, town, category);


--
-- Name: news_approval_history news_approval_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_pkey PRIMARY KEY (approval_id);


--
-- Name: news_categories news_categories_news_id_category_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_news_id_category_id_key UNIQUE (news_id, category_id);


--
-- Name: news_categories news_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_pkey PRIMARY KEY (news_category_id);


--
-- Name: news_comments news_comments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_pkey PRIMARY KEY (comment_id);


--
-- Name: news_images news_images_news_id_image_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_images
    ADD CONSTRAINT news_images_news_id_image_url_key UNIQUE (news_id, image_url);


--
-- Name: news_images news_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_images
    ADD CONSTRAINT news_images_pkey PRIMARY KEY (image_id);


--
-- Name: news news_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_pkey PRIMARY KEY (news_id);


--
-- Name: news_quotes news_quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes
    ADD CONSTRAINT news_quotes_pkey PRIMARY KEY (quote_id);


--
-- Name: news_reactions news_reactions_news_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_news_id_user_id_key UNIQUE (news_id, user_id);


--
-- Name: news_reactions news_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_pkey PRIMARY KEY (reaction_id);


--
-- Name: news_shares news_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_shares
    ADD CONSTRAINT news_shares_pkey PRIMARY KEY (share_id);


--
-- Name: news news_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_slug_key UNIQUE (slug);


--
-- Name: news_social_media news_social_media_news_id_platform_post_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_social_media
    ADD CONSTRAINT news_social_media_news_id_platform_post_id_key UNIQUE (news_id, platform, post_id);


--
-- Name: news_social_media news_social_media_news_id_post_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_social_media
    ADD CONSTRAINT news_social_media_news_id_post_url_key UNIQUE (news_id, post_url);


--
-- Name: news_social_media news_social_media_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_social_media
    ADD CONSTRAINT news_social_media_pkey PRIMARY KEY (social_media_id);


--
-- Name: news_videos news_videos_news_id_video_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_videos
    ADD CONSTRAINT news_videos_news_id_video_url_key UNIQUE (news_id, video_url);


--
-- Name: news_videos news_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_videos
    ADD CONSTRAINT news_videos_pkey PRIMARY KEY (video_id);


--
-- Name: newsletters newsletters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.newsletters
    ADD CONSTRAINT newsletters_pkey PRIMARY KEY (newsletter_id);


--
-- Name: page_views page_views_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_pkey PRIMARY KEY (view_id);


--
-- Name: public_session_store public_session_store_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.public_session_store
    ADD CONSTRAINT public_session_store_pkey PRIMARY KEY (sid);


--
-- Name: referrals referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_pkey PRIMARY KEY (referral_id);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (permission_id);


--
-- Name: role_permissions role_permissions_role_id_resource_type_resource_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_resource_type_resource_name_key UNIQUE (role_id, resource_type, resource_name);


--
-- Name: scheduler_logs scheduler_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scheduler_logs
    ADD CONSTRAINT scheduler_logs_pkey PRIMARY KEY (log_id);


--
-- Name: session_store session_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.session_store
    ADD CONSTRAINT session_pkey PRIMARY KEY (sid);


--
-- Name: social_embed_cache social_embed_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_embed_cache
    ADD CONSTRAINT social_embed_cache_pkey PRIMARY KEY (cache_id);


--
-- Name: social_embed_cache social_embed_cache_post_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_embed_cache
    ADD CONSTRAINT social_embed_cache_post_url_key UNIQUE (post_url);


--
-- Name: subscribers subscribers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT subscribers_email_key UNIQUE (email);


--
-- Name: subscribers subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscribers
    ADD CONSTRAINT subscribers_pkey PRIMARY KEY (subscriber_id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (log_id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (setting_id);


--
-- Name: system_settings system_settings_setting_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_setting_key_key UNIQUE (setting_key);


--
-- Name: cookie_stats_daily unique_daily_location; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_daily
    ADD CONSTRAINT unique_daily_location UNIQUE (stat_date, county, town, category);


--
-- Name: cookie_stats_monthly unique_monthly_location; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cookie_stats_monthly
    ADD CONSTRAINT unique_monthly_location UNIQUE (year, month, county, category);


--
-- Name: user_notifications user_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_pkey PRIMARY KEY (notification_id);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (preference_id);


--
-- Name: user_preferences user_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_key UNIQUE (user_id);


--
-- Name: user_reading_history user_reading_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_reading_history
    ADD CONSTRAINT user_reading_history_pkey PRIMARY KEY (history_id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (role_id);


--
-- Name: user_roles user_roles_role_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_name_key UNIQUE (role_name);


--
-- Name: user_roles user_roles_role_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_role_slug_key UNIQUE (role_slug);


--
-- Name: user_saved_articles user_saved_articles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_pkey PRIMARY KEY (saved_id);


--
-- Name: user_saved_articles user_saved_articles_user_id_news_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_user_id_news_id_key UNIQUE (user_id, news_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (session_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: users users_referral_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referral_code_key UNIQUE (referral_code);


--
-- Name: volunteers volunteers_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.volunteers
    ADD CONSTRAINT volunteers_email_key UNIQUE (email);


--
-- Name: volunteers volunteers_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.volunteers
    ADD CONSTRAINT volunteers_phone_key UNIQUE (phone);


--
-- Name: volunteers volunteers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.volunteers
    ADD CONSTRAINT volunteers_pkey PRIMARY KEY (volunteer_id);


--
-- Name: IDX_session_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "IDX_session_expire" ON public.session_store USING btree (expire);


--
-- Name: idx_active_counts_active_now; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_active_counts_active_now ON public.active_location_counts USING btree (active_now DESC);


--
-- Name: idx_active_counts_activity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_active_counts_activity ON public.active_location_counts USING btree (last_activity DESC);


--
-- Name: idx_active_counts_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_active_counts_category ON public.active_location_counts USING btree (category);


--
-- Name: idx_active_counts_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_active_counts_county ON public.active_location_counts USING btree (county);


--
-- Name: idx_ad_clicks_ad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ad_clicks_ad ON public.ad_clicks USING btree (ad_id);


--
-- Name: idx_ad_impressions_ad; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ad_impressions_ad ON public.ad_impressions USING btree (ad_id);


--
-- Name: idx_admin_notifications_admin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_notifications_admin ON public.admin_notifications USING btree (admin_id, is_read);


--
-- Name: idx_admin_session_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_session_expire ON public.admin_session_store USING btree (expire);


--
-- Name: idx_admin_sessions_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admin_sessions_expires ON public.admin_sessions USING btree (expires_at) WHERE (is_active = true);


--
-- Name: idx_admins_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_email ON public.admins USING btree (email);


--
-- Name: idx_admins_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_role_id ON public.admins USING btree (role_id);


--
-- Name: idx_admins_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_status ON public.admins USING btree (status);


--
-- Name: idx_admins_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_admins_username ON public.admins USING btree (username);


--
-- Name: idx_advertisements_advertiser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advertisements_advertiser ON public.advertisements USING btree (advertiser_id);


--
-- Name: idx_advertisements_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advertisements_dates ON public.advertisements USING btree (start_date, end_date);


--
-- Name: idx_advertisements_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_advertisements_status ON public.advertisements USING btree (status);


--
-- Name: idx_approval_history_news; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_approval_history_news ON public.news_approval_history USING btree (news_id, created_at DESC);


--
-- Name: idx_approval_history_reviewer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_approval_history_reviewer ON public.news_approval_history USING btree (reviewer_id);


--
-- Name: idx_bookmarks_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_news_id ON public.bookmarks USING btree (news_id);


--
-- Name: idx_bookmarks_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_bookmarks_user_id ON public.bookmarks USING btree (user_id);


--
-- Name: idx_categories_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_active ON public.categories USING btree (active) WHERE (active = true);


--
-- Name: idx_categories_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_order ON public.categories USING btree (order_index);


--
-- Name: idx_categories_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_parent_id ON public.categories USING btree (parent_id);


--
-- Name: idx_categories_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_slug ON public.categories USING btree (slug);


--
-- Name: idx_chat_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_created ON public.admin_chat_messages USING btree (created_at DESC);


--
-- Name: idx_chat_receiver; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_receiver ON public.admin_chat_messages USING btree (receiver_id, is_read);


--
-- Name: idx_chat_sender; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_chat_sender ON public.admin_chat_messages USING btree (sender_id);


--
-- Name: idx_cloudflare_images_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cloudflare_images_id ON public.cloudflare_images USING btree (cloudflare_id);


--
-- Name: idx_comments_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_news_id ON public.news_comments USING btree (news_id, status, created_at DESC);


--
-- Name: idx_comments_parent_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_parent_id ON public.news_comments USING btree (parent_id);


--
-- Name: idx_comments_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_status ON public.news_comments USING btree (status);


--
-- Name: idx_comments_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comments_user_id ON public.news_comments USING btree (user_id);


--
-- Name: idx_cookie_stats_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cookie_stats_category ON public.cookie_stats_daily USING btree (category);


--
-- Name: idx_cookie_stats_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cookie_stats_county ON public.cookie_stats_daily USING btree (county);


--
-- Name: idx_cookie_stats_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cookie_stats_date ON public.cookie_stats_daily USING btree (stat_date DESC);


--
-- Name: idx_cookie_stats_monthly_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cookie_stats_monthly_county ON public.cookie_stats_monthly USING btree (county);


--
-- Name: idx_cookie_stats_monthly_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_cookie_stats_monthly_date ON public.cookie_stats_monthly USING btree (year DESC, month DESC);


--
-- Name: idx_daily_stats_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_stats_category ON public.daily_location_stats USING btree (category);


--
-- Name: idx_daily_stats_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_stats_county ON public.daily_location_stats USING btree (county);


--
-- Name: idx_daily_stats_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_stats_date ON public.daily_location_stats USING btree (stat_date DESC);


--
-- Name: idx_daily_stats_date_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_daily_stats_date_county ON public.daily_location_stats USING btree (stat_date DESC, county);


--
-- Name: idx_device_registry_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_registry_category ON public.device_registry USING btree (category);


--
-- Name: idx_device_registry_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_registry_county ON public.device_registry USING btree (county);


--
-- Name: idx_device_registry_last_seen; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_registry_last_seen ON public.device_registry USING btree (last_seen DESC);


--
-- Name: idx_device_registry_registered; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_device_registry_registered ON public.device_registry USING btree (registered_at DESC);


--
-- Name: idx_media_files_cloudflare; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_media_files_cloudflare ON public.media_files USING btree (cloudflare_id);


--
-- Name: idx_media_files_storage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_media_files_storage ON public.media_files USING btree (storage_provider);


--
-- Name: idx_monthly_summary_county; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_monthly_summary_county ON public.monthly_location_summary USING btree (county);


--
-- Name: idx_monthly_summary_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_monthly_summary_date ON public.monthly_location_summary USING btree (year DESC, month DESC);


--
-- Name: idx_news_author; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_author ON public.news USING btree (author_id);


--
-- Name: idx_news_breaking; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_breaking ON public.news USING btree (breaking, breaking_until, published_at DESC) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_categories_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_categories_category ON public.news_categories USING btree (category_id);


--
-- Name: idx_news_categories_news; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_categories_news ON public.news_categories USING btree (news_id);


--
-- Name: idx_news_categories_primary; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_categories_primary ON public.news_categories USING btree (is_primary) WHERE (is_primary = true);


--
-- Name: idx_news_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_category ON public.news USING btree (category_id);


--
-- Name: idx_news_category_ids; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_category_ids ON public.news USING gin (category_ids);


--
-- Name: idx_news_combined_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_combined_search ON public.news USING gin (to_tsvector('english'::regconfig, (((title)::text || ' '::text) || content)));


--
-- Name: idx_news_content_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_content_search ON public.news USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_news_featured; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_featured ON public.news USING btree (featured) WHERE (featured = true);


--
-- Name: idx_news_images_cloudflare; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_cloudflare ON public.news_images USING btree (cloudflare_id);


--
-- Name: idx_news_images_display_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_display_order ON public.news_images USING btree (news_id, display_order);


--
-- Name: idx_news_images_featured; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_featured ON public.news_images USING btree (is_featured) WHERE (is_featured = true);


--
-- Name: idx_news_images_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_news_id ON public.news_images USING btree (news_id);


--
-- Name: idx_news_images_storage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_storage ON public.news_images USING btree (storage_provider);


--
-- Name: idx_news_performance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_performance ON public.news USING btree (views, likes_count, comments_count);


--
-- Name: idx_news_pin_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_pin_type ON public.news USING btree (pin_type) WHERE (pin_type IS NOT NULL);


--
-- Name: idx_news_pinned; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_pinned ON public.news USING btree (pinned, pin_until DESC) WHERE (pinned = true);


--
-- Name: idx_news_priority; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_priority ON public.news USING btree (priority, published_at DESC) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_published; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_published ON public.news USING btree (published_at DESC) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_quotes_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_quotes_active ON public.news_quotes USING btree (active);


--
-- Name: idx_news_quotes_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_quotes_data ON public.news USING gin (quotes_data);


--
-- Name: idx_news_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_slug ON public.news USING btree (slug);


--
-- Name: idx_news_social_auto_embed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_auto_embed ON public.news_social_media USING btree (auto_embed) WHERE (auto_embed = true);


--
-- Name: idx_news_social_display_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_display_order ON public.news_social_media USING btree (news_id, display_order);


--
-- Name: idx_news_social_featured; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_featured ON public.news_social_media USING btree (is_featured) WHERE (is_featured = true);


--
-- Name: idx_news_social_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_news_id ON public.news_social_media USING btree (news_id);


--
-- Name: idx_news_social_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_platform ON public.news_social_media USING btree (platform);


--
-- Name: idx_news_social_post_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_post_date ON public.news_social_media USING btree (post_date DESC);


--
-- Name: idx_news_social_post_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_post_type ON public.news_social_media USING btree (post_type);


--
-- Name: idx_news_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_status ON public.news USING btree (status);


--
-- Name: idx_news_title_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_title_search ON public.news USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: idx_news_trending; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_trending ON public.news USING btree (status, published_at DESC, views, likes_count, comments_count, share_count) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_videos_display_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_videos_display_order ON public.news_videos USING btree (news_id, display_order);


--
-- Name: idx_news_videos_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_videos_news_id ON public.news_videos USING btree (news_id);


--
-- Name: idx_news_videos_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_videos_platform ON public.news_videos USING btree (platform);


--
-- Name: idx_news_workflow; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_workflow ON public.news USING btree (workflow_status, submitted_at);


--
-- Name: idx_page_views_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_page_views_created ON public.page_views USING btree (created_at DESC);


--
-- Name: idx_page_views_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_page_views_news_id ON public.page_views USING btree (news_id);


--
-- Name: idx_public_session_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_public_session_expire ON public.public_session_store USING btree (expire);


--
-- Name: idx_reactions_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reactions_news_id ON public.news_reactions USING btree (news_id);


--
-- Name: idx_reactions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reactions_user_id ON public.news_reactions USING btree (user_id);


--
-- Name: idx_shares_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shares_news_id ON public.news_shares USING btree (news_id);


--
-- Name: idx_shares_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_shares_platform ON public.news_shares USING btree (platform);


--
-- Name: idx_user_notifications_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_notifications_user ON public.user_notifications USING btree (user_id, is_read);


--
-- Name: idx_user_sessions_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_sessions_expires ON public.user_sessions USING btree (expires_at) WHERE (is_active = true);


--
-- Name: idx_users_created_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_created_status ON public.users USING btree (created_at DESC, status);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_phone ON public.users USING btree (phone);


--
-- Name: idx_users_role_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role_id ON public.users USING btree (role_id);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: news_quotes_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_quotes_active_idx ON public.news_quotes USING btree (active);


--
-- Name: news_quotes_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_quotes_created_at_idx ON public.news_quotes USING btree (created_at DESC);


--
-- Name: news_quotes news_quotes_updated_at_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER news_quotes_updated_at_trigger BEFORE UPDATE ON public.news_quotes FOR EACH ROW EXECUTE FUNCTION public.update_news_quotes_updated_at_column();


--
-- Name: news set_breaking_until; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_breaking_until BEFORE INSERT OR UPDATE ON public.news FOR EACH ROW WHEN ((new.breaking = true)) EXECUTE FUNCTION public.update_breaking_until();


--
-- Name: news set_featured_until; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_featured_until BEFORE INSERT OR UPDATE ON public.news FOR EACH ROW WHEN ((new.featured = true)) EXECUTE FUNCTION public.update_featured_until();


--
-- Name: news_quotes set_news_quotes_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_news_quotes_updated_at BEFORE UPDATE ON public.news_quotes FOR EACH ROW EXECUTE FUNCTION public.update_news_quotes_updated_at_column();


--
-- Name: active_location_counts trigger_active_counts_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_active_counts_updated BEFORE UPDATE ON public.active_location_counts FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: cookie_stats_daily trigger_cookie_stats_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_cookie_stats_updated BEFORE UPDATE ON public.cookie_stats_daily FOR EACH ROW EXECUTE FUNCTION public.update_cookie_stats_timestamp();


--
-- Name: daily_location_stats trigger_daily_stats_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_daily_stats_updated BEFORE UPDATE ON public.daily_location_stats FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


--
-- Name: news_social_media trigger_generate_oembed_url; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_generate_oembed_url BEFORE INSERT OR UPDATE ON public.news_social_media FOR EACH ROW EXECUTE FUNCTION public.generate_oembed_url();


--
-- Name: news_social_media trigger_social_media_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_social_media_updated BEFORE UPDATE ON public.news_social_media FOR EACH ROW EXECUTE FUNCTION public.update_social_media_timestamp();


--
-- Name: activity_log activity_log_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_log
    ADD CONSTRAINT activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: activity_log activity_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_log
    ADD CONSTRAINT activity_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: ad_clicks ad_clicks_ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_clicks
    ADD CONSTRAINT ad_clicks_ad_id_fkey FOREIGN KEY (ad_id) REFERENCES public.advertisements(ad_id) ON DELETE CASCADE;


--
-- Name: ad_impressions ad_impressions_ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_impressions
    ADD CONSTRAINT ad_impressions_ad_id_fkey FOREIGN KEY (ad_id) REFERENCES public.advertisements(ad_id) ON DELETE CASCADE;


--
-- Name: admin_activity_log admin_activity_log_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_activity_log
    ADD CONSTRAINT admin_activity_log_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_chat_messages admin_chat_messages_receiver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_chat_messages admin_chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_chat_messages
    ADD CONSTRAINT admin_chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_notifications admin_notifications_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_notifications
    ADD CONSTRAINT admin_notifications_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_online_status admin_online_status_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_online_status
    ADD CONSTRAINT admin_online_status_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_permissions admin_permissions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_permissions
    ADD CONSTRAINT admin_permissions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admin_sessions admin_sessions_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: admins admins_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.user_roles(role_id);


--
-- Name: advertisements advertisements_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisements
    ADD CONSTRAINT advertisements_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES public.advertisers(advertiser_id) ON DELETE CASCADE;


--
-- Name: advertisers advertisers_tier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advertisers
    ADD CONSTRAINT advertisers_tier_id_fkey FOREIGN KEY (tier_id) REFERENCES public.ad_tiers(tier_id) ON DELETE SET NULL;


--
-- Name: bookmarks bookmarks_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: bookmarks bookmarks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: breaking_news breaking_news_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: breaking_news breaking_news_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: categories categories_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


--
-- Name: cloudflare_images cloudflare_images_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cloudflare_images
    ADD CONSTRAINT cloudflare_images_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.admins(admin_id);


--
-- Name: donations donations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: event_registrations event_registrations_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id) ON DELETE CASCADE;


--
-- Name: event_registrations event_registrations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.event_registrations
    ADD CONSTRAINT event_registrations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: events events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: image_variants image_variants_parent_image_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_variants
    ADD CONSTRAINT image_variants_parent_image_id_fkey FOREIGN KEY (parent_image_id) REFERENCES public.cloudflare_images(image_id) ON DELETE CASCADE;


--
-- Name: media_files media_files_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id);


--
-- Name: news_approval_history news_approval_history_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_approval_history news_approval_history_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.admins(admin_id);


--
-- Name: news news_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.admins(admin_id);


--
-- Name: news news_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: news_categories news_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE CASCADE;


--
-- Name: news_categories news_categories_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_categories
    ADD CONSTRAINT news_categories_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news news_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


--
-- Name: news_comments news_comments_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_comments news_comments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.news_comments(comment_id) ON DELETE CASCADE;


--
-- Name: news_comments news_comments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_comments
    ADD CONSTRAINT news_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: news_images news_images_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_images
    ADD CONSTRAINT news_images_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_reactions news_reactions_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_reactions news_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_reactions
    ADD CONSTRAINT news_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: news news_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.admins(admin_id);


--
-- Name: news_shares news_shares_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_shares
    ADD CONSTRAINT news_shares_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_shares news_shares_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_shares
    ADD CONSTRAINT news_shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: news_social_media news_social_media_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_social_media
    ADD CONSTRAINT news_social_media_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_videos news_videos_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_videos
    ADD CONSTRAINT news_videos_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: newsletters newsletters_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.newsletters
    ADD CONSTRAINT newsletters_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id);


--
-- Name: page_views page_views_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE SET NULL;


--
-- Name: page_views page_views_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.page_views
    ADD CONSTRAINT page_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: referrals referrals_referred_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referred_id_fkey FOREIGN KEY (referred_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: referrals referrals_referrer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.referrals
    ADD CONSTRAINT referrals_referrer_id_fkey FOREIGN KEY (referrer_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.user_roles(role_id) ON DELETE CASCADE;


--
-- Name: user_notifications user_notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_notifications
    ADD CONSTRAINT user_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_reading_history user_reading_history_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_reading_history
    ADD CONSTRAINT user_reading_history_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: user_reading_history user_reading_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_reading_history
    ADD CONSTRAINT user_reading_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_saved_articles user_saved_articles_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: user_saved_articles user_saved_articles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_saved_articles
    ADD CONSTRAINT user_saved_articles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users users_referred_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_referred_by_fkey FOREIGN KEY (referred_by) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.user_roles(role_id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

\unrestrict qUcv2lqXS2yXrPZEeXBqxRoaCFxoUlcqVwKekmfQktI37cN0EX7JzwsQO5Ybx9U

