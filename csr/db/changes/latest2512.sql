-- Please update version.sql too -- this keeps clean builds in sync
define version=2512
@update_header

ALTER TABLE csr.cms_imp_class_step ADD (
	ftp_sort_by_dir		VARCHAR2(10),
	CONSTRAINT chk_cms_imp_cls_stp_so_dir CHECK (ftp_sort_by_dir IN ('ASC','DESC') OR ftp_sort_by_dir IS NULL)
);

ALTER TABLE csr.cms_imp_instance_step ADD (
	payload_filename	VARCHAR2(255)
);

ALTER TABLE csr.cms_imp_class_step DROP CONSTRAINT chk_cms_imp_cls_stp_sep;
ALTER TABLE csr.cms_imp_class_step ADD CONSTRAINT chk_cms_imp_cls_stp_sep CHECK (dsv_separator IN ('PIPE','TAB','COMMA', 'SEMICOLON') OR dsv_separator IS NULL);

@../cms_data_imp_pkg;
@../cms_data_imp_body;

@update_tail
