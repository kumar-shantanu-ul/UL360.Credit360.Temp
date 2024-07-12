-- Please update version.sql too -- this keeps clean builds in sync
define version=984
@update_header

ALTER TABLE csr.excel_export_options
	ADD region_show_geo_country NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\excel_export_pkg.sql
@..\excel_export_body.sql

@..\..\..\postcode\db\geo_region_pkg
@..\..\..\postcode\db\geo_region_body


@update_tail
