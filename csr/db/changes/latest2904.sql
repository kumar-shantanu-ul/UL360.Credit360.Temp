define version=2904
define minor_version=0
define is_combined=1
@update_header

-- *** DDL ***
-- Create tables
-- CSR
CREATE SEQUENCE csr.benchmark_dashb_char_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	NOCACHE
	NOORDER
;

CREATE TABLE csr.benchmark_dashboard_char (
	app_sid							NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10) 		NOT NULL,
	benchmark_dashboard_char_id		NUMBER(10) 		NOT NULL,
	pos								NUMBER(10) 		NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT PK_BENCHMARK_DAS_CHAR PRIMARY KEY (app_sid, benchmark_dashboard_char_id),
	CONSTRAINT FK_BENCHMARK_DAS_REGION_METRIC FOREIGN KEY (app_sid, ind_sid) REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT FK_BENCHMARK_DAS_TAG_GRP FOREIGN KEY (app_sid, tag_group_id) REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT UK_BENCHMARK_DAS_IND_TAG_GRP UNIQUE (app_sid, benchmark_dashboard_sid, ind_sid, tag_group_id),
	CONSTRAINT CHK_BENCHMARK_DAS_IND_TAG_GRP CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

-- indexes
CREATE INDEX csr.IX_BENCHMARK_DAS_CHAR_IND_SID ON csr.benchmark_dashboard_char (app_sid, benchmark_dashboard_sid);
-- FK indexes
CREATE INDEX csr.IX_BENCHMARK_DAS_IND_SID ON csr.benchmark_dashboard_char (app_sid, ind_sid);
CREATE INDEX csr.IX_BENCHMARK_DAS_TAG_GROUP_ID ON csr.benchmark_dashboard_char (app_sid, tag_group_id);

-- translate year_built_ind_sid to a characteristic
DECLARE
BEGIN
	FOR r IN (
		SELECT app_sid, benchmark_dashboard_sid, year_built_ind_sid
		  FROM csr.benchmark_dashboard
		 WHERE year_built_ind_sid IS NOT NULL
	)
	LOOP
		INSERT INTO csr.benchmark_dashboard_char (app_sid, benchmark_dashboard_sid, benchmark_dashboard_char_id, pos, ind_sid)
			 VALUES (r.app_sid, r.benchmark_dashboard_sid, csr.benchmark_dashb_char_id_seq.NEXTVAL, 1, r.year_built_ind_sid);
	END LOOP;
END;
/

-- drop year_built_ind_sid
ALTER TABLE csr.benchmark_dashboard DROP CONSTRAINT FK_BENCH_DASH_YEAR_BUILT_IND;
ALTER TABLE csr.benchmark_dashboard DROP COLUMN year_built_ind_sid;

-- CSRIMP
CREATE TABLE csrimp.benchmark_dashboard (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	name							VARCHAR2(255)	NOT NULL,
	start_dtm						DATE 			NOT NULL,
	end_dtm							DATE,
	lookup_key						VARCHAR2(255),
	period_set_id					NUMBER(10)		NOT NULL,
	period_interval_id				NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_char (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	benchmark_dashboard_char_id		NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT PK_BENCHMARK_DASHB_CHAR PRIMARY KEY (csrimp_session_id, benchmark_dashboard_char_id),
	CONSTRAINT UK_BENCHMARK_DASHB_IND_TG_GRP UNIQUE (csrimp_session_id, benchmark_dashboard_sid, ind_sid, tag_group_id),
	CONSTRAINT CHK_BENCHMARK_DASHB_IND_TG_GRP CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_CHAR_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_ind (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10)		NOT NULL,
	display_name					VARCHAR2(255),
	scenario_run_sid				NUMBER(10),
	floor_area_ind_sid				NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_IND PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid, ind_sid),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_IND_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_plugin (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	plugin_id						NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_PLUGIN PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid, plugin_id),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_PLG_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	name							VARCHAR2(255)	NOT NULL,
	start_dtm						DATE 			NOT NULL,
	end_dtm							DATE,
	lookup_key						VARCHAR2(255),
	period_set_id					NUMBER(10)		NOT NULL,
	period_interval_id				NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD PRIMARY KEY (csrimp_session_id, metric_dashboard_sid),
	CONSTRAINT FK_METRIC_DASHBOARD_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard_ind (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	block_title						VARCHAR2(32)	NOT NULL,
	block_css_class					VARCHAR2(32)	NOT NULL,
	inten_view_scenario_run_sid		NUMBER(10)		NOT NULL,
	inten_view_floor_area_ind_sid	NUMBER(10),
	absol_view_scenario_run_sid		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD_IND PRIMARY KEY (csrimp_session_id, metric_dashboard_sid, ind_sid),
	CONSTRAINT FK_METRIC_DASHBOARD_IND_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard_plugin (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	plugin_id						NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD_PLUGIN PRIMARY KEY (csrimp_session_id, metric_dashboard_sid, plugin_id),
	CONSTRAINT FK_METRIC_DASHBOARD_PLUGIN_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- CSRIMP MAP
CREATE TABLE csrimp.map_benchmark_dashboard_char (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	new_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_MAP_BENCHMARK_DAS_CHAR PRIMARY KEY (csrimp_session_id, old_benchmark_das_char_id) USING INDEX,
	CONSTRAINT UK_MAP_BENCHMARK_DAS_CHAR UNIQUE (csrimp_session_id, new_benchmark_das_char_id) USING INDEX,
	CONSTRAINT FK_MAP_BENCHMARK_DAS_CHAR_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables
-- Column is NOT NULL in schema but created as NULL in change script...
BEGIN
	FOR r IN (
		SELECT nullable
		  FROM all_tab_columns
		 WHERE owner = 'CHAIN'
		   AND table_name = 'SAVED_FILTER'
		   AND column_name = 'GROUP_KEY'
		   AND nullable = 'N'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.saved_filter MODIFY group_key NULL';
	END LOOP;
END;
/

ALTER TABLE chain.filter_value ADD (
	filter_type NUMBER(10) NULL, -- Should be not-null, but can't guarantee existing data is consistent
	null_filter NUMBER(10) DEFAULT 0 NOT NULL, -- chain.filter_pkg.NULL_FILTER_ALL
    CONSTRAINT ck_null_filter_valid CHECK (
		null_filter IN (
			0, -- chain.filter_pkg.NULL_FILTER_ALL
			1, -- chain.filter_pkg.NULL_FILTER_REQUIRE_NULL
			2  -- chain.filter_pkg.NULL_FILTER_EXCLUDE_NULL
		)
	),
    CONSTRAINT ck_filter_type_valid CHECK (
		filter_type IS NULL OR filter_type IN (
			1, -- chain.filter_pkg.FILTER_VALUE_TYPE_NUMBER
			2, -- chain.filter_pkg.FILTER_VALUE_TYPE_NUMBER_RANGE
			3, -- chain.filter_pkg.FILTER_VALUE_TYPE_STRING
			4, -- chain.filter_pkg.FILTER_VALUE_TYPE_USER
			5, -- chain.filter_pkg.FILTER_VALUE_TYPE_REGION
			6, -- chain.filter_pkg.FILTER_VALUE_TYPE_DATE_RANGE
			7, -- chain.filter_pkg.FILTER_VALUE_TYPE_SAVED
			8  -- chain.filter_pkg.FILTER_VALUE_TYPE_COMPOUND
		)
	) 
);

DELETE FROM csrimp.imp_session;
TRUNCATE TABLE csrimp.chain_filter_value;
ALTER TABLE csrimp.chain_filter_value ADD (
	filter_type NUMBER(10) NULL, 
	null_filter NUMBER(10) NOT NULL
);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_char TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_ind TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_plugin TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard_ind TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard_plugin TO web_user;

GRANT INSERT ON csr.benchmark_dashboard TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_char TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_ind TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_plugin TO csrimp;
GRANT INSERT ON csr.metric_dashboard TO csrimp;
GRANT INSERT ON csr.metric_dashboard_ind TO csrimp;
GRANT INSERT ON csr.metric_dashboard_plugin TO csrimp;

GRANT SELECT ON csr.benchmark_dashb_char_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /cvs/csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
		   fv.filter_type, fv.null_filter
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE TYPE T_NORMALISED_VAL_ROW AS 
  OBJECT ( 
	REGION_SID		NUMBER(10),
	START_DTM		DATE,
	END_DTM			DATE,
	VAL_NUMBER		NUMBER(24, 10)
  );
/
CREATE OR REPLACE TYPE T_NORMALISED_VAL_TABLE AS 
  TABLE OF T_NORMALISED_VAL_ROW;
/

DECLARE
	FUNCTION eq(
		in_a	IN	NUMBER,
		in_b	IN	NUMBER
	) RETURN BOOLEAN
	AS
	BEGIN
		IF in_a = in_b OR (in_a IS NULL AND in_b IS NULL) THEN
			RETURN TRUE;
		END IF;
		RETURN FALSE;
	END;

	FUNCTION ne(
		in_a	IN	VARCHAR2,
		in_b	IN	VARCHAR2
	) RETURN BOOLEAN
	AS
	BEGIN
		RETURN NOT eq(in_a, in_b);
	END;

	-- version with ACT since this is sometimes called by older SPs that are passed ACTs, so it 
	-- is more consistent to also call this with the same ACT (just in case they were different
	-- for some reason).
	FUNCTION CheckCapability(
		in_act_id      					IN 	security.security_pkg.T_ACT_ID,
		in_capability  					IN	security.security_pkg.T_SO_NAME
	) RETURN BOOLEAN
	AS
		v_allow_by_default      csr.capability.allow_by_default%TYPE;
		v_capability_sid        security.security_pkg.T_SID_ID;
	BEGIN
		-- this also serves to check that the capability is valid
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;
	
		BEGIN
			-- get sid of capability to check permission
			v_capability_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), '/Capabilities/' || in_capability);
			-- check permissions....
			RETURN security.Security_Pkg.IsAccessAllowedSID(in_act_id, v_capability_sid, security.security_pkg.PERMISSION_WRITE);
		EXCEPTION 
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				IF v_allow_by_default = 1 THEN
					RETURN TRUE; -- let them do it if it's not configured
				ELSE
					RETURN FALSE;
				END IF;
		END;
	END; 

	FUNCTION IsPeriodLocked(
		in_app_sid						IN	security.security_pkg.T_SID_ID,
		in_start_dtm					IN	csr.customer.lock_start_dtm%TYPE,
		in_end_dtm						IN	csr.customer.lock_end_dtm%TYPE
	) RETURN NUMBER
	AS
		CURSOR c IS
			SELECT lock_start_dtm, lock_end_dtm 
			  FROM csr.customer
			 WHERE app_sid = in_app_sid
			   AND lock_start_dtm < in_end_dtm
			   AND lock_end_dtm > in_start_dtm;
		r	c%ROWTYPE;
	BEGIN
		OPEN c;
		FETCH c INTO r;
		IF c%NOTFOUND THEN
			RETURN 0;
		ELSE
			RETURN 1;
		END IF;
	END;

	FUNCTION GetPctOwnership(
		in_ind_sid          IN	security.security_pkg.T_SID_ID,
		in_region_sid       IN	security.security_pkg.T_SID_ID,
		in_dtm              IN  date
	) RETURN csr.pct_ownership.pct%TYPE
	IS
		v_pct_ownership_applies csr.measure.pct_Ownership_applies%TYPE;
		v_pct                   csr.pct_ownership.pct%TYPE;
	BEGIN
		BEGIN
			SELECT pct_ownership_applies
			  INTO v_pct_ownership_applies
			  FROM csr.measure m, csr.ind i
			 WHERE i.measure_sid = m.measure_sid
			   AND i.ind_sid = in_ind_sid;
		EXCEPTION
			-- default to 0
			WHEN NO_DATA_FOUND THEN 
				v_pct_ownership_applies := 0;
		END;
		IF v_pct_ownership_applies = 0 THEN
			RETURN 1; -- assume 100% ownership
		END IF;
    
		BEGIN
			SELECT pct
			  INTO v_pct
			  FROM csr.pct_ownership
			 WHERE region_sid = in_region_sid
			   AND start_dtm <= in_dtm
			   AND NVL(end_dtm, in_dtm + 1) > in_dtm; -- end_dtm is null will always return true
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pct := 1; -- assume 100% ownership
		END;
		RETURN v_pct;
	END;

	PROCEDURE SetValueWithReasonWithSid(
		in_user_sid						IN	security.security_pkg.T_SID_ID,
		in_ind_sid						IN	security.security_pkg.T_SID_ID,
		in_region_sid					IN	security.security_pkg.T_SID_ID,
		in_period_start					IN	csr.val.period_start_dtm%TYPE,
		in_period_end					IN	csr.val.period_end_dtm%TYPE,
		in_val_number					IN	csr.val.val_number%TYPE,
		in_flags						IN	csr.val.flags%TYPE DEFAULT 0,
		in_source_type_id				IN	csr.val.source_type_id%TYPE DEFAULT 0,
		in_source_id					IN	csr.val.source_id%TYPE DEFAULT NULL,
		in_entry_conversion_id			IN	csr.val.entry_measure_conversion_id%TYPE DEFAULT NULL,
		in_entry_val_number				IN	csr.val.entry_val_number%TYPE DEFAULT NULL,
		in_error_code					IN	csr.val.error_code%TYPE DEFAULT NULL,
		in_update_flags					IN	NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
		in_reason						IN	csr.val_change.reason%TYPE,
		in_note							IN	csr.val.note%TYPE DEFAULT NULL,
		in_have_file_uploads			IN	NUMBER,
		in_file_uploads					IN	security.security_pkg.T_SID_IDS,
		out_val_id						OUT	csr.val.val_id%TYPE
	)
	AS
		CURSOR c_indicator IS
			SELECT m.scale, i.app_sid, i.ind_type, i.factor_type_id,
				   NVL(i.divisibility, m.divisibility) divisibility
			  FROM csr.ind i, csr.measure m
			 WHERE i.ind_sid = in_ind_sid AND i.measure_sid = m.measure_sid;
		r_indicator 	c_indicator%ROWTYPE;
		CURSOR c_update(v_region_sid security.security_pkg.T_SID_ID) IS
			SELECT val_id, val_number, flags, source_id, source_type_id, error_code, entry_measure_conversion_id, entry_val_number, note
			  FROM csr.val
			 WHERE ind_sid = in_ind_sid
			   AND region_sid = v_region_sid
			   AND period_start_dtm = in_period_start
			   AND period_end_dtm = in_period_end
			   FOR UPDATE;
		r_update 						c_update%ROWTYPE;
		v_change_period_start			csr.val.period_start_dtm%TYPE := in_period_start;
		v_change_period_end				csr.val.period_end_dtm%TYPE := in_period_end;
		v_helper_pkg					csr.source_type.helper_pkg%TYPE;
		v_is_changed_value 	 			BOOLEAN;
		c								SYS_REFCURSOR;
		v_rounded_in_val_number			csr.val.val_number%TYPE;
		v_entry_val_number  			csr.val.entry_val_number%TYPE;
		v_region_type					csr.region.region_type%TYPE;
		v_is_new_value					BOOLEAN DEFAULT FALSE;
		v_is_changed_detail				BOOLEAN;
		v_is_changed_note				BOOLEAN;
		v_file_changes					NUMBER(10);
		v_file_uploads					security.T_SID_TABLE;
		v_pct_ownership					NUMBER;
		v_scaled_val_number				csr.val.val_number%TYPE;
		v_scaled_entry_val_number		csr.val.entry_val_number%TYPE;
	BEGIN
		--security_pkg.debugmsg('set ind='||in_ind_sid||', region='||in_region_sid||', start='||in_period_start||
		--	', end='||in_period_end||', val='||in_val_number||', update_flags='||in_update_flags);
		OPEN c_indicator;
		FETCH c_indicator INTO r_indicator;
		IF c_indicator%NOTFOUND THEN	
			RAISE_APPLICATION_ERROR(-20001, 'cannot find indicator '||in_ind_sid);
		END IF;
		CLOSE c_indicator;

		-- If the period is locked (unless we have special capability), disallow writing, except for things from scrag which indicate a recalc of some 
		-- type has taken place -- we'd otherwise lose the values.
		IF in_source_type_id NOT IN (5, 6) AND NOT
		   CheckCapability(security.security_pkg.GetAct, 'Can edit forms before system lock date') AND
		   IsPeriodLocked(r_indicator.app_sid, in_period_start, in_period_end) = 1 THEN
			-- TODO: log that we tried to write to a historic value
			out_val_id := -1; -- -1 means we didn't do anything
			RETURN;	
		END IF;

		-- round it as we'll put it in the database, and apply pctOwnership so long
		-- as we're not aggregating
		IF in_source_type_id IN (5,6) AND bitand(in_update_flags, 8) = 0 THEN
			v_rounded_in_val_number := ROUND(in_val_number, 10);
		ELSE
			v_pct_ownership := getPctOwnership(in_ind_sid, in_region_sid, in_period_start);
			v_rounded_in_val_number := ROUND(in_val_number * v_pct_ownership, 10);
		END IF;

		-- this is a bit of a hack for existing code that calls this.
		-- It supports calling in with in_entry_val_number IS NULL and in_entry_conversion_id IS NULL and v_entry_val_number IS NOT NULL
		-- if in_entry_conversion_id is null then put our number into v_entry_val_number since this is the number actually entered (we might have modified val_number for pct ownership)
		IF in_entry_conversion_id IS NULL THEN
			v_entry_val_number := in_val_number;
		ELSE
			v_entry_val_number := in_entry_val_number;
		END IF;
    
		-- clear or scale any overlapping values (we scale for stored calcs / aggregates, but clear for other value types)
		-- there are multiple cases, but basically it boils down to having a non-overlapping left/right portion or the value being completely covered
		-- for the left/right cases we either scale according to divisibility or create NULLs covering the non-overlapping portion 
		-- (to clear aggregates up the tree in those time periods)
		-- for the complete coverage case the old value simply needs to be removed (but any value with the exact period is simply updated in place)
		--security_pkg.debugmsg('adding value for ind='||in_ind_sid||', region='||in_region_sid||',period='||in_period_start||' -> '||in_period_end);    
		FOR r IN (SELECT val_id, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id
    				FROM csr.val
				   WHERE ind_sid = in_ind_sid
					 AND region_sid = in_region_sid
					 AND period_end_dtm > in_period_start
					 AND period_start_dtm < in_period_end
					 AND NOT (period_start_dtm = in_period_start AND period_end_dtm = in_period_end)
			     		 FOR UPDATE) LOOP
			v_change_period_start := LEAST(v_change_period_start, r.period_start_dtm);
			v_change_period_end := GREATEST(v_change_period_end, r.period_end_dtm);
		
			-- non-overlapping portion on the left
			IF r.period_start_dtm < in_period_start THEN
				IF r.source_type_id IN (5,6,12) THEN
					IF r_indicator.divisibility = 1 THEN
						v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
						v_scaled_entry_val_number := (r.entry_val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
					ELSE
						v_scaled_val_number := r.val_number;
						v_scaled_entry_val_number := r.entry_val_number;
					END IF;

					--security_pkg.debugmsg('adding left value from '||r.period_start_dtm||' to '||in_period_start||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');				
					INSERT INTO csr.val
						(val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
					VALUES
						(csr.val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, r.period_start_dtm, in_period_start, v_scaled_val_number, 
						 r.error_code, v_scaled_entry_val_number, r.source_type_id);
				END IF;			
			END IF;

			-- non-overlapping portion on the right
			IF r.period_end_dtm > in_period_end THEN
			
				IF r.source_type_id IN (5,6,12) THEN
					IF r_indicator.divisibility = 1 THEN
						v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
						v_scaled_entry_val_number := (r.entry_val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
					ELSE
						v_scaled_val_number := r.val_number;
						v_scaled_entry_val_number := r.entry_val_number;
					END IF;

					--security_pkg.debugmsg('adding right value from '||in_period_end||' to '||r.period_end_dtm||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');
					INSERT INTO csr.val
						(val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
					VALUES
						(csr.val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_end, r.period_end_dtm, v_scaled_val_number, 
						 r.error_code, v_scaled_entry_val_number, r.source_type_id);
				END IF;
			END IF;
		
			-- remove the overlapping value
			--security_pkg.debugmsg('clearing overlapping value '||r.val_id||' (period '||r.period_start_dtm||' -> '||r.period_end_dtm||'), source='||r.source_type_id||', val='||r.val_number);
			UPDATE csr.imp_val
			   SET set_val_id = NULL 
			 WHERE set_val_id = r.val_id;
		 
			DELETE FROM csr.val_file
			 WHERE val_id = r.val_id;

			DELETE FROM csr.val_accuracy
			 WHERE val_id = r.val_id;
		 
			DELETE FROM csr.val
			 WHERE val_id = r.val_id;
		END LOOP;
			  
		-- upsert (there are constraints on val which will throw DUP_VAL_ON_INDEX if this should be an update)
		BEGIN
			INSERT INTO csr.val (val_id, ind_sid, region_sid, period_start_dtm,
				period_end_dtm,  val_number, flags, source_id, source_type_id,
				entry_measure_conversion_id, entry_val_number, note, error_code)
			VALUES (csr.val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_start,
				in_period_end,  v_rounded_in_val_number, in_flags, in_source_id, in_source_type_id, 
				in_entry_conversion_id, v_entry_val_number, in_note, in_error_code)
			RETURNING val_id INTO out_val_id;
			v_is_new_value := true;
			-- only mark this down as a change if we're really entering a value / error (nulls don't count as no row effectively means null)
			IF v_rounded_in_val_number IS NOT NULL OR in_error_code IS NOT NULL THEN
        		v_is_changed_value := true;
    		END IF;
    		IF in_note IS NOT NULL THEN
				v_is_changed_note := true;
    		END IF;		
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- do we really need to update?
				OPEN c_update(in_region_sid);
				FETCH c_update INTO r_update;
				IF c_update%NOTFOUND THEN
					RAISE_APPLICATION_ERROR(-20001,'Constraint violated but no value found ');
				END IF;

				out_val_id := r_update.val_id;
                    
				v_is_changed_value := r_update.val_number != v_rounded_in_val_number
					OR (r_update.val_number IS NULL AND v_rounded_in_val_number IS NOT NULL)
					OR (r_update.val_number IS NOT NULL AND v_rounded_in_val_number IS NULL)
               		OR r_update.error_code != in_error_code
					OR (r_update.error_code IS NULL AND in_error_code IS NOT NULL)
					OR (r_update.error_code IS NOT NULL AND in_error_code IS NULL);

				v_is_changed_note := NVL(dbms_lob.compare(r_update.note, in_note), -1) != 0;

				-- check for details changing -- we still want to write rows to val_change
				-- if that is the case (but not to trigger recalcs)
        		v_is_changed_detail :=
				   ne(r_update.source_type_id, in_source_type_id) OR
        		   ne(r_update.source_id, in_source_id) OR
        		   ne(r_update.entry_measure_conversion_id, in_entry_conversion_id) OR 
        		   ne(r_update.entry_val_number, in_entry_val_number) OR
        		   ne(r_update.flags, in_flags) OR
        		   v_is_changed_note;

				-- check files using the SIDs (if supplied)
				IF NOT v_is_changed_detail AND in_have_file_uploads = 1 THEN
					v_file_uploads := security.security_pkg.SidArrayToTable(in_file_uploads);

					SELECT COUNT(*)
					  INTO v_file_changes
					  FROM (SELECT file_upload_sid
							  FROM csr.val_file
							 WHERE val_id = r_update.val_id
							 MINUS
							SELECT column_value
							  FROM TABLE(v_file_uploads)
							 UNION
							SELECT column_value
							  FROM TABLE(v_file_uploads)
							 MINUS
							SELECT file_upload_sid
							  FROM csr.val_file
							 WHERE val_id = r_update.val_id);

					v_is_changed_detail := v_file_changes > 0;
				END IF;
            
				-- check for INSERT_ONLY - this means that we never update values
				-- this is useful if we want to ask users to explain their changes
				IF bitand(in_update_flags, 4) > 0 AND v_is_changed_value THEN
					-- check for INSERT_ONLY AND a change in value (including old value is NOT null and our new value IS a NULL)
					-- IND_INSERT_ONLY is used when we don't want to amend changed rows, i.e. we want to force the
					-- user to explain any changes we detect. This is a pretty horrible mechanism - i.e. these
					-- are really two separate jobs and should be split into separate stored procedures I think
					out_val_id := -r_update.val_id; 
					-- return without updating
					RETURN;
				END IF;
            
				-- what is IND_OVERRIDE_LOCKS for?
				--IF bitand(in_update_flags, Indicator_Pkg.IND_OVERRIDE_LOCKS) > 0
				IF bitand(in_update_flags, 4) = 0 THEN
            
					IF v_is_changed_value THEN
						-- unhook any linked value (import / delegation etc)
						SELECT helper_pkg 
						  INTO v_helper_pkg 
						  FROM csr.source_type
						 WHERE source_type_id = r_update.source_type_id;
                     
						IF v_helper_pkg IS NOT NULL THEN
							-- call helper_pkg to unhook any val_id pointers they keep 
							EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.OnValChange(:1,:2);end;'
								USING r_update.val_id, r_update.source_id;
						END IF;
					END IF;
                
					UPDATE csr.val
					   SET val_number = v_rounded_in_val_number, 
						   flags = in_flags,
						   source_id = in_source_id, 
						   source_type_id = in_source_type_id,
						   entry_measure_conversion_id = in_entry_conversion_id,
						   entry_val_number = v_entry_val_number, 
						   note = in_note,
						   error_code = in_error_code,
						   changed_by_sid = in_user_sid,
						   changed_dtm = SYSDATE
					 WHERE CURRENT OF c_update;
				END IF; 
    
				CLOSE c_update;
		END;

		IF (v_is_changed_value OR v_is_new_value OR v_is_changed_detail) AND in_source_type_id NOT IN (5,6) THEN
			INSERT INTO csr.val_change (
				val_change_id, reason, changed_by_sid, changed_dtm, source_type_id,
				val_number, ind_sid, region_sid, period_start_dtm, period_end_dtm,
				entry_val_number, entry_measure_conversion_id, note, source_id
			) VALUES (
				csr.val_change_id_seq.NEXTVAL, in_reason, in_user_sid, SYSDATE, in_source_type_id,
				v_rounded_in_val_number, in_ind_sid, in_region_sid, in_period_start, in_period_end,
				v_entry_val_number, in_entry_conversion_id, null, in_source_id
			);
		END IF;

		-- splodge files in
		IF in_have_file_uploads = 1 THEN
			IF v_file_uploads IS NULL THEN -- we might have done this above
				v_file_uploads := security.security_pkg.SidArrayToTable(in_file_uploads);
			END IF;

			DELETE FROM csr.val_file
			 WHERE val_id = out_val_id
			   AND file_upload_sid NOT IN (
		   			SELECT column_value
		   			  FROM TABLE(v_file_uploads));
	
			INSERT INTO csr.val_file (val_id, file_upload_sid)
				SELECT out_val_id, column_value
				  FROM TABLE(v_file_uploads)
				 MINUS
				SELECT out_val_id, file_upload_sid
				  FROM csr.val_file
				 WHERE val_id = out_val_id;
		END IF;
	
		-- add some recalc jobs for formulae which depend on this indicator or region if changed
		-- XXX: we only really need to add jobs for note only changes for scrag++
		-- there's no good way of doing that at present though so recomputing old style
		-- scenarios and merged data on note changes too
		IF v_is_changed_value OR v_is_changed_note THEN
			IF bitand(in_update_flags, 1) = 0 OR
			   bitand(in_update_flags, 2) = 0 THEN
				MERGE /*+ALL_ROWS*/ INTO csr.val_change_log vcl
				USING (SELECT date '1990-01-01' period_start_dtm, date '2021-01-01' period_end_dtm
		  				 FROM dual) r
				   ON (vcl.ind_sid = in_ind_sid)
				 WHEN MATCHED THEN
					UPDATE 
					   SET vcl.start_dtm = LEAST(vcl.start_dtm, r.period_start_dtm),
						   vcl.end_dtm = GREATEST(vcl.end_dtm, r.period_end_dtm)
				 WHEN NOT MATCHED THEN
					INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
					VALUES (in_ind_sid, r.period_start_dtm, r.period_end_dtm);
			END IF;		
			
		END IF;
	
		out_val_id := NVL(out_val_id, -1); -- we can't return nulls in an output parameter via ADO :(
	END;

	FUNCTION UNSEC_GetBaseValue(
		in_val_number				IN	csr.val.entry_val_number%TYPE,
		in_conversion_id			IN	csr.measure_conversion.measure_conversion_id%TYPE,
		in_dtm						IN	DATE
	) RETURN csr.val.val_number%TYPE
	AS
		v_val csr.val.val_number%TYPE;
	BEGIN
		IF NVL(in_conversion_Id,-1) = -1 THEN 
			RETURN in_val_number;
		END IF;
	
		BEGIN
			SELECT NVL(NVL(mc.a, mcp.a), 1) * POWER(in_val_number, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0) 	
			  INTO v_val
			  FROM csr.measure_conversion mc, csr.measure_conversion_period mcp
			 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
			   AND in_conversion_id = mc.measure_conversion_id(+)
			   AND (in_dtm >= mcp.start_dtm or mcp.start_dtm is null)
			   AND (in_dtm < mcp.end_dtm or mcp.end_dtm is null);     
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- we throw an exception -> change to some kind of recognised type?
				RAISE_APPLICATION_ERROR(-20352, 'Conversion factor not found for Id '||in_conversion_id||' for date '||in_dtm);
		END;
	
		RETURN v_val;
	END; 

	PROCEDURE INTERNAL_UpsertVal(
		in_region_sid			IN	security.security_pkg.T_SID_ID,
		in_ind_sid				IN	security.security_pkg.T_SID_ID,
		in_start_dtm			IN	csr.region_metric_val.effective_dtm%TYPE,
		in_end_dtm				IN	csr.region_metric_val.effective_dtm%TYPE,
		in_conv_id				IN	csr.measure_conversion.measure_conversion_id%TYPE,
		in_val					IN	csr.val.val_number%TYPE,
		in_note					IN	csr.val.note%TYPE,
		in_source_type_id		IN	csr.val.source_type_id%TYPE
	)
	AS
		v_val_id				csr.val.val_id%TYPE;
		v_file_uploads			security.security_pkg.T_SID_IDS; -- empty
	BEGIN	
		-- Call SetValue as it's more robust than inserting directly into val
		-- SetValueWithReasonWithSid doesn't check security -- this mirrors the previous
		-- behaviour. We ought to do the security check in region_metric_pkg somewhere.
		SetValueWithReasonWithSid(
			in_user_sid				=> security.security_pkg.GetSid,
			in_ind_sid				=> in_ind_sid,
			in_region_sid			=> in_region_sid,
			in_period_start			=> in_start_dtm,
			in_period_end			=> in_end_dtm,
			in_val_number			=> UNSEC_GetBaseValue(in_val, in_conv_id, in_start_dtm),
			in_flags				=> 0,
			in_source_type_id		=> NVL(in_source_type_id, 14),
			in_entry_conversion_id	=> in_conv_id,
			in_entry_val_number		=> in_val,
			in_note					=> in_note,
			in_reason				=> 'Region metric',
			in_have_file_uploads	=> 0,
			in_file_uploads			=> v_file_uploads,
			out_val_id				=> v_val_id
		);
	END;

	FUNCTION NormaliseToPeriodSpan(
		in_cur					IN	SYS_REFCURSOR,
		in_start_dtm 			IN	DATE,
		in_end_dtm				IN	DATE,
		in_interval_duration	IN	NUMBER DEFAULT 1,
		in_divisibility			IN	NUMBER DEFAULT 1
	) RETURN T_NORMALISED_VAL_TABLE
	AS
		-- processed data
		v_tbl						T_NORMALISED_VAL_TABLE := T_NORMALISED_VAL_TABLE();
		-- rowset values
		v_row_region_sid            security.security_pkg.T_SID_ID;
		v_row_start_dtm 	        DATE;
		v_row_end_dtm		        DATE;
		v_row_val                   NUMBER(24,10);
		-- value collation
		v_collate_val               NUMBER(24,10);
		v_collate_val_duration      NUMBER(24,10);
		v_collate_region_sid        security.security_pkg.T_SID_ID;
		v_collate_start_dtm         DATE;
		v_collate_end_dtm           DATE;
		-- interim stuff
		v_chunk_duration            NUMBER(10);
		v_chunk_start_dtm           DATE;
		v_chunk_end_dtm             DATE;
		v_current_end_dtm           DATE;
	BEGIN
		v_collate_start_dtm := in_start_dtm;
		FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;
		IF in_cur%NOTFOUND THEN
			RETURN v_tbl;
		END IF;
		IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
		END IF;	
		-- DBMS_OUTPUT.PUT_LINE('FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
		--
		<<each_region>>
		WHILE in_cur%FOUND
		LOOP
			v_collate_region_sid := v_row_region_sid;
			-- DBMS_OUTPUT.PUT_LINE('region_sid '||v_collate_region_sid);
			v_collate_start_dtm := in_start_dtm;
			<<each_period>>
			WHILE v_collate_start_dtm < in_end_dtm
			LOOP
				v_collate_end_dtm := ADD_MONTHS(v_collate_start_dtm, in_interval_duration);
				-- DBMS_OUTPUT.PUT_LINE('  period '||v_collate_start_dtm||' -> '||v_collate_end_dtm);
				-- for each period in the period span
				-- eat irrelevant historic data in the data reader
				WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_end_dtm <= v_collate_start_dtm
				LOOP
					FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;			
					IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
						RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
					END IF;	
					-- DBMS_OUTPUT.PUT_LINE('  FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
				END LOOP;

				-- ASSUMPTION: data ends after our seek period start
				v_collate_val := null;
				v_collate_val_duration := 0;
            
				-- collate data for period from cursor
				<<collate_period>>
				WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_start_dtm < v_collate_end_dtm
				LOOP
					-- crop date off either side of our period
					v_chunk_start_dtm := GREATEST(v_collate_start_dtm, v_row_start_dtm);
					v_chunk_end_dtm := LEAST(v_collate_end_dtm, v_row_end_dtm);
					-- DBMS_OUTPUT.PUT_LINE('    chunk '||v_chunk_start_dtm||' -> '||v_chunk_end_dtm);
					-- get duration in days
					v_chunk_duration := v_chunk_end_dtm - v_chunk_start_dtm;
					CASE in_divisibility
						WHEN 1 THEN
							-- if divisble, then get a proportional value for this period
							-- DBMS_OUTPUT.PUT_LINE('          v_collate_val = '||v_collate_val);
							-- DBMS_OUTPUT.PUT_LINE('          v_row_val = '||v_row_val);	
							-- DBMS_OUTPUT.PUT_LINE('          v_chunk_duration = '||v_chunk_duration);
							-- DBMS_OUTPUT.PUT_LINE('          v_row_duration = '||(v_row_end_dtm - v_row_start_dtm));
							v_collate_val := NVL(v_collate_val, 0) + v_row_val * v_chunk_duration / (v_row_end_dtm - v_row_start_dtm);
							-- DBMS_OUTPUT.PUT_LINE('    val = '||v_collate_val);
						WHEN 2 THEN
							-- we want to use the last value for the period
							-- e.g. Q1, Q2, Q3, Q4 << we take Q4 value
							v_collate_val := v_row_val;
						WHEN 0 THEN
							-- if not divisible, then average this out over differing periods for val
							IF v_collate_val_duration + v_chunk_duration = 0 THEN
								v_collate_val := 0; -- avoid division by 0
							ELSE
								v_collate_val := (NVL(v_collate_val,0) * v_collate_val_duration + v_row_val * v_chunk_duration) / (v_collate_val_duration + v_chunk_duration);
							END IF;
							v_collate_val_duration := v_collate_val_duration + v_chunk_duration;                    
					END CASE;
                
					-- what next? store this value away...?
					-- DBMS_OUTPUT.PUT_LINE('    check: '||v_collate_end_dtm||' <= '||v_row_end_dtm);
					EXIT collate_period WHEN v_collate_end_dtm <= v_row_end_dtm;
                
					-- DBMS_OUTPUT.PUT_LINE('    fetch more...');
					-- or keep getting more data to build up the new value?
                
					/* get some more data, but swallow anything which starts before the end of the
					   last data we shoved into our overall value for this period.
					   e.g.
					   J  F  M  A  M  J  J  A  (seek period is Jan -> end June)
					   |--------|        |     (used)
					   |     |-----|     |     (discarded) << or throw exception?
					   |        |--------|--|  (used - both parts)
					   |              |--|     (discarded) << or throw exception?
					*/
					-- eat_intermediate_data
					v_current_end_dtm := v_row_end_dtm; 
					WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid AND v_row_start_dtm < v_current_end_dtm
					LOOP
						FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val;			
						IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
							RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
						END IF;	
						-- DBMS_OUTPUT.PUT_LINE('    FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
					END LOOP;

				END LOOP;
		
				-- store
				-- DBMS_OUTPUT.PUT_LINE('    '||v_collate_start_dtm||' -> '||v_collate_end_dtm||' ['||v_collate_region_sid||'] = '||v_collate_val);
				v_tbl.extend;
				v_tbl(v_tbl.COUNT) := T_NORMALISED_VAL_ROW(
					v_collate_region_sid, v_collate_start_dtm, v_collate_end_dtm, v_collate_val);	

				-- DBMS_OUTPUT.PUT_LINE('    fetched all for period, moving to next period, starting '||v_collate_end_dtm);
            
				-- next period
				v_collate_start_dtm := v_collate_end_dtm;            
			END LOOP;
        
			-- DBMS_OUTPUT.PUT_LINE('  periods processed. skip to next region...');
			-- skip to start of next region (if not already at start)
			WHILE in_cur%FOUND AND v_row_region_sid = v_collate_region_sid
			LOOP
				FETCH in_cur INTO v_row_region_sid, v_row_start_dtm, v_row_end_dtm, v_row_val; -- try next row								
				IF v_row_start_dtm >= v_row_end_dtm OR v_row_start_dtm IS NULL OR v_row_end_dtm IS NULL OR v_row_region_sid IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001, 'Invalid input value with region = '||v_row_region_sid||', start_dtm = '||v_row_start_dtm||', end_dtm = '||v_row_end_dtm||', val = '||v_row_val);
				END IF;	
				-- DBMS_OUTPUT.PUT_LINE('  FETCHED region '||v_row_region_sid||', '||v_row_start_dtm||' -> '||v_row_end_dtm||' = '||v_row_val);
			END LOOP;        
			-- DBMS_OUTPUT.PUT_LINE('  now processing region_sid '||v_row_region_sid);
		END LOOP;
	
		-- DBMS_OUTPUT.PUT_LINE('done');
		RETURN v_tbl;
	END;	

	PROCEDURE SetSystemValues(
		in_region_sid			IN	security.security_pkg.T_SID_ID,
		in_ind_sid				IN	security.security_pkg.T_SID_ID,
		in_start_dtm			IN	csr.region_metric_val.effective_dtm%TYPE,
		in_end_dtm				IN	csr.region_metric_val.effective_dtm%TYPE
	)
	AS
		v_cur						SYS_REFCURSOR;
		v_months_tbl 				T_NORMALISED_VAL_TABLE;
		v_measure_conversion_id		csr.measure_conversion.measure_conversion_id%TYPE;
		v_divisibility				NUMBER(1);
		v_cust_field				csr.measure.custom_field%TYPE;
		v_min_month					DATE;
		v_max_month					DATE;
		v_source_type_id			csr.region_metric_region.source_type_id%TYPE;
	BEGIN
		-- Get the metric's mreasure conversion	
		SELECT measure_conversion_id
		  INTO v_measure_conversion_id
		  FROM csr.region_metric_region
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid;
	
		-- Get the measure's custom field
		SELECT custom_field
		  INTO v_cust_field
		  FROM csr.measure m, csr.ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = in_ind_sid
		   AND m.measure_sid = i.measure_sid;
	
		-- Get the source type
		SELECT source_type_id
		  INTO v_source_type_id
		  FROM csr.region_metric_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND ind_sid = in_ind_sid;
		
		-- Delete anything overlapping the affected period	
		DELETE FROM csr.imp_val iv
		WHERE EXISTS (SELECT NULL 
						FROM csr.VAL
					   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 AND region_sid = in_region_sid
						 AND ind_sid = in_ind_sid
						 AND period_start_dtm < TRUNC(in_end_dtm, 'MONTH')
						 AND period_end_dtm > TRUNC(in_start_dtm, 'MONTH')
						 AND source_type_id IN (
							v_source_type_id,
							14
						)
						 AND val_id = iv.SET_VAL_ID);
					 
		DELETE FROM csr.val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND ind_sid = in_ind_sid
		   AND period_start_dtm < TRUNC(in_end_dtm, 'MONTH')
		   AND period_end_dtm > TRUNC(in_start_dtm, 'MONTH')
		   AND source_type_id IN (
	   			v_source_type_id,
	   			14
	   		);
	
		-- Pre select a set of region metric values that have an effective date no sooner than 
		-- CALC_START but ensuring the any latest value beofre CALC start is still inserted into the main system
		DELETE FROM csr.temp_region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid
		   AND ind_sid = in_ind_sid;
	   
		INSERT INTO csr.temp_region_metric_val (app_sid, region_sid, ind_sid, effective_dtm, val, note)
			-- Take latest entry with effective_dtm <= CALC_START and simulate an entry on CALC_START with that value
	  		SELECT r1.app_sid, r1.region_sid, r1.ind_sid, date '1990-01-01' effective_dtm, r1.val, r1.note
			  FROM csr.region_metric_val r1
				LEFT JOIN csr.region_metric_val r2
				  ON (r2.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				  AND r1.ind_sid = r2.ind_sid
				  AND r1.region_sid = r2.region_sid
				  AND r2.effective_dtm <= date '1990-01-01'
				  AND r1.effective_dtm < r2.effective_dtm
			   )
			 WHERE r1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r1.region_sid = in_region_sid
			   AND r1.ind_sid = in_ind_sid
			   AND r1.effective_dtm <= date '1990-01-01'
			   AND r2.region_sid IS NULL
			   AND r2.ind_sid IS NULL
			UNION
			-- get everything else > CALC_START
			SELECT r1.app_sid, r1.region_sid, r1.ind_sid, r1.effective_dtm, r1.val, r1.note
			  FROM csr.region_metric_val r1
			 WHERE r1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r1.region_sid = in_region_sid
			   AND r1.ind_sid = in_ind_sid
			   AND r1.effective_dtm > date '1990-01-01' 
		;
	
		v_min_month := TRUNC(in_start_dtm, 'MONTH');
		v_max_month := ADD_MONTHS(TRUNC(in_end_dtm, 'MONTH'), 1);
	
		-- Get the value data
		OPEN v_cur FOR
			SELECT *
			  FROM (
				SELECT 
					region_sid,
					LEAST(effective_dtm, date '2021-01-01') start_dtm,
					LEAST(NVL(LEAD(effective_dtm) OVER (ORDER BY effective_dtm), date '2021-01-01'), date '2021-01-01') end_dtm, -- Clamp the end dtm
					val val_number
				  FROM csr.temp_region_metric_val
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid
				   AND ind_sid = in_ind_sid
			) WHERE start_dtm < end_dtm
				ORDER BY start_dtm;
	
		-- Normalise the value data, we're interested in the weighted averages for the intersecting
		-- months unless the measure specifies a custom field in which case use last period...
		v_divisibility := 0;
		IF v_cust_field IS NOT NULL THEN
			v_divisibility := 2;
		END IF;
	
		v_months_tbl := NormaliseToPeriodSpan(v_cur, v_min_month, v_max_month, 1, v_divisibility);
	
		-- ...pick out the intersecting bits we want and insert them into the val table	
		FOR r IN (
			SELECT v.effective_dtm, v.region_sid, v.start_dtm, v.val_number,
				DECODE(v.ongoing_val, NULL, v.ongoing_end_dtm, v.nv_end_dtm) end_dtm,
				v.ongoing_val, note, v.ongoing_end_dtm, r.source_type_id
			  FROM (
				SELECT rmv.effective_dtm, nv.region_sid, nv.start_dtm, nv.val_number, nv.end_dtm nv_end_dtm, 
					NVL(TRUNC(LEAD(rmv.effective_dtm) OVER (ORDER BY rmv.effective_dtm), 'MONTH'), date '2021-01-01') ongoing_end_dtm,
					DECODE(nv.start_dtm, rmv.effective_dtm, NULL, rmv.val) ongoing_val, rmv.note
				  FROM csr.temp_region_metric_val rmv, TABLE(v_months_tbl) nv
				 WHERE rmv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND rmv.region_sid = in_region_sid
				   AND rmv.ind_sid = in_ind_sid
				   AND rmv.effective_dtm >= in_start_dtm
				   AND rmv.effective_dtm <= date '2021-01-01' -- need to select values for 'lead'
				   AND nv.start_dtm(+) = TRUNC(rmv.effective_dtm, 'MONTH')
			  ) v, csr.region_metric_region r
			 WHERE r.region_sid = v.region_sid
			   AND start_dtm <> ongoing_end_dtm
			 		ORDER BY effective_dtm
		) LOOP
			-- Bail out once we get to the end of the date span
			EXIT WHEN r.start_dtm > TRUNC(in_end_dtm, 'MONTH');
		
			-- Insert the weighted average values and then insert full values in between
			INTERNAL_UpsertVal(in_region_sid, in_ind_sid, r.start_dtm, r.end_dtm, v_measure_conversion_id, r.val_number, r.note, r.source_type_id);
			IF r.ongoing_val IS NOT NULL AND r.end_dtm <> r.ongoing_end_dtm THEN
				INTERNAL_UpsertVal(in_region_sid, in_ind_sid, r.end_dtm, r.ongoing_end_dtm, v_measure_conversion_id, r.ongoing_val, r.note, r.source_type_id);
				v_max_month := GREATEST(v_max_month, r.ongoing_end_dtm);
			END IF;
		
		END LOOP;
	
		MERGE /*+ALL_ROWS*/ INTO csr.val_change_log vcl
		USING (SELECT date '1990-01-01' period_start_dtm, date '2021-01-01' period_end_dtm
		  			FROM dual) r
			ON (vcl.ind_sid = in_ind_sid)
			WHEN MATCHED THEN
			UPDATE 
				SET vcl.start_dtm = LEAST(vcl.start_dtm, r.period_start_dtm),
					vcl.end_dtm = GREATEST(vcl.end_dtm, r.period_end_dtm)
			WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (in_ind_sid, r.period_start_dtm, r.period_end_dtm);

	END;

	PROCEDURE LockApp(
		in_lock_type					IN	csr.app_lock.lock_type%TYPE,
		in_app_sid						IN	csr.app_lock.app_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'APP')
	)
	AS
	BEGIN
		UPDATE csr.app_lock
		   SET dummy = 1
		 WHERE lock_type = in_lock_type
		   AND app_sid = in_app_sid;
	 
		IF SQL%ROWCOUNT != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Unknown lock type: '||in_lock_type||' for app_sid:'||in_app_sid);
		END IF;
	END;

	-- Try and find the property sid
	FUNCTION INTERNAL_GetPropertySid(
		in_region_sid				IN	security.security_pkg.T_SID_ID
	)
	RETURN security.security_pkg.T_SID_ID
	AS
		v_property_sid  security.security_pkg.T_SID_ID;
	BEGIN
		WITH pro AS (               
			 SELECT region_sid, region_type
			   FROM csr.region 
			  WHERE CONNECT_BY_ISLEAF = 1
			  START WITH region_sid = in_region_sid
			CONNECT BY PRIOR parent_sid = region_sid
				AND PRIOR region_type != 3
		 )
		SELECT CASE 
				WHEN pro.region_type != 2 THEN pro.region_sid 
				ELSE pr.region_sid -- just use parent
			   END property_sid
		  INTO v_property_sid
		  FROM pro, csr.region r
			JOIN csr.region pr ON pr.region_sid = r.parent_sid
		 WHERE r.region_sid = in_region_sid;
    
		RETURN v_property_sid;
	END;

	PROCEDURE OnRegionMetricChange(
		in_region_sid				IN	security.security_pkg.T_SID_ID,
		in_region_metric_val_id		IN	csr.region_metric_val.region_metric_val_id%TYPE
	)
	AS
		v_count						NUMBER;
		v_prop_sid					security.security_pkg.T_SID_ID;
		v_est_account_sid			security.security_pkg.T_SID_ID;
		v_pm_customer_id			csr.est_building.pm_customer_id%TYPE;
		v_pm_building_id			csr.est_building.pm_building_id%TYPE;
		v_pm_space_id				csr.est_space.pm_space_id%TYPE;
		v_pm_val_id					csr.est_space_attr.pm_val_id%TYPE;
	BEGIN
	
		-- Check the associated property is set-up for energy_star_push
		BEGIN
			v_prop_sid := INTERNAL_GetPropertySid(in_region_sid);
			SELECT region_sid
			  INTO v_prop_sid
			  FROM csr.property
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = v_prop_sid
			   AND energy_star_sync = 1
			   AND energy_star_push != 0;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN; -- Associated region not part of an energy star property doing push
		END;

		-- If the region metric value that changed is tied to a read-only building metric then we don't want to create a push job
		-- (this happens when we pull read-only building metrics for properties set to push).
		SELECT COUNT(*)
		  INTO v_count
		  FROM csr.region_metric_val v
		  JOIN csr.est_building_metric_mapping map ON map.app_sid = v.app_sid AND map.ind_sid = v.ind_sid
		 WHERE v.region_metric_val_id = in_region_metric_val_id
		   AND map.simulated = 0
		   AND map.read_only = 1;

		IF v_count > 0 THEN
			RETURN;
		END IF;
	
		-- Lock the app when we fiddle with the change log table
		LockApp(
			in_lock_type => 3,
			in_app_sid => security.security_pkg.GetAPP
		);
	
		BEGIN
			SELECT sa.pm_val_id
			  INTO v_pm_val_id
			  FROM csr.region_metric_val v
			  LEFT JOIN csr.est_space_attr sa ON v.app_sid = sa.app_sid AND v.region_metric_val_id = sa.region_metric_val_id
			 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND v.region_metric_val_id = in_region_metric_val_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pm_val_id := NULL;
		END;
	
		-- If it's a building then add to the building change log
		FOR r IN (
			SELECT est_account_sid, pm_customer_id, pm_building_id
			  FROM csr.est_building
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
		) LOOP
			BEGIN
				INSERT INTO csr.est_building_change_log (est_account_sid, pm_customer_id, pm_building_id)
				VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore dupes
			END;
		END LOOP;
	
		-- If it's a space then add to attribute change log
		FOR r IN (
			SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id
			  FROM csr.est_space
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid
		) LOOP
			BEGIN
				INSERT INTO csr.est_space_attr_change_log (est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_metric_val_id, pm_val_id)
				VALUES(r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_space_id, in_region_metric_val_id, v_pm_val_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore dupes
			END;
		END LOOP;
	END;


	PROCEDURE DeleteMetricValue(
		in_region_metric_val_id	IN 	csr.region_metric_val.region_metric_val_id%TYPE
	)
	AS
		v_ind_sid					csr.region_metric_val.ind_sid%TYPE;
		v_region_sid				csr.region_metric_val.region_sid%TYPE;
		v_effective_dtm				csr.region_metric_val.effective_dtm%TYPE;
		v_min_dtm					DATE;
		v_max_dtm					DATE;
	BEGIN
		SELECT ind_sid, region_sid, effective_dtm
		  INTO v_ind_sid, v_region_sid, v_effective_dtm
		  FROM csr.region_metric_val
		 WHERE region_metric_val_id = in_region_metric_val_id;
	
		IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.GetACT, v_region_sid, security.security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied on region with sid '||v_region_sid);
		END IF;
	
		-- Create energy star jobs if required
		OnRegionMetricChange(v_region_sid, in_region_metric_val_id);
	
		-- Remove any reference held by a space attribute
		UPDATE csr.est_space_attr
		   SET region_metric_val_id = NULL
		 WHERE region_metric_val_id = in_region_metric_val_id;
	
		-- Have to update imp_val before deleting region_metric_val
		UPDATE csr.imp_val
		   SET set_region_metric_val_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND set_region_metric_val_id = in_region_metric_val_id;
	
		DELETE FROM csr.region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_metric_val_id = in_region_metric_val_id;
	
		-- Determine min dtm (previous value or old value if none exists)
		SELECT NVL(MAX(effective_dtm), v_effective_dtm)
		  INTO v_min_dtm
		  FROM csr.region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_region_sid
		   AND ind_sid = v_ind_sid
		   AND effective_dtm < v_effective_dtm;
	
		-- Determine max dtm (next value or calc end)
		SELECT NVL(MIN(effective_dtm), date '2021-01-01')
		  INTO v_max_dtm
		  FROM csr.region_metric_val
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_region_sid
		   AND ind_sid = v_ind_sid
		   AND effective_dtm > v_effective_dtm;
	
		-- Update the val table
		SetSystemValues(
			v_region_sid,
			v_ind_sid,
			v_min_dtm,
			v_max_dtm
		);
	END;

BEGIN
	FOR x IN 
		(SELECT distinct c.host, c.app_sid 
		   FROM csr.region_metric_val  v
		   JOIN csr.ind i ON i.ind_sid=v.ind_sid AND i.app_sid = v.app_sid
		   JOIN csr.measure m ON m.measure_sid = i.measure_sid AND i.app_sid = m.app_sid
		   JOIN csr.customer c ON v.app_sid = c.app_sid
		  WHERE v.val = 0 AND m.custom_field = '$')
	LOOP
		security.user_pkg.logonAdmin(x.host);
		FOR y IN 
			(SELECT * 
			   FROM csr.region_metric_val  v
			   JOIN csr.ind i ON i.ind_sid=v.ind_sid AND i.app_sid = v.app_sid
			   JOIN csr.measure m ON m.measure_sid = i.measure_sid AND i.app_sid = m.app_sid
			  WHERE v.val = 0 AND m.custom_field = '$' AND v.app_sid = x.app_sid)
		LOOP
			DeleteMetricValue(y.region_metric_val_id);
		END LOOP;
	END LOOP;
	security.user_pkg.logonAdmin();
END;
/

DROP TYPE T_NORMALISED_VAL_TABLE;
DROP TYPE T_NORMALISED_VAL_ROW;

BEGIN
	FOR r IN (
		SELECT c.host, m.sid_id 
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE lower(action) like '%portlets.acds%'
			OR lower(action) like '%sitelanguages.acds%'
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');	
		BEGIN				
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, r.sid_id, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(r.sid_id));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(r.sid_id), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		END;
		
		security.user_pkg.logoff(security.security_pkg.GetAct);
		
	END LOOP;
END;
/

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (64, 'Property dashboards', 'EnablePropertyDashboards', 'Enables the Property Benchmarking and Performance dashboards');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

UPDATE csr.benchmark_dashboard SET name = 'Benchmarking' WHERE lookup_key = 'DEFAULT_BENCHMARKING_DASHBOARD';
UPDATE csr.metric_dashboard SET name = 'Performance' WHERE lookup_key = 'DEFAULT_METRIC_DASHBOARD';

UPDATE chain.filter_value 
   SET filter_type = 1 -- chain.FILTER_VALUE_TYPE_NUMBER
 WHERE num_value IS NOT NULL
   AND num_value >= 0
   AND max_num_val IS NULL
   AND min_num_val IS NULL;

UPDATE chain.filter_value 
   SET filter_type = 2 -- chain.FILTER_VALUE_TYPE_NUMBER_RANGE
 WHERE num_value IS NOT NULL
   AND num_value >= 0 
   AND max_num_val IS NOT NULL OR min_num_val IS NOT NULL;

UPDATE chain.filter_value 
   SET filter_type = 3 -- chain.FILTER_VALUE_TYPE_STRING
 WHERE str_value IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 4 -- chain.FILTER_VALUE_TYPE_USER
 WHERE user_sid IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 5 -- chain.FILTER_VALUE_TYPE_REGION
 WHERE region_sid IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 6 -- chain.FILTER_VALUE_TYPE_DATE_RANGE
 WHERE (num_value IS NOT NULL AND num_value < 0)
	OR start_period_id IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 7 -- chain.FILTER_VALUE_TYPE_SAVED
 WHERE saved_filter_sid_value IS NOT NULL;

UPDATE chain.filter_value
   SET filter_type = 8 -- chain.FILTER_VALUE_TYPE_COMPOUND
 WHERE compound_filter_id_value IS NOT NULL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/filter_pkg

@../benchmarking_dashboard_pkg
@../enable_pkg
@../property_pkg
@../schema_pkg

@../chain/company_type_pkg;
@../chain/filter_pkg

@../csrimp/imp_pkg

@../../../aspen2/cms/db/filter_body

@../benchmarking_dashboard_body
@../enable_body
@../indicator_body
@../meter_body
@../property_body
@../property_report_body
@../schema_body
@../tag_body

@../chain/company_filter_body
@../chain/company_type_body;
@../chain/filter_body
@../chain/supplier_flow_body

@../csrimp/imp_body


@update_tail
