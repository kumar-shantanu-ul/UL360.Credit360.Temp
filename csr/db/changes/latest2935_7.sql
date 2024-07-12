-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.like_for_like_slot (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid  				NUMBER(10, 0) NOT NULL,
	include_inactive_regions	NUMBER(1, 0) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	period_end_dtm				DATE NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					NUMBER(1, 0) NOT NULL,
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0),
	created_dtm 				DATE,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	is_locked					NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_LIKE_FOR_LIKE 		PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_SLOT_IND_SID 		FOREIGN KEY	(APP_SID, IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID),
	CONSTRAINT FK_L4L_SLOT_REGION_SID 	FOREIGN KEY	(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT FK_L4L_SLOT_SCENARIO_RUN	FOREIGN KEY	(APP_SID, SCENARIO_RUN_SID) REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID),
	CONSTRAINT FK_L4L_SLOT_CREATED_BY 	FOREIGN KEY	(APP_SID, CREATED_BY_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_SLOT_REFRESHED_BY FOREIGN KEY	(APP_SID, LAST_REFRESH_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_SLOT_PERIOD_INT 	FOREIGN KEY	(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID) REFERENCES CSR.PERIOD_INTERVAL(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID),
	CONSTRAINT CK_L4L_RULE_TYPE			CHECK 		(RULE_TYPE IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_INACT_REG	CHECK 		(INCLUDE_INACTIVE_REGIONS IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_LOCKED		CHECK 		(IS_LOCKED IN (0, 1))
);


CREATE TABLE csr.like_for_like_email_sub (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	csr_user_sid		NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_L4L_EMAIL		 		PRIMARY KEY	(APP_SID, LIKE_FOR_LIKE_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_EMAIL_L4L_SID 	FOREIGN KEY	(APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_EMAIL_USER_SID	FOREIGN KEY	(APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
);

CREATE TABLE csr.batch_job_like_for_like (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	batch_job_id		NUMBER(10, 0) NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_BATCH_JOB_L4L PRIMARY KEY (APP_SID, LIKE_FOR_LIKE_SID, BATCH_JOB_ID),
	CONSTRAINT FK_BATCH_JOB_L4L_LIKE_SID FOREIGN KEY (APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_BATCH_JOB_L4L_JOB_ID FOREIGN KEY (APP_SID, BATCH_JOB_ID) REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
);

CREATE TABLE csr.like_for_like_excluded_regions (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	like_for_like_sid	NUMBER(10, 0) NOT NULL,
	region_sid			NUMBER(10, 0) NOT NULL,
	period_start_dtm	DATE,
	period_end_dtm		DATE,
	CONSTRAINT PK_L4L_EXCLUDED_REGIONS PRIMARY KEY (APP_SID, LIKE_FOR_LIKE_SID, REGION_SID, PERIOD_START_DTM, PERIOD_END_DTM),
	CONSTRAINT FK_L4L_EXCLUDED_REG_LIKE_SID FOREIGN KEY (APP_SID, LIKE_FOR_LIKE_SID) REFERENCES CSR.LIKE_FOR_LIKE_SLOT(APP_SID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_L4L_EXCLUDED_REG_REGION_SID FOREIGN KEY (APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT CK_L4L_EXCLUDED_REG_DATES CHECK (PERIOD_END_DTM > PERIOD_START_DTM)
);

CREATE TABLE csrimp.like_for_like_slot (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	like_for_like_sid			NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid  				NUMBER(10, 0) NOT NULL,
	include_inactive_regions	NUMBER(1, 0) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	period_end_dtm				DATE NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					NUMBER(1, 0) NOT NULL,
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0),
	created_dtm 				DATE,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	is_locked					NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_LIKE_FOR_LIKE 		PRIMARY KEY	(CSRIMP_SESSION_ID, LIKE_FOR_LIKE_SID),
	CONSTRAINT FK_LIKE_FOR_LIKE_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE,
	CONSTRAINT CK_L4L_RULE_TYPE			CHECK 		(RULE_TYPE IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_INACT_REG	CHECK 		(INCLUDE_INACTIVE_REGIONS IN (0, 1)),
	CONSTRAINT CK_L4L_INCL_LOCKED		CHECK 		(IS_LOCKED IN (0, 1))
);

CREATE TABLE csrimp.like_for_like_email_sub (
	csrimp_session_id		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	like_for_like_sid		NUMBER(10, 0) NOT NULL,
	csr_user_sid			NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_L4L_EMAIL		 		PRIMARY KEY	(CSRIMP_SESSION_ID, LIKE_FOR_LIKE_SID, CSR_USER_SID),
	CONSTRAINT FK_L4L_EMAIL_SESSION 	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.customer
ADD like_for_like_slots NUMBER(10) DEFAULT 0 NOT NULL;

ALTER TABLE csr.scenario_run
ADD last_success_dtm DATE;

ALTER TABLE csr.scenario_run
ADD on_completion_sp VARCHAR2(255);

ALTER TABLE csrimp.customer
ADD like_for_like_slots NUMBER(10) DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.scenario_run
ADD last_success_dtm DATE;

ALTER TABLE csrimp.scenario_run
ADD on_completion_sp VARCHAR2(255);

-- *** Grants ***

grant select, insert, update on csr.like_for_like_slot to csrimp;
grant select, insert, update on csr.like_for_like_email_sub to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
	VALUES (25, 'Like for like region recalc', NULL, 'like-for-like', 1, NULL);

-- RLS

-- Data
DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRLikeForLike', 'csr.like_for_like_pkg', null, v_id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/

-- ** New package grants **
-- Create dummy packages for the grant
create or replace package csr.like_for_like_pkg as
	procedure dummy;
end;
/
create or replace package body csr.like_for_like_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.like_for_like_pkg to security;
grant execute on csr.like_for_like_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\batch_job_pkg
@..\like_for_like_pkg
@..\like_for_like_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body

@update_tail