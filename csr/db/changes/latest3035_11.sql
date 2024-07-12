-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.plugin add card_group_id number(10);
grant references on chain.card_group to csr;
alter table csr.plugin add constraint fk_plugin_chain_card_group foreign key (card_group_id) references chain.card_group (card_group_id);
create index csr.ix_plugin_card_group_id on csr.plugin (card_group_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
begin
	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'Audits tab', '/csr/site/chain/manageCompany/controls/AuditList.js',
		'Chain.ManageCompany.AuditList', 'Credit360.Chain.Plugins.AuditListPlugin', 'A list of audits associated with the supplier.');

	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 10, 'Audit request list tab', '/csr/site/chain/manageCompany/controls/AuditRequestList.js',
		'Chain.ManageCompany.AuditRequestList', 'Credit360.Chain.Plugins.AuditRequestListPlugin', 'A list of open audit requests for the supplier.');

	insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	values (csr.plugin_id_seq.nextval, 1, 'Audits tab', '/csr/site/property/properties/controls/AuditList.js',
		'Controls.AuditList', 'Credit360.Property.Plugins.AuditListPlugin', 'A list of audits associated with the property.');
	commit;
end;
/

begin
	-- this is overkill, but it doesn't hurt.
	update csr.plugin set card_group_id=23 where plugin_type_id in (10,11);
	update csr.plugin set card_group_id=42 where plugin_type_id in (13,14);
	update csr.plugin set card_group_id=46 where plugin_type_id = 16;
	commit;
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_report_pkg
@../audit_report_body
@../plugin_pkg
@../plugin_body

@update_tail
