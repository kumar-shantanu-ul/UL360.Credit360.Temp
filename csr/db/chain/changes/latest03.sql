define version=3
@update_header

@..\chain_pkg

CREATE GLOBAL TEMPORARY TABLE TT_ORDERED_PARAM 
( 
	ID					NUMBER(10) NOT NULL, 
	POSITION			NUMBER(10) NOT NULL,
	VALUE				VARCHAR2(255) NOT NULL
) 
ON COMMIT DELETE ROWS; 

begin
	for r in (select table_name from user_tables where table_name='ALERT_ENTRY_PARAM') loop
		execute immediate 'DROP TABLE ALERT_ENTRY_PARAM';
	end loop;
end;
/

CREATE TABLE ALERT_ENTRY_NAMED_PARAM(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_ID    NUMBER(10, 0)     NOT NULL,
    NAME              VARCHAR2(100)     NOT NULL,
    VALUE             VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK163 PRIMARY KEY (APP_SID, ALERT_ENTRY_ID, NAME)
)
;

CREATE TABLE ALERT_ENTRY_ORDERED_PARAM(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_ID    NUMBER(10, 0)     NOT NULL,
    POSITION          NUMBER(10, 0)     NOT NULL,
    VALUE             VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK162 PRIMARY KEY (APP_SID, ALERT_ENTRY_ID, POSITION)
)
;

CREATE TABLE ALERT_ENTRY_TEMPLATE(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    TEMPLATE_NAME          VARCHAR2(100)     NOT NULL,
    TEMPLATE               VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK160 PRIMARY KEY (APP_SID, ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
)
;

ALTER TABLE ALERT_ENTRY DROP COLUMN ALREADY_VIEWED;
ALTER TABLE ALERT_ENTRY ADD (TEMPLATE_NAME VARCHAR2(100) NOT NULL);

ALTER TABLE ALERT_ENTRY_TYPE DROP COLUMN ITEM_CSS;
ALTER TABLE ALERT_ENTRY_TYPE DROP COLUMN VIEWED_CSS;

ALTER TABLE ALERT_ENTRY_NAMED_PARAM ADD CONSTRAINT RefALERT_ENTRY371 
    FOREIGN KEY (APP_SID, ALERT_ENTRY_ID)
    REFERENCES ALERT_ENTRY(APP_SID, ALERT_ENTRY_ID)
;

ALTER TABLE ALERT_ENTRY_ORDERED_PARAM ADD CONSTRAINT RefALERT_ENTRY372 
    FOREIGN KEY (APP_SID, ALERT_ENTRY_ID)
    REFERENCES ALERT_ENTRY(APP_SID, ALERT_ENTRY_ID)
;

ALTER TABLE ALERT_ENTRY ADD CONSTRAINT RefALERT_ENTRY_TEMPLATE366 
    FOREIGN KEY (APP_SID, ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
    REFERENCES ALERT_ENTRY_TEMPLATE(APP_SID, ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
;

ALTER TABLE ALERT_ENTRY_TEMPLATE ADD CONSTRAINT RefCUSTOMER_OPTIONS367 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE ALERT_ENTRY_TEMPLATE ADD CONSTRAINT RefALERT_ENTRY_TYPE368 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;



BEGIN	
	DELETE FROM alert_entry_param_type;
		-- constants changed...
	INSERT INTO	alert_entry_param_type (alert_entry_param_type_id, description) VALUES (chain_pkg.ORDERED_PARAMS, 'Ordered params applied using String.Format("{0} are being used", "Ordered Params")');
	INSERT INTO	alert_entry_param_type (alert_entry_param_type_id, description) VALUES (chain_pkg.NAMED_PARAMS, 'Named params applied using String.Format("{paramType} are being used", new KeyValuePair<string, string>("paramType", "Named Params"))');
	
	user_pkg.logonadmin;
		
	FOR r IN (
		SELECT app_sid
		  FROM customer_options
	) LOOP
		security_pkg.SetACT(security_pkg.GetAct, r.app_sid);
	
		INSERT INTO	alert_entry_template (alert_entry_type_id, template_name, template) VALUES (chain_pkg.EVENT_ALERT, 'DEFAULT', '<div>{text}</div><div style="color: #888888; font-size:smaller; margin-bottom: 1em">Occurred: {occurredDtm}</div>');
		INSERT INTO	alert_entry_template (alert_entry_type_id, template_name, template) VALUES (chain_pkg.ACTION_ALERT, 'DEFAULT', '<div>{text}</div><div style="color: #888888; font-size:smaller; margin-bottom: 1em">Occurred: {occurredDtm}</div>');
		INSERT INTO	alert_entry_template (alert_entry_type_id, template_name, template) VALUES (chain_pkg.ACTION_ALERT, 'COMPLETED', '<div>{text}</div><div style="color: #52A252; font-size:smaller; margin-bottom: 1em">Completed: {occurredDtm}</div>');
	
	END LOOP;
END;
/



@..\create_views

@..\scheduled_alert_pkg
@..\event_pkg
@..\action_pkg

@..\scheduled_alert_body
@..\event_body
@..\action_body


@update_tail