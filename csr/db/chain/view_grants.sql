GRANT SELECT ON chain.v$filter_value TO cms;
GRANT SELECT ON chain.v$filter_field TO cms;
grant select on chain.v$company_user to cms;

grant select on chain.v$bsci_supplier to csr;
grant select on chain.v$bsci_2009_audit to csr;
grant select on chain.v$bsci_2014_audit to csr;
grant select on chain.v$bsci_ext_audit to csr;

GRANT SELECT ON chain.v$current_country_risk_level TO CSR;