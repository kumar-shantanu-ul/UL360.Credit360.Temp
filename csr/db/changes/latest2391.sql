-- Please update version.sql too -- this keeps clean builds in sync
define version=2391
@update_header

DROP TABLE CSR.TEMP_AUDIT_IDS;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_AUDIT_IDS (
	ROW_ID				ROWID			NOT NULL,
	AUDIT_DTM			DATE			NOT NULL
) ON COMMIT DELETE ROWS;

@../csr_data_body

@update_tail