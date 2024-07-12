-- Please update version.sql too -- this keeps clean builds in sync
define version=2255
@update_header

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE RENAME COLUMN ALLOW_AUTO_APPROVE TO XX_ALLOW_AUTO_APPROVE;
ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE RENAME COLUMN ENABLE_AUTO_APPROVE TO XX_ENABLE_AUTO_APPROVE;

BEGIN
	UPDATE chain.questionnaire_type
	   SET requires_review = 1
	 WHERE xx_enable_auto_approve = 0
	   AND requires_review = 0;
END;
/

@../chain/questionnaire_body

@update_tail
