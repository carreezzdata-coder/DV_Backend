--
-- PostgreSQL database dump
--

\restrict rfKhMDuTuveI3f8assXn4dejBIYoNR9hXeVNS0GAaqMzzpaceiC6cipPlHlaYi8

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
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
    'archived',
    'pending'
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
-- Name: video_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.video_status AS ENUM (
    'draft',
    'scheduled',
    'live',
    'ended',
    'published',
    'archived'
);


ALTER TYPE public.video_status OWNER TO postgres;

--
-- Name: video_visibility; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.video_visibility AS ENUM (
    'public',
    'unlisted',
    'private'
);


ALTER TYPE public.video_visibility OWNER TO postgres;

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
-- Name: auto_end_expired_live(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auto_end_expired_live() RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
      $$;


ALTER FUNCTION public.auto_end_expired_live() OWNER TO postgres;

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
-- Name: get_promotion_stats(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_promotion_stats() RETURNS TABLE(featured_count bigint, breaking_count bigint, pinned_count bigint)
    LANGUAGE plpgsql
    AS $$
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
      $$;


ALTER FUNCTION public.get_promotion_stats() OWNER TO postgres;

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
-- Name: update_mpesa_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_mpesa_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_mpesa_timestamp() OWNER TO postgres;

--
-- Name: update_news_quotes_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_news_quotes_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
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
-- Name: update_social_videos_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_social_videos_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$;


ALTER FUNCTION public.update_social_videos_timestamp() OWNER TO postgres;

--
-- Name: update_timestamp(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
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
    CONSTRAINT active_counts_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text])))
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
-- Name: ad_survey_questions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_survey_questions (
    question_id integer NOT NULL,
    survey_id integer NOT NULL,
    question text NOT NULL,
    question_type character varying(20),
    options jsonb DEFAULT '{}'::jsonb,
    required boolean DEFAULT false,
    order_index integer,
    CONSTRAINT ad_survey_questions_question_type_check CHECK (((question_type)::text = ANY (ARRAY[('text'::character varying)::text, ('radio'::character varying)::text, ('checkbox'::character varying)::text, ('rating'::character varying)::text])))
);


ALTER TABLE public.ad_survey_questions OWNER TO postgres;

--
-- Name: ad_survey_questions_question_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ad_survey_questions ALTER COLUMN question_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ad_survey_questions_question_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ad_survey_responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_survey_responses (
    response_id integer NOT NULL,
    survey_id integer NOT NULL,
    user_id integer,
    ip_address character varying(64),
    responses jsonb DEFAULT '{}'::jsonb,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ad_survey_responses OWNER TO postgres;

--
-- Name: TABLE ad_survey_responses; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ad_survey_responses IS 'User responses to advertising surveys';


--
-- Name: ad_survey_responses_response_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ad_survey_responses ALTER COLUMN response_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ad_survey_responses_response_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: ad_surveys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ad_surveys (
    survey_id integer NOT NULL,
    client_name character varying(255),
    campaign_name character varying(255),
    survey_title character varying(255),
    survey_description text,
    target_url character varying(512),
    status character varying(20) DEFAULT 'draft'::character varying,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    budget numeric(10,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ad_surveys_status_check CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('active'::character varying)::text, ('paused'::character varying)::text, ('completed'::character varying)::text])))
);


ALTER TABLE public.ad_surveys OWNER TO postgres;

--
-- Name: TABLE ad_surveys; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.ad_surveys IS 'Client survey campaigns for opinion polling and brand testing';


--
-- Name: ad_surveys_survey_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.ad_surveys ALTER COLUMN survey_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ad_surveys_survey_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


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
    data jsonb DEFAULT '{}'::jsonb,
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
    expire timestamp(6) without time zone NOT NULL,
    sess json DEFAULT '{}'::json NOT NULL
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
    permissions jsonb DEFAULT '{}'::jsonb,
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
    CONSTRAINT advertisements_placement_check CHECK (((placement)::text = ANY (ARRAY[('banner'::character varying)::text, ('sidebar'::character varying)::text, ('inline'::character varying)::text, ('popup'::character varying)::text, ('floating'::character varying)::text]))),
    CONSTRAINT advertisements_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('paused'::character varying)::text, ('expired'::character varying)::text, ('rejected'::character varying)::text])))
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
    CONSTRAINT advertisers_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('suspended'::character varying)::text, ('expired'::character varying)::text])))
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
    priority character varying(10) NOT NULL,
    starts_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ends_at timestamp without time zone,
    activated_by integer,
    manually_removed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT breaking_news_priority_check CHECK (((priority)::text = ANY ((ARRAY['high'::character varying, 'medium'::character varying, 'low'::character varying])::text[])))
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
    CONSTRAINT daily_stats_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text])))
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
    CONSTRAINT device_registry_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text])))
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
-- Name: editor_pick; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.editor_pick (
    pick_id integer NOT NULL,
    news_id integer NOT NULL,
    picked_by integer,
    picked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    manually_removed boolean DEFAULT false
);


ALTER TABLE public.editor_pick OWNER TO postgres;

--
-- Name: editor_pick_pick_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.editor_pick_pick_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.editor_pick_pick_id_seq OWNER TO postgres;

--
-- Name: editor_pick_pick_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.editor_pick_pick_id_seq OWNED BY public.editor_pick.pick_id;


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
    CONSTRAINT email_queue_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('sent'::character varying)::text, ('failed'::character varying)::text])))
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
    author_id integer,
    image_url character varying(500),
    processed_content text,
    quote_sayer text,
    quote_position integer DEFAULT 0,
    views integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    status public.news_status DEFAULT 'draft'::public.news_status,
    priority character varying(10) DEFAULT 'medium'::character varying,
    tags text,
    meta_description text,
    seo_keywords text,
    reading_time integer,
    published_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    uuid uuid DEFAULT gen_random_uuid(),
    fact_checked boolean DEFAULT false,
    fact_checked_by integer,
    content_warning text,
    sensitive boolean DEFAULT false,
    reading_level character varying(20),
    ai_summary text,
    last_edited_by integer,
    last_edited_at timestamp without time zone,
    revision integer DEFAULT 1,
    primary_category_id integer,
    quotes_data jsonb DEFAULT '[]'::jsonb NOT NULL,
    sources jsonb DEFAULT '[]'::jsonb NOT NULL,
    editor_pick boolean DEFAULT false,
    CONSTRAINT news_priority_check CHECK (((priority)::text = ANY (ARRAY[('high'::character varying)::text, ('medium'::character varying)::text, ('low'::character varying)::text])))
);


ALTER TABLE public.news OWNER TO postgres;

--
-- Name: COLUMN news.priority; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.priority IS 'Article priority: high, medium, or low';


--
-- Name: COLUMN news.uuid; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.uuid IS 'Universal unique identifier for external references';


--
-- Name: COLUMN news.fact_checked; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.fact_checked IS 'Whether article has been fact-checked';


--
-- Name: COLUMN news.content_warning; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.content_warning IS 'Warning text for sensitive content';


--
-- Name: COLUMN news.reading_level; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.reading_level IS 'Target reading level: general, expert, etc';


--
-- Name: COLUMN news.ai_summary; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.ai_summary IS 'AI-generated summary for quick overview';


--
-- Name: COLUMN news.last_edited_by; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.last_edited_by IS 'Most recent editor';


--
-- Name: COLUMN news.revision; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news.revision IS 'Version number for change tracking';


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
    dimensions jsonb DEFAULT '{}'::jsonb,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    shares_count integer DEFAULT 0,
    views_count integer DEFAULT 0,
    saves_count integer DEFAULT 0,
    display_order integer DEFAULT 2,
    is_featured boolean DEFAULT false,
    show_full_embed boolean DEFAULT true,
    auto_embed boolean DEFAULT true,
    caption text,
    hashtags text[] DEFAULT '{}'::text[],
    mentions text[] DEFAULT '{}'::text[],
    location character varying(255),
    oembed_data jsonb DEFAULT '{}'::jsonb,
    raw_api_response jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    last_fetched_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_social_media_platform_check CHECK (((platform)::text = ANY (ARRAY[('youtube_video'::character varying)::text, ('youtube_short'::character varying)::text, ('twitter_post'::character varying)::text, ('twitter_video'::character varying)::text, ('x_post'::character varying)::text, ('x_video'::character varying)::text, ('instagram_post'::character varying)::text, ('instagram_reel'::character varying)::text, ('instagram_video'::character varying)::text, ('facebook_post'::character varying)::text, ('facebook_video'::character varying)::text, ('facebook_reel'::character varying)::text, ('tiktok_video'::character varying)::text, ('tiktok_reel'::character varying)::text, ('linkedin_post'::character varying)::text, ('threads_post'::character varying)::text, ('whatsapp_status'::character varying)::text]))),
    CONSTRAINT news_social_media_post_type_check CHECK (((post_type)::text = ANY (ARRAY[('post'::character varying)::text, ('reel'::character varying)::text, ('video'::character varying)::text, ('short'::character varying)::text, ('story'::character varying)::text, ('status'::character varying)::text])))
);


ALTER TABLE public.news_social_media OWNER TO postgres;

--
-- Name: COLUMN news_social_media.display_order; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news_social_media.display_order IS 'Paragraph index (1-based) for inline embed placement. Social media embeds always appear at least at paragraph 2.';


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
            WHEN ((sm.platform)::text ~~* 'facebook%'::text) THEN (('<div class="fb-post" data-href="'::text || sm.post_url) || '"></div>'::text)
            WHEN (((sm.platform)::text ~~* 'twitter%'::text) OR ((sm.platform)::text ~~* 'x_%'::text)) THEN (('<blockquote class="twitter-tweet"><a href="'::text || sm.post_url) || '"></a></blockquote>'::text)
            WHEN ((sm.platform)::text ~~* 'instagram%'::text) THEN (('<blockquote class="instagram-media" data-instgrm-permalink="'::text || sm.post_url) || '"></blockquote>'::text)
            ELSE NULL::text
        END) AS generated_embed_html
   FROM (public.news_social_media sm
     JOIN public.news n ON ((sm.news_id = n.news_id)))
  WHERE (sm.show_full_embed = true);


ALTER VIEW public.embedded_social_posts OWNER TO postgres;

--
-- Name: featured_news; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.featured_news (
    featured_id integer NOT NULL,
    news_id integer NOT NULL,
    tier character varying(10) NOT NULL,
    starts_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ends_at timestamp without time zone,
    activated_by integer,
    manually_removed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT featured_news_tier_check CHECK (((tier)::text = ANY ((ARRAY['gold'::character varying, 'silver'::character varying, 'bronze'::character varying])::text[])))
);


ALTER TABLE public.featured_news OWNER TO postgres;

--
-- Name: featured_news_featured_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.featured_news_featured_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.featured_news_featured_id_seq OWNER TO postgres;

--
-- Name: featured_news_featured_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.featured_news_featured_id_seq OWNED BY public.featured_news.featured_id;


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
-- Name: live_broadcast_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.live_broadcast_sessions (
    session_id integer NOT NULL,
    video_id integer NOT NULL,
    session_started_at timestamp with time zone NOT NULL,
    session_ended_at timestamp with time zone,
    peak_viewers integer DEFAULT 0,
    total_messages integer DEFAULT 0,
    total_reactions integer DEFAULT 0,
    quality_settings jsonb DEFAULT '{}'::jsonb,
    broadcast_metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT session_dates_check CHECK (((session_ended_at IS NULL) OR (session_ended_at > session_started_at)))
);


ALTER TABLE public.live_broadcast_sessions OWNER TO postgres;

--
-- Name: TABLE live_broadcast_sessions; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.live_broadcast_sessions IS 'Live streaming sessions for social_videos ONLY. Foreign key to social_videos.video_id enforced.';


--
-- Name: COLUMN live_broadcast_sessions.video_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.live_broadcast_sessions.video_id IS 'Foreign key to social_videos.video_id. Never references news_videos.';


--
-- Name: live_broadcast_sessions_session_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.live_broadcast_sessions_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.live_broadcast_sessions_session_id_seq OWNER TO postgres;

--
-- Name: live_broadcast_sessions_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.live_broadcast_sessions_session_id_seq OWNED BY public.live_broadcast_sessions.session_id;


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
    CONSTRAINT monthly_summary_category_check CHECK (((category)::text = ANY (ARRAY[('KENYA'::character varying)::text, ('EAST_AFRICA'::character varying)::text, ('AFRICA'::character varying)::text, ('GLOBAL'::character varying)::text, ('UNKNOWN'::character varying)::text]))),
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
-- Name: mpesa_b2c_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mpesa_b2c_transactions (
    b2c_id integer NOT NULL,
    advertiser_id integer,
    conversation_id character varying(100),
    originator_conversation_id character varying(100),
    mpesa_receipt_number character varying(50),
    phone_number character varying(15) NOT NULL,
    amount numeric(12,2) NOT NULL,
    transaction_type character varying(50),
    result_code integer,
    result_desc text,
    status character varying(20) DEFAULT 'pending'::character varying,
    callback_received boolean DEFAULT false,
    callback_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_b2c_transactions_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('success'::character varying)::text, ('failed'::character varying)::text, ('queued'::character varying)::text])))
);


ALTER TABLE public.mpesa_b2c_transactions OWNER TO postgres;

--
-- Name: mpesa_b2c_transactions_b2c_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mpesa_b2c_transactions_b2c_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mpesa_b2c_transactions_b2c_id_seq OWNER TO postgres;

--
-- Name: mpesa_b2c_transactions_b2c_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mpesa_b2c_transactions_b2c_id_seq OWNED BY public.mpesa_b2c_transactions.b2c_id;


--
-- Name: mpesa_callback_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mpesa_callback_log (
    callback_id integer NOT NULL,
    callback_type character varying(50) NOT NULL,
    reference_id character varying(100),
    raw_payload jsonb NOT NULL,
    processed boolean DEFAULT false,
    processing_error text,
    ip_address inet,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_callback_log_callback_type_check CHECK (((callback_type)::text = ANY (ARRAY[('stk_push'::character varying)::text, ('b2c'::character varying)::text, ('c2b'::character varying)::text, ('validation'::character varying)::text, ('confirmation'::character varying)::text])))
);


ALTER TABLE public.mpesa_callback_log OWNER TO postgres;

--
-- Name: mpesa_callback_log_callback_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mpesa_callback_log_callback_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mpesa_callback_log_callback_id_seq OWNER TO postgres;

--
-- Name: mpesa_callback_log_callback_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mpesa_callback_log_callback_id_seq OWNED BY public.mpesa_callback_log.callback_id;


--
-- Name: mpesa_stk_push_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mpesa_stk_push_log (
    log_id integer NOT NULL,
    transaction_id integer,
    merchant_request_id character varying(100),
    checkout_request_id character varying(100),
    response_code character varying(10),
    response_description text,
    customer_message text,
    request_payload jsonb DEFAULT '{}'::jsonb,
    response_payload jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.mpesa_stk_push_log OWNER TO postgres;

--
-- Name: mpesa_stk_push_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mpesa_stk_push_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mpesa_stk_push_log_log_id_seq OWNER TO postgres;

--
-- Name: mpesa_stk_push_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mpesa_stk_push_log_log_id_seq OWNED BY public.mpesa_stk_push_log.log_id;


--
-- Name: mpesa_transactions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mpesa_transactions (
    transaction_id integer NOT NULL,
    advertiser_id integer,
    merchant_request_id character varying(100),
    checkout_request_id character varying(100),
    mpesa_receipt_number character varying(50),
    phone_number character varying(15) NOT NULL,
    amount numeric(12,2) NOT NULL,
    transaction_date timestamp with time zone,
    result_code integer,
    result_desc text,
    status character varying(20) DEFAULT 'pending'::character varying,
    callback_received boolean DEFAULT false,
    callback_data jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT mpesa_transactions_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('success'::character varying)::text, ('failed'::character varying)::text, ('cancelled'::character varying)::text])))
);


ALTER TABLE public.mpesa_transactions OWNER TO postgres;

--
-- Name: mpesa_transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mpesa_transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mpesa_transactions_transaction_id_seq OWNER TO postgres;

--
-- Name: mpesa_transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mpesa_transactions_transaction_id_seq OWNED BY public.mpesa_transactions.transaction_id;


--
-- Name: news_approval; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_approval (
    approval_record_id integer NOT NULL,
    news_id integer NOT NULL,
    workflow_status character varying(20) DEFAULT 'draft'::character varying,
    requires_approval boolean DEFAULT false,
    submitted_at timestamp without time zone,
    submitted_by integer NOT NULL,
    approved_by integer,
    approved_at timestamp without time zone,
    rejected_by integer,
    rejected_at timestamp without time zone,
    rejection_reason text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_approval_workflow_status_check CHECK (((workflow_status)::text = ANY ((ARRAY['draft'::character varying, 'pending_review'::character varying, 'pending_approval'::character varying, 'approved'::character varying, 'rejected'::character varying, 'published'::character varying])::text[])))
);


ALTER TABLE public.news_approval OWNER TO postgres;

--
-- Name: news_approval_approval_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_approval_approval_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_approval_approval_record_id_seq OWNER TO postgres;

--
-- Name: news_approval_approval_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_approval_approval_record_id_seq OWNED BY public.news_approval.approval_record_id;


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
    CONSTRAINT news_approval_history_action_check CHECK (((action)::text = ANY (ARRAY[('submit'::character varying)::text, ('approve'::character varying)::text, ('reject'::character varying)::text, ('request_changes'::character varying)::text])))
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
-- Name: news_content_blocks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_content_blocks (
    block_id integer NOT NULL,
    news_id integer NOT NULL,
    block_type character varying(20) NOT NULL,
    block_data jsonb NOT NULL,
    order_index integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT news_content_blocks_block_type_check CHECK (((block_type)::text = ANY (ARRAY[('paragraph'::character varying)::text, ('heading'::character varying)::text, ('quote'::character varying)::text, ('highlight'::character varying)::text, ('timeline'::character varying)::text, ('interview'::character varying)::text, ('image'::character varying)::text, ('video'::character varying)::text, ('embed'::character varying)::text])))
);


ALTER TABLE public.news_content_blocks OWNER TO postgres;

--
-- Name: TABLE news_content_blocks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.news_content_blocks IS 'Structured content blocks for advanced rendering';


--
-- Name: news_content_blocks_block_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.news_content_blocks ALTER COLUMN block_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.news_content_blocks_block_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: news_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_images (
    image_id integer NOT NULL,
    news_id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    image_caption text,
    alt_text text,
    display_order integer DEFAULT 5,
    is_featured boolean DEFAULT false,
    width integer,
    height integer,
    file_size bigint,
    mime_type character varying(100),
    storage_provider character varying(20) DEFAULT 'local'::character varying,
    cloudflare_id character varying(255),
    cloudflare_variant character varying(50),
    uploaded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_images_storage_provider_check CHECK (((storage_provider)::text = ANY (ARRAY[('local'::character varying)::text, ('cloudflare'::character varying)::text, ('s3'::character varying)::text])))
);


ALTER TABLE public.news_images OWNER TO postgres;

--
-- Name: COLUMN news_images.display_order; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news_images.display_order IS 'Paragraph index (1-based) where image appears. Featured images: paragraph 1, Regular images: paragraph 5+';


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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    editor_pick boolean DEFAULT false
);


ALTER TABLE public.news_quotes OWNER TO postgres;

--
-- Name: COLUMN news_quotes.editor_pick; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news_quotes.editor_pick IS 'Selected by editors as exceptional content';


--
-- Name: news_quotes_images; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.news_quotes_images (
    image_id integer NOT NULL,
    quote_id integer NOT NULL,
    image_url character varying(500) NOT NULL,
    cloudflare_id character varying(255),
    storage_provider character varying(20) DEFAULT 'cloudflare'::character varying,
    width integer,
    height integer,
    file_size bigint,
    mime_type character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    storage_mode character varying(20) DEFAULT 'production'::character varying,
    local_path character varying(500),
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT news_quotes_images_storage_mode_check CHECK (((storage_mode)::text = ANY (ARRAY[('development'::character varying)::text, ('production'::character varying)::text])))
);


ALTER TABLE public.news_quotes_images OWNER TO postgres;

--
-- Name: TABLE news_quotes_images; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.news_quotes_images IS 'Cloudflare-stored images for news quotes - separate from news article images';


--
-- Name: news_quotes_images_image_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.news_quotes_images_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.news_quotes_images_image_id_seq OWNER TO postgres;

--
-- Name: news_quotes_images_image_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.news_quotes_images_image_id_seq OWNED BY public.news_quotes_images.image_id;


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
    CONSTRAINT news_videos_platform_check CHECK (((platform)::text = ANY (ARRAY[('facebook'::character varying)::text, ('twitter'::character varying)::text, ('youtube'::character varying)::text, ('instagram'::character varying)::text, ('tiktok'::character varying)::text])))
);


ALTER TABLE public.news_videos OWNER TO postgres;

--
-- Name: TABLE news_videos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.news_videos IS 'Videos embedded INSIDE news articles ONLY. Foreign key to news table enforced. Never used by standalone video system.';


--
-- Name: COLUMN news_videos.news_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.news_videos.news_id IS 'REQUIRED foreign key to news table. This table is ONLY for videos that belong to a news article.';


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
    CONSTRAINT newsletters_status_check CHECK (((status)::text = ANY (ARRAY[('draft'::character varying)::text, ('scheduled'::character varying)::text, ('sent'::character varying)::text, ('failed'::character varying)::text])))
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
-- Name: pinned_news; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pinned_news (
    pinned_id integer NOT NULL,
    news_id integer NOT NULL,
    tier character varying(10) NOT NULL,
    "position" integer,
    starts_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ends_at timestamp without time zone,
    activated_by integer,
    manually_removed boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pinned_news_position_check CHECK (("position" > 0)),
    CONSTRAINT pinned_news_tier_check CHECK (((tier)::text = ANY ((ARRAY['gold'::character varying, 'silver'::character varying, 'bronze'::character varying])::text[])))
);


ALTER TABLE public.pinned_news OWNER TO postgres;

--
-- Name: pinned_news_pinned_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pinned_news_pinned_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pinned_news_pinned_id_seq OWNER TO postgres;

--
-- Name: pinned_news_pinned_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pinned_news_pinned_id_seq OWNED BY public.pinned_news.pinned_id;


--
-- Name: public_session_store; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.public_session_store (
    sid character varying NOT NULL,
    expire timestamp(6) without time zone NOT NULL,
    sess json DEFAULT '{}'::json NOT NULL
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
    event_data jsonb DEFAULT '{}'::jsonb,
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
    expire timestamp(6) without time zone NOT NULL,
    sess json DEFAULT '{}'::json NOT NULL
);


ALTER TABLE public.session_store OWNER TO postgres;

--
-- Name: social_embed_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.social_embed_cache (
    cache_id integer NOT NULL,
    post_url text NOT NULL,
    embed_html text,
    oembed_data jsonb DEFAULT '{}'::jsonb,
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
-- Name: social_videos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.social_videos (
    video_id integer NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    platform character varying(50) NOT NULL,
    video_type character varying(50) NOT NULL,
    video_url text NOT NULL,
    video_id_external character varying(255),
    embed_code text,
    embed_html text,
    oembed_url text,
    thumbnail_url text,
    duration integer,
    channel_name character varying(255),
    channel_id character varying(255),
    channel_url text,
    channel_avatar_url text,
    is_live boolean DEFAULT false,
    live_started_at timestamp with time zone,
    live_ended_at timestamp with time zone,
    scheduled_start_time timestamp with time zone,
    concurrent_viewers integer DEFAULT 0,
    peak_viewers integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    dislikes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    views_count integer DEFAULT 0,
    shares_count integer DEFAULT 0,
    status public.video_status DEFAULT 'draft'::public.video_status,
    visibility public.video_visibility DEFAULT 'public'::public.video_visibility,
    featured boolean DEFAULT false,
    featured_until timestamp with time zone,
    display_order integer DEFAULT 0,
    tags text[] DEFAULT ARRAY[]::text[],
    categories integer[] DEFAULT ARRAY[]::integer[],
    auto_refresh boolean DEFAULT true,
    refresh_interval integer DEFAULT 300,
    last_refreshed_at timestamp with time zone,
    created_by integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    editor_pick boolean DEFAULT false,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    oembed_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT video_platform_check CHECK (((platform)::text = ANY (ARRAY[('youtube'::character varying)::text, ('youtube_live'::character varying)::text, ('facebook'::character varying)::text, ('facebook_live'::character varying)::text, ('instagram'::character varying)::text, ('instagram_live'::character varying)::text, ('twitter'::character varying)::text, ('twitter_live'::character varying)::text, ('tiktok'::character varying)::text, ('tiktok_live'::character varying)::text, ('twitch'::character varying)::text, ('vimeo'::character varying)::text, ('dailymotion'::character varying)::text]))),
    CONSTRAINT video_type_check CHECK (((video_type)::text = ANY (ARRAY[('live'::character varying)::text, ('recorded'::character varying)::text, ('premiere'::character varying)::text, ('short'::character varying)::text, ('reel'::character varying)::text, ('story'::character varying)::text])))
);


ALTER TABLE public.social_videos OWNER TO postgres;

--
-- Name: TABLE social_videos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.social_videos IS 'Standalone social videos system. Completely independent from news_videos. No foreign key to news table.';


--
-- Name: COLUMN social_videos.video_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.social_videos.video_id IS 'Primary key for standalone social videos. Never references news_videos table.';


--
-- Name: COLUMN social_videos.is_live; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.social_videos.is_live IS 'Whether video is currently streaming live';


--
-- Name: COLUMN social_videos.auto_refresh; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.social_videos.auto_refresh IS 'Automatically refresh video stats';


--
-- Name: COLUMN social_videos.refresh_interval; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.social_videos.refresh_interval IS 'Seconds between stat refreshes';


--
-- Name: COLUMN social_videos.editor_pick; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.social_videos.editor_pick IS 'Selected by editors as exceptional content';


--
-- Name: social_videos_analytics; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.social_videos_analytics (
    analytics_id integer NOT NULL,
    video_id integer NOT NULL,
    stat_date date NOT NULL,
    views_count integer DEFAULT 0,
    unique_viewers integer DEFAULT 0,
    likes_count integer DEFAULT 0,
    comments_count integer DEFAULT 0,
    shares_count integer DEFAULT 0,
    watch_time_minutes integer DEFAULT 0,
    avg_watch_duration integer DEFAULT 0,
    peak_concurrent_viewers integer DEFAULT 0,
    total_concurrent_viewers integer DEFAULT 0,
    engagement_rate numeric(5,2) DEFAULT 0,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.social_videos_analytics OWNER TO postgres;

--
-- Name: social_videos_analytics_analytics_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.social_videos_analytics_analytics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.social_videos_analytics_analytics_id_seq OWNER TO postgres;

--
-- Name: social_videos_analytics_analytics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.social_videos_analytics_analytics_id_seq OWNED BY public.social_videos_analytics.analytics_id;


--
-- Name: social_videos_video_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.social_videos_video_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.social_videos_video_id_seq OWNER TO postgres;

--
-- Name: social_videos_video_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.social_videos_video_id_seq OWNED BY public.social_videos.video_id;


--
-- Name: subscribers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscribers (
    subscriber_id integer NOT NULL,
    email character varying(150) NOT NULL,
    name character varying(200),
    status public.subscriber_status DEFAULT 'pending'::public.subscriber_status,
    preferences jsonb DEFAULT '{}'::jsonb,
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
    log_data jsonb DEFAULT '{}'::jsonb,
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
-- Name: editor_pick pick_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.editor_pick ALTER COLUMN pick_id SET DEFAULT nextval('public.editor_pick_pick_id_seq'::regclass);


--
-- Name: email_queue queue_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue ALTER COLUMN queue_id SET DEFAULT nextval('public.email_queue_queue_id_seq'::regclass);


--
-- Name: featured_news featured_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_news ALTER COLUMN featured_id SET DEFAULT nextval('public.featured_news_featured_id_seq'::regclass);


--
-- Name: image_variants variant_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_variants ALTER COLUMN variant_id SET DEFAULT nextval('public.image_variants_variant_id_seq'::regclass);


--
-- Name: live_broadcast_sessions session_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_broadcast_sessions ALTER COLUMN session_id SET DEFAULT nextval('public.live_broadcast_sessions_session_id_seq'::regclass);


--
-- Name: media_files file_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_files ALTER COLUMN file_id SET DEFAULT nextval('public.media_files_file_id_seq'::regclass);


--
-- Name: monthly_location_summary summary_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.monthly_location_summary ALTER COLUMN summary_id SET DEFAULT nextval('public.monthly_location_summary_summary_id_seq'::regclass);


--
-- Name: mpesa_b2c_transactions b2c_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions ALTER COLUMN b2c_id SET DEFAULT nextval('public.mpesa_b2c_transactions_b2c_id_seq'::regclass);


--
-- Name: mpesa_callback_log callback_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_callback_log ALTER COLUMN callback_id SET DEFAULT nextval('public.mpesa_callback_log_callback_id_seq'::regclass);


--
-- Name: mpesa_stk_push_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_stk_push_log ALTER COLUMN log_id SET DEFAULT nextval('public.mpesa_stk_push_log_log_id_seq'::regclass);


--
-- Name: mpesa_transactions transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.mpesa_transactions_transaction_id_seq'::regclass);


--
-- Name: news news_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news ALTER COLUMN news_id SET DEFAULT nextval('public.news_news_id_seq'::regclass);


--
-- Name: news_approval approval_record_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval ALTER COLUMN approval_record_id SET DEFAULT nextval('public.news_approval_approval_record_id_seq'::regclass);


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
-- Name: news_quotes_images image_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes_images ALTER COLUMN image_id SET DEFAULT nextval('public.news_quotes_images_image_id_seq'::regclass);


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
-- Name: pinned_news pinned_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pinned_news ALTER COLUMN pinned_id SET DEFAULT nextval('public.pinned_news_pinned_id_seq'::regclass);


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
-- Name: social_videos video_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos ALTER COLUMN video_id SET DEFAULT nextval('public.social_videos_video_id_seq'::regclass);


--
-- Name: social_videos_analytics analytics_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos_analytics ALTER COLUMN analytics_id SET DEFAULT nextval('public.social_videos_analytics_analytics_id_seq'::regclass);


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

COPY public.active_location_counts (location_id, county, town, category, active_now, active_today, total_registered, last_activity, last_updated) FROM stdin;
\.


--
-- Data for Name: activity_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_log (activity_id, user_id, admin_id, action, details, ip_address, user_agent, created_at) FROM stdin;
\.


--
-- Data for Name: ad_clicks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_clicks (click_id, ad_id, session_id, county, town, created_at) FROM stdin;
\.


--
-- Data for Name: ad_impressions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_impressions (impression_id, ad_id, session_id, county, town, created_at) FROM stdin;
\.


--
-- Data for Name: ad_survey_questions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_survey_questions (question_id, survey_id, question, question_type, options, required, order_index) FROM stdin;
\.


--
-- Data for Name: ad_survey_responses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_survey_responses (response_id, survey_id, user_id, ip_address, responses, submitted_at) FROM stdin;
\.


--
-- Data for Name: ad_surveys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_surveys (survey_id, client_name, campaign_name, survey_title, survey_description, target_url, status, starts_at, ends_at, budget, created_at) FROM stdin;
\.


--
-- Data for Name: ad_tiers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ad_tiers (tier_id, tier_name, price_per_month, price_per_year, max_ads, priority_level, features, active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: admin_activity_log; Type: TABLE DATA; Schema: public; Owner: postgres
--


--
-- Data for Name: news_quotes_images; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_quotes_images (image_id, quote_id, image_url, cloudflare_id, storage_provider, width, height, file_size, mime_type, created_at, updated_at, storage_mode, local_path, metadata) FROM stdin;
10	12	/uploads/image-1769187763432-qqddiddlp.png	\N	local	\N	\N	1240133	image/png	2026-01-23 09:02:43.548603	2026-01-23 09:02:43.548603	development	C:\\Projects\\DAILY VAIBE\\backend\\uploads\\image-1769187763432-qqddiddlp.png	{"uploadedAt": "2026-01-23T17:02:43.548Z", "originalName": "image.png"}
11	13	/uploads/image-1769188074205-8gcd5vut1ls.png	\N	local	\N	\N	1956603	image/png	2026-01-23 09:07:54.255212	2026-01-23 09:07:54.255212	development	C:\\Projects\\DAILY VAIBE\\backend\\uploads\\image-1769188074205-8gcd5vut1ls.png	{"uploadedAt": "2026-01-23T17:07:54.254Z", "originalName": "image.png"}
12	14	/uploads/image-1769188170869-7aww1pailw9.png	\N	local	\N	\N	1632308	image/png	2026-01-23 09:09:30.892759	2026-01-23 09:09:30.892759	development	C:\\Projects\\DAILY VAIBE\\backend\\uploads\\image-1769188170869-7aww1pailw9.png	{"uploadedAt": "2026-01-23T17:09:30.892Z", "originalName": "image.png"}
13	15	/uploads/image-1769188289980-8jcgp2zevkf.png	\N	local	\N	\N	609959	image/png	2026-01-23 09:11:30.024584	2026-01-23 09:11:30.024584	development	C:\\Projects\\DAILY VAIBE\\backend\\uploads\\image-1769188289980-8jcgp2zevkf.png	{"uploadedAt": "2026-01-23T17:11:30.023Z", "originalName": "image.png"}
14	16	/uploads/image-1769188074205-8gcd5vut1l-1769278736410-e8ksv0vzyrb.png	\N	local	\N	\N	1956603	image/png	2026-01-24 10:18:56.600147	2026-01-24 10:18:56.600147	development	C:\\Projects\\DAILY VAIBE\\backend\\uploads\\image-1769188074205-8gcd5vut1l-1769278736410-e8ksv0vzyrb.png	{"uploadedAt": "2026-01-24T18:18:56.599Z", "originalName": "image-1769188074205-8gcd5vut1ls.png"}
\.


--
-- Data for Name: news_reactions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_reactions (reaction_id, news_id, user_id, reaction_type, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: news_shares; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_shares (share_id, news_id, platform, user_id, ip_address, shared_at) FROM stdin;
\.


--
-- Data for Name: news_social_media; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_social_media (social_media_id, news_id, platform, post_type, post_url, post_id, embed_code, embed_html, oembed_url, author_name, author_handle, author_avatar_url, post_text, post_date, thumbnail_url, media_url, media_urls, duration, dimensions, likes_count, comments_count, shares_count, views_count, saves_count, display_order, is_featured, show_full_embed, auto_embed, caption, hashtags, mentions, location, oembed_data, raw_api_response, created_at, updated_at, last_fetched_at, metadata) FROM stdin;
5	10	youtube_video	video	https://www.youtube.com/watch?v=_GDxrfP0_40	\N	\N	\N	https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=_GDxrfP0_40&format=json	\N	\N	\N	\N	\N	\N	\N	[]	\N	{}	0	0	0	0	0	2	t	t	t		{}	{}	\N	{}	{}	2026-01-21 23:50:52.578755-08	2026-01-21 23:50:52.578755-08	\N	{}
6	10	twitter_post	post	https://x.com/ManCityWomen/status/2014037779051847993?s=20	\N	\N	\N	https://publish.twitter.com/oembed?url=https://x.com/ManCityWomen/status/2014037779051847993?s=20	\N	\N	\N	\N	\N	\N	\N	[]	\N	{}	0	0	0	0	0	3	f	t	t		{}	{}	\N	{}	{}	2026-01-21 23:50:52.578755-08	2026-01-21 23:50:52.578755-08	\N	{}
7	11	facebook_video	video	https://web.facebook.com/reel/1226330619451673	\N	\N	\N	https://www.facebook.com/plugins/post/oembed.json/?url=https://web.facebook.com/reel/1226330619451673	\N	\N	\N	\N	\N	\N	\N	[]	\N	{}	0	0	0	0	0	2	t	t	t		{}	{}	\N	{}	{}	2026-01-22 04:36:09.090878-08	2026-01-22 04:36:09.090878-08	\N	{}
\.


--
-- Data for Name: news_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.news_videos (video_id, news_id, platform, video_url, embed_code, caption, thumbnail_url, duration, display_order, metadata, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: newsletters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.newsletters (newsletter_id, title, content, sent_to, status, scheduled_at, sent_at, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: page_views; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.page_views (view_id, page_url, news_id, user_id, ip_address, user_agent, referer, created_at) FROM stdin;
\.


--
-- Data for Name: pinned_news; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pinned_news (pinned_id, news_id, tier, "position", starts_at, ends_at, activated_by, manually_removed, created_at) FROM stdin;
1	11	gold	1	2026-01-22 12:46:53.616909	2026-01-25 12:46:53.616909	5	f	2026-01-22 12:46:53.616909
4	10	gold	1	2026-01-26 09:28:27.671956	2026-01-29 09:28:27.671956	5	f	2026-01-26 09:28:27.671956
6	9	gold	1	2026-01-26 09:28:44.756943	2026-01-29 09:28:44.756943	5	f	2026-01-26 09:28:44.756943
7	7	gold	1	2026-01-26 09:28:55.952824	2026-01-29 09:28:55.952824	5	f	2026-01-26 09:28:55.952824
8	5	gold	1	2026-01-26 09:29:08.462596	2026-01-29 09:29:08.462596	5	f	2026-01-26 09:29:08.462596
\.


--
-- Data for Name: public_session_store; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.public_session_store (sid, expire, sess) FROM stdin;
\.


--
-- Data for Name: referrals; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.referrals (referral_id, referrer_id, referred_id, status, reward_given, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role_permissions (permission_id, role_id, resource_type, resource_name, can_create, can_read, can_update, can_delete, can_publish, can_approve, additional_permissions, created_at) FROM stdin;
\.


--
-- Data for Name: scheduler_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scheduler_logs (log_id, event_type, event_data, created_at) FROM stdin;
\.


--
-- Data for Name: session_store; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.session_store (sid, expire, sess) FROM stdin;
AJQ03Jdiz7x2di2ftllXYmxpZUTK-62r	2026-02-02 11:30:00	{"cookie":{"originalMaxAge":604800000,"expires":"2026-01-29T21:04:55.783Z","secure":false,"httpOnly":true,"path":"/","sameSite":"lax"},"adminId":5,"loginTime":"2026-01-22T21:04:55.702Z","csrfToken":"5b316d57cd99ae403e8fb5dca9b32758abdab93ef3dbe506d9d56d042813d03c"}
mX6q8nPbltwJdlojn-c13myBMzCLqEId	2026-02-02 19:52:23	{"cookie":{"originalMaxAge":604800000,"expires":"2026-01-30T08:03:53.747Z","secure":false,"httpOnly":true,"path":"/","sameSite":"lax"},"adminId":5,"loginTime":"2026-01-23T08:03:53.698Z","csrfToken":"2a431da06a2d9ab8b9aee494a855653f0c98dfe1ecef3f66c1c3d37576d257d7"}
\.


--
-- Data for Name: social_embed_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.social_embed_cache (cache_id, post_url, embed_html, oembed_data, fetched_at, expires_at) FROM stdin;
\.


--
-- Data for Name: social_videos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.social_videos (video_id, title, description, platform, video_type, video_url, video_id_external, embed_code, embed_html, oembed_url, thumbnail_url, duration, channel_name, channel_id, channel_url, channel_avatar_url, is_live, live_started_at, live_ended_at, scheduled_start_time, concurrent_viewers, peak_viewers, likes_count, dislikes_count, comments_count, views_count, shares_count, status, visibility, featured, featured_until, display_order, tags, categories, auto_refresh, refresh_interval, last_refreshed_at, created_by, created_at, updated_at, editor_pick, metadata, oembed_data) FROM stdin;
\.


--
-- Data for Name: social_videos_analytics; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.social_videos_analytics (analytics_id, video_id, stat_date, views_count, unique_viewers, likes_count, comments_count, shares_count, watch_time_minutes, avg_watch_duration, peak_concurrent_viewers, total_concurrent_viewers, engagement_rate, created_at) FROM stdin;
\.


--
-- Data for Name: subscribers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscribers (subscriber_id, email, name, status, preferences, subscribed_at, confirmed_at, unsubscribed_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_logs (log_id, log_level, log_message, log_source, log_data, created_at) FROM stdin;
1	INFO	Critical constraint fix migration completed	migration_script	{"timestamp": "2026-01-17T16:51:58.051Z", "orphaned_editor": 0, "orphaned_pinned": 0, "duplicate_editor": 0, "duplicate_pinned": 0, "invalid_approved": 0, "invalid_rejected": 0, "invalid_submitted": 0, "orphaned_approval": 0, "orphaned_breaking": 0, "orphaned_featured": 0, "duplicate_approval": 0, "duplicate_breaking": 0, "duplicate_featured": 0}	2026-01-17 08:51:57.936634
2	INFO	Foreign key constraint fix completed	migration_script	{"timestamp": "2026-01-17T18:03:14.844Z"}	2026-01-17 10:03:13.932032
3	INFO	Workflow-aligned foreign key fix completed	migration_script	{"timestamp": "2026-01-17T18:21:40.626Z", "total_admins": 2, "fixed_approved": 0, "fixed_rejected": 0, "fixed_submitted": 0, "system_admin_id": 5}	2026-01-17 10:21:40.513025
4	INFO	Workflow-aligned foreign key fix completed	migration_script	{"timestamp": "2026-01-18T10:03:45.297Z", "total_admins": 2, "fixed_approved": 0, "fixed_rejected": 0, "fixed_submitted": 0, "system_admin_id": 5}	2026-01-18 02:03:44.169797
5	INFO	Radical simplification - all FK constraints removed	radical_simplification.js	{"action": "removed_all_fk_constraints", "timestamp": "2026-01-18T16:14:27.534Z", "tables_affected": ["news_approval", "breaking_news", "featured_news", "pinned_news", "editor_pick"]}	2026-01-18 08:14:27.538
6	INFO	Foreign key constraints restored	rollback_restore_fks.js	{"action": "restored_all_fk_constraints", "timestamp": "2026-01-18T17:09:26.603Z"}	2026-01-18 09:09:26.610592
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_settings (setting_id, setting_key, setting_value, setting_type, description, is_public, created_at, updated_at) FROM stdin;
1	social_embed_enabled	true	boolean	Enable social media embedding	f	2025-12-19 09:10:35.793779	2025-12-19 09:10:35.793779
2	social_embed_cache_duration	3600	number	Embed cache duration in seconds	f	2025-12-19 09:10:35.793779	2025-12-19 09:10:35.793779
3	live_video_auto_end_hours	24	integer	Hours before auto-ending stuck live streams	f	2025-12-31 04:49:39.383986	2025-12-31 04:49:39.383986
4	live_video_refresh_interval	300	integer	Default refresh interval for live videos (seconds)	f	2025-12-31 04:49:39.383986	2025-12-31 04:49:39.383986
5	max_featured_videos	3	integer	Maximum number of featured videos	f	2025-12-31 04:49:39.383986	2025-12-31 04:49:39.383986
\.


--
-- Data for Name: user_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_notifications (notification_id, user_id, title, message, type, link, is_read, created_at) FROM stdin;
\.


--
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_preferences (preference_id, user_id, preferred_categories, notification_settings, language, theme, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_reading_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_reading_history (history_id, user_id, news_id, read_at, read_duration, read_percentage) FROM stdin;
\.


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_roles (role_id, role_name, role_slug, description, permissions, is_active, created_at, updated_at) FROM stdin;
1	Super Administrator	super_admin	Full system access with all permissions	{"global": true, "manage_ads": true, "manage_roles": true, "manage_users": true, "manage_admins": true, "manage_system": true, "manage_content": true, "view_analytics": true, "manage_settings": true}	t	2025-12-07 12:18:11.133695	2025-12-07 12:18:11.133695
2	Contributor	contributor	Can submit content for review	{"create_content": true, "edit_own_content": true}	t	2025-12-07 15:10:13.143432	2025-12-07 15:10:13.143432
\.


--
-- Data for Name: user_saved_articles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_saved_articles (saved_id, user_id, news_id, saved_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (session_id, user_id, ip_address, user_agent, last_activity, created_at, expires_at, is_active) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, phone, county, constituency, referral_code, referred_by, volunteer_interest, sms_updates, email_verified, phone_verified, password_hash, last_login, status, role_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: volunteers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.volunteers (volunteer_id, full_name, nickname, phone, email, county, constituency, expertise, availability, status, assigned_tasks, created_at, updated_at) FROM stdin;
\.


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
-- Name: ad_survey_questions_question_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_survey_questions_question_id_seq', 1, false);


--
-- Name: ad_survey_responses_response_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_survey_responses_response_id_seq', 1, false);


--
-- Name: ad_surveys_survey_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_surveys_survey_id_seq', 1, false);


--
-- Name: ad_tiers_tier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ad_tiers_tier_id_seq', 1, false);


--
-- Name: admin_activity_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_activity_log_log_id_seq', 58, true);


--
-- Name: admin_chat_messages_message_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.admin_chat_messages_message_id_seq', 1, true);


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

SELECT pg_catalog.setval('public.admins_admin_id_seq', 10, true);


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

SELECT pg_catalog.setval('public.breaking_news_breaking_id_seq', 8, true);


--
-- Name: categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_category_id_seq', 98, true);


--
-- Name: cleanup_history_cleanup_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cleanup_history_cleanup_id_seq', 1, false);


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
-- Name: editor_pick_pick_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.editor_pick_pick_id_seq', 8, true);


--
-- Name: email_queue_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.email_queue_queue_id_seq', 1, false);


--
-- Name: featured_news_featured_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.featured_news_featured_id_seq', 8, true);


--
-- Name: image_variants_variant_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.image_variants_variant_id_seq', 1, false);


--
-- Name: live_broadcast_sessions_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.live_broadcast_sessions_session_id_seq', 1, false);


--
-- Name: media_files_file_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.media_files_file_id_seq', 1, false);


--
-- Name: monthly_location_summary_summary_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.monthly_location_summary_summary_id_seq', 1, false);


--
-- Name: mpesa_b2c_transactions_b2c_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mpesa_b2c_transactions_b2c_id_seq', 1, false);


--
-- Name: mpesa_callback_log_callback_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mpesa_callback_log_callback_id_seq', 1, false);


--
-- Name: mpesa_stk_push_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mpesa_stk_push_log_log_id_seq', 1, false);


--
-- Name: mpesa_transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mpesa_transactions_transaction_id_seq', 1, false);


--
-- Name: news_approval_approval_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_approval_approval_record_id_seq', 21, true);


--
-- Name: news_approval_history_approval_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_approval_history_approval_id_seq', 2, true);


--
-- Name: news_categories_news_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_categories_news_category_id_seq', 32, true);


--
-- Name: news_comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_comments_comment_id_seq', 1, false);


--
-- Name: news_content_blocks_block_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_content_blocks_block_id_seq', 1, false);


--
-- Name: news_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_images_image_id_seq', 19, true);


--
-- Name: news_news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_news_id_seq', 11, true);


--
-- Name: news_quotes_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_quotes_images_image_id_seq', 14, true);


--
-- Name: news_quotes_quote_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.news_quotes_quote_id_seq', 16, true);


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

SELECT pg_catalog.setval('public.news_social_media_social_media_id_seq', 7, true);


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
-- Name: pinned_news_pinned_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pinned_news_pinned_id_seq', 8, true);


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
-- Name: social_videos_analytics_analytics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.social_videos_analytics_analytics_id_seq', 1, false);


--
-- Name: social_videos_video_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.social_videos_video_id_seq', 2, true);


--
-- Name: subscribers_subscriber_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscribers_subscriber_id_seq', 1, false);


--
-- Name: system_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_logs_log_id_seq', 6, true);


--
-- Name: system_settings_setting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.system_settings_setting_id_seq', 5, true);


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
-- Name: ad_survey_questions ad_survey_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_survey_questions
    ADD CONSTRAINT ad_survey_questions_pkey PRIMARY KEY (question_id);


--
-- Name: ad_survey_responses ad_survey_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_survey_responses
    ADD CONSTRAINT ad_survey_responses_pkey PRIMARY KEY (response_id);


--
-- Name: ad_surveys ad_surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_surveys
    ADD CONSTRAINT ad_surveys_pkey PRIMARY KEY (survey_id);


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
-- Name: editor_pick editor_pick_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.editor_pick
    ADD CONSTRAINT editor_pick_pkey PRIMARY KEY (pick_id);


--
-- Name: email_queue email_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_queue
    ADD CONSTRAINT email_queue_pkey PRIMARY KEY (queue_id);


--
-- Name: featured_news featured_news_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_news
    ADD CONSTRAINT featured_news_pkey PRIMARY KEY (featured_id);


--
-- Name: image_variants image_variants_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.image_variants
    ADD CONSTRAINT image_variants_pkey PRIMARY KEY (variant_id);


--
-- Name: live_broadcast_sessions live_broadcast_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_broadcast_sessions
    ADD CONSTRAINT live_broadcast_sessions_pkey PRIMARY KEY (session_id);


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
-- Name: mpesa_b2c_transactions mpesa_b2c_transactions_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_conversation_id_key UNIQUE (conversation_id);


--
-- Name: mpesa_b2c_transactions mpesa_b2c_transactions_mpesa_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_mpesa_receipt_number_key UNIQUE (mpesa_receipt_number);


--
-- Name: mpesa_b2c_transactions mpesa_b2c_transactions_originator_conversation_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_originator_conversation_id_key UNIQUE (originator_conversation_id);


--
-- Name: mpesa_b2c_transactions mpesa_b2c_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_pkey PRIMARY KEY (b2c_id);


--
-- Name: mpesa_callback_log mpesa_callback_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_callback_log
    ADD CONSTRAINT mpesa_callback_log_pkey PRIMARY KEY (callback_id);


--
-- Name: mpesa_stk_push_log mpesa_stk_push_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_stk_push_log
    ADD CONSTRAINT mpesa_stk_push_log_pkey PRIMARY KEY (log_id);


--
-- Name: mpesa_transactions mpesa_transactions_checkout_request_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_checkout_request_id_key UNIQUE (checkout_request_id);


--
-- Name: mpesa_transactions mpesa_transactions_merchant_request_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_merchant_request_id_key UNIQUE (merchant_request_id);


--
-- Name: mpesa_transactions mpesa_transactions_mpesa_receipt_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_mpesa_receipt_number_key UNIQUE (mpesa_receipt_number);


--
-- Name: mpesa_transactions mpesa_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: news_approval_history news_approval_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_pkey PRIMARY KEY (approval_id);


--
-- Name: news_approval news_approval_news_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_news_id_key UNIQUE (news_id);


--
-- Name: news_approval news_approval_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_pkey PRIMARY KEY (approval_record_id);


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
-- Name: news_content_blocks news_content_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_content_blocks
    ADD CONSTRAINT news_content_blocks_pkey PRIMARY KEY (block_id);


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
-- Name: news_quotes_images news_quotes_images_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes_images
    ADD CONSTRAINT news_quotes_images_pkey PRIMARY KEY (image_id);


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
-- Name: news news_uuid_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_uuid_key UNIQUE (uuid);


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
-- Name: pinned_news pinned_news_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pinned_news
    ADD CONSTRAINT pinned_news_pkey PRIMARY KEY (pinned_id);


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
-- Name: social_videos_analytics social_videos_analytics_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos_analytics
    ADD CONSTRAINT social_videos_analytics_pkey PRIMARY KEY (analytics_id);


--
-- Name: social_videos_analytics social_videos_analytics_video_id_stat_date_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos_analytics
    ADD CONSTRAINT social_videos_analytics_video_id_stat_date_key UNIQUE (video_id, stat_date);


--
-- Name: social_videos social_videos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos
    ADD CONSTRAINT social_videos_pkey PRIMARY KEY (video_id);


--
-- Name: social_videos social_videos_video_url_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos
    ADD CONSTRAINT social_videos_video_url_key UNIQUE (video_url);


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
-- Name: idx_breaking_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_breaking_active ON public.breaking_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_breaking_news_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_breaking_news_active ON public.breaking_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_breaking_priority; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_breaking_priority ON public.breaking_news USING btree (priority, starts_at DESC) WHERE (manually_removed = false);


--
-- Name: idx_broadcast_sessions_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_broadcast_sessions_active ON public.live_broadcast_sessions USING btree (session_started_at DESC) WHERE (session_ended_at IS NULL);


--
-- Name: idx_broadcast_sessions_video; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_broadcast_sessions_video ON public.live_broadcast_sessions USING btree (video_id);


--
-- Name: idx_categories_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_active ON public.categories USING btree (active) WHERE (active = true);


--
-- Name: idx_categories_active_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_active_order ON public.categories USING btree (active, order_index) WHERE (active = true);


--
-- Name: idx_categories_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_order ON public.categories USING btree (order_index);


--
-- Name: idx_categories_parent_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_categories_parent_active ON public.categories USING btree (parent_id, active, order_index);


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
-- Name: idx_content_blocks_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_content_blocks_data ON public.news_content_blocks USING gin (block_data);


--
-- Name: idx_content_blocks_news; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_content_blocks_news ON public.news_content_blocks USING btree (news_id, order_index);


--
-- Name: idx_content_blocks_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_content_blocks_type ON public.news_content_blocks USING btree (block_type);


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
-- Name: idx_editor_pick_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_editor_pick_active ON public.editor_pick USING btree (news_id, manually_removed);


--
-- Name: idx_featured_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_featured_active ON public.featured_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_featured_news_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_featured_news_active ON public.featured_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_featured_tier; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_featured_tier ON public.featured_news USING btree (tier, starts_at DESC) WHERE (manually_removed = false);


--
-- Name: idx_live_broadcast_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_live_broadcast_active ON public.live_broadcast_sessions USING btree (session_started_at DESC) WHERE (session_ended_at IS NULL);


--
-- Name: idx_live_broadcast_video_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_live_broadcast_video_id ON public.live_broadcast_sessions USING btree (video_id);


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
-- Name: idx_mpesa_b2c_advertiser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_b2c_advertiser ON public.mpesa_b2c_transactions USING btree (advertiser_id);


--
-- Name: idx_mpesa_b2c_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_b2c_status ON public.mpesa_b2c_transactions USING btree (status);


--
-- Name: idx_mpesa_callback_processed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_callback_processed ON public.mpesa_callback_log USING btree (processed);


--
-- Name: idx_mpesa_callback_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_callback_type ON public.mpesa_callback_log USING btree (callback_type);


--
-- Name: idx_mpesa_trans_advertiser; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_trans_advertiser ON public.mpesa_transactions USING btree (advertiser_id);


--
-- Name: idx_mpesa_trans_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_trans_date ON public.mpesa_transactions USING btree (transaction_date DESC);


--
-- Name: idx_mpesa_trans_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_trans_phone ON public.mpesa_transactions USING btree (phone_number);


--
-- Name: idx_mpesa_trans_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_mpesa_trans_status ON public.mpesa_transactions USING btree (status);


--
-- Name: idx_news_approval_news; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_approval_news ON public.news_approval USING btree (news_id);


--
-- Name: idx_news_approval_workflow; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_approval_workflow ON public.news_approval USING btree (workflow_status);


--
-- Name: idx_news_author; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_author ON public.news USING btree (author_id);


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
-- Name: idx_news_category_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_category_status ON public.news USING btree (category_id, status, published_at DESC);


--
-- Name: idx_news_combined_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_combined_search ON public.news USING gin (to_tsvector('english'::regconfig, (((title)::text || ' '::text) || content)));


--
-- Name: idx_news_content_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_content_search ON public.news USING gin (to_tsvector('english'::regconfig, content));


--
-- Name: idx_news_editor_pick; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_editor_pick ON public.news USING btree (editor_pick) WHERE (editor_pick = true);


--
-- Name: idx_news_fact_checked; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_fact_checked ON public.news USING btree (fact_checked) WHERE (fact_checked = true);


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
-- Name: idx_news_images_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_metadata_gin ON public.news_images USING gin (metadata);


--
-- Name: idx_news_images_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_news_id ON public.news_images USING btree (news_id);


--
-- Name: idx_news_images_storage; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_images_storage ON public.news_images USING btree (storage_provider);


--
-- Name: idx_news_last_edited_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_last_edited_at ON public.news USING btree (last_edited_at DESC);


--
-- Name: idx_news_last_edited_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_last_edited_by ON public.news USING btree (last_edited_by);


--
-- Name: idx_news_performance; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_performance ON public.news USING btree (views, likes_count, comments_count);


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
-- Name: idx_news_quotes_data_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_quotes_data_gin ON public.news USING gin (quotes_data);


--
-- Name: idx_news_quotes_editor_pick; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_quotes_editor_pick ON public.news_quotes USING btree (editor_pick) WHERE (editor_pick = true);


--
-- Name: idx_news_reading_level; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_reading_level ON public.news USING btree (reading_level);


--
-- Name: idx_news_revision; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_revision ON public.news USING btree (revision DESC);


--
-- Name: idx_news_sensitive; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_sensitive ON public.news USING btree (sensitive) WHERE (sensitive = true);


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
-- Name: idx_news_social_media_news; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_media_news ON public.news_social_media USING btree (news_id, is_featured, display_order);


--
-- Name: idx_news_social_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_social_metadata_gin ON public.news_social_media USING gin (metadata);


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
-- Name: idx_news_sources_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_sources_gin ON public.news USING gin (sources);


--
-- Name: idx_news_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_status ON public.news USING btree (status);


--
-- Name: idx_news_status_published; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_status_published ON public.news USING btree (status, published_at DESC) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_title_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_title_search ON public.news USING gin (to_tsvector('english'::regconfig, (title)::text));


--
-- Name: idx_news_trending; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_trending ON public.news USING btree (status, published_at DESC, views, likes_count, comments_count, share_count) WHERE (status = 'published'::public.news_status);


--
-- Name: idx_news_uuid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_news_uuid ON public.news USING btree (uuid);


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
-- Name: idx_page_views_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_page_views_created ON public.page_views USING btree (created_at DESC);


--
-- Name: idx_page_views_news_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_page_views_news_id ON public.page_views USING btree (news_id);


--
-- Name: idx_pinned_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pinned_active ON public.pinned_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_pinned_news_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pinned_news_active ON public.pinned_news USING btree (news_id, manually_removed, ends_at);


--
-- Name: idx_pinned_position; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_pinned_position ON public.pinned_news USING btree ("position", starts_at DESC) WHERE (manually_removed = false);


--
-- Name: idx_public_session_expire; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_public_session_expire ON public.public_session_store USING btree (expire);


--
-- Name: idx_quotes_images_cloudflare; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quotes_images_cloudflare ON public.news_quotes_images USING btree (cloudflare_id);


--
-- Name: idx_quotes_images_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quotes_images_metadata_gin ON public.news_quotes_images USING gin (metadata);


--
-- Name: idx_quotes_images_quote_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_quotes_images_quote_id ON public.news_quotes_images USING btree (quote_id);


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
-- Name: idx_social_videos_created; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_created ON public.social_videos USING btree (created_at DESC);


--
-- Name: idx_social_videos_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_created_by ON public.social_videos USING btree (created_by);


--
-- Name: idx_social_videos_display_order; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_display_order ON public.social_videos USING btree (display_order, created_at DESC);


--
-- Name: idx_social_videos_editor_pick; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_editor_pick ON public.social_videos USING btree (editor_pick) WHERE (editor_pick = true);


--
-- Name: idx_social_videos_featured; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_featured ON public.social_videos USING btree (featured, featured_until) WHERE (featured = true);


--
-- Name: idx_social_videos_is_live; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_is_live ON public.social_videos USING btree (is_live) WHERE (is_live = true);


--
-- Name: idx_social_videos_metadata_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_metadata_gin ON public.social_videos USING gin (metadata);


--
-- Name: idx_social_videos_oembed_gin; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_oembed_gin ON public.social_videos USING gin (oembed_data);


--
-- Name: idx_social_videos_platform; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_platform ON public.social_videos USING btree (platform);


--
-- Name: idx_social_videos_scheduled; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_scheduled ON public.social_videos USING btree (scheduled_start_time) WHERE (scheduled_start_time IS NOT NULL);


--
-- Name: idx_social_videos_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_status ON public.social_videos USING btree (status);


--
-- Name: idx_social_videos_status_visibility; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_social_videos_status_visibility ON public.social_videos USING btree (status, visibility);


--
-- Name: idx_survey_questions_survey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_survey_questions_survey ON public.ad_survey_questions USING btree (survey_id, order_index);


--
-- Name: idx_survey_responses_survey; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_survey_responses_survey ON public.ad_survey_responses USING btree (survey_id);


--
-- Name: idx_survey_responses_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_survey_responses_user ON public.ad_survey_responses USING btree (user_id);


--
-- Name: idx_surveys_dates; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_surveys_dates ON public.ad_surveys USING btree (starts_at, ends_at);


--
-- Name: idx_surveys_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_surveys_status ON public.ad_surveys USING btree (status);


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
-- Name: idx_video_analytics_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_video_analytics_date ON public.social_videos_analytics USING btree (stat_date DESC);


--
-- Name: idx_video_analytics_video; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_video_analytics_video ON public.social_videos_analytics USING btree (video_id, stat_date DESC);


--
-- Name: news_quotes_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_quotes_active_idx ON public.news_quotes USING btree (active);


--
-- Name: news_quotes_created_at_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_quotes_created_at_idx ON public.news_quotes USING btree (created_at DESC);


--
-- Name: news_quotes_images_quote_id_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX news_quotes_images_quote_id_idx ON public.news_quotes_images USING btree (quote_id);


--
-- Name: news_quotes set_news_quotes_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_news_quotes_updated_at BEFORE UPDATE ON public.news_quotes FOR EACH ROW EXECUTE FUNCTION public.update_news_quotes_updated_at_column();


--
-- Name: news_quotes trg_news_quotes_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_news_quotes_updated BEFORE UPDATE ON public.news_quotes FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();


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
-- Name: mpesa_b2c_transactions trigger_mpesa_b2c_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_mpesa_b2c_updated BEFORE UPDATE ON public.mpesa_b2c_transactions FOR EACH ROW EXECUTE FUNCTION public.update_mpesa_timestamp();


--
-- Name: mpesa_transactions trigger_mpesa_trans_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_mpesa_trans_updated BEFORE UPDATE ON public.mpesa_transactions FOR EACH ROW EXECUTE FUNCTION public.update_mpesa_timestamp();


--
-- Name: news_social_media trigger_social_media_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_social_media_updated BEFORE UPDATE ON public.news_social_media FOR EACH ROW EXECUTE FUNCTION public.update_social_media_timestamp();


--
-- Name: social_videos trigger_social_videos_updated; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_social_videos_updated BEFORE UPDATE ON public.social_videos FOR EACH ROW EXECUTE FUNCTION public.update_social_videos_timestamp();


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
-- Name: ad_survey_questions ad_survey_questions_survey_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_survey_questions
    ADD CONSTRAINT ad_survey_questions_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES public.ad_surveys(survey_id) ON DELETE CASCADE;


--
-- Name: ad_survey_responses ad_survey_responses_survey_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_survey_responses
    ADD CONSTRAINT ad_survey_responses_survey_id_fkey FOREIGN KEY (survey_id) REFERENCES public.ad_surveys(survey_id) ON DELETE CASCADE;


--
-- Name: ad_survey_responses ad_survey_responses_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ad_survey_responses
    ADD CONSTRAINT ad_survey_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


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
-- Name: breaking_news breaking_news_activated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breaking_news
    ADD CONSTRAINT breaking_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


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
-- Name: donations donations_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.donations
    ADD CONSTRAINT donations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE SET NULL;


--
-- Name: editor_pick editor_pick_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.editor_pick
    ADD CONSTRAINT editor_pick_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: editor_pick editor_pick_picked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.editor_pick
    ADD CONSTRAINT editor_pick_picked_by_fkey FOREIGN KEY (picked_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: featured_news featured_news_activated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_news
    ADD CONSTRAINT featured_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: featured_news featured_news_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.featured_news
    ADD CONSTRAINT featured_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_quotes_images fk_news_quotes_images_quote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes_images
    ADD CONSTRAINT fk_news_quotes_images_quote FOREIGN KEY (quote_id) REFERENCES public.news_quotes(quote_id) ON DELETE CASCADE;


--
-- Name: news fk_primary_category; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT fk_primary_category FOREIGN KEY (primary_category_id) REFERENCES public.categories(category_id) ON DELETE SET NULL;


--
-- Name: live_broadcast_sessions live_broadcast_sessions_video_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.live_broadcast_sessions
    ADD CONSTRAINT live_broadcast_sessions_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.social_videos(video_id) ON DELETE CASCADE;


--
-- Name: media_files media_files_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id);


--
-- Name: mpesa_b2c_transactions mpesa_b2c_transactions_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_b2c_transactions
    ADD CONSTRAINT mpesa_b2c_transactions_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES public.advertisers(advertiser_id) ON DELETE SET NULL;


--
-- Name: mpesa_stk_push_log mpesa_stk_push_log_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_stk_push_log
    ADD CONSTRAINT mpesa_stk_push_log_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.mpesa_transactions(transaction_id) ON DELETE CASCADE;


--
-- Name: mpesa_transactions mpesa_transactions_advertiser_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mpesa_transactions
    ADD CONSTRAINT mpesa_transactions_advertiser_id_fkey FOREIGN KEY (advertiser_id) REFERENCES public.advertisers(advertiser_id) ON DELETE SET NULL;


--
-- Name: news_approval news_approval_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: news_approval_history news_approval_history_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_approval_history news_approval_history_reviewer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval_history
    ADD CONSTRAINT news_approval_history_reviewer_id_fkey FOREIGN KEY (reviewer_id) REFERENCES public.admins(admin_id) ON DELETE CASCADE;


--
-- Name: news_approval news_approval_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news_approval news_approval_rejected_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: news_approval news_approval_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_approval
    ADD CONSTRAINT news_approval_submitted_by_fkey FOREIGN KEY (submitted_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


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
-- Name: news_content_blocks news_content_blocks_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_content_blocks
    ADD CONSTRAINT news_content_blocks_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news news_fact_checked_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_fact_checked_by_fkey FOREIGN KEY (fact_checked_by) REFERENCES public.admins(admin_id);


--
-- Name: news_images news_images_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_images
    ADD CONSTRAINT news_images_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


--
-- Name: news news_last_edited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_last_edited_by_fkey FOREIGN KEY (last_edited_by) REFERENCES public.admins(admin_id);


--
-- Name: news_quotes_images news_quotes_images_quote_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.news_quotes_images
    ADD CONSTRAINT news_quotes_images_quote_id_fkey FOREIGN KEY (quote_id) REFERENCES public.news_quotes(quote_id) ON DELETE CASCADE;


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
-- Name: pinned_news pinned_news_activated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pinned_news
    ADD CONSTRAINT pinned_news_activated_by_fkey FOREIGN KEY (activated_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


--
-- Name: pinned_news pinned_news_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pinned_news
    ADD CONSTRAINT pinned_news_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(news_id) ON DELETE CASCADE;


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
-- Name: social_videos_analytics social_videos_analytics_video_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos_analytics
    ADD CONSTRAINT social_videos_analytics_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.social_videos(video_id) ON DELETE CASCADE;


--
-- Name: social_videos social_videos_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.social_videos
    ADD CONSTRAINT social_videos_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.admins(admin_id) ON DELETE SET NULL;


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

\unrestrict rfKhMDuTuveI3f8assXn4dejBIYoNR9hXeVNS0GAaqMzzpaceiC6cipPlHlaYi8

