define version=2882
define minor_version=0
define is_combined=1
@update_header

CREATE TABLE csr.lookup_table
(
	app_sid 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	lookup_id		NUMBER(10) NOT NULL,
	lookup_name		VARCHAR2(255) NOT NULL,
	constraint pk_lookup_table primary key (app_sid, lookup_id),
	constraint fk_lookup_table_customer foreign key (app_sid)
	references csr.customer (app_sid)
);
CREATE TABLE csr.lookup_table_entry
(
	app_sid 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	lookup_id		NUMBER(10) NOT NULL,
	start_dtm		DATE NOT NULL,
	val				NUMBER,
	constraint pk_lookup_table_entry primary key (app_sid, lookup_id, start_dtm),
	constraint fk_lookup_tab_ent_lookup_tab foreign key (app_sid, lookup_id)
	references csr.lookup_table (app_sid, lookup_id)
);
create index csr.ix_lookup_tab_entry_lookup_id on csr.lookup_table_entry (app_sid, lookup_id);
CREATE TABLE CSRIMP.LOOKUP_TABLE
(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_ID						NUMBER(10) NOT NULL,
	LOOKUP_NAME						VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_LOOKUP_TABLE PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_ID)
);
CREATE TABLE CSRIMP.LOOKUP_TABLE_ENTRY
(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_ID						NUMBER(10) NOT NULL,
	START_DTM						DATE NOT NULL,
	VAL								NUMBER,
	CONSTRAINT PK_LOOKUP_TABLE_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_ID, START_DTM)
);
CREATE SEQUENCE csr.meter_element_layout_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;
CREATE SEQUENCE csr.meter_input_id_seq
    START WITH 100
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;
CREATE TABLE csr.meter_element_layout (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	meter_element_layout_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT pk_meter_element_layout PRIMARY KEY (app_sid, meter_element_layout_id),
	CONSTRAINT fk_meter_el_layout_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_meter_el_layout_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT chk_meter_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);
CREATE TABLE csrimp.meter_element_layout (	
	csrimp_session_id				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	meter_element_layout_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT pk_meter_element_layout PRIMARY KEY (csrimp_session_id, meter_element_layout_id),
	CONSTRAINT chk_meter_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_meter_element_layout_is FOREIGN KEY
        (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
        ON DELETE CASCADE
);
CREATE TABLE csrimp.map_meter_input (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_meter_input_id    NUMBER(10) NOT NULL,
    new_meter_input_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_meter_input primary key (csrimp_session_id, old_meter_input_id) USING INDEX,
    CONSTRAINT uk_map_meter_input unique (csrimp_session_id, new_meter_input_id) USING INDEX,
    CONSTRAINT fk_map_meter_input_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);
	
create index csr.ix_meter_element_tag_group_id on csr.meter_element_layout (app_sid, tag_group_id);
create index csr.ix_meter_element_ind_sid on csr.meter_element_layout (app_sid, ind_sid);
CREATE UNIQUE INDEX csr.UK_METER_EL_LAYOUT ON csr.meter_element_layout(app_sid, ind_sid, tag_group_id);
create table csr.scenario_run_snapshot_file
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	version							number(10) not null,
	file_path						varchar2(4000), --not null,
	sha1							raw(20), --not null,
	constraint pk_scenario_run_snapshot_file primary key (app_sid, scenario_run_snapshot_sid, version)
);
create table csr.scenario_run_snapshot
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	scenario_run_sid				number(10) not null,
	start_dtm						date not null,
	end_dtm							date not null,
	period_set_id					number(10),
	period_interval_id				number(10),
	last_updated_dtm				date default sysdate not null,
	version							number(10) not null deferrable initially deferred,
	constraint pk_scenario_run_snapshot primary key (app_sid, scenario_run_snapshot_sid),
	constraint fk_scenario_run_snapshot foreign key (app_sid, scenario_run_sid)
	references csr.scenario_run (app_sid, scenario_run_sid),
	constraint fk_scn_run_scn_snap_run_file foreign key (app_sid, scenario_run_snapshot_sid, version)
	references csr.scenario_run_snapshot_file (app_sid, scenario_run_snapshot_sid, version),
	constraint fk_scn_run_snap_period_int foreign key (app_sid, period_set_id, period_interval_id)
	references csr.period_interval (app_sid, period_set_id, period_interval_id),
	constraint ck_scn_run_snap_period_int check (
		(period_set_id is null and period_interval_id is null) or
		(period_set_id is not null and period_interval_id is not null)
	)
);
create index csr.ix_scn_run_snap_period_int on csr.scenario_run_snapshot (app_sid, period_set_id, period_interval_id);
create index csr.ix_scn_run_snap_scn_run on csr.scenario_run_snapshot (app_sid, scenario_run_sid);
create index csr.ix_scn_run_snap_file_ver on csr.scenario_run_snapshot (app_sid, scenario_run_snapshot_sid, version);
alter table csr.scenario_run_snapshot_file add
	constraint fk_scn_run_snap_file_scn_run foreign key (app_sid, scenario_run_snapshot_sid)
	references csr.scenario_run_snapshot (app_sid, scenario_run_snapshot_sid);
create table csr.scenario_run_snapshot_ind
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	ind_sid							number(10) not null,
	constraint pk_scenario_run_snapshot_ind primary key (app_sid, scenario_run_snapshot_sid, ind_sid),
	constraint fk_scn_run_snapshot_ind_ind foreign key (app_sid, ind_sid)
	references csr.ind (app_sid, ind_sid)
);
create index csr.ix_scn_run_snapshot_ind_ind on csr.scenario_run_snapshot_ind (app_sid, ind_sid);
create table csr.scenario_run_snapshot_region
(
	app_sid							number(10) default SYS_CONTEXT('SECURITY', 'APP') not null,
	scenario_run_snapshot_sid		number(10) not null,
	region_sid						number(10) not null,
	constraint pk_scenario_run_snapshot_reg primary key (app_sid, scenario_run_snapshot_sid, region_sid),
	constraint fk_scn_run_snapshot_reg_reg foreign key (app_sid, region_sid)
	references csr.region (app_sid, region_sid)
);
create index csr.ix_scn_run_snapshot_reg_reg on csr.scenario_run_snapshot_region (app_sid, region_sid);

ALTER TABLE csr.meter_insert_data ADD (
	source_row NUMBER(10) NULL,
	error_msg VARCHAR2(4000) NULL
);
ALTER TABLE csr.customer
  ADD rstrct_multiprd_frm_edit_to_yr NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.customer
  ADD allow_multiperiod_forms NUMBER(1) NOT NULL;
ALTER TABLE csrimp.customer
  ADD rstrct_multiprd_frm_edit_to_yr NUMBER(1) NOT NULL;
DECLARE
	v_exists	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_constraints
	 WHERE owner = 'CSR'
	   AND constraint_name = 'UK_AGG_IND_GRP_NAME';
	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.aggregate_ind_group DROP CONSTRAINT uk_agg_ind_grp_name';
	END IF;
	-- local db has unique index but it is not on live
	v_exists := 0;
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND index_name = 'UK_AGGR_IND_GROUP';
  
	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX csr.uk_aggr_ind_group ON csr.aggregate_ind_group (app_sid, UPPER(name))';
	END IF;
END;
/


grant insert on csr.lookup_table to csrimp;
grant insert on csr.lookup_table_entry to csrimp;
grant select,insert,update,delete on csrimp.meter_element_layout to web_user;
grant insert on csr.meter_element_layout to csrimp;
grant select on csr.meter_element_layout_id_seq to csrimp;
grant select on csr.meter_input_id_seq to csrimp;




BEGIN
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (3, 'Manual Instance Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.ManualInstanceDbReader');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
CREATE OR REPLACE TRIGGER CSR.METER_IND_TRIGGER
AFTER INSERT OR UPDATE
	ON CSR.ALL_METER
	FOR EACH ROW
DECLARE
	v_consumption_input_id	csr.meter_input.meter_input_id%TYPE;
	v_cost_input_id			csr.meter_input.meter_input_id%TYPE;
BEGIN
	IF :NEW.app_sid != :OLD.app_sid OR
	   :NEW.region_sid != :OLD.region_sid OR
	   :NEW.primary_ind_sid != :OLD.primary_ind_sid OR
	   NVL(:NEW.primary_measure_conversion_id, -1) != NVL(:OLD.primary_measure_conversion_id, -1) OR
	   NVL(:NEW.cost_ind_sid, -1) != NVL(:OLD.cost_ind_sid, -1) OR
	   NVL(:NEW.cost_measure_conversion_id, -1) != NVL(:OLD.cost_measure_conversion_id, -1) THEN
	   	
		SELECT meter_input_id
		  INTO v_consumption_input_id
		  FROM csr.meter_input
		 WHERE app_sid = :NEW.app_sid
		   AND lookup_key = 'CONSUMPTION';
		
		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM csr.meter_input
		 WHERE app_sid = :NEW.app_sid
		   AND lookup_key = 'COST';
		
		FOR r IN (
			SELECT :NEW.app_sid app_sid, :NEW.region_sid region_sid, 
				pia.aggregator primary_aggregator, :NEW.primary_ind_sid primary_ind_sid, pi.measure_sid primary_measure_sid, :NEW.primary_measure_conversion_id primary_measure_conversion_id,
				cia.aggregator cost_aggregator, :NEW.cost_ind_sid cost_ind_sid, ci.measure_sid cost_measure_sid, :NEW.cost_measure_conversion_id cost_measure_conversion_id
			  FROM csr.ind pi
			  JOIN csr.meter_input_aggregator pia ON pia.app_sid = pi.app_sid AND pia.meter_input_id = v_consumption_input_id
			  LEFT JOIN csr.ind ci ON ci.app_sid = pi.app_sid AND ci.ind_sid = :NEW.cost_ind_sid
			  LEFT JOIN csr.meter_input_aggregator cia ON cia.app_sid = ci.app_sid AND cia.meter_input_id = v_cost_input_id
			 WHERE pi.app_sid = :NEW.app_sid
			   AND pi.ind_sid = :NEW.primary_ind_sid
		) LOOP
			-- Set the consumption indicator/measure/conversion
			BEGIN
				INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
				VALUES (r.app_sid, r.region_sid, v_consumption_input_id, r.primary_aggregator, r.primary_ind_sid, r.primary_measure_sid, r.primary_measure_conversion_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE csr.meter_input_aggr_ind
					   SET ind_sid = r.primary_ind_sid,
						   measure_sid = r.primary_measure_sid, 
						   measure_conversion_id = r.primary_measure_conversion_id
					 WHERE app_sid = r.app_sid
					   AND region_sid = r.region_sid
					   AND meter_input_id = v_consumption_input_id
					   AND aggregator = r.primary_aggregator;
			END;
			
			-- Set the cost indicator/measure/conversion
			IF r.cost_ind_sid IS NOT NULL THEN
				BEGIN
					INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
					VALUES (r.app_sid, r.region_sid, v_cost_input_id, r.cost_aggregator, r.cost_ind_sid, r.cost_measure_sid, r.cost_measure_conversion_id);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE csr.meter_input_aggr_ind
						   SET ind_sid = r.cost_ind_sid,
							   measure_sid = r.cost_measure_sid, 
							   measure_conversion_id = r.cost_measure_conversion_id
						 WHERE app_sid = r.app_sid
						   AND region_sid = r.region_sid
						   AND meter_input_id = v_cost_input_id
						   AND aggregator = r.cost_aggregator;
				END;
			ELSE
				DELETE FROM csr.meter_input_aggr_ind
				  WHERE app_sid = r.app_sid
				    AND region_sid = r.region_sid
				    AND meter_input_id = v_cost_input_id;
			END IF;
		END LOOP;
	END IF;
	-- Associate any inputs which are not CONSUMPTION or COST
	FOR i IN (
		SELECT mi.meter_input_id, mi.lookup_key, mia.aggregator
		  FROM csr.meter_input mi
		  JOIN csr.meter_input_aggregator mia ON mia.app_sid = mi.app_sid AND mia.meter_input_id = mi.meter_input_id
		 WHERE mi.lookup_key NOT IN ('CONSUMPTION', 'COST')
	) LOOP
		BEGIN
			INSERT INTO csr.meter_input_aggr_ind (region_sid, meter_input_id, aggregator)
			VALUES (:NEW.region_sid, i.meter_input_id, i.aggregator);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Nothing to do
		END;
	END LOOP;
END;
/
declare
	v_class_id security.security_pkg.T_CLASS_ID;
begin
	BEGIN
		security.user_pkg.logonadmin;
		security.class_pkg.CreateClass(sys_context('security','act'), NULL, 'CSRScenarioRunSnapshot', 'csr.scenario_run_snapshot_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;	
end;
/




UPDATE csr.batch_job_type
   SET one_at_a_time = 1
 WHERE plugin_name IN ('automated-import', 'automated-export');




create or replace package csr.scenario_Run_snapshot_pkg as end;
/
grant execute on csr.scenario_run_snapshot_pkg to security;
grant execute on csr.scenario_run_snapshot_pkg to web_user;


@..\schema_pkg
@..\stored_calc_datasource_pkg
@..\automated_import_pkg
@..\meter_pkg
@..\property_pkg
@..\meter_monitor_pkg
@..\scenario_run_snapshot_pkg
@..\chain\company_type_pkg


@..\schema_body
@..\stored_calc_datasource_body
@..\csrimp\imp_body
@..\calc_body
@..\csr_app_body
@..\csr_data_body
@..\automated_import_body
@..\meter_body
@..\property_report_body
@..\property_body
@..\chain\company_body
@..\initiative_body
@..\indicator_body
@..\tag_body
@..\meter_monitor_body
@..\meter_aggr_body
@..\..\..\aspen2\cms\db\tab_body
@..\issue_body
@..\period_body
@..\..\..\aspen2\cms\db\filter_body
@..\deleg_plan_body
@..\customer_body
@..\delegation_body
@..\audit_body
@..\scenario_run_snapshot_body
	 
@..\chain\company_type_body
@..\quick_survey_body



@update_tail
