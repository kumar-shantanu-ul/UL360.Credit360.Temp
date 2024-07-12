-- Please update version.sql too -- this keeps clean builds in sync
define version=1255
@update_header

ALTER TABLE CSR.AXIS ADD (PUBLICATION_SID NUMBER(10, 0));
ALTER TABLE CSR.AXIS_MEMBER ADD (PUBLICATION_SID NUMBER(10, 0));

DECLARE
	v_sid	 number(10);
	v_ok	 BOOLEAN;
	v_cnt	 number(10);
BEGIN
	security.user_pkg.logonadmin;
	v_ok := TRUE;
	v_cnt := 0;

	FOR r IN (
		select axis_id, app_sid, name FROM csr.axis
	)
	LOOP
		BEGIN
			v_sid := security.securableobject_pkg.getSidFromPath(SYS_CONTEXT('SECURITY','ACT'), r.app_sid, 'wwwroot/'||r.name);	
			UPDATE csr.axis
			  SET publication_sid = v_sid
			 WHERE axis_id= r.axis_id;
			v_cnt := v_cnt + 1;
		EXCEPTION 
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('error with axis_id '||r.axis_id||' - path not found "wwwroot/'||r.name||'"');
				v_ok := FALSE;
		END;
	END LOOP;
	
	DBMS_OUTPUT.PUT_LINE(v_cnt||' items fixed');
	IF v_ok = TRUE THEN
		FOR s IN (	
			SELECT column_name FROM all_tab_columns WHERE owner='CSR' AND table_name = 'AXIS' AND column_name ='PUBLICATION_SID' AND nullable = 'Y'
		)
		LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE CSR.AXIS MODIFY PUBLICATION_SID NOT NULL';
		END LOOP;
	ELSE
		DBMS_OUTPUT.PUT_LINE('fix the problems and then re-run');
	END IF;

	v_ok := TRUE;
	v_cnt := 0;
	FOR r IN (
		select am.axis_member_id, a.name axis_name, am.name member_name, a.app_sid 
		  FROM csr.axis a 
			join csr.axis_member am on a.axis_id = am.axis_id
		 where am.publication_sid is null
	)
	LOOP
		BEGIN
			v_sid := security.securableobject_pkg.getSidFromPath(sys_context('security', 'act'), r.app_sid, 'wwwroot/' || r.axis_name || '/' || r.member_name);
			UPDATE csr.axis_member
			  SET publication_sid = v_sid
			 WHERE axis_member_id= r.axis_member_id;
			v_cnt := v_cnt + 1;
		EXCEPTION 
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				DBMS_OUTPUT.PUT_LINE('error with axis_member_id '||r.axis_member_id||' - path not found "wwwroot/' || r.axis_name || '/' || r.member_name||'"');
				v_ok := FALSE;
		END;
	END LOOP;
	
	DBMS_OUTPUT.PUT_LINE(v_cnt||' items fixed');
	IF v_ok = TRUE THEN
		FOR s IN (	
			SELECT column_name FROM all_tab_columns WHERE owner='CSR' AND table_name = 'AXIS_MEMBER' AND column_name ='PUBLICATION_SID' AND nullable = 'Y'
		)
		LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE CSR.AXIS_MEMBER MODIFY PUBLICATION_SID NOT NULL';
		END LOOP;
	ELSE
		DBMS_OUTPUT.PUT_LINE('fix the problems and then re-run');
	END IF;
END;
/

@..\strategy_pkg
@..\strategy_body

@update_tail
