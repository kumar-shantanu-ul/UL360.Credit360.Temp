CREATE OR REPLACE PACKAGE BODY CSR.utility_report_pkg IS

PROCEDURE GetRegionTreeForExtract(
	in_start_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_cnt							NUMBER(10);
	v_billing_role_sid				security_pkg.T_SID_ID;
	v_reading_role_sid				security_pkg.T_SID_ID;
	v_meter_admin_role_sid			security_pkg.T_SID_ID;
BEGIN
	
	-- Check security on the mount point sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_start_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_start_sid);
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM role
     WHERE LOWER(name) = 'invoice owner';
	
	IF v_cnt > 0 THEN
		SELECT role_sid
	      INTO v_billing_role_sid	 
	      FROM role
	     WHERE LOWER(name) = 'invoice owner';
	END IF;
	
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM role
     WHERE LOWER(name) = 'meter administrator';
	
	IF v_cnt > 0 THEN
		SELECT role_sid
	      INTO v_meter_admin_role_sid	 
	      FROM role
	     WHERE LOWER(name) = 'meter administrator';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt	 
	  FROM role
	 WHERE LOWER(name) = 'meter reader';
	
	IF v_cnt > 0 THEN
		SELECT role_sid
	      INTO v_reading_role_sid	 
	      FROM role
	     WHERE LOWER(name) = 'meter reader';
	END IF;
	
	OPEN out_cur FOR
		SELECT x.*, extract(r.info_xml,'/').getClobVal() info_xml
		  FROM (
		  	-- x
			SELECT rn, lvl, region_sid, name, description, parent_sid, pos, active, link_to_region_sid, region_type,
				   geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, region_ref,
				   lookup_key, meter_ind_sid, meter_measure_conversion_id, meter_region_sid, meter_ref, meter_source_type_id, meter_source_type_name, 
				   meter_source_type_desc, prop_region_sid, prop_desc, prop_lookup_key, prop_region_ref, is_core, 
				   stragg(utility_supplier_id) utility_supplier_id, stragg(supplier_name) supplier_name, stragg(supplier_contact) supplier_contact, 
				   stragg(billing_full_name) billing_full_name, stragg(reading_full_name) reading_full_name, 
				   last_invoice_verified, uplift_required
			FROM (
			  SELECT tree.rn, tree.lvl, r.region_sid, r.name, r.description, r.parent_sid, r.pos, r.active, r.link_to_region_sid, r.region_type,
					 r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref,  r.geo_type, r.disposal_dtm, r.acquisition_dtm, 
					 r.lookup_key, r.region_ref, m.primary_ind_sid meter_ind_sid, m.primary_measure_conversion_id meter_measure_conversion_id, 
					 m.region_sid meter_region_sid, m.reference meter_ref, mst.meter_source_type_id, mst.name meter_source_type_name, mst.description meter_source_type_desc, 
					 prop.region_sid prop_region_sid, prop.description prop_desc, prop.lookup_key prop_lookup_key, prop.region_ref prop_region_ref, m.is_core, --ind.core is_core,
					 sup.utility_supplier_id, sup.supplier_name, sup.contact_details supplier_contact,
					 billing_usr.full_name billing_full_name, reading_usr.full_name reading_full_name,
					 utility_pkg.LastInvoiceVerified(m.region_sid) last_invoice_verified,
					 meter_pkg.MissingReadingInPastMonths(m.region_sid, 6) uplift_required -- past six months hard coded
		        FROM (
		        	-- r	
		        	SELECT r.region_sid, LEVEL lvl, ROWNUM rn
		          	  FROM (
		             	SELECT parent_sid, region_sid, description, link_to_region_sid, active
		              	  FROM v$region
		             	 WHERE app_sid = security_pkg.GetApp
		            	UNION
		            	SELECT parent_sid_id parent_sid, region_tree_root_sid, so.name description, NULL link_to_region_sid, 1 active
		              	  FROM region_tree rt, security.securable_object so
		             	 WHERE so.sid_id = rt.region_tree_root_sid
		               	   AND rt.app_sid = security_pkg.GetApp
		          ) r
		         START WITH region_sid = in_start_sid 
			         CONNECT BY PRIOR NVL(link_to_region_sid, region_Sid) = parent_sid
			         	ORDER SIBLINGS BY DESCRIPTION
		      ) tree, v$region r, v$legacy_meter m, meter_source_type mst, v$region prop, ind,
		        meter_utility_contract muc, utility_contract con, utility_supplier sup, 
		        region_role_member billing_rrm, csr_user billing_usr, 
		        region_role_member reading_rrm, csr_user reading_usr
			 WHERE r.region_sid = tree.region_sid
			   AND m.region_sid(+) = r.region_sid
			   AND mst.meter_source_type_id(+) = m.meter_source_type_id
			   AND prop.region_sid(+) = utility_pkg.GetPropRegionSid(m.region_sid)
			   AND ind.ind_sid(+) = m.primary_ind_sid
			   AND muc.region_sid(+) = r.region_sid
			   AND con.utility_contract_id(+) = muc.utility_contract_id
			   AND sup.utility_supplier_id(+) = con.utility_supplier_id
			   AND billing_rrm.region_sid(+) = m.region_sid
			   AND billing_usr.csr_user_sid(+) = billing_rrm.user_sid
			   AND reading_rrm.role_sid(+) = v_reading_role_sid
			   AND reading_rrm.region_sid(+) = m.region_sid
			   AND reading_usr.csr_user_sid(+) = reading_rrm.user_sid
			   AND billing_rrm.role_sid(+) IN (v_billing_role_sid, v_meter_admin_role_sid)
			)
			GROUP BY rn, lvl, region_sid, name, description, parent_sid, pos, active, link_to_region_sid, region_type,
				geo_latitude, geo_longitude, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, geo_type, disposal_dtm, acquisition_dtm, region_ref,
				lookup_key, meter_ind_sid, meter_measure_conversion_id, meter_region_sid, meter_ref, meter_source_type_id, meter_source_type_name, 
				meter_source_type_desc, prop_region_sid, prop_desc, prop_lookup_key, prop_region_ref, is_core, last_invoice_verified, uplift_required
		) x, region r
		WHERE r.region_sid = x.region_sid
		  ORDER BY x.rn; -- maintain tree specified ordering
END;

PROCEDURE GetDocumentsForRegion (
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_proc_docs					OUT	SYS_REFCURSOR,
	out_proc_files					OUT	SYS_REFCURSOR,
	out_reading_files				OUT	SYS_REFCURSOR,
	out_contract					OUT	SYS_REFCURSOR,
	out_invoices					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_proc_docs FOR 
		SELECT dd.mime_type, dv.filename file_name, rpd.doc_id, dd.data
		  FROM region_proc_doc rpd, doc_current dc, doc_version dv, doc_data dd
		 WHERE rpd.region_sid = in_region_sid
		   AND dc.doc_id = rpd.doc_id
		   AND dv.doc_id = dc.doc_id
		   AND dv.version = dc.version
		   AND dv.doc_data_id = dd.doc_data_id;
		   
	OPEN out_proc_files FOR
		SELECT md.mime_type, md.file_name, md.meter_document_id doc_id, md.data
		  FROM meter_document md, region_proc_file rpf
		 WHERE rpf.region_sid = in_region_sid
		   AND md.meter_document_id = rpf.meter_document_id;
		   
	OPEN out_reading_files FOR
		SELECT md.mime_type, md.file_name, mr.start_dtm, NULL doc_id, md.data
		  FROM meter_document md, v$meter_reading mr
		 WHERE mr.region_sid = in_region_sid
		   AND md.meter_document_id = mr.meter_document_id;
		   
	OPEN out_contract FOR
		SELECT file_mime_type mime_type, file_data data, NULL doc_id, file_name
		  FROM utility_contract uc, meter_utility_contract muc
		 WHERE muc.region_sid = in_region_sid
		   AND uc.utility_contract_id = muc.utility_contract_id;
		   
	OPEN out_invoices FOR
		SELECT file_mime_type mime_type, file_name, ui.invoice_dtm, NULL doc_id, file_data data
		  FROM utility_invoice ui, meter_utility_contract muc
		 WHERE muc.region_sid = in_region_sid
		   AND ui.utility_contract_id = muc.utility_contract_id;
		   
END;

PROCEDURE SuppliersWithoutContracts (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by				VARCHAR2(4000);
BEGIN
	
	v_order_by := 'supplier_name';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'supplier_name,contact_details');
	END IF;
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
			' SELECT utility_supplier_id, supplier_name, contact_details,'||
				' ROWNUM rn, COUNT(*) OVER () AS total_rows'||
			  ' FROM utility_supplier'||
			 ' WHERE utility_supplier_id NOT IN ('||
			 	' SELECT utility_supplier_id'||
			 	  ' FROM utility_contract'||
			 ' )'||
			 	' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :1 AND rn < :2'
		 	USING in_start_row, in_end_row;
END;

PROCEDURE GetMeterRoles (
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT m.region_sid, r.role_sid, r.name, u.csr_user_sid, u.full_name
		  FROM all_meter m, region_role_member rrm, role r, csr_user u
		 WHERE rrm.region_sid = m.region_sid
		   AND r.role_sid = rrm.role_sid
		   AND r.is_metering = 1
		   AND u.csr_user_sid = rrm.user_sid;
END;


PROCEDURE MetersWithoutContracts (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by				VARCHAR2(4000);
BEGIN	
	v_order_by := 'meter';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter,property,note,reference,active');
	END IF;
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
		  	' SELECT x.*'||
		  	  ' FROM ('||
				' SELECT m.region_sid, r.description meter, prop.description property, m.note, m.reference,'||
					' ROWNUM rn, COUNT(*) OVER () AS total_rows'||
				  ' FROM v$meter m, v$region r, v$region prop'||
				 ' WHERE r.region_sid = m.region_sid'||
				   ' AND r.active > 0'||
				   ' AND m.crc_meter > 0'||
				   ' AND prop.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid)'||
				   ' AND m.region_sid IN ('||
				   		' SELECT region_sid'||
				   		  ' FROM region'||
				   		  	' START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP''))'||
				   		  	' CONNECT BY PRIOR region_sid = parent_sid'||
				   ' )'||
				   ' AND m.region_sid NOT IN ('||
					   ' SELECT region_sid'||
					     ' FROM meter_utility_contract'||
					' )'||
		 	  ' ) x'||
		 	' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :1 AND rn < :2'
		 	USING in_start_row, in_end_row;
END;


PROCEDURE CRCMeterContractExpired (
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir						IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by			VARCHAR2(4000);
BEGIN
	v_order_by := 'meter';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter,property,indicator_name,reference,note');
	END IF;
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
			  ' SELECT x.*'||
			    ' FROM ('||
					'SELECT m.region_sid, r.description meter, prop.description property, m.note, m.reference, uc.from_dtm, uc.to_dtm, '||
							'ROWNUM rn, COUNT(*) OVER () AS total_rows'||
					' FROM v$meter m'||
					' JOIN v$region r ON r.region_sid = m.region_sid'||
					' JOIN meter_utility_contract mu ON m.region_sid = mu.region_sid AND mu.active = 1'||
					' JOIN utility_contract uc ON mu.utility_contract_id = uc.utility_contract_id'||
					' LEFT JOIN v$region prop ON prop.region_sid = csr.utility_pkg.GetPropRegionSid(m.region_sid) '||
					'WHERE r.active > 0'||
					'  AND m.crc_meter > 0'||
					'  AND (uc.to_dtm IS NULL OR uc.to_dtm <= SYSDATE)'||
					'  AND m.region_sid IN ('||
						'SELECT region_sid'||
						'  FROM region '||
							'START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP'')) '||
							'CONNECT BY PRIOR region_sid = parent_sid'||
						')'||
			 	' ) x' ||
			 ' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :1 AND rn < :2'
		USING in_start_row, in_end_row;
END;

PROCEDURE MetersMissingPeriodData (
	in_period_months				IN	NUMBER,
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by				VARCHAR2(4000);
	v_period_months			NUMBER(10);
BEGIN
	v_period_months := in_period_months;
	IF v_period_months < 0 THEN
		v_period_months := NULL;
	END IF;
	
	v_order_by := 'meter';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter,property,note,reference,active,last_reading_dtm');
	END IF;
		
	IF v_period_months IS NULL THEN
		-- Meters without any readings
		OPEN out_cur FOR
			' SELECT x.*'||
			  ' FROM ('||
			  	' SELECT x.*'||
				  ' FROM ('||
					' SELECT m.region_sid, r.description meter, prop.description property, m.reference, m.note, NULL last_reading_dtm,'||
						' ROWNUM rn, COUNT(*) OVER () AS total_rows'||
					  ' FROM v$region r, v$meter m, v$region prop'||
					 ' WHERE r.region_sid = m.region_sid'||
					   ' AND prop.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid)'||
					   ' AND r.active > 0'||
					   ' AND m.crc_meter > 0'||
					   ' AND m.region_sid NOT IN ('||
					   		' SELECT region_sid'||
					   		  ' FROM v$meter_reading'||
						' )'||
					   ' AND m.region_sid IN ('||
				   		' SELECT region_sid'||
				   		  ' FROM region'||
						    ' START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP''))'||
				   		  	' CONNECT BY PRIOR region_sid = parent_sid'||
				   		' )'||
			 	   ' ) x '||
			 	' ORDER BY ' || v_order_by ||
			 ' ) x '||
		 	 ' WHERE rn >= :1 AND rn < :2'
		 	 	USING in_start_row, in_end_row;
	ELSE
		-- Meters without readings in the last N months
		OPEN out_cur FOR
			'SELECT x.*'||
			  ' FROM ('||
				  'SELECT x.*'||
				  ' FROM ('||
					' SELECT m.region_sid, r.description meter, prop.description property, m.reference, m.note, x.last_reading_dtm,'||
						' ROWNUM rn, COUNT(*) OVER () AS total_rows'||
					  ' FROM ('||
					' SELECT m.region_sid, NVL(MAX(r.end_dtm), MAX(r.start_dtm)) last_reading_dtm,'||
						' CASE'||
							' WHEN r.region_sid IS NULL THEN 1'||
							' WHEN TRUNC(SYSDATE, ''MONTH'') > ADD_MONTHS(TRUNC(NVL(MAX(r.end_dtm), MAX(r.start_dtm)), ''MONTH''), :1) THEN 1 '||
							' ELSE 0'||
						' END missing_reading'||
						  ' FROM all_meter m, v$meter_reading r'||
						 ' WHERE r.region_sid(+) = m.region_sid'||
					    '  GROUP BY m.region_sid, r.region_sid'||
					' ) x, v$meter m, v$region r, v$region prop'||
					' WHERE x.missing_reading = 1'||
					  ' AND m.region_sid = x.region_sid'||
					  ' AND r.region_sid = m.region_sid'||
					  ' AND r.active > 0'||
					  ' AND m.crc_meter > 0'||
					  ' AND prop.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid)'||
					  ' AND m.region_sid IN ('||
				   		' SELECT region_sid'||
				   		  ' FROM region'||
							' START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP''))'||
				   		  	' CONNECT BY PRIOR region_sid = parent_sid'||
				   		' )'||
		 		' ) x'||
		 	' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :2 AND rn < :3'
		 	USING v_period_months, in_start_row, in_end_row;
	END IF;
END;

PROCEDURE SpecialEventsForTree (
	in_start_sid					IN	security_pkg.T_SID_ID,
	in_show_inherited				IN	NUMBER,
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	in_start_dtm					IN	EVENT.EVENT_DTM%TYPE,
	in_end_dtm						IN	EVENT.EVENT_DTM%TYPE,	
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_date_filter					VARCHAR2(100);
BEGIN
	IF in_start_dtm IS NOT NULL AND in_end_dtm IS NOT NULL THEN 
		v_date_filter := ' AND event_dtm BETWEEN '''|| in_start_dtm || ''' AND ''' || in_end_dtm ||'''';
	END IF; 
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
		  ' SELECT sel.description selected_region, prop.description property, x.*, ROWNUM rn, COUNT(*) OVER () AS total_rows'||
		    ' FROM v$region sel, v$region prop, ('||
		    ' SELECT r.region_sid, r.description meter_or_region, '||
		        ' DECODE (e.raised_for_region_sid, r.region_sid, 0, DECODE(e.raised_for_region_sid, NULL, NULL, 1)) inherited,'||
		        ' e.event_id, label, raised_dtm, event_dtm, raised_for_region_sid, /*event_text,*/ rf.description raised_for_region, cu.full_name raised_by'||
		      ' FROM event e, region_event re, v$region rf, csr_user cu, v$region r'||
		     ' WHERE r.region_sid IN ('||
		         ' SELECT region_sid'||
		            ' FROM region'||
		              ' START WITH region_sid = :1'||
		              ' CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid  '||
		       ' )'||
		       ' AND r.active = 1'||
		       ' AND re.region_sid = r.region_sid'||
		       ' AND e.event_id = re.event_id'||
		       ' AND cu.csr_user_sid(+) = e.raised_by_user_sid'||
		       ' AND rf.region_sid(+) = e.raised_for_region_sid'||
		       v_date_filter ||
		        ' ORDER BY raised_dtm DESC, event_id'||
		   ' ) x'||
		   ' WHERE NVL(x.inherited, 0) < DECODE (:2, 0, 1, 2)'||
		     ' AND sel.region_sid = :3'||
		     ' AND prop.region_sid(+) = utility_pkg.GetPropRegionSid(x.region_sid)'||
		 ' ) x'||
		 ' WHERE rn >= :4 AND rn < :5'
		 	USING in_start_sid, in_show_inherited, in_start_sid, in_start_row, in_end_row;
END;

PROCEDURE MetersFlaggedCRCndicatorsNot (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by						VARCHAR2(4000);
BEGIN
	v_order_by := '';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter_name,property,indicator_name,reference,note');
	END IF;
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
			  ' SELECT x.*'||
			    ' FROM ('||
					' SELECT m.region_sid, r.description meter_name, prop.description property, i.description indicator_name, m.reference, m.note, '||
						' ROWNUM rn, COUNT(*) OVER () total_rows'||
					  ' FROM v$legacy_meter m, v$ind i, v$region r, v$region prop'||
					 ' WHERE r.region_sid = m.region_sid'||
					   ' AND i.ind_sid = m.primary_ind_sid'||
					   ' AND m.crc_meter > 0'||
					   ' AND NVL(i.ind_activity_type_id, 1) NOT IN (2, 3)'||
					   ' AND prop.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid)'||
					   ' AND r.active > 0'||
					   ' AND m.region_sid IN ('||
					   		' SELECT region_sid'||
					   		  ' FROM region'||
								' START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP''))'||
					   		  	' CONNECT BY PRIOR region_sid = parent_sid'||
					   ' )'||
			 	' ) x' ||
			 ' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :1 AND rn < :2'
		   	USING in_start_row, in_end_row; 
	
END;

PROCEDURE IndicatorsFlaggedCRCMetersNot (
	in_start_row	    			IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir		    			IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by						VARCHAR2(4000);
BEGIN
	v_order_by := 'meter_name';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'meter_name,property,indicator_name,reference,note');
	END IF;
	
	OPEN out_cur FOR
		' SELECT x.*'||
		  ' FROM ('||
			  ' SELECT x.*'||
			    ' FROM ('||
					' SELECT m.region_sid, r.description meter_name, prop.description property, i.description indicator_name, m.reference, m.note, '||
						' ROWNUM rn, COUNT(*) OVER () total_rows'||
					  ' FROM v$legacy_meter m, v$ind i, v$region r, v$region prop'||
					 ' WHERE r.region_sid = m.region_sid'||
					   ' AND i.ind_sid = m.primary_ind_sid'||
					   ' AND m.crc_meter = 0'||
					   ' AND NVL(i.ind_activity_type_id, 1) IN (2, 3)'||
					   ' AND prop.region_sid(+) = csr.utility_pkg.GetPropRegionSid(m.region_sid)'||
					   ' AND r.active > 0'||
					   ' AND m.region_sid IN ('||
					   		' SELECT region_sid'||
					   		  ' FROM region'||
								' START WITH region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT(''SECURITY'', ''APP''))'||
					   		  	' CONNECT BY PRIOR region_sid = parent_sid'||
					   ' )'||
			 	' ) x' ||
			 ' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :1 AND rn < :2'
		   	USING in_start_row, in_end_row;
END;

PROCEDURE GetCRCMeterDump (
	out_roles						OUT	SYS_REFCURSOR,
	out_dump						OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetCRCMeterDump(null, null, out_roles, out_dump);
END;

PROCEDURE GetCRCMeterDump (
	in_from_dtm						IN DATE,
	in_to_dtm						IN DATE,
	out_roles						OUT	SYS_REFCURSOR,
	out_dump						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_roles FOR
		SELECT m.region_sid, r.name role_name, stragg(u.full_name) user_names
		  FROM all_meter m, region_role_member rrm, role r, csr_user u
		 WHERE m.crc_meter = 1
		   AND m.active = 1
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.region_sid = m.region_sid
		   AND r.role_sid = rrm.role_sid
		   AND r.is_metering = 1
		   AND u.csr_user_sid = rrm.user_sid
		   	GROUP BY m.region_sid, r.name	
		UNION ALL
		-- Hmm - I've selected the role sid here as using null changes the value of the returned type from long to decimal.
		-- The role sid will definitely not match any of the region sids from the query below so shouldn't cause a problem.
		SELECT role_sid region_sid, name role_name, NULL user_names
		  FROM role
		 WHERE is_metering = 1
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		;
	
	OPEN out_dump FOR
		SELECT m.region_sid,
			   prop.description property_name,
			   agent.description managing_agent,
			   DECODE(r.region_type, csr_data_pkg.REGION_TYPE_RATE, pr.description || ' - ' || r.description, r.description) meter_description,
			   mst.description source_type,
			   i.description indicator,
			   m.reference,
			   us.supplier_name supplier,
			   uc.account_ref contract_ref,
			   uc.to_dtm contract_expiry,
			   i_count.invoice_count invoice_count,
			   i_count.consumption invoice_consumption,
			   DECODE(mc.description, null, msr.description, mc.description) unit,
			   e_count.event_count event_count
		  FROM v$legacy_meter m
		  JOIN v$region r ON r.region_sid = m.region_sid
		  JOIN meter_source_type mst ON mst.meter_source_type_id = m.meter_source_type_id
		  LEFT JOIN v$region pr ON pr.region_sid = r.parent_sid
		  LEFT JOIN v$region prop ON prop.region_sid = csr.utility_pkg.GetPropRegionSid(m.region_sid)
		  LEFT JOIN v$region agent ON agent.region_sid = csr.utility_pkg.GetAgentRegionSid(m.region_sid)
		  LEFT JOIN v$ind i ON i.ind_sid = m.primary_ind_sid
		  LEFT JOIN measure msr ON i.measure_sid = msr.measure_sid
		  LEFT JOIN measure_conversion mc ON m.primary_measure_conversion_id = mc.measure_conversion_id
		  LEFT JOIN meter_utility_contract muc ON muc.region_sid = m.region_sid
		  LEFT JOIN utility_contract uc ON uc.utility_contract_id = muc.utility_contract_id
		  LEFT JOIN utility_supplier us ON us.utility_supplier_id = uc.utility_supplier_id
		  LEFT JOIN (
				SELECT m.region_sid, uc.utility_supplier_id,
					   COUNT(ui.utility_invoice_id) invoice_count,
					   SUM(ui.consumption) consumption
				  FROM all_meter m, meter_utility_contract muc, utility_contract uc, utility_invoice ui
				 WHERE m.crc_meter = 1
				   AND m.active = 1
				   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND muc.region_sid = m.region_sid
				   AND uc.utility_contract_id = muc.utility_contract_id
				   AND ui.utility_contract_id = uc.utility_contract_id
				   AND (in_from_dtm IS NULL OR ui.invoice_dtm >= in_from_dtm)
				   AND (in_to_dtm IS NULL OR ui.invoice_dtm < in_to_dtm)
				 GROUP BY m.region_sid, uc.utility_supplier_id
				) i_count
 			ON m.region_sid = i_count.region_sid
		   AND i_count.utility_supplier_id = uc.utility_supplier_id
		  LEFT JOIN (
				SELECT m.region_sid, COUNT(e.event_id) event_count
			      FROM all_meter m, region_event re, event e
				 WHERE m.crc_meter = 1
				   AND m.active = 1
				   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND re.region_sid = m.region_sid
				   AND e.event_id = re.event_id
				   AND (in_from_dtm IS NULL OR e.event_dtm >= in_from_dtm)
				   AND (in_to_dtm IS NULL OR e.event_dtm < in_to_dtm)
				 GROUP BY m.region_sid
			  ) e_count ON m.region_sid = e_count.region_sid
		 WHERE m.crc_meter = 1
		   AND m.active = 1
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE MeterConsumption (
	in_start_row					IN	NUMBER,
	in_end_row						IN	NUMBER,
	in_sort_by						IN	VARCHAR2,
	in_sort_dir						IN	VARCHAR2,
	in_from_dtm						IN DATE,
	in_to_dtm						IN DATE,
	out_consumption					OUT	SYS_REFCURSOR
)
AS
	v_order_by	VARCHAR2(4000);
BEGIN
	v_order_by := 'property';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		utils_pkg.ValidateOrderBy(v_order_by, 'property,managing_agent,meter,indicator,consumption');
	END IF;

	OPEN out_consumption FOR
	'SELECT x.*'||
	 ' FROM ('||
		  'SELECT x.*'||
			'FROM ('||
				'SELECT m.region_sid, prop.description property, '||
						'agent.description managing_agent, '||
						'DECODE(r.region_type, :1, pr.description || '' - '' || r.description, r.description) meter, '||
						'mst.description source_type, '||
						'i.ind_sid, '||
						'i.description indicator, '||
						'm.reference,  '||
						'ROUND(v.consumption, 3) consumption, '||
						'ms.description unit, '||
						'ROWNUM rn, COUNT(*) OVER () total_rows '||
				'   FROM v$legacy_meter m '||
				'   JOIN v$region r ON r.region_sid = m.region_sid '||
				'  JOIN meter_source_type mst ON mst.meter_source_type_id = m.meter_source_type_id '||
				'  LEFT JOIN v$region pr ON pr.region_sid = r.parent_sid '||
				'  LEFT JOIN v$region prop ON prop.region_sid = csr.utility_pkg.GetPropRegionSid(m.region_sid) '||
				'  LEFT JOIN v$region agent ON agent.region_sid = csr.utility_pkg.GetAgentRegionSid(m.region_sid) '||
				'  LEFT JOIN v$ind i ON i.ind_sid = m.primary_ind_sid'||
				'  LEFT JOIN measure ms ON i.measure_sid = ms.measure_sid'||
				'  LEFT JOIN  '||
						'( '||
						'SELECT ind_sid, region_sid, SUM(val_number) consumption '||
						'  FROM val '||
						' WHERE source_type_id = :2 '||
						'   AND period_start_dtm >= :3 '||
						'   AND period_end_dtm <= :4 '||
						' GROUP BY ind_sid, region_sid '||
						') v '||
							'ON v.ind_sid = m.primary_ind_sid '||
							'AND v.region_sid = m.region_sid '||
				' WHERE m.crc_meter = 1 '||
				'   AND m.active = 1 '||
				'   AND m.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
			 	' ) x' ||
			 ' ORDER BY ' || v_order_by ||
		 ' ) x'||
		 ' WHERE rn >= :5 AND rn < :6'
		   	USING csr_data_pkg.REGION_TYPE_RATE, csr_data_pkg.SOURCE_TYPE_METER, TRUNC(in_from_dtm, 'MONTH'), TRUNC(in_to_dtm, 'MONTH'), in_start_row, in_end_row;
END;

PROCEDURE SetBatchJob(
	in_region_sid 					IN	batch_job_meter_extract.region_sid%TYPE, 
	in_start_dtm 					IN	batch_job_meter_extract.start_dtm%TYPE, 
	in_end_dtm 						IN	batch_job_meter_extract.end_dtm%TYPE, 
	in_period_set_id 				IN	batch_job_meter_extract.period_set_id%TYPE,
	in_period_interval_id 			IN	batch_job_meter_extract.period_set_id%TYPE,
	in_is_full						IN	batch_job_meter_extract.is_full%TYPE,
	in_user_sid						IN	batch_job_meter_extract.user_sid%TYPE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_METER_EXTRACT,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_meter_extract
	  (batch_job_id, region_sid, start_dtm, end_dtm, period_set_id, period_interval_id, is_full, user_sid)
	  VALUES 
      (out_batch_job_id, in_region_sid, in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id, in_is_full, in_user_sid);
END;

PROCEDURE GetBatchJob(
	in_batch_job_id					IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_Sid, user_sid, start_dtm, end_dtm, period_set_id, period_interval_id, is_full
		  FROM batch_job_meter_extract
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE UpdateBatchJob(
	in_batch_job_id					IN NUMBER,
	in_report_data					IN batch_job_meter_extract.report_data%TYPE
)
AS
BEGIN
	UPDATE batch_job_meter_extract
	   SET report_data = in_report_data
	 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetBatchJobReportData(
	in_batch_job_id					IN NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT report_data
		  FROM batch_job_meter_extract
		 WHERE batch_job_id = in_batch_job_id;
END;

END utility_report_pkg;
/
