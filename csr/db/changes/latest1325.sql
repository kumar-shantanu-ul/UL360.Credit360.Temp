-- Please update version.sql too -- this keeps clean builds in sync
define version=1325
@update_header
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

ALTER TABLE CSR.ROLE ADD (
	IS_USER_CREATOR		NUMBER(1) DEFAULT 0 NOT NULL 
);

ALTER TABLE CSR.ROLE ADD CONSTRAINT CHK_ROLE_IS_USRCR CHECK (IS_USER_CREATOR IN (0, 1)) ENABLE;

@..\csr_user_pkg
@..\csr_user_body

@update_tail
