-- Please update version.sql too -- this keeps clean builds in sync
define version=2376
@update_header

/* in case it had not been dropped */
BEGIN
	FOR r IN (
		SELECT owner, object_name
		  FROM all_objects
		 WHERE owner = 'CHAIN' 
		   AND object_name = 'TT_QUESTIONNAIRE_ORGANIZER'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP TABLE chain.' || r.object_name;
	END LOOP;
END;
/

-- renamed from tt_qnr_organizer so that we can alter the table without worrying about open connection issues
CREATE GLOBAL TEMPORARY TABLE CHAIN.tt_questionnaire_organizer
( 
	QUESTIONNAIRE_ID			NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_ID		NUMBER(10) NOT NULL,
	QUESTIONNAIRE_STATUS_NAME	VARCHAR2(200) NOT NULL,
	STATUS_UPDATE_DTM			TIMESTAMP(6),
	DUE_BY_DTM					DATE,
	POSITION					NUMBER,
	NAME						VARCHAR2(200) NOT NULL,
	COMPONENT_DESCRIPTION		VARCHAR2(4000) 
) 
ON COMMIT PRESERVE ROWS; 

@..\chain\questionnaire_body

@update_tail
