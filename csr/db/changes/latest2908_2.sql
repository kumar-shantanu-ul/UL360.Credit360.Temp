-- Please update version.sql too -- this keeps clean builds in sync
define version=2908
define minor_version=2
@update_header

-- BEGIN
-- this bit is intentionally above the Create tables section, so that the combine script doesn't include it.
-- it was added because a change script was merged without the rest of the branch and run on the DB CI kit and it screwed it up
-- if this section fails then just take it out as you probably haven't run the minor which cocked everything up.

DECLARE
	PROCEDURE RunAndIgnoreErrors(in_sql IN VARCHAR2)
	AS
	BEGIN
		EXECUTE IMMEDIATE in_sql;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
BEGIN
	RunAndIgnoreErrors('DROP SEQUENCE csr.audit_non_compliance_id_seq');
	RunAndIgnoreErrors('DROP TABLE csrimp.map_audit_non_compliance');

	RunAndIgnoreErrors('ALTER TABLE csr.audit_non_compliance DROP CONSTRAINT fk_anc_repeat_anc');
	RunAndIgnoreErrors('ALTER TABLE csr.audit_non_compliance DROP PRIMARY KEY DROP INDEX');
	RunAndIgnoreErrors('ALTER TABLE csr.audit_non_compliance DROP (audit_non_compliance_id, repeat_of_audit_nc_id)');

	RunAndIgnoreErrors('ALTER TABLE csr.audit_non_compliance ADD CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(app_sid, internal_audit_sid, non_compliance_id)');

	RunAndIgnoreErrors('ALTER TABLE csrimp.audit_non_compliance DROP (audit_non_compliance_id, repeat_of_audit_nc_id)');

	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP CONSTRAINT ck_nct_mtch_rpt_by_crry_fwd');
	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP CONSTRAINT ck_nct_mtch_rpt_by_dflt_ncs');
	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP CONSTRAINT ck_nct_mtch_rpt_by_surveys');
	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP CONSTRAINT ck_nct_find_rpt_in');
	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP CONSTRAINT ck_nct_crry_fwd_rpt_type');

	RunAndIgnoreErrors('ALTER TABLE csr.non_compliance_type DROP (match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys, find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type)');

	RunAndIgnoreErrors('ALTER TABLE csrimp.non_compliance_type DROP (match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys, find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type)');
END;
/

-- END of the cocked section

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

UPDATE csr.audit_non_compliance
   SET audit_non_compliance_id = csr.audit_non_compliance_id_seq.NEXTVAL
 WHERE audit_non_compliance_id IS NULL;

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

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csrimp.audit_non_compliance DROP PRIMARY KEY DROP INDEX';
EXCEPTION
	WHEN OTHERS THEN
		IF (SQLCODE = -2441) THEN
			-- Cannot drop nonexistent primary key = fine
			NULL;
		ELSE
			RAISE;
		END IF;
END;
/

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
		   AND c.app_sid NOT IN (34625403, 27888577) -- Skip Gap's sites - they have lots of NCs and need the settings changed anyway
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
			SELECT anc.audit_non_compliance_id, ia.audit_dtm, ia.region_sid,
				   nc.non_compliance_id, nc.from_non_comp_default_id,
				   nc.question_id, ncea.qs_expr_non_compl_action_id expr_action_id
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nc
			    ON nc.non_compliance_id = anc.non_compliance_id
			   AND nc.app_sid = anc.app_sid
			   AND nc.created_in_audit_sid = anc.internal_audit_sid
			  JOIN csr.internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
			  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
			  LEFT JOIN csr.non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id
			 WHERE anc.app_sid = s.app_sid
			   AND nc.non_compliance_type_id = s.non_compliance_type_id
		) LOOP
			BEGIN
				WITH eligible_audits AS (
					SELECT internal_audit_sid, audit_dtm, region_sid
					  FROM (
						SELECT internal_audit_sid, audit_dtm, region_sid
						  FROM csr.internal_audit ia
						 WHERE ia.audit_dtm < r.audit_dtm
						   AND ia.deleted = 0
						   AND ia.region_sid = r.region_sid
					  )
				)
				SELECT audit_non_compliance_id
				  INTO v_repeat_of_audit_nc_id
				  FROM (
					SELECT audit_non_compliance_id, ROWNUM rn
					  FROM (
						SELECT anc.audit_non_compliance_id
						  FROM csr.audit_non_compliance anc
						  JOIN eligible_audits ia ON ia.internal_audit_sid = anc.internal_audit_sid
						  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
						  LEFT JOIN csr.non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id AND nc.app_sid = ncea.app_sid
						 WHERE (
								(nc.from_non_comp_default_id = r.from_non_comp_default_id) OR
								((nc.question_id = r.question_id OR ncea.qs_expr_non_compl_action_id = r.expr_action_id))
						   )
						 ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC
					  )
				  ) WHERE rn = 1;
				  
				UPDATE csr.audit_non_compliance
				   SET repeat_of_audit_nc_id = v_repeat_of_audit_nc_id
				 WHERE audit_non_compliance_id = r.audit_non_compliance_id;
 
			EXCEPTION
				WHEN no_data_found THEN
					NULL;
			END;	
			
		END LOOP;
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/

-- back up NC IDs
CREATE TABLE chain.fb87238_saved_filter_sent_alrt AS
	SELECT sa.*
	  FROM chain.saved_filter_sent_alert sa
	 WHERE saved_filter_sid IN (
		SELECT saved_filter_sid
		  FROM chain.saved_filter
		 WHERE card_group_id = 42
	);

-- remove NC IDs
DELETE FROM chain.saved_filter_sent_alert sa
 WHERE saved_filter_sid IN (
	SELECT saved_filter_sid
	  FROM chain.saved_filter
	 WHERE card_group_id = 42
);

-- insert ANC IDs
INSERT INTO chain.saved_filter_sent_alert (app_sid, saved_filter_sid, user_sid, sent_dtm, object_id)
SELECT sa.app_sid, sa.saved_filter_sid, sa.user_sid, sa.sent_dtm, anc.audit_non_compliance_id
  FROM chain.fb87238_saved_filter_sent_alrt sa
  JOIN csr.audit_non_compliance anc
    ON sa.app_sid = anc.app_sid
   AND sa.object_id = anc.non_compliance_id;

-- Leave this table on live in case something goes wrong, otherwise we can't reverse/undo the change.
--DROP TABLE TABLE chain.fb87238_saved_filter_sent_alrt;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg

@../audit_body
@../audit_report_body
@../non_compliance_report_body
@../issue_report_body

@update_tail
