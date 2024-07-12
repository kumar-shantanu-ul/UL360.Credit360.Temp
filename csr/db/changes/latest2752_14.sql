-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.UTIL_SCRIPT (
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL ,
	UTIL_SCRIPT_NAME	VARCHAR2(255) NOT NULL,
	DESCRIPTION			VARCHAR2(2047),
	UTIL_SCRIPT_SP		VARCHAR2(255),
	WIKI_ARTICLE		VARCHAR2(10),
	CONSTRAINT pk_util_script_id PRIMARY KEY (util_script_id)
	USING INDEX
);

CREATE TABLE CSR.UTIL_SCRIPT_PARAM (
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL,
	PARAM_NAME			VARCHAR2(1023) NOT NULL,
	PARAM_HINT			VARCHAR2(1023),
	POS					NUMBER(2) NOT NULL,
	CONSTRAINT fk_util_script_param_id FOREIGN KEY (util_script_id)
	REFERENCES CSR.UTIL_SCRIPT(util_script_id)
);

CREATE TABLE CSR.UTIL_SCRIPT_RUN_LOG (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	UTIL_SCRIPT_ID		NUMBER(10) NOT NULL,
	CSR_USER_SID		NUMBER(10) NOT NULL,
	RUN_DTM				DATE NOT NULL,
	PARAMS				VARCHAR2(2048),
	CONSTRAINT fk_util_script_run_script_id FOREIGN KEY (util_script_id)
	REFERENCES CSR.UTIL_SCRIPT(util_script_id),
	CONSTRAINT fk_util_script_run_user FOREIGN KEY (app_sid, csr_user_sid)
	REFERENCES CSR.csr_user(app_sid, csr_user_sid)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data
-- Create future sheets for delegation
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (1, 'Create future sheets for delegation', 'Creates sheets in the future for an existing delegation. Replaces CreateDelegationSheetsFuture.sql', 'CreateDelegationSheetsFuture');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (1, 'Delegation sid', 'The sid of the delegation to run against', 1);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (1, 'Max date (YYYY-MM-DD)', 'The maximum date to create sheets for', 2);
	-- Recalcone
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
	VALUES (2, 'Recalc one', 'Queues recalc jobs for the current site/app. Replaces recalcOne.sql', 'CreateDelegationSheetsFuture');
	-- Create imap folder
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (3, 'Create IMAP folder', 'Creates an imap folder for routing client emails. See the wiki page. Replaces EnableClientImapFolder.sql', 'CreateImapFolder', 'W955');
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (3, 'Folder name', 'IMAP folder name to create (lower-case by convention, e.g. credit360)', 1);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
	VALUES (3, 'Suffixes (See wiki)', '(optionally comma-separated list) of email suffixes, e.g. credit360.com,credit360.co.uk', 2);
	
	--Create the menu item for all sites
	security.user_pkg.logonadmin;
	
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
	
		security.user_pkg.logonadmin(r.host);
	
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
			v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
			v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
			v_setup_menu				security.security_pkg.T_SID_ID;
			v_utilscript_menu				security.security_pkg.T_SID_ID;
			
		BEGIN
			BEGIN
				v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup',  'Setup',  '/csr/site/admin/config/global.acds',  0, null, v_setup_menu);
			END;
		
			BEGIN
				v_utilscript_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'csr_admin_utilscripts');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'csr_admin_utilscripts',  'Utility scripts',  '/csr/site/admin/UtilScripts/UtilScripts.acds',  0, null, v_utilscript_menu);
			END;
			
			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_utilscript_menu, 0);
			--Remove inherited ones
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_utilscript_menu));
			-- Add SA permission
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_utilscript_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		END;
	END LOOP;
	
	commit;
END;
/
	
-- Creating new packages first; but these grants needed first
GRANT EXECUTE ON mail.message_filter_pkg TO web_user;
GRANT EXECUTE ON mail.mailbox_pkg TO web_user;
GRANT EXECUTE ON mail.message_filter_pkg TO csr;
GRANT EXECUTE ON mail.mailbox_pkg TO csr;

@../util_script_pkg
@../util_script_body

-- ** New package grants **
GRANT EXECUTE ON csr.util_script_pkg TO web_user;

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
