-- Please update version.sql too -- this keeps clean builds in sync
define version=1709
@update_header


CREATE TABLE CSR.BATCH_JOB_STRUCTURE_IMPORT (
    app_sid        	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    batch_job_id    NUMBER(10) NOT NULL,
    workbook        BLOB NOT NULL, 
    sheet_number    NUMBER(4) NOT NULL,
    import_type    	NUMBER(2) NOT NULL,
    input          	VARCHAR2(256) NOT NULL,
    start_row     	NUMBER(10) NOT NULL,
    allow_move      NUMBER(1) NOT NULL,
    trash_old      	NUMBER(1) NOT NULL,
    CONSTRAINT pk_batch_job_structure_import PRIMARY KEY (app_sid, batch_job_id)
);

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name)
VALUES (6, 'Structure Import', 'structure-import');

--Packages
@../batch_job_pkg
@../structure_import_pkg
@../structure_import_body

grant execute on csr.structure_import_pkg to web_user;

@update_tail