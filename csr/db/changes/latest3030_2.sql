-- Please update version.sql too -- this keeps clean builds in sync
define version=3030
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DECLARE
	v_newest_st	NUMBER(10);
BEGIN
	FOR r IN (SELECT app_sid FROM csr.compliance_options)
	LOOP
		SELECT MAX(quick_survey_type_id)
		  INTO v_newest_st
		  FROM csr.compliance_options
		 WHERE app_sid = r.app_sid;
		IF (v_newest_st IS NOT NULL) THEN 
			DELETE FROM csr.compliance_options
			 WHERE quick_survey_type_id != v_newest_st
			   AND app_sid = r.app_sid;
			   
			DELETE FROM csr.quick_survey_type
			 WHERE quick_survey_type_id != v_newest_st
			   AND app_sid = r.app_sid
			   AND cs_class = 'Credit360.QuickSurvey.ComplianceSurveyType';
		 END IF;
	END LOOP;
END;
/

ALTER TABLE csr.compliance_options 
  ADD CONSTRAINT pk_compliance_options PRIMARY KEY (app_sid);

CREATE TABLE csr.compliance_region_tag( 
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAG_ID			    NUMBER(10, 0)    NOT NULL,
    REGION_SID			NUMBER(10, 0)	 NOT NULL,
	CONSTRAINT PK_COMP_REGION_TAG PRIMARY KEY (APP_SID, TAG_ID, REGION_SID)
);

ALTER TABLE csr.compliance_region_tag ADD CONSTRAINT FK_COMP_REGION_TAG_TAG
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE csr.compliance_region_tag ADD CONSTRAINT FK_COMP_REGION_TAG_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

CREATE TABLE csrimp.compliance_region_tag( 
	CSRIMP_SESSION_ID	NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAG_ID				NUMBER(10, 0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_comp_region_tag PRIMARY KEY (csrimp_session_id, TAG_ID, REGION_SID),
	CONSTRAINT fk_comp_region_tag_is
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

CREATE INDEX csr.ix_comp_reg_tag_region_sid ON csr.compliance_region_tag (app_sid, region_sid);
CREATE INDEX csr.ix_comp_reg_tag_tag_id ON csr.compliance_region_tag (app_sid, tag_id);
  
-- *** Grants ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_region_tag TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../schema_pkg
@../tag_pkg

@../compliance_body
@../csr_app_body
@../enable_body
@../region_body
@../schema_body
@../tag_body

@../csrimp/imp_body

@update_tail
