--Please update version.sql too -- this keeps clean builds in sync
define version=2699
@update_header

ALTER TABLE CSRIMP.QS_CAMPAIGN
ADD campaign_end_dtm DATE NULL;

@..\schema_body
@..\csrimp\imp_body

@update_tail