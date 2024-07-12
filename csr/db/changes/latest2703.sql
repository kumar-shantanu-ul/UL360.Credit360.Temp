--Please update version.sql too -- this keeps clean builds in sync
define version=2703
@update_header

ALTER TABLE CSR.INITIATIVE_METRIC ADD(
    IS_EXTERNAL             NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (IS_EXTERNAL IN(0,1))
);

CREATE OR REPLACE TYPE CSR.T_INIT_METRIC_AUDIT_ROW AS 
  OBJECT ( 
  	INITIATIVE_METRIC_ID	NUMBER(10),
	CONVERSION_ID			NUMBER(10),
	VAL						NUMBER(24, 10)
  );
/
CREATE OR REPLACE TYPE CSR.T_INIT_METRIC_AUDIT_TABLE AS 
  TABLE OF CSR.T_INIT_METRIC_AUDIT_ROW;
/

BEGIN
	INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
	VALUES (23, 'Initiatives', 1);
END;
/

@../csr_data_pkg
@../initiative_metric_pkg

@../initiative_body
@../initiative_metric_body
@../initiative_doc_body
	
@update_tail
