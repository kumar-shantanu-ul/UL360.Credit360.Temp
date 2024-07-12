-- Please update version.sql too -- this keeps clean builds in sync
define version=317
@update_header

alter table customer add (FULLY_HIDE_SHEETS NUMBER(1) DEFAULT 0 NOT NULL);

@update_tail
