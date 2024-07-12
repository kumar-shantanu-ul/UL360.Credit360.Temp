-- Please update version.sql too -- this keeps clean builds in sync
define version=1166
@update_header

create table csr.delegation_ind_description (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	delegation_sid	number(10) not null,
	ind_sid			number(10) not null,
	lang 			varchar2(10) not null,
	description		varchar2(1023) not null,
	constraint pk_delegation_ind_description primary key (app_sid, delegation_sid, ind_sid, lang),
	constraint fk_deleg_ind_desc_deleg_ind foreign key (app_sid, delegation_sid, ind_sid)
	references csr.delegation_ind (app_sid, delegation_sid, ind_sid),
	constraint fk_deleg_ind_desc_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.ix_delegation_ind_desc_lang on csr.delegation_ind_description (app_sid, lang);

-- insert translations of whatever text was in the delegation_ind_member table
-- but only where they differ from the original ind descriptions
insert into csr.delegation_ind_description (app_sid, delegation_sid, ind_sid, lang, description)
	select di.app_sid, di.delegation_sid, di.ind_sid, ts.lang, NVL(tr.translated, di.description) description
	  from csr.delegation_ind di
	  join aspen2.translation_set ts on ts.application_sid = di.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
	  where NVL(tr.translated, di.description) IS NOT NULL
	 minus 
	 select id.app_sid, di.delegation_sid, di.ind_sid, id.lang, id.description
	   from csr.ind_description id, csr.delegation_ind di
	  where di.app_sid = id.app_sid and di.ind_sid = id.ind_sid;

create table csr.backup_delegation_ind as
	select *
	  from csr.delegation_ind;
	   
alter table csr.delegation_ind drop column description;

create table csr.ind_sel_group_member_desc (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	ind_sid			number(10) not null,
	lang			varchar2(10) not null,
	description		varchar2(500) not null,
	constraint pk_ind_sel_group_member_desc primary key (app_sid, ind_sid, lang),
	constraint fk_ind_sel_grp_desc_ind_sel foreign key (app_sid, ind_sid)
	references csr.ind_selection_group_member (app_sid, ind_sid),
	constraint fk_ind_sel_grp_mem_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.ix_ind_sel_group_member_desc on csr.ind_sel_group_member_desc (app_sid, lang);

-- insert translations of whatever text was in the ind_selection_group_member table
insert into csr.ind_sel_group_member_desc (app_sid, ind_sid, lang, description)
	select isgm.app_sid, isgm.ind_sid, ts.lang, NVL(tr.translated, isgm.description) description
	  from csr.ind_selection_group_member isgm
	  join aspen2.translation_set ts on ts.application_sid = isgm.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and isgm.description = tr.original
	  where NVL(tr.translated, isgm.description) IS NOT NULL;

create table backup_ind_selection_group_mem as
	select * 
	  from csr.ind_selection_group_member;
alter table csr.ind_selection_group_member drop column description;
	
create or replace view csr.v$ind_selection_group_dep as
	select isg.app_sid, isg.master_ind_sid, isg.master_ind_sid ind_sid
	  from csr.ind_selection_group isg, csr.ind i
	 where i.app_sid = isg.app_sid and i.ind_sid = isg.master_ind_sid
	 union all
	select isgm.app_sid, isgm.master_ind_sid, isgm.ind_sid
	  from csr.ind_selection_group_member isgm;

create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisible, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed 
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

create or replace view csr.v$delegation_ind as
	select di.app_sid, di.delegation_sid, di.ind_sid, di.mandatory, NVL(did.description, id.description) description,
		   di.pos, di.section_key, di.var_expl_group_id, di.visibility, di.css_class
	  from delegation_ind di
	  join ind_description id 
	    on di.app_sid = id.app_sid and di.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  left join delegation_ind_description did
	    on di.app_sid = did.app_sid AND di.delegation_sid = did.delegation_sid
	   and di.ind_sid = did.ind_sid AND did.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

grant select,insert,update,delete on csr.delegation_ind_description to csrimp;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.DELEGATION_IND_DESCRIPTION
(
	DELEGATION_SID				 	NUMBER(10, 0) 		NOT NULL,
	IND_SID							NUMBER(10, 0)		NOT NULL,
	LANG 							VARCHAR2(10) 		NOT NULL,
	DESCRIPTION						VARCHAR2(1023) 		NOT NULL,
	CONSTRAINT PK_DELEGATION_IND_DESCRIPTION PRIMARY KEY (DELEGATION_SID, IND_SID, LANG)
);

alter table csrimp.delegation_ind drop column description;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'DELEGATION_IND_DESCRIPTION',
		'IND_SEL_GROUP_MEMBER_DESC'		
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

@../delegation_pkg
@../deleg_admin_pkg
@../schema_pkg
@../csr_data_body
@../csrimp/imp_body
@../delegation_body
@../deleg_admin_body
@../deleg_plan_body
@../indicator_body
@../schema_body
@../vb_legacy_body
	
@update_tail

