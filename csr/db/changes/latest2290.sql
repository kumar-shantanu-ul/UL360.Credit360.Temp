-- Please update version.sql too -- this keeps clean builds in sync
define version=2290
@update_header

ALTER TABLE csrimp.quick_survey_response ADD HIDDEN	NUMBER(1);
UPDATE csrimp.quick_survey_response
   SET hidden = 0;
ALTER TABLE csrimp.quick_survey_response MODIFY HIDDEN NOT NULL;
ALTER TABLE csrimp.quick_survey_response ADD CONSTRAINT chk_qs_response_hidden_0_1 CHECK (hidden IN (0,1));

@..\schema_body
@..\csrimp\imp_body

@update_tail
