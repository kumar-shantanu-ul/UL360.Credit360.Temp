-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE ADD (
	AUDIT_COORD_ROLE_OR_GROUP_SID				NUMBER(10)	NULL
);

ALTER TABLE CSRIMP.AUDIT_TYPE_FLOW_INV_TYPE ADD (
	USERS_ROLE_OR_GROUP_SID					NUMBER(10)	NULL
);

begin
	for r in (select 1 from all_Tables where owner='CHAIN' and table_name='FB87238_SAVED_FILTER_SENT_ALRT') loop
		execute immediate 'DROP TABLE chain.fb87238_saved_filter_sent_alrt';
	end loop;
end;
/

-- *** Grants ***
grant select on chain.bsci_audit to csr;
grant select on chain.bsci_associate to csr;
grant select on chain.bsci_finding to csr;
grant select on chain.bsci_supplier to csr;
grant insert on chain.bsci_audit to csrimp;
grant insert on chain.bsci_associate to csrimp;
grant insert on chain.bsci_finding to csrimp;
grant insert on chain.bsci_supplier to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../csrimp/imp_pkg

@../schema_body
@../csrimp/imp_body

@update_tail
