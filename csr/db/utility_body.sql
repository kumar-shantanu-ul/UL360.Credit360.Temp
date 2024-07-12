CREATE OR REPLACE PACKAGE BODY CSR.utility_pkg IS

PROCEDURE SearchForContract(
	in_text				IN	VARCHAR2,
	in_start_row	    IN	NUMBER,
	in_end_row			IN	NUMBER,
	in_sort_by			IN	VARCHAR2,
	in_sort_dir		    IN	VARCHAR2,
	out_cur			    OUT	security_pkg.T_OUTPUT_CUR
) IS
	v_search		VARCHAR2(4000);
	v_order_by		VARCHAR2(4000);
BEGIN
	v_order_by := 'utility_supplier_id';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'supplier_name,last_invoice_date,account_ref');
	END IF;
	v_search:=in_text;
	-- Excape filter string
	v_search := utils_pkg.RegexpEscape(v_search);
	-- Replace any number of white spaces with \s+
	v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');
	
	OPEN out_cur FOR
		'SELECT	' ||
			'SYS_CONTEXT(''SECURITY'',''APP'') app_sid, ' || -- APP SID Cheat
			'utility_supplier_id, supplier_name AS supplier_name, ' ||
			'utility_contract_id, account_ref, ' ||
			'from_dtm AS start_date, ' ||
			'to_dtm AS end_date, ' ||
			'last_invoice_date, ' ||
			'(SELECT MAX(utility_invoice_id) FROM csr.utility_invoice WHERE invoice_dtm = last_invoice_date) AS last_invoice_id, ' ||
			'total_rows, ' ||
			'prop_region_sid, ' ||
			'prop_region_desc ' ||
		'FROM ( ' ||
			'SELECT x.*, pr.region_sid prop_region_sid, pr.description prop_region_desc ' || 
				'FROM v$region pr, ( ' ||
					'SELECT UC.*, /*M.note, R.description,*/ ' ||
						'(SELECT MAX(invoice_dtm) FROM csr.utility_invoice WHERE utility_contract_id = UC.utility_contract_id) AS last_invoice_date,	' ||
						'US.supplier_name, ' ||
						'COUNT(*) OVER () AS total_rows, ' ||
						'ROWNUM AS rn ' ||
						'FROM csr.utility_contract UC, csr.utility_supplier US /*csr.all_meter M, csr.v$region R, */ ' ||
						'WHERE UC.utility_contract_id IN ( ' ||
								'SELECT utility_contract_id FROM csr.utility_contract WHERE utility_supplier_id IN ( ' ||
									'SELECT utility_supplier_id FROM csr.utility_supplier WHERE REGEXP_LIKE(supplier_name, :1, ''i'') ' ||
								') ' ||
							'UNION ' ||
								'SELECT utility_contract_id FROM csr.utility_contract WHERE REGEXP_LIKE(account_ref, :2, ''i'') ' ||
							'UNION ' ||
								'SELECT utility_contract_id FROM csr.utility_invoice WHERE REGEXP_LIKE(REFERENCE, :3, ''i'') ' ||
							'UNION ' ||
								'SELECT MUC.utility_contract_id FROM csr.v$region R, csr.all_meter M, meter_utility_contract MUC	' ||
								'WHERE ( ' ||
									'REGEXP_LIKE(R.description, :4, ''i'') OR ' ||
									'REGEXP_LIKE(M.note, :5, ''i'')	OR ' ||
									'REGEXP_LIKE(M.reference, :6, ''i'') ' ||
								') ' ||
								'AND M.region_sid = R.region_sid ' ||
								'AND MUC.region_sid = M.region_sid ' ||
						')	' ||
						'AND US.utility_supplier_id=UC.utility_supplier_id ' ||
						'AND UC.app_sid=SYS_CONTEXT(''SECURITY'',''APP'') ' ||
						'AND US.app_sid=SYS_CONTEXT(''SECURITY'',''APP'') ' ||
			') x ' ||
			'WHERE pr.region_sid(+) = csr.utility_pkg.GetPropRegionSidFromContractId(x.utility_contract_id) ' || 
			'ORDER BY ' || v_order_by	||
		') WHERE rn >= :7 AND rn < :8'
	USING v_search, v_search, v_search, v_search, v_search, v_search, in_start_row, in_end_row;
END;

PROCEDURE GetSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT utility_supplier_id, supplier_name, contact_details
		  FROM utility_supplier
		 WHERE utility_supplier_id = in_supplier_id;
END;

PROCEDURE DeleteSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE
)
AS
BEGIN
	-- Check capability
	IF NOT csr_data_pkg.CheckCapability('Delete Utility Supplier') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on capability ''Delete Utility Supplier''');
	END IF;
	
	DELETE FROM utility_supplier
	 WHERE utility_supplier_id = in_supplier_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveSupplier(
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	in_name					IN	utility_supplier.supplier_name%TYPE,
	in_contact				IN	utility_supplier.contact_details%TYPE,
	out_id					OUT	utility_supplier.utility_supplier_id%TYPE
)
AS
BEGIN
	out_id := in_supplier_id;
	IF out_id < 0 THEN
		out_id := NULL;
	END IF;
	
	-- XXX: this is a seriously bad idea which is likely
	-- to save dupes. Needs to use FK constraint
	
	-- Update supplier data
	IF out_id IS NULL THEN
		INSERT INTO utility_supplier
		  (utility_supplier_id, supplier_name, contact_details)
		  	VALUES (cms.item_id_seq.nextval, in_name, in_contact)
		  	  RETURNING utility_supplier_id INTO out_id;
	ELSE
		UPDATE utility_supplier
		   SET supplier_name = in_name,
		   	   contact_details = in_contact
		 WHERE utility_supplier_id = in_supplier_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE GetContract(
	in_contract_id			IN utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.utility_contract_id, c.utility_supplier_id, c.account_ref, 
			   c.from_dtm, c.to_dtm, c.alert_when_due, c.file_name, c.file_mime_type,
			   prop.region_sid prop_region_sid, prop.description prop_region_desc
		  FROM utility_contract c, v$region prop
		 WHERE utility_contract_id = in_contract_id
		   AND prop.region_sid(+) = GetPropRegionSidFromContractId(utility_contract_id)
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetSuppliers (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- I could check read access on the app SO but that would seem a bit pointless.
	
	OPEN out_cur FOR
		SELECT utility_supplier_id, supplier_name, contact_details
		  FROM utility_supplier
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetContracts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- RLS deals with access
	OPEN out_cur FOR
		SELECT x.utility_contract_id, x.utility_supplier_id, x.account_ref, x.from_dtm, x.to_dtm, 
			x.alert_when_due, x.file_name, x.file_mime_type, x.supplier_name, stragg(y.prop_region_desc) prop_region_desc
		  FROM (
			SELECT DISTINCT c.utility_contract_id, c.utility_supplier_id, c.account_ref, 
				c.from_dtm, c.to_dtm, c.alert_when_due, c.file_name, c.file_mime_type, s.supplier_name
			  FROM utility_contract c, utility_supplier s, meter_utility_contract muc
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND s.utility_supplier_id = c.utility_supplier_id
			   AND muc.utility_contract_id(+) = c.utility_contract_id
		  ) x, (
			SELECT DISTINCT c.utility_contract_id, pr.description prop_region_desc
			  FROM utility_contract c, meter_utility_contract muc, v$region pr
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND muc.utility_contract_id(+) = c.utility_contract_id
			   AND pr.region_sid(+) = utility_pkg.GetPropRegionSid(muc.region_sid)
		  ) y
		WHERE x.utility_contract_id = y.utility_contract_id
     	 GROUP BY x.utility_contract_id, x.utility_supplier_id, x.account_ref, x.from_dtm, x.to_dtm, 
     	 	x.alert_when_due, x.file_name, x.file_mime_type, x.supplier_name
     	 ORDER BY x.account_ref, x.from_dtm
     	;
END;

PROCEDURE GetContractsForSupplier (
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.utility_contract_id, c.utility_supplier_id, c.account_ref, 
			   c.from_dtm, c.to_dtm, c.alert_when_due, c.file_name, c.file_mime_type,
			   prop.region_sid prop_region_sid, prop.description prop_region_desc
		  FROM utility_contract c, v$region prop
		 WHERE utility_supplier_id = in_supplier_id
		   AND prop.region_sid(+) = GetPropRegionSidFromContractId(utility_contract_id)
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetMeterContract (
	in_meter_sid			IN	security_pkg.T_SID_ID,
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
)
AS
BEGIN
	-- Once again we check for read access here as we assume that if the user can see the region then thay can change stuff associated with it.
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_meter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'READ access denied when trying to write to region with sid '||in_meter_sid);
	END IF;
	
	BEGIN
		INSERT INTO meter_utility_contract
			(app_sid, region_sid, utility_contract_id)
		  VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_meter_sid, in_contract_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Already associated, ignore
	END;
	
	-- Make the new association the active one
	UPDATE meter_utility_contract
	   SET active = DECODE(utility_contract_id, in_contract_id, 1, 0)
	 WHERE region_sid = in_meter_sid;
END;

PROCEDURE SaveContract(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_supplier_id			IN	utility_supplier.utility_supplier_id%TYPE,
	in_account_ref			IN	utility_contract.account_ref%TYPE,
	in_from_dtm				IN	utility_contract.from_dtm%TYPE,
	in_to_dtm				IN	utility_contract.to_dtm%TYPE,
	in_alert_due			IN	utility_contract.alert_when_due%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_delete_file			IN	NUMBER,
	out_id					OUT	utility_contract.utility_contract_id%TYPE
)
AS
BEGIN
	
	out_id := in_contract_id;
	IF out_id < 0 THEN
		out_id := NULL;
	END IF;
	
	-- Update contract data
	IF out_id IS NULL THEN
		INSERT INTO utility_contract
		  (utility_contract_id, utility_supplier_id, account_ref, from_dtm, to_dtm, alert_when_due)
		  	VALUES (cms.item_id_seq.nextval, in_supplier_id, in_account_ref, in_from_dtm, in_to_dtm, in_alert_due)
		  	  RETURNING utility_contract_id INTO out_id;
	ELSE
		UPDATE utility_contract
		   SET account_ref = in_account_ref,
		   	   from_dtm = in_from_dtm,
		   	   to_dtm = in_to_dtm,
		   	   alert_when_due = in_alert_due
		 WHERE utility_contract_id = in_contract_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	-- Deal with file uplaods/deletes
	IF in_cache_key IS NOT NULL THEN
		UPDATE utility_contract
		   SET (file_data, file_mime_type, file_name) = (
		   	SELECT object, mime_type, filename
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		) WHERE utility_contract_id = out_id
		    AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSIF in_delete_file <> 0 THEN
		UPDATE utility_contract
		   SET file_data = NULL,
		   	   file_mime_type = NULL,
		   	   file_name = NULL
		 WHERE utility_contract_id = out_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
END;


PROCEDURE DeleteContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
)
AS
BEGIN
	-- Check capability
	IF NOT csr_data_pkg.CheckCapability('Delete Utility Contract') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on capability ''Delete Utility Supplier''');
	END IF;
	
	DELETE FROM utility_contract
	 WHERE utility_contract_id = in_contract_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE GetInvoicesForContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT utility_invoice_id, utility_contract_id, 
			reference, invoice_dtm, cost_value, cost_measure_sid, cost_conv_id, consumption, consumption_measure_sid, consumption_conv_id, file_name, file_mime_type,
			verified_by_sid, verified_dtm, usr.full_name verified_by_name
		  FROM utility_invoice ui, csr_user usr
		 WHERE ui.utility_contract_id = in_contract_id
		   AND usr.csr_user_sid(+) = ui.verified_by_sid
		   AND ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	ORDER BY invoice_dtm DESC;
END;


PROCEDURE GetInvoices (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetInvoices(NULL, NULL, out_cur);
END;

PROCEDURE GetInvoices (
	in_start_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_end_dtm				IN	utility_invoice.invoice_dtm%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	-- RLS deals with access
	OPEN out_cur FOR
		SELECT DISTINCT i.utility_invoice_id, i.utility_contract_id, 
			   i.reference, i.invoice_dtm, i.cost_value, i.cost_measure_sid, i.cost_conv_id, i.consumption, i.consumption_measure_sid, i.consumption_conv_id, i.file_name, i.file_mime_type,
			   c.account_ref, pr.region_sid prop_region_sid, pr.description prop_region_desc,
			   i.verified_by_sid, i.verified_dtm, usr.full_name verified_by_name
		  FROM utility_invoice i, utility_contract c, utility_supplier s, 
		       meter_utility_contract muc, v$region pr, csr_user usr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.utility_contract_id = c.utility_contract_id
		   AND s.utility_supplier_id = c.utility_supplier_id
		   AND muc.utility_contract_id(+) = c.utility_contract_id
		   AND pr.region_sid(+) = GetPropRegionSid(muc.region_sid)
		   AND invoice_dtm >= NVL(in_start_dtm, invoice_dtm)
		   AND invoice_dtm <= NVL(in_end_dtm - 1, invoice_dtm)
		   AND usr.csr_user_sid(+) = verified_by_sid
		   	ORDER BY invoice_dtm DESC;
END;

PROCEDURE SearchInvoices (
	in_search				IN	VARCHAR2,
	in_unverified_only		IN	NUMBER,
	in_start_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_end_dtm				IN	utility_invoice.invoice_dtm%TYPE,
	in_start_row			IN  NUMBER,
	in_end_row				IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search			VARCHAR2(4000);
	v_order_by			VARCHAR2(4000);
	v_unverified_only	NUMBER(1);
BEGIN
	-- Remote sorting
	v_order_by := 'invoice_dtm';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		-- TODO: decide on columns
		--utils_pkg.ValidateOrderBy(v_order_by, '');
	END IF;
	
	v_unverified_only := NULL;
	IF in_unverified_only <> 0 THEN
		v_unverified_only := -1;
	END IF;
	
	-- Deal with the filter string
	IF in_search IS NULL THEN
		-- Search string is zero length
		v_search := '.*';
	ELSE
		-- Escape filter string
		v_search := in_search;
		v_search := utils_pkg.RegexpEscape(v_search);
		-- Replace any number of white spaces with \s+
		v_search := REGEXP_REPLACE(v_search, '\s+', '\s+');
	END IF;
	
	OPEN out_cur FOR
		'SELECT * FROM (' ||
			'SELECT ROWNUM rn, COUNT(*) OVER () total_rows, x.* ' ||
			  'FROM (' ||
			  	'SELECT ' ||
			  		'utility_invoice_id, utility_contract_id, ' ||
					'reference, invoice_dtm, cost_value, consumption, file_name, file_mime_type,' ||
					'account_ref, stragg(prop_region_desc) prop_region_desc,' ||
					'verified_by_sid, verified_dtm, verified_by_name, ' ||
					'cost_unit_name, consumption_unit_name  ' ||
				'FROM ( ' ||
					'SELECT DISTINCT i.utility_invoice_id, i.utility_contract_id, ' ||
						'i.reference, i.invoice_dtm, i.cost_value, i.consumption, i.file_name, i.file_mime_type,' ||
						'c.account_ref, pr.description prop_region_desc,' ||
						'i.verified_by_sid, i.verified_dtm, usr.full_name verified_by_name, ' ||
						'NVL(c_cost.description, m_cost.description) cost_unit_name, NVL(c_cons.description, m_cons.description) consumption_unit_name  ' ||
					  'FROM utility_invoice i, meter_utility_contract muc, utility_contract c, utility_supplier s, all_meter m, region mr, v$region pr, csr_user usr, ' ||
					  	'measure m_cost, measure_conversion c_cost, measure m_cons, measure_conversion c_cons ' ||
					 'WHERE c.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') ' ||
					   'AND i.utility_contract_id = c.utility_contract_id ' ||
					   'AND s.utility_supplier_id = c.utility_supplier_id ' ||
					   'AND muc.utility_contract_id(+) = c.utility_contract_id ' ||
					   'AND m.region_sid(+) = muc.region_sid ' ||
					   'AND m.active = 1 ' ||
			           'AND mr.region_sid(+) = muc.region_sid ' ||
			           'AND mr.active = 1 ' ||
					   'AND pr.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid) ' ||
					   'AND invoice_dtm >= NVL(:1, invoice_dtm) ' ||
					   'AND invoice_dtm <= NVL(:2 - 1, invoice_dtm) ' ||
					   'AND NVL(verified_by_sid, -1) = NVL(:3, NVL(verified_by_sid, -1)) ' ||
					   'AND usr.csr_user_sid(+) = verified_by_sid ' ||
					   'AND m_cost.measure_sid(+) = i.cost_measure_sid ' ||
					   'AND c_cost.measure_conversion_id(+) = i.cost_conv_id ' ||
					   'AND m_cons.measure_sid(+) = i.consumption_measure_sid ' ||
					   'AND c_cons.measure_conversion_id(+) = i.consumption_conv_id ' ||
					   'AND ( ' ||
					   		-- Search params
					   	'	 REGEXP_LIKE(i.reference, :4, ''i'') ' ||
					   	' OR REGEXP_LIKE(c.account_ref, :5, ''i'') ' ||
					   	' OR REGEXP_LIKE(pr.description, :6, ''i'') ' ||
					   	' OR REGEXP_LIKE(usr.full_name, :7, ''i'') ' ||
					   ') ' ||	   
				') ' ||
				'GROUP BY '||
			   		'utility_invoice_id, utility_contract_id, ' ||
					'reference, invoice_dtm, cost_value, consumption, file_name, file_mime_type,' ||
					'account_ref, verified_by_sid, verified_dtm, verified_by_name, ' ||
					'cost_unit_name, consumption_unit_name ' ||
				'ORDER BY ' || v_order_by ||
			') x ' ||
		') WHERE rn >= :8 AND rn < :9'
	  USING 
	  	in_start_dtm,  		-- :1
	  	in_end_dtm, 		-- :2
	  	v_unverified_only, 	-- :3
	  	v_search, 			-- :4
	  	v_search, 			-- :5
	  	v_search, 			-- :6
	  	v_search, 			-- :7
	  	in_start_row, 		-- :8
	  	in_end_row; 		-- :9
END;


PROCEDURE GetAssocMetersForContract(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT x.region_sid, x.description, x.reference, x.last_reading_dtm, v.val_number
		  FROM (
		    SELECT m.region_sid, r.description, m.reference, MAX(start_dtm) last_reading_dtm
		      FROM meter_utility_contract muc, all_meter m, v$meter_reading v, v$region r
		     WHERE muc.utility_contract_id = in_contract_id
		       AND m.region_sid = muc.region_sid
		       AND m.active = 1
		       AND v.region_sid(+) = m.region_sid
		       AND r.region_sid = m.region_sid
		       AND r.active = 1
		       AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		        GROUP BY m.region_sid, r.description, m.reference
		) x, v$meter_reading v
		WHERE v.region_sid(+) = x.region_sid
		  AND v.start_dtm(+) = last_reading_dtm;
END;

PROCEDURE GetContractDocData(
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT utility_contract_id, file_mime_type, file_name, file_data
		  FROM utility_contract
		 WHERE utility_contract_id = in_contract_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveIvoiceFromReading(
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE
)
AS
	v_contract_id			utility_contract.utility_contract_id%TYPE;
	v_invoice_id			utility_invoice.utility_invoice_id%TYPE;
BEGIN
	
	v_contract_id := NULL;
	
	-- Check source type and data availability
	-- There must be one active contract for this to work
	FOR r IN (
		SELECT s.add_invoice_data, r.reference, r.cost, muc.utility_contract_id
		  FROM meter_source_type s, all_meter m, meter_utility_contract muc, v$meter_reading r
		 WHERE r.meter_reading_id = in_reading_id
		   AND m.region_sid = r.region_sid
		   AND muc.region_sid = r.region_sid
		   AND muc.active = 1
		   AND s.meter_source_type_id = m.meter_source_type_id
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		
		-- The meter source type must specify the add_invoice_data option
		-- The user will not expact any invoice data to be created
		-- If the source type does not specify this option
		IF r.add_invoice_data = 0 THEN
			RETURN;
		END IF;	
		
		-- The reference and cost data (which may not be mandatory on the form) must be available
		IF r.reference IS NULL OR r.cost IS NULL THEN
			-- TODO: We may want to warn the user at this stage?
			RETURN;
		END IF;
		
		-- The meter must have a contract associated with it
		IF r.utility_contract_id IS NULL THEN
			-- TODO: We may want to warn the user at this stage?
			RETURN;
		END IF;
		v_contract_id := r.utility_contract_id;
		
	END LOOP;
	
	-- The meter must have an active contract associated with it
	-- The query in the above loop may have returnde no results so check here
	IF v_contract_id IS NULL THEN
		RETURN;
	END IF;
	
	FOR r IN (
		SELECT r.meter_reading_id, r.start_dtm, r.reference, r.cost, 
			r.created_invoice_id, r.meter_document_id, r.consumption,
			r.primary_measure_sid, r.primary_measure_conversion_id, 
			r.cost_measure_sid, r.cost_measure_conversion_id,
			d.mime_type, d.file_name, d.data
		  FROM (
		  		SELECT r.meter_reading_id, r.start_dtm, r.reference, r.cost, r.created_invoice_id, r.meter_document_id, 
		  			CASE WHEN st.arbitrary_period = 0 THEN
		  				r.val_number - NVL(LEAD(r.val_number) OVER (ORDER BY r.start_dtm DESC), 0)
		  			ELSE
		  				r.val_number
		  			END consumption,
		  			pi.measure_sid primary_measure_sid, am.primary_measure_conversion_id, 
		  			ci.measure_sid cost_measure_sid, am.cost_measure_conversion_id
				  FROM v$meter_reading r, meter_reading sid_lookup, v$legacy_meter am, meter_source_type st, ind pi, ind ci
				 WHERE r.region_sid = sid_lookup.region_sid
				   AND sid_lookup.meter_reading_id = in_reading_id
				   AND am.region_sid = r.region_sid
		           AND st.meter_source_type_id = am.meter_source_type_id
		           AND am.primary_ind_sid = pi.ind_sid
		           AND am.cost_ind_sid(+) = ci.ind_sid
		  ) r, meter_document d
		 WHERE r.meter_reading_id = in_reading_id
		   AND d.meter_document_id(+) = r.meter_document_id
		   AND d.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		-- Save the invoice, note we always clear down the 
		-- document as we update it ourselves after the call
		
		--security_pkg.DebugMsg('cm: '||r.cost_measure_sid);
		--security_pkg.DebugMsg('cc: '||r.cost_measure_conversion_id);
		--security_pkg.DebugMsg('pm: '||r.primary_measure_sid);
		--security_pkg.DebugMsg('pc: '||r.primary_measure_conversion_id);
		
		SaveInvoice(
			r.created_invoice_id,
			v_contract_id,
			r.reference,
			r.start_dtm,
			r.cost,
			r.cost_measure_sid,
			r.cost_measure_conversion_id,
			r.consumption,
			r.primary_measure_sid,
			r.primary_measure_conversion_id,
			NULL,
			1, -- Delete existing document
			v_invoice_id
		);
		
		-- Update meter reading with the invoice id
		UPDATE meter_reading
		   SET created_invoice_id = v_invoice_id
		 WHERE meter_reading_id = in_reading_id;
		
		-- Update the documemnt if available
		IF r.meter_document_id IS NOT NULL THEN
			UPDATE utility_invoice
			   SET file_name = r.file_name,
			       file_mime_type = r.mime_type,
			       file_data = r.data
			 WHERE utility_invoice_id = v_invoice_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
		
	END LOOP;
END;


PROCEDURE SaveInvoice(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_reference			IN	utility_invoice.reference%TYPE,
	in_invoice_dtm			IN	utility_invoice.invoice_dtm%TYPE,
	in_cost_value			IN	utility_invoice.cost_value%TYPE,
	in_cost_measure_sid		IN	security_pkg.T_SID_ID,
	in_cost_conv_id			IN	utility_invoice.cost_conv_id%TYPE,
	in_consumption			IN	utility_invoice.consumption%TYPE,
	in_cons_measure_sid		IN	security_pkg.T_SID_ID,
	in_cons_conv_id			IN	utility_invoice.consumption_conv_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_delete_file			IN	NUMBER,
	out_id					OUT	utility_invoice.utility_invoice_id%TYPE
)
AS
BEGIN
	
	out_id := in_invoice_id;
	IF out_id < 0 THEN
		out_id := NULL;
	END IF;
	
	-- Update invoice data
	IF out_id IS NULL THEN
		INSERT INTO utility_invoice
		  (utility_invoice_id, utility_contract_id, reference, invoice_dtm, 
		  	cost_value, cost_measure_sid, cost_conv_id, 
		  	consumption, consumption_measure_sid, consumption_conv_id)
		  	VALUES (cms.item_id_seq.nextval, in_contract_id, in_reference, in_invoice_dtm, 
		  		in_cost_value, in_cost_measure_sid, in_cost_conv_id, 
		  		in_consumption, in_cons_measure_sid, in_cons_conv_id)
		  	  RETURNING utility_invoice_id INTO out_id;
	ELSE
		UPDATE utility_invoice
		   SET reference = in_reference,
		   	   invoice_dtm = in_invoice_dtm,
		   	   cost_value = in_cost_value,
		   	   cost_measure_sid = in_cost_measure_sid,
		   	   cost_conv_id = in_cost_conv_id,
		   	   consumption = in_consumption,
		   	   consumption_measure_sid = in_cons_measure_sid,
		   	   consumption_conv_id = in_cons_conv_id,
		   	   verified_by_sid = NULL,	-- TODO: need some sort of audit trail
		   	   verified_dtm = NULL
		 WHERE utility_invoice_id = in_invoice_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	-- Deal with file uplaods/deletes
	IF in_cache_key IS NOT NULL THEN
		UPDATE utility_invoice
		   SET (file_data, file_mime_type, file_name) = (
		   	SELECT object, mime_type, filename
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		) WHERE utility_invoice_id = out_id
		    AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSIF in_delete_file <> 0 THEN
		UPDATE utility_invoice
		   SET file_data = NULL,
		   	   file_mime_type = NULL,
		   	   file_name = NULL
		 WHERE utility_invoice_id = out_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

END;

PROCEDURE GetInvoiceDocData(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT utility_invoice_id, file_mime_type, file_name, file_data
		  FROM utility_invoice
		 WHERE utility_invoice_id = in_invoice_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteInvoice (
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE
)
AS
BEGIN
	-- Check capability
	IF NOT csr_data_pkg.CheckCapability('Delete Utility Invoice') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on capability ''Delete Utility Invoice''');
	END IF;
	
	DELETE FROM utility_invoice
	 WHERE utility_invoice_id = in_invoice_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AssociateMetersWithContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Once again we check for read access here as we assume that if the user can see the region then thay can change stuff associated with it.
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'READ access denied when trying to write to region with sid ' || in_region_sid);
	END IF;

	FOR r IN (
		SELECT region_sid
		  FROM (
		  	SELECT r.region_sid, DECODE (r.region_sid, m.region_sid, 1, 0) is_meter
			  FROM region r, all_meter m
			 WHERE m.region_sid(+) = r.region_sid
			   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			    START WITH r.region_sid = in_region_sid
			    CONNECT BY PRIOR r.region_sid = r.parent_sid
		)
		WHERE is_meter = 1 
	) LOOP
		BEGIN
			INSERT INTO meter_utility_contract
				(app_sid, region_sid, utility_contract_id)
			  VALUES (SYS_CONTEXT('SECURITY', 'APP'), r.region_sid, in_contract_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Already associated, ignore
		END;
		
		-- Make the new association the active one
		UPDATE meter_utility_contract
		   SET active = DECODE(utility_contract_id, in_contract_id, 1, 0)
		 WHERE region_sid = r.region_sid;
		
	END LOOP;
END;

PROCEDURE RemoveAssociationWithContract (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_active				meter_utility_contract.active%TYPE;
BEGIN
	-- Once again we check for read access here as we assume that if the user can see the region then thay can change stuff associated with it.
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'READ access denied when trying to write to region with sid ' || in_region_sid);
	END IF;

	SELECT active
	  INTO v_active
	  FROM meter_utility_contract
	 WHERE region_sid = in_region_sid
	   AND utility_contract_id = in_contract_id;

	DELETE FROM meter_utility_contract
	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	    AND region_sid = in_region_sid
	    AND utility_contract_id = in_contract_id;
	    
	IF v_active <> 0 THEN
		UPDATE meter_utility_contract
		   SET active = 1
		 WHERE region_sid = in_region_sid
		   AND ROWNUM = 1;
	END IF;
END;


PROCEDURE GetInvoice ( 
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT utility_invoice_id, utility_contract_id, 
			reference, invoice_dtm, cost_value, cost_measure_sid, cost_conv_id, consumption, consumption_measure_sid, consumption_conv_id, file_name, file_mime_type
		  FROM utility_invoice
		 WHERE utility_invoice_id = in_invoice_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAssocMetersForInvoice(
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT x.region_sid, x.description, x.reference, x.last_reading_dtm, v.val_number
		  FROM (
		    SELECT m.region_sid, r.description, m.reference, MAX(start_dtm) last_reading_dtm
              FROM utility_invoice i, utility_contract c, meter_utility_contract muc, 
                   v$region r, all_meter m, v$meter_reading v
             WHERE i.utility_invoice_id = in_invoice_id
               AND c.utility_contract_id = i.utility_contract_id
               AND muc.utility_contract_id = c.utility_contract_id
               AND m.region_sid = muc.region_sid
               AND r.region_sid = m.region_sid
               AND v.region_sid(+) = m.region_sid
               AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
                GROUP BY m.region_sid, r.description, m.reference
		) x, v$meter_reading v
		WHERE v.region_sid(+) = x.region_sid
		  AND v.start_dtm(+) = last_reading_dtm;
END;

FUNCTION GetPropRegionSid(
	in_child_region			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_prop_region_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT r.region_sid
		  INTO v_prop_region_sid
		  FROM region r, (
		    SELECT LEVEL lvl, MIN(LEVEL) over() min_lvl, region_sid 
		      FROM region
		     WHERE region_type = csr_data_pkg.REGION_TYPE_PROPERTY
		    START WITH region_sid = in_child_region
		    CONNECT BY PRIOR parent_sid = region_sid
		  ) x
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND r.region_sid = x.region_sid
		  AND x.lvl = x.min_lvl
		  AND ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_prop_region_sid := NULL;
	END;
	
	RETURN v_prop_region_sid;
END;

FUNCTION GetAgentRegionSid(
	in_child_region			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_prop_region_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT r.region_sid
		  INTO v_prop_region_sid
		  FROM region r, (
		    SELECT LEVEL lvl, MIN(LEVEL) over() min_lvl, region_sid 
		      FROM region
		     WHERE region_type = csr_data_pkg.REGION_TYPE_AGENT
		    START WITH region_sid = in_child_region
		    CONNECT BY PRIOR parent_sid = region_sid
		  ) x
		WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  AND r.region_sid = x.region_sid
		  AND x.lvl = x.min_lvl
		  AND ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_prop_region_sid := NULL;
	END;
	
	RETURN v_prop_region_sid;
END;


FUNCTION GetPropRegionSidFromContractId (
	in_contract_id			IN	utility_contract.utility_contract_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_prop_region_sid		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT DISTINCT utility_pkg.GetPropRegionSid(muc.region_sid)
	      INTO v_prop_region_sid
	      FROM meter_utility_contract muc
	  	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   AND muc.utility_contract_id = in_contract_id
	  	   AND ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_prop_region_sid := NULL;
	END;
	
	RETURN v_prop_region_sid;
END;

PROCEDURE GetInvoiceDateRange(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT MIN(invoice_dtm) min_dtm, MAX (invoice_dtm) max_dtm
		  FROM utility_invoice
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetMeterReadingsForInvoice (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_contract_id		utility_contract.utility_contract_id%TYPE;
BEGIN
	
	SELECT utility_contract_id
	  INTO v_contract_id
	  FROM utility_invoice
	 WHERE utility_invoice_id = in_invoice_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	OPEN out_cur FOR
		SELECT mr.meter_reading_id, mr.start_dtm reading_dtm, mr.val_number, mr.note, mr.reference, mr.cost,
				mr.entered_dtm, mr.entered_by_user_sid, usr.full_name entered_by_user_name
		  FROM (
			SELECT utility_invoice_id, utility_contract_id, invoice_dtm, LEAD(invoice_dtm) OVER (order by invoice_dtm desc) last_invoice_dtm
			  FROM utility_invoice ui WHERE utility_contract_id = v_contract_id
		) ui, utility_contract uc, meter_utility_contract muc, v$meter_reading mr, csr_user usr
		 WHERE ui.utility_invoice_id = in_invoice_id
		   AND uc.utility_contract_id = ui.utility_contract_id
		   AND muc.utility_contract_id = uc.utility_contract_id
		   AND mr.region_sid = muc.region_sid
		   AND mr.region_sid = muc.region_sid
		   AND mr.start_dtm >= ui.last_invoice_dtm
		   AND mr.start_dtm <= ui.invoice_dtm
		   AND usr.csr_user_sid = mr.entered_by_user_sid
		   AND muc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			ORDER BY reading_dtm DESC;
END;


PROCEDURE GetInvoiceVerificationData (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE,
	out_invoice			OUT security_pkg.T_OUTPUT_CUR,
	out_readings		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetInvoice(in_invoice_id, out_invoice);
	GetMeterReadingsForInvoice(in_invoice_id, out_readings);
END;


PROCEDURE VerifyInvoice (
	in_invoice_id		IN	utility_invoice.utility_invoice_id%TYPE
)
AS
BEGIN
	UPDATE utility_invoice
	   SET verified_by_sid = security_pkg.GetSID,
	   	   verified_dtm = SYSDATE
	 WHERE utility_invoice_id = in_invoice_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION LastInvoiceVerified(
	in_region_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_verified				NUMBER(1);
BEGIN
	SELECT DECODE(COUNT(*), 0, NULL, DECODE(COUNT(*), SUM(verified), 1, 0))
	  INTO v_verified
	  FROM (
		SELECT invoice_dtm, DECODE(verified_by_sid, NULL, 0, 1) verified, MAX(invoice_dtm) over () max_dtm
		  FROM all_meter m, meter_utility_contract muc, utility_invoice i
		 WHERE m.region_sid = in_region_sid
		   AND muc.region_sid = m.region_sid
		   AND i.utility_contract_id = muc.utility_contract_id
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) WHERE invoice_dtm = max_dtm;
	
	RETURN v_verified;
END;

PROCEDURE GetInvoiceFields (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT field_id, measure_sid, name, description
		  FROM utility_invoice_field
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetInvoiceFields (
	in_invoice_id			IN	utility_invoice.utility_invoice_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT f.field_id, f.measure_sid, f.name, f.description,
			v.utility_invoice_id, v.measure_conversion_id, v.val
		  FROM utility_invoice_field f, utility_invoice_field_val v
		 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND v.app_sid(+) = f.app_sid
		   AND v.field_id(+) = f.field_id
		   AND v.utility_invoice_id(+) = in_invoice_id;
END;


PROCEDURE GetInvoiceFieldsForReading (
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invoice_id			utility_invoice.utility_invoice_id%TYPE;
BEGIN
	SELECT created_invoice_id
	  INTO v_invoice_id
	  FROM v$meter_reading
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND meter_reading_id = in_reading_id;
	
	GetInvoiceFields(v_invoice_id, out_cur);
END;

PROCEDURE SaveInvoiceField (
	in_field_id				IN	utility_invoice_field_val.field_id%TYPE,
	in_invoice_id			IN	utility_invoice_field_val.utility_invoice_id%TYPE,
	in_conversion_id		IN	utility_invoice_field_val.measure_conversion_id%TYPE,
	in_val					IN	utility_invoice_field_val.val%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO utility_invoice_field_val
			(field_id, utility_invoice_id, measure_conversion_id, val)
		  VALUES (in_field_id, in_invoice_id, in_conversion_id, in_val);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE utility_invoice_field_val
			   SET measure_conversion_id = in_conversion_id,
			   	   val = in_val
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND field_id = in_field_id
			   AND utility_invoice_id = in_invoice_id;
	END;
END;

PROCEDURE SaveFieldForReading (
	in_reading_id			IN	meter_reading.meter_reading_id%TYPE,
	in_field_id				IN	utility_invoice_field_val.field_id%TYPE,
	in_conversion_id		IN	utility_invoice_field_val.measure_conversion_id%TYPE,
	in_val					IN	utility_invoice_field_val.val%TYPE
)
AS
	v_invoice_id			utility_invoice_field_val.utility_invoice_id%TYPE;
BEGIN
    BEGIN
	    SELECT created_invoice_id
	      INTO v_invoice_id
	      FROM v$meter_reading
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND meter_reading_id = in_reading_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_invoice_id IS NULL THEN
		RETURN;
	END IF;
	
	SaveInvoiceField(
		in_field_id,
		v_invoice_id,
		in_conversion_id,
		in_val
	);
END;

END utility_pkg;
/
