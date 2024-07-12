-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.internal_audit_score (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	internal_audit_sid				NUMBER(10, 0) NOT NULL,
	score_type_id					NUMBER(10, 0) NOT NULL,
    score							NUMBER(15, 5),
    score_threshold_id				NUMBER(10, 0),
	CONSTRAINT pk_internal_audit_score PRIMARY KEY (app_sid, internal_audit_sid, score_type_id),
	CONSTRAINT fk_internal_audit_score_ia FOREIGN KEY (app_sid, internal_audit_sid) REFERENCES csr.internal_audit (app_sid, internal_audit_sid),
	CONSTRAINT fk_internal_audit_score_st FOREIGN KEY (app_sid, score_type_id) REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_internal_audit_score_sth FOREIGN KEY (app_sid, score_threshold_id) REFERENCES csr.score_threshold (app_sid, score_threshold_id)
);

CREATE INDEX csr.ix_internal_audit_score_ia ON csr.internal_audit_score (app_sid, internal_audit_sid);
CREATE INDEX csr.ix_internal_audit_score_st ON csr.internal_audit_score (app_sid, score_type_id);
CREATE INDEX csr.ix_internal_audit_score_sth ON csr.internal_audit_score (app_sid, score_threshold_id);

CREATE TABLE CSRIMP.INTERNAL_AUDIT_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_SID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE NUMBER(15,5),
	SCORE_THRESHOLD_ID NUMBER(10,0),
	CONSTRAINT PK_INTERNAL_AUDIT_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, SCORE_TYPE_ID),
	CONSTRAINT FK_INTERNAL_AUDIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.score_type ADD (
	applies_to_audits				NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT ck_score_type_app_to_aud_1_0 CHECK (applies_to_audits IN (0, 1)),
	CONSTRAINT ck_score_type_not_aud_and_nc	CHECK (applies_to_audits = 0 OR applies_to_non_compliances = 0)
);

ALTER TABLE csrimp.score_type ADD (
	applies_to_audits				NUMBER(1, 0) NOT NULL,
    CONSTRAINT ck_score_type_app_to_aud_1_0 CHECK (applies_to_audits IN (0, 1)),
	CONSTRAINT ck_score_type_not_aud_and_nc	CHECK (applies_to_audits = 0 OR applies_to_non_compliances = 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	UPDATE chain.filter_page_column SET column_name = 'ncScore' WHERE column_name = 'auditScore';

	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
		 SELECT app_sid, flow_sid, 'csr.audit_helper_pkg.ApplyAuditScoresToSupplier', 'Apply audit scores to supplier'
		   FROM csr.flow f
	      WHERE f.flow_alert_class = 'audit'
		    AND NOT EXISTS (
				SELECT NULL
				  FROM csr.flow_state_trans_helper
				 WHERE app_sid = f.app_sid
				   AND flow_sid = f.flow_sid
				   AND helper_sp = 'csr.audit_helper_pkg.ApplyAuditScoresToSupplier'
		    );
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../audit_helper_pkg
@../audit_report_pkg
@../quick_survey_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../audit_body
@../audit_helper_body
@../audit_report_body
@../quick_survey_body
@../schema_body
@../csrimp/imp_body

@update_tail
