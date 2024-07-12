-- Please update version.sql too -- this keeps clean builds in sync
define version=72
@update_header

VARIABLE version NUMBER
BEGIN :version := 72; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
END;
/	

ALTER TABLE customer ADD account_policy_sid NUMBER(10);

-- Fix up stuff for existing customers that have account policies applied
DECLARE
	v_policy_sid		security_pkg.T_SID_ID;
	v_act_id			security_pkg.T_ACT_ID;
	v_csr_root_sid		security_pkg.T_SID_ID;
BEGIN
	User_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 300, v_act_id);

	-- dump the old policy object + class
	BEGIN
		SecurableObject_pkg.DeleteSO(v_act_id, SecurableObject_pkg.GetSIDFromPath(v_act_id,security_pkg.SID_ROOT,'//CSR/Disable account after 5 logon failures'));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- ignore this if you have deleted it manually
	END;
	BEGIN
		SecurableObject_pkg.DeleteSO(v_act_id, SecurableObject_pkg.GetSIDFromPath(v_act_id,security_pkg.SID_ROOT,'//CSR/Disable account after 3 logon failures'));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- ignore this if you have deleted it manually
	END;
	Class_pkg.DeleteClass(v_act_id, class_pkg.GetClassId('CSRLogonPolicy'));
	
	-- Create empty policy objects for all customers
	FOR r IN (SELECT csr_root_sid 
	  		 	FROM customer) LOOP
		accountPolicy_pkg.CreatePolicy(v_act_id, 
			r.csr_root_sid,
			'AccountPolicy', 
			null, null, null, null, v_policy_sid);
		UPDATE customer
		   SET account_policy_sid = v_policy_sid
		 WHERE csr_root_sid = r.csr_root_sid;
	END LOOP;
	
	-- Fix up pre-existing policies (if sites are in the DB, ignore if they aren't)
	BEGIN
		security.accountPolicy_pkg.SetPolicy(v_act_id, 
			SecurableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//Aspen/Applications/rwe.credit360.com/CSR/AccountPolicy'),
			5, 90, null, null);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	BEGIN
		security.accountPolicy_pkg.SetPolicy(v_act_id, 
			SecurableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//Aspen/Applications/providentfinancial.credit360.com/CSR/AccountPolicy'),
			5, 90, null, null);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	BEGIN
		security.accountPolicy_pkg.SetPolicy(v_act_id, 
			SecurableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//Aspen/Applications/ica.credit360.com/CSR/AccountPolicy'),
			5, 90, null, null);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	BEGIN
		security.accountPolicy_pkg.SetPolicy(v_act_id, 
			SecurableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//Aspen/Applications/test.ica.credit360.com/CSR/AccountPolicy'),
			5, 90, null, null);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	BEGIN
		security.accountPolicy_pkg.SetPolicy(v_act_id, 
			SecurableObject_pkg.GetSIDFromPath(v_act_id, security_pkg.SID_ROOT, '//Aspen/Applications/eon.credit360.com/CSR/AccountPolicy'),
			5, 90, null, null);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	COMMIT;
END;
/

-- Make the aps not null
ALTER TABLE customer MODIFY account_policy_sid NUMBER(10) NOT NULL;

-- get rid of the old logon policy package
DROP PACKAGE logon_policy_pkg;

-- get rid of the old user active flag (using user_table.enabled instead)
ALTER TABLE csr_user DROP COLUMN active;

-- fix up last logon columns in security
BEGIN
	FOR r IN (SELECT csr_user_sid, last_logon_dtm, last_but_one_logon_dtm
				FROM csr_user) LOOP
		UPDATE security.user_table 
		   SET last_logon = NVL(r.last_logon_dtm, SYSDATE), last_but_one_logon = NVL(r.last_but_one_logon_dtm,SYSDATE)
		 WHERE sid_id = r.csr_user_sid;
	END LOOP;
	COMMIT;
END;
/

-- dump our copies
ALTER TABLE csr_user DROP COLUMN last_but_one_logon_dtm;
ALTER TABLE csr_user DROP COLUMN last_logon_dtm;

-- fix up grant
PROMPT Enter DB connection string to grant security privileges
connect security/security@&&1
grant select on security.user_table to csr;
grant select on security.user_table to actions;

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
PROMPT
EXIT



@update_tail
