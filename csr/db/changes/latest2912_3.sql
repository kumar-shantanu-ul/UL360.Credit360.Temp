-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.region_score_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE csr.region_score_log (
	app_sid			   				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_score_log_id	 			NUMBER(10, 0)	NOT NULL,
	region_sid		 				NUMBER(10, 0)	NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	score_threshold_id				NUMBER(10, 0),
	score							NUMBER(15, 5),
	set_dtm							DATE			DEFAULT SYSDATE NOT NULL,
	changed_by_user_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	comment_text					CLOB,
	CONSTRAINT pk_region_score_log PRIMARY KEY (app_sid, region_score_log_id),
	CONSTRAINT fk_region_score_log_type FOREIGN KEY (app_sid, score_type_id) 
		REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_region_score_log_user FOREIGN KEY (app_sid, changed_by_user_sid) 
		REFERENCES csr.csr_user (app_sid, csr_user_sid),
	CONSTRAINT fk_region_score_log_region FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_region_score_log_thresh_id FOREIGN KEY (app_sid, score_threshold_id)
		REFERENCES csr.score_threshold (app_sid, score_threshold_id)
);


CREATE TABLE csr.region_score (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	last_region_score_log_id 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_region_score PRIMARY KEY (app_sid, score_type_id, region_sid),
	CONSTRAINT fk_region_score_score_type FOREIGN KEY (app_sid, score_type_id) 
		REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_region_score_region FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_region_score_last_score FOREIGN KEY (app_sid, last_region_score_log_id) 
		REFERENCES csr.region_score_log (app_sid, region_score_log_id)
);

CREATE INDEX csr.ix_region_score_last_region_s ON csr.region_score (app_sid, last_region_score_log_id);
CREATE INDEX csr.ix_region_score_region_sid ON csr.region_score (app_sid, region_sid);
CREATE INDEX csr.ix_region_score_changed_by_us ON csr.region_score_log (app_sid, changed_by_user_sid);
CREATE INDEX csr.ix_region_score_score_type_id ON csr.region_score_log (app_sid, score_type_id);
CREATE INDEX csr.ix_region_score_score_thresho ON csr.region_score_log (app_sid, score_threshold_id);
CREATE INDEX csr.ix_region_score_log_region_sid ON csr.region_score_log (app_sid, region_sid);

CREATE TABLE csrimp.region_score_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_score_log_id	 			NUMBER(10, 0)	NOT NULL,
	region_sid		 				NUMBER(10, 0)	NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	score_threshold_id				NUMBER(10, 0),
	score							NUMBER(15, 5),
	set_dtm							DATE			DEFAULT SYSDATE NOT NULL,
	changed_by_user_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	comment_text					CLOB,
	CONSTRAINT pk_region_score_log PRIMARY KEY (csrimp_session_id, region_score_log_id),
	CONSTRAINT fk_region_score_log_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE csrimp.region_score (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	last_region_score_log_id 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_region_score PRIMARY KEY (csrimp_session_id, score_type_id, region_sid),
	CONSTRAINT fk_region_score_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_region_score_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_region_score_log_id 		NUMBER(10)	NOT NULL,
	new_region_score_log_id 		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_region_score PRIMARY KEY (csrimp_session_id, old_region_score_log_id) USING INDEX,
	CONSTRAINT uk_map_region_score UNIQUE (csrimp_session_id, new_region_score_log_id) USING INDEX,
    CONSTRAINT fk_map_region_score_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.score_type ADD (
	applies_to_regions				NUMBER(1) DEFAULT 0 NOT NULL,	
	CONSTRAINT ck_score_type_app_to_reg_1_0 CHECK (applies_to_regions in (0, 1))	
);

ALTER TABLE csrimp.score_type ADD (
	applies_to_regions				NUMBER(1)
);

UPDATE csrimp.score_type SET applies_to_regions = 0;
ALTER TABLE csrimp.score_type MODIFY applies_to_regions NOT NULL;
ALTER TABLE csrimp.score_type ADD CONSTRAINT ck_score_type_app_to_reg_1_0 CHECK (applies_to_regions in (0, 1));

-- *** Grants ***
grant select on csr.region_score_log_id_seq to csrimp;
grant insert on csr.region_score to csrimp;
grant insert on csr.region_score_log to csrimp;
grant select,insert,update,delete on csrimp.region_score to web_user;
grant select,insert,update,delete on csrimp.region_score_log to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- Default applies to regions to on for any campaign surveys with scoring enabled
UPDATE csr.score_type
   SET applies_to_regions = 1
 WHERE (app_sid, score_type_id) IN (
	SELECT qs.app_sid, qs.score_type_id
	  FROM csr.quick_survey qs
	  JOIN csr.qs_campaign qsc ON qs.app_sid = qsc.app_sid AND qs.survey_sid = qsc.survey_sid
	 WHERE qs.score_type_id IS NOT NULL
);

DECLARE 
	v_region_score_id	NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;

	-- get the last score for a region that is linked to a campaign survey that has been submitted for each score type
	FOR r IN (		     
		SELECT app_sid, region_sid, score_type_id, score_threshold_id, overall_score, submitted_dtm, submitted_by_user_sid
		  FROM (
			SELECT rsr.app_sid, rsr.region_sid, qs.score_type_id, qss.score_threshold_id, qss.overall_score, qss.submitted_dtm, qss.submitted_by_user_sid,
				   ROW_NUMBER() OVER (PARTITION BY rsr.app_sid, rsr.region_sid, qs.score_type_id ORDER BY qss.submitted_dtm DESC) rn
			  FROM csr.region_survey_response rsr
			  JOIN csr.quick_survey_response sr ON rsr.app_sid = sr.app_sid AND rsr.survey_response_id = sr.survey_response_id AND rsr.survey_sid = sr.survey_sid
			  JOIN csr.quick_survey_submission qss ON sr.app_sid = qss.app_sid
			   AND sr.survey_response_id = qss.survey_response_id
			   AND NVL(sr.last_submission_id, 0) = qss.submission_id
			   AND sr.survey_version > 0 -- filter out draft submissions
			   AND sr.hidden = 0 -- filter out hidden responses
			  JOIN csr.quick_survey qs ON sr.app_sid = qs.app_sid AND sr.survey_sid = qs.survey_sid      
			  JOIN csr.qs_campaign qsc ON qs.app_sid = qsc.app_sid AND qs.survey_sid = qsc.survey_sid
			 WHERE (qss.overall_score IS NOT NULL OR qss.score_threshold_id IS NOT NULL)
			   AND qs.score_type_id IS NOT NULL   
			   AND qss.submitted_dtm IS NOT NULL
		  ) 
		 WHERE rn = 1
	) LOOP
		INSERT INTO csr.region_score_log (app_sid, region_score_log_id, region_sid,	score_type_id, score_threshold_id, score, set_dtm, changed_by_user_sid)
		     VALUES (r.app_sid, csr.region_score_log_id_seq.NEXTVAL, r.region_sid, r.score_type_id, r.score_threshold_id, r.overall_score, r.submitted_dtm, r.submitted_by_user_sid)
		  RETURNING region_score_log_id INTO v_region_score_id;
		  
		BEGIN
			INSERT INTO csr.region_score (app_sid, score_type_id, region_sid, last_region_score_log_id)
				 VALUES (r.app_sid, r.score_type_id, r.region_sid, v_region_score_id);	
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE csr.region_score
				   SET last_region_score_log_id = v_region_score_id
				 WHERE app_sid = r.app_sid
				   AND score_type_id = r.score_type_id
				   AND region_sid = r.region_sid;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../quick_survey_pkg
@../property_report_pkg

@../schema_body
@../quick_survey_body
@../property_report_body
@../chain/filter_body
@../csrimp/imp_body
@../csr_app_body

@update_tail
