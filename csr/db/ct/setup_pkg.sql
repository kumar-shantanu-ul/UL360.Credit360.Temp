CREATE OR REPLACE PACKAGE ct.setup_pkg AS

PROCEDURE SetupHotspotter (
	in_overwrite_default_url	BOOLEAN DEFAULT TRUE,
	in_top_company_type			chain.company_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_company_type	chain.company_type.lookup_key%TYPE DEFAULT NULL
);

PROCEDURE SetupValueChain (
	in_overwrite_default_url	BOOLEAN DEFAULT TRUE,
	in_side_by_side				BOOLEAN DEFAULT TRUE,
	in_top_company_type			chain.company_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_company_type	chain.company_type.lookup_key%TYPE DEFAULT NULL
);

END setup_pkg;
/
