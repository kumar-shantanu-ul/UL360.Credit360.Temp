-- Please update version.sql too -- this keeps clean builds in sync
define version=190
@update_header

CREATE GLOBAL TEMPORARY TABLE IND_LIST
(
	IND_SID		NUMBER(10)	NOT NULL,
	POS			NUMBER(10)
) ON COMMIT DELETE ROWS;

@update_tail
