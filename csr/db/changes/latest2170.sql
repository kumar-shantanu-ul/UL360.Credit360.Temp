define version=2170
@update_header


alter table CHAIN.QUESTIONNAIRE_TYPE add procurer_can_review number(1, 0) null;
update CHAIN.QUESTIONNAIRE_TYPE set procurer_can_review=0;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE MODIFY procurer_can_review DEFAULT 0;
	 
@../chain/questionnaire_body
	
@update_tail