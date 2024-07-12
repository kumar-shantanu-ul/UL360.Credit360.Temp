-- Please update version.sql too -- this keeps clean builds in sync
define version=1392
@update_header

create table csr.flow_item_generated_alert
(
	app_sid number(10) default sys_context('security', 'app') not null,
	flow_item_alert_id number(10) not null,
	flow_transition_alert_id number(10) not null,
	from_user_sid number(10) not null,
	to_user_sid number(10) not null,
	constraint pk_flow_item_generated_alert primary key (app_sid, flow_item_alert_id, flow_transition_alert_id, from_user_sid, to_user_sid)
);
alter table csr.flow_item_generated_alert add constraint fk_fl_itm_gn_alrt_fl_itm_alrt
foreign key (app_sid, flow_item_alert_id) references csr.flow_item_alert (app_sid, flow_item_alert_id);
alter table csr.flow_item_generated_alert add constraint fk_fl_itm_gn_alrt_from_user
foreign key (app_sid, from_user_sid) references csr.csr_user (app_sid, csr_user_sid);
alter table csr.flow_item_generated_alert add constraint fk_fl_itm_gn_alrt_to_user
foreign key (app_sid, to_user_sid) references csr.csr_user (app_sid, csr_user_sid);
alter table csr.flow_item_generated_alert add constraint fk_fl_itm_gn_alrt_fl_tr_alrt
foreign key (app_sid, flow_transition_alert_id) references csr.flow_transition_alert (app_sid, flow_transition_alert_id);

	CREATE OR REPLACE VIEW CSR.v$flow_item_alert AS
	     SELECT fia.flow_item_alert_id, ftu.region_sid, ftu.user_sid, fta.flow_state_transition_id,
	        fta.flow_transition_alert_id, fta.customer_alert_type_id, flsf.label from_state_label, flst.label to_state_label, 
	        fsl.flow_state_log_Id, fsl.set_dtm, 
	        fsl.set_by_user_sid, cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
	        cut.csr_user_sid to_user_sid, cut.full_name to_full_name, cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
	        fia.processed_dtm, fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id, fi.survey_response_id, fi.dashboard_instance_id
	       FROM flow_item_alert fia 
	        JOIN flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
	        JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
	        JOIN flow_item fi ON fia.flow_item_id = fi.flow_item_id AND fia.app_sid = fi.app_sid
	        JOIN flow_transition_alert fta 
	            ON fia.flow_transition_alert_id = fta.flow_transition_alert_id 
	            AND fia.app_sid = fta.app_sid
	        JOIN (SELECT DISTINCT ftar.app_sid, ftar.flow_transition_alert_id, rrm.region_sid, rrm.user_sid
	        	    FROM flow_transition_alert_role ftar, region_role_member rrm
	        	   WHERE ftar.app_sid = rrm.app_sid AND ftar.role_sid = rrm.role_sid) ftu
	            ON fta.flow_transition_alert_id = ftu.flow_transition_alert_id 
	            AND fta.app_sid = ftu.app_sid
	        JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
	        JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
	        JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid         
	        JOIN csr_user cut ON ftu.user_sid = cut.csr_user_sid AND ftu.app_sid = cut.app_sid
	      WHERE fia.processed_dtm IS NULL;
	
	CREATE OR REPLACE VIEW csr.v$open_flow_item_alert AS
	     SELECT *
	       FROM v$flow_item_alert
	      WHERE processed_dtm IS NULL;

begin
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='CMS_ALERT_TYPE' and column_name='HELPER_SP') loop
		execute immediate 'alter table csrimp.cms_alert_type drop column helper_sp';
	end loop;
end;
/

grant execute on aspen2.filecache_pkg to mail;

@../flow_pkg
@../flow_body
@../csrimp/imp_body

@update_tail
