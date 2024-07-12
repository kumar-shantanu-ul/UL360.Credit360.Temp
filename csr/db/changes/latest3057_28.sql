-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.DEDUPE_PP_ALT_COMP_NAME (
	APP_SID 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	COMPANY_SID 				NUMBER(10,0) NOT NULL,
	NAME 						VARCHAR2(255) NOT NULL,
	CONSTRAINT FK_DEDUPE_PP_ALT_COMP_NAME FOREIGN KEY (APP_SID, ALT_COMPANY_NAME_ID) REFERENCES CHAIN.ALT_COMPANY_NAME (APP_SID, ALT_COMPANY_NAME_ID),
	CONSTRAINT UK_DEDUPE_PP_ALT_COMP_NAME UNIQUE (APP_SID, ALT_COMPANY_NAME_ID, COMPANY_SID, NAME)
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_PP_ALT_COMP_NAME (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ALT_COMPANY_NAME_ID NUMBER(10) NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	NAME VARCHAR2(255) NOT NULL,
	CONSTRAINT FK_CHAIN_DEDU_PP_ALT_COMP_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE chain.dedupe_mapping ADD allow_create_alt_company_name NUMBER(1);
ALTER TABLE csrimp.chain_dedupe_mapping ADD allow_create_alt_company_name NUMBER(1);

ALTER TABLE chain.dedupe_merge_log ADD alt_comp_name_downgrade NUMBER(1);
ALTER TABLE csrimp.chain_dedupe_merge_log ADD alt_comp_name_downgrade NUMBER(1);

ALTER TABLE chain.dedupe_merge_log DROP CONSTRAINT chk_dedupe_merge_one_value_set;

ALTER TABLE chain.dedupe_merge_log ADD CONSTRAINT CHK_DEDUPE_MERGE_ONE_VALUE_SET CHECK ((
		CASE WHEN dedupe_field_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN reference_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN tag_group_id IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN destination_col_sid IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN role_sid IS NOT NULL THEN 1 ELSE 0 END
		+ CASE WHEN alt_comp_name_downgrade IS NOT NULL THEN 1 ELSE 0 END
		) = 1);

create index chain.ix_dedupe_pp_alt_comp_name on chain.dedupe_pp_alt_comp_name (app_sid, company_sid);

-- *** Grants ***
grant select on chain.dedupe_pp_alt_comp_name to csr;
grant select, insert, update on chain.dedupe_pp_alt_comp_name to csrimp;
grant select, insert, update, delete on csrimp.chain_dedupe_pp_alt_comp_name to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@ ../schema_pkg
@ ../schema_body
@ ../csrimp/imp_body
@ ../chain/dedupe_admin_pkg
@ ../chain/dedupe_admin_body
@ ../chain/company_dedupe_body
@ ../chain/dedupe_preprocess_body
@ ../chain/chain_body
@ ../chain/company_pkg
@ ../chain/company_body
@ ../../../aspen2/cms/db/tab_body

@update_tail
