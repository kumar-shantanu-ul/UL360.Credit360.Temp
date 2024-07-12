-- Please update version.sql too -- this keeps clean builds in sync
define version=1381
@update_header

create table csr.cms_alert_helper (
	app_sid							number(10) default sys_context('security','app') not null,
	helper_sp						varchar2(100) not null,
	tab_sid							number(10) not null,
	description						varchar2(500) not null,
	constraint pk_cms_alert_helper primary key (app_sid, helper_sp)
);
alter table csr.cms_alert_helper add constraint fk_cms_alert_helper_cms_tab
foreign key (app_sid, tab_sid) references cms.tab (app_sid, tab_sid);
create index csr.ix_cms_alert_helper_tab on csr.cms_alert_helper (app_sid, tab_sid);

create sequence csr.flow_transition_alert_id_seq;

alter table csr.flow_transition_alert add flow_transition_alert_id number(10) ;
alter table csr.flow_transition_alert_role add flow_transition_alert_id number(10);
alter table csr.flow_item_alert add flow_transition_alert_id number(10);

begin
	for r in (select * from csr.flow_transition_alert) loop
		update csr.flow_transition_alert
		   set flow_transition_alert_id = csr.flow_transition_alert_id_seq.nextval
		 where app_sid = r.app_sid and flow_state_transition_id = r.flow_state_transition_id
		   and customer_alert_type_id = r.customer_alert_type_id;
		   
		update csr.flow_transition_alert_role
		   set flow_transition_alert_id = csr.flow_transition_alert_id_seq.currval
		 where app_sid = r.app_sid and flow_state_transition_id = r.flow_state_transition_id
		   and customer_alert_type_id = r.customer_alert_type_id;

		update csr.flow_item_alert
		   set flow_transition_alert_id = csr.flow_transition_alert_id_seq.currval
		 where app_sid = r.app_sid and flow_state_transition_id = r.flow_state_transition_id
		   and customer_alert_type_id = r.customer_alert_type_id;
	end loop;
end;
/

alter table csr.flow_transition_alert modify flow_transition_alert_id not null;
alter table csr.flow_transition_alert_role modify flow_transition_alert_id not null;
alter table csr.flow_item_alert modify flow_transition_alert_id not null;

alter table csr.flow_transition_alert_role drop column flow_state_transition_id cascade constraints;
alter table csr.flow_transition_alert_role drop column customer_alert_type_id cascade constraints;

alter table csr.flow_item_alert drop column flow_state_transition_id cascade constraints;
alter table csr.flow_item_alert drop column customer_alert_type_id cascade constraints;

alter table csr.flow_transition_alert drop primary key cascade drop index;
alter table csr.flow_transition_alert add constraint pk_flow_transition_alert primary key (app_sid, flow_transition_alert_id);

alter table csr.flow_transition_alert_role add constraint fk_flow_tr_al_role_flow_tr_al
foreign key (app_sid, flow_transition_alert_id) references csr.flow_transition_alert (app_sid, flow_transition_alert_id);
alter table csr.flow_transition_alert_role add constraint pk_flow_transition_alert_role
primary key (app_sid, flow_transition_alert_id, role_sid);

alter table csr.flow_item_alert add constraint fk_flow_itm_alrt_flow_tr_alrt
foreign key (app_sid, flow_transition_alert_id) references csr.flow_transition_alert (app_sid, flow_transition_alert_id);

alter table csr.flow_transition_alert add description varchar2(500);
alter table csr.flow_transition_alert add deleted number(1) default 0 not null;
alter table csr.flow_transition_alert add constraint ck_flow_trans_alert_deleted check (deleted in (0,1));

alter table csr.flow_transition_alert add helper_sp varchar2(100);
alter table csr.flow_transition_alert add constraint fk_trans_alert_helper
foreign key (app_sid, helper_sp) references csr.cms_alert_helper (app_sid, helper_sp);
create index csr.ix_flow_trans_alert_helper on csr.flow_transition_alert (app_sid, helper_sp);

create table csr.cms_alert_type (
	app_sid							number(10) default sys_context('security','app') not null,
	tab_sid							number(10) not null,
	customer_alert_type_id			number(10) not null,
	description						varchar2(500) not null,
	constraint pk_cms_alert_type primary key (app_sid, tab_sid, customer_alert_type_id)
);
alter table csr.cms_alert_type add constraint fk_cms_alert_type_cms_tab
foreign key (app_sid, tab_sid) references cms.tab (app_sid, tab_sid);
alter table csr.cms_alert_type add constraint fk_cms_alert_type_cat
foreign key (app_sid, customer_alert_type_id) references csr.customer_alert_type (app_sid, customer_alert_type_id);
create index csr.ix_cms_alert_type_cat on csr.cms_alert_type (app_sid, customer_alert_type_id);

-- hmmm -- possibly need to get rid of flow_alert_type
alter table csr.flow_transition_alert drop constraint FK_FL_AL_TYPE_FTA;

delete from csrimp.csrimp_session;
alter table csrimp.flow_transition_alert add flow_transition_alert_id number(10) not null;
alter table csrimp.flow_transition_alert add helper_sp varchar2(100);
alter table csrimp.flow_transition_alert_role add flow_transition_alert_id number(10) not null;
alter table csrimp.flow_item_alert add flow_transition_alert_id number(10) not null;
alter table csrimp.flow_transition_alert_role drop column flow_state_transition_id cascade constraints;
alter table csrimp.flow_transition_alert_role drop column customer_alert_type_id cascade constraints;
alter table csrimp.flow_item_alert drop column flow_state_transition_id cascade constraints;
alter table csrimp.flow_item_alert drop column customer_alert_type_id cascade constraints;
alter table csrimp.flow_transition_alert add description varchar2(500);
alter table csrimp.flow_transition_alert add deleted number(1) not null;
alter table csrimp.flow_transition_alert add constraint ck_flow_trans_alert_deleted check (deleted in (0,1));

alter table csrimp.flow_transition_alert drop primary key cascade drop index;
alter table csrimp.flow_transition_alert add constraint pk_flow_transition_alert primary key (csrimp_session_id, flow_transition_alert_id);
begin
	for r in (select constraint_name from all_constraints where owner='CSRIMP' and table_name='FLOW_TRANSITION_ALERT_ROLE' and constraint_type = 'P') loop
		execute immediate 'alter table csrimp.flow_transition_alert_role drop primary key cascade drop index';
	end loop;
end;
/
alter table csrimp.flow_transition_alert_role add constraint pk_flow_transition_alert_role
primary key (csrimp_session_id, flow_transition_alert_id, role_sid);

CREATE TABLE csrimp.map_flow_transition_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_transition_alert_id	NUMBER(10) NOT NULL,
	new_flow_transition_alert_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_transition_alert PRIMARY KEY (old_flow_transition_alert_id) USING INDEX,
	CONSTRAINT uk_map_flow_transition_alert UNIQUE (new_flow_transition_alert_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_TRANS_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

create table csrimp.cms_alert_helper (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	helper_sp						varchar2(100) not null,
	tab_sid							number(10) not null,
	description						varchar2(500) not null,
	constraint pk_cms_alert_helper primary key (helper_sp),
    CONSTRAINT FK_CMS_ALERT_HELPER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

create table csrimp.cms_alert_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tab_sid							number(10) not null,
	customer_alert_type_id			number(10) not null,
	description						varchar2(500) not null,
	constraint pk_cms_alert_type primary key (tab_sid, customer_alert_type_id),
    CONSTRAINT FK_CMS_ALERT_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE	
);

grant select,insert,update,delete on csrimp.cms_alert_helper to web_user;
grant select,insert,update,delete on csrimp.cms_alert_type to web_user;
grant insert on csr.cms_alert_type to csrimp;
grant insert on csr.cms_alert_helper to csrimp;

grant select on csr.flow_transition_alert_id_seq to csrimp;

CREATE OR REPLACE VIEW CSR.v$open_flow_item_alert AS
     SELECT fia.flow_item_alert_id, rrm.region_sid, rrm.user_sid, fta.flow_state_transition_id,
        fta.customer_alert_type_id, flsf.label from_state_label, flst.label to_state_label, 
        fsl.flow_state_log_Id, fsl.set_dtm, 
        fsl.set_by_user_sid, cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
        cut.csr_user_sid to_user_sid, cut.full_name to_full_name, cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
        fi.*
       FROM flow_item_alert fia 
        JOIN flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
        JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
        JOIN flow_item fi ON fia.flow_item_id = fi.flow_item_id AND fia.app_sid = fi.app_sid
        JOIN flow_transition_alert fta 
            ON fia.flow_transition_alert_id = fta.flow_transition_alert_id 
            AND fia.app_sid = fta.app_sid
        JOIN flow_transition_alert_role ftar 
            ON fta.flow_transition_alert_id = ftar.flow_transition_alert_id 
            AND fta.app_sid = ftar.app_sid
        JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
        JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
        JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid         
        JOIN role ro ON ftar.role_sid = ro.role_sid AND ftar.app_sid = ro.app_sid
        JOIN region_role_member rrm ON ro.role_sid = rrm.role_sid AND ro.app_sid = rrm.app_sid
        JOIN csr_user cut ON rrm.user_sid = cut.csr_user_sid AND rrm.app_sid = cut.app_sid
      WHERE fia.processed_dtm IS NULL;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'CMS_ALERT_TYPE',
		'CMS_ALERT_HELPER'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

-- although not normally a good plan this only affects csrimp, not the website
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE pf_owner = 'CSRIMP' AND function IN ('SESSIONIDCHECK')
		   AND object_owner IN ('CSRIMP', 'CMS')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
END;
/

@../alert_body
@../schema_pkg
@../schema_body
@../csrimp/imp_body
@../flow_pkg
@../flow_body
@../csr_data_body
@../section_body
@../../../aspen2/cms/db/tab_body

@update_tail
