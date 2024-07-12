-- Please update version.sql too -- this keeps clean builds in sync
define version=1808
@update_header

--multi step process required on 11g
ALTER TABLE chain.questionnaire_type ADD ENABLE_AUTO_APPROVE NUMBER(1,0);
UPDATE chain.questionnaire_type SET ENABLE_AUTO_APPROVE = 0;
ALTER TABLE chain.questionnaire_type MODIFY ENABLE_AUTO_APPROVE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE chain.questionnaire_type ADD CHECK (ENABLE_AUTO_APPROVE IN (0, 1));

@../chain/questionnaire_body
 
@update_tail