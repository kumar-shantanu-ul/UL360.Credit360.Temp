-- Please update version.sql too -- this keeps clean builds in sync
define version=1648
@update_header

CREATE TABLE CSR.CALENDAR(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALENDAR_SID     NUMBER(10, 0)    NOT NULL,
    JS_INCLUDE       VARCHAR2(255)    NOT NULL,
    JS_CLASS_TYPE    VARCHAR2(255)    NOT NULL,
    DESCRIPTION      VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_CALENDAR PRIMARY KEY (APP_SID, CALENDAR_SID)
)
;

ALTER TABLE CSR.CALENDAR ADD CONSTRAINT FK_CALENDAR_APP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

-- Create dummy package so that grants / so ops don't fail if package doesn't compile
create or replace package csr.calendar_pkg as
	PROCEDURE CreateObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_class_id					IN  security.security_pkg.T_CLASS_ID,
		in_name						IN  security.security_pkg.T_SO_NAME,
		in_parent_sid_id			IN  security.security_pkg.T_SID_ID
	);

	PROCEDURE RenameObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_new_name					IN  security.security_pkg.T_SO_NAME
	);

	PROCEDURE DeleteObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID
	); 

	PROCEDURE MoveObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_new_parent_sid_id		IN  security.security_pkg.T_SID_ID
	); 
end;
/

create or replace package body csr.calendar_pkg as
	PROCEDURE CreateObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_class_id					IN  security.security_pkg.T_CLASS_ID,
		in_name						IN  security.security_pkg.T_SO_NAME,
		in_parent_sid_id			IN  security.security_pkg.T_SID_ID
	) AS BEGIN NULL; END;

	PROCEDURE RenameObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_new_name					IN  security.security_pkg.T_SO_NAME
	) AS BEGIN NULL; END;

	PROCEDURE DeleteObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID
	) AS BEGIN NULL; END; 

	PROCEDURE MoveObject(
		in_act_id					IN  security.security_pkg.T_ACT_ID,
		in_sid_id					IN  security.security_pkg.T_SID_ID,
		in_new_parent_sid_id		IN  security.security_pkg.T_SID_ID
	) AS BEGIN NULL; END; 
end;
/

grant execute on csr.calendar_pkg to web_user;
grant execute on csr.calendar_pkg to security;

DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN	
		security.class_pkg.CreateClass(security.security_pkg.GetAct, NULL, 'CSRCalendar', 'csr.calendar_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

DECLARE
	v_act						security.security_pkg.T_ACT_ID;
	v_calendars_sid				security.security_pkg.T_SID_ID;
	v_calendar_sid				security.security_pkg.T_SID_ID;
	v_sid						security.security_pkg.T_SID_ID;
BEGIN
	-- Update all sites that have calendars enabled already
	security.user_pkg.LogonAdmin;
	v_act := security.security_pkg.GetAct;
	
	FOR r IN (
		SELECT so.parent_sid_id app_sid
		  FROM security.web_resource wr
		  JOIN security.securable_object so ON wr.web_root_sid_id = so.sid_id
		 WHERE wr.path='/csr/site/calendar'
	) LOOP
		
		BEGIN
			v_calendars_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Calendars');
		EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.SecurableObject_pkg.CreateSO(v_act, r.app_sid, security.security_pkg.SO_CONTAINER, 'Calendars', v_calendars_sid);
		END;
		
		BEGIN
			security.securableObject_pkg.CreateSO(v_act, v_calendars_sid, security.class_pkg.GetClassID('CSRCalendar'), 'issues', v_calendar_sid);
			INSERT INTO csr.calendar (app_sid, calendar_sid, description, js_include, js_class_type)
			VALUES (r.app_sid, v_calendar_sid, 'Issues coming due', '/csr/site/calendar/includes/issues.js', 'Credit360.Calendars.Issues');
		EXCEPTION WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		END;
		
		BEGIN
			v_sid := security.securableobject_pkg.GetSIDFromPath(v_act, r.app_sid, 'Audits');
			security.securableObject_pkg.CreateSO(v_act, v_calendars_sid, security.class_pkg.GetClassID('CSRCalendar'), 'audits', v_calendar_sid);
			INSERT INTO csr.calendar (app_sid, calendar_sid, description, js_include, js_class_type)
			VALUES (r.app_sid, v_calendar_sid, 'Audits', '/csr/site/calendar/includes/audits.js', 'Credit360.Calendars.Audits');
		EXCEPTION WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- Skip sites that don't have audits enabled
		END;
		
	END LOOP;
END;
/

declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'CALENDAR'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin               
                    v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    
                    dbms_output.put_line('doing '||v_name);
                    dbms_rls.add_policy(
                        object_schema   => 'CSR',
                        object_name     => v_list(i),
                        policy_name     => v_name,
                        function_schema => 'CSR',
                        policy_function => 'appSidCheck',
                        statement_types => 'select, insert, update, delete',
                        update_check    => true,
                        policy_type     => dbms_rls.context_sensitive );
                    exit;
                exception
                    when policy_already_exists then
                        NULL;
                end;
            end loop;
        end;
    end loop;
end;
/

@..\calendar_pkg
@..\issue_pkg

@..\calendar_body
@..\issue_body

@update_tail