-- Please update version.sql too -- this keeps clean builds in sync
define version=245
@update_header


 
ALTER TABLE ATTACHMENT ADD (
    DOC_ID                        NUMBER(10, 0)
    );

ALTER TABLE SECTION ADD (
    SECTION_STATUS_SID            NUMBER(10, 0)     NULL,
    FURTHER_INFO_URL              VARCHAR2(1024)    NULL
);



ALTER TABLE SECTION_MODULE ADD (
    SHOW_SUMMARY_TAB    NUMBER(1, 0)      DEFAULT 0 NOT NULL
);


CREATE TABLE SECTION_STATUS(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_STATUS_SID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    COLOUR                NUMBER(10, 0)    NOT NULL,
    POS                   NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK543 PRIMARY KEY (APP_SID, SECTION_STATUS_SID)
)
;



CREATE TABLE SECTION_TRANSITION(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SECTION_TRANSITION_SID     NUMBER(10, 0)    NOT NULL,
    FROM_SECTION_STATUS_SID    NUMBER(10, 0)    NOT NULL,
    TO_SECTION_STATUS_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK542 PRIMARY KEY (APP_SID, SECTION_TRANSITION_SID)
)
;


ALTER TABLE SECTION_MODULE ADD (
    DEFAULT_STATUS_SID    NUMBER(10, 0)     NULL
  );
  
 
 
ALTER TABLE SECTION_MODULE ADD CONSTRAINT RefSECTION_STATUS1043 
    FOREIGN KEY (APP_SID, DEFAULT_STATUS_SID)
    REFERENCES SECTION_STATUS(APP_SID, SECTION_STATUS_SID);
 
 
ALTER TABLE ATTACHMENT ADD CONSTRAINT RefDOC1036 
    FOREIGN KEY (APP_SID, DOC_ID)
    REFERENCES DOC(APP_SID, DOC_ID);
 
 
ALTER TABLE SECTION_STATUS ADD CONSTRAINT RefCUSTOMER1038 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);

ALTER TABLE SECTION_TRANSITION ADD CONSTRAINT RefSECTION_STATUS1039 
    FOREIGN KEY (APP_SID, FROM_SECTION_STATUS_SID)
    REFERENCES SECTION_STATUS(APP_SID, SECTION_STATUS_SID);

ALTER TABLE SECTION_TRANSITION ADD CONSTRAINT RefSECTION_STATUS1040 
    FOREIGN KEY (APP_SID, TO_SECTION_STATUS_SID)
    REFERENCES SECTION_STATUS(APP_SID, SECTION_STATUS_SID);

ALTER TABLE SECTION_TRANSITION ADD CONSTRAINT RefCUSTOMER1041 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID);



-- new classess
DECLARE
	v_act_id	security_pkg.T_ACT_ID;
	v_class_id	security_pkg.T_SID_ID;
BEGIN	
	-- log on
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act_id);
		
	BEGIN
		class_pkg.CreateClass(v_act_id, NULL, 'SectionStatus', 'csr.section_status_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_class_id:=class_pkg.GetClassId('SectionStatus');
	END;
	
	BEGIN	
	class_pkg.CreateClass(v_act_id, NULL, 'SectionStatusTransition', 'csr.section_transition_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_class_id:=class_pkg.GetClassId('SectionStatusTransition');
	END;
END;
/


@..\text\section_transition_pkg
@..\text\section_status_pkg
@..\text\section_root_pkg
@..\text\section_pkg
@..\csr_data_pkg


@..\text\section_transition_body
@..\text\section_status_body
@..\text\section_root_body
@..\text\section_body
@..\csr_data_body

GRANT EXECUTE ON section_transition_pkg TO SECURITY;
GRANT EXECUTE ON section_status_pkg TO SECURITY;

grant execute on section_status_pkg to web_user;
grant execute on section_transition_pkg to web_user;


-- create status stuff for all customers
DECLARE
	v_act				    security_pkg.T_ACT_ID;
    v_sid                   security_pkg.T_SID_ID;
    v_text_sid              security_pkg.T_SID_ID;
    v_text_statuses_sid     security_pkg.T_SID_ID;
    v_text_transitions_sid  security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 10000, v_act);
    FOR r IN (
        SELECT app_sid, host FROM CUSTOMER
    )
    LOOP
    	security_pkg.SetACT(v_act, r.app_sid);
    	DBMS_OUTPUT.PUT_LINE('Doing '||r.host);
        securableobject_pkg.CreateSO(v_act, r.app_sid, security_pkg.SO_CONTAINER, 'Text', v_text_sid);
        -- move other sections under here? hmm - maybe - can't be bothered right now - might muck up permissions
        securableobject_pkg.CreateSO(v_act, v_text_sid, security_pkg.SO_CONTAINER, 'Statuses', v_text_statuses_sid);
        securableobject_pkg.CreateSO(v_act, v_text_sid, security_pkg.SO_CONTAINER, 'Transitions', v_text_transitions_sid);
        -- make default status (red)
        section_status_pkg.CreateSectionStatus('Editing', 15728640, 0, v_sid);
        UPDATE section_module SET default_status_sid = v_sid WHERE app_sid = r.app_sid;
        UPDATE section SET section_status_sid = v_sid WHERE app_sid = r.app_sid;
    END LOOP;
END;
/


ALTER TABLE SECTION MODIFY SECTION_STATUS_SID NOT NULL;

ALTER TABLE SECTION_MODULE MODIFY DEFAULT_STATUS_SID NOT NULL;
  


ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_STATUS1037 
    FOREIGN KEY (APP_SID, SECTION_STATUS_SID)
    REFERENCES SECTION_STATUS(APP_SID, SECTION_STATUS_SID);
 

@..\rls

@update_tail
