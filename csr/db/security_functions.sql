CREATE OR REPLACE FUNCTION csr.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN	
	-- Not logged on => see everything.  Support for old batch apps, should probably
	-- check for a special batch flag to work with the whole table?
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- Only show data if you are logged on and data is for the current application
	RETURN 'app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/

GRANT EXECUTE ON csr.appSidCheck TO chain;

CREATE OR REPLACE FUNCTION csr.nullableAppSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN	
	-- Not logged on => see everything.  Support for old batch apps, should probably
	-- check for a special batch flag to work with the whole table?
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- Only show data if you are logged on and data is for the current application, or app_sid is null
	RETURN 'app_sid IS NULL OR app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/

CREATE OR REPLACE FUNCTION csr.utilityContractCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- If the user has the "access all contracts" capability then return all rows.
	-- This is useful as contracts may not yet be associated with meters and there 
	-- needs to be a set of users who can see them in order to create the assocations.
	IF csr_data_pkg.CheckCapability('Access all contracts') THEN
		RETURN '';
	END IF;
	
	-- Otherwise base access on contracts associated with meters under the user's region mount point
	RETURN 'utility_contract_id IN (' ||
			'SELECT muc.utility_contract_id ' ||
			  'FROM all_meter am, meter_utility_contract muc ' ||
			 'WHERE muc.region_sid = am.region_sid ' ||
			   'AND am.region_sid IN (' ||
			    'SELECT region_sid ' ||
			      'FROM region ' ||
			        'START WITH region_sid IN (SELECT region_sid FROM region_start_point) '||
			        'CONNECT BY PRIOR region_sid = parent_sid ' ||
			  ') ' ||
		') ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = created_by_sid ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = 3';
end;
/

CREATE OR REPLACE FUNCTION csr.utilityInvoiceCheck (
	in_schema IN VARCHAR2, 
	in_object IN VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- If the user has the "access all contracts" capability then return all rows.
	-- This is useful as contracts may not yet be associated with meters and there 
	-- needs to be a set of users who can see them in order to create the assocations.
	IF csr_data_pkg.CheckCapability('Access All Contracts') THEN
		RETURN '';
	END IF;
	
	-- Otherwise base access on contracts associated with meters under the user's region mount point
	RETURN 'utility_contract_id IN (' ||
			'SELECT utility_contract_id ' ||
			  'FROM all_meter am, meter_utility_contract muc ' ||
			 'WHERE muc.region_sid = am.region_sid ' ||
			   'AND am.region_sid IN (' ||
			    'SELECT region_sid ' ||
			      'FROM region ' ||
			        'START WITH region_sid IN (SELECT region_sid FROM region_start_point) '||
			        'CONNECT BY PRIOR region_sid = parent_sid ' ||
			  ') ' ||
		') ' ||
		'OR SYS_CONTEXT(''SECURITY'',''SID'') = 3';
end;
/
