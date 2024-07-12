-- Please update version.sql too -- this keeps clean builds in sync
define version=1219
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_AUDIT_LOG
(
	AUDIT_DATE						DATE NOT NULL,
	AUDIT_TYPE_ID					NUMBER(10) NOT NULL,
	OBJECT_SID						NUMBER(10) NOT NULL,
	CSR_USER_SID					NUMBER(10) NOT NULL,
	DESCRIPTION						VARCHAR2(4000),
	NAME							VARCHAR2(4000),
	PARAM_1							VARCHAR2(4000),
	PARAM_2							VARCHAR2(4000),
	PARAM_3							VARCHAR2(4000),
	REMOTE_ADDR						VARCHAR2(40)
) ON COMMIT DELETE ROWS;

@../csr_data_body

@update_tail
