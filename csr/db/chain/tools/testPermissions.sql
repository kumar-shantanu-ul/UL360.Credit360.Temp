set termout off
set verify off

CREATE OR REPLACE VIEW chain.v$testmatrix
AS
	SELECT p.company_sid primary_company_sid, p.company_type_id primary_company_type_id, p.lookup_key primary_lookup_key, p.user_sid primary_user_sid, p.company_group_type_id primary_comp_group_type_id, p.group_sid primary_group_sid, p.group_name primary_group_name,
		   s.company_sid secondary_company_sid, s.company_type_id secondary_company_type_id, s.lookup_key secondary_lookup_key, s.user_sid secondary_user_sid, s.company_group_type_id secondary_comp_group_type_id, s.group_sid secondary_group_sid, s.group_name secondary_group_name,
		   t.company_sid tertiary_company_sid, t.company_type_id tertiary_company_type_id, t.lookup_key tertiary_lookup_key, t.user_sid tertiary_user_sid, t.company_group_type_id tertiary_comp_group_type_id, t.group_sid tertiary_group_sid, t.group_name tertiary_group_name
	  FROM (
		SELECT company_type_id primary_company_type_id, null secondary_company_type_id, null tertiary_company_type_id
		  FROM company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 UNION ALL
		SELECT primary_company_type_id, secondary_company_type_id, null tertiary_company_type_id
		  FROM company_type_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 UNION ALL
		SELECT ctr1.primary_company_type_id, ctr1.secondary_company_type_id, ctr2.secondary_company_type_id tertiary_company_type_id
		  FROM company_type_relationship ctr1, company_type_relationship ctr2
		 WHERE ctr1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctr1.app_sid = ctr2.app_sid
		   AND ctr1.secondary_company_type_id = ctr2.primary_company_type_id
		) ctr, (
		SELECT c.company_sid, ct.company_type_id, ct.lookup_key, cug.user_sid, cug.group_sid, cgt.company_group_type_id, cgt.name group_name
		  FROM chain.company c, chain.company_type ct, chain.tt_user_groups cug, chain.company_group cg, chain.company_group_type cgt
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.app_sid = ct.app_sid
		   AND c.company_type_id = ct.company_type_id
		   AND c.company_sid = cug.company_sid
		   AND c.company_sid = cg.company_sid
		   AND cug.group_sid = cg.group_sid
		   AND cg.company_group_type_id = cgt.company_group_type_id
		) p, (
		SELECT c.company_sid, ct.company_type_id, ct.lookup_key, cug.user_sid, cug.group_sid, cgt.company_group_type_id, cgt.name group_name
		  FROM chain.company c, chain.company_type ct, chain.tt_user_groups cug, chain.company_group cg, chain.company_group_type cgt
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.app_sid = ct.app_sid
		   AND c.company_type_id = ct.company_type_id
		   AND c.company_sid = cug.company_sid
		   AND c.company_sid = cg.company_sid
		   AND cug.group_sid = cg.group_sid
		   AND cg.company_group_type_id = cgt.company_group_type_id
		) s, (
		SELECT c.company_sid, ct.company_type_id, ct.lookup_key, cug.user_sid, cug.group_sid, cgt.company_group_type_id, cgt.name group_name
		  FROM chain.company c, chain.company_type ct, chain.tt_user_groups cug, chain.company_group cg, chain.company_group_type cgt
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.app_sid = ct.app_sid
		   AND c.company_type_id = ct.company_type_id
		   AND c.company_sid = cug.company_sid
		   AND c.company_sid = cg.company_sid
		   AND cug.group_sid = cg.group_sid
		   AND cg.company_group_type_id = cgt.company_group_type_id
		) t
	 WHERE ctr.primary_company_type_id = p.company_type_id
	   AND ctr.secondary_company_type_id = s.company_type_id(+)
	   AND ctr.tertiary_company_type_id = t.company_type_id(+)
;

CREATE OR REPLACE VIEW chain.v$testpermissionsfound
AS
	SELECT c.*, ctc.permission_set, x.*, 'Defined permission' permission_source
	  FROM chain.company_type_capability ctc, chain.capability c, chain.v$testmatrix x
	 WHERE ctc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ctc.capability_id = c.capability_id
	   AND ctc.primary_company_type_id = x.primary_company_type_id
	   AND NVL(ctc.secondary_company_type_id, 0) = NVL(x.secondary_company_type_id, 0)
	   AND NVL(ctc.tertiary_company_type_id, 0) = NVL(x.tertiary_company_type_id, 0)
	   AND ctc.primary_company_group_type_id = x.primary_comp_group_type_id
;

CREATE OR REPLACE VIEW chain.v$testpermissionsmissing
AS
	SELECT c.*, NULL permission_set, x.*, 'Derived permission' permission_source
	  FROM capability c, chain.v$testmatrix x
	 WHERE c.capability_id NOT IN (SELECT capability_id FROM chain.v$testpermissionsfound)
	   AND ((
              c.capability_type_id IN (0, 1)
          AND c.is_supplier = 0
          AND x.secondary_company_type_id IS NULL
          AND x.tertiary_company_type_id IS NULL
       ) OR (
              c.capability_type_id IN (0, 2)
          AND c.is_supplier = 1
          AND x.secondary_company_type_id IS NOT NULL
          AND x.tertiary_company_type_id IS NULL
       ) OR (
              c.capability_type_id = 3
          AND x.secondary_company_type_id IS NOT NULL
          AND x.tertiary_company_type_id IS NOT NULL
      ))
;

CREATE OR REPLACE VIEW chain.v$testpermissions
AS
	SELECT * FROM chain.v$testpermissionsmissing
	 UNION ALL
	SELECT * FROM chain.v$testpermissionsfound
;

CREATE OR REPLACE VIEW chain.v$testperms
AS
	SELECT 0 perm_type, 1 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 2 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 4 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 8 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 16 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 32 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 64 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 128 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 256 perm FROM DUAL
	UNION
	SELECT 0 perm_type, 512 perm FROM DUAL
	UNION
	SELECT 1 perm_type, 2 perm FROM DUAL
;

set termout on

PROMPT please enter a host:
define _1="a&&1"
PROMPT would you like detailed output (Y/N)?
define _2="a&&2"

DECLARE
	v_host				VARCHAR2(100) DEFAULT '&&1';
	v_detailed_output	BOOLEAN DEFAULT UPPER('&&2') = 'Y';
	v_company_sid		security.security_pkg.T_SID_ID;
	v_admin_user_sid	security.security_pkg.T_SID_ID;
	v_user_sid			security.security_pkg.T_SID_ID;
	v_max_key_len		NUMBER(10);
	--
	v_last_user_sid		security.security_pkg.T_SID_ID DEFAULT 0;
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_expected_result	BOOLEAN;
	v_expected_name		VARCHAR2(100);
	v_result			BOOLEAN;
	v_perm_type_name	VARCHAR2(100);
	v_count				NUMBER(10) DEFAULT 0;
	v_fail_count		NUMBER(10) DEFAULT 0;
	v_exception_hit		BOOLEAN;
	v_exception_code	VARCHAR2(1000);
	v_exception_msg		VARCHAR2(1000);
	v_exception_stack	VARCHAR2(4000);
BEGIN
	security.user_pkg.logonadmin(v_host);
	v_app_sid := security_pkg.GetApp;
	
	dbms_output.put_line(CHR(10));
	dbms_output.put_line('-----------------------------------------------------------------');
	
	SELECT MAX(key_len )
	  INTO v_max_key_len
	  FROM (SELECT LENGTH(lookup_key) key_len FROM chain.company_type);
	
	-- Create one company of each type in the application, and one user account for each of the admin and user roles for each company
	FOR r IN (
		SELECT * FROM chain.company_type
	) LOOP
		v_company_sid := chain.setup_pkg.CreateCompany('PERMISSION VERIFICATION COMPANY '||r.lookup_key, 'gb', r.lookup_key);
		v_admin_user_sid := chain.company_user_pkg.CreateUser(v_company_sid, 'PERMISSION VERIFICATION COMPANY '||r.lookup_key||' ADMIN USER', '12345678', NULL, 'PERMISSION.VERIFICATION.COMPANY.'||r.company_type_id||'.ADMIN.USER@credit360.com');
		v_user_sid := chain.company_user_pkg.CreateUser(v_company_sid, 'PERMISSION VERIFICATION COMPANY '||r.lookup_key||' USER', '12345678', NULL, 'PERMISSION.VERIFICATION.COMPANY.'||r.company_type_id||'.USER@credit360.com');
		
		chain.company_user_pkg.ActivateUser(v_admin_user_sid);
		chain.company_user_pkg.AddUserToCompany(v_company_sid, v_admin_user_sid);
		chain.company_user_pkg.ApproveUser(v_company_sid, v_admin_user_sid);
		chain.company_user_pkg.MakeAdmin(v_company_sid, v_admin_user_sid);
		
		chain.company_user_pkg.ActivateUser(v_user_sid);
		chain.company_user_pkg.AddUserToCompany(v_company_sid, v_user_sid);
		chain.company_user_pkg.ApproveUser(v_company_sid, v_user_sid);
		
		INSERT INTO chain.tt_user_groups (user_sid, company_sid, group_sid)
		SELECT v_admin_user_sid, v_company_sid, group_sid
		  FROM chain.company_group cg, chain.company_group_type cgt
		 WHERE cg.company_sid = v_company_sid
		   AND cg.company_group_type_id = cgt.company_group_type_id
		   AND cgt.name = chain.chain_pkg.ADMIN_GROUP;
		
		INSERT INTO chain.tt_user_groups (user_sid, company_sid, group_sid)
		SELECT v_user_sid, v_company_sid, group_sid
		  FROM chain.company_group cg, chain.company_group_type cgt
		 WHERE cg.company_sid = v_company_sid
		   AND cg.company_group_type_id = cgt.company_group_type_id
		   AND cgt.name = chain.chain_pkg.USER_GROUP;
		   
		dbms_output.put_line('Created company: K=>'||RPAD(r.lookup_key, v_max_key_len)||' C=>'||v_company_sid||' AU=>'||v_admin_user_sid||' NU=>'||v_user_sid);
	END LOOP;
	
	dbms_output.put_line(CHR(10));
	dbms_output.put_line('C (company sid)   AU (admin user)   NU (normal user)');
	
	-- establish the company relationships
	FOR r IN (
		SELECT c1.company_sid primary_company_sid, c2.company_sid secondary_company_sid
		  FROM chain.company_type_relationship ctr, chain.company c1, chain.company c2, 
		       (SELECT UNIQUE company_sid FROM chain.tt_user_groups) cug1, (SELECT UNIQUE company_sid FROM chain.tt_user_groups) cug2
		 WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ctr.app_sid = c1.app_sid
		   AND ctr.app_sid = c2.app_sid
		   AND ctr.primary_company_type_id = c1.company_type_id
		   AND ctr.secondary_company_type_id = c2.company_type_id
		   AND c1.company_sid = cug1.company_sid
		   AND c2.company_sid = cug2.company_sid
	) LOOP
		chain.company_pkg.StartRelationship(r.primary_company_sid, r.secondary_company_sid, NULL);
		chain.company_pkg.ActivateRelationship(r.primary_company_sid, r.secondary_company_sid);
	END LOOP;
	
	dbms_output.put_line(CHR(10));
	dbms_output.put_line('-----------------------------------------------------------------');
	
	FOR r IN (
		SELECT * FROM chain.v$testpermissions
		 ORDER BY primary_user_sid, capability_id, secondary_company_type_id, tertiary_company_type_id
	) LOOP
		IF v_last_user_sid <> r.primary_user_sid THEN
			-- we can't login as normal because the logon process contains autonomous transactions
			v_act := security.user_pkg.GenerateACT;
			security.security_pkg.SetACTAndSID(v_act, r.primary_user_sid);
			security.security_pkg.SetApp(v_app_sid);
			security.security_pkg.SetContext('CHAIN_COMPANY', r.primary_company_sid);
			v_last_user_sid := r.primary_user_sid;
		END IF;
		
		FOR c IN (
			SELECT * FROM chain.v$testperms WHERE perm_type = r.perm_type
		) LOOP
			
			v_count := v_count + 1;
			
			BEGIN
				IF r.perm_type = chain.chain_pkg.BOOLEAN_PERMISSION THEN
					v_expected_result := security.bitwise_pkg.bitand(c.perm, r.permission_set) = c.perm;
					v_result := chain.type_capability_pkg.CheckCapability(r.primary_company_sid, r.secondary_company_sid, r.tertiary_company_sid, r.capability_name);
					v_perm_type_name := 'BOOLEAN ';
				ELSE
					v_expected_result := security.bitwise_pkg.bitand(c.perm, r.permission_set) = c.perm;
					v_result := chain.type_capability_pkg.CheckCapability(r.primary_company_sid, r.secondary_company_sid, r.tertiary_company_sid, r.capability_name, c.perm);
					v_perm_type_name := 'SPECIFIC';
				END IF;
				
				v_exception_hit := FALSE;
			EXCEPTION
				WHEN OTHERS THEN
					v_exception_hit := TRUE;
					v_exception_code := SQLCODE;
					v_exception_msg := SQLERRM;
					v_exception_stack := dbms_utility.format_error_backtrace;
			END;
			
			IF v_expected_result THEN
				v_expected_name := 'TRUE ';
			ELSE
				v_expected_name := 'FALSE';
			END IF;
			
			IF v_expected_result <> v_result OR v_exception_hit THEN
				IF v_exception_hit THEN
					dbms_output.put_line(v_exception_msg);
					IF v_detailed_output THEN
						dbms_output.put_line(v_exception_stack);
					END IF;
				ELSE
					dbms_output.put_line('Expected '||v_expected_name||' ('||c.perm||') for '||v_perm_type_name||' capability "'||r.capability_name||'" for: P=>'||r.primary_lookup_key||' S=>'||r.secondary_lookup_key||' T=>'||r.tertiary_lookup_key||' PU =>'||r.primary_user_sid||' PUG=>'||r.primary_group_name);
				END IF;				
				
				IF v_detailed_output THEN
					dbms_output.put_line(CHR(10));
					dbms_output.put_line('  r.capability_id:              '||r.capability_id);
					dbms_output.put_line('  r.permission_source:          '||r.permission_source);
					dbms_output.put_line('  c.perm:                       '||c.perm);
					dbms_output.put_line('  r.permission_set:             '||r.permission_set);
					dbms_output.put_line('  permission_type:              '||v_perm_type_name);
					dbms_output.put_line('  r.primary_company_type_id:    '||r.primary_company_type_id);
					dbms_output.put_line('  r.primary_company_sid:        '||r.primary_company_sid);
					dbms_output.put_line('  r.secondary_company_type_id:  '||r.secondary_company_type_id);
					dbms_output.put_line('  r.secondary_company_sid:      '||r.secondary_company_sid);
					dbms_output.put_line('  r.tertiary_company_type_id:   '||r.tertiary_company_type_id);
					dbms_output.put_line('  r.tertiary_company_sid:       '||r.tertiary_company_sid);
					dbms_output.put_line('  r.capability_name:            '||r.capability_name);
					dbms_output.put_line('  Session company:              '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
					dbms_output.put_line('  Session user:                 '||SYS_CONTEXT('SECURITY', 'SID'));
					dbms_output.put_line('  r.primary_user_sid:           '||r.primary_user_sid);
					dbms_output.put_line('  r.primary_comp_group_type_id: '||r.primary_comp_group_type_id);
					dbms_output.put_line('  r.primary_group_name:         '||r.primary_group_name);
					dbms_output.put_line('  r.capability_name:            '||r.capability_name);
					dbms_output.put_line('  v_expected_result:            '||CASE WHEN v_expected_result THEN 'TRUE' ELSE 'FALSE' END);
					dbms_output.put_line('  v_result:                     '||CASE WHEN v_result THEN 'TRUE' ELSE 'FALSE' END);
				
					dbms_output.put_line(CHR(10));
					dbms_output.put_line('EXITING (standard when detailed output is turned on)');
					dbms_output.put_line(CHR(10));
					dbms_output.put_line(CHR(10));
				
					RETURN;
				END IF;
				
				v_fail_count := v_fail_count + 1;
			ELSE
				--dbms_output.put_line(v_expected_name);
				NULL;
			END IF;			
		END LOOP;
	END LOOP;
	dbms_output.put_line(CHR(10));
	dbms_output.put_line('Tested '||v_count||' combinations, with '||v_fail_count||' unexpected results');
	dbms_output.put_line(CHR(10));
	dbms_output.put_line(CHR(10));
	
	security.user_pkg.logonadmin();
END;
/
set termout off

rollback;

/*
DROP VIEW chain.v$testperms;
DROP VIEW chain.v$testpermissions;
DROP VIEW chain.v$testpermissionsmissing;
DROP VIEW chain.v$testpermissionsfound;
DROP VIEW chain.v$testmatrix;
*/
set termout on

PROMPT 
PROMPT 
PROMPT Test complete. Test data rolled back.
PROMPT 
PROMPT 
PROMPT 

exit


