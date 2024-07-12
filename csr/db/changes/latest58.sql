-- Please update version.sql too -- this keeps clean builds in sync
define version=58
@update_header

ALTER TABLE CUSTOMER ADD (RAISE_REMINDERS NUMBER(1) DEFAULT (0) NOT NULL);

commit;
/

@update_tail
