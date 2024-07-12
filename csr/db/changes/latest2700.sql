--Please update version.sql too -- this keeps clean builds in sync
define version=2700
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.internal_audit_type ADD (
    active            NUMBER(1) DEFAULT 1,
    CONSTRAINT chk_audit_type_act_1_0 CHECK (active IN (1, 0))
);
ALTER TABLE csrimp.internal_audit_type ADD (
    active            NUMBER(1) DEFAULT 1,
    CONSTRAINT chk_audit_type_act_1_0 CHECK (active IN (1, 0))
);

ALTER TABLE csr.non_compliance ADD (
	suggested_action						CLOB
);

ALTER TABLE csrimp.non_compliance ADD (
	suggested_action						CLOB
);

ALTER TABLE csr.non_compliance_type ADD (
	suggested_action_enabled				NUMBER(1) DEFAULT 0,
	CONSTRAINT chk_non_comp_typ_sugg_act_1_0 CHECK (suggested_action_enabled IN (1, 0))
);

ALTER TABLE csr.non_compliance_type MODIFY suggested_action_enabled NOT NULL;

ALTER TABLE csrimp.non_compliance_type ADD (
	suggested_action_enabled				NUMBER(1),
	CONSTRAINT chk_non_comp_typ_sugg_act_1_0 CHECK (suggested_action_enabled IN (1, 0))
);

UPDATE csrimp.non_compliance_type SET suggested_action_enabled = 0;
ALTER TABLE csrimp.non_compliance_type MODIFY suggested_action_enabled NOT NULL;

GRANT CREATE TABLE TO csr;
create index csr.ix_non_comp_sugact_search on csr.non_compliance(suggested_action) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');
REVOKE CREATE TABLE FROM csr;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

DECLARE
    job BINARY_INTEGER;
BEGIN
	 DBMS_SCHEDULER.DROP_JOB (
       job_name             => 'csr.audit_text'
    );
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.audit_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_audit_label_search'');ctx_ddl.sync_index(''ix_audit_notes_search'');ctx_ddl.sync_index(''ix_non_comp_label_search'');ctx_ddl.sync_index(''ix_non_comp_detail_search'');ctx_ddl.sync_index(''ix_non_comp_rt_cse_search'');ctx_ddl.sync_index(''ix_non_comp_sugact_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise audit and non-compliance text indexes');
       COMMIT;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\audit_pkg

--@..\schema_body
--@..\csrimp\imp_body
@..\audit_body
@..\non_compliance_report_body

@update_tail