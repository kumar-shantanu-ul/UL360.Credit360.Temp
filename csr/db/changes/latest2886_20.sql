-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.filter_item_config (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	card_id					NUMBER(10) NOT NULL,
	item_name				VARCHAR2(255) NOT NULL,
	company_tab_id			NUMBER(10),
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	include_in_filter		NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_breakdown	NUMBER(1) DEFAULT 0 NOT NULL,
	include_in_advanced		NUMBER(1) DEFAULT 0 NOT NULL,
	group_sid				NUMBER(10),
	path					VARCHAR2(1024),
	CONSTRAINT chk_fltr_itm_cfg_inc_fil_1_0 CHECK (include_in_filter IN (1, 0)),
	CONSTRAINT chk_fltr_itm_cfg_inc_brkd_1_0 CHECK (include_in_breakdown IN (1, 0)),
	CONSTRAINT chk_fltr_itm_cfg_inc_adv_1_0 CHECK (include_in_advanced IN (1, 0))
);

CREATE UNIQUE INDEX chain.uk_filter_item_config ON chain.filter_item_config(app_sid, card_group_id, card_id, item_name, company_tab_id, path);

CREATE TABLE csrimp.chain_filter_item_config (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	card_id					NUMBER(10) NOT NULL,
	item_name				VARCHAR2(255) NOT NULL,
	company_tab_id			NUMBER(10),
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	include_in_filter		NUMBER(1) NOT NULL,
	include_in_breakdown	NUMBER(1) NOT NULL,
	include_in_advanced		NUMBER(1) NOT NULL,
	group_sid				NUMBER(10),
	path					VARCHAR2(1024),
	CONSTRAINT chk_fltr_itm_cfg_inc_fil_1_0 CHECK (include_in_filter IN (1, 0)),
	CONSTRAINT chk_fltr_itm_cfg_inc_brkd_1_0 CHECK (include_in_breakdown IN (1, 0)),
	CONSTRAINT chk_fltr_itm_cfg_inc_adv_1_0 CHECK (include_in_advanced IN (1, 0))
);

CREATE UNIQUE INDEX csrimp.uk_filter_item_config ON csrimp.chain_filter_item_config(csrimp_session_id, card_group_id, card_id, item_name, company_tab_id, path);


-- Alter tables

-- *** Grants ***
GRANT SELECT ON chain.filter_item_config TO csr;
grant select, insert, update on chain.filter_item_config to csrimp;
grant select, insert, update, delete on csrimp.chain_filter_item_config to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO chain.filter_item_config (app_sid, card_group_id, card_id, item_name, label, pos, include_in_filter, include_in_breakdown, include_in_advanced)
SELECT cip.app_sid, cip.card_group_id, cip.card_id, 'invitationStatusId', 'Invitation status', 11,
	   CASE WHEN LOWER(cip.value)='true' THEN 0 ELSE 1 END,
	   CASE WHEN LOWER(cip.value)='true' THEN 0 ELSE 1 END,
	   CASE WHEN LOWER(cip.value)='true' THEN 0 ELSE 1 END
  FROM chain.card_init_param cip
 WHERE cip.key='hideInvitationStatusFilter';

DELETE FROM chain.card_init_param WHERE key='hideInvitationStatusFilter';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\filter_pkg
@..\schema_pkg
@..\supplier_pkg

@..\chain\filter_body
@..\chain\company_filter_body
@..\csrimp\imp_body
@..\schema_body
@..\supplier_body

@update_tail
