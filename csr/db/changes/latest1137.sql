-- Please update version.sql too -- this keeps clean builds in sync
define version=1137
@update_header

create table csr.ind_description (
	app_sid 	number(10) default sys_context('security', 'app') not null,
	ind_sid		number(10) not null,
	lang 		varchar2(10) not null,
	description	varchar2(1023) not null,
	constraint pk_ind_description primary key (app_sid, ind_sid, lang),
	constraint fk_ind_description_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid),
	constraint fk_ind_description_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.ix_ind_description_lang on csr.ind_description (app_sid, lang);

grant select on csr.ind_description to actions;

-- insert translations of whatever text was in the ind table
insert into csr.ind_description (app_sid, ind_sid, lang, description)
	select i.app_sid, i.ind_sid, ts.lang, NVL(tr.translated, NVL(i.description, i.name)) description
	  from csr.ind i
	  join aspen2.translation_set ts on ts.application_sid = i.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and i.description = tr.original
	  order by app_sid, ind_sid, lang;

create table csr.backup_ind_description as
	select app_sid, ind_sid, description
	  from csr.ind;
	   
alter table csr.ind drop column description;

-- alter table csr.ind add description varchar2(1023);
-- update csr.ind i set description = (select description from csr.backup_ind_description bi where bi.app_sid = i.app_sid and bi.ind_sid = i.ind_sid);

create table csr.dataview_ind_description (
	app_sid 		number(10) default sys_context('security', 'app') not null,
	dataview_sid	number(10) not null,
	pos				number(10) not null,
	lang 			varchar2(10) not null,
	description		varchar2(1023) not null,
	constraint pk_dataview_ind_description primary key (app_sid, dataview_sid, pos, lang),
	constraint fk_dv_ind_desc_dv_ind_member foreign key (app_sid, dataview_sid, pos)
	references csr.dataview_ind_member (app_sid, dataview_sid, pos),
	constraint fk_dv_ind_desc_aspen2_ts foreign key (app_sid, lang)
	references aspen2.translation_set (application_sid, lang)
);
create index csr.dataview_ind_desc_lang on csr.dataview_ind_description (app_sid, lang);

-- insert translations of whatever text was in the dataview_ind_member table
-- but only where they differ from the original ind descriptions
insert into csr.dataview_ind_description (app_sid, dataview_sid, pos, lang, description)
	select di.app_sid, di.dataview_sid, di.pos, ts.lang, NVL(tr.translated, di.description) description
	  from csr.dataview_ind_member di
	  join aspen2.translation_set ts on ts.application_sid = di.app_sid
	  left join (
		select t.application_sid, t.original, tr.lang, tr.translated
		  from aspen2.translated tr, aspen2.translation t
		where t.application_sid = tr.application_sid and t.original_hash = tr.original_hash
	  ) tr on tr.application_sid = ts.application_sid and tr.lang = ts.lang and di.description = tr.original
	  where NVL(tr.translated, di.description) IS NOT NULL
	 minus 
	 select id.app_sid, di.dataview_sid, di.pos, id.lang, id.description
	   from csr.ind_description id, csr.dataview_ind_member di
	  where di.app_sid = id.app_sid and di.ind_sid = id.ind_sid;
				
create table csr.backup_dataview_ind_member as
	select *
	  from csr.dataview_ind_member;

alter table csr.dataview_ind_member drop column description;

CREATE OR REPLACE VIEW csr.v$customer_lang AS
	SELECT ts.lang
	  FROM aspen2.translation_set ts
	 WHERE ts.application_sid = SYS_CONTEXT('SECURITY', 'APP')
	 UNION
	SELECT 'en' -- ensure english is present
	  FROM DUAL;

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
	 where id.app_sid = id.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

grant select on csr.v$ind to actions;

create or replace view csr.v$ind_selection_group_dep as
	select isg.app_sid, isg.master_ind_sid, isg.master_ind_sid ind_sid, i.description
	  from csr.ind_selection_group isg, csr.v$ind i
	 where i.app_sid = isg.app_sid and i.ind_sid = isg.master_ind_sid
	 union all
	select isgm.app_sid, isgm.master_ind_sid, isgm.ind_sid, isgm.description
	  from csr.ind_selection_group_member isgm;

CREATE OR REPLACE VIEW csr.v$imp_val_mapped AS
    SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm, 
           ii.description ind_description,
           i.description maps_to_ind_description,
           ir.description region_description,
           i.aggregate,
           iv.val,			               				
           NVL(NVL(mc.a, mcp.a),1) factor_a,
           NVL(NVL(mc.b, mcp.b),1) factor_b,
           NVL(NVL(mc.c, mcp.c),0) factor_c,
           m.description measure_description,
           im.maps_to_measure_conversion_id,
           mc.description from_measure_description,
           NVL(i.format_mask, m.format_mask) format_mask,
           ir.maps_to_region_sid, 
           iv.rowid rid,
           ii.app_Sid, iv.note,
           CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
           icv.imp_conflict_id,
           iv.imp_ind_id, iv.imp_region_id
      FROM imp_val iv
           JOIN imp_ind ii ON iv.imp_ind_id = ii.imp_ind_id AND iv.app_sid = ii.app_sid
           JOIN imp_region ir ON iv.imp_region_id = ir.imp_region_id AND iv.app_sid = ir.app_sid
           LEFT JOIN imp_measure im 
                ON  iv.imp_ind_id = im.imp_ind_id 
                AND iv.imp_measure_id = im.imp_measure_id 
                AND iv.app_sid = im.app_sid
           LEFT JOIN measure_conversion mc
                ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
                AND im.app_sid = mc.app_sid
           LEFT JOIN measure_conversion_period mcp                
                ON mc.measure_conversion_id = mcp.measure_conversion_id
                AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
                AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
           LEFT JOIN imp_conflict_val icv
                ON iv.imp_val_id = icv.imp_val_id
                AND iv.app_sid = icv.app_sid
           JOIN v$ind i 
                ON ii.maps_to_ind_sid = i.ind_sid
                AND ii.app_sid = i.app_sid
           JOIN measure m 
                ON i.measure_sid = m.measure_sid 
                AND i.app_sid = m.app_sid
     WHERE ir.maps_to_region_sid IS NOT NULL
       AND ii.maps_to_ind_sid IS NOT NULL;

CREATE OR REPLACE VIEW csr.audit_val_log AS
	SELECT changed_dtm audit_date, r.app_sid, 6 audit_type_id, vc.ind_sid object_sid, changed_by_sid user_sid,
	 	   'Set "{0}" ("{1}") to {2}: '||reason description, i.description param_1, r.description param_2, val_number param_3
	  FROM val_change vc, region r, v$ind i
	 WHERE vc.app_sid = r.app_sid AND vc.region_sid = r.region_sid
	   AND vc.app_sid = i.app_sid AND vc.ind_sid = i.ind_sid AND i.app_sid = r.app_sid;


CREATE OR REPLACE VIEW csr.IMP_VAL_MAPPED
(IND_DESCRIPTION, REGION_DESCRIPTION, IND_SID, REGION_SID, IMP_IND_DESCRIPTION, IMP_REGION_DESCRIPTION, IMP_VAL_ID, IMP_IND_ID, IMP_REGION_ID, UNKNOWN, START_DTM, END_DTM, VAL, FILE_SID, IMP_SESSION_SID, SET_VAL_ID, IMP_MEASURE_ID, TOLERANCE_TYPE, PCT_UPPER_TOLERANCE, PCT_LOWER_TOLERANCE, NOTE, LOOKUP_KEY, MAP_ENTITY, ROLL_FORWARD, ACQUISITION_DTM, A, B, C, CALC_DESCRIPTION, NORMALIZE, DO_TEMPORAL_AGGREGATION) AS
SELECT i.DESCRIPTION, r.DESCRIPTION, i.IND_SID, r.REGION_SID, ii.DESCRIPTION, ir.DESCRIPTION, iv.IMP_VAL_ID, iv.IMP_IND_ID, iv.IMP_REGION_ID, iv.UNKNOWN, iv.START_DTM, iv.END_DTM, iv.VAL, iv.FILE_SID, iv.IMP_SESSION_SID, iv.SET_VAL_ID, iv.IMP_MEASURE_ID, i.TOLERANCE_TYPE, i.PCT_UPPER_TOLERANCE, i.PCT_LOWER_TOLERANCE, iv.NOTE, r.LOOKUP_KEY, r.MAP_ENTITY, i.ROLL_FORWARD, r.ACQUISITION_DTM, iv.A, iv.B, iv.C, i.CALC_DESCRIPTION, i.NORMALIZE, i.DO_TEMPORAL_AGGREGATION
FROM imp_val iv, imp_ind ii, imp_region ir, v$ind i, region r
WHERE iv.IMP_IND_ID = ii.IMP_IND_ID AND iv.IMP_REGION_ID = ir.IMP_REGION_ID AND ii.APP_SID = i.APP_SID AND ii.MAPS_TO_IND_SID = i.IND_SID AND ir.APP_SID = r.APP_SID AND ir.MAPS_TO_REGION_SID = r.REGION_SID AND ir.APP_SID = r.APP_SID AND ir.MAPS_TO_REGION_SID = r.REGION_SID AND ii.APP_SID = i.APP_SID AND ii.MAPS_TO_IND_SID = i.IND_SID
;

--- XXX
--- client specific grants
begin
	for r in (select grantee from table_privileges where table_name='IND' and select_priv='Y') loop
		execute immediate 'grant select on csr.v$ind to '||r.grantee;
	end loop;
end;
/

-- drop some useless columns
alter table csr.dataview_ind_member drop column scale;
alter table csr.dataview_ind_member drop column flags;
alter table csr.dataview_ind_member drop column dataview_ind_id;
alter table csr.dataview_ind_member drop column measure_description;
alter table csr.dataview_ind_member drop column multiplier_ind_sid cascade constraints;

CREATE GLOBAL TEMPORARY TABLE CSRIMP.DATAVIEW_IND_DESCRIPTION(
    DATAVIEW_SID             NUMBER(10, 0)     NOT NULL,
    POS                      NUMBER(10, 0)     NOT NULL,
    LANG					 VARCHAR2(10)      NOT NULL,
    DESCRIPTION				 VARCHAR2(1023)	   NOT NULL,
    CONSTRAINT PK_DATAVIEW_IND_DESCRIPTION PRIMARY KEY (DATAVIEW_SID, POS, LANG)
) ON COMMIT DELETE ROWS
;

grant select,insert,delete on csr.dataview_ind_description to csrimp;

@../actions/ind_template_pkg
@../dataview_pkg
@../indicator_pkg
@../range_pkg
@../schema_pkg
@../vb_legacy_pkg
@../actions/ind_template_body
@../actions/initiative_reporting_body
@../actions/task_body
@../audit_body
@../calc_body
@../csr_data_body
@../csr_user_body
@../csrimp/imp_body
@../datasource_body
@../dataview_body
@../delegation_body
@../form_body
@../img_chart_body
@../imp_body
@../indicator_body
@../issue_body
@../meter_body
@../meter_monitor_body
@../model_body
@../pending_body
@../pending_datasource_body
@../quick_survey_body
@../range_body
@../scenario_body
@../schema_body
@../section_body
@../snapshot_body
@../stored_calc_datasource_body
@../tag_body
@../target_dashboard_body
@../templated_report_body
@../tree_body
@../utility_report_body
@../val_body
@../val_datasource_body
@../vb_legacy_body
	
@update_tail

