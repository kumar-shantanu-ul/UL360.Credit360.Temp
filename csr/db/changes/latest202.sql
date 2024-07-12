-- Please update version.sql too -- this keeps clean builds in sync
define version=202
@update_header

alter table customer add approver_response_window NUMBER(10,0) DEFAULT 3 NOT NULL; 

@update_tail
