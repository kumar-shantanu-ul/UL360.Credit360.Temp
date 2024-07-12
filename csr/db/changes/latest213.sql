-- Please update version.sql too -- this keeps clean builds in sync
define version=213
@update_header

grant select, update, references on csr_user to donations;
 

ALTER TABLE csr_user ADD (DONATIONS_BROWSE_FILTER_ID NUMBER(10));
ALTER TABLE csr_user ADD (DONATIONS_REPORTS_FILTER_ID NUMBER(10));
	

@update_tail