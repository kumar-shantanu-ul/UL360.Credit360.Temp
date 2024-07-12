-- Please update version.sql too -- this keeps clean builds in sync
define version=2999
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

grant select, insert, update, delete on csrimp.chain_bsci_associate to tool_user;
grant select, insert, update, delete on csrimp.chain_bsci_audit to tool_user;
grant select, insert, update, delete on csrimp.chain_bsci_finding to tool_user;
grant select, insert, update, delete on csrimp.chain_bsci_options to tool_user;
grant select, insert, update, delete on csrimp.chain_bsci_supplier to tool_user;
grant select, insert, update, delete on csrimp.chain_higg to tool_user;
grant select, insert, update, delete on csrimp.chain_project to tool_user;
grant select, insert, update, delete on csrimp.chain_scheduled_alert to tool_user;
grant select, insert, update, delete on csrimp.cms_tidy_ddl to tool_user;
grant select, insert, update, delete on csrimp.delegation_layout to tool_user;
grant select, insert, update, delete on csrimp.export_feed to tool_user;
grant select, insert, update, delete on csrimp.export_feed_cms_form to tool_user;
grant select, insert, update, delete on csrimp.export_feed_dataview to tool_user;
grant select, insert, update, delete on csrimp.export_feed_stored_proc to tool_user;
grant select, insert, update, delete on csrimp.forecasting_email_sub to tool_user;
grant select, insert, update, delete on csrimp.forecasting_indicator to tool_user;
grant select, insert, update, delete on csrimp.forecasting_region to tool_user;
grant select, insert, update, delete on csrimp.forecasting_rule to tool_user;
grant select, insert, update, delete on csrimp.forecasting_slot to tool_user;
grant select, insert, update, delete on csrimp.forecasting_val to tool_user;
grant select, insert, update, delete on csrimp.hide_portlet to tool_user;
grant select, insert, update, delete on csrimp.internal_audit_type_report to tool_user;
grant select, insert, update, delete on csrimp.issue_type_rag_status to tool_user;
grant select, insert, update, delete on csrimp.like_for_like_email_sub to tool_user;
grant select, insert, update, delete on csrimp.like_for_like_slot to tool_user;
grant select, insert, update, delete on csrimp.linked_meter to tool_user;
grant select, insert, update, delete on csrimp.meter_patch_batch_data to tool_user;
grant select, insert, update, delete on csrimp.meter_raw_data_log to tool_user;
grant select, insert, update, delete on csrimp.non_com_typ_rpt_audi_typ to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
