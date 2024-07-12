-- Please update version.sql too -- this keeps clean builds in sync
define version=2569
@update_header

-- CLEAN
--ALTER TABLE csr.tpl_report_tag_ind DROP CONSTRAINT fk_tag_measure_conversion;
--ALTER TABLE csr.tpl_report_tag_ind DROP (measure_conversion_id, format_mask);
--ALTER TABLE csrimp.tpl_report_tag_ind DROP (measure_conversion_id, format_mask);

ALTER TABLE csr.tpl_report_tag_ind ADD (
	measure_conversion_id NUMBER(10, 0) NULL,
	format_mask VARCHAR2(255) NULL,
	CONSTRAINT fk_tag_measure_conversion
		FOREIGN KEY (app_sid, measure_conversion_id)
		REFERENCES csr.measure_conversion
);

ALTER TABLE csrimp.tpl_report_tag_ind ADD (
	measure_conversion_id NUMBER(10, 0) NULL,
	format_mask VARCHAR2(255) NULL
);

@../templated_report_pkg
@../templated_report_body
@../measure_body

@update_tail
