define version=2025
@update_header

ALTER TABLE csr.issue_type ADD (
	helper_pkg		VARCHAR2(255)
);

ALTER TABLE csrimp.issue_type ADD (
	helper_pkg		VARCHAR2(255)
);

@@..\schema_body
@@..\csrimp\imp_body
@@..\issue_body

@update_tail