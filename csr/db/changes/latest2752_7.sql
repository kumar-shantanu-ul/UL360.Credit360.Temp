-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=7
@update_header

-- THIS SCRIPT IS TO REVERT OUT 2752.5 CHANGES

ALTER TABLE csr.role DROP CONSTRAINT CHK_ROLE_IS_TRAIN;
ALTER TABLE csr.role DROP COLUMN IS_TRAINING_ROLE;

ALTER TABLE csr.function_course DROP CONSTRAINT FK_FUNCTION_COURSE_FUNCTION;
ALTER TABLE csr.function_course ADD CONSTRAINT FK_FUNCTION_COURSE_FUNCTION FOREIGN KEY (APP_SID, FUNCTION_ID) REFERENCES CSR.FUNCTION(APP_SID, FUNCTION_ID) ON DELETE CASCADE; 

DROP VIEW csr.v$function;
DROP VIEW csr.v$user_function;

@..\csr_user_pkg
@..\csr_user_body
@..\training_pkg
@..\training_body

@update_tail