DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_class_id				security.security_pkg.T_CLASS_ID;	
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_reg_users_sid			security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_chem_admins_sid		security.security_pkg.T_SID_ID;
	
	v_menu_admin			security.security_pkg.T_SID_ID;
	v_menu1					security.security_pkg.T_SID_ID;
	
	v_www					security.security_pkg.T_SID_ID;
	v_www_csr_site_chem 	security.security_pkg.T_SID_ID;

	v_flow_root_sid			SECURITY.SECURITY_PKG.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	-- TODO: OWL stuff
	
	csr.delegation_pkg.CreatePluginIndicator('Chem Plugin','Plugin used for Chem module','SheetPlugin.Chem','/csr/site/delegation/sheet2/sheetElements/plugins/Chem.js');
	
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	
	--Adding Chemical Inventory plugin (of type: property tab)
	DECLARE
		v_chem_plugin_id NUMBER(10);
	BEGIN
		v_chem_plugin_id := csr.plugin_pkg.SetCorePlugin(
			in_plugin_type_id => csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
			in_js_class => 'Controls.ChemicalInventoryTab',
			in_description => 'Chemicals Inventory',
			in_js_include => '/csr/site/property/properties/controls/ChemicalInventoryTab.js',
			in_cs_class => 'Credit360.Plugins.PluginDto',
			in_details => 'This tab shows a list chemicals associated with the property.'
		);
		
		BEGIN
			INSERT INTO csr.property_tab (plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_chem_plugin_id, csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB, 2, 'Chemicals Inventory');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.property_tab
				   SET pos=2
				 WHERE plugin_id = v_chem_plugin_id;
		END;

		BEGIN
			INSERT INTO csr.property_tab_group (plugin_id, group_sid)
			VALUES (v_chem_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/Administrators'));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END;
	
	BEGIN
		v_flow_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Workflows');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001,'Workflows not enable on site. Run csr\db\utils\enableWorkflow first.');
			RETURN;
	END;

	DECLARE
		v_workflow_sid			security.security_pkg.T_SID_ID;
		v_app_sid				security.security_pkg.T_SID_ID;
		v_act_id				security.security_pkg.T_ACT_ID;
		v_wf_ct_sid				security.security_pkg.T_SID_ID;
		v_complete_xml			CLOB;
		v_frame0				csr.alert_frame.alert_frame_id%TYPE;
		v_cat0					csr.customer_alert_type.customer_alert_type_id%TYPE;
		v_cat1					csr.customer_alert_type.customer_alert_type_id%TYPE;
		v_r0					security.security_pkg.T_SID_ID;
		v_r1					security.security_pkg.T_SID_ID;
		v_r2					security.security_pkg.T_SID_ID;
		v_s0					security.security_pkg.T_SID_ID;
		v_s1					security.security_pkg.T_SID_ID;
		v_s2					security.security_pkg.T_SID_ID;
		v_s3					security.security_pkg.T_SID_ID;
		v_s4					security.security_pkg.T_SID_ID;
		v_s5					security.security_pkg.T_SID_ID;
		v_s6					security.security_pkg.T_SID_ID;
		v_xml_p1				CLOB;
		v_str					VARCHAR2(2000);
	BEGIN
		v_app_sid := sys_context('security','app');
		v_act_id := sys_context('security','act');

		BEGIN
			v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Chemical Workflow');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				BEGIN
					v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');	
				EXCEPTION
					WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
				END;
				
				BEGIN
					INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
							VALUES ('chemical');
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;

				-- create our workflow
				csr.flow_pkg.CreateFlow(
					in_label			=> 'Chemical Workflow', 
					in_parent_sid		=> v_wf_ct_sid, 
					in_flow_alert_class	=> 'chemical',
					out_flow_sid		=> v_workflow_sid
				);
		END;

	-- Create alert templates.
		csr.alert_pkg.GetOrCreateFrame(UNISTR('Default'), v_frame0);
		csr.alert_pkg.SaveFrameBody(v_frame0, 'en', UNISTR('<template><table width="700"><tr><td><div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #C4D9E9;margin-bottom:20px;padding-bottom:10px;">CRedit360 Sustainability data management application</div><table border="0"><tr><td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;"><mergefield name="BODY" /></td></tr></table><div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #C4D9E9;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email <a href="mailto:support@credit360.com" style="color:#C4D9E9;text-decoration:none;">our support team</a></div></td></tr></table></template>'));
		csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Submission alert'), '', v_frame0, 'manual', '', '',  0, v_cat0);
		csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat0, 'en', UNISTR('<template>
	Chemical has been submitted
	</template>'), UNISTR('<template>
	<div><span style="font-family: arial; font-size: small;"><br /></span></div>
	<div><span style="font-family: arial; font-size: small;">Please be informed that site</span> <mergefield name="PROPERTY_NAME" /><span style="font-family: arial; font-size: small;"> </span><span style="font-family: arial; font-size: small;">submitted chemical </span><mergefield name="SUBSTANCE_NAME" />.</div>
	<div><font face="arial" size="2"><br /></font></div>
	<div><font face="arial" size="2">You can access the site <a href="https://philipsdev.credit360.com/property/{REGION_SID}/Philips.ChemicalInventoryTab">here</a>.</font></div>
	</template>'), UNISTR('<template></template>'));
		csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Return alert'), '', v_frame0, 'manual', '', '',  0, v_cat1);
		csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat1, 'en', UNISTR('<template>
	Chemical has been returned
	</template>'), UNISTR('<template>
	<div><br /></div>
	<div>
	<div><span><font face="arial" size="2">Please be informed that your Sector Validation Officer returned chemical </font></span><mergefield name="SUBSTANCE_NAME" /> at <mergefield name="PROPERTY_NAME" />.</div>
	<div><font face="arial" size="2"><br /></font></div>
	<div><font face="arial" size="2">You can access the site <a href="https://philipsdev.credit360.com/property/{REGION_SID}/Philips.ChemicalInventoryTab">here</a>.</font></div>
	</div>
	</template>'), UNISTR('<template></template>'));


		-- Roles
		csr.role_pkg.SetRole('Data Collectors', v_r0);
		csr.role_pkg.SetRole('Sector Validators', v_r1);
		csr.role_pkg.SetRole('Property Manager', v_r2);
	-- Get/Create states.

		-- Get/Create States and store vals here so we don't end up
		-- using different IDs if the place-holders are in different
		-- workflow XML chunks.
		v_s0 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_REGISTERED'), csr.flow_pkg.GetNextStateID);
		v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'APPROVAL_NOT_REQUIRED'), csr.flow_pkg.GetNextStateID);
		v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_SUBMITTED'), csr.flow_pkg.GetNextStateID);
		v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_RETURNED'), csr.flow_pkg.GetNextStateID);
		v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_APPROVED'), csr.flow_pkg.GetNextStateID);
		v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_REJECTED'), csr.flow_pkg.GetNextStateID);
		v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CHEM_REMOVED'), csr.flow_pkg.GetNextStateID);

		
		v_xml_p1 := '<';
		v_str := UNISTR('flow label="Chemical Workflow" cmsTabSid="" default-state-id="$S0$" flow-alert-class="chemical"><state id="$S0$" label="Registered" final="0" colour="" lookup-key="CHEM_REGISTERED"><attributes x="538.5" y="825.5" /><role sid="$R0$" is-editable="1" /><transition flow-state-transition-id="1017" to-state-id="$S2$" verb="Submit" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif"><role sid="$R0$" /><alerts><alert customerAlertTypeId="$CAT0$" toInitiator="0" description="New alert" helperSp=""><role sid="$R1$" /></alert></alerts></transition><transition flow-state-transition-id="1018" to-state-id="$S1$" verb="Auto Approve" helper-sp="" lookup-key="" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state><state id="$S1$" label="12NC used');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('" final="1" colour="" lookup-key="APPROVAL_NOT_REQUIRED"><attributes x="1177.5" y="956.5" /><role sid="$R2$" is-editable="0" /><role sid="$R0$" is-editable="0" /></state><state id="$S2$" label="Submitted" final="0" colour="" lookup-key="CHEM_SUBMITTED"><attributes x="930.5" y="828.5" /><role sid="$R2$" is-editable="0" /><role sid="$R0$" is-editable="0" /><role sid="$R1$" is-editable="1" /><transition flow-state-transition-id="1019" to-state-id="$S5$" verb="Reject" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_cross.gif"><role sid="$R1$" /></transition><transition flow-state-transition-id="1020" to-state-id="$S4$" verb="Approve" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif"><role sid="$R1$" /></transition><transition flow-state-transition-id="1021" to-state-id="$S3$" verb="Return" helpe');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('r-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_return.gif"><role sid="$R1$" /><alerts><alert customerAlertTypeId="$CAT1$" toInitiator="0" description="Return alert" helperSp=""><role sid="$R0$" /></alert></alerts></transition></state><state id="$S3$" label="Returned" final="0" colour="" lookup-key="CHEM_RETURNED"><attributes x="726.5" y="680" /><role sid="$R2$" is-editable="0" /><role sid="$R0$" is-editable="1" /><transition flow-state-transition-id="1022" to-state-id="$S5$" verb="Auto Reject" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="720" button-icon-path="" /><transition flow-state-transition-id="1023" to-state-id="$S2$" verb="Submit" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_tick.gif"><role sid="$R0$" /></transition></state><state id="');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);
		v_str := UNISTR('$S4$" label="Approved" final="1" colour="" lookup-key="CHEM_APPROVED"><attributes x="1176.5" y="836.5" /><role sid="$R2$" is-editable="0" /><role sid="$R1$" is-editable="0" /><transition flow-state-transition-id="1024" to-state-id="$S6$" verb="Remove" helper-sp="" lookup-key="" ask-for-comment="none" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path="/fp/shared/images/ic_delete.gif" /></state><state id="$S5$" label="Rejected" final="1" colour="" lookup-key="CHEM_REJECTED"><attributes x="928.5" y="527.5" /><role sid="$R2$" is-editable="0" /><role sid="$R0$" is-editable="0" /></state><state id="$S6$" label="Removed" final="1" colour="" lookup-key="CHEM_REMOVED"><attributes x="1177.5" y="605" /></state></flow>');
		dbms_lob.writeappend(v_xml_p1, LENGTH(v_str), v_str);


		-- #### Replace place-holders in XML chunk. ####

		-- Alerts
		v_xml_p1 := REPLACE(v_xml_p1, '$CAT0$', v_cat0);
		v_xml_p1 := REPLACE(v_xml_p1, '$CAT1$', v_cat1);

		-- Roles
		v_xml_p1 := REPLACE(v_xml_p1, '$R0$', v_r0);
		v_xml_p1 := REPLACE(v_xml_p1, '$R1$', v_r1);
		v_xml_p1 := REPLACE(v_xml_p1, '$R2$', v_r2);

		-- States
		v_xml_p1 := REPLACE(v_xml_p1, '$S0$', v_s0);
		v_xml_p1 := REPLACE(v_xml_p1, '$S1$', v_s1);
		v_xml_p1 := REPLACE(v_xml_p1, '$S2$', v_s2);
		v_xml_p1 := REPLACE(v_xml_p1, '$S3$', v_s3);
		v_xml_p1 := REPLACE(v_xml_p1, '$S4$', v_s4);
		v_xml_p1 := REPLACE(v_xml_p1, '$S5$', v_s5);
		v_xml_p1 := REPLACE(v_xml_p1, '$S6$', v_s6);


		dbms_lob.createtemporary(v_complete_xml, true);


		v_complete_xml := v_xml_p1;

		csr.flow_pkg.SetFlowFromXml(v_workflow_sid, XMLType(v_complete_xml));
		dbms_lob.freetemporary (v_complete_xml);

		COMMIT;

		UPDATE csr.flow_state SET pos=1 WHERE lookup_key = 'APPROVAL_NOT_REQUIRED';
		UPDATE csr.flow_state SET pos=2 WHERE lookup_key = 'CHEM_REGISTERED';
		UPDATE csr.flow_state SET pos=3 WHERE lookup_key = 'CHEM_SUBMITTED';
		UPDATE csr.flow_state SET pos=4 WHERE lookup_key = 'CHEM_RETURNED';
		UPDATE csr.flow_state SET pos=5 WHERE lookup_key = 'CHEM_APPROVED';
		UPDATE csr.flow_state SET pos=6 WHERE lookup_key = 'CHEM_REJECTED';
		UPDATE csr.flow_state SET pos=7 WHERE lookup_key = 'CHEM_REMOVED';
		
		UPDATE csr.customer
		   SET chemical_flow_sid = v_workflow_sid
		 WHERE app_sid =  v_app_sid;
		 
		 COMMIT;
	END;

	v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
    v_admins_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
    
    v_class_id := security.class_pkg.GetClassId('CSRUserGroup');
    BEGIN
		security.group_pkg.CreateGroupWithClass(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Chem Admins', v_class_id, v_chem_admins_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_chem_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Chem Admins');
	END;
	
    -- make admins members of chem admins
    security.group_pkg.AddMember(v_act_id, v_admins_sid, v_chem_admins_sid);   
    	
		/*** WEB RESOURCE ***/
	v_www := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
    -- create new web-resource
	security.web_pkg.CreateResource(v_act_id, v_www, security.securableobject_pkg.GetSidFromPath(v_act_id, v_www, 'csr/site'), 'chem', v_www_csr_site_chem);	
    -- add chem admin users to web resource    
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_chem), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
		v_chem_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	-- allow registered users
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_csr_site_chem), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, 
		v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		
	v_menu_admin := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid,'menu/admin');
	BEGIN
		security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
			'csr_chem_reports',
			'Chemical reports',
			'/csr/site/chem/reports/reports.acds',
			10, null, v_menu1);
		
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu1), -1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid,
			security.security_pkg.PERMISSION_STANDARD_READ);
		
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	
	-- this grants admins access automatically
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetCasCodes');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetCasRestrictions');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetWaiverStatus');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetSubstances');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetSubstancesReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetFullReport');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetMSDSUploads');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetUngroupedCASCodes');
	csr.sqlreport_pkg.EnableReport('chem.report_pkg.GetRawOutputs');
END;
/

commit;
