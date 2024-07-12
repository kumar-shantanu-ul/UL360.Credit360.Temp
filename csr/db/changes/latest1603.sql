-- Please update version.sql too -- this keeps clean builds in sync
define version=1603
@update_header

ALTER TABLE csr.dataview ADD region_grouping_tag_group NUMBER(10, 0);

CREATE INDEX CSR.FK_DATAVIEW_TAG_GROUP ON csr.dataview(app_sid, region_grouping_tag_group)
;

ALTER TABLE csr.dataview ADD CONSTRAINT FK_DATAVIEW_TAG_GROUP
    FOREIGN KEY (app_sid, region_grouping_tag_group)
    REFERENCES csr.tag_group(app_sid, tag_group_id)
;

ALTER TABLE csrimp.dataview ADD region_grouping_tag_group NUMBER(10, 0);

@../dataview_pkg
@../dataview_body
@../schema_body
@../csrimp/imp_body

@update_tail
