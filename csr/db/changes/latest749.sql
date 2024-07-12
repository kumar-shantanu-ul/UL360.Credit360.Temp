-- Please update version.sql too -- this keeps clean builds in sync
define version=749
@update_header

DROP SEQUENCE csr.QS_CAMPAIGN_ID_SEQ;

DROP TABLE csr.QS_CAMPAIGN;

CREATE TABLE csr.QS_CAMPAIGN(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_CAMPAIGN_SID    NUMBER(10, 0)    NOT NULL,
    NAME               VARCHAR2(255),
    TABLE_SID          NUMBER(10, 0),
    FILTER_SID         NUMBER(10, 0),
    SURVEY_SID         NUMBER(10, 0),
    FRAME_ID           NUMBER(10, 0),
    SUBJECT            CLOB,
    BODY               CLOB,
    SEND_AFTER_DTM     DATE,
    STATUS             VARCHAR2(20)     DEFAULT 'draft' NOT NULL,
    SENT_DTM           DATE,
    CONSTRAINT CHK_QS_CAMPAIGN_STATUS CHECK (STATUS IN ('draft', 'pending', 'sent')),
    CONSTRAINT PK_QS_CAMPAIGN PRIMARY KEY (APP_SID, QS_CAMPAIGN_SID)
)
;

ALTER TABLE csr.QS_CAMPAIGN ADD CONSTRAINT FK_QS_CAMP_FRAME_ID 
    FOREIGN KEY (APP_SID, FRAME_ID)
    REFERENCES csr.ALERT_FRAME(APP_SID, ALERT_FRAME_ID)
;

ALTER TABLE csr.QS_CAMPAIGN ADD CONSTRAINT FK_QS_CAMP_QS 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES csr.QUICK_SURVEY(APP_SID, SURVEY_SID)
;

ALTER TABLE csr.QS_CAMPAIGN ADD CONSTRAINT FK_QS_CAMPAIGN_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

@..\quick_survey_pkg
@..\campaign_pkg
@..\quick_survey_body
@..\campaign_body

grant execute on csr.campaign_pkg to web_user;
grant execute on csr.campaign_pkg to security;

EXEC user_pkg.logonadmin;

DECLARE
	new_class_id 	security_pkg.T_SID_ID;
BEGIN
	class_pkg.CreateClass(security_pkg.getACT, NULL, 'CSRSurveyCampaign', 'csr.campaign_pkg', NULL, new_class_id);
EXCEPTION
	WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
END;
/

DECLARE
	v_sid			security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT app_sid FROM customer
	) LOOP
		BEGIN
			v_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, r.app_sid, 'wwwroot/surveys');
			BEGIN
				securableobject_pkg.CreateSO(security_pkg.getACT, r.app_sid, security_pkg.SO_CONTAINER, 'Campaigns', v_sid);
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL; -- Aready exists
			END;
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Not a survey-enabled site
		END;
	END LOOP;
END;
/


@update_tail
