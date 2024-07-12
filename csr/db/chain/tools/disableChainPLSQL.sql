/* WARNING: This PL/SQL block is pulled into scripts at the SQL*Plus level (via DisableChain.sql) as well as */
/* at the PL/SQL level (e.g. via \cvs\clients\chaindemo\db\chain\setup.sql), and so it absolutely must not  */
/* contain any SQL*Plus commands, including / (slash) to execute the block.                                 */
/* &&1 indicates a light setup 																				*/

DECLARE
	v_act_id				security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid				security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	v_group_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');

	v_menu					security.security_pkg.T_SID_ID;	

	v_respondent			security.security_pkg.T_SID_ID;
BEGIN
	
	/**************************************************************************************
		DELETE GROUPS
	**************************************************************************************/
	BEGIN
		security.group_pkg.DeleteGroup(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_ADMIN_GROUP));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		security.group_pkg.DeleteGroup(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, chain.chain_pkg.CHAIN_USER_GROUP));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- get rid of this at some point...
	BEGIN
		security.group_pkg.DeleteGroup(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Chain Hidden Users'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	/**************************************************************************************
		DELETE CHAIN CONTAINER
	**************************************************************************************/
	
	-- We need to explicitly clear the Chain Invitation Respondant user here. 
	-- It's class is "User" but a row gets added explicitly in "csr_user" table in DisableChain
	-- When it's deleted as it's class is not "CSRUser" then this row isn't cleared and this causes an integrity constraint to fail (CSR.REFCSRUSERTOSECUSER)
	-- TO DO - I don't know why this users class isn't CSRUser but I presume there is a good reason for it so taking the saf course until I can run past CG

	BEGIN
		v_respondent := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, v_app_sid, 'Chain/BuiltIn/Invitation Respondent');
		csr.csr_user_pkg.DeleteObject(security.security_pkg.GetACT, v_respondent);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	/**************************************************************************************
		DELETE CHAIN WEB RESOURCE
	**************************************************************************************/
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site/chain'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	/**************************************************************************************
		DELETE MENUS
	**************************************************************************************/	
	
	v_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'menu');
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	v_menu := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_menu, 'admin');
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain_my_details'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain_my_company'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	BEGIN
		security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain_news_setup'));
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	IF INSTR(LOWER(security.securableobject_pkg.GetNamedStringAttribute(v_act_id, v_app_sid, 'logon-url')), '/chain/') > 0 THEN
		security.securableobject_pkg.SetNamedStringAttribute(v_act_id, v_app_sid, 'logon-url', '/csr/site/login.acds');
	END IF;

	IF INSTR(LOWER(security.securableobject_pkg.GetNamedStringAttribute(v_act_id, v_app_sid, 'default-url')), '/chain/') > 0 THEN
		security.securableobject_pkg.SetNamedStringAttribute(v_act_id, v_app_sid, 'default-url', '/csr/site/portal/Home.acds');
	END IF;	
END;

/* WARNING: This PL/SQL block is pulled into scripts at the SQL*Plus level (via DisableChain.sql) as well as */
/* at the PL/SQL level (e.g. via \cvs\clients\chaindemo\db\chain\setup.sql), and so it absolutely must not  */
/* contain any SQL*Plus commands, including / (slash) to execute the block.                                 */

