-- Please update version.sql too -- this keeps clean builds in sync
define version=2383
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_AUDIT_IDS (
	ROW_ID				ROWID			NOT NULL,
	AUDIT_DTM			DATE			NOT NULL
) ON COMMIT PRESERVE ROWS;

@../csr_data_body

@update_tail