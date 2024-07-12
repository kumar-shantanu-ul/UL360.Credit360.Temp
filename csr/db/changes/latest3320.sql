define version=3320
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

DROP TABLE csr.flow_editor_beta;
CREATE TABLE csr.scheduled_task_stat(
	scheduled_task_stat_run_id		NUMBER(10,0) NOT NULL,
	task_group						VARCHAR2(255) NOT NULL,
	task_name						VARCHAR2(255) NOT NULL,
	ran_on							VARCHAR2(255) NOT NULL,
	run_start_dtm					DATE DEFAULT SYSDATE NOT NULL,
	run_end_dtm						DATE,
	number_of_apps					NUMBER(10,0),
	number_of_items					NUMBER(10,0),
	number_of_handled_failures		NUMBER(10,0),
	fetch_time_secs					NUMBER(10,0),
	work_time_secs					NUMBER(10,0),
	was_unhandled_failure			NUMBER(1,0),
	CONSTRAINT pk_scheduled_task_stat PRIMARY KEY (scheduled_task_stat_run_id),
	CONSTRAINT ck_scheduled_task_stat_fail CHECK (was_unhandled_failure IS NULL OR was_unhandled_failure IN (0,1))
)
PARTITION BY RANGE (run_start_dtm)
INTERVAL(NUMTOYMINTERVAL(1, 'MONTH'))
( 
	PARTITION sched_task_stat_p1 VALUES LESS THAN (TO_DATE('01-09-2020', 'DD-MM-YYYY'))
);
CREATE INDEX CSR.SCHED_TASK_STAT_IDX1 ON CSR.SCHEDULED_TASK_STAT
    (TASK_GROUP, TASK_NAME) LOCAL;
CREATE SEQUENCE csr.scheduled_task_stat_id CACHE 5;












DECLARE
	v_workflow_module_id 			NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		SELECT module_id
		  INTO v_workflow_module_id
		  FROM csr.module
		 WHERE enable_sp = 'EnableWorkflow';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	DELETE FROM csr.module_param
		  WHERE module_id = v_workflow_module_id;
END;
/
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (93, 'Reporting point export', 'Credit360.ExportImport.Export.Batched.Exporters.ReportingPointExporter');
DELETE FROM csr.tab_portlet
 WHERE customer_portlet_sid IN (
	SELECT customer_portlet_sid
	  FROM csr.customer_portlet
	 WHERE portlet_id = 1070
);
DELETE FROM csr.customer_portlet
 WHERE portlet_id = 1070;
UPDATE csr.portlet SET name = 'Indicator Map (deprecated)' WHERE portlet_id = 923;
UPDATE csr.portlet SET name = 'Indicator Map' WHERE portlet_id = 1070;
UPDATE csr.customer_portlet SET portlet_id = 1070 WHERE portlet_id = 923;
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) 
VALUES (65, 'Indicator Map (Flash)', 'Switches non flash indicator map to the flash version', 'RevertToFlashIndicatorMap', NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) 
VALUES (66, 'Indicator Map (Non Flash)', 'Switches flash indicator map to the non flash version', 'SwitchToNonFlashIndicatorMap', NULL);




create or replace package csr.scheduled_task_pkg  as end;
/
grant execute on CSR.scheduled_task_pkg to web_user;


@..\enable_pkg
@..\flow_pkg
@..\scheduled_task_pkg
@..\region_pkg
@..\util_script_pkg


@..\enable_body
@..\flow_body
@..\..\..\aspen2\cms\db\filter_body
@..\scheduled_task_body
@..\property_body
@..\region_body
@..\util_script_body



@update_tail
