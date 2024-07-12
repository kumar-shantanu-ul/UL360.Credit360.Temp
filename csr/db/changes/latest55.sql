-- Please update version.sql too -- this keeps clean builds in sync
define version=55
@update_header

alter table customer add (message clob);

ALTER TABLE CUSTOMER MODIFY (RAISE_REMINDERS NUMBER(1) DEFAULT (0));

@update_tail
