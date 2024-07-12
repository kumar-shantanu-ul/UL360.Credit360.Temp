-- Please update version.sql too -- this keeps clean builds in sync
define version=842
@update_header

create table csr.scenario_run (
	app_sid							number(10)	default sys_context('security', 'app') not null,
	scenario_run_sid				number(10)	not null,
	scenario_sid					number(10)	not null,
	run_dtm							date default sysdate not null,
	description						varchar2(4000),
	constraint pk_scenario_run primary key (app_sid, scenario_run_sid),
	constraint fk_scenario_run_scenario foreign key (app_sid, scenario_sid)
	references csr.scenario (app_sid, scenario_sid)
);
create index csr.ix_scenario_run_scenario on csr.scenario_run (app_sid, scenario_sid);

begin
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SCENARIO_RUN',
		policy_name     => 'SCENARIO_RUN_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
end;
/

create table csr.scenario_run_val (
	app_sid							number(10)	default sys_context('security', 'app') not null,
	scenario_run_val_id				number(10)	not null,
	scenario_run_sid				number(10)	not null,
    ind_sid							number(10)	not null,
    region_sid						number(10)	not null,
    period_start_dtm				date		not null,
    period_end_dtm					date		not null,
    val_number						number(24, 10),
    error_code						number(10),
    source_type_id					number(10)	not null,
    source_id						number(10),
    constraint pk_scenario_run_val primary key (app_sid, scenario_run_val_id),
    constraint fk_scnrio_run_val_scnrio_run foreign key (app_sid, scenario_run_sid)
    references csr.scenario_run (app_sid, scenario_run_sid),
    constraint ck_scenario_run_val_dates check (period_start_dtm = trunc(period_start_dtm, 'MON') and period_end_dtm = trunc(period_end_dtm, 'MON') and period_end_dtm > period_start_dtm),
    constraint fk_scenario_val_ind foreign key (app_sid, ind_sid)
    references csr.ind (app_sid, ind_sid),
    constraint fk_scenario_val_region foreign key (app_sid, region_sid)
    references csr.region (app_sid, region_sid),
    constraint fk_scenario_val_src foreign key (source_type_id)
    references csr.source_type (source_type_id)
);
create index csr.ix_scenario_val_ind on csr.scenario_run_val (app_sid, ind_sid);
create index csr.ix_scenario_val_reg on csr.scenario_run_val (app_sid, region_sid);
create index csr.ix_scenario_val_src on csr.scenario_run_val (source_type_id);

alter table csr.scenario_run_val add constraint ck_val_null check ( (val_number is not null and error_code is null) or (val_number is null and error_code is not null) );
alter table csr.scenario_run_val add constraint uk_scenario_run_val unique (app_sid, scenario_run_sid, ind_sid, region_sid, period_start_dtm, period_end_dtm);

begin
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SCENARIO_RUN_VAL',
		policy_name     => 'SCENARIO_RUN_VAL_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
end;
/

create table csr.sheet_calc_job (
	app_sid							number(10)	default sys_context('security', 'app') not null,
	ind_sid							number(10)	not null,
	start_dtm						date not null,
	end_dtm							date not null,
	processing						number(1)	default 0 not null,
	constraint ck_sheet_calc_job_dates check (end_dtm > start_dtm and trunc(start_dtm, 'MON') = start_dtm and trunc(end_dtm, 'MON') = end_dtm),
	constraint pk_sheet_calc_job primary key (app_sid, ind_sid, processing),
	constraint fk_sheet_calc_job_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid)
);
create index csr.ix_sheet_calc_job_ind on csr.sheet_calc_job (app_sid, ind_sid);
create sequence csr.scenario_run_val_id_seq;

alter table csr.scenario add auto_update number(1) default 0 not null;
alter table csr.scenario add constraint ck_scenario_auto_update check (auto_update in (0,1));

alter table csr.scenario add auto_update_merged_run_sid number(10);
alter table csr.scenario add constraint fk_scn_merged_run_scn_run foreign key (app_sid, auto_update_merged_run_sid) references csr.scenario_run (app_sid, scenario_run_sid);
create index csr.ix_scn_auto_upd_mrged_run_sid on csr.scenario (app_sid, auto_update_merged_run_sid);

alter table csr.scenario add auto_update_unmerged_run_sid number(10);
alter table csr.scenario add constraint fk_scn_unmerged_run_scn_run foreign key (app_sid, auto_update_unmerged_run_sid) references csr.scenario_run (app_sid, scenario_run_sid);
create index csr.ix_scn_aut_upd_unmrged_rn_sid on csr.scenario (app_sid, auto_update_unmerged_run_sid);


alter table csr.scenario add constraint ck_auto_update_runs check (
	(auto_update = 0 and auto_update_merged_run_sid is null and auto_update_unmerged_run_sid is null) or
	(auto_update = 1 and auto_update_merged_run_sid is not null and auto_update_unmerged_run_sid is not null));

CREATE OR REPLACE PACKAGE CSR.scenario_run_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID
);

PROCEDURE SetValue(
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_period_start					IN	scenario_run_val.period_start_dtm%TYPE,
	in_period_end					IN	scenario_run_val.period_end_dtm%TYPE,
	in_val_number					IN	scenario_run_val.val_number%TYPE,
	in_source_type_id				IN	scenario_run_val.source_type_id%TYPE DEFAULT 0,
	in_error_code					IN	scenario_run_val.error_code%TYPE DEFAULT NULL,
	out_val_id						OUT	scenario_run_val.scenario_run_val_id%TYPE
);

PROCEDURE CreateScenarioRun(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario_run.description%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE
);

END scenario_run_pkg;
/
	
CREATE OR REPLACE PACKAGE BODY CSR.scenario_run_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Should be called via the Create method
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	DELETE
	  FROM scenario_run_val
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;
	DELETE
	  FROM scenario_run
	 WHERE app_sid = v_app_sid AND scenario_run_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	NULL;
END;

PROCEDURE SetValue(
	in_ind_sid						IN	scenario_run_val.ind_sid%TYPE,
	in_region_sid					IN	scenario_run_val.region_sid%TYPE,
	in_period_start					IN	scenario_run_val.period_start_dtm%TYPE,
	in_period_end					IN	scenario_run_val.period_end_dtm%TYPE,
	in_val_number					IN	scenario_run_val.val_number%TYPE,
	in_source_type_id				IN	scenario_run_val.source_type_id%TYPE DEFAULT 0,
	in_error_code					IN	scenario_run_val.error_code%TYPE DEFAULT NULL,
	out_val_id						OUT	scenario_run_val.scenario_run_val_id%TYPE
)
AS
	v_divisible						ind.divisible%TYPE;
	v_rounded_in_val_number			scenario_run_val.val_number%TYPE;
	v_pct_ownership					NUMBER;
	v_scaled_val_number				scenario_run_val.val_number%TYPE;
BEGIN
	SELECT divisible
	  INTO v_divisible
	  FROM ind
	 WHERE ind_sid = in_ind_sid;

	-- round it as we'll put it in the database, and apply pctOwnership so long
	-- as we're not aggregating
--	IF in_source_type_id = csr_data_pkg.SOURCE_TYPE_AGGREGATOR AND bitand(in_update_flags, IND_CASCADE_PCT_OWNERSHIP) = 0 THEN
        v_rounded_in_val_number := ROUND(in_val_number, 10);
--	ELSE
--		v_pct_ownership := region_pkg.getPctOwnership(in_ind_sid, in_region_sid, in_period_start);
--        v_rounded_in_val_number := ROUND(in_val_number * v_pct_ownership, 10);
--    END IF;
    
    -- clear or scale any overlapping values (we scale for stored calcs / aggregates, but clear for other value types)
    -- there are multiple cases, but basically it boils down to having a non-overlapping left/right portion or the value being completely covered
    -- for the left/right cases we either scale according to divisibility or create NULLs covering the non-overlapping portion 
    -- (to clear aggregates up the tree in those time periods)
    -- for the complete coverage case the old value simply needs to be removed (but any value with the exact period is simply updated in place)
    --security_pkg.debugmsg('adding value for ind='||in_ind_sid||', region='||in_region_sid||',period='||in_period_start||' -> '||in_period_end);    
    FOR r IN (SELECT scenario_run_val_id, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id
    			FROM scenario_run_val
		       WHERE ind_sid = in_ind_sid
			     AND region_sid = in_region_sid
			     AND period_end_dtm > in_period_start
			     AND period_start_dtm < in_period_end
			     AND NOT (period_start_dtm = in_period_start AND period_end_dtm = in_period_end)
			     	 FOR UPDATE) LOOP
		
		-- non-overlapping portion on the left
		IF r.period_start_dtm < in_period_start THEN
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) THEN
				IF v_divisible = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
				END IF;

				--security_pkg.debugmsg('adding left value from '||r.period_start_dtm||' to '||in_period_start||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');				
				INSERT INTO scenario_run_val
					(scenario_run_val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id)
				VALUES
					(scenario_run_val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, r.period_start_dtm, in_period_start, v_scaled_val_number, 
					 r.error_code, r.source_type_id);
			ELSE
				--security_pkg.debugmsg('adding left null from '||r.period_start_dtm||' to '||in_period_start);
				INSERT INTO scenario_run_val
					(scenario_run_val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id)
				VALUES
					(scenario_run_val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, r.period_start_dtm, in_period_start, csr_data_pkg.SOURCE_TYPE_AGGREGATOR);
			END IF;			
		END IF;

		-- non-overlapping portion on the right
		IF r.period_end_dtm > in_period_end THEN
			
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) THEN
				IF v_divisible = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
				END IF;

				--security_pkg.debugmsg('adding right value from '||in_period_end||' to '||r.period_end_dtm||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');
				INSERT INTO scenario_run_val
					(scenario_run_val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, source_type_id)
				VALUES
					(scenario_run_val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_end, r.period_end_dtm, v_scaled_val_number, 
					 r.error_code, r.source_type_id);
			ELSE
				--security_pkg.debugmsg('adding right null from '||in_period_end||' to '||r.period_end_dtm);
				INSERT INTO scenario_run_val
					(scenario_run_val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id)
				VALUES
					(scenario_run_val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_end, r.period_end_dtm, csr_data_pkg.SOURCE_TYPE_AGGREGATOR);
			END IF;
		END IF;
		
		-- remove the overlapping value
		DELETE FROM scenario_run_val
		 WHERE scenario_run_val_id = r.scenario_run_val_id;
	END LOOP;
			  
    -- upsert (there are constraints on val which will throw DUP_VAL_ON_INDEX if this should be an update)
    BEGIN
        INSERT INTO scenario_run_val (scenario_run_val_id, ind_sid, region_sid, period_start_dtm,
            period_end_dtm,  val_number, source_type_id, error_code)
        VALUES (scenario_run_val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_start,
            in_period_end, v_rounded_in_val_number, in_source_type_id, in_error_code)
        RETURNING scenario_run_val_id INTO out_val_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
        	UPDATE scenario_run_val
        	   SET val_number = v_rounded_in_val_number,
        	   	   source_type_id = in_source_type_id,
        	   	   error_code = in_error_code
        	 WHERE ind_sid = in_ind_sid
        	   AND region_sid = in_region_sid
        	   AND period_start_dtm = in_period_start
        	   AND period_end_dtm = in_period_end
        	   	   RETURNING scenario_run_val_id INTO out_val_id;
    END;
END;

PROCEDURE CreateScenarioRun(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	in_description					IN	scenario_run.description%TYPE,
	out_scenario_run_sid			OUT	scenario_run.scenario_run_sid%TYPE
)
AS
	v_parent_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT parent_sid_id
	  INTO v_parent_sid
	  FROM security.securable_object
	 WHERE sid_id = in_scenario_sid;
	 
	securableObject_pkg.CreateSO(security_pkg.GetACT(), v_parent_sid,
		class_pkg.GetClassId('CSRScenarioRun'), 'Unmerged cube scenario run', out_scenario_run_sid);
		
	INSERT INTO scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (out_scenario_run_sid, in_scenario_sid, 'Unmerged cube scenario run');
END;

END scenario_run_pkg;
/
grant execute on csr.scenario_run_pkg to security;

declare
	v_new_class_id 		security.security_pkg.t_sid_id;
	v_act 				security.security_pkg.t_act_id;
begin
	security.user_pkg.logonauthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, null, v_act);	
	begin	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRScenarioRun', 'csr.scenario_run_pkg', NULL, v_new_class_id);
	exception
		when security.security_pkg.DUPLICATE_OBJECT_NAME then
			null;
	end;
end;
/

/*
declare
	v_merged_run_sid number;
	v_unmerged_run_sid number;
begin
	for h in (select host from csr.customer where app_sid in (select distinct app_sid from csr.scenario)) loop
		security.user_pkg.logonadmin(h.host);
		for r in (select so.parent_sid_id, s.scenario_sid, s.description
					from csr.scenario s, security.securable_object so
				   where so.sid_id = s.scenario_sid) loop
			csr.scenario_run_pkg.createscenariorun(r.scenario_sid, r.description||' run', v_merged_run_sid);
			csr.scenario_run_pkg.createscenariorun(r.scenario_sid, 'Unmerged '||r.description||' run', v_unmerged_run_sid);
			update csr.scenario
			   set auto_update_merged_run_sid = v_merged_run_sid,
			       auto_update_unmerged_run_sid = v_unmerged_run_sid,
			       auto_update = 1
			 where scenario_sid = r.scenario_sid;
		end loop;
	end loop;
end;
/
*/

create table csr.scenario_auto_run_request(
	app_sid							number(10)		default sys_context('security', 'app') not null,
	scenario_sid					number(10)		not null,
	processing						number(1)		default 0 not null,
	constraint pk_scenario_auto_run_request primary key (app_sid, scenario_sid, processing),
	constraint fk_scn_aut_run_req_scn foreign key (app_sid, scenario_sid)
	references csr.scenario (app_sid, scenario_sid),
	constraint ck_scn_auto_run_req_processng check (processing in (0,1))
);

begin
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SCENARIO_AUTO_RUN_REQUEST',
		policy_name     => 'SCENARIO_AUTO_RUN_REQU_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
end;
/

create sequence csr.scenario_man_run_req_id_seq;
create table csr.scenario_man_run_request(
	app_sid							number(10)		default sys_context('security', 'app') not null,
	scenario_man_run_request_id		number(10)		not null,
	scenario_sid					number(10)		not null,
	description						varchar2(4000),
	processing						number(1)		default 0 not null,
	constraint pk_scenario_man_run_request primary key (app_sid, scenario_man_run_request_id),
	constraint fk_scn_man_run_req_scn foreign key (app_sid, scenario_sid)
	references csr.scenario (app_sid, scenario_sid),
	constraint ck_scn_man_run_req_processng check (processing in (0,1))
);
create index csr.ix_scn_man_run_scn on csr.scenario_man_run_request (app_sid, scenario_sid);

begin
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'SCENARIO_MAN_RUN_REQUEST',
		policy_name     => 'SCENARIO_MAN_RUN_REQUe_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
end;
/

alter table csr.customer add unmerged_scenario_run_sid number(10);
alter table csr.customer add constraint fk_customer_scenario_run foreign key (app_sid, unmerged_scenario_run_sid)
references csr.scenario_run (app_sid, scenario_run_sid);
create index csr.ix_cust_unmrged_scn_run_sid on csr.customer (app_sid, unmerged_scenario_run_sid);

create global temporary table csr.ind_list_2 (ind_sid number(10) not null) on commit delete rows;

@../csr_data_pkg
@../calc_pkg
@../scenario_pkg
@../scenario_run_pkg
@../stored_calc_datasource_pkg
@../val_datasource_pkg
@../csr_app_body
@../csr_data_body
@../calc_body
@../delegation_body
@../scenario_body
@../scenario_run_body
@../sheet_body
@../stored_calc_datasource_body
@../val_datasource_body

@update_tail
