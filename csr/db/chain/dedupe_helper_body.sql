CREATE OR REPLACE PACKAGE BODY CHAIN.dedupe_helper_pkg
IS

FUNCTION GetImportSourceId(
	in_lookup_key		IN import_source.lookup_key%TYPE
)RETURN import_source.import_source_id%TYPE
AS
	v_import_source_id	import_source.import_source_id%TYPE;
BEGIN
	SELECT import_source_id
	  INTO v_import_source_id
	  FROM import_source
	 WHERE lower(lookup_key) = lower(in_lookup_key);
	 
	RETURN v_import_source_id;
END;

FUNCTION IsOwnedBySystem(
	in_import_source_id		IN import_source.import_source_id%TYPE
)RETURN BOOLEAN
AS
	v_is_owned_by_system NUMBER(1);
BEGIN
	SELECT is_owned_by_system
	  INTO v_is_owned_by_system
	  FROM import_source
	 WHERE import_source_id = in_import_source_id;
	 
	RETURN v_is_owned_by_system = 1;
END;


END dedupe_helper_pkg;
/
