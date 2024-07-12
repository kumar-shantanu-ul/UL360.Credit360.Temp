-- Please update version.sql too -- this keeps clean builds in sync
define version=825
@update_header

ALTER TABLE CSR.LOGISTICS_TAB_MODE ADD (
	GET_AGGREGATES_SP	VARCHAR2(255)
);

UPDATE CSR.LOGISTICS_TAB_MODE SET GET_AGGREGATES_SP = REPLACE(GET_ROWS_SP, 'JobRows', 'Aggregates');

ALTER TABLE CSR.LOGISTICS_TAB_MODE MODIFY GET_AGGREGATES_SP NOT NULL;

@..\logistics_pkg
@..\logistics_body

@update_tail