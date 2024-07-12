-- Please update version.sql too -- this keeps clean builds in sync
define version=2901
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.audit_non_compliance_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE TABLE csrimp.map_audit_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	new_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_audit_non_compliance primary key (csrimp_session_id, old_audit_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_audit_non_compliance unique (csrimp_session_id, new_audit_non_compliance_id) USING INDEX,
    CONSTRAINT fk_map_audit_non_compliance_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.audit_non_compliance ADD (
	audit_non_compliance_id				NUMBER(10, 0),
	repeat_of_audit_nc_id				NUMBER(10, 0)
);

UPDATE csr.audit_non_compliance SET audit_non_compliance_id = csr.audit_non_compliance_id_seq.NEXTVAL;

ALTER TABLE csr.audit_non_compliance MODIFY (
	audit_non_compliance_id				NOT NULL
);

ALTER TABLE csr.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
CREATE UNIQUE INDEX csr.ix_audit_non_compliance ON csr.audit_non_compliance (app_sid, internal_audit_sid, non_compliance_id);

ALTER TABLE csr.audit_non_compliance ADD (
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(app_sid, audit_non_compliance_id),
	CONSTRAINT fk_anc_repeat_anc		FOREIGN KEY (app_sid, repeat_of_audit_nc_id)
		REFERENCES csr.audit_non_compliance (app_sid, audit_non_compliance_id)
);

TRUNCATE TABLE csrimp.audit_non_compliance;
ALTER TABLE csrimp.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csrimp.audit_non_compliance ADD (
	audit_non_compliance_id				NUMBER(10, 0) NOT NULL,
	repeat_of_audit_nc_id				NUMBER(10, 0),
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(csrimp_session_id, audit_non_compliance_id)
);

ALTER TABLE csr.non_compliance_type ADD (
	match_repeats_by_carry_fwd			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	match_repeats_by_default_ncs		NUMBER(1, 0) DEFAULT 0 NOT NULL,
	match_repeats_by_surveys			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	find_repeats_in_unit				VARCHAR2(10) DEFAULT 'none' NOT NULL,
	find_repeats_in_qty					NUMBER(10, 0),
	carry_fwd_repeat_type				VARCHAR2(10) DEFAULT 'normal' NOT NULL,
	CONSTRAINT ck_nct_mtch_rpt_by_crry_fwd CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_mtch_rpt_by_dflt_ncs CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_mtch_rpt_by_surveys CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_find_rpt_in CHECK ((find_repeats_in_unit IN ('all', 'none') AND find_repeats_in_qty IS NULL) OR
										 (find_repeats_in_unit IN ('audits', 'months', 'years') AND find_repeats_in_qty > 0)),
	CONSTRAINT ck_nct_crry_fwd_rpt_type CHECK (carry_fwd_repeat_type IN ('normal', 'as_created', 'never'))
);

ALTER TABLE csrimp.non_compliance_type ADD (
	match_repeats_by_carry_fwd			NUMBER(1, 0),
	match_repeats_by_default_ncs		NUMBER(1, 0),
	match_repeats_by_surveys			NUMBER(1, 0),
	find_repeats_in_unit				VARCHAR2(10),
	find_repeats_in_qty					NUMBER(10, 0),
	carry_fwd_repeat_type				VARCHAR2(10)
);

-- *** Grants ***
grant select on csr.audit_non_compliance_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE PACKAGE csr.latest_xxx_pkg AS

NCT_RPT_MATCH_UNIT_NONE			CONSTANT VARCHAR2(10) := 'none';
NCT_RPT_MATCH_UNIT_ALL			CONSTANT VARCHAR2(10) := 'all';
NCT_RPT_MATCH_UNIT_AUDITS		CONSTANT VARCHAR2(10) := 'audits';
NCT_RPT_MATCH_UNIT_MONTHS		CONSTANT VARCHAR2(10) := 'months';
NCT_RPT_MATCH_UNIT_YEARS		CONSTANT VARCHAR2(10) := 'years';

NCT_CARRY_FWD_RPT_TYPE_NORMAL	CONSTANT VARCHAR2(10) := 'normal';
NCT_CARRY_FWD_RPT_TYPE_AS_CRTD	CONSTANT VARCHAR2(10) := 'as_created';
NCT_CARRY_FWD_RPT_TYPE_NEVER	CONSTANT VARCHAR2(10) := 'never';

PROCEDURE GetRepeatAuditNC(
	in_audit_non_compliance_id	IN	audit_non_compliance.audit_non_compliance_id%TYPE,
	out_audit_non_compliance_id	OUT	audit_non_compliance.audit_non_compliance_id%TYPE
);

END;
/

CREATE OR REPLACE PACKAGE BODY csr.latest_xxx_pkg AS

PROCEDURE GetRepeatAuditNC(
	in_audit_non_compliance_id	IN	audit_non_compliance.audit_non_compliance_id%TYPE,
	out_audit_non_compliance_id	OUT	audit_non_compliance.audit_non_compliance_id%TYPE
)
AS
	v_audit_non_compliance_id		audit_non_compliance.audit_non_compliance_id%TYPE := in_audit_non_compliance_id;
	v_carried_from_audit_nc_id		audit_non_compliance.audit_non_compliance_id%TYPE;

	v_audit_dtm						internal_audit.audit_dtm%TYPE;
	v_region_sid					security_pkg.T_SID_ID;
	v_non_compliance_id				non_compliance.non_compliance_id%TYPE;
	v_from_non_comp_default_id		non_compliance.from_non_comp_default_id%TYPE;
	v_question_id					non_compliance.question_id%TYPE;
	v_expr_action_id				non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE;

	CURSOR v_cfg_cur IS
		SELECT match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
				find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type
			FROM non_compliance_type nct
			JOIN non_compliance nc ON nc.non_compliance_type_id = nct.non_compliance_type_id
			JOIN audit_non_compliance anc ON anc.non_compliance_id = nc.non_compliance_id
			WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;

	v_cfg v_cfg_cur%ROWTYPE;
BEGIN
	-- get the config from the non-compliance
	OPEN v_cfg_cur;
	FETCH v_cfg_cur INTO v_cfg;
	IF v_cfg_cur%NOTFOUND OR v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_NONE THEN
		out_audit_non_compliance_id := NULL;
		RETURN;
	END IF;

	-- find the original audit NC, if it's still there
	BEGIN
		SELECT cianc.audit_non_compliance_id
		  INTO v_carried_from_audit_nc_id
		  FROM audit_non_compliance anc
		  JOIN audit_non_compliance cianc ON cianc.non_compliance_id = anc.non_compliance_id
		  JOIN non_compliance nc ON nc.non_compliance_id = cianc.non_compliance_id
								AND nc.created_in_audit_sid = cianc.internal_audit_sid
		 WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;
	EXCEPTION
		WHEN no_data_found THEN
			v_carried_from_audit_nc_id := in_audit_non_compliance_id;
	END;

	-- if this is a carried-forward audit, find out what to do.
	IF v_audit_non_compliance_id != v_carried_from_audit_nc_id THEN
		IF v_cfg.carry_fwd_repeat_type = 'as_created' THEN
			v_audit_non_compliance_id := v_carried_from_audit_nc_id;
		ELSIF v_cfg.carry_fwd_repeat_type = 'never' THEN
			out_audit_non_compliance_id := NULL;
			RETURN;
		END IF;
	END IF;

	BEGIN
		-- get the things we could match against
		SELECT ia.audit_dtm, NVL(nc.region_sid, ia.region_sid),
			   nc.non_compliance_id, nc.from_non_comp_default_id, nc.question_id, 
			   ncea.qs_expr_non_compl_action_id
		  INTO v_audit_dtm, v_region_sid,
			   v_non_compliance_id, v_from_non_comp_default_id, v_question_id,
			   v_expr_action_id
	      FROM audit_non_compliance anc
		  JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id
		 WHERE anc.audit_non_compliance_id = v_audit_non_compliance_id;
		
		WITH eligible_audits AS (
			SELECT internal_audit_sid, audit_dtm, region_sid
			  FROM (
				SELECT internal_audit_sid, audit_dtm, region_sid,
					   CASE WHEN v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS THEN
							ROW_NUMBER() OVER (PARTITION BY region_sid ORDER BY audit_dtm DESC, internal_audit_sid DESC) 
					   END audit_number
				  FROM internal_audit ia
				 WHERE ia.audit_dtm < v_audit_dtm
				   AND ia.deleted = 0
			  ) ia WHERE (
					v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_ALL OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS AND ia.audit_number <= v_cfg.find_repeats_in_qty) OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_MONTHS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -1 * v_cfg.find_repeats_in_qty)) OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_YEARS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -12 * v_cfg.find_repeats_in_qty))
			   )
		)
		SELECT audit_non_compliance_id
		  INTO out_audit_non_compliance_id
		  FROM (
			SELECT audit_non_compliance_id, ROWNUM rn
			  FROM (
				SELECT anc.audit_non_compliance_id
				  FROM audit_non_compliance anc
				  JOIN eligible_audits ia ON ia.internal_audit_sid = anc.internal_audit_sid
				  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
				  LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id AND nc.app_sid = ncea.app_sid
				 WHERE NVL(nc.region_sid, ia.region_sid) = v_region_sid
				   AND (
						(v_cfg.match_repeats_by_carry_fwd = 1 AND nc.non_compliance_id = v_non_compliance_id) OR
						(v_cfg.match_repeats_by_default_ncs = 1 AND nc.from_non_comp_default_id = v_from_non_comp_default_id) OR
						(v_cfg.match_repeats_by_surveys = 1 AND (nc.question_id = v_question_id OR ncea.qs_expr_non_compl_action_id = v_expr_action_id))
				   )
				 ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC
			  )
		  ) WHERE rn = 1;
	EXCEPTION
		WHEN no_data_found THEN
			out_audit_non_compliance_id := NULL;
	END;
END;

END;
/

DECLARE
	v_repeat_of_audit_nc_id		NUMBER(10, 0);
BEGIN
	-- we only care about repeats because of repeat score so we only
	-- look at customers who have scores for repeats
	FOR s IN (
		SELECT c.app_sid, c.host, nct.non_compliance_type_id
		  FROM csr.customer c
		  JOIN csr.non_compliance_type nct ON nct.app_sid = c.app_sid
		 WHERE nct.repeat_score IS NOT NULL
		   AND c.app_sid NOT IN (34625403, 27888577)
	) LOOP
		security.user_pkg.logonadmin(s.host);

		-- these are the closest settings to what's already live.
		UPDATE csr.non_compliance_type
		   SET match_repeats_by_default_ncs = 1,
			   match_repeats_by_surveys = 1,
			   find_repeats_in_unit = 'all',
			   carry_fwd_repeat_type = 'as_created'
		 WHERE non_compliance_type_id = s.non_compliance_type_id;

		FOR r IN (
			SELECT anc.audit_non_compliance_id
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
			 WHERE anc.app_sid = s.app_sid
			   AND nc.non_compliance_type_id = s.non_compliance_type_id
		) LOOP

			csr.latest_xxx_pkg.GetRepeatAuditNC(
				r.audit_non_compliance_id,
				v_repeat_of_audit_nc_id
			);
			
			UPDATE csr.audit_non_compliance
			   SET repeat_of_audit_nc_id = v_repeat_of_audit_nc_id
			 WHERE audit_non_compliance_id = r.audit_non_compliance_id;
		END LOOP;
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg

@../audit_body
@../audit_report_body
@../non_compliance_report_body
@../issue_report_body

@update_tail
