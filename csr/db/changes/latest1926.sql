-- Please update version.sql too -- this keeps clean builds in sync
define version=1926
@update_header

ALTER TABLE csr.dataview_zone ADD (is_target NUMBER(1, 0));
ALTER TABLE csr.dataview_zone ADD (target_direction NUMBER(1, 0));

UPDATE csr.dataview_zone SET is_target = 0;
UPDATE csr.dataview_zone SET target_direction = 0;

ALTER TABLE csr.dataview_zone MODIFY is_target DEFAULT 0 NOT NULL;
ALTER TABLE csr.dataview_zone MODIFY target_direction DEFAULT 0 NOT NULL;

ALTER TABLE csrimp.dataview_zone ADD (is_target NUMBER(1, 0));
ALTER TABLE csrimp.dataview_zone ADD (target_direction NUMBER(1, 0));

UPDATE csrimp.dataview_zone SET is_target = 0;
UPDATE csrimp.dataview_zone SET target_direction = 0;

ALTER TABLE csrimp.dataview_zone MODIFY is_target DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.dataview_zone MODIFY target_direction DEFAULT 0 NOT NULL;

@../dataview_pkg

@../dataview_body
@../schema_body
@../imp_body

@update_tail