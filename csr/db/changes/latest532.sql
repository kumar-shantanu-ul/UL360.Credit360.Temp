-- Please update version.sql too -- this keeps clean builds in sync
define version=532
@update_header

ALTER TABLE doc_folder
	RENAME COLUMN lifespan_override TO lifespan_is_override;
ALTER TABLE doc_folder
	RENAME COLUMN approver_override TO approver_is_override;

@update_tail
