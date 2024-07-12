-- Please update version.sql too -- this keeps clean builds in sync
define version=308
@update_header

ALTER TABLE ind MODIFY core DEFAULT 1;
UPDATE ind SET core = 1 WHERE core IS NULL;
ALTER TABLE ind MODIFY core NOT NULL CHECK (core IN (0,1));

@update_tail
