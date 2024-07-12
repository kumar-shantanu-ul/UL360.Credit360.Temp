-- Please update version.sql too -- this keeps clean builds in sync
define version=804
@update_header

GRANT REFERENCES ON SECURITY.MENU to CSR;

ALTER TABLE CSR.AXIS ADD MENU_SID NUMBER(10,0);

ALTER TABLE CSR.AXIS ADD CONSTRAINT FK_AXIS_MENU 
    FOREIGN KEY (MENU_SID)
    REFERENCES SECURITY.MENU(SID_ID)
;

DECLARE
	v_act				security.security_pkg.T_ACT_ID;
	v_menu_sid			security.security_pkg.T_SID_ID;
BEGIN
	SECURITY.user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	
	FOR r IN (SELECT c.host, a.axis_id, a.name, a.app_sid FROM CSR.axis a, CSR.customer c WHERE a.app_sid = c.app_sid)
	LOOP
		dbms_output.put_line('processing: '|| r.host);
		v_menu_sid := null;
		
		BEGIN
			v_menu_sid := SECURITY.securableobject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY','ACT'), r.app_sid, 'Menu/home/' || r.name);
		EXCEPTION
			WHEN SECURITY.security_pkg.object_not_found THEN
				-- FRONTENAC has different containers
				IF r.host = 'frontenac.credit360.com' AND r.name = 'pillar' THEN
					-- update frontenac
					v_menu_sid := security.securableobject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY','ACT'), r.app_sid, 'Menu/home/Our_Pillars');
				ELSIF r.host = 'frontenac.credit360.com' AND r.name = 'focus_area' THEN
					v_menu_sid := security.securableobject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY','ACT'), r.app_sid, 'Menu/home/Environmental_Indicators');
				ELSE
					dbms_output.put_line('menu path not Menu/home/'||r.name||' NOT found for: ' || r.host);
				END IF;
		END;
		UPDATE CSR.AXIS SET MENU_SID = v_menu_sid WHERE axis_id = r.axis_id;
	END LOOP;
END;
/

ALTER TABLE csr.AXIS MODIFY MENU_SID NOT NULL;

@update_tail