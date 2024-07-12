-- Please update version.sql too -- this keeps clean builds in sync
define version=2085
@update_header

-- WARNING: THIS SCRIPT WILL INVALIDATE THE UNIVERSE
-- WARNING: ALL SERVICES NEED TO BE STOPPED BEFORE APPLYING THIS SCRIPT (i.e. scrag on the app servers)

ALTER TABLE csr.customer ADD (
	ALLOW_MULTIPERIOD_FORMS		NUMBER(1,0) DEFAULT 0 NOT NULL
	CONSTRAINT CHK_ALLOW_MULTIPERIOD_FRM CHECK (ALLOW_MULTIPERIOD_FORMS IN (0,1))
);

@..\delegation_pkg

@..\csr_app_body
@..\delegation_body

@update_tail
