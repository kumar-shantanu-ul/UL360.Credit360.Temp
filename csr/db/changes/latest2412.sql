-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2412
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_AUDIT_LOG_IDS (
	ROW_ID				ROWID			NOT NULL,
	AUDIT_DTM			DATE			NOT NULL
) ON COMMIT DELETE ROWS;

@../csr_data_body

@update_tail
