-- Please update version.sql too -- this keeps clean builds in sync
define version=1194
@update_header

create table csr.region_description (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	region_sid		number(10) not null,
	lang 			varchar2(10) not null,
	description		varchar2(1023) not null,
	constraint pk_region_description primary key (app_sid, region_sid, lang),
	constraint fk_region_description_region foreign key (app_sid, region_sid)
	references csr.region (app_sid, region_sid),
	constraint fk_region_desc_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.ix_region_description_lang on csr.region_description (app_sid, lang);

-- insert translations of whatever text was in the region table
insert into csr.region_description (app_sid, region_sid, lang, description)
	select i.app_sid, i.region_sid, ts.lang, NVL(tr.translated, NVL(i.description, i.name)) description
	  from csr.region i
	  join aspen2.translation_set ts on ts.application_sid = i.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and i.description = tr.original
	  order by app_sid, region_sid, lang;

create table csr.backup_region_description as
	select app_sid, region_sid, description
	  from csr.region;
	   
alter table csr.region drop column description;

-- alter table csr.region add description varchar2(1023);
-- update csr.region i set description = (select description from csr.backup_region_description bi where bi.app_sid = i.app_sid and bi.region_sid = i.region_sid);

create table csr.dataview_region_description (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	dataview_sid	number(10) not null,
	region_sid		number(10) not null,
	lang 			varchar2(10) not null,
	description		varchar2(1023) not null,
	constraint pk_dataview_region_desc primary key (app_sid, dataview_sid, region_sid, lang),
	constraint fk_dv_reg_desc_dv_reg_member foreign key (app_sid, dataview_sid, region_sid)
	references csr.dataview_region_member (app_sid, dataview_sid, region_sid),
	constraint fk_dv_reg_desc_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.dataview_reg_desc_lang on csr.dataview_region_description (app_sid, lang);

-- insert translations of whatever text was in the dataview_region_member table
-- but only where they differ from the original region descriptions
insert into csr.dataview_region_description (app_sid, dataview_sid, region_sid, lang, description)
	select di.app_sid, di.dataview_sid, di.region_sid, ts.lang, NVL(tr.translated, di.description) description
	  from csr.dataview_region_member di
	  join aspen2.translation_set ts on ts.application_sid = di.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
	  where NVL(tr.translated, di.description) IS NOT NULL
	 minus 
	 select id.app_sid, di.dataview_sid, di.region_sid, id.lang, id.description
	   from csr.region_description id, csr.dataview_region_member di
	  where di.app_sid = id.app_sid and di.region_sid = id.region_sid;
				
create table csr.backup_dataview_region_member as
	select *
	  from csr.dataview_region_member;

alter table csr.dataview_region_member drop column description;

create table csr.delegation_region_description (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	delegation_sid	number(10) not null,
	region_sid		number(10) not null,
	lang 			varchar2(10) not null,
	description		varchar2(1023) not null,
	constraint pk_delegation_region_desc primary key (app_sid, delegation_sid, region_sid, lang),
	constraint fk_deleg_reg_desc_deleg_reg foreign key (app_sid, delegation_sid, region_sid)
	references csr.delegation_region (app_sid, delegation_sid, region_sid),
	constraint fk_deleg_reg_desc_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.ix_delegation_reg_desc_lang on csr.delegation_region_description (app_sid, lang);

insert into csr.delegation_region_description (app_sid, delegation_sid, region_sid, lang, description)
	select di.app_sid, di.delegation_sid, di.region_sid, ts.lang, COALESCE(tr.translated, di.description, id.description) description
	  from csr.delegation_region di
	  join aspen2.translation_set ts on ts.application_sid = di.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
	  left join csr.region_description id on di.app_sid = id.app_sid and di.region_sid = id.region_sid and ts.lang = id.lang
	  where COALESCE(tr.translated, di.description, id.description) IS NOT NULL
	 minus 
	 select id.app_sid, di.delegation_sid, di.region_sid, id.lang, id.description
	   from csr.region_description id, csr.delegation_region di
	  where di.app_sid = id.app_sid and di.region_sid = id.region_sid
	  ;

create table csr.backup_delegation_region as
	select *
	  from csr.delegation_region;
	   
alter table csr.delegation_region drop column description;

begin
	for r in (select 1 from all_tab_columns where owner='CSR' and table_name='REGION' and column_name='PCT_OWNERSHIP') loop
		execute immediate 'alter table csr.region drop column pct_ownership';
	end loop;
end;
/


create or replace view csr.v$region as
	select r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, rd.description, r.active, 
		   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm, r.region_type, 
		   r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, 
		   r.geo_type, r.map_entity, r.egrid_ref, r.egrid_ref_overridden
	  from region r, region_description rd
	 where r.app_sid = rd.app_sid and r.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_region as
	select dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility
	  from delegation_region dr
	  join region_description rd
	    on dr.app_sid = rd.app_sid and dr.region_sid = rd.region_sid 
	   and rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_region_description drd
	    on dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   and dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.imp_val_mapped 
	(ind_description, region_description, ind_sid, region_sid, imp_ind_description, imp_region_description, 
	 imp_val_id, imp_ind_id, imp_region_id, unknown, start_dtm, end_dtm, val, file_sid, imp_session_sid, 
	 set_val_id, imp_measure_id, tolerance_type, pct_upper_tolerance, pct_lower_tolerance, note, lookup_key, 
	 map_entity, roll_forward, acquisition_dtm, a, b, c, calc_description, normalize, do_temporal_aggregation) as	 
	select i.description, r.description, i.ind_sid, r.region_sid, ii.description, ir.description, iv.imp_val_id, 
	       iv.imp_ind_id, iv.imp_region_id, iv.unknown, iv.start_dtm, iv.end_dtm, iv.val, iv.file_sid, iv.imp_session_sid, 
	       iv.set_val_id, iv.imp_measure_id, i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance, iv.note, 
	       r.lookup_key, r.map_entity, i.roll_forward, r.acquisition_dtm, iv.a, iv.b, iv.c, i.calc_description, 
	       i.normalize, i.do_temporal_aggregation
	  from imp_val iv, imp_ind ii, imp_region ir, v$ind i, v$region r
	 where iv.app_sid = ii.app_sid and iv.imp_ind_id = ii.imp_ind_id 
	   and iv.app_sid = ir.app_sid and iv.imp_region_id = ir.imp_region_id
	   and ii.app_sid = i.app_sid and ii.maps_to_ind_sid = i.ind_sid 
	   and ir.app_sid = r.app_sid and ir.maps_to_region_sid = r.region_sid 
;

CREATE OR REPLACE VIEW csr.audit_val_log AS
	SELECT changed_dtm audit_date, r.app_sid, 6 audit_type_id, vc.ind_sid object_sid, changed_by_sid user_sid,
	 	   'Set "{0}" ("{1}") to {2}: '||reason description, i.description param_1, r.description param_2, val_number param_3
	  FROM val_change vc, v$region r, v$ind i
	 WHERE vc.app_sid = r.app_sid AND vc.region_sid = r.region_sid
	   AND vc.app_sid = i.app_sid AND vc.ind_sid = i.ind_sid AND i.app_sid = r.app_sid;

grant select on csr.v$region to actions, donations, cms;
grant select on csr.v$region to chain with grant option;

CREATE OR REPLACE VIEW CHAIN.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value, fv.num_value, fv.dtm_value, fv.region_sid, r.description
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DELEGATION_SID
(
	DELEGATION_SID                NUMBER(10, 0)     NOT NULL
) ON COMMIT DELETE ROWS;

--- XXX
--- client specific grants
begin
	for r in (select grantee from dba_tab_privs where owner='CSR' and table_name='REGION' and privilege='SELECT') loop
		execute immediate 'grant select on csr.v$region to '||r.grantee;
	end loop;
end;
/

CREATE GLOBAL TEMPORARY TABLE CSRIMP.REGION_DESCRIPTION(
    REGION_SID                    NUMBER(10, 0)     NOT NULL,
    LANG					 	  VARCHAR2(10)      NOT NULL,
    DESCRIPTION				 	  VARCHAR2(1023)	NOT NULL,
    CONSTRAINT PK_REGION_DESCRIPTION PRIMARY KEY (REGION_SID, LANG)
) ON COMMIT DELETE ROWS
;
alter table csrimp.region drop column description;

grant select,insert,update,delete on csr.region_description to csrimp;


CREATE GLOBAL TEMPORARY TABLE CSRIMP.DATAVIEW_REGION_DESCRIPTION(
    DATAVIEW_SID             NUMBER(10, 0)     NOT NULL,
    REGION_SID				 NUMBER(10, 0)     NOT NULL,
    LANG					 VARCHAR2(10)      NOT NULL,
    DESCRIPTION				 VARCHAR2(1023)	   NOT NULL,
    CONSTRAINT PK_DATAVIEW_REGION_DESC PRIMARY KEY (DATAVIEW_SID, REGION_SID, LANG)
) ON COMMIT DELETE ROWS
;
alter table csrimp.dataview_region_member drop column description;

grant select,insert,delete on csr.dataview_region_description to csrimp;


CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEGATION_REGION_DESCRIPTION
(
	DELEGATION_SID				 	NUMBER(10, 0) 		NOT NULL,
	REGION_SID						NUMBER(10, 0)		NOT NULL,
	LANG 							VARCHAR2(10) 		NOT NULL,
	DESCRIPTION						VARCHAR2(1023) 		NOT NULL,
	CONSTRAINT PK_DELEGATION_REGION_DESC PRIMARY KEY (DELEGATION_SID, REGION_SID, LANG)
);

alter table csrimp.delegation_region drop column description;

begin
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='DATAVIEW_IND_MEMBER' and column_name='DESCRIPTION') loop
		execute immediate 'alter table csrimp.dataview_ind_member drop column description';
	end loop;
end;
/

grant select, insert, update, delete on csr.delegation_region_description to csrimp;
grant select, insert, update, delete on csr.delegation_region to csrimp;
grant execute on csr.csr_data_pkg to csrimp;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'REGION_DESCRIPTION',
		'DATAVIEW_REGION_DESCRIPTION',
		'DELEGATION_REGION_DESCRIPTION'
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

update security.menu set action='/csr/site/delegation/manage/topDeleg.acds' where lower(action) = '/csr/site/delegation/topdeleg.acds';

@../dataview_pkg
@../delegation_pkg
@../indicator_pkg
@../region_pkg
@../schema_pkg
@../vb_legacy_pkg

@../approval_dashboard_body
@../audit_body
@../campaign_body
@../csr_data_body
@../csr_user_body
@../dataview_body
@../delegation_body
@../deleg_plan_body
@../division_body
@../doc_body
@../energy_star_body
@../factor_body
@../form_body
@../flow_body
@../imp_body
@../indicator_body
@../issue_body
@../map_body
@../meter_body
@../meter_alarm_body
@../meter_monitor_body
@../model_body
@../pending_body
@../quick_survey_body
@../region_list_body
@../region_event_body
@../role_body
@../region_body
@../region_picker_body
@../region_tree_body
@../scenario_body
@../schema_body
@../sheet_body
@../snapshot_body
@../stored_calc_datasource_body
@../supplier_body
@../survey_body
@../tag_body
@../tree_body
@../templated_report_body
@../utility_body
@../utility_report_body
@../val_body
@../val_datasource_body
@../vb_legacy_body

@../actions/aggr_dependency_body
@../actions/gantt_body
@../actions/importer_body
@../actions/initiative_reporting_body
@../actions/initiative_body
@../actions/role_body
@../actions/task_body

@../csrimp/imp_body

@../donations/donation_body
@../donations/funding_commitment_body
@../donations/region_group_body

@../../../aspen2/cms/db/tab_body

@update_tail
