CREATE OR REPLACE PACKAGE BODY ct.company_pkg AS

FUNCTION GetCompanyCurrency RETURN company.currency_id%TYPE
AS
	v_company_currency_id		company.currency_id%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	SELECT currency_id
	  INTO v_company_currency_id
	  FROM company
	 WHERE app_sid = security_pkg.getApp
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	   
	RETURN v_company_currency_id;
END;

PROCEDURE GetCompany(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCompany(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), out_cur);
END;

PROCEDURE GetCompany(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR 
		SELECT app_sid, company_sid, fte, turnover, currency_id, period_id, business_type_id, eio_id, 
		       scope_input_type_id, scope_1, scope_2
		  FROM company
	     WHERE company_sid = in_company_sid
	  ORDER BY company_sid;
END;

PROCEDURE SetCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_fte						IN  company.fte%TYPE,
	in_turnover					IN  company.turnover%TYPE,
	in_currency_id				IN  company.currency_id%TYPE,
	in_period_id				IN  company.period_id%TYPE,
	in_business_type_id			IN  company.business_type_id%TYPE,
	in_eio_id					IN  company.eio_id%TYPE,
	in_scope_input_type_id		IN  company.scope_input_type_id%TYPE,
	in_scope_1					IN  company.scope_1%TYPE,
	in_scope_2					IN  company.scope_2%TYPE
)
AS
	v_old_turnover				company.turnover%TYPE;
	v_old_fte					company.fte%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		INSERT INTO company (app_sid, company_sid, fte, turnover, currency_id, period_id, 
		                     business_type_id, eio_id, scope_input_type_id, scope_1, scope_2)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_company_sid, in_fte, in_turnover, in_currency_id, in_period_id,
           		in_business_type_id, in_eio_id, in_scope_input_type_id, in_scope_1, in_scope_2);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT turnover, fte INTO v_old_turnover, v_old_fte
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND company_sid = in_company_sid;
		
			UPDATE company
			   SET fte = in_fte, 
				   turnover = in_turnover, 
				   currency_id = in_currency_id, 
				   period_id = in_period_id, 
				   business_type_id = in_business_type_id, 
				   eio_id = in_eio_id,
				   scope_input_type_id = in_scope_input_type_id,
				   scope_1 = in_scope_1,
				   scope_2 = in_scope_2
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND company_sid = in_company_sid;
			
			breakdown_pkg.UpdateGroupBreakdownTurnover(in_turnover - v_old_turnover);
			breakdown_pkg.UpdateGroupBreakdownFte(in_fte - v_old_fte);
			
			-- Update group region eios
			breakdown_pkg.UpdateAllGroupRegionEios();	
	 END;	
END;

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid,  security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting company');
	END IF;
	
	FOR r IN (
		SELECT breakdown_type_id 
		  FROM breakdown_type 
		 WHERE company_sid = in_company_sid		
	) LOOP
		breakdown_type_pkg.DeleteBreakdownType(r.breakdown_type_id);
	END LOOP;
	
	FOR r IN (
		SELECT wfu.worksheet_id 
		  FROM chain.file_upload fu, chain.worksheet_file_upload wfu
		 WHERE fu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fu.app_sid = wfu.app_sid
		   AND fu.file_upload_sid = wfu.file_upload_sid
		   AND fu.company_sid = in_company_sid
	) LOOP
		excel_pkg.DeleteWorksheet(r.worksheet_id);
	END LOOP;
	
	DELETE FROM ct.bt_profile
	 WHERE (app_sid,company_sid) IN (
	    SELECT app_sid,company_sid
	      FROM ct.company
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_sid = in_company_sid
	);
	
	DELETE FROM ct.company_consumption_type
	 WHERE (app_sid,company_sid) IN (
	    SELECT app_sid,company_sid
	      FROM ct.company
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_sid = in_company_sid
	);
	
	DELETE FROM ct.ht_consumption_region
	 WHERE (app_sid,company_sid,ht_consumption_type_id,ht_consumption_category_id) IN (
	    SELECT app_sid,company_sid,ht_consumption_type_id,ht_consumption_category_id
	      FROM ct.ht_consumption
	     WHERE (app_sid,company_sid) IN (
	        SELECT app_sid,company_sid
	          FROM ct.company
	         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	           AND company_sid = in_company_sid
	    )
	);
	
	DELETE FROM ct.ht_cons_source_breakdown
	 WHERE (app_sid,company_sid) IN (
	    SELECT app_sid,company_sid
	      FROM ct.company
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_sid = in_company_sid
	);
	
	DELETE FROM ct.ht_consumption
	 WHERE (app_sid,company_sid) IN (
	    SELECT app_sid,company_sid
	      FROM ct.company
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_sid = in_company_sid
	);	
	
	DELETE FROM ct.ps_supplier_eio_freq
	 WHERE (app_sid,supplier_id) IN (
	    SELECT app_sid,supplier_id
	      FROM ct.supplier
	     WHERE (app_sid,owner_company_sid) IN (
	        SELECT app_sid,company_sid
	          FROM ct.company
	         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	           AND company_sid = in_company_sid
	    )
	);
		
	DELETE FROM ct.supplier_contact
	 WHERE (app_sid,supplier_id) IN (
	    SELECT app_sid,supplier_id
	      FROM ct.supplier
	     WHERE (app_sid,owner_company_sid) IN (
	        SELECT app_sid,company_sid
	          FROM ct.company
	         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	           AND company_sid = in_company_sid
	    )
	);
	
	DELETE FROM ct.worksheet_value_map_supplier
	 WHERE (app_sid,supplier_id) IN (
	    SELECT app_sid,supplier_id
	      FROM ct.supplier
	     WHERE (app_sid,owner_company_sid) IN (
	        SELECT app_sid,company_sid
	          FROM ct.company
	         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	           AND company_sid = in_company_sid
	    )
	);
	
	UPDATE supplier 
	   SET company_sid = NULL, status_id = ct_pkg.SS_NEWSUPPLIER 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	   
	DELETE FROM ct.supplier
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND owner_company_sid = in_company_sid;

	
	DELETE FROM ct.up_product
	 WHERE (app_sid,company_sid) IN (
	    SELECT app_sid,company_sid
	      FROM ct.company
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_sid = in_company_sid
	);
	
	UPDATE chain.customer_options
	   SET top_company_sid = NULL
	 WHERE top_company_sid = in_company_sid;

	DELETE FROM ct.company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
 	  AND company_sid = in_company_sid;
 	  
 	DELETE FROM csr.tab_portlet WHERE tab_id IN (
		SELECT tab_id 
		  FROM csr.tab 
		 WHERE portal_group IN ('CT Hotspotter - '||in_company_sid, 'CT Value Chain - '||in_company_sid)
		)
	  AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.tab_group WHERE tab_id IN (
		SELECT tab_id 
		  FROM csr.tab 
		 WHERE portal_group IN ('CT Hotspotter - '||in_company_sid, 'CT Value Chain - '||in_company_sid)
		)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	DELETE FROM csr.tab_user WHERE tab_id IN (
		SELECT tab_id 
		  FROM csr.tab 
		 WHERE portal_group IN ('CT Hotspotter - '||in_company_sid, 'CT Value Chain - '||in_company_sid)
		)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.tab 
	 WHERE portal_group IN ('CT Hotspotter - '||in_company_sid, 'CT Value Chain - '||in_company_sid)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END company_pkg;
/
