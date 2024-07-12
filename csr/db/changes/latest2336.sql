-- Please update version.sql too -- this keeps clean builds in sync
define version=2336
@update_header

DROP VIEW CHAIN.v$questionnaire_share_debug;

-- renamed from tt_questionnaire_organizer so that we can alter the table without worrying about open connection issues
CREATE GLOBAL TEMPORARY TABLE CHAIN.tt_qnr_organizer
( 
	QUESTIONNAIRE_ID			NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_ID		NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_NAME	VARCHAR2(200) NOT NULL,
	STATUS_UPDATE_DTM			TIMESTAMP(6),
	DUE_BY_DTM					DATE,
	POSITION					NUMBER,
	NAME						VARCHAR2(200) NOT NULL,
	COMPONENT_DESCRIPTION		VARCHAR2(200) 
) 
ON COMMIT PRESERVE ROWS; 

@..\chain\questionnaire_body

@update_tail
