-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=5
@update_header

ALTER TABLE csr.role ADD IS_TRAINING_ROLE NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.role ADD CONSTRAINT CHK_ROLE_IS_TRAIN CHECK (IS_TRAINING_ROLE IN (0,1));

ALTER TABLE csr.function_course DROP CONSTRAINT FK_FUNCTION_COURSE_FUNCTION;
ALTER TABLE csr.function_course ADD CONSTRAINT FK_FUNCTION_COURSE_FUNCTION FOREIGN KEY (APP_SID, FUNCTION_ID) REFERENCES CSR.ROLE(APP_SID, ROLE_SID) ON DELETE CASCADE; 

CREATE OR REPLACE VIEW csr.v$function AS
SELECT app_sid, role_sid function_id, NAME label, lookup_key FROM csr.role WHERE is_training_role = 1;

CREATE OR REPLACE VIEW csr.v$user_function AS 
SELECT DISTINCT app_sid, user_sid csr_user_sid, role_sid function_id FROM csr.region_role_member;

@..\csr_user_pkg
@..\csr_user_body
@..\training_pkg
@..\training_body

@update_tail