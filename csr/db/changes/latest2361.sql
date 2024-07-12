-- Please update version.sql too -- this keeps clean builds in sync
define version=2361
@update_header

alter table csr.section_flow add DFLT_RET_AFT_INC_USR_SUBMIT NUMBER(1) DEFAULT 0 NOT NULL;

@../section_body

@update_tail
