-- Please update version.sql too -- this keeps clean builds in sync
define version=2914
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

declare
	v_exists number;
begin
	select count(*) into v_exists from all_indexes where owner='CHAIN' and index_name ='IX_COMPANY_TAB_P_COMPANY_SID';
	if v_exists = 0 then
		execute immediate 'create index chain.ix_company_tab_p_company_sid on chain.company_tab (app_sid, page_company_col_sid)';
	end if;

	select count(*) into v_exists from all_indexes where owner='CHAIN' and index_name ='IX_COMPANY_TAB_U_COMPANY_SID';
	if v_exists = 0 then
		execute immediate 'create index chain.ix_company_tab_u_company_sid on chain.company_tab (app_sid, user_company_col_sid)';
	end if;

	select count(*) into v_exists from all_indexes where owner='CSR' and index_name ='IX_CSR_USER_PRIM_REGION';
	if v_exists = 0 then
		execute immediate 'create index csr.ix_csr_user_prim_region on csr.csr_user (app_sid, primary_region_sid)';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='MAIL_MESSAGE' and column_name='SHA512';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.mail_message add sha512 raw(64) not null';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='NON_COMPLIANCE' and column_name='SUGGESTED_ACTION';
	if v_exists = 0 then
		execute immediate 'alter table csrimp.non_compliance add suggested_action CLOB';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='CHAIN_FILTER_VALUE' and column_name='POS';	
	if v_exists = 0 then
		execute immediate 'alter table csrimp.chain_filter_value add pos number(10)';
	end if;	

	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Controls.ChemicalInventoryTab') and upper(cs_class) = upper('Credit360.Plugins.PluginDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 1, 'Chemicals Inventory',  '/csr/site/property/properties/controls/ChemicalInventoryTab.js', 'Controls.ChemicalInventoryTab', 
			         'Credit360.Plugins.PluginDto', 'This tab shows a list chemicals associated with the property.', null, null, null);
	end if;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Credit360.Calendars.Training') and upper(cs_class) = upper('Credit360.Plugins.PluginDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 12, 'Course schedules',  '/csr/shared/calendar/includes/training.js', 'Credit360.Calendars.Training',
			         'Credit360.Plugins.PluginDto', null, null, null, null);
	end if;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Credit360.Initiatives.AuditLogPanel') and upper(cs_class) = upper('Credit360.Plugins.PluginDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Audit Log',  '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel',
			         'Credit360.Plugins.PluginDto', 'Audit Log', null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Chain.ManageCompany.CompaniesGraph') and upper(cs_class) = upper('Credit360.Chain.Plugins.CompaniesGraphDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 10, 'Supply Chain Graph',  '/csr/site/chain/manageCompany/controls/CompaniesGraph.js', 'Chain.ManageCompany.CompaniesGraph',
			         'Credit360.Chain.Plugins.CompaniesGraphDto', 'This tab shows a graph of the supply chain for the selected company.', null, null, null);
	end if;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Portlets') and upper(cs_class) = upper('Credit360.Property.Plugins.PortalDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 1, 'Portlets',  '/csr/site/property/properties/controls/PortalTab.js', 'Portlets',
			         'Credit360.Property.Plugins.PortalDto', null, null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('MarksAndSpencer.Teamroom.Edit.SettingsPanel') and upper(cs_class) = upper('Credit360.Plugins.PluginDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 6, 'Settings',  '/csr/site/teamroom/controls/edit/SettingsPanel.js', 'MarksAndSpencer.Teamroom.Edit.SettingsPanel',
			         'Credit360.Plugins.PluginDto', null, null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('MarksAndSpencer.Teamroom.MainTab.SettingsPanel') and upper(cs_class) = upper('Credit360.Plugins.PluginDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 7, 'Settings',  '/csr/site/teamroom/controls/mainTab/SettingsPanel.js', 'MarksAndSpencer.Teamroom.MainTab.SettingsPanel',
			         'Credit360.Plugins.PluginDto', null, null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Activity.MyFeedPanel') and upper(cs_class) = upper('Credit360.UserProfile.MyFeedDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 4, 'My feed',  '/csr/site/activity/controls/MyFeedPanel.js', 'Activity.MyFeedPanel',
			         'Credit360.UserProfile.MyFeedDto', null, null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from csr.plugin where app_sid	is null and upper(js_class) = upper('Activity.MyActivitiesPanel') and upper(cs_class) = upper('Credit360.UserProfile.MyActivitiesDto');
	if v_exists = 0 then
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 4, 'My activities',  '/csr/site/activity/controls/MyActivitiesPanel.js', 'Activity.MyActivitiesPanel',
			         'Credit360.UserProfile.MyActivitiesDto', null, null, null, null);
	end if;
	commit;
	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='AUDIT_CLOSURE_TYPE' and column_name='INTERNAL_AUDIT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'alter table csr.audit_closure_type drop column internal_audit_type_id';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSRIMP' and table_name='FLOW_TRANSITION_ALERT' and constraint_name='FK_TRANS_FLALERT_HELPER';
	if v_exists = 1 then
		execute immediate 'alter table csrimp.flow_transition_alert drop constraint fk_trans_flalert_helper';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CHAIN' and table_name='ACTIVITY_INVOLVEMENT' and column_name='ROLE_SID' and nullable='N';
	if v_exists = 1 then
		execute immediate 'alter table chain.activity_involvement modify role_sid null';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CHAIN' and table_name='ACTIVITY_INVOLVEMENT' and column_name='USER_SID' and nullable='N';
	if v_exists = 1 then
		execute immediate 'alter table chain.activity_involvement modify user_sid null';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='CHAIN_ACTIVITY_INVOLVEMENT' and column_name='ROLE_SID' and nullable='N';
	if v_exists = 1 then
		execute immediate 'alter table csrimp.chain_activity_involvement modify role_sid null';
	end if;
	select count(*) into v_exists from all_constraints where owner='CSRIMP' and table_name='CHAIN_ACTIVITY_INVOLVEMENT' and constraint_name='PK_CHAIN_ACTIVITY_USER';
	if v_exists = 1 then
		execute immediate 'alter table csrimp.CHAIN_ACTIVITY_INVOLVEMENT drop constraint PK_CHAIN_ACTIVITY_USER';
	end if;	
	select count(*) into v_exists from all_tab_columns where owner='CSRIMP' and table_name='CHAIN_ACTIVITY_INVOLVEMENT' and column_name='USER_SID' and nullable='N';
	if v_exists = 1 then
		execute immediate 'alter table csrimp.chain_activity_involvement modify user_sid null';
	end if;
	
	begin
		INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from)
				VALUES(63, 'Corporate Reporter questions declined',
					'Sent when a user declines a question which they have been assigned.',
					'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
				);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'BY_FULL_NAME', 'By full name', 'The full name of the user who declined the question', 4);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'BY_FRIENDLY_NAME', 'By friendly name', 'The friendly name of the user who declined the question', 5);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'BY_EMAIL', 'By e-mail', 'The e-mail address of the user who declined the question', 6);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
	exception
		when dup_val_on_index then
			null;
	end;
	begin		
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'ROUTE_STEP_ID', 'Route Step Id', 'The Route Step that was declined', 8);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'SECTION_SID', 'Section Id', 'The Section containing the question that was declined', 9);
	exception
		when dup_val_on_index then
			null;
	end;
	begin		
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'MODULE_TITLE', 'Framework Title', 'The Framework containing the question that was declined', 10);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (63, 1, 'SECTION_TITLE', 'Section Title', 'The Section containing the question that was declined', 11);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE
			(std_alert_type_id, default_alert_frame_id, send_type) 
		VALUES
			(63, 1, 'manual');
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (63,'en',
			'<template>Questions have been declined in CRedit360</template>',
			'<template>
			<p>Hello <mergefield name="TO_FULL_NAME"/>,</p>
			<p>The following questions have been declined by the assigned user and returned to the previous step. The user has been removed from the route.</p>
			<ul>
	            		<mergefield name="ITEMS"/>
			</ul>
			<p>To view the changes, please go to this web page:</p>
			<p><mergefield name="MANAGE_QUESTIONS_LINK"/></p>
			<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
			</template>',
			'<template><li>Framework <mergefield name="MODULE_TITLE"/>, Section <mergefield name="SECTION_TITLE"/> - declined by <mergefield name="BY_FULL_NAME"/> (<mergefield name="BY_EMAIL"/>)</li></template>'
			);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

alter table csrimp.non_comp_default_issue drop constraint CHK_NON_COMP_DEF_ISS_DUE_UNIT;
alter table csrimp.non_comp_default_issue add
	CONSTRAINT CHK_NON_COMP_DEF_ISS_DUE_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m'));

grant insert,select,update,delete on csrimp.rss_cache to web_user;

alter table csrimp.FLOW_TRANSITION_ALERT drop constraint FK_FL_TRANS_ALERT_IS;
alter table csrimp.FLOW_TRANSITION_ALERT add constraint FK_FL_TRANS_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body

@update_tail
