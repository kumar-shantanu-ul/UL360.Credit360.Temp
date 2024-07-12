-- Please update version.sql too -- this keeps clean builds in sync
define version=1605
@update_header

INSERT INTO csr.tpl_region_type (tpl_region_type_id, label)
     VALUES (13, 'Bottom of tree');

INSERT INTO csr.tpl_region_type (tpl_region_type_id, label)
     VALUES (14, 'One level from bottom');

ALTER TABLE csr.tpl_report_tag_dv_region ADD (
	filter_by_tag	NUMBER(10, 0)
);

ALTER TABLE csrimp.tpl_report_tag_dv_region ADD (
	filter_by_tag	NUMBER(10, 0)
);

ALTER TABLE csr.tpl_report_tag_dv_region ADD CONSTRAINT fk_tpl_rp_tg_dv_rg_tag
FOREIGN KEY (app_sid, filter_by_tag) REFERENCES csr.tag (app_sid, tag_id);

CREATE INDEX csr.ix_tpl_rp_tg_dv_rg_tag ON csr.tpl_report_tag_dv_region (app_sid, filter_by_tag);

@../templated_report_pkg
@../templated_report_body
@../schema_body

@update_tail
