-- Please update version.sql too -- this keeps clean builds in sync
define version=2187
@update_header
set verify off
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

grant references on security.application to aspen2;

create table aspen2.application
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	menu_path						varchar2(512),
	metadata_connection_string		varchar2(512),
	commerce_store_path				varchar2(512),
	admin_email						varchar2(512),
	logon_url						varchar2(512),
	referer_url						varchar2(512),
	confirm_user_details			number(1) default 1 not null,
	default_stylesheet				varchar2(512),
	default_url						varchar2(512),
	default_css						varchar2(512),
	edit_css						varchar2(512),
	logon_autocomplete				number(1) default 1 not null,
	constraint pk_application primary key (app_sid),
	constraint fk_aspen2_application foreign key (app_sid)
	references security.application (application_sid_id)
);

CREATE TABLE CSRIMP.ASPEN2_APPLICATION
(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	MENU_PATH						VARCHAR2(512),
	METADATA_CONNECTION_STRING		VARCHAR2(512),
	COMMERCE_STORE_PATH				VARCHAR2(512),
	ADMIN_EMAIL						VARCHAR2(512),
	LOGON_URL						VARCHAR2(512),
	REFERER_URL						VARCHAR2(512),
	CONFIRM_USER_DETAILS			NUMBER(1) DEFAULT 1 NOT NULL,
	DEFAULT_STYLESHEET				VARCHAR2(512),
	DEFAULT_URL						VARCHAR2(512),
	DEFAULT_CSS						VARCHAR2(512),
	EDIT_CSS						VARCHAR2(512),
	LOGON_AUTOCOMPLETE				NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT PK_ASPEN2_APPLICATION PRIMARY KEY (CSRIMP_SESSION_ID),
    CONSTRAINT FK_ASPEN2_APPLICATION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

insert into aspen2.application (app_sid, menu_path, metadata_connection_string, commerce_store_path, admin_email,
	logon_url, referer_url, confirm_user_details, default_stylesheet, default_url, default_css, edit_css,
	logon_autocomplete)
	select so.sid_id,
		   max(case when att.name='menu-path' then soa.string_value else null end) default_stylesheet,
		   max(case when att.name='metadata-connectionstring' then soa.string_value else null end) metadata_connection_string,
		   max(case when att.name='commerce-store-path' then soa.string_value else null end) commerce_store_path,
		   max(case when att.name='admin-email' then soa.string_value else null end) admin_email,
		   max(case when att.name='logon-url' then soa.string_value else null end) logon_url,
		   max(case when att.name='referer-url' then soa.string_value else null end) referer_url,
		   max(case when att.name='confirm-user-details' then soa.number_value else 1 end) confirm_user_details,
		   max(case when att.name='default-stylesheet' then soa.string_value else null end) default_stylesheet,
		   max(case when att.name='default-url' then soa.string_value else null end) default_url,
		   max(case when att.name='default-css' then soa.string_value else null end) default_css,
		   max(case when att.name='edit-css' then soa.string_value else null end) edit_css,
		   max(case when att.name='login-autocomplete' then soa.number_value else 1 end) logon_autocomplete 	   
	  from (select *
			  from security.securable_object_class soc
				   start with lower(class_name)=lower('AspenApp') connect by prior class_id = parent_class_id) cls
	  join security.securable_object so on so.class_id = cls.class_id
	  join security.application app on so.sid_id = app.application_sid_id
	  join security.attributes att on cls.class_id = att.class_id
	  left join security.securable_object_attributes soa on so.sid_id = soa.sid_id and soa.attribute_id = att.attribute_id
	  group by so.sid_id;

delete from security.securable_object_attributes
 where attribute_id in (
 		select attribute_id
 		  from security.attributes
 		 where class_id in (
	  		select class_id
			  from security.securable_object_class soc
				   start with lower(class_name)=lower('AspenApp') connect by prior class_id = parent_class_id
		 ) 
		);
		
delete from security.attributes
 where class_id in (
	select class_id
	  from security.securable_object_class soc
		   start with lower(class_name)=lower('AspenApp') connect by prior class_id = parent_class_id
 );

alter table csr.customer add start_month number(2) default 1 not null;
alter table csr.customer add constraint ck_cust_start_month check (start_month between 1 and 12);
alter table csr.customer add chart_xsl varchar2(512);
alter table csr.customer add show_region_disposal_date number(1) default 1 not null;
alter table csr.customer add constraint ck_cust_sho_region_disp_date check (show_region_disposal_date in (0, 1));
alter table csr.customer add data_explorer_show_markers number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_show_de_markers check (data_explorer_show_markers in (0, 1));
alter table csr.customer add show_all_sheets_for_rep_prd number(1) default 1 not null;
alter table csr.customer add constraint ck_cust_sho_all_sht_rep_prd check (show_all_sheets_for_rep_prd in (0, 1));
alter table csr.customer add deleg_browser_show_rag number(1) default 1 not null;
alter table csr.customer add constraint ck_cust_deleg_browser_sho_rag check (deleg_browser_show_rag in (0, 1));
alter table csr.customer add tgtdash_ignore_estimated number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_ignore_est check (tgtdash_ignore_estimated in (0, 1));
alter table csr.customer add tgtdash_hide_totals number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_hide_totals check (tgtdash_hide_totals in (0, 1));
alter table csr.customer add tgtdash_show_chg_from_last_yr number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdsh_sho_chg_lst_yr check (tgtdash_show_chg_from_last_yr in (0, 1));
alter table csr.customer add tgtdash_show_last_year number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_show_last_yr check (tgtdash_show_last_year in (0, 1));
alter table csr.customer add tgtdash_colour_text number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_colour_text check (tgtdash_colour_text in (0, 1));
alter table csr.customer add tgtdash_show_target_first number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_sho_tgt_first check (tgtdash_show_target_first in (0, 1));
alter table csr.customer add tgtdash_show_flash number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_tgtdash_show_flash check (tgtdash_show_flash in (0, 1));
alter table csr.customer add use_region_events number(1) default 1 not null;
alter table csr.customer add constraint ck_cust_use_region_events check (use_region_events in (0, 1));
alter table csr.customer add metering_enabled number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_metering_enabled check (metering_enabled in (0, 1));
alter table csr.customer add crc_metering_enabled number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_crc_metering_enabled check (crc_metering_enabled in (0, 1));
alter table csr.customer add crc_metering_ind_core number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_crc_metering_ind_core check (crc_metering_ind_core in (0, 1));
alter table csr.customer add crc_metering_auto_core number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_crc_meterng_auto_core check (crc_metering_auto_core in (0, 1));
alter table csr.customer add iss_view_src_to_deepest_sheet number(1) default 0 not null;
alter table csr.customer add constraint ck_cust_iss_vw_src_dpst_sht check (iss_view_src_to_deepest_sheet in (0, 1));
alter table csr.customer add delegs_always_show_adv_opts number(1) default 0 not null;
alter table csr.customer add constraint ck_dlgs_always_show_adv_opts check (delegs_always_show_adv_opts in (0, 1));
alter table csr.customer add default_admin_css varchar2(512);

alter table csrimp.customer add start_month number(2) default 1 not null;
alter table csrimp.customer add constraint ck_cust_start_month check (start_month between 1 and 12);
alter table csrimp.customer add chart_xsl varchar2(512);
alter table csrimp.customer add show_region_disposal_date number(1) default 1 not null;
alter table csrimp.customer add constraint ck_cust_sho_region_disp_date check (show_region_disposal_date in (0, 1));
alter table csrimp.customer add data_explorer_show_markers number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_show_de_markers check (data_explorer_show_markers in (0, 1));
alter table csrimp.customer add show_all_sheets_for_rep_prd number(1) default 1 not null;
alter table csrimp.customer add constraint ck_cust_sho_all_sht_rep_prd check (show_all_sheets_for_rep_prd in (0, 1));
alter table csrimp.customer add deleg_browser_show_rag number(1) default 1 not null;
alter table csrimp.customer add constraint ck_cust_deleg_browser_sho_rag check (deleg_browser_show_rag in (0, 1));
alter table csrimp.customer add tgtdash_ignore_estimated number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_ignore_est check (tgtdash_ignore_estimated in (0, 1));
alter table csrimp.customer add tgtdash_hide_totals number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_hide_totals check (tgtdash_hide_totals in (0, 1));
alter table csrimp.customer add tgtdash_show_chg_from_last_yr number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdsh_sho_chg_lst_yr check (tgtdash_show_chg_from_last_yr in (0, 1));
alter table csrimp.customer add tgtdash_show_last_year number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_show_last_yr check (tgtdash_show_last_year in (0, 1));
alter table csrimp.customer add tgtdash_colour_text number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_colour_text check (tgtdash_colour_text in (0, 1));
alter table csrimp.customer add tgtdash_show_target_first number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_sho_tgt_first check (tgtdash_show_target_first in (0, 1));
alter table csrimp.customer add tgtdash_show_flash number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_tgtdash_show_flash check (tgtdash_show_flash in (0, 1));
alter table csrimp.customer add use_region_events number(1) default 1 not null;
alter table csrimp.customer add constraint ck_cust_use_region_events check (use_region_events in (0, 1));
alter table csrimp.customer add metering_enabled number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_metering_enabled check (metering_enabled in (0, 1));
alter table csrimp.customer add crc_metering_enabled number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_crc_metering_enabled check (crc_metering_enabled in (0, 1));
alter table csrimp.customer add crc_metering_ind_core number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_crc_metering_ind_core check (crc_metering_ind_core in (0, 1));
alter table csrimp.customer add crc_metering_auto_core number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_crc_meterng_auto_core check (crc_metering_auto_core in (0, 1));
alter table csrimp.customer add iss_view_src_to_deepest_sheet number(1) default 0 not null;
alter table csrimp.customer add constraint ck_cust_iss_vw_src_dpst_sht check (iss_view_src_to_deepest_sheet in (0, 1));
alter table csrimp.customer add delegs_always_show_adv_opts number(1) default 0 not null;
alter table csrimp.customer add constraint ck_dlgs_always_show_adv_opts check (delegs_always_show_adv_opts in (0, 1));
alter table csrimp.customer add default_admin_css varchar2(512);

begin
	for r in (
		select so.sid_id, max(so.parent_sid_id) app_sid,
		max(case when att.name='region-disposal-date' then soa.number_value else null end) region_disposal_date,
		max(case when att.name='dataexplorer-show-markers' then soa.number_value else null end) dataexplorer_show_markers,
		max(case when att.name='show-all-sheets-for-current-reporting-period' then soa.number_value else null end) show_all_shts_cur_rep_period,
		max(case when att.name='delegbrowser-show-rag' then soa.number_value else null end) delegbrowser_show_rag,
		max(case when att.name='current-year' then soa.number_value else null end) current_year,
		max(case when att.name='targetdashboard-ignore-estimated' then soa.number_value else null end) tgtdash_ignore_estimated,
		max(case when att.name='targetdashboard-hide-totals' then soa.number_value else null end) tgtdash_hide_totals,
		max(case when att.name='targetdashboard-show-change-from-last-year' then soa.number_value else null end) tgtdash_show_chg_from_last_yr,
		max(case when att.name='targetdashboard-show-last-year' then soa.number_value else null end) tgtdash_show_last_year,
		max(case when att.name='targetdashboard-colour-text' then soa.number_value else null end) tgtdash_colour_text,
		max(case when att.name='targetdashboard-show-target-first' then soa.number_value else null end) tgtdash_show_target_first,
		max(case when att.name='targetdashboard-show-flash' then soa.number_value else null end) tgtdash_show_flash,
		max(case when att.name='region-events' then soa.number_value else null end) region_events,
		max(case when att.name='modules-metering' then soa.number_value else null end) modules_metering,
		max(case when att.name='issue-view-source-goes-to-deepest-sheet' then soa.number_value else null end) iss_view_src_to_deepest_sheet,
		max(case when att.name='crc-metering-enabled' then soa.number_value else null end) crc_metering_enabled,
		max(case when att.name='crc-metering-ind-core' then soa.number_value else null end) crc_metering_ind_core,
		max(case when att.name='crc-metering-auto-core' then soa.number_value else null end) crc_metering_auto_core,
		max(case when att.name='basestyle-xml-path' then soa.string_value else null end) basestyle_xml_path,
		max(case when att.name='ind-metadata' then soa.string_value else null end) ind_metadata,
		max(case when att.name='region-metadata' then soa.string_value else null end) region_metadata,
		max(case when att.name='user-metadata' then soa.string_value else null end) user_metadata,
		max(case when att.name='data-pane-xsl' then soa.string_value else null end) data_pane_xsl,
		max(case when att.name='default-admin-css' then soa.string_value else null end) default_admin_css,
		max(case when att.name='delegations-always-show-advanced-options' then soa.number_value else null end) delegs_always_show_adv_opts,
		max(case when att.name='date-format-m' then soa.string_value else null end) date_format_m,
		max(case when att.name='date-format-q' then soa.string_value else null end) date_format_q,
		max(case when att.name='date-format-y' then soa.string_value else null end) date_format_y,
		max(case when att.name='start-month' then soa.number_value else null end) start_month,
		max(case when att.name='dates-helper' then soa.string_value else null end) dates_helper,
		max(case when att.name='chart-xsl' then soa.string_value else null end) chart_xsl
		  from (select *
				  from security.securable_object_class soc
					   start with lower(class_name)=lower('CSRData') connect by prior class_id = parent_class_id) cls
		  join security.securable_object so on so.class_id = cls.class_id
		  join security.attributes att on cls.class_id = att.class_id
		  left join security.securable_object_attributes soa on so.sid_id = soa.sid_id and soa.attribute_id = att.attribute_id
			group by so.sid_id) loop

		--dbms_output.put_line('doing '||r.app_sid);
		update csr.customer
		   set show_region_disposal_date = nvl(r.region_disposal_date, 0),
		   	   data_explorer_show_markers = nvl(r.dataexplorer_show_markers, 0),
		   	   show_all_sheets_for_rep_prd = nvl(r.show_all_shts_cur_rep_period, 0),
		   	   deleg_browser_show_rag = nvl(r.delegbrowser_show_rag, 0),
		   	   tgtdash_ignore_estimated = nvl(r.tgtdash_ignore_estimated, 0),
		   	   tgtdash_hide_totals = nvl(r.tgtdash_hide_totals, 0),
		   	   tgtdash_show_chg_from_last_yr = nvl(r.tgtdash_show_chg_from_last_yr, 0),
		   	   tgtdash_show_last_year = nvl(r.tgtdash_show_last_year, 0),
		   	   tgtdash_colour_text = nvl(r.tgtdash_colour_text, 0),
		   	   tgtdash_show_target_first = nvl(r.tgtdash_show_target_first, 0),
		   	   tgtdash_show_flash = nvl(r.tgtdash_show_flash, 0),
		   	   use_region_events = nvl(r.region_events, 0),
		   	   start_month = nvl(r.start_month, 1),
			   chart_xsl = r.chart_xsl,			   
			   metering_enabled = nvl(r.modules_metering, 0),
			   crc_metering_enabled = nvl(r.crc_metering_enabled, 0),
			   crc_metering_ind_core = nvl(r.crc_metering_ind_core, 0),
			   crc_metering_auto_core = nvl(r.crc_metering_auto_core, 0),
			   iss_view_src_to_deepest_sheet = nvl(r.iss_view_src_to_deepest_sheet, 0),
			   delegs_always_show_adv_opts = nvl(r.delegs_always_show_adv_opts, 0),
			   default_admin_css = r.default_admin_css
		 where app_sid = r.app_sid;
	end loop;
end;
/

grant select, insert, update, delete on aspen2.application to csrimp;
grant select, update on aspen2.application to csr;
grant select on security.website to aspen2;

declare
	v_app_class_id number;
	v_data_class_id number;
begin
	security.user_pkg.logonadmin;
	v_data_class_id := security.class_pkg.getclassid('CSRData');
	v_app_class_id := security.class_pkg.getclassid('CSRApp');

	-- add an alter schema permission to the app object
	security.class_pkg.AddPermission(sys_context('security','act'), v_app_class_id, 
		262144 /*csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA*/, 'Alter schema');
	security.class_pkg.createmapping(sys_context('security','act'), 
		security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, v_app_class_id, 
		262144 /*csr.Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA*/);

	-- add alter schema permissions to the app object where it was granted on the csr data object
	for r in (select so.dacl_id, c.app_sid, c.host
				from csr.customer c, security.securable_object so
			   where so.sid_id = c.app_sid) loop
		for s in (
			select *
			  from security.acl
			  where acl_id in (
					select dacl_id 
					  from security.securable_object 
					 where parent_sid_id = r.app_sid
					   and lower(name)='csr'
			  ) and bitand(permission_set, 262144) != 0
		) loop
			--dbms_output.put_line('doing ' ||r.host||' adding to '||r.dacl_id||' '||s.ace_type||' '||s.sid_id);
			security.acl_pkg.addace(sys_context('security','act'), r.dacl_id, 0, s.ace_type,
				security.security_pkg.ACE_FLAG_DEFAULT, s.sid_id, 262144);
		end loop;
	end loop;
	
	-- clean up csr objects
	for r in (select sid_id from security.securable_object where class_id = v_data_class_id) loop
		update security.securable_object
		   set class_id = security.security_pkg.SO_CONTAINER
		 where sid_id = r.sid_id;
		dbms_output.put_line('delete '||r.sid_id);
		security.securableobject_pkg.deleteso(sys_context('security','act'), r.sid_id);
	end loop;
	
	security.class_pkg.DeleteClass(sys_context('security','act'), v_data_class_id);
end;
/

/*
begin
	for r in (select 1 from all_objects where objecT_name = 'CSR_DATA_PKG' and owner='CSR' and object_type='PACKAGE') loop
		execute immediate 'drop package csr.csr_data_pkg';
	end loop;
end;
*/

create or replace package csr.enable_pkg as end;
/
grant execute on csr.enable_pkg to security;

@../../../aspen2/db/aspenapp_pkg
@../csr_app_pkg
@../csr_data_pkg
@../enable_pkg
@../schema_pkg
@../indicator_pkg

@../../../aspen2/db/aspenapp_body
@../csr_app_body
@../csr_data_body
@../schema_body
@../csrimp/imp_body
@../accuracy_body
@../alert_body
@../chain/setup_body
@../delegation_body
@../enable_body
@../indicator_body
@../issue_body
@../meter_alarm_body
@../meter_body
@../role_body
@../schema_body
@../tag_body
@../template_body

@update_tail
