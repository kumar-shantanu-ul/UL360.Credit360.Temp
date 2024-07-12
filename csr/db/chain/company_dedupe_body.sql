CREATE OR REPLACE PACKAGE BODY CHAIN.company_dedupe_pkg
IS

--definitions
FUNCTION TryInsertCmsData (
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_oracle_table					IN cms.tab.oracle_table%TYPE,
	in_company_column				IN cms.tab_column.oracle_column%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_auto_incr_col_name			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	out_cms_record_id				OUT NUMBER
) RETURN BOOLEAN;

FUNCTION TryUpdateChildCmsData (
	in_oracle_schema 			IN	cms.tab.oracle_schema%TYPE,
	in_oracle_table 			IN	cms.tab.oracle_table%TYPE,
	in_tab_sid 					IN	cms.tab.tab_sid%TYPE,
	in_company_sid				IN	security.security_pkg.T_SID_ID,
	in_processed_record_id 		IN	tt_dedupe_cms_data.processed_record_id%TYPE,
	in_uk_cons_cols				IN	security.T_VARCHAR2_TABLE,
	in_cons_val_array			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_where_clause				IN VARCHAR2
) RETURN BOOLEAN;

PROCEDURE UpdateCmsData (
	in_oracle_schema		IN cms.tab.oracle_schema%TYPE,
	in_oracle_table			IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid	IN security_pkg.T_SID_ID,
	in_uk_cons_cols			IN security.T_VARCHAR2_TABLE,
	in_cons_val_array		IN security_pkg.T_VARCHAR2_ARRAY,
	in_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE
);

FUNCTION TryParseEnumVal(
	in_raw_val					IN VARCHAR2,
	in_destination_col_sid		IN dedupe_mapping.destination_col_sid%TYPE,
	out_enum_value_id			OUT NUMBER,
	out_translated_val			OUT VARCHAR2
)RETURN BOOLEAN;

FUNCTION TryParseNumberVal(
	in_raw_val		IN VARCHAR2,
	out_num_val		OUT NUMBER
) RETURN BOOLEAN;

FUNCTION FindCompanyColumnName(
	in_tab_sid					IN security_pkg.T_SID_ID,
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_col_name				OUT cms.tab_column.oracle_column%TYPE
)RETURN BOOLEAN;

FUNCTION ShouldBeCleared(
	in_dedupe_field_id			IN NUMBER,
	in_higher_than_system		IN NUMBER,
	in_is_old_cmp_row_null		IN BOOLEAN,
	in_prev_merges_fld_t		IN security.T_SID_TABLE,
	in_fill_null_fld_t			IN security.T_SID_TABLE
) RETURN BOOLEAN;

------------

FUNCTION GetRawDateVal(
	in_staging_tab_schema	IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name		IN cms.tab.oracle_table%TYPE,
	in_id_column			IN cms.tab_column.oracle_column%TYPE,
	in_mapped_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference			IN VARCHAR2,
	in_batch_num_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_batch_num			IN NUMBER DEFAULT NULL,
	in_source_lookup_col	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup		IN VARCHAR DEFAULT NULL
)RETURN DATE
AS
	v_val			DATE;
	v_sql			VARCHAR2(4000);
BEGIN
	v_sql :=
		'SELECT "'||in_mapped_column||'"
		   FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'"
		  WHERE "'||in_id_column||'"=:1';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:2, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :2 IS NULL';
	END IF;

	IF in_source_lookup_col IS NOT NULL THEN
		v_sql := v_sql||' AND :3 = "'||in_source_lookup_col||'"';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	BEGIN
		EXECUTE IMMEDIATE v_sql
		   INTO v_val
		  USING TRIM(in_reference), in_batch_num, in_source_lookup;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Error in GetRawDateVal: expected 1 returned result for ref:'||in_reference||' and batch num:'||in_batch_num||' Got 0 rows. Sql:'||v_sql);
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Error in GetRawDateVal: expected 1 returned result for ref:'||in_reference||' and batch num:'||in_batch_num||' Got too many rows. Sql:'||v_sql);
	END;

	RETURN v_val;
END;

FUNCTION GetRawValue(
	in_staging_tab_schema	IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name		IN cms.tab.oracle_table%TYPE,
	in_id_column			IN cms.tab_column.oracle_column%TYPE,
	in_mapped_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference			VARCHAR2,
	in_batch_num_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_batch_num			NUMBER DEFAULT NULL,
	in_source_lookup_col	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup		VARCHAR DEFAULT NULL
)RETURN VARCHAR2
AS
	v_val				VARCHAR(4000);
	v_sql				VARCHAR2(4000);
BEGIN
	v_sql :='SELECT "'||in_mapped_column||'"
			   FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'"
			  WHERE "'||in_id_column||'"=:1';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:2, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :2 IS NULL';
	END IF;

	IF in_source_lookup_col IS NOT NULL THEN
		v_sql := v_sql||' AND :3 = "'||in_source_lookup_col||'"';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	BEGIN
		EXECUTE IMMEDIATE v_sql
		   INTO v_val
		  USING TRIM(in_reference), in_batch_num, in_source_lookup;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Error in GetRawValue: expected 1 returned result for ref:'||in_reference||' and batch num:'||in_batch_num||' Got 0 rows. Sql:'||v_sql);
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Error in GetRawValue: expected 1 returned result for ref:'||in_reference||' and batch num:'||in_batch_num||' Got too many rows. Sql:'||v_sql);
	END;

	RETURN v_val;
END;

FUNCTION TryParseEnumVal(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	in_destination_col_sid		IN dedupe_mapping.destination_col_sid%TYPE,
	out_enum_value_id			OUT NUMBER,
	out_staging_val				OUT VARCHAR2,
	out_translated_val			OUT VARCHAR2
)RETURN BOOLEAN
AS
	v_enum_tab_sid		cms.tab.tab_sid%TYPE;
BEGIN
	out_staging_val := GetRawValue(
		in_staging_tab_schema	=> in_staging_tab_schema,
		in_staging_tab_name		=> in_staging_tab_name,
		in_id_column			=> in_staging_id_col_name,
		in_mapped_column		=> in_mapped_column,
		in_reference			=> in_reference,
		in_batch_num_column 	=> in_batch_num_column,
		in_batch_num			=> in_batch_num,
		in_source_lookup_col	=> in_source_lookup_col,
		in_source_lookup		=> in_source_lookup
	);

	RETURN TryParseEnumVal(
		in_raw_val				=> out_staging_val,
		in_destination_col_sid	=> in_destination_col_sid,
		out_enum_value_id		=> out_enum_value_id,
		out_translated_val		=> out_translated_val
	);
END;

FUNCTION TryParseUserSid(
	in_raw_val		IN VARCHAR2,
	out_user_sid	OUT security_pkg.T_SID_ID
)RETURN BOOLEAN
AS
BEGIN
	IF in_raw_val IS NOT NULL THEN
		BEGIN
			SELECT csr_user_sid
			  INTO out_user_sid
			  FROM csr.csr_user
			 WHERE lower(in_raw_val) IN (lower(user_name), lower(user_ref), lower(full_name));
		EXCEPTION
			WHEN OTHERS THEN
				RETURN FALSE;
		END;
	END IF;

	RETURN TRUE;
END;

FUNCTION TryParseUserSid(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	out_user_sid				OUT security_pkg.T_SID_ID,
	out_raw_val					OUT VARCHAR2
)RETURN BOOLEAN
AS
BEGIN
	out_raw_val	:= GetRawValue(
		in_staging_tab_schema	=> in_staging_tab_schema,
		in_staging_tab_name		=> in_staging_tab_name,
		in_id_column			=> in_staging_id_col_name,
		in_mapped_column		=> in_mapped_column,
		in_reference			=> in_reference,
		in_batch_num_column 	=> in_batch_num_column,
		in_batch_num			=> in_batch_num,
		in_source_lookup_col	=> in_source_lookup_col,
		in_source_lookup		=> in_source_lookup
	);

	RETURN TryParseUserSid(
		in_raw_val		=> out_raw_val,
		out_user_sid	=> out_user_sid
	);
END;

FUNCTION TryParseVal(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	in_data_type				IN cms.tab_column.data_type%TYPE,
	out_str_val					OUT VARCHAR2,
	out_date_val				OUT DATE
) RETURN BOOLEAN
AS
	v_num_val						NUMBER;
BEGIN
	IF in_data_type = 'DATE' THEN
		out_date_val := GetRawDateVal(
			in_staging_tab_schema	=> in_staging_tab_schema,
			in_staging_tab_name		=> in_staging_tab_name,
			in_id_column			=> in_staging_id_col_name,
			in_mapped_column		=> in_mapped_column,
			in_reference			=> in_reference,
			in_batch_num_column 	=> in_batch_num_column,
			in_batch_num			=> in_batch_num,
			in_source_lookup_col	=> in_source_lookup_col,
			in_source_lookup		=> in_source_lookup
		);

		RETURN TRUE;
	END IF;

	out_str_val :=	GetRawValue(
		in_staging_tab_schema	=> in_staging_tab_schema,
		in_staging_tab_name		=> in_staging_tab_name,
		in_id_column			=> in_staging_id_col_name,
		in_mapped_column		=> in_mapped_column,
		in_reference			=> in_reference,
		in_batch_num_column 	=> in_batch_num_column,
		in_batch_num			=> in_batch_num,
		in_source_lookup_col	=> in_source_lookup_col,
		in_source_lookup		=> in_source_lookup
	);

	IF out_str_val IS NOT NULL AND in_data_type = 'NUMBER' THEN
		RETURN TryParseNumberVal(out_str_val, v_num_val);
	END IF;

	RETURN TRUE;
END;

FUNCTION TryParseNumberVal(
	in_raw_val		IN VARCHAR2,
	out_num_val		OUT NUMBER
) RETURN BOOLEAN
AS
BEGIN
	BEGIN
		out_num_val := TO_NUMBER(in_raw_val);
	EXCEPTION
		WHEN VALUE_ERROR THEN
			RETURN FALSE;
	END;
	RETURN TRUE;
END;

FUNCTION TryParseEnumVal(
	in_raw_val					IN VARCHAR2,
	in_destination_col_sid		IN dedupe_mapping.destination_col_sid%TYPE,
	out_enum_value_id			OUT NUMBER,
	out_translated_val			OUT VARCHAR2
)RETURN BOOLEAN
AS
	v_enum_tab_sid		cms.tab.tab_sid%TYPE;
BEGIN
	IF in_raw_val IS NOT NULL THEN
		--get the tab_sid the col references to
		v_enum_tab_sid := cms.tab_pkg.GetParentTabSid(in_destination_col_sid);

		--try to resolve the value, check in the tranlation emum first, then in the actual enum
		IF NOT cms.tab_pkg.TryGetEnumValFromMapTable(v_enum_tab_sid, in_destination_col_sid, in_raw_val, out_enum_value_id, out_translated_val)
			AND NOT cms.tab_pkg.TryGetEnumVal(v_enum_tab_sid, in_destination_col_sid, in_raw_val, out_enum_value_id) THEN
			RETURN FALSE;
		END IF;
	END IF;

	RETURN TRUE;
END;

FUNCTION TryParseCompanySid(
	in_raw_val			IN	VARCHAR2,
	out_company_sid		OUT	security_pkg.T_SID_ID
)RETURN BOOLEAN
AS
BEGIN
	IF in_raw_val IS NOT NULL THEN
		BEGIN
			SELECT company_sid
			  INTO out_company_sid
			  FROM company
			 WHERE company_sid = in_raw_val;
		EXCEPTION
			WHEN OTHERS THEN
				RETURN FALSE;
		END;
	END IF;

	RETURN TRUE;
END;

FUNCTION TryParseCompanySid(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference 				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_mapped_column			IN cms.tab_column.oracle_column%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID,
	out_raw_val					OUT VARCHAR2
)RETURN BOOLEAN
AS
BEGIN
	out_raw_val	:= GetRawValue(
		in_staging_tab_schema	=> in_staging_tab_schema,
		in_staging_tab_name		=> in_staging_tab_name,
		in_id_column			=> in_staging_id_col_name,
		in_mapped_column		=> in_mapped_column,
		in_reference			=> in_reference,
		in_batch_num_column 	=> in_batch_num_column,
		in_batch_num			=> in_batch_num
	);

	RETURN TryParseCompanySid(
		in_raw_val		=> out_raw_val,
		out_company_sid	=> out_company_sid
	);
END;

FUNCTION BuildSqlForCmsSourceData(
	in_dedupe_staging_link_id 	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_sid			IN security_pkg.T_SID_ID,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL
) RETURN VARCHAR2
AS
	v_sql 					VARCHAR2(4000);
	v_cols 					VARCHAR2(255);
	v_schema 				VARCHAR2(255);
	v_table 				VARCHAR2(255);
	v_company_col_name 		VARCHAR2(255);
	v_auto_incr_stag_column	VARCHAR2(30);
BEGIN
	DELETE FROM tt_column_config;

	--If there is an auto-incr field, use it for sorting to get a deterministic processing order
	BEGIN
		SELECT oracle_column
		  INTO v_auto_incr_stag_column
		  FROM cms.tab_column
		 WHERE tab_sid = in_staging_tab_sid
		   AND col_type = cms.tab_pkg.CT_AUTO_INCREMENT;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; --that's fine
	END;

	FOR r IN (
		SELECT dm.dedupe_mapping_id, stc.oracle_column source_column, stc.column_sid source_col_sid, stc.col_type source_col_type, stc.data_type source_data_type,
			   dt.oracle_table destination_table, dm.destination_tab_sid, dtc.oracle_column destination_column,
			   dtc.column_sid destination_col_sid, dtc.col_type destination_col_type, dtc.data_type destination_data_type
		  FROM dedupe_mapping dm
		  JOIN cms.tab st ON st.tab_sid = dm.tab_sid
		  JOIN cms.tab_column stc ON stc.tab_sid = st.tab_sid AND stc.column_sid = dm.col_sid
		  JOIN cms.tab dt ON dt.tab_sid = dm.destination_tab_sid
		  JOIN cms.tab_column dtc ON dtc.tab_sid = dt.tab_sid AND dtc.column_sid = dm.destination_col_sid
		 WHERE dm.dedupe_staging_link_id = in_dedupe_staging_link_id
	  ORDER BY dm.dedupe_mapping_id
	) LOOP
		IF v_sql IS NULL THEN
			v_sql := 'SELECT ';
		ELSE
			v_sql := v_sql ||' ,';
		END IF;

		v_sql := v_sql ||'"'||r.source_column||'"';

		INSERT INTO tt_column_config (dedupe_mapping_id, source_column, source_col_sid, source_col_type, source_data_type,
					destination_table, destination_tab_sid, destination_column, destination_col_sid, destination_col_type, destination_data_type)
			 VALUES (r.dedupe_mapping_id, r.source_column, r.source_col_sid, r.source_col_type, r.source_data_type,
					r.destination_table, r.destination_tab_sid, r.destination_column, r.destination_col_sid, r.destination_col_type, r.destination_data_type);
	END LOOP;

	IF v_sql IS NULL THEN
		RETURN NULL;
	END IF;

	v_sql := v_sql||' FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'"';

	v_sql := v_sql||' WHERE "'||in_staging_id_col_name||'" = :1';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:2, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :2 IS NULL';
	END IF;

	IF in_source_lookup_column IS NOT NULL THEN
		v_sql := v_sql||' AND :3 = "'||in_source_lookup_column||'"';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	IF v_auto_incr_stag_column IS NOT NULL THEN
		v_sql := v_sql||' ORDER BY "'||v_auto_incr_stag_column||'"';
	END IF;

	RETURN v_sql;
END;

FUNCTION DataMergedFromHigherPriorSrc(
	in_company_sid 		IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_system_import_source_id	import_source.import_source_id%TYPE;
BEGIN
	SELECT MIN(import_source_id)
	  INTO v_system_import_source_id
	  FROM import_source
	 WHERE app_sid = security_pkg.GetApp
	   AND is_owned_by_system = 1;
	
	RETURN DataMergedFromHigherPriorSrc(in_company_sid, v_system_import_source_id);
END;

FUNCTION DataMergedFromHigherPriorSrc(
	in_company_sid 		IN security_pkg.T_SID_ID,
	in_import_source_id IN import_source.import_source_id%TYPE
)RETURN NUMBER
AS
	v_merge_from_higher_prior	NUMBER(10,0);
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_merge_from_higher_prior
	  FROM dedupe_processed_record dpr
	  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
	  JOIN import_source s ON dsl.import_source_id = s.import_source_id
	 WHERE dpr.app_sid = security_pkg.getApp
	   AND in_company_sid IN (dpr.matched_to_company_sid, dpr.created_company_sid)
	   AND dpr.data_merged = 1
	   AND s.position < (
			SELECT s2.position
			  FROM import_source s2
			 WHERE s2.app_sid = security_pkg.getApp
			   AND import_source_id = in_import_source_id
			);

	RETURN v_merge_from_higher_prior;
END;

FUNCTION BuildAddressSelectSQL(
	in_oracle_table 	cms.tab.oracle_table%TYPE,
	in_oracle_column 	cms.tab_column.oracle_column%TYPE
) RETURN VARCHAR2
AS
	v_count 			NUMBER(10);
	v_return_sql 		VARCHAR2(4000);
	v_field_sql 		VARCHAR2(4000);
	v_field_string 		VARCHAR2(255);
	v_base_address_col	VARCHAR2(30);
BEGIN
	v_return_sql := 't."'||in_oracle_column||'"';

	SELECT COUNT(*)
	  INTO v_count
	  FROM dual
	 WHERE in_oracle_column LIKE ('%_1');

	IF v_count = 0 THEN
		RETURN v_return_sql||', NULL, NULL, NULL'; -- address_2, _3, _4
	END IF;

	v_base_address_col := SUBSTR(in_oracle_column, 0, LENGTH(in_oracle_column) - 2);

	FOR i IN 2 .. 4 -- max num of address columns supported
	LOOP
		SELECT COUNT(*)
		  INTO v_count
		  FROM cms.tab_column tc
		  JOIN cms.tab t ON tc.tab_sid = t.tab_sid
		 WHERE t.oracle_table = in_oracle_table
		   AND tc.oracle_column = v_base_address_col||'_'|| i;

		IF v_count > 0 THEN
			v_return_sql := v_return_sql || ','|| 't."'||v_base_address_col || '_' ||i || '"';
		ELSE
			v_return_sql := v_return_sql || ', NULL';
		END IF;
	END LOOP;

	RETURN v_return_sql;
END;

-- Get a list of alternative cites to try and match if needed
FUNCTION GetAlternativeCitySubs (
	in_city_name			company.city%TYPE,
	in_rule_set_id			IN dedupe_rule_set.dedupe_rule_set_id%TYPE
)
RETURN CSR.T_VARCHAR2_TABLE
AS
	v_alt_cities			CSR.T_VARCHAR2_TABLE := CSR.T_VARCHAR2_TABLE();
	v_count					NUMBER;
BEGIN

	--We only support cities atm - so if there isn't a rule using cities then ignore
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_rule rm
	  JOIN dedupe_mapping m ON rm.dedupe_mapping_id = m.dedupe_mapping_id
	 WHERE rm.dedupe_rule_set_id = in_rule_set_id
	   AND m.dedupe_field_id = chain_pkg.FLD_COMPANY_CITY;

	IF v_count > 0 THEN
		-- there is a degree of compromise here - we scoop up what we can as there's no concept of country on dedupe_sub
		-- so when we pre-process the sub rules (if preprocessing is enabled) we only apply the ones that apply to all countries
		-- bidirectional substitutions - so look for pattern->subs and subs->pattern
		SELECT LOWER(alt_city)
		  BULK COLLECT INTO v_alt_cities
		  FROM (
			SELECT proc_pattern alt_city
			  FROM dedupe_sub ds
			 WHERE in_city_name IS NOT NULL
			   AND proc_substitution IS NOT NULL
			   AND proc_pattern IS NOT NULL
			   AND (
					in_city_name = ds.proc_substitution
					OR in_city_name = LOWER(TRIM(ds.substitution))
			   )
			UNION
			SELECT proc_substitution alt_city
			  FROM dedupe_sub ds
			 WHERE in_city_name IS NOT NULL
			   AND proc_substitution IS NOT NULL
			   AND proc_pattern IS NOT NULL
			   AND (
					in_city_name = ds.proc_pattern
					OR in_city_name = LOWER(TRIM(ds.pattern))
			   )
		);
	END IF;

	RETURN v_alt_cities;
END;

FUNCTION FindMatchesForRuleSet(
	in_rule_set_id					IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_company_row					IN T_DEDUPE_COMPANY_ROW,
	in_map_tag_vals					IN T_NUMERIC_TABLE, /* mapping_id, tag_id */
	in_map_ref_vals					IN security.T_VARCHAR2_TABLE /* mapping_id, ref value */
)RETURN security.T_SID_TABLE /*matched_company_sids*/
AS
	v_sql					VARCHAR(4000);
	v_rule_first_mapping	NUMBER := 1;
	v_temp_matched_sids		security.T_SID_TABLE := security.T_SID_TABLE();
	v_rule_matched_sids		security.T_SID_TABLE := security.T_SID_TABLE();
	v_staging_tag_ids		security.T_SID_TABLE := security.T_SID_TABLE();
	v_staging_value			VARCHAR2(512);
	v_alt_cities			CSR.T_VARCHAR2_TABLE;
	v_email_domain			chain.dd_customer_blcklst_email.email_domain%TYPE;
	v_website_domain		chain.company.website%TYPE;
	v_phone					chain.company.phone%TYPE;
	
	ALPHA_RE CONSTANT VARCHAR2(6) := '[^a-z]';
	ALPHANUM_RE CONSTANT VARCHAR2(9) := '[^a-z0-9]';
	NUM_RE CONSTANT VARCHAR2(6) := '[^0-9]';
BEGIN

	v_alt_cities:= GetAlternativeCitySubs(in_company_row.city, in_rule_set_id);

	FOR r IN(
		SELECT f.entity, f.dedupe_field_id, f.field, m.reference_id, m.tag_group_id,
			rm.dedupe_rule_type_id, rm.match_threshold, m.dedupe_mapping_id, rm.dedupe_rule_id
		  FROM dedupe_rule rm
		  JOIN dedupe_mapping m ON rm.dedupe_mapping_id = m.dedupe_mapping_id
		  LEFT JOIN dedupe_field f ON f.dedupe_field_id = m.dedupe_field_id
		 WHERE rm.dedupe_rule_set_id = in_rule_set_id
		   AND m.dedupe_staging_link_id = in_dedupe_staging_link_id
		 ORDER BY rm.position
	)
	LOOP
		v_temp_matched_sids.delete;

		IF r.reference_id IS NOT NULL THEN
			IF in_map_ref_vals IS NULL OR in_map_ref_vals.COUNT = 0 THEN
				--no reason to evaluate the next mapping
				RETURN NULL;
			END IF;

			BEGIN
				SELECT t.value
				  INTO v_staging_value
				  FROM TABLE(in_map_ref_vals) t
				 WHERE t.pos = r.dedupe_mapping_id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RETURN NULL;
			END;

			SELECT cr.company_sid
			  BULK COLLECT INTO v_temp_matched_sids
			  FROM company_reference cr
			  JOIN company c ON cr.company_sid = c.company_sid AND c.deleted = 0 AND c.pending = 0
			 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
			   AND reference_id = r.reference_id
			   AND lower(trim(value)) = lower(trim(v_staging_value));

		ELSIF r.entity = 'COMPANY' THEN
			IF in_company_row.name IS NULL THEN
				RETURN NULL;
			END IF;

			IF r.dedupe_field_id = chain_pkg.FLD_COMPANY_NAME THEN
				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					  LEFT JOIN alt_company_name acn ON c.company_sid = acn.company_sid
					  LEFT JOIN dedupe_pp_alt_comp_name dpacn ON c.company_sid = dpacn.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND ((dpc.name IS NOT NULL AND lower(dpc.name) = lower(in_company_row.name)
							OR lower(c.name) = lower(in_company_row.name))
						OR (dpacn.name IS NOT NULL AND lower(dpacn.name) = lower(in_company_row.name)
							OR lower(acn.name) = lower(in_company_row.name)));

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					  LEFT JOIN alt_company_name acn ON c.company_sid = acn.company_sid
					  LEFT JOIN dedupe_pp_alt_comp_name dpacn ON c.company_sid = dpacn.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND ((dpc.name IS NOT NULL AND utl_match.edit_distance_similarity(lower(dpc.name), lower(in_company_row.name)) >= r.match_threshold
							OR utl_match.edit_distance_similarity(lower(c.name), lower(in_company_row.name)) >= r.match_threshold)
						OR (dpacn.name IS NOT NULL AND utl_match.edit_distance_similarity(lower(dpacn.name), lower(in_company_row.name)) >= r.match_threshold
							OR utl_match.edit_distance_similarity(lower(acn.name), lower(in_company_row.name)) >= r.match_threshold));

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					  LEFT JOIN alt_company_name acn ON c.company_sid = acn.company_sid
					  LEFT JOIN dedupe_pp_alt_comp_name dpacn ON c.company_sid = dpacn.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND ((dpc.name IS NOT NULL AND utl_match.jaro_winkler_similarity(lower(dpc.name), lower(in_company_row.name)) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(lower(c.name), lower(in_company_row.name)) >= r.match_threshold)
						OR (dpacn.name IS NOT NULL AND utl_match.jaro_winkler_similarity(lower(dpacn.name), lower(in_company_row.name)) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(lower(acn.name), lower(in_company_row.name)) >= r.match_threshold));

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_CONTAINS THEN
					--destination contains the whole source string and vice-versa (only alphabetical chars)
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					  LEFT JOIN alt_company_name acn ON c.company_sid = acn.company_sid
					  LEFT JOIN dedupe_pp_alt_comp_name dpacn ON c.company_sid = dpacn.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND ((dpc.name IS NOT NULL AND (INSTR(REGEXP_REPLACE(lower(dpc.name), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,'')) > 0
								OR INSTR(REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,''), REGEXP_REPLACE(lower(dpc.name), ALPHA_RE,'')) > 0)
							OR INSTR(REGEXP_REPLACE(lower(c.name), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,'')) > 0
							OR INSTR(REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,''), REGEXP_REPLACE(lower(c.name), ALPHA_RE,'')) > 0
						)
						OR (dpacn.name IS NOT NULL AND (INSTR(REGEXP_REPLACE(lower(dpacn.name), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,'')) > 0
								OR INSTR(REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,''), REGEXP_REPLACE(lower(dpacn.name), ALPHA_RE,'')) > 0)
							OR INSTR(REGEXP_REPLACE(lower(acn.name), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,'')) > 0
							OR INSTR(REGEXP_REPLACE(lower(in_company_row.name), ALPHA_RE,''), REGEXP_REPLACE(lower(acn.name), ALPHA_RE,'')) > 0
						));
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_POSTCODE THEN
				IF in_company_row.postcode IS NULL THEN
					RETURN NULL;
				END IF;

				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.postcode IS NOT NULL AND lower(dpc.postcode) = lower(in_company_row.postcode)
							OR lower(c.postcode) = lower(in_company_row.postcode));

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.postcode IS NOT NULL AND utl_match.edit_distance_similarity(lower(dpc.postcode), lower(in_company_row.postcode)) >= r.match_threshold
							OR utl_match.edit_distance_similarity(lower(c.postcode), lower(in_company_row.postcode)) >= r.match_threshold);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.postcode IS NOT NULL AND utl_match.jaro_winkler_similarity(lower(dpc.postcode), lower(in_company_row.postcode)) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(lower(c.postcode), lower(in_company_row.postcode)) >= r.match_threshold);
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_ADDRESS THEN
				IF in_company_row.address IS NULL THEN
					RETURN NULL;
				END IF;

				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.address IS NOT NULL AND lower(dpc.address) = lower(in_company_row.address)
							OR lower(c.address_1||' '||c.address_2||' '||c.address_3||' '||c.address_4) = lower(in_company_row.address));

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.address IS NOT NULL AND utl_match.edit_distance_similarity(lower(dpc.address), lower(in_company_row.address)) >= r.match_threshold
							OR utl_match.edit_distance_similarity(TRIM(lower(c.address_1||' '||c.address_2||' '||c.address_3||' '||c.address_4)), lower(in_company_row.address)) >= r.match_threshold);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.address IS NOT NULL AND utl_match.jaro_winkler_similarity(lower(dpc.address), lower(in_company_row.address)) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(TRIM(lower(c.address_1||' '||c.address_2||' '||c.address_3||' '||c.address_4)), lower(in_company_row.address)) >= r.match_threshold);
				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_CONTAINS THEN
					--destination contains the whole source string and vice-versa (only alphabetical chars)
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.address IS NOT NULL AND (INSTR(REGEXP_REPLACE(lower(dpc.address), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.address), ALPHA_RE,'')) > 0
								OR INSTR(REGEXP_REPLACE(lower(in_company_row.address), ALPHA_RE,''), REGEXP_REPLACE(lower(dpc.address), ALPHA_RE,'')) > 0)
							OR INSTR(REGEXP_REPLACE(lower(c.address_1||' '||c.address_2||' '||c.address_3||' '||c.address_4), ALPHA_RE,''), REGEXP_REPLACE(lower(in_company_row.address), ALPHA_RE,'')) > 0
							OR INSTR(REGEXP_REPLACE(lower(in_company_row.address), ALPHA_RE,''), REGEXP_REPLACE(lower(c.address_1||' '||c.address_2||' '||c.address_3||' '||c.address_4), ALPHA_RE,'')) > 0
						);
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_ACTIVE THEN
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND TRIM(lower(active))= in_company_row.active;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_CITY THEN

				-- match direct city record => company city and alt cities
				SELECT c.company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND (
						(dpc.city IS NOT NULL AND lower(dpc.city) = lower(in_company_row.city)) OR
						(lower(c.city) = lower(in_company_row.city)) OR
						(dpc.city IS NOT NULL AND lower(dpc.city) IN (SELECT column_value FROM TABLE(v_alt_cities))) OR
						(lower(c.city) IN (SELECT column_value FROM TABLE(v_alt_cities)))
					);


			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_STATE THEN
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND nlssort(city,'nls_sort=generic_m_ai') = nlssort(in_company_row.state,'nls_sort=generic_m_ai');

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_SECTOR THEN
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND sector_id IN (
						SELECT sector_id
						  FROM sector
						 WHERE lower(description) = lower(in_company_row.sector)
					);

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_WEBSITE THEN
				IF in_company_row.website IS NULL THEN
					RETURN NULL;
				END IF;
				
				v_website_domain := GetWebsiteDomainName(in_company_row.website);

				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.website IS NOT NULL AND GetWebsiteDomainName(dpc.website) = v_website_domain
							OR GetWebsiteDomainName(c.website) = v_website_domain);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.website IS NOT NULL AND utl_match.edit_distance_similarity(GetWebsiteDomainName(dpc.website), v_website_domain) >= r.match_threshold
							OR utl_match.edit_distance_similarity(GetWebsiteDomainName(c.website), v_website_domain) >= r.match_threshold);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.website IS NOT NULL AND utl_match.jaro_winkler_similarity(GetWebsiteDomainName(dpc.website), v_website_domain) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(GetWebsiteDomainName(c.website), v_website_domain) >= r.match_threshold);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_CONTAINS THEN
					--destination contains the whole source string and vice-versa (alpha numeric chars)
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.website IS NOT NULL AND (INSTR(REGEXP_REPLACE(GetWebsiteDomainName(dpc.website), ALPHANUM_RE,''), REGEXP_REPLACE(v_website_domain, ALPHANUM_RE,'')) > 0
								OR INSTR(REGEXP_REPLACE(v_website_domain, ALPHANUM_RE,''), REGEXP_REPLACE(GetWebsiteDomainName(dpc.website), ALPHANUM_RE,'')) > 0)
								OR INSTR(REGEXP_REPLACE(GetWebsiteDomainName(c.website), ALPHANUM_RE,''), REGEXP_REPLACE(v_website_domain, ALPHANUM_RE,'')) > 0
							OR INSTR(REGEXP_REPLACE(v_website_domain, ALPHANUM_RE,''), REGEXP_REPLACE(GetWebsiteDomainName(c.website), ALPHANUM_RE,'')) > 0
						);
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_PHONE THEN
				IF in_company_row.phone IS NULL THEN
					RETURN NULL;
				END IF;
				
				v_phone := LTRIM(REGEXP_REPLACE(in_company_row.phone, NUM_RE, ''), '0');

				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.phone IS NOT NULL AND ltrim(REGEXP_REPLACE(dpc.phone, NUM_RE, ''), '0') = v_phone
							OR ltrim(REGEXP_REPLACE(c.phone, NUM_RE, ''), '0') = v_phone);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.phone IS NOT NULL AND utl_match.edit_distance_similarity(ltrim(REGEXP_REPLACE(dpc.phone, NUM_RE, ''), '0'), v_phone) >= r.match_threshold
							OR utl_match.edit_distance_similarity(ltrim(REGEXP_REPLACE(c.phone, NUM_RE, ''), '0'), v_phone) >= r.match_threshold);

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.phone IS NOT NULL AND utl_match.jaro_winkler_similarity(ltrim(REGEXP_REPLACE(dpc.phone, NUM_RE, ''), '0'), v_phone) >= r.match_threshold
							OR utl_match.jaro_winkler_similarity(ltrim(REGEXP_REPLACE(c.phone, NUM_RE, ''), '0'), v_phone) >= r.match_threshold);
				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_CONTAINS THEN
					--destination contains the whole source string and vice-versa
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  LEFT JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND (dpc.phone IS NOT NULL AND (INSTR(ltrim(REGEXP_REPLACE(dpc.phone, NUM_RE, ''), '0'), v_phone) > 0
								OR INSTR(v_phone, ltrim(REGEXP_REPLACE(dpc.phone, NUM_RE, ''), '0')) > 0)
								OR INSTR(ltrim(REGEXP_REPLACE(c.phone, NUM_RE, ''), '0'), v_phone) > 0
								OR INSTR(v_phone, ltrim(REGEXP_REPLACE(c.phone, NUM_RE, ''), '0')) > 0
						);
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_FAX THEN
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND TRIM(lower(fax))= TRIM(lower(in_company_row.fax));

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_EMAIL THEN
				IF in_company_row.email IS NULL THEN
					RETURN NULL;
				END IF;

				v_email_domain := chain.dedupe_preprocess_pkg.GetDomainNameFromEmail(in_company_row.email); -- lowered and trimmed

				IF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_EXACT THEN				
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND dpc.email_domain IS NOT NULL AND lower(dpc.email_domain) = v_email_domain;

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_LEVENSHTEIN THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND dpc.email_domain IS NOT NULL AND utl_match.edit_distance_similarity(lower(dpc.email_domain), v_email_domain) >= r.match_threshold;

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_JAROWINKLER THEN
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND dpc.email_domain IS NOT NULL AND utl_match.jaro_winkler_similarity(lower(dpc.email_domain), v_email_domain) >= r.match_threshold;

				ELSIF r.dedupe_rule_type_id = chain_pkg.RULE_TYPE_CONTAINS THEN
					--destination contains the whole source string and vice-versa (only alphabetical chars)
					SELECT c.company_sid
					  BULK COLLECT INTO v_temp_matched_sids
					  FROM company c
					  JOIN dedupe_preproc_comp dpc ON c.company_sid = dpc.company_sid
					 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					   AND c.deleted = 0
					   AND c.pending = 0
					   AND ((dpc.email_domain IS NOT NULL AND (INSTR(REGEXP_REPLACE(lower(dpc.email_domain), ALPHA_RE,''), REGEXP_REPLACE(v_email_domain, ALPHA_RE,'')) > 0
						OR INSTR(REGEXP_REPLACE(v_email_domain, ALPHA_RE,''), REGEXP_REPLACE(lower(dpc.email_domain), ALPHA_RE,'')) > 0)
					  ));
				END IF;

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_DELETED THEN
				RAISE_APPLICATION_ERROR(-20001, 'Having a rule based on DELETED mapping is not supported');

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_ACTIVATED_DTM THEN
				SELECT company_sid
				   BULK COLLECT INTO v_temp_matched_sids
				   FROM company c
				  WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
					AND c.deleted = 0
					AND c.pending = 0
					AND TRUNC(activated_dtm) = TRUNC(in_company_row.activated_dtm);

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_CREATED_DTM THEN
				SELECT company_sid
				   BULK COLLECT INTO v_temp_matched_sids
				   FROM company c
				  WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				    AND c.deleted = 0
					AND c.pending = 0
					AND TRUNC(created_dtm) = TRUNC(in_company_row.created_dtm);

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_DEACTIVATED_DTM THEN
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND TRUNC(deactivated_dtm) = TRUNC(in_company_row.deactivated_dtm);

			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_COMPANY_TYPE THEN
				--company type
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND company_type_id IN (
					SELECT company_type_id
					  FROM company_type
					 WHERE lower(in_company_row.company_type) IN (TO_CHAR(company_type_id), lower(lookup_key), lower(singular), lower(plural))
				);
			ELSIF r.dedupe_field_id = chain_pkg.FLD_COMPANY_COUNTRY THEN
				--country
				SELECT company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND lower(country_code) IN (
						SELECT lower(country_code)
						  FROM v$country
						 WHERE lower(in_company_row.country_code) IN (lower(country_code), lower(name))
					 );
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Field not supported for matching companies:'||r.field);
			END IF;
		ELSIF r.tag_group_id IS NOT NULL THEN
			IF in_map_tag_vals IS NULL OR in_map_tag_vals.COUNT =0 THEN
				--no reason to evaluate the next mapping
				RETURN NULL;
			END IF;

			SELECT item
			  BULK COLLECT INTO v_staging_tag_ids
			  FROM TABLE(in_map_tag_vals) t
			 WHERE t.pos = r.dedupe_mapping_id;

			IF v_staging_tag_ids.COUNT > 0 THEN
				--get exact tag matches
				SELECT DISTINCT c.company_sid
				  BULK COLLECT INTO v_temp_matched_sids
				  FROM company c
				 WHERE (v_rule_first_mapping = 1 OR c.company_sid IN (SELECT column_value FROM TABLE(v_rule_matched_sids)))
				   AND c.deleted = 0
				   AND c.pending = 0
				   AND NOT EXISTS(
						SELECT 1
						  FROM v$company_tag ct
						 WHERE ct.company_sid = c.company_sid
						   AND ct.tag_group_id = r.tag_group_id
						   AND tag_id NOT IN (
								SELECT column_value
								  FROM TABLE(v_staging_tag_ids)
							)
						)
				   AND NOT EXISTS(
						SELECT 1
						  FROM TABLE(v_staging_tag_ids)
						 WHERE column_value NOT IN(
							SELECT tag_id
							  FROM v$company_tag ct
							 WHERE ct.company_sid = c.company_sid
							   AND ct.tag_group_id = r.tag_group_id
							)
						);
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Mapping not supported for matching companies for rule with id:'||r.dedupe_rule_id);
		END IF;

		IF v_temp_matched_sids IS NULL OR v_temp_matched_sids.COUNT = 0 THEN
			--no reason to evaluate the next mapping
			RETURN NULL;
		END IF;

		SELECT DISTINCT column_value
		  BULK COLLECT INTO v_rule_matched_sids
		  FROM TABLE(v_temp_matched_sids);

		v_rule_first_mapping := 0;
	END LOOP;

	RETURN v_rule_matched_sids;
END;

FUNCTION HasBeenProcessed(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_reference				IN dedupe_processed_record.reference%TYPE,
	in_batch_num				IN NUMBER DEFAULT NULL
)RETURN NUMBER
AS
	v_has_been_processed NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_has_been_processed
	  FROM dedupe_processed_record
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
	   AND reference = in_reference
	   AND ((in_batch_num IS NULL AND batch_num IS NULL) OR batch_num = in_batch_num);

	RETURN v_has_been_processed;
END;

PROCEDURE GetRefsAndTagsFromStaging(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_staging_source_lookup_col	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_source_lookup				IN VARCHAR2 DEFAULT NULL,
	out_map_tag_vals				OUT T_NUMERIC_TABLE, /* mapping_id, tag_id */
	out_map_ref_vals				OUT security.T_VARCHAR2_TABLE /* mapping_id, ref value */
)
AS
	v_staging_value					VARCHAR2(512);
BEGIN
	out_map_ref_vals := security.T_VARCHAR2_TABLE();
	out_map_tag_vals := T_NUMERIC_TABLE();

	--get staging tags and reference vals used in matching rules
	FOR r IN(
		SELECT tc.oracle_column, m.reference_id, m.tag_group_id, m.dedupe_mapping_id
		  FROM dedupe_rule rm
		  JOIN dedupe_mapping m ON rm.dedupe_mapping_id = m.dedupe_mapping_id
		  JOIN cms.tab_column tc ON tc.column_sid = m.col_sid
		  JOIN cms.tab t ON t.tab_sid = tc.tab_sid
		 WHERE m.dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND (m.reference_id IS NOT NULL OR m.tag_group_id IS NOT NULL)
		 ORDER BY rm.position
	)
	LOOP
		v_staging_value := TRIM(lower(GetRawValue(
			in_staging_tab_schema	=> in_staging_tab_schema,
			in_staging_tab_name		=> in_staging_tab_name,
			in_id_column			=> in_staging_id_col_name,
			in_mapped_column		=> r.oracle_column,
			in_reference			=> in_reference,
			in_batch_num_column		=> in_staging_batch_num_col_name,
			in_batch_num			=> in_batch_num,
			in_source_lookup_col	=> in_staging_source_lookup_col,
			in_source_lookup		=> in_source_lookup
		)));

		IF r.reference_id IS NOT NULL THEN
			out_map_ref_vals.extend;
			out_map_ref_vals(out_map_ref_vals.COUNT) := security.T_VARCHAR2_ROW(pos=> r.dedupe_mapping_id, value => v_staging_value);
		ELSE
			FOR t IN(
				SELECT t.tag_id
				  FROM csr.v$tag t
				  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id
				 WHERE tgm.tag_group_id = r.tag_group_id
				   AND LOWER(t.tag) IN (
						SELECT LOWER(TRIM(item))
						  FROM TABLE(aspen2.utils_pkg.SplitString(v_staging_value))  --in the future we might need to offer an option for the delimiter
						)
			)
			LOOP
				out_map_tag_vals.extend;
				out_map_tag_vals(out_map_tag_vals.COUNT) := T_NUMERIC_ROW(pos=> r.dedupe_mapping_id, item => t.tag_id);
			END LOOP;
		END IF;
	END LOOP;
END;

FUNCTION FindMatches(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_staging_source_lookup_col	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_source_lookup				IN VARCHAR2 DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	in_company_row					IN T_DEDUPE_COMPANY_ROW,
	out_rule_set_id					OUT dedupe_rule_set.dedupe_rule_set_id%TYPE,
	out_resulted_match_type_id		OUT dedupe_rule_set.dedupe_match_type_id%TYPE
)RETURN security_pkg.T_SID_IDS /*company_sids*/
AS
	v_matched_sid_t					security.T_SID_TABLE := security.T_SID_TABLE();
	v_matched_sids					security_pkg.T_SID_IDS;
	v_resulted_match_type_id		dedupe_rule_set.dedupe_match_type_id%TYPE;
	v_normalised_company_row		T_DEDUPE_COMPANY_ROW DEFAULT in_company_row;
	v_map_tag_vals					T_NUMERIC_TABLE; /* mapping_id, tag_id */
	v_map_ref_vals					security.T_VARCHAR2_TABLE; /* mapping_id, ref value */
BEGIN
	IF in_force_re_eval = 0 AND HasBeenProcessed(in_dedupe_staging_link_id, in_reference, in_batch_num) = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The record with reference'||in_reference||' has already been processed for staging config:'||in_dedupe_staging_link_id||' and batch_num:'||in_batch_num);
	END IF;

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		dedupe_preprocess_pkg.ApplyRulesToCompanyRow(v_normalised_company_row);
	END IF;

	GetRefsAndTagsFromStaging(
		in_dedupe_staging_link_id		=>	in_dedupe_staging_link_id,
		in_staging_tab_schema			=>	in_staging_tab_schema,
		in_staging_tab_name				=>	in_staging_tab_name,
		in_staging_id_col_name			=>	in_staging_id_col_name,
		in_staging_batch_num_col_name	=>	in_staging_batch_num_col_name,
		in_staging_source_lookup_col	=>	in_staging_source_lookup_col,
		in_reference					=>	in_reference,
		in_batch_num					=>	in_batch_num,
		in_source_lookup				=>	in_source_lookup,
		out_map_ref_vals				=>	v_map_ref_vals,
		out_map_tag_vals				=>	v_map_tag_vals
	);

	FOR r IN(
		SELECT dedupe_rule_set_id, dedupe_match_type_id
		  FROM dedupe_rule_set
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		 ORDER BY position
	)
	LOOP
		v_matched_sid_t := FindMatchesForRuleSet(
			in_rule_set_id					=> r.dedupe_rule_set_id,
			in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
			in_company_row					=> v_normalised_company_row,
			in_map_tag_vals					=> v_map_tag_vals,
			in_map_ref_vals					=> v_map_ref_vals
		);

		IF v_matched_sid_t IS NULL OR v_matched_sid_t.count = 0 THEN
			CONTINUE;
		ELSE
			SELECT column_value
			  BULK COLLECT INTO v_matched_sids
			  FROM TABLE(v_matched_sid_t);

			out_rule_set_id := r.dedupe_rule_set_id;
			out_resulted_match_type_id := r.dedupe_match_type_id;
			EXIT;
		END IF;
	END LOOP;

	RETURN v_matched_sids;
END;

FUNCTION FindMatchesForCompanyRow(
	in_system_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_normalised_row			IN T_DEDUPE_COMPANY_ROW,
	in_map_tag_vals				IN T_NUMERIC_TABLE,
	in_map_ref_vals				IN security.T_VARCHAR2_TABLE,
	out_dedupe_rule_set_id		OUT dedupe_rule_set.dedupe_rule_set_id%TYPE
)RETURN security_pkg.T_SID_IDS /*company_sids*/
AS
	v_matched_sid_t				security.T_SID_TABLE;
	v_matched_sids				security_pkg.T_SID_IDS;
BEGIN
	FOR r IN(
		SELECT dedupe_rule_set_id, dedupe_match_type_id
		  FROM dedupe_rule_set
		 WHERE dedupe_staging_link_id = in_system_staging_link_id
		 ORDER BY position
	)
	LOOP
		v_matched_sid_t := FindMatchesForRuleSet(
			in_rule_set_id				=> r.dedupe_rule_set_id,
			in_dedupe_staging_link_id	=> in_system_staging_link_id,
			in_company_row				=> in_normalised_row,
			in_map_tag_vals				=> in_map_tag_vals,
			in_map_ref_vals				=> in_map_ref_vals
		);

		IF v_matched_sid_t IS NULL OR v_matched_sid_t.count = 0 THEN
			CONTINUE;
		ELSE
			SELECT column_value
			  BULK COLLECT INTO v_matched_sids
			  FROM TABLE(v_matched_sid_t);

			out_dedupe_rule_set_id := r.dedupe_rule_set_id;

			EXIT;
		END IF;
	END LOOP;

	RETURN v_matched_sids;
END;

FUNCTION FindMatchesForNewCompany_UNSEC(
	in_company_row		T_DEDUPE_COMPANY_ROW,
	in_tag_ids			security_pkg.T_SID_IDS,
	in_ref_ids			security_pkg.T_SID_IDS,
	in_ref_vals			chain_pkg.T_STRINGS
)RETURN security_pkg.T_SID_IDS /*company_sids*/
AS
	v_system_staging_link_id	dedupe_staging_link.dedupe_staging_link_id%TYPE;
	v_normalised_company_row	T_DEDUPE_COMPANY_ROW DEFAULT in_company_row;
	v_tag_ids_t					security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_tag_ids);
	v_ref_ids_t					security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_ref_ids);
	v_map_tag_vals				T_NUMERIC_TABLE DEFAULT T_NUMERIC_TABLE(); /* mapping_id, tag_id */
	v_map_ref_vals				security.T_VARCHAR2_TABLE DEFAULT security.T_VARCHAR2_TABLE(); /* mapping_id, ref value */
	v_matched_sids				security_pkg.T_SID_IDS;
	v_temp_mapping_id			dedupe_mapping.dedupe_mapping_id%TYPE;
	v_dedupe_rule_set_id		dedupe_rule_set.dedupe_rule_set_id%TYPE;
BEGIN
	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		dedupe_preprocess_pkg.ApplyRulesToCompanyRow(v_normalised_company_row);
	END IF;

	SELECT dedupe_staging_link_id
	  INTO v_system_staging_link_id
	  FROM dedupe_staging_link
	 WHERE is_owned_by_system = 1;

	SELECT T_NUMERIC_ROW(t.column_value, m.dedupe_mapping_id)
	  BULK COLLECT INTO v_map_tag_vals
	  FROM dedupe_rule_set rs
	  JOIN dedupe_rule r ON r.dedupe_rule_set_id = rs.dedupe_rule_set_id
	  JOIN dedupe_mapping m ON m.dedupe_mapping_id = r.dedupe_mapping_id
	  JOIN csr.tag_group_member tg ON tg.tag_group_id = m.tag_group_id
	  JOIN TABLE(v_tag_ids_t) t ON tg.tag_id = t.column_value
	 WHERE rs.dedupe_staging_link_id = v_system_staging_link_id;

	IF in_ref_ids IS NOT NULL AND in_ref_ids.COUNT > 0 THEN
		FOR i IN in_ref_ids.FIRST .. in_ref_ids.LAST LOOP
			BEGIN
				SELECT m.dedupe_mapping_id
				  INTO v_temp_mapping_id
				  FROM dedupe_mapping m
				 WHERE m.reference_id = in_ref_ids(i)
				   AND m.dedupe_staging_link_id = v_system_staging_link_id
				   AND EXISTS(
						SELECT 1
						  FROM dedupe_rule_set rs
						  JOIN dedupe_rule r ON r.dedupe_rule_set_id = rs.dedupe_rule_set_id
						 WHERE m.dedupe_mapping_id = r.dedupe_mapping_id
					);

				v_map_ref_vals.extend;
				v_map_ref_vals(v_map_ref_vals.COUNT) := security.T_VARCHAR2_ROW(pos => v_temp_mapping_id, value => in_ref_vals(i));
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
		END LOOP;
	END IF;

	v_matched_sids := FindMatchesForCompanyRow(
		in_system_staging_link_id	=> v_system_staging_link_id,
		in_normalised_row			=> v_normalised_company_row,
		in_map_tag_vals				=> v_map_tag_vals,
		in_map_ref_vals				=> v_map_ref_vals,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	RETURN v_matched_sids;
END;

FUNCTION FindAndStoreMatchesPendi_UNSEC(
	in_pending_company_sid		security_pkg.T_SID_ID
)RETURN security_pkg.T_SID_IDS /*company_sids*/
AS
	v_system_staging_link_id	dedupe_staging_link.dedupe_staging_link_id%TYPE;
	v_matched_sids				security_pkg.T_SID_IDS;
	v_resulted_match_type_id	dedupe_rule_set.dedupe_match_type_id%TYPE;
	v_normalised_company_row	T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW();
	v_map_tag_vals				T_NUMERIC_TABLE DEFAULT T_NUMERIC_TABLE(); /* mapping_id, tag_id */
	v_map_ref_vals				security.T_VARCHAR2_TABLE DEFAULT security.T_VARCHAR2_TABLE(); /* mapping_id, ref value */
	v_dedupe_rule_set_id		dedupe_rule_set.dedupe_rule_set_id%TYPE;
	v_count		NUMBER;
BEGIN
	SELECT name,
		company_type_id,
		address_1,
		address_2,
		address_3,
		address_4,
		country_code,
		state,
		postcode,
		phone,
		city,
		website,
		fax,
		sector_id,
		email
	  INTO v_normalised_company_row.name,
		v_normalised_company_row.company_type,
		v_normalised_company_row.address_1,
		v_normalised_company_row.address_2,
		v_normalised_company_row.address_3,
		v_normalised_company_row.address_4,
		v_normalised_company_row.country_code,
		v_normalised_company_row.state,
		v_normalised_company_row.postcode,
		v_normalised_company_row.phone,
		v_normalised_company_row.city,
		v_normalised_company_row.website,
		v_normalised_company_row.fax,
		v_normalised_company_row.sector,
		v_normalised_company_row.email
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_pending_company_sid;

	IF helper_pkg.IsDedupePreprocessEnabled = 1 THEN
		dedupe_preprocess_pkg.ApplyRulesToCompanyRow(v_normalised_company_row);
	END IF;

	SELECT dedupe_staging_link_id
	  INTO v_system_staging_link_id
	  FROM dedupe_staging_link
	 WHERE is_owned_by_system = 1;

	SELECT T_NUMERIC_ROW(pos=> m.dedupe_mapping_id, item => ct.tag_id)
	  BULK COLLECT INTO v_map_tag_vals
	  FROM dedupe_mapping m
	  JOIN csr.tag_group_member tgm ON m.tag_group_id = tgm.tag_group_id
	  JOIN pending_company_tag ct ON tgm.tag_id = ct.tag_id
	 WHERE ct.pending_company_sid = in_pending_company_sid
	   AND EXISTS(
		  SELECT 1
			FROM dedupe_rule_set rs
			JOIN dedupe_rule r ON r.dedupe_rule_set_id = rs.dedupe_rule_set_id
		   WHERE rs.dedupe_staging_link_id = v_system_staging_link_id
			 AND r.dedupe_mapping_id = m.dedupe_mapping_id
	   );

	SELECT security.T_VARCHAR2_ROW(pos => m.dedupe_mapping_id, value => cr.value)
	  BULK COLLECT INTO v_map_ref_vals
	  FROM dedupe_mapping m
	  JOIN company_reference cr ON m.reference_id = cr.reference_id
	 WHERE cr.company_sid = in_pending_company_sid
	   AND EXISTS(
		  SELECT 1
			FROM dedupe_rule_set rs
			JOIN dedupe_rule r ON r.dedupe_rule_set_id = rs.dedupe_rule_set_id
		   WHERE rs.dedupe_staging_link_id = v_system_staging_link_id
			 AND r.dedupe_mapping_id = m.dedupe_mapping_id
	   );

   v_matched_sids := FindMatchesForCompanyRow(
		in_system_staging_link_id	=> v_system_staging_link_id,
		in_normalised_row			=> v_normalised_company_row,
		in_map_tag_vals				=> v_map_tag_vals,
		in_map_ref_vals				=> v_map_ref_vals,
		out_dedupe_rule_set_id		=> v_dedupe_rule_set_id
	);

	IF v_matched_sids IS NOT NULL AND v_matched_sids.COUNT > 0  THEN
		FOR m IN v_matched_sids.FIRST .. v_matched_sids.LAST LOOP
			INSERT INTO pend_company_suggested_match (pending_company_sid, matched_company_sid, dedupe_rule_set_id)
			VALUES(in_pending_company_sid, v_matched_sids(m), v_dedupe_rule_set_id);
		END LOOP;
	END IF;

	RETURN v_matched_sids;
END;

PROCEDURE StoreMatches(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_matched_sids 				IN security_pkg.T_SID_IDS,
	in_rule_set_used 				IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_resulted_match_type_id		IN dedupe_rule_set.dedupe_match_type_id%TYPE,
	out_dedupe_processed_record_id	OUT dedupe_processed_record.dedupe_processed_record_id%TYPE
)
AS
	v_iteration_num			dedupe_processed_record.iteration_num%TYPE;
BEGIN
	SELECT NVL(MAX(iteration_num),0) + 1
	  INTO v_iteration_num
	  FROM dedupe_processed_record
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
	   AND reference = in_reference
	   AND (in_batch_num IS NULL OR batch_num = in_batch_num);

	INSERT INTO dedupe_processed_record(dedupe_processed_record_id,dedupe_staging_link_id,
		reference, iteration_num, batch_num)
	VALUES(dedupe_processed_record_id_seq.NEXTVAL, in_dedupe_staging_link_id,
		in_reference,v_iteration_num, in_batch_num)
	RETURNING dedupe_processed_record_id INTO out_dedupe_processed_record_id;

	IF in_matched_sids IS NOT NULL AND in_matched_sids.COUNT > 0 THEN
		FOR i IN in_matched_sids.FIRST .. in_matched_sids.LAST LOOP
			INSERT INTO dedupe_match(dedupe_match_id, dedupe_processed_record_id, matched_to_company_sid, dedupe_rule_set_id)
			VALUES(dedupe_match_id_seq.NEXTVAL, out_dedupe_processed_record_id, in_matched_sids(i), in_rule_set_used);
		END LOOP;

		--if there is only one match and rule set's match type is auto, auto-link it to the processed record
		IF in_matched_sids.COUNT = 1 AND in_resulted_match_type_id = chain_pkg.DEDUPE_AUTO THEN
			UPDATE dedupe_processed_record
			   SET matched_to_company_sid = in_matched_sids(1),
				matched_by_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR,
				matched_dtm = SYSDATE,
				dedupe_action_type_id = chain_pkg.DEDUPE_AUTO
			 WHERE dedupe_processed_record_id = out_dedupe_processed_record_id;
		ELSE
			UPDATE dedupe_processed_record
			   SET dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL
			 WHERE dedupe_processed_record_id = out_dedupe_processed_record_id;
		END IF;
	END IF;
END;

FUNCTION GetRawValFromMappedCol(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE,
	in_staging_src_lookup_col_name	IN cms.tab_column.oracle_column%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_source_lookup				IN VARCHAR2,
	in_dedupe_field_id				IN dedupe_field.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id					IN reference.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN csr.tag_group.tag_group_id%TYPE DEFAULT NULL
)RETURN VARCHAR2
AS
	v_mapped_column		cms.tab_column.oracle_column%TYPE;
	v_staging_value		VARCHAR2(4000);
BEGIN
	--get mapped col
	SELECT tc.oracle_column
	  INTO v_mapped_column
	  FROM dedupe_mapping m
	  JOIN cms.tab_column tc ON tc.column_sid = m.col_sid
	 WHERE m.dedupe_staging_link_id = in_dedupe_staging_link_id
	   AND (in_dedupe_field_id IS NULL OR m.dedupe_field_id = in_dedupe_field_id)
	   AND (in_reference_id IS NULL OR m.reference_id = in_reference_id)
	   AND (in_tag_group_id IS NULL OR m.tag_group_id = in_tag_group_id);

	v_staging_value := GetRawValue(
		in_staging_tab_schema	=> in_staging_tab_schema,
		in_staging_tab_name		=> in_staging_tab_name,
		in_id_column			=> in_staging_id_col_name,
		in_mapped_column		=> v_mapped_column,
		in_reference			=> in_reference,
		in_batch_num_column 	=> in_staging_batch_num_col_name,
		in_source_lookup_col	=> in_staging_src_lookup_col_name,
		in_batch_num			=> in_batch_num,
		in_source_lookup		=> in_source_lookup
	);

	RETURN v_staging_value;
END;

FUNCTION BuildSqlForCompanyBasedata(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL
)RETURN VARCHAR2
AS
	v_sql				VARCHAR2(4000);
	v_from				VARCHAR2(4000);
BEGIN
	--get mapped + unmapped cols (for the unmapped we will append "null" in the select statement as we need to keep the columns order)
	v_from := ' FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'" t';

	FOR r IN (
		SELECT f.dedupe_field_id, tc.oracle_column
		  FROM dedupe_field f
		  LEFT JOIN dedupe_mapping m ON f.dedupe_field_id = m.dedupe_field_id AND m.dedupe_staging_link_id = in_dedupe_staging_link_id
		  LEFT JOIN cms.tab_column tc ON tc.column_sid = m.col_sid
		  LEFT JOIN cms.tab t ON t.tab_sid = tc.tab_sid
		 WHERE f.dedupe_field_id IN (chain_pkg.FLD_COMPANY_NAME, chain_pkg.FLD_COMPANY_COMPANY_TYPE, chain_pkg.FLD_COMPANY_PARENT,
			chain_pkg.FLD_COMPANY_CREATED_DTM, chain_pkg.FLD_COMPANY_ACTIVATED_DTM, chain_pkg.FLD_COMPANY_ACTIVE, chain_pkg.FLD_COMPANY_ADDRESS,
			chain_pkg.FLD_COMPANY_STATE, chain_pkg.FLD_COMPANY_POSTCODE, chain_pkg.FLD_COMPANY_COUNTRY, chain_pkg.FLD_COMPANY_PHONE,
			chain_pkg.FLD_COMPANY_FAX, chain_pkg.FLD_COMPANY_WEBSITE, chain_pkg.FLD_COMPANY_EMAIL, chain_pkg.FLD_COMPANY_DELETED,
			chain_pkg.FLD_COMPANY_SECTOR, chain_pkg.FLD_COMPANY_CITY, chain_pkg.FLD_COMPANY_DEACTIVATED_DTM, chain_pkg.FLD_COMPANY_PURCHASER_COMPANY)
		 ORDER BY f.dedupe_field_id /*we need to specify the order so we can map the query result columns to the right T_COMPANY_ROW fields*/
	)
	LOOP
		IF v_sql IS NOT NULL THEN
			v_sql := v_sql||',';
		ELSE
			v_sql := 'SELECT ';
		END IF;

		-- If the address field is across multiple staging columns concatenate them for matching and store each field for merging
		IF r.dedupe_field_id = chain_pkg.FLD_COMPANY_ADDRESS THEN
			IF r.oracle_column IS NULL THEN
				v_sql := v_sql || ' NULL, NULL, NULL, NULL '; --address_1, address_2 ...
			ELSE
				v_sql := v_sql || BuildAddressSelectSQL(in_staging_tab_name, r.oracle_column);
			END IF;

			CONTINUE;
		END IF;

		IF r.oracle_column IS NULL THEN
			v_sql := v_sql||' NULL ';
		ELSE
			v_sql := v_sql||'t."'||r.oracle_column||'"';
		END IF;
	END LOOP;

	IF v_sql IS NULL THEN
		RETURN NULL;
	END IF;

	v_sql := v_sql||v_from||' WHERE t."'||in_staging_id_col_name||'"= :1';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:2, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :2 IS NULL';
	END IF;

	--restrict records by the import source lookup key
	IF in_source_lookup_col IS NOT NULL THEN
		v_sql := v_sql||' AND :3 = "'||in_source_lookup_col||'"';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	RETURN v_sql;
END;

FUNCTION GetStagingCompanyRow(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_col		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup		IN VARCHAR2 DEFAULT NULL
)RETURN T_DEDUPE_COMPANY_ROW
AS
	v_sql			VARCHAR2(4000);
	v_company_row	T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW;
BEGIN
	v_sql := BuildSqlForCompanyBasedata(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_batch_num_column,
		in_source_lookup_col		=> in_source_lookup_col
	);

	IF v_sql IS NULL THEN
		RETURN NULL; --no sql cosntructed as no core field mappings were found
	END IF;

	BEGIN
		EXECUTE IMMEDIATE v_sql
		   INTO
			v_company_row.name,
			v_company_row.parent_company_name,
			v_company_row.company_type,
			v_company_row.created_dtm,
			v_company_row.activated_dtm,
			v_company_row.active,
			v_company_row.address_1,
			v_company_row.address_2,
			v_company_row.address_3,
			v_company_row.address_4,
			v_company_row.state,
			v_company_row.postcode,
			v_company_row.country_code,
			v_company_row.phone,
			v_company_row.fax,
			v_company_row.website,
			v_company_row.email,
			v_company_row.deleted,
			v_company_row.sector,
			v_company_row.city,
			v_company_row.deactivated_dtm,
			v_company_row.purchaser_company
		  USING TRIM(in_reference), in_batch_num, in_source_lookup;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'No rows found in staging table for company ref:'||in_reference
				||', batch num:'||in_batch_num||', staging link:'||in_dedupe_staging_link_id||', source lookup_key:'||in_source_lookup||' sql:'||v_sql);
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(-20001, 'Multiple rows found in staging table for company ref:'||in_reference||', batch num:'||in_batch_num
			||', staging link:'||in_dedupe_staging_link_id||', source lookup_key:'||in_source_lookup||' sql:'||v_sql);
	END;

	v_company_row.address := TRIM(v_company_row.address_1||' '||v_company_row.address_2||' '||v_company_row.address_3||' '||v_company_row.address_4);

	RETURN v_company_row;
END;

FUNCTION BuildSqlForRolesSourceData(
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_mapped_role_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_username_col_name		IN cms.tab_column.oracle_column%TYPE
)RETURN VARCHAR2
AS
	v_sql				VARCHAR2(4000);
BEGIN
	v_sql := 'SELECT T_DEDUPE_ROLE("'||in_username_col_name||'", :1, "'||in_mapped_role_col_name||'")'; --add placeholder var for role_sid
	v_sql := v_sql ||' FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'" t';
	v_sql := v_sql ||' WHERE t."'||in_staging_id_col_name||'"= :2';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:3, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	IF in_source_lookup_column IS NOT NULL THEN
		v_sql := v_sql||' AND :4 = "'||in_source_lookup_column||'"';
	ELSE
		v_sql := v_sql||' AND :4 IS NULL';
	END IF;

	RETURN v_sql;
END;

FUNCTION BuildSqlForUserSourceData(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL
)RETURN VARCHAR2
AS
	v_sql				VARCHAR2(4000);
	v_from				VARCHAR2(4000);
BEGIN
	--get mapped + unmapped cols (for the unmapped we will append "null" in the select statement as we need to keep the columns order)
	v_from := ' FROM "'||in_staging_tab_schema||'"."'||in_staging_tab_name||'" t';

	FOR r IN (
		SELECT f.dedupe_field_id, tc.oracle_column
		  FROM dedupe_field f
		  LEFT JOIN dedupe_mapping m ON f.dedupe_field_id = m.dedupe_field_id AND m.dedupe_staging_link_id = in_dedupe_staging_link_id
		  LEFT JOIN cms.tab_column tc ON tc.column_sid = m.col_sid
		 WHERE f.dedupe_field_id IN (chain_pkg.FLD_USER_EMAIL, chain_pkg.FLD_USER_FULL_NAME, chain_pkg.FLD_USER_FIRST_NAME,
			chain_pkg.FLD_USER_LAST_NAME, chain_pkg.FLD_USER_USER_NAME, chain_pkg.FLD_USER_FRIENDLY_NAME, chain_pkg.FLD_USER_PHONE_NUM,
			chain_pkg.FLD_USER_JOB_TITLE, chain_pkg.FLD_USER_CREATED_DTM, chain_pkg.FLD_USER_REF, chain_pkg.FLD_USER_ACTIVE)
		 ORDER BY f.dedupe_field_id /*we need to specify the order so we can map the query result columns to the right T_USER_ROW fields*/
	)
	LOOP
		IF v_sql IS NOT NULL THEN
			v_sql := v_sql||',';
		ELSE
			v_sql := 'SELECT T_DEDUPE_USER_ROW(';
		END IF;

		IF r.oracle_column IS NULL THEN
			v_sql := v_sql||' NULL ';
		ELSE
			v_sql := v_sql||'t."'||r.oracle_column||'"';
		END IF;
	END LOOP;

	IF v_sql IS NULL THEN
		RETURN NULL;
	END IF;

	v_sql := v_sql || ', NULL)'; --corresponds to t_dedupe_user_row.user_sid

	v_sql := v_sql||v_from||' WHERE t."'||in_staging_id_col_name||'"= :1';

	IF in_batch_num_column IS NOT NULL THEN
		v_sql := v_sql||' AND NVL(:2, -1) = NVL("'||in_batch_num_column||'", -1)';
	ELSE
		v_sql := v_sql||' AND :2 IS NULL';
	END IF;

	IF in_source_lookup_column IS NOT NULL THEN
		v_sql := v_sql||' AND :3 = "'||in_source_lookup_column||'"';
	ELSE
		v_sql := v_sql||' AND :3 IS NULL';
	END IF;

	RETURN v_sql;
END;

FUNCTION GetStagingUserRows(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL
)RETURN T_DEDUPE_USER_TABLE
AS
	v_sql				VARCHAR2(4000);
	v_user_table		T_DEDUPE_USER_TABLE;
BEGIN
	v_sql := BuildSqlForUserSourceData(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_batch_num_column,
		in_source_lookup_column		=> in_source_lookup_column
	);

	IF v_sql IS NULL THEN
		RETURN NULL; --no sql constructed as there are no dedupe user field mappings
	END IF;

	EXECUTE IMMEDIATE v_sql
	   BULK COLLECT INTO v_user_table
	  USING in_reference, in_batch_num, in_source_lookup;

	RETURN v_user_table;
END;

PROCEDURE LogItem(
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_old_value					IN dedupe_merge_log.old_val%TYPE DEFAULT NULL,
	in_new_value					IN dedupe_merge_log.new_val%TYPE DEFAULT NULL,
	in_error_message				IN dedupe_merge_log.error_message%TYPE DEFAULT NULL,
	in_dedupe_field_id				IN dedupe_field.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id					IN reference.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN csr.tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_role_sid						IN security_pkg.T_SID_ID DEFAULT NULL,
	in_destination_tab_sid			IN dedupe_mapping.destination_tab_sid%TYPE DEFAULT NULL,
	in_destination_col_sid			IN dedupe_mapping.destination_col_sid%TYPE DEFAULT NULL,
	in_current_desc_value			IN dedupe_merge_log.current_desc_val%TYPE DEFAULT NULL,
	in_new_raw_val					IN dedupe_merge_log.new_raw_val%TYPE DEFAULT NULL,
	in_new_translated_value			IN dedupe_merge_log.new_translated_val%TYPE DEFAULT NULL,
	in_alt_comp_name_downgrade		IN dedupe_merge_log.alt_comp_name_downgrade%TYPE DEFAULT NULL
)
AS
BEGIN
	IF COALESCE(in_new_value, in_old_value, in_error_message) IS NULL THEN
		RETURN;
	END IF;

	BEGIN
		INSERT INTO dedupe_merge_log(
			dedupe_merge_log_id,
			dedupe_processed_record_id,
			dedupe_field_id,
			reference_id,
			tag_group_id,
			role_sid,
			destination_tab_sid,
			destination_col_sid,
			old_val,
			new_val,
			error_message,
			current_desc_val,
			new_raw_val,
			new_translated_val,
			alt_comp_name_downgrade
		)
		VALUES(
			dedupe_merge_log_id_seq.nextval,
			in_dedupe_processed_record_id,
			in_dedupe_field_id,
			in_reference_id,
			in_tag_group_id,
			in_role_sid,
			in_destination_tab_sid,
			in_destination_col_sid,
			in_old_value,
			in_new_value,
			in_error_message,
			in_current_desc_value,
			in_new_raw_val,
			in_new_translated_value,
			in_alt_comp_name_downgrade
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE dedupe_merge_log
			   SET error_message = NVL2(error_message, error_message || '|', '') || NVL(in_error_message, '')
			 WHERE dedupe_processed_record_id = in_dedupe_processed_record_id
				AND (in_reference_id = reference_id
					OR in_dedupe_field_id = dedupe_field_id
					OR in_tag_group_id = tag_group_id
					OR in_destination_col_sid = destination_col_sid
					OR in_role_sid = role_sid
				);
	END;
END;

PROCEDURE LogValueChange (
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_old_value					IN dedupe_merge_log.old_val%TYPE,
	in_new_value					IN dedupe_merge_log.new_val%TYPE,
	in_dedupe_field_id				IN dedupe_field.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id					IN reference.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN csr.tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_role_sid						IN security_pkg.T_SID_ID DEFAULT NULL,
	in_destination_tab_sid			IN dedupe_mapping.destination_tab_sid%TYPE DEFAULT NULL,
	in_destination_col_sid			IN dedupe_mapping.destination_col_sid%TYPE DEFAULT NULL,
	in_current_desc_value			IN dedupe_merge_log.current_desc_val%TYPE DEFAULT NULL,
	in_new_raw_val					IN dedupe_merge_log.new_raw_val%TYPE DEFAULT NULL,
	in_new_translated_value			IN dedupe_merge_log.new_translated_val%TYPE DEFAULT NULL,
	in_alt_comp_name_downgrade		IN dedupe_merge_log.alt_comp_name_downgrade%TYPE DEFAULT NULL
)
AS
BEGIN
	LogItem(
		in_dedupe_processed_record_id	=> in_dedupe_processed_record_id,
		in_old_value					=> in_old_value,
		in_new_value					=> in_new_value,
		in_error_message				=> NULL,
		in_dedupe_field_id				=> in_dedupe_field_id,
		in_reference_id					=> in_reference_id,
		in_tag_group_id					=> in_tag_group_id,
		in_role_sid						=> in_role_sid,
		in_destination_tab_sid			=> in_destination_tab_sid,
		in_destination_col_sid			=> in_destination_col_sid,
		in_current_desc_value			=> in_current_desc_value,
		in_new_raw_val					=> in_new_raw_val,
		in_new_translated_value			=> in_new_translated_value,
		in_alt_comp_name_downgrade		=> in_alt_comp_name_downgrade
	);
END;

PROCEDURE LogError (
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_error_message				IN dedupe_merge_log.error_message%TYPE,
	in_import_val					IN dedupe_merge_log.new_val%TYPE DEFAULT NULL,
	in_dedupe_field_id				IN dedupe_field.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id					IN reference.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN csr.tag_group.tag_group_id%TYPE DEFAULT NULL,
	in_role_sid						IN security_pkg.T_SID_ID DEFAULT NULL,
	in_destination_tab_sid			IN dedupe_mapping.destination_tab_sid%TYPE DEFAULT NULL,
	in_destination_col_sid			IN dedupe_mapping.destination_col_sid%TYPE DEFAULT NULL,
	in_new_raw_value				IN dedupe_merge_log.new_raw_val%TYPE DEFAULT NULL
)
AS
BEGIN
	LogItem(
		in_dedupe_processed_record_id	=> in_dedupe_processed_record_id,
		in_old_value					=> NULL,
		in_new_raw_val					=> in_new_raw_value,
		in_error_message				=> in_error_message,
		in_dedupe_field_id				=> in_dedupe_field_id,
		in_reference_id					=> in_reference_id,
		in_tag_group_id					=> in_tag_group_id,
		in_role_sid						=> in_role_sid,
		in_destination_tab_sid			=> in_destination_tab_sid,
		in_destination_col_sid			=> in_destination_col_sid
	);
END;

PROCEDURE PutCompanyChangesToMemTable(
	in_company_row		IN T_DEDUPE_COMPANY_ROW,
	in_old_row			IN T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW,
	in_val_changes		IN OUT T_DEDUPE_VAL_CHANGE_TABLE
)
AS
BEGIN
	IF in_company_row.name IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_NAME, in_old_row.name, in_company_row.name);
	END IF;

	IF in_company_row.country_code IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_COUNTRY, in_old_row.country_code, in_company_row.country_code);
	END IF;

	IF in_company_row.parent_company_name IS NOT NULL THEN
	in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_PARENT, in_old_row.parent_company_name, in_company_row.parent_company_name);
	END IF;

	IF in_company_row.active IN ('0','1') THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_ACTIVE, in_old_row.active, in_company_row.active);
	END IF;

	IF in_company_row.created_dtm IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_CREATED_DTM, in_old_row.created_dtm, in_company_row.created_dtm);
	END IF;

	IF in_company_row.activated_dtm IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_ACTIVATED_DTM, in_old_row.activated_dtm, in_company_row.activated_dtm);
	END IF;
	
	IF in_company_row.deactivated_dtm IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_DEACTIVATED_DTM, in_old_row.deactivated_dtm, in_company_row.deactivated_dtm);
	END IF;

	IF in_company_row.address IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_ADDRESS, TRIM(in_old_row.address_1||' '||in_old_row.address_2||' '||in_old_row.address_3||' '||in_old_row.address_4), in_company_row.address);
	END IF;

	IF in_company_row.state IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_STATE, in_old_row.state, in_company_row.state);
	END IF;

	IF in_company_row.postcode IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_POSTCODE, in_old_row.postcode, in_company_row.postcode);
	END IF;

	IF in_company_row.phone IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_PHONE, in_old_row.phone, in_company_row.phone);
	END IF;

	IF in_company_row.fax IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_FAX, in_old_row.fax, in_company_row.fax);
	END IF;

	IF in_company_row.website IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_WEBSITE, in_old_row.website, in_company_row.website);
	END IF;

	IF in_company_row.email IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_EMAIL, in_old_row.email, in_company_row.email);
	END IF;

	IF in_company_row.city IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_CITY, in_old_row.city, in_company_row.city);
	END IF;

	IF in_company_row.sector IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_SECTOR, in_old_row.sector, in_company_row.sector);
	END IF;

	IF in_company_row.purchaser_company IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_PURCHASER_COMPANY, NULL, in_company_row.purchaser_company);
	END IF;
END;

PROCEDURE PutUserChangesToMemTable(
	in_user_row		IN T_DEDUPE_USER_ROW,
	in_old_row		IN T_DEDUPE_USER_ROW DEFAULT T_DEDUPE_USER_ROW,
	in_val_changes	IN OUT T_DEDUPE_VAL_CHANGE_TABLE
)
AS
BEGIN
	IF in_user_row.email IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_EMAIL, in_old_row.email, in_user_row.email);
	END IF;

	IF in_user_row.full_name IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_FULL_NAME, in_old_row.full_name, in_user_row.full_name);
	END IF;

	IF in_user_row.user_name IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_USER_NAME, in_old_row.user_name, in_user_row.user_name);
	END IF;

	IF in_user_row.friendly_name IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_FRIENDLY_NAME, in_old_row.friendly_name, in_user_row.friendly_name);
	END IF;

	IF in_user_row.phone_num IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_PHONE_NUM, in_old_row.phone_num, in_user_row.phone_num);
	END IF;

	IF in_user_row.job_title IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_JOB_TITLE, in_old_row.job_title, in_user_row.job_title);
	END IF;

	IF in_user_row.created_dtm IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_CREATED_DTM, in_old_row.created_dtm, in_user_row.created_dtm);
	END IF;

	IF in_user_row.user_ref IS NOT NULL THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_REF, in_old_row.user_ref, in_user_row.user_ref);
	END IF;

	IF in_user_row.active IN ('0','1') THEN
		in_val_changes.extend;
		in_val_changes(in_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_USER_ACTIVE, in_old_row.active, in_user_row.active);
	END IF;
END;

PROCEDURE LogChanges(
	in_processed_record_id 	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_val_change_t			IN T_DEDUPE_VAL_CHANGE_TABLE
)
AS
BEGIN
	FOR r IN (
		SELECT mapping_field_id, old_val, new_val
		  FROM TABLE(in_val_change_t)
	)
	LOOP
		LogValueChange(
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_old_value					=> r.old_val,
			in_new_value					=> r.new_val,
			in_dedupe_field_id				=> r.mapping_field_id
		);
	END LOOP;
END;

FUNCTION TryEstablishRelationship(
	in_processed_record_id				IN	dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_purchaser_company_sid			IN	security.security_pkg.T_SID_ID,
	in_supplier_company_sid				IN	security.security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_purchaser_company_sid					security.security_pkg.T_SID_ID;
	v_error_message							VARCHAR2(4000);
BEGIN
	IF TryParseCompanySid(
		in_raw_val			=> in_purchaser_company_sid,
		out_company_sid		=> v_purchaser_company_sid
	) THEN
		BEGIN
			company_pkg.EstablishRelationship(
				in_purchaser_company_sid		=> v_purchaser_company_sid,
				in_supplier_company_sid			=> in_supplier_company_sid
			);
			RETURN TRUE;
		EXCEPTION
			WHEN security_pkg.ACCESS_DENIED THEN
				v_error_message := 'Access denied. ' || SUBSTR(SQLERRM, 12);
			WHEN OTHERS THEN
				v_error_message := SUBSTR(SQLERRM, 12);
		END;
	ELSE
		v_error_message := 'Unable to find purchaser company';
	END IF;

	IF v_error_message IS NOT NULL THEN
		LogError(
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_new_raw_value				=> v_purchaser_company_sid,
			in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_PURCHASER_COMPANY,
			in_error_message 				=> v_error_message
		);
		RETURN FALSE;
	END IF;
END;

PROCEDURE ActivateOrDeactivate(
	in_active							IN	company.active%TYPE,
	in_activated_dtm					IN	company.activated_dtm%TYPE,
	in_deactivated_dtm					IN	company.deactivated_dtm%TYPE,
	out_action							OUT	chain_pkg.T_ACTIVE,
	out_action_dtm						OUT	company.activated_dtm%TYPE
)
AS
BEGIN
	IF in_active IS NULL THEN
		IF in_activated_dtm IS NULL THEN
			IF NOT in_deactivated_dtm IS NULL THEN
				out_action := chain_pkg.INACTIVE;
				out_action_dtm := in_deactivated_dtm;
			END IF;
		ELSE
			IF in_deactivated_dtm IS NULL OR in_deactivated_dtm < in_activated_dtm THEN
				out_action := chain_pkg.ACTIVE;
				out_action_dtm := in_activated_dtm;
			ELSE
				out_action := chain_pkg.INACTIVE;
				out_action_dtm := in_deactivated_dtm;
			END IF;
		END IF;
		RETURN;
	END IF;
	
	IF in_active = 0 THEN
		IF in_activated_dtm IS NULL THEN
			out_action := chain_pkg.INACTIVE;
			out_action_dtm := NVL(in_deactivated_dtm, TRUNC(SYSDATE));
		ELSE
			IF in_deactivated_dtm IS NULL OR in_deactivated_dtm < in_activated_dtm THEN
				RAISE_APPLICATION_ERROR(chain_pkg.ERR_DEDUPE_INVALID_COMP_DATA, 'No deactivate date or deactivate date is earlier than activated date');
			ELSE
				out_action := chain_pkg.INACTIVE;
				out_action_dtm := in_deactivated_dtm;
			END IF;
		END IF;
		RETURN;
	END IF;

	IF in_active = 1 THEN	
		IF in_activated_dtm IS NULL THEN
			IF NOT in_deactivated_dtm IS NULL THEN
				RAISE_APPLICATION_ERROR(chain_pkg.ERR_DEDUPE_INVALID_COMP_DATA, 'Company is set to be active with deactivated date');
			END IF;

			out_action := chain_pkg.ACTIVE;
			out_action_dtm := TRUNC(SYSDATE);
		ELSE
			IF in_deactivated_dtm IS NULL OR in_deactivated_dtm < in_activated_dtm THEN
				out_action := chain_pkg.ACTIVE;
				out_action_dtm := in_activated_dtm;
			ELSE
				RAISE_APPLICATION_ERROR(chain_pkg.ERR_DEDUPE_INVALID_COMP_DATA, 'Company is set to be active with deactivated date');
			END IF;
		END IF;
		RETURN;
	END IF;
END;

PROCEDURE MergeCompanyActiveStatus(
	in_dedupe_staging_link_id			IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_company_sid						IN security.security_pkg.T_SID_ID,
	in_action							IN chain_pkg.T_ACTIVE,
	in_action_dtm						IN company.activated_dtm%TYPE,
	in_old_company_row					IN T_DEDUPE_COMPANY_ROW,
	in_prev_merges_fld_t				IN security.T_SID_TABLE,
	in_fill_null_fields_t				IN security.T_SID_TABLE,
	in_higher_than_system				IN NUMBER,
	in_company_row						IN OUT T_DEDUPE_COMPANY_ROW
)
AS
	v_top_company_sid					security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;
	v_active							company.active%TYPE;
	v_action_dtm						company.activated_dtm%TYPE := in_action_dtm;
	v_override_company_active			import_source.override_company_active%TYPE;
BEGIN
	SELECT override_company_active
	  INTO v_override_company_active
	  FROM import_source ims
	  JOIN dedupe_staging_link dsl ON ims.import_source_id = dsl.import_source_id
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	SELECT active
	  INTO v_active
	  FROM company
	 WHERE company_sid = in_company_sid;
	
	IF in_action = chain_pkg.ACTIVE THEN
		IF v_override_company_active = 1 THEN
			company_pkg.ReActivateCompany(in_company_sid);
			company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);
			in_company_row.active := chain_pkg.ACTIVE;
			in_company_row.activated_dtm := v_action_dtm;
		ELSE
			IF v_active = chain_pkg.ACTIVE THEN
				IF ShouldBeCleared(chain_pkg.FLD_COMPANY_ACTIVATED_DTM, in_higher_than_system, in_old_company_row.activated_dtm IS NULL, in_prev_merges_fld_t, in_fill_null_fields_t) THEN
					in_company_row.activated_dtm := NULL;
					v_action_dtm := NULL;
				END IF;
			ELSE
				IF NOT ShouldBeCleared(chain_pkg.FLD_COMPANY_DEACTIVATED_DTM, in_higher_than_system, in_old_company_row.deactivated_dtm IS NULL, in_prev_merges_fld_t, in_fill_null_fields_t) THEN
					company_pkg.ReActivateCompany(in_company_sid);
					company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);
					in_company_row.active := chain_pkg.ACTIVE;
					in_company_row.activated_dtm := v_action_dtm;
				END IF;
			END IF;
		END IF;
	ELSIF in_action = chain_pkg.INACTIVE THEN
		IF v_active = chain_pkg.INACTIVE THEN
			IF ShouldBeCleared(chain_pkg.FLD_COMPANY_DEACTIVATED_DTM, in_higher_than_system, in_old_company_row.deactivated_dtm IS NULL, in_prev_merges_fld_t, in_fill_null_fields_t) THEN
				in_company_row.deactivated_dtm := NULL;
				v_action_dtm := NULL;
			END IF;
		ELSE
			IF NOT ShouldBeCleared(chain_pkg.FLD_COMPANY_ACTIVATED_DTM, in_higher_than_system, in_old_company_row.activated_dtm IS NULL, in_prev_merges_fld_t, in_fill_null_fields_t) THEN
				company_pkg.DeactivateCompany(in_company_sid);
				in_company_row.active := chain_pkg.INACTIVE;
				in_company_row.deactivated_dtm := v_action_dtm;
			END IF;
		END IF;
	ELSE
		IF v_override_company_active = 1 THEN
			company_pkg.ReActivateCompany(in_company_sid);
			company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);
			in_company_row.active := chain_pkg.ACTIVE;
			in_company_row.activated_dtm := v_action_dtm;
		END IF;
	END IF;	
	
	UPDATE company
	   SET activated_dtm = CASE WHEN in_action = chain_pkg.ACTIVE THEN NVL(v_action_dtm, activated_dtm) ELSE activated_dtm END,
		   deactivated_dtm = CASE WHEN in_action = chain_pkg.INACTIVE THEN NVL(v_action_dtm, deactivated_dtm) ELSE deactivated_dtm END
	 WHERE company_sid = in_company_sid;
END;

PROCEDURE SetCompanyActiveStatus(
	in_dedupe_staging_link_id			IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_company_sid						IN security.security_pkg.T_SID_ID,
	in_action							IN chain_pkg.T_ACTIVE,
	in_action_dtm						IN company.activated_dtm%TYPE,
	in_company_row						IN OUT T_DEDUPE_COMPANY_ROW
)
AS
	v_top_company_sid					security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;
	v_override_company_active			import_source.override_company_active%TYPE;
BEGIN
	SELECT override_company_active
	  INTO v_override_company_active
	  FROM import_source ims
	  JOIN dedupe_staging_link dsl ON ims.import_source_id = dsl.import_source_id
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	IF v_override_company_active = 1 OR in_action IS NULL OR in_action = chain_pkg.ACTIVE THEN
		company_pkg.ActivateCompany(in_company_sid);
		company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);
		in_company_row.active := chain_pkg.ACTIVE;
		in_company_row.activated_dtm := in_action_dtm;
	ELSIF in_action = chain_pkg.INACTIVE THEN
		company_pkg.DeactivateCompany(in_company_sid);
		in_company_row.active := chain_pkg.INACTIVE;
		in_company_row.deactivated_dtm := in_action_dtm;
	END IF;

	UPDATE company
	   SET activated_dtm = CASE WHEN in_action = chain_pkg.ACTIVE THEN NVL(in_action_dtm, activated_dtm) ELSE activated_dtm END,
		   deactivated_dtm = CASE WHEN in_action = chain_pkg.INACTIVE THEN NVL(in_action_dtm, deactivated_dtm) ELSE deactivated_dtm END
	 WHERE company_sid = in_company_sid;
END;

FUNCTION CreateCompany(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER,
	in_source_lookup			IN VARCHAR2,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_row				IN T_DEDUPE_COMPANY_ROW
) RETURN security_pkg.T_SID_ID
AS
	v_default_company_type_id	company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetDefaultCompanyTypeId;
	v_company_row				T_DEDUPE_COMPANY_ROW DEFAULT in_company_row;

	v_country_code				company.country_code%TYPE;
	v_company_type_id			company.company_type_id%TYPE;
	v_sector_id					company.sector_id%TYPE;

	v_created_company_sid		security.security_pkg.T_SID_ID;
	v_top_company_sid			security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;

	v_raw_val					VARCHAR2(4000);
	v_tag_ids_t					security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_temp_tag_ids				security.T_SID_TABLE;
	v_tag_ids					security.security_pkg.T_SID_IDS;
	v_tag_new_value				VARCHAR2(4000);
	v_parent_company_sid		security.security_pkg.T_SID_ID;

	v_field_val_changes			T_DEDUPE_VAL_CHANGE_TABLE DEFAULT T_DEDUPE_VAL_CHANGE_TABLE();
	v_action					chain_pkg.T_ACTIVE;
	v_action_dtm				company.activated_dtm%TYPE;
BEGIN
	IF in_company_row IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Can''t create company as there are no mappings for any of the core fields for the dedupe staging link:'||in_dedupe_staging_link_id);
	END IF;

	BEGIN
		SELECT country_code
		  INTO v_country_code
		  FROM v$country
		 WHERE lower(trim(v_company_row.country_code)) IN (lower(country_code), lower(name));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			LogError (
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_error_message 				=> 'Country not found',
				in_new_raw_value				=> v_company_row.country_code,
				in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_COUNTRY
			);
		RETURN NULL;
	END;

	--if the company type is not found, fall back to the default one
	BEGIN
		SELECT company_type_id
		  INTO v_company_type_id
		  FROM company_type
		 WHERE lower(trim(v_company_row.company_type)) IN (lower(lookup_key), lower(singular), lower(plural));

		--only log when the company type is found
		v_field_val_changes.extend;
		v_field_val_changes(v_field_val_changes.count) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_COMPANY_TYPE, NULL, v_company_row.company_type);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_company_type_id := v_default_company_type_id;
	END;

	IF v_company_row.sector IS NOT NULL THEN
		SELECT sector_id
		  INTO v_sector_id
		  FROM sector
		 WHERE lower(description) = lower(v_company_row.sector);
	END IF;

	BEGIN
		ActivateOrDeactivate(
			in_active				=> in_company_row.active,
			in_activated_dtm		=> in_company_row.activated_dtm,
			in_deactivated_dtm		=> in_company_row.deactivated_dtm,
			out_action				=> v_action,
			out_action_dtm			=> v_action_dtm
		);
	EXCEPTION
		WHEN chain_pkg.DEDUPE_INVALID_COMP_DATA THEN
			LogError (
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_error_message				=> SUBSTR(SQLERRM, 12)
			);
			RETURN NULL;
	END;	

	IF v_company_row.parent_company_name IS NOT NULL THEN
		SELECT company_sid
		  INTO v_parent_company_sid
		  FROM company
		 WHERE deleted = 0
		   AND nlssort(lower(trim(name)),'nls_sort=generic_m_ai') = nlssort(v_company_row.parent_company_name, 'nls_sort=generic_m_ai');

		company_pkg.CreateSubCompany(
			in_parent_sid		=> v_parent_company_sid,
			in_name				=> v_company_row.name,
			in_country_code		=> v_country_code,
			in_company_type_id	=> v_company_type_id,
			in_sector_id		=> v_sector_id,
			out_company_sid		=> v_created_company_sid
		);
	ELSE
		company_pkg.CreateCompanyNoLink(
			in_name				=> v_company_row.name,
			in_country_code		=> v_country_code,
			in_company_type_id	=> v_company_type_id,
			in_sector_id		=> v_sector_id,
			in_address_1 		=> v_company_row.address_1,
			in_address_2 		=> v_company_row.address_2,
			in_address_3 		=> v_company_row.address_3,
			in_address_4 		=> v_company_row.address_4,
			in_state 			=> v_company_row.state,
			in_postcode 		=> v_company_row.postcode,
			in_phone 			=> v_company_row.phone,
			in_fax 				=> v_company_row.fax,
			in_website 			=> v_company_row.website,
			in_email 			=> v_company_row.email,
			in_city 			=> v_company_row.city,
			out_company_sid		=> v_created_company_sid
		);
	END IF;

	--any reason not to connect it to top company?
	company_pkg.StartRelationship(
		in_purchaser_company_sid		=> v_top_company_sid,
		in_supplier_company_sid			=> v_created_company_sid
	);

	SetCompanyActiveStatus(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_company_sid				=> v_created_company_sid,
		in_action					=> v_action,
		in_action_dtm				=> v_action_dtm,
		in_company_row				=> v_company_row
	);

	--import additional data
	UPDATE company
	   SET created_dtm = NVL(v_company_row.created_dtm, created_dtm),
		   deactivated_dtm = v_company_row.deactivated_dtm
	 WHERE company_sid = v_created_company_sid;

	-- purchaser -> supplier relationship
	IF v_company_row.purchaser_company IS NOT NULL THEN
		IF TryEstablishRelationship(
			in_processed_record_id			=> in_processed_record_id,
			in_purchaser_company_sid		=> v_company_row.purchaser_company,
			in_supplier_company_sid			=> v_created_company_sid
		) THEN
			v_field_val_changes.extend;
			v_field_val_changes(v_field_val_changes.COUNT) := T_DEDUPE_VAL_CHANGE(chain_pkg.FLD_COMPANY_PURCHASER_COMPANY, NULL, v_company_row.purchaser_company);
		ELSE
			v_company_row.purchaser_company := NULL;
		END IF;
	END IF;

	PutCompanyChangesToMemTable(
		in_company_row	=> v_company_row,
		in_val_changes	=> v_field_val_changes
	);

	-- company references
	FOR r IN (
		SELECT reference_id
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND reference_id IS NOT NULL
	)
	LOOP
		v_raw_val := GetRawValFromMappedCol(
			in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
			in_staging_tab_schema			=> in_staging_tab_schema,
			in_staging_tab_name				=> in_staging_tab_name,
			in_staging_id_col_name			=> in_staging_id_col_name,
			in_staging_batch_num_col_name	=> in_batch_num_column,
			in_staging_src_lookup_col_name	=> in_source_lookup_column,
			in_reference					=> in_reference,
			in_batch_num					=> in_batch_num,
			in_source_lookup				=> in_source_lookup,
			in_reference_id					=> r.reference_id
		);

		IF v_raw_val IS NOT NULL THEN
			INSERT INTO company_reference (company_reference_id, reference_id, company_sid, value)
			VALUES (company_reference_id_seq.nextval, r.reference_id, v_created_company_sid, v_raw_val);

			LogValueChange(
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_old_value					=> NULL,
				in_new_value					=> v_raw_val,
				in_reference_id					=> r.reference_id
			);
		END IF;
	END LOOP;

	-- call to link_pkg needs to happen before setting any tags
	chain_link_pkg.AddCompany(v_created_company_sid);

	--tags
	FOR t IN (
		SELECT tag_group_id
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND tag_group_id IS NOT NULL
	)
	LOOP
		v_raw_val := GetRawValFromMappedCol(
			in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
			in_staging_tab_schema			=> in_staging_tab_schema,
			in_staging_tab_name				=> in_staging_tab_name,
			in_staging_id_col_name			=> in_staging_id_col_name,
			in_staging_batch_num_col_name	=> in_batch_num_column,
			in_staging_src_lookup_col_name	=> in_source_lookup_column,
			in_reference					=> in_reference,
			in_batch_num					=> in_batch_num,
			in_source_lookup				=> in_source_lookup,
			in_tag_group_id					=> t.tag_group_id
		);

		SELECT t.tag_id
		  BULK COLLECT INTO v_temp_tag_ids
		  FROM csr.tag_group_member tgm
		  JOIN csr.v$tag t ON t.tag_id = tgm.tag_id
		 WHERE tag_group_id = t.tag_group_id
		   AND LOWER(TRIM(t.tag)) IN (
				SELECT LOWER(TRIM(item))
				  FROM TABLE(aspen2.utils_pkg.SplitString(v_raw_val)) --in the future we might need to offer an option for the delimiter
			);

		v_tag_ids_t := v_tag_ids_t MULTISET UNION v_temp_tag_ids;

		SELECT LISTAGG(tag, ', ') WITHIN GROUP (ORDER BY tag)
		  INTO v_tag_new_value
		  FROM (
			SELECT DISTINCT tag
			  FROM TABLE(v_temp_tag_ids) t_t
			  JOIN csr.v$tag t ON t.tag_id = t_t.column_value
		);

		LogValueChange(
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_old_value					=> NULL,
			in_new_value					=> v_tag_new_value,
			in_new_raw_val					=> v_raw_val,
			in_tag_group_id					=> t.tag_group_id
		);
	END LOOP;
	
	IF v_tag_ids_t.COUNT > 0 THEN
		SELECT column_value
		 BULK COLLECT INTO v_tag_ids
		 FROM TABLE(v_tag_ids_t);

		csr.supplier_pkg.UNSEC_SetTags(
			in_company_region_sid	=> csr.supplier_pkg.GetRegionSid(v_created_company_sid),
			in_tag_ids		=> v_tag_ids
		);
	END IF;

	LogChanges(in_processed_record_id, v_field_val_changes);

	RETURN v_created_company_sid;
END;

PROCEDURE GetOldCompanyRow(
	in_matched_to_company_sid	IN security_pkg.T_SID_ID,
	in_old_company_row 			IN OUT T_DEDUPE_COMPANY_ROW
)
AS
BEGIN
	SELECT c.name,
		   c2.name,
		   ct.lookup_key,
		   c.created_dtm,
		   c.activated_dtm,
		   c.active,
		   c.address_1,
		   c.address_2,
		   c.address_3,
		   c.address_4,
		   c.state,
		   c.postcode,
		   c.country_code,
		   c.phone,
		   c.fax,
		   c.website,
		   c.email,
		   c.deleted,
		   s.description,
		   c.city,
		   c.deactivated_dtm
	  INTO in_old_company_row.name,
		   in_old_company_row.parent_company_name,
		   in_old_company_row.company_type,
		   in_old_company_row.created_dtm,
		   in_old_company_row.activated_dtm,
		   in_old_company_row.active,
		   in_old_company_row.address_1,
		   in_old_company_row.address_2,
		   in_old_company_row.address_3,
		   in_old_company_row.address_4,
		   in_old_company_row.state,
		   in_old_company_row.postcode,
		   in_old_company_row.country_code,
		   in_old_company_row.phone,
		   in_old_company_row.fax,
		   in_old_company_row.website,
		   in_old_company_row.email,
		   in_old_company_row.deleted,
		   in_old_company_row.sector,
		   in_old_company_row.city,
		   in_old_company_row.deactivated_dtm
	  FROM company c
	  JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company c2 ON c2.company_sid = c.parent_sid
	  LEFT JOIN sector s ON s.sector_id = c.sector_id
	 WHERE c.company_sid = in_matched_to_company_sid;
END;

FUNCTION TryMatchSingleUser(
	in_user_name	IN csr.csr_user.user_name%TYPE,
	out_user_row 	OUT T_DEDUPE_USER_ROW
)RETURN BOOLEAN
AS
BEGIN
	out_user_row := T_DEDUPE_USER_ROW();

	BEGIN
		SELECT
			email,
			full_name,
			user_name,
			friendly_name,
			phone_number,
			job_title,
			created_dtm,
			user_ref,
			csr_user_sid,
			active
		  INTO
			out_user_row.email,
			out_user_row.full_name,
			out_user_row.user_name,
			out_user_row.friendly_name,
			out_user_row.phone_num,
			out_user_row.job_title,
			out_user_row.created_dtm,
			out_user_row.user_ref,
			out_user_row.user_sid,
			out_user_row.active
		  FROM csr.v$csr_user
		 WHERE lower(user_name) = lower(in_user_name);
	EXCEPTION
		WHEN OTHERS THEN
			RETURN FALSE;
	END;

	RETURN TRUE;
END;

PROCEDURE GetExistingCmsData(
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_oracle_table					IN cms.tab.oracle_table%TYPE,
	in_company_column				IN cms.tab_column.oracle_column%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE
)
AS
	v_sql							VARCHAR2(4000);
	v_val_sql						VARCHAR2(4000);
	v_str_val						VARCHAR2(4000);
	v_current_desc					VARCHAR2(4000);
	v_date_val						DATE;
	v_enum_tab_sid					cms.tab.tab_sid%TYPE;
	v_success						BOOLEAN;
BEGIN
	FOR r IN (
		SELECT destination_column, destination_data_type, destination_col_type, destination_col_sid
		  FROM tt_dedupe_cms_data
		 WHERE processed_record_id = in_processed_record_id
		   AND oracle_schema = in_oracle_schema
		   AND destination_table = in_oracle_table
		   AND destination_data_type IN ('NUMBER','VARCHAR2', 'DATE')
		 ORDER BY destination_column
	)
	LOOP
		v_str_val := NULL;
		v_date_val := NULL;
		IF r.destination_data_type = 'NUMBER' THEN
			v_val_sql := 'TO_CHAR('||r.destination_column||')';
		ELSE
			v_val_sql := r.destination_column;
		END IF;

		v_sql := '
		SELECT ' || v_val_sql || '
		  FROM ' || in_oracle_schema || '.' || in_oracle_table || '
		 WHERE ' || in_company_column || '= :1';

		IF r.destination_data_type = 'DATE' THEN
			EXECUTE IMMEDIATE v_sql
			   INTO v_date_val
			  USING in_company_sid;
		ELSE
			EXECUTE IMMEDIATE v_sql
			   INTO v_str_val
			  USING in_company_sid;
		END IF;

		v_current_desc := NULL;

		IF v_str_val IS NOT NULL THEN
			IF r.destination_col_type IN (cms.tab_pkg.CT_ENUMERATED, cms.tab_pkg.CT_SEARCH_ENUM, cms.tab_pkg.CT_CASCADE_ENUM, cms.tab_pkg.CT_CONSTRAINED_ENUM) THEN
				v_enum_tab_sid := cms.tab_pkg.GetParentTabSid(r.destination_col_sid);
				v_success := cms.tab_pkg.TryGetEnumDescription(v_enum_tab_sid, r.destination_col_sid, to_number(v_str_val), v_current_desc);
			ELSIF r.destination_col_type = cms.tab_pkg.CT_USER THEN
				SELECT full_name
				  INTO v_current_desc
				  FROM csr.csr_user
				 WHERE csr_user_sid = to_number(v_str_val);
			END IF;
		END IF;

		UPDATE tt_dedupe_cms_data
		   SET current_str_value = v_str_val,
		       current_date_value = v_date_val,
			   current_desc_val = v_current_desc
		 WHERE oracle_schema = in_oracle_schema
		   AND destination_table = in_oracle_table
		   AND destination_column = r.destination_column;
	END LOOP;
END;

FUNCTION CheckForExistingCmsRecord(
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_oracle_table					IN cms.tab.oracle_table%TYPE,
	in_company_column				IN cms.tab_column.oracle_column%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_sql							VARCHAR2(4000);
	v_cur							INTEGER;
	v_rec_count						NUMBER(10);
BEGIN
	v_sql := '
		SELECT COUNT(*)
		  FROM ' || in_oracle_schema || '.' || in_oracle_table || '
		 WHERE ' || in_company_column || ' = :1
	';

	EXECUTE IMMEDIATE v_sql
	   INTO v_rec_count
	  USING in_company_sid;

	RETURN v_rec_count > 0;
END;

PROCEDURE MergeCmsData (
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER,
	in_source_lookup			IN VARCHAR2,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid				IN security.security_pkg.T_SID_ID,
	in_import_source_position 	IN import_source.position%TYPE
)
AS
	v_import_source_id			import_source.import_source_id%TYPE;
	v_destination_tab_sid		security_pkg.T_SID_ID;
	v_destination_table			cms.tab.oracle_table%TYPE;
	v_str_val					VARCHAR2(4000);
	v_date_val					DATE;
	v_num_val					NUMBER;
	v_error_message				VARCHAR2(4000);
	v_raw_val					VARCHAR2(4000);
	v_translated_val			VARCHAR2(4000);
	v_higher_prior_sources_t	security.T_SID_TABLE;
	v_company_col_name			VARCHAR2(4000);
	v_ui_source_position		NUMBER;
BEGIN
	BEGIN
		SELECT dsl.import_source_id, dsl.destination_tab_sid, dt.oracle_table
		  INTO v_import_source_id, v_destination_tab_sid, v_destination_table
		  FROM dedupe_staging_link dsl
		  JOIN cms.tab dt ON dt.tab_sid = dsl.destination_tab_sid
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; --no destination_tab_sid, nothing to merge for cms
	END;

	SELECT import_source_id
	  BULK COLLECT INTO v_higher_prior_sources_t
	  FROM import_source
	 WHERE position < in_import_source_position
	   AND is_owned_by_system = 0;

	 SELECT	position
	   INTO	v_ui_source_position
	   FROM	chain.import_source
	  WHERE	is_owned_by_system = 1;

	FOR r IN (
		SELECT stc.oracle_column source_column, stc.col_type source_col_type,
			stc.data_type source_data_type, dt.oracle_table destination_table, dtc.oracle_column destination_column,
			dtc.col_type destination_col_type, dtc.data_type destination_data_type, dm.tab_sid source_tab_sid, dm.col_sid source_col_sid,
			dm.destination_tab_sid, dm.destination_col_sid, dm.dedupe_mapping_id
		  FROM dedupe_mapping dm
		  JOIN cms.tab st ON st.tab_sid = dm.tab_sid
		  JOIN cms.tab_column stc ON stc.tab_sid = dm.tab_sid AND stc.column_sid = dm.col_sid
		  JOIN cms.tab dt ON dt.tab_sid = dm.destination_tab_sid
		  JOIN cms.tab_column dtc ON dtc.tab_sid = dm.destination_tab_sid AND dtc.column_sid = dm.destination_col_sid
		 WHERE dm.dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND NOT EXISTS(
				SELECT 1
				  FROM dedupe_merge_log dml
				  JOIN dedupe_processed_record dpr ON dpr.dedupe_processed_record_id = dml.dedupe_processed_record_id
				  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
				 WHERE dml.destination_tab_sid = dm.destination_tab_sid
				   AND dml.destination_col_sid = dm.destination_col_sid
				   AND dml.error_message IS NULL
				   AND new_val IS NOT NULL
				   AND dpr.dedupe_processed_record_id <> in_processed_record_id
				   AND (dpr.matched_to_company_sid = in_company_sid OR dpr.created_company_sid = in_company_sid)
				   AND dsl.import_source_id IN (SELECT t.column_value FROM TABLE(v_higher_prior_sources_t) t)
		   )
	)
	LOOP
		v_str_val 			:= NULL;
		v_error_message 	:= NULL;
		v_date_val 			:= NULL;
		v_raw_val 			:= NULL;
		v_translated_val	:= NULL;
		v_num_val 			:= NULL;

		IF r.destination_col_type = cms.tab_pkg.CT_NORMAL THEN
			IF NOT TryParseVal (
				in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
				in_staging_tab_schema		=> in_staging_tab_schema,
				in_staging_tab_name			=> in_staging_tab_name,
				in_staging_id_col_name		=> in_staging_id_col_name,
				in_reference 				=> in_reference,
				in_batch_num_column			=> in_batch_num_column,
				in_batch_num				=> in_batch_num,
				in_source_lookup_col		=> in_source_lookup_column,
				in_source_lookup			=> in_source_lookup,
				in_mapped_column			=> r.source_column,
				in_data_type				=> r.destination_data_type,
				out_str_val					=> v_str_val,
				out_date_val				=> v_date_val
			)
			THEN
				v_raw_val := v_str_val;
				v_error_message := 'Imported value did not have the required data type';
			END IF;
		ELSIF r.destination_col_type = cms.tab_pkg.CT_USER THEN
			IF NOT TryParseUserSid (
				in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
				in_staging_tab_schema		=> in_staging_tab_schema,
				in_staging_tab_name			=> in_staging_tab_name,
				in_staging_id_col_name		=> in_staging_id_col_name,
				in_reference 				=> in_reference,
				in_batch_num_column			=> in_batch_num_column,
				in_source_lookup_col		=> in_source_lookup_column,
				in_batch_num				=> in_batch_num,
				in_source_lookup			=> in_source_lookup,
				in_mapped_column			=> r.source_column,
				out_user_sid				=> v_num_val,
				out_raw_val					=> v_raw_val
			) THEN
				v_error_message := 'Unable to find user ';
			END IF;
		ELSIF r.destination_col_type IN (cms.tab_pkg.CT_ENUMERATED,cms.tab_pkg.CT_SEARCH_ENUM,cms.tab_pkg.CT_CASCADE_ENUM,cms.tab_pkg.CT_CONSTRAINED_ENUM) THEN

			IF NOT TryParseEnumVal (
				in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
				in_staging_tab_schema		=> in_staging_tab_schema,
				in_staging_tab_name			=> in_staging_tab_name,
				in_staging_id_col_name		=> in_staging_id_col_name,
				in_reference 				=> in_reference,
				in_batch_num_column			=> in_batch_num_column,
				in_source_lookup_col		=> in_source_lookup_column,
				in_batch_num				=> in_batch_num,
				in_source_lookup			=> in_source_lookup,
				in_mapped_column			=> r.source_column,
				in_destination_col_sid		=> r.destination_col_sid,
				out_enum_value_id			=> v_num_val,
				out_staging_val				=> v_raw_val,
				out_translated_val			=> v_translated_val
			)THEN
				v_error_message := 'Unable to match imported value to a corresponding enumerated value';
			END IF;
		ELSIF r.destination_col_type IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY) THEN
			IF NOT TryParseCompanySid (
				in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
				in_staging_tab_schema		=> in_staging_tab_schema,
				in_staging_tab_name			=> in_staging_tab_name,
				in_staging_id_col_name		=> in_staging_id_col_name,
				in_reference 				=> in_reference,
				in_batch_num_column			=> in_batch_num_column,
				in_batch_num				=> in_batch_num,
				in_mapped_column			=> r.source_column,
				out_company_sid				=> v_num_val,
				out_raw_val					=> v_raw_val
			) THEN
				v_error_message := 'Unable to find company';
			END IF;
		END IF;

		IF v_error_message IS NOT NULL THEN
			LogError (
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_destination_tab_sid 			=> r.destination_tab_sid,
				in_destination_col_sid			=> r.destination_col_sid,
				in_error_message 				=> v_error_message,
				in_new_raw_value				=> v_raw_val
			);
		ELSE
			INSERT INTO tt_dedupe_cms_data (processed_record_id, oracle_schema, source_table, source_tab_sid, source_column, source_col_sid,
				source_col_type, source_data_type, destination_table, destination_tab_sid, destination_column,
				destination_col_sid, destination_col_type, destination_data_type, new_str_value, new_date_value, new_raw_value, new_translated_value)
			VALUES (in_processed_record_id, in_staging_tab_schema, in_staging_tab_name, r.source_tab_sid, r.source_column, r.source_col_sid,
				r.source_col_type, r.source_data_type, r.destination_table, r.destination_tab_sid, r.destination_column,
				r.destination_col_sid, r.destination_col_type, r.destination_data_type,
				NVL(v_str_val, NVL2(v_num_val, TO_CHAR(v_num_val), NULL)), v_date_val, v_raw_val, v_translated_val);
		END IF;
	END LOOP;

	IF NOT FindCompanyColumnName(
		in_tab_sid					=> v_destination_tab_sid,
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		out_col_name				=> v_company_col_name
	) 
	THEN
		RETURN;
	END IF;

	IF (CheckForExistingCmsRecord(in_staging_tab_schema, v_destination_table, v_company_col_name, in_company_sid)) THEN
		GetExistingCmsData(
			in_oracle_schema		=> in_staging_tab_schema,
			in_oracle_table			=> v_destination_table,
			in_company_column		=> v_company_col_name,
			in_company_sid			=> in_company_sid,
			in_processed_record_id	=> in_processed_record_id
		);
	END IF;

	IF in_import_source_position > v_ui_source_position THEN
		 DELETE FROM tt_dedupe_cms_data
		  WHERE destination_col_sid IN (
			 SELECT dm.destination_col_sid FROM chain.dedupe_mapping dm
			   JOIN chain.dedupe_staging_link dsl ON dm.dedupe_staging_link_id = dsl.dedupe_staging_link_id
			   JOIN tt_dedupe_cms_data dtd ON dm.destination_col_sid = dtd.destination_col_sid
			    AND dm.fill_nulls_under_ui_source = 0
				AND NOT (
					dtd.current_str_value IS NOT NULL
					OR dtd.current_date_value IS NOT NULL
					OR dtd.current_desc_val IS NOT NULL
				)
			);
	END IF;

	MergePreparedCmsData(
		in_oracle_schema			=> in_staging_tab_schema,
		in_destination_table		=> v_destination_table,
		in_destination_tab_sid		=> v_destination_tab_sid,
		in_company_sid				=> in_company_sid,
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_processed_record_id		=> in_processed_record_id
	);
END;

FUNCTION BuildWhereClauseAndGetStagVals(
	in_tab_sid 					IN	cms.tab.tab_sid%TYPE,
	in_company_sid				IN	security.security_pkg.T_SID_ID,
	in_uk_cons_cols 			IN	security.T_VARCHAR2_TABLE,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	out_error_message 			OUT VARCHAR2,
	out_cons_val_array			OUT security_pkg.T_VARCHAR2_ARRAY,
	out_ordered_uk_cons_cols	OUT security.T_VARCHAR2_TABLE
)RETURN VARCHAR2
AS
	v_where				VARCHAR2(4000);
	v_idx				NUMBER DEFAULT 0;
	v_uk_col_val		VARCHAR2(4000);
BEGIN
	--the column order in out_cons_val_array and out_ordered_uk_cons_cols need to be aligned
	out_ordered_uk_cons_cols := security.T_VARCHAR2_TABLE();

	FOR r IN (
		SELECT t.pos column_sid, t.value oracle_column, tc.col_type
		  FROM TABLE(in_uk_cons_cols) t
		  JOIN cms.tab_column tc ON tc.column_sid = t.pos
		 ORDER BY CASE WHEN tc.col_type IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY) THEN -1 
		 		  ELSE tc.col_type END -- put company col type in the 1st slot
	) LOOP
		IF v_idx = 0 THEN
			IF r.col_type NOT IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY) THEN
				RAISE_APPLICATION_ERROR(-20001, 'Expected a company column type in the UC for table with sid:'||in_tab_sid);
			END IF;
		END IF;

		v_idx := v_idx + 1;

		-- Get the new value for this column
		BEGIN
			SELECT new_str_value
			  INTO v_uk_col_val
			  FROM tt_dedupe_cms_data
			 WHERE processed_record_id = in_processed_record_id
			   AND destination_tab_sid = in_tab_sid
			   AND destination_col_sid = r.column_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				IF r.col_type IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY) THEN
					v_uk_col_val := in_company_sid;
				ELSE
					out_error_message := 'No mapping found for the unique constraint column: '||r.oracle_column || ' for the table with sid:'||in_tab_sid;
					RETURN NULL;
				END IF;
		END;

		out_cons_val_array(v_idx) := v_uk_col_val;

		out_ordered_uk_cons_cols.extend(1);
		out_ordered_uk_cons_cols(v_idx) := security.T_VARCHAR2_ROW(r.column_sid, r.oracle_column);

		IF v_where IS NOT NULL THEN
			v_where := v_where || ' AND ';
		END IF;

		v_where := v_where ||'"'||r.oracle_column||'"= :UC'||v_idx;
	END LOOP;

	RETURN v_where;
END;

FUNCTION CmsRecordExists(
	in_oracle_schema			IN cms.tab.oracle_schema%TYPE,
	in_destination_table		IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid		IN cms.tab.tab_sid%TYPE,
	in_matched_company_sid		IN chain.company.company_sid%TYPE,
	in_uk_cons_cols				IN security.T_VARCHAR2_TABLE,
	in_auto_incr_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	out_error_message 			OUT VARCHAR2,
	out_cons_val_array			OUT security_pkg.T_VARCHAR2_ARRAY,
	out_ordered_uk_cons_cols	OUT security.T_VARCHAR2_TABLE,
	out_where_clause			OUT VARCHAR2,
	out_cms_record_id			OUT NUMBER
) RETURN BOOLEAN
AS
	v_sql				VARCHAR2(4000);
	v_ret				NUMBER(10);
	v_col_val			NUMBER(10);
	v_col_type			cms.tab_column.col_type%TYPE;
	v_cur				NUMBER;
BEGIN
	--first get the staging values for the UC columns
	out_where_clause := BuildWhereClauseAndGetStagVals(
		in_tab_sid 					=> in_destination_tab_sid,
		in_company_sid				=> in_matched_company_sid,
		in_uk_cons_cols 			=> in_uk_cons_cols,
		in_processed_record_id		=> in_processed_record_id,
		out_error_message 			=> out_error_message,
		out_cons_val_array			=> out_cons_val_array,
		out_ordered_uk_cons_cols	=> out_ordered_uk_cons_cols
	);

	IF out_where_clause IS NULL THEN
		RETURN FALSE;
	END IF;

	IF in_auto_incr_col_name IS NOT NULL THEN
		v_sql := 'SELECT "'||in_auto_incr_col_name||'" FROM "'||in_oracle_schema||'"."'||in_destination_table||'" ';
	ELSE
		v_sql := 'SELECT COUNT(*) FROM "'||in_oracle_schema||'"."'||in_destination_table||'" ';
	END IF;

	v_sql := v_sql||' WHERE '||out_where_clause;

	--security_pkg.debugmsg(v_sql||'. 1:'||out_cons_val_array(1) ||' 2:'||out_cons_val_array(2)||' 3:'||out_cons_val_array(3));

	BEGIN
		v_cur := dbms_sql.open_cursor;

		dbms_sql.parse(v_cur, v_sql, dbms_sql.native);

		FOR i IN out_cons_val_array.FIRST .. out_cons_val_array.LAST
		LOOP
			dbms_sql.bind_variable(v_cur, ':UC'||i, out_cons_val_array(i));
		END LOOP;

		dbms_sql.define_column(v_cur, 1, v_col_val); --either count or cms_record_id

		v_ret := dbms_sql.execute(v_cur);

		IF in_auto_incr_col_name IS NULL THEN
			v_ret := dbms_sql.fetch_rows(v_cur);

			dbms_sql.column_value(v_cur, 1, v_col_val);

			IF v_col_val > 1 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Multiple records found in the table with sid:'||in_destination_tab_sid||' for company with sid:'||in_matched_company_sid||' sql:'||v_sql);
			END IF;

			dbms_sql.close_cursor(v_cur);
			RETURN v_col_val = 1;
		ELSE
			IF dbms_sql.fetch_rows(v_cur) = 0 THEN
				dbms_sql.close_cursor(v_cur);
				RETURN FALSE;
			END IF;

			dbms_sql.column_value(v_cur, 1, v_col_val);

			IF dbms_sql.fetch_rows(v_cur) > 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Multiple records found in the table with sid:'||in_destination_tab_sid||' for company with sid:'||in_matched_company_sid||' sql:'||v_sql);
			END IF;

			out_cms_record_id := v_col_val;

			dbms_sql.close_cursor(v_cur);
			RETURN TRUE;
		END IF;

		dbms_sql.close_cursor(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			IF v_cur IS NOT NULL THEN
				dbms_sql.close_cursor(v_cur);
			END IF;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;
END;

FUNCTION FindCompanyColumnName(
	in_tab_sid					IN security_pkg.T_SID_ID,
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_col_name				OUT cms.tab_column.oracle_column%TYPE
)RETURN BOOLEAN
AS
BEGIN
	BEGIN
		SELECT tc.oracle_column
		  INTO out_col_name
		  FROM cms.tab_column tc
		  JOIN cms.uk_cons_col ucc ON tc.column_sid = ucc.column_sid
		 WHERE tc.col_type IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY)
		   AND tc.tab_sid = in_tab_sid
		   AND NOT EXISTS (
				SELECT 1
				  FROM dedupe_mapping dm
				 WHERE dm.dedupe_staging_link_id = in_dedupe_staging_link_id
				   AND dm.destination_col_sid = tc.column_sid
			);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
		WHEN TOO_MANY_ROWS THEN
			RAISE_APPLICATION_ERROR(-20001, 'You can''t have more than one unmapped company column in the unique key of the destination table');
	END;
	
	RETURN TRUE;
END;

PROCEDURE MergePreparedChildCmsData (
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_destination_table			IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid			IN cms.tab.oracle_table%TYPE,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_matched_company_sid			IN security.security_pkg.T_SID_ID,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_dedupe_action_type_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_can_update 					IN BOOLEAN
)
AS
	v_company_col_name			cms.tab_column.oracle_column%TYPE;
	v_auto_incr_column_name		cms.tab_column.oracle_column%TYPE;
	v_found_comp_col			BOOLEAN;
	v_record_found				BOOLEAN DEFAULT FALSE;
	v_data_merged				BOOLEAN DEFAULT FALSE;
	v_count						NUMBER;
	v_cms_auto_incr_record_id	NUMBER;
	v_error_message				dedupe_merge_log.error_message%TYPE;
	v_uk_cons_cols				security.T_VARCHAR2_TABLE;
	v_ordered_uk_cons_cols		security.T_VARCHAR2_TABLE;
	v_cons_val_array			security_pkg.T_VARCHAR2_ARRAY;
	v_where_clause				VARCHAR2(4000);
	
	v_company_col_types			security.security_pkg.T_SID_IDS;
BEGIN
	v_company_col_types(1) := cms.tab_pkg.CT_COMPANY;
	v_company_col_types(2) := cms.tab_pkg.CT_FLOW_COMPANY;
	v_uk_cons_cols := cms.tab_pkg.GetUCColsInclColType(in_destination_tab_sid, v_company_col_types);
	
	IF v_uk_cons_cols.COUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Expected at least one UC col for table sid:'||in_destination_tab_sid);
	END IF;

	--check for auto incr column
	BEGIN
		SELECT oracle_column
		  INTO v_auto_incr_column_name
		  FROM cms.tab_column
		 WHERE tab_sid = in_destination_tab_sid
		   AND col_type = cms.tab_pkg.CT_AUTO_INCREMENT;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; --that's fine
	END;

	v_record_found := CmsRecordExists(
		in_oracle_schema			=> in_oracle_schema,
		in_destination_table		=> in_destination_table,
		in_destination_tab_sid		=> in_destination_tab_sid,
		in_matched_company_sid		=> in_matched_company_sid,
		in_processed_record_id		=> in_processed_record_id,
		in_auto_incr_col_name		=> v_auto_incr_column_name,
		in_uk_cons_cols				=> v_uk_cons_cols,
		out_error_message 			=> v_error_message,
		out_cons_val_array			=> v_cons_val_array,
		out_ordered_uk_cons_cols	=> v_ordered_uk_cons_cols,
		out_where_clause			=> v_where_clause,
		out_cms_record_id			=> v_cms_auto_incr_record_id
	);

	IF v_error_message IS NOT NULL THEN
		--no need to carry one with this processed record
		LogError (
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_destination_tab_sid 			=> in_destination_tab_sid,
			in_error_message 				=> v_error_message
		);

		RETURN;
	END IF;

	IF v_record_found AND in_can_update THEN
		UPDATE dedupe_processed_record
		   SET dedupe_action_type_id = in_dedupe_action_type_id,
		   dedupe_action = chain_pkg.ACTION_UPDATE
		 WHERE dedupe_processed_record_id = in_processed_record_id;

		v_data_merged := TryUpdateChildCmsData (
			in_oracle_schema		=> in_oracle_schema,
			in_oracle_table			=> in_destination_table,
			in_tab_sid				=> in_destination_tab_sid,
			in_company_sid			=> in_matched_company_sid,
			in_processed_record_id	=> in_processed_record_id,
			in_uk_cons_cols			=> v_ordered_uk_cons_cols,
			in_cons_val_array		=> v_cons_val_array,
			in_where_clause			=> v_where_clause
		);
	END IF;

	IF NOT v_record_found THEN
		v_found_comp_col := FindCompanyColumnName(
			in_tab_sid					=> in_destination_tab_sid,
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			out_col_name				=> v_company_col_name
		);

		UPDATE dedupe_processed_record
		   SET dedupe_action_type_id = in_dedupe_action_type_id,
		   dedupe_action = chain_pkg.ACTION_CREATE
		 WHERE dedupe_processed_record_id = in_processed_record_id;

		v_data_merged := TryInsertCmsData(
			in_oracle_schema		=> in_oracle_schema,
			in_oracle_table			=> in_destination_table,
			in_company_column		=> v_company_col_name,
			in_company_sid			=> in_matched_company_sid,
			in_processed_record_id	=> in_processed_record_id,
			in_auto_incr_col_name	=> v_auto_incr_column_name,
			out_cms_record_id		=> v_cms_auto_incr_record_id
		);
	END IF;

	IF v_data_merged THEN
		--do the merge logging
		FOR i IN(
			SELECT processed_record_id, current_str_value, new_str_value, current_date_value, new_date_value,
				destination_tab_sid, destination_col_sid, current_desc_val, new_raw_value, new_translated_value
			  FROM tt_dedupe_cms_data
			 WHERE destination_tab_sid = in_destination_tab_sid
			   AND processed_record_id = in_processed_record_id
			   AND (new_date_value IS NOT NULL OR new_str_value IS NOT NULL)
		)
		LOOP
			LogValueChange(
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_old_value					=> CASE WHEN i.current_date_value IS NOT NULL THEN TO_CHAR(i.current_date_value) ELSE i.current_str_value END,
				in_new_value					=> CASE WHEN i.new_date_value IS NOT NULL THEN TO_CHAR(i.new_date_value) ELSE i.new_str_value END,
				in_destination_tab_sid			=> i.destination_tab_sid,
				in_destination_col_sid			=> i.destination_col_sid,
				in_current_desc_value			=> i.current_desc_val,
				in_new_raw_val					=> i.new_raw_value,
				in_new_translated_value			=> i.new_translated_value
			);
		END LOOP;

		--did we merge anything?
		SELECT COUNT(*)
		  INTO v_count
		  FROM dedupe_merge_log
		 WHERE dedupe_processed_record_id = in_processed_record_id
		   AND error_message IS NULL;

		IF v_count > 0 THEN
			UPDATE dedupe_processed_record
			   SET data_merged = 1
			 WHERE dedupe_processed_record_id = in_processed_record_id;
		END IF;
	END IF;

	IF v_cms_auto_incr_record_id IS NOT NULL THEN
		UPDATE dedupe_processed_record
		   SET cms_record_id = v_cms_auto_incr_record_id
		 WHERE dedupe_processed_record_id = in_processed_record_id;
	END IF;
END;

PROCEDURE MergeChildCmsData(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_staging_tab_sid			IN security_pkg.T_SID_ID,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER DEFAULT NULL,
	in_source_lookup			IN VARCHAR2 DEFAULT NULL,
	in_matched_company_sid		IN security.security_pkg.T_SID_ID,
	in_import_source_position 	IN import_source.position%TYPE,
	in_iteration_num			NUMBER DEFAULT 1,
	in_can_update				BOOLEAN,
	in_parent_proc_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_dedupe_action_type_id	IN dedupe_processed_record.dedupe_action_type_id%TYPE,
	out_processed_record_ids	OUT security_pkg.T_SID_IDS
)
AS
	v_import_source_id		import_source.import_source_id%TYPE;
	v_destination_tab_sid	security_pkg.T_SID_ID;
	v_processed_record_id	dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_str_val				VARCHAR2(4000);
	v_date_val				DATE;
	v_num_val				NUMBER;
	v_error_message			VARCHAR2(4000);
	v_raw_val				VARCHAR2(4000);
	v_translated_val		VARCHAR2(4000);
	v_sql					VARCHAR2(4000);

	v_cur					NUMBER;
	v_count					NUMBER;
	v_idx					NUMBER DEFAULT 0;

	v_ret					NUMBER;
	v_source_date			DATE;
	v_source_val			VARCHAR2(4000);
BEGIN
	SELECT import_source_id, destination_tab_sid
	  INTO v_import_source_id, v_destination_tab_sid
	  FROM dedupe_staging_link
	 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	DELETE FROM tt_dedupe_cms_data;

	IF v_destination_tab_sid IS NULL THEN
		RETURN;
	END IF;

	v_sql := BuildSqlForCmsSourceData(
		in_dedupe_staging_link_id 	=> in_dedupe_staging_link_id,
		in_staging_tab_sid			=> in_staging_tab_sid,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_batch_num_column,
		in_source_lookup_column		=> in_source_lookup_column
	);

	IF v_sql IS NULL THEN
		RETURN;
	END IF;

	BEGIN
		v_cur := dbms_sql.open_cursor;

		dbms_sql.parse(v_cur, v_sql, dbms_sql.native);

		dbms_sql.bind_variable(v_cur, ':1', in_reference);
		dbms_sql.bind_variable(v_cur, ':2', in_batch_num);
		dbms_sql.bind_variable(v_cur, ':3', in_source_lookup);

		FOR r IN (
			SELECT dedupe_mapping_id, source_column, source_col_sid, source_col_type, source_data_type,
				destination_table, destination_tab_sid, destination_column, destination_col_sid,
				destination_col_type, destination_data_type
			  FROM tt_column_config
			 ORDER BY dedupe_mapping_id
		)
		LOOP
			v_idx := v_idx + 1;
			IF r.source_data_type = 'DATE' THEN
				dbms_sql.define_column(v_cur, v_idx, v_source_date);
			ELSE
				dbms_sql.define_column(v_cur, v_idx, v_source_val, 4000);
			END IF;
		END LOOP;

		v_ret := dbms_sql.execute(v_cur);

		LOOP
			IF dbms_sql.fetch_rows(v_cur) > 0 THEN

				--create a processed record
				INSERT INTO dedupe_processed_record (
					dedupe_staging_link_id,
					dedupe_processed_record_id,
					reference,
					iteration_num, --need to match the parent iteration_num
					processed_dtm,
					matched_to_company_sid,
					data_merged, --initially 0
					batch_num,
					parent_processed_record_id
				)
				VALUES(
					in_dedupe_staging_link_id,
					dedupe_processed_record_id_seq.nextval,
					in_reference,
					in_iteration_num,
					SYSDATE,
					in_matched_company_sid,
					0,
					in_batch_num,
					in_parent_proc_record_id
				)
				RETURNING dedupe_processed_record_id INTO v_processed_record_id;
				out_processed_record_ids(out_processed_record_ids.COUNT + 1) := v_processed_record_id;

				v_idx := 0;

				FOR r IN (
					SELECT dedupe_mapping_id, source_column, source_col_sid, source_col_type, source_data_type,
						destination_table, destination_tab_sid, destination_column, destination_col_sid, destination_col_type,
						destination_data_type
					  FROM tt_column_config
					 ORDER BY dedupe_mapping_id --we need to associate the column values with the right indices defined previously
				)
				LOOP
					v_source_date := NULL;
					v_source_val := NULL;
					v_idx := v_idx + 1;

					IF r.source_data_type = 'DATE' THEN
						dbms_sql.column_value(v_cur, v_idx, v_source_date);
					ELSE
						dbms_sql.column_value(v_cur, v_idx, v_source_val);
					END IF;

					--initiate TT values
					INSERT INTO tt_dedupe_cms_data (processed_record_id, oracle_schema, source_table, source_tab_sid, source_column, source_col_sid,
						source_col_type, source_data_type, destination_table, destination_tab_sid, destination_column,
						destination_col_sid, destination_col_type, destination_data_type,
						new_date_value, new_raw_value)
					VALUES (v_processed_record_id, in_staging_tab_schema, in_staging_tab_name, in_staging_tab_sid, r.source_column, r.source_col_sid,
						r.source_col_type, r.source_data_type, r.destination_table, r.destination_tab_sid, r.destination_column,
						r.destination_col_sid, r.destination_col_type, r.destination_data_type,
						v_source_date, v_source_val);
				END LOOP;

			ELSE
				EXIT;
			END IF;
		END LOOP;

		dbms_sql.close_cursor(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			IF v_cur IS NOT NULL THEN
				dbms_sql.close_cursor(v_cur);
			END IF;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
	END;

	--put parsed values into the existing TT records
	FOR r IN (
		SELECT processed_record_id, oracle_schema, source_table, source_tab_sid, source_column, source_col_sid,
			source_col_type, source_data_type, destination_table, destination_tab_sid, destination_column,
			destination_col_sid, destination_col_type, destination_data_type,
			new_date_value, new_raw_value
		  FROM tt_dedupe_cms_data
	)
	LOOP
		v_str_val 			:= NULL;
		v_error_message 	:= NULL;
		v_date_val 			:= NULL;
		v_translated_val	:= NULL;
		v_num_val 			:= NULL;

		IF r.destination_col_type = cms.tab_pkg.CT_NORMAL THEN
			IF r.destination_data_type = 'VARCHAR2' THEN
				v_str_val := r.new_raw_value;
			ELSIF r.destination_data_type = 'DATE' THEN
				v_date_val := r.new_date_value;
			ELSIF r.destination_data_type = 'NUMBER' THEN
				IF NOT TryParseNumberVal(r.new_raw_value, v_num_val) THEN
					v_error_message := 'Imported value did not have the required data type';
				END IF;
			ELSE
				v_error_message := 'Imported value did not have the required data type';
			END IF;

		ELSIF r.destination_col_type = cms.tab_pkg.CT_USER THEN
			IF NOT TryParseUserSid (r.new_raw_value, v_num_val) THEN
				v_error_message := 'Unable to find user ';
			END IF;
		ELSIF r.destination_col_type IN (cms.tab_pkg.CT_ENUMERATED,cms.tab_pkg.CT_SEARCH_ENUM,cms.tab_pkg.CT_CASCADE_ENUM,cms.tab_pkg.CT_CONSTRAINED_ENUM) THEN
			IF NOT TryParseEnumVal(
					in_raw_val					=> r.new_raw_value,
					in_destination_col_sid		=> r.destination_col_sid,
					out_enum_value_id			=> v_num_val,
					out_translated_val			=> v_translated_val
			)THEN
				v_error_message := 'Unable to match imported value to a corresponding enumerated value';
			END IF;
		ELSIF r.destination_col_type IN (cms.tab_pkg.CT_COMPANY, cms.tab_pkg.CT_FLOW_COMPANY) THEN
			IF NOT TryParseCompanySid (r.new_raw_value, v_num_val) THEN
				v_error_message := 'Unable to find company';
			END IF;
		ELSE
			v_error_message := 'Destination column type '||r.destination_col_type||' is not supported';
		END IF;

		IF v_error_message IS NOT NULL THEN
			LogError (
				in_dedupe_processed_record_id	=> v_processed_record_id,
				in_destination_tab_sid 			=> r.destination_tab_sid,
				in_destination_col_sid			=> r.destination_col_sid,
				in_error_message 				=> v_error_message,
				in_new_raw_value				=> r.new_raw_value
			);
		ELSE
			UPDATE tt_dedupe_cms_data
			   SET new_str_value = NVL(v_str_val, NVL2(v_num_val, TO_CHAR(v_num_val), NULL)),
				new_date_value = v_date_val,
				new_translated_value = v_translated_val,
				new_raw_value = r.new_raw_value
			 WHERE processed_record_id = r.processed_record_id
			   AND destination_col_sid = r.destination_col_sid;

			IF SQL%ROWCOUNT <> 1 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Expected 1 updated row for processed_record_id:'||r.processed_record_id||' AND destination_col_sid:'||r.destination_col_sid||' got:'||SQL%ROWCOUNT);
			END IF;

		END IF;
	END LOOP;

	--merge into destination tab
	FOR r IN (
		SELECT processed_record_id, oracle_schema, destination_table, destination_tab_sid
		  FROM tt_dedupe_cms_data
		 GROUP BY processed_record_id, oracle_schema, destination_table, destination_tab_sid
		 ORDER BY processed_record_id
	)
	LOOP
		--security_pkg.debugmsg('merge processed record id:'||r.processed_record_id);

		MergePreparedChildCmsData(
			in_oracle_schema			=> r.oracle_schema,
			in_destination_table		=> r.destination_table,
			in_destination_tab_sid		=> r.destination_tab_sid,
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_matched_company_sid		=> in_matched_company_sid,
			in_processed_record_id		=> r.processed_record_id,
			in_dedupe_action_type_id	=> in_dedupe_action_type_id,
			in_can_update 				=> in_can_update
		);
	END LOOP;

	-- Just to be sure we clean after
	DELETE FROM tt_dedupe_cms_data;
END;

PROCEDURE ProcessAltCompNames(
	in_create_alt_company_name	IN dedupe_mapping.allow_create_alt_company_name%TYPE,
	in_matched_company_sid		IN security.security_pkg.T_SID_ID,
	in_alt_comp_name			IN alt_company_name.name%TYPE,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_current_desc_value 		IN dedupe_merge_log.current_desc_val%TYPE
)
AS
BEGIN
	IF NOT company_pkg.CheckAltCompNameExists(in_matched_company_sid,in_alt_comp_name,-1) THEN
		company_pkg.SaveAltCompanyName(in_company_sid => in_matched_company_sid, in_name => in_alt_comp_name);
		LogValueChange(
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_new_value 					=> in_alt_comp_name,
			in_old_value 					=> null,
			in_current_desc_value			=> in_current_desc_value,
			in_alt_comp_name_downgrade		=> in_create_alt_company_name
		);
	END IF;
END;

FUNCTION ShouldBeCleared(
	in_dedupe_field_id			IN NUMBER,
	in_higher_than_system		IN NUMBER,
	in_is_old_cmp_row_null		IN BOOLEAN,
	in_prev_merges_fld_t		IN security.T_SID_TABLE,
	in_fill_null_fld_t			IN security.T_SID_TABLE
) RETURN BOOLEAN
AS
BEGIN
	IF in_dedupe_field_id MEMBER OF in_prev_merges_fld_t THEN 
		RETURN TRUE;
	ELSIF in_dedupe_field_id MEMBER OF in_fill_null_fld_t AND in_higher_than_system = 0 AND NOT in_is_old_cmp_row_null THEN
		RETURN TRUE;
	ELSIF NOT in_dedupe_field_id MEMBER OF in_fill_null_fld_t AND in_higher_than_system = 0 THEN
		RETURN TRUE;
	ELSE 
		RETURN FALSE;
	END IF;
END;


PROCEDURE MergeCompanyData(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER,
	in_source_lookup			IN VARCHAR2,
	in_processed_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_matched_company_sid		IN security.security_pkg.T_SID_ID,
	in_import_source_position 	IN import_source.position%TYPE,
	in_company_row				IN T_DEDUPE_COMPANY_ROW,
	in_fill_nulls_map_ids		IN security.T_SID_TABLE
)
AS
	v_default_company_type_id	company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetDefaultCompanyTypeId;
	v_company_row				T_DEDUPE_COMPANY_ROW DEFAULT in_company_row;

	v_country_code				company.country_code%TYPE;
	v_company_type_id			company.company_type_id%TYPE;
	v_sector_id					company.sector_id%TYPE;
	v_active					company.active%TYPE;

	v_top_company_sid			security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;

	v_raw_val					VARCHAR2(4000);
	v_old_ref_val				company_reference.value%TYPE;
	v_tag_ids					security_pkg.T_SID_IDS;
	v_old_tag_text				VARCHAR2(4000);
	v_new_tag_text				VARCHAR2(4000);
	v_company_region_sid		security_pkg.T_SID_ID;

	v_higher_prior_sources_t	security.T_SID_TABLE;
	v_system_source_position 	import_source.position%TYPE;
	v_higher_than_system		NUMBER(1) DEFAULT 0;
	v_prev_merges_fld_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_prev_merged_ref_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_field_val_changes			T_DEDUPE_VAL_CHANGE_TABLE DEFAULT T_DEDUPE_VAL_CHANGE_TABLE();
	v_old_company_row			T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW();
	v_create_alt_company_name	NUMBER(1);
	v_alt_comp_name_count		NUMBER(10);
	v_alt_comp_name				company.name%TYPE;
	v_count						NUMBER(10);
	v_add						VARCHAR2(4000);
	v_tag_new_value				VARCHAR2(4000);
	v_fill_null_fields_t		security.T_SID_TABLE;
	v_action					chain_pkg.T_ACTIVE;
	v_action_dtm				company.activated_dtm%TYPE;
	v_override_company_active	import_source.override_company_active%TYPE;
BEGIN

	 SELECT	position
	   INTO	v_system_source_position
	   FROM	import_source
	  WHERE	is_owned_by_system = 1;

	IF v_system_source_position > in_import_source_position THEN
		v_higher_than_system := 1;
	END IF;

	SELECT dm.dedupe_field_id
	  BULK COLLECT INTO v_fill_null_fields_t
	  FROM TABLE(in_fill_nulls_map_ids) t
	  JOIN dedupe_mapping dm on t.column_value = dm.dedupe_mapping_id;

	--find the fields that have been merged from a higher priority source (note that we dont log values for system managed)
	SELECT import_source_id
	  BULK COLLECT INTO v_higher_prior_sources_t
	  FROM import_source
	 WHERE position < in_import_source_position
	   AND is_owned_by_system = 0;

	IF v_higher_prior_sources_t.COUNT > 0 THEN
		SELECT DISTINCT dml.dedupe_field_id
		  BULK COLLECT INTO v_prev_merges_fld_t
		  FROM dedupe_merge_log dml
		 WHERE dedupe_field_id IN (
			 chain_pkg.FLD_COMPANY_NAME,
			 chain_pkg.FLD_COMPANY_PARENT,
			 chain_pkg.FLD_COMPANY_COMPANY_TYPE,
			 chain_pkg.FLD_COMPANY_CREATED_DTM,
			 chain_pkg.FLD_COMPANY_ACTIVATED_DTM,
			 chain_pkg.FLD_COMPANY_ACTIVE,
			 chain_pkg.FLD_COMPANY_ADDRESS,
			 chain_pkg.FLD_COMPANY_STATE,
			 chain_pkg.FLD_COMPANY_POSTCODE,
			 chain_pkg.FLD_COMPANY_COUNTRY,
			 chain_pkg.FLD_COMPANY_PHONE,
			 chain_pkg.FLD_COMPANY_FAX,
			 chain_pkg.FLD_COMPANY_WEBSITE,
			 chain_pkg.FLD_COMPANY_EMAIL,
			 chain_pkg.FLD_COMPANY_DELETED,
			 chain_pkg.FLD_COMPANY_SECTOR,
			 chain_pkg.FLD_COMPANY_CITY,
			 chain_pkg.FLD_COMPANY_DEACTIVATED_DTM)
		   AND dml.dedupe_processed_record_id IN (
				SELECT dpr.dedupe_processed_record_id
				  FROM dedupe_processed_record dpr
				  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
				  JOIN TABLE (v_higher_prior_sources_t) t ON t.column_value = dsl.import_source_id
				 WHERE dpr.matched_to_company_sid = in_matched_company_sid
			);
	END IF;

	GetOldCompanyRow(in_matched_company_sid, v_old_company_row);

	IF v_company_row IS NOT NULL THEN
		--for everything we can't merge, clear the vals in the memory table
		--(dont support updating company type, parent for now as they are not supported in UpdateCompany either)
		v_company_row.parent_company_name := NULL;
		v_company_row.company_type := NULL;

		SELECT NVL(MAX(allow_create_alt_company_name),0)
		  INTO v_create_alt_company_name
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND dedupe_field_id = chain_pkg.FLD_COMPANY_NAME;

		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_NAME, v_higher_than_system, v_old_company_row.name IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t) THEN
			v_alt_comp_name := v_company_row.name;
			v_company_row.name := NULL;
			IF v_create_alt_company_name = 1 THEN
				ProcessAltCompNames(v_create_alt_company_name, in_matched_company_sid, v_alt_comp_name, in_processed_record_id, 'Lower priority import source, so moved company name to alternative company name.');
			END IF;
		END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_CREATED_DTM, v_higher_than_system, v_old_company_row.created_dtm IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.created_dtm := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_ADDRESS, v_higher_than_system, v_old_company_row.address_1 IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN
			v_company_row.address_1 := NULL;
			v_company_row.address_2 := NULL;
			v_company_row.address_3 := NULL;
			v_company_row.address_4 := NULL;
			v_company_row.address := NULL;
		END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_STATE, v_higher_than_system, v_old_company_row.state IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.state := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_POSTCODE, v_higher_than_system, v_old_company_row.postcode IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.postcode := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_COUNTRY, v_higher_than_system, v_old_company_row.country_code IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.country_code := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_PHONE, v_higher_than_system, v_old_company_row.phone IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.phone := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_FAX, v_higher_than_system, v_old_company_row.fax IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.fax := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_WEBSITE, v_higher_than_system, v_old_company_row.website IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.website := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_EMAIL, v_higher_than_system, v_old_company_row.email IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.email := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_DELETED, v_higher_than_system, v_old_company_row.deleted IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.deleted := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_SECTOR, v_higher_than_system, v_old_company_row.sector IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.sector := NULL; END IF;
		IF ShouldBeCleared(chain_pkg.FLD_COMPANY_CITY, v_higher_than_system, v_old_company_row.city IS NULL, v_prev_merges_fld_t, v_fill_null_fields_t)
			THEN v_company_row.city := NULL; END IF;

		IF v_company_row.country_code IS NOT NULL THEN
			SELECT country_code
			  INTO v_country_code
			  FROM v$country
			 WHERE lower(trim(v_company_row.country_code)) IN (lower(country_code), lower(name));
		END IF;

		IF v_company_row.sector IS NOT NULL THEN
			BEGIN
			SELECT sector_id
			  INTO v_sector_id
			  FROM sector
			 WHERE lower(description) = lower(v_company_row.sector);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Sector not found. Description:'|| v_company_row.sector);
			END;
		END IF;

		BEGIN
			ActivateOrDeactivate(
				in_active				=> v_company_row.active,
				in_activated_dtm		=> v_company_row.activated_dtm,
				in_deactivated_dtm		=> v_company_row.deactivated_dtm,
				out_action				=> v_action,
				out_action_dtm			=> v_action_dtm
			);
			MergeCompanyActiveStatus(
				in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
				in_company_sid				=> in_matched_company_sid,
				in_action					=> v_action,
				in_action_dtm				=> v_action_dtm,
				in_old_company_row			=> v_old_company_row,
				in_prev_merges_fld_t		=> v_prev_merges_fld_t,
				in_fill_null_fields_t		=> v_fill_null_fields_t,
				in_higher_than_system		=> v_higher_than_system,
				in_company_row				=> v_company_row
			);
		EXCEPTION
			WHEN chain_pkg.DEDUPE_INVALID_COMP_DATA THEN
				LogError (
					in_dedupe_processed_record_id	=> in_processed_record_id,
					in_error_message				=> SUBSTR(SQLERRM, 12)
				);
		END;

		company_pkg.UpdateCompany(
			in_company_sid	=> in_matched_company_sid,
			in_name			=> NVL(v_company_row.name, chain_pkg.PRESERVE_STRING),
			in_country_code	=> NVL(v_country_code, chain_pkg.PRESERVE_STRING),
			in_address_1	=> NVL(v_company_row.address_1, chain_pkg.PRESERVE_STRING),
			in_address_2 	=> CASE WHEN v_company_row.address_1 IS NOT NULL THEN v_company_row.address_2 ELSE chain_pkg.PRESERVE_STRING END,
			in_address_3 	=> CASE WHEN v_company_row.address_1 IS NOT NULL THEN v_company_row.address_3 ELSE chain_pkg.PRESERVE_STRING END,
			in_address_4 	=> CASE WHEN v_company_row.address_1 IS NOT NULL THEN v_company_row.address_4 ELSE chain_pkg.PRESERVE_STRING END,
			in_city			=> NVL(v_company_row.city, chain_pkg.PRESERVE_STRING),
			in_state		=> NVL(v_company_row.state, chain_pkg.PRESERVE_STRING),
			in_postcode		=> NVL(v_company_row.postcode, chain_pkg.PRESERVE_STRING),
			in_phone		=> NVL(v_company_row.phone, chain_pkg.PRESERVE_STRING),
			in_fax			=> NVL(v_company_row.fax, chain_pkg.PRESERVE_STRING),
			in_website		=> NVL(v_company_row.website, chain_pkg.PRESERVE_STRING),
			in_email		=> NVL(v_company_row.email, chain_pkg.PRESERVE_STRING),
			in_sector_id	=> NVL(v_sector_id, chain_pkg.PRESERVE_NUMBER),
			in_trigger_link => 0
		);

		IF v_company_row.name IS NOT NULL AND v_create_alt_company_name = 1 THEN
			ProcessAltCompNames(v_create_alt_company_name, in_matched_company_sid, v_old_company_row.name, in_processed_record_id, 'Higher priority import source, so old company name moved to alternative company name.');
		END IF;

		-- purchaser -> supplier relationship
		IF v_company_row.purchaser_company IS NOT NULL THEN
			IF NOT TryEstablishRelationship(
				in_processed_record_id			=> in_processed_record_id,
				in_purchaser_company_sid		=> v_company_row.purchaser_company,
				in_supplier_company_sid			=> in_matched_company_sid
			) THEN
				v_company_row.purchaser_company := NULL;
			END IF;
		END IF;

		PutCompanyChangesToMemTable(
			in_company_row	=> v_company_row,
			in_val_changes	=> v_field_val_changes,
			in_old_row		=> v_old_company_row
		);
	END IF;

		-- company references
	--find which references we cannot merge
	IF v_higher_prior_sources_t.COUNT > 0 THEN
		SELECT DISTINCT dml.reference_id
		  BULK COLLECT INTO v_prev_merged_ref_t
		  FROM dedupe_merge_log dml
		  JOIN dedupe_mapping dm ON dm.reference_id = dml.reference_id
		  JOIN dedupe_processed_record dpr ON dpr.dedupe_processed_record_id = dml.dedupe_processed_record_id
		  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
		  JOIN TABLE (v_higher_prior_sources_t) t ON t.column_value = dsl.import_source_id
		 WHERE matched_to_company_sid = in_matched_company_sid;
	END IF;

	FOR r IN (
		SELECT reference_id
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND reference_id IS NOT NULL
		   AND reference_id NOT IN(
				SELECT column_value
				  FROM TABLE(v_prev_merged_ref_t)
		   )
	)
	LOOP
		v_raw_val := GetRawValFromMappedCol(
			in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
			in_staging_tab_schema			=> in_staging_tab_schema,
			in_staging_tab_name				=> in_staging_tab_name,
			in_staging_id_col_name			=> in_staging_id_col_name,
			in_staging_batch_num_col_name	=> in_batch_num_column,
			in_staging_src_lookup_col_name	=> in_source_lookup_column,
			in_reference					=> in_reference,
			in_batch_num					=> in_batch_num,
			in_source_lookup				=> in_source_lookup,
			in_reference_id					=> r.reference_id
		);

		IF v_raw_val IS NOT NULL THEN
			BEGIN
				SELECT value
				  INTO v_old_ref_val
				  FROM company_reference
				 WHERE company_sid = in_matched_company_sid
				   AND reference_id = r.reference_id;

			    UPDATE company_reference
				   SET value = v_raw_val
				 WHERE company_sid = in_matched_company_sid
				   AND reference_id = r.reference_id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_old_ref_val := NULL;
					INSERT INTO company_reference (company_reference_id, reference_id, company_sid, value)
						VALUES (company_reference_id_seq.nextval, r.reference_id, in_matched_company_sid, v_raw_val);
			END;

			LogValueChange(
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_old_value					=> v_old_ref_val,
				in_new_value					=> v_raw_val,
				in_reference_id					=> r.reference_id
			);
		END IF;
	END LOOP;

	-- call to link_pkg needs to happen before we try set any tags
	chain_link_pkg.UpdateCompany(in_matched_company_sid);

	--tags
	FOR t IN (
		SELECT tag_group_id
		  FROM dedupe_mapping
		 WHERE dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND tag_group_id IS NOT NULL
	)
	LOOP
		v_raw_val := GetRawValFromMappedCol(
			in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
			in_staging_tab_schema			=> in_staging_tab_schema,
			in_staging_tab_name				=> in_staging_tab_name,
			in_staging_id_col_name			=> in_staging_id_col_name,
			in_staging_batch_num_col_name	=> in_batch_num_column,
			in_staging_src_lookup_col_name	=> in_source_lookup_column,
			in_reference					=> in_reference,
			in_batch_num					=> in_batch_num,
			in_tag_group_id					=> t.tag_group_id,
			in_source_lookup				=> in_source_lookup
		);

		SELECT t.tag_id
		  BULK COLLECT INTO v_tag_ids
		  FROM csr.tag_group_member tgm
		  JOIN csr.v$tag t ON t.tag_id = tgm.tag_id
		 WHERE tag_group_id = t.tag_group_id
		   AND LOWER(TRIM(t.tag)) IN (
				SELECT LOWER(TRIM(item))
				  FROM TABLE(aspen2.utils_pkg.SplitString(v_raw_val)) --in the future we might need to offer an option for the delimiter
			);

		v_company_region_sid := csr.supplier_pkg.GetRegionSid(in_matched_company_sid);
		v_old_tag_text := csr.supplier_pkg.UNSEC_GetTagsText(v_company_region_sid, t.tag_group_id);

		csr.supplier_pkg.UNSEC_SetTagsInsertOnly(
			in_company_region_sid	=> v_company_region_sid,
			in_tag_ids				=> v_tag_ids
		);

		v_new_tag_text := csr.supplier_pkg.UNSEC_GetTagsText(v_company_region_sid, t.tag_group_id);
		
		LogValueChange(
			in_dedupe_processed_record_id	=> in_processed_record_id,
			in_old_value					=> v_old_tag_text,
			in_new_value					=> v_new_tag_text,
			in_new_raw_val					=> v_raw_val,
			in_tag_group_id					=> t.tag_group_id
		);

	END LOOP;

	LogChanges(in_processed_record_id, v_field_val_changes);

	MergeCmsData(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_batch_num_column,
		in_source_lookup_column		=> in_source_lookup_column,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num,
		in_source_lookup			=> in_source_lookup,
		in_processed_record_id		=> in_processed_record_id,
		in_company_sid				=> in_matched_company_sid,
		in_import_source_position	=> in_import_source_position
	);

	--have we actually merged anything?
	SELECT COUNT(*)
	  INTO v_count
	  FROM dedupe_merge_log
	 WHERE dedupe_processed_record_id = in_processed_record_id
	   AND error_message IS NULL;

	IF v_count > 0 THEN
		UPDATE dedupe_processed_record
		   SET data_merged = 1
		 WHERE dedupe_processed_record_id = in_processed_record_id;
	END IF;
END;

PROCEDURE MergeAndLogCompanyTypeRoles(
	in_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_matched_company_sid	IN security_pkg.T_SID_ID,
	in_roles_t				IN T_DEDUPE_ROLE_TABLE,
	in_user_name			IN VARCHAR2,
	in_user_sid				IN security_pkg.T_SID_ID,
	in_company_type_id		IN company_type.company_type_id%TYPE
)
AS
	v_region_sid			security_pkg.T_SID_ID DEFAULT csr.supplier_pkg.GetRegionSid(in_matched_company_sid);
	v_exists  				NUMBER;
BEGIN
	--now process the company type roles
	FOR r IN (
		SELECT role_sid, is_set
		  FROM TABLE (in_roles_t)
		 WHERE lower(user_name) = lower(in_user_name)
		   AND is_set IS NOT NULL
	)
	LOOP
		IF NOT company_type_pkg.IsRoleApplicable(in_company_type_id, r.role_sid) THEN
			LogError (
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_role_sid						=> r.role_sid,
				in_error_message 				=> 'Role is N/A for company type with id:'||in_company_type_id,
				in_new_raw_value				=> r.is_set
			);
		ELSE
			SELECT DECODE(COUNT(*), 0, 0, 1)
			  INTO v_exists
			  FROM csr.region_role_member
			 WHERE app_sid = security_pkg.getapp
			   AND region_sid = v_region_sid
			   AND user_sid = in_user_sid
			   AND role_sid = r.role_sid;

			IF v_exists = r.is_set THEN --nothing is being modified
				CONTINUE;
			END IF;

			IF r.is_set = 1 THEN
				company_user_pkg.AddCompanyTypeRoleToUser(in_matched_company_sid, in_user_sid, r.role_sid);
			ELSIF r.is_set = 0 THEN
				company_user_pkg.RemoveCompanyTypeRoleFromUser(in_matched_company_sid, in_user_sid, r.role_sid);
			END IF;

			LogValueChange(
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_old_value					=> v_exists,
				in_new_value					=> r.is_set,
				in_new_raw_val					=> r.is_set,
				in_role_sid						=> r.role_sid
			);
		END IF;
	END LOOP;
END;

PROCEDURE SetAdditionalUserData(
	in_user_sid		security_pkg.T_SID_ID,
	in_source_row	T_DEDUPE_USER_ROW
)
AS
BEGIN
	IF in_source_row.user_ref IS NOT NULL THEN
		csr.csr_user_pkg.SetUserRef(in_user_sid, in_source_row.user_ref);
	END IF;

	IF in_source_row.created_dtm IS NOT NULL THEN
		--poke the created_dtm
		UPDATE csr.csr_user
		   SET created_dtm = in_source_row.created_dtm
		 WHERE app_sid = security_pkg.getApp
		   AND csr_user_sid = in_user_sid;
	END IF;
END;

PROCEDURE MergeUserData(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema		IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name			IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name		IN cms.tab_column.oracle_column%TYPE,
	in_batch_num_column			IN cms.tab_column.oracle_column%TYPE,
	in_source_lookup_column		IN cms.tab_column.oracle_column%TYPE,
	in_reference				IN VARCHAR2,
	in_batch_num				IN NUMBER,
	in_source_lookup			IN VARCHAR2,
	in_iteration_num			IN NUMBER,
	in_parent_proc_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_matched_company_sid		IN security.security_pkg.T_SID_ID,
	in_company_type_id			IN company_type.company_type_id%TYPE,
	in_import_source_position 	IN import_source.position%TYPE,
	in_can_update				IN BOOLEAN,
	out_processed_record_ids	OUT security_pkg.T_SID_IDS
)
AS
	v_user_table				T_DEDUPE_USER_TABLE;
	v_old_user_row				T_DEDUPE_USER_ROW;
	v_source_user_row			T_DEDUPE_USER_ROW;

	v_higher_prior_sources_t	security.T_SID_TABLE;
	v_prev_merges_fld_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
	v_field_val_changes			T_DEDUPE_VAL_CHANGE_TABLE;

	v_user_found				BOOLEAN DEFAULT FALSE;
	v_data_merged 				BOOLEAN DEFAULT FALSE;
	v_error_found 				BOOLEAN DEFAULT FALSE;
	v_user_sid					security_pkg.T_SID_ID;
	v_processed_record_id		dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_count						NUMBER;
	v_user_is_member			NUMBER;
	v_source_role_temp			T_DEDUPE_ROLE_TABLE;
	v_source_roles_t			T_DEDUPE_ROLE_TABLE DEFAULT T_DEDUPE_ROLE_TABLE();
	v_sql						VARCHAR2(4000);
	v_username_col_name			cms.tab_column.oracle_column%TYPE;
BEGIN
	SELECT import_source_id
	  BULK COLLECT INTO v_higher_prior_sources_t
	  FROM import_source
	 WHERE position < in_import_source_position
	   AND is_owned_by_system = 0;

	v_user_table:= GetStagingUserRows(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_batch_num_column,
		in_source_lookup_column		=> in_source_lookup_column,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num,
		in_source_lookup			=> in_source_lookup
	);

	IF v_user_table IS NULL OR v_user_table.COUNT = 0 THEN
		RETURN;
	END IF;

	SELECT tc.oracle_column
	  INTO v_username_col_name
	  FROM dedupe_mapping dm
	  JOIN cms.tab_column tc ON dm.col_sid = tc.column_sid
	 WHERE dm.app_sid = security_pkg.getApp
	   AND dedupe_staging_link_id = in_dedupe_staging_link_id
	   AND dedupe_field_id = chain_pkg.FLD_USER_USER_NAME;

	--now get the roles from the source
	--For a staging record with format: company_id, user_name, ..., role_1, role_2, role_3 ...
	--we return an array of <user_name, role(n)> for each respective mapped role
	FOR r IN (
		SELECT m.role_sid, tc.oracle_column
		  FROM dedupe_mapping m
		  JOIN cms.tab_column tc ON tc.column_sid = m.col_sid
		 WHERE m.dedupe_staging_link_id = in_dedupe_staging_link_id
		   AND m.role_sid IS NOT NULL
		 ORDER BY m.role_sid
	)
	LOOP
		v_sql := BuildSqlForRolesSourceData(
			in_staging_tab_schema		=> in_staging_tab_schema,
			in_staging_tab_name			=> in_staging_tab_name,
			in_staging_id_col_name		=> in_staging_id_col_name,
			in_batch_num_column			=> in_batch_num_column,
			in_source_lookup_column		=> in_source_lookup_column,
			in_mapped_role_col_name		=> r.oracle_column,
			in_username_col_name		=> v_username_col_name
		);

		EXECUTE IMMEDIATE v_sql
		   BULK COLLECT INTO v_source_role_temp
		  USING r.role_sid, in_reference, in_batch_num, in_source_lookup;

		v_source_roles_t := v_source_roles_t MULTISET UNION v_source_role_temp;
	END LOOP;

	FOR r IN (
		SELECT email, full_name, first_name, last_name, user_name, friendly_name, phone_num,
			job_title, created_dtm, user_ref, active
		  FROM TABLE(v_user_table)
	)
	LOOP
		v_source_user_row := T_DEDUPE_USER_ROW(
			email => TRIM(r.email),
			full_name => TRIM(r.full_name),
			first_name => TRIM(r.first_name),
			last_name => TRIM(r.last_name),
			user_name => TRIM(r.user_name),
			friendly_name => TRIM(r.friendly_name),
			phone_num => TRIM(r.phone_num),
			job_title => TRIM(r.job_title),
			created_dtm => r.created_dtm,
			user_ref => TRIM(r.user_ref),
			active => r.active,
			user_sid => NULL
		);

		--create a processed record
		INSERT INTO dedupe_processed_record (
			dedupe_staging_link_id,
			dedupe_processed_record_id,
			reference,
			iteration_num, --need to match the parent iteration_num
			processed_dtm,
			matched_to_company_sid,
			data_merged, --initially 0
			batch_num,
			parent_processed_record_id
		)
		VALUES(
			in_dedupe_staging_link_id,
			dedupe_processed_record_id_seq.nextval,
			in_reference,
			in_iteration_num,
			SYSDATE,
			in_matched_company_sid,
			0,
			in_batch_num,
			in_parent_proc_record_id
		)
		RETURNING dedupe_processed_record_id INTO v_processed_record_id;
		out_processed_record_ids(out_processed_record_ids.COUNT + 1) := v_processed_record_id;

		--fall back to first/lastname dedupe fields
		IF v_source_user_row.full_name IS NULL AND v_source_user_row.first_name IS NOT NULL AND v_source_user_row.last_name IS NOT NULL THEN
			v_source_user_row.full_name := v_source_user_row.first_name || ' ' || v_source_user_row.last_name;
		ELSE
			--no reason to log them
			v_source_user_row.first_name := NULL;
			v_source_user_row.last_name := NULL;
		END IF;

		--use email address for username if no username is supplied
		IF v_source_user_row.user_name IS NULL THEN
			v_source_user_row.user_name := v_source_user_row.email;
		END IF;

		v_old_user_row := T_DEDUPE_USER_ROW();
		v_user_found := TryMatchSingleUser(v_source_user_row.user_name, v_old_user_row);

		v_user_sid := v_old_user_row.user_sid;

		IF v_user_found THEN

			IF in_can_update THEN
				--find the fields that have been merged from a higher priority source (note that we dont log values for system managed)
				--for core user data we only care for merges against the user and not the matched company
				IF v_higher_prior_sources_t.COUNT > 0 THEN
					SELECT DISTINCT dml.dedupe_field_id
					  BULK COLLECT INTO v_prev_merges_fld_t
					  FROM dedupe_merge_log dml
					 WHERE dedupe_field_id IN (
							chain_pkg.FLD_USER_EMAIL,
							chain_pkg.FLD_USER_FULL_NAME,
							chain_pkg.FLD_USER_USER_NAME,
							chain_pkg.FLD_USER_FRIENDLY_NAME,
							chain_pkg.FLD_USER_PHONE_NUM,
							chain_pkg.FLD_USER_JOB_TITLE,
							chain_pkg.FLD_USER_CREATED_DTM,
							chain_pkg.FLD_USER_REF,
							chain_pkg.FLD_USER_ACTIVE)
					   AND dml.dedupe_processed_record_id IN (
							SELECT dpr.dedupe_processed_record_id
							  FROM dedupe_processed_record dpr
							  JOIN dedupe_staging_link dsl ON dsl.dedupe_staging_link_id = dpr.dedupe_staging_link_id
							  JOIN TABLE (v_higher_prior_sources_t) t ON t.column_value = dsl.import_source_id
							 WHERE dpr.imported_user_sid = v_user_sid
						);

					--for everything we can't merge, clear the vals in the memory table
					IF chain_pkg.FLD_USER_EMAIL MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.email := NULL; END IF;
					IF chain_pkg.FLD_USER_FULL_NAME MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.full_name := NULL; END IF;
					IF chain_pkg.FLD_USER_USER_NAME MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.user_name := NULL; END IF;
					IF chain_pkg.FLD_USER_FRIENDLY_NAME MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.friendly_name := NULL; END IF;
					IF chain_pkg.FLD_USER_PHONE_NUM MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.phone_num := NULL; END IF;
					IF chain_pkg.FLD_USER_JOB_TITLE MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.job_title := NULL; END IF;
					IF chain_pkg.FLD_USER_CREATED_DTM MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.created_dtm := NULL; END IF;
					IF chain_pkg.FLD_USER_REF MEMBER OF v_prev_merges_fld_t THEN v_source_user_row.user_ref := NULL; END IF;
				END IF;

				--we don't clear existing values
				csr.csr_user_pkg.amendUserWhereInputNotNull(
					in_act				=> security_pkg.getAct,
					in_user_sid			=> v_user_sid,
					in_user_name		=> NULL ,--no need to update the user name
					in_full_name		=> v_source_user_row.full_name,
					in_friendly_name	=> v_source_user_row.friendly_name,
					in_email			=> v_source_user_row.email,
					in_job_title		=> v_source_user_row.job_title,
					in_phone_number		=> v_source_user_row.phone_num,
					in_active			=> v_old_user_row.active, --keep current active state
					in_info_xml			=> NULL,
					in_send_alerts		=> NULL,
					in_enable_aria		=> NULL,
					in_line_manager_sid	=> NULL
				);

				SetAdditionalUserData(v_user_sid, v_source_user_row);

				v_data_merged := TRUE;
			END IF;

			--if the user in not a member of the matched company we dont treat the processing record as an update
			SELECT DECODE(COUNT(*), 0, 0, 1)
			  INTO v_user_is_member
			  FROM v$company_user
			 WHERE app_sid = security_pkg.getapp
			   AND company_sid = in_matched_company_sid
			   AND user_sid = v_user_sid;

			IF v_user_is_member = 0 OR in_can_update THEN
				--add/remove company user
				IF v_source_user_row.active = 0 THEN
					company_user_pkg.RemoveUserFromCompany(
						in_user_sid				=> v_user_sid,
						in_company_sid			=> in_matched_company_sid,
						in_remove_last_admin	=> 1
					);
				ELSE
					company_user_pkg.SetVisibility(v_user_sid, chain_pkg.FULL);

					company_user_pkg.AddUserToCompany(
						in_company_sid	=> in_matched_company_sid,
						in_user_sid		=> v_user_sid
					);
				END IF;

				--now process the company type roles
				MergeAndLogCompanyTypeRoles(
					in_processed_record_id	=> v_processed_record_id,
					in_matched_company_sid	=> in_matched_company_sid,
					in_roles_t				=> v_source_roles_t,
					in_user_name			=> v_source_user_row.user_name,
					in_user_sid				=> v_user_sid,
					in_company_type_id		=> in_company_type_id
				);

				v_data_merged := TRUE;
			END IF;

			--if we only set roles/membership, we clear the rest of the fields as we dont log them
			IF v_data_merged AND v_user_is_member = 0 AND NOT in_can_update THEN
				v_source_user_row.email := NULL;
				v_source_user_row.full_name := NULL;
				v_source_user_row.user_name := NULL;
				v_source_user_row.friendly_name := NULL;
				v_source_user_row.phone_num := NULL;
				v_source_user_row.job_title := NULL;
				v_source_user_row.created_dtm := NULL;
				v_source_user_row.user_ref := NULL;
			END IF;
		END IF;

		IF NOT v_user_found THEN
			--create new user
			v_error_found := FALSE;
			IF v_source_user_row.full_name IS NULL THEN
				LogError (
					in_dedupe_processed_record_id	=> v_processed_record_id,
					in_error_message				=> 'Mandatory field missing',
					in_dedupe_field_id				=> chain_pkg.FLD_USER_FULL_NAME
				);
				v_error_found := TRUE;
			END IF;

			IF v_source_user_row.user_name IS NULL THEN
				LogError (
					in_dedupe_processed_record_id	=> v_processed_record_id,
					in_error_message				=> 'Mandatory field missing',
					in_dedupe_field_id				=> chain_pkg.FLD_USER_USER_NAME
				);
				v_error_found := TRUE;
			END IF;

			IF v_error_found THEN
				CONTINUE;
			END IF;

			v_user_sid := company_user_pkg.CreateUser (
				in_company_sid		=> in_matched_company_sid,
				in_full_name		=> v_source_user_row.full_name,
				in_friendly_name	=> v_source_user_row.friendly_name,
				in_email			=> v_source_user_row.email,
				in_user_name		=> v_source_user_row.user_name,
				in_phone_number		=> v_source_user_row.phone_num,
				in_job_title		=> v_source_user_row.job_title
			);

			SetAdditionalUserData(v_user_sid, v_source_user_row);

			company_user_pkg.SetVisibility(v_user_sid, chain_pkg.FULL);
			company_user_pkg.SetRegistrationStatus(v_user_sid, chain_pkg.REGISTERED);
			company_user_pkg.AddUserToCompany(in_matched_company_sid, v_user_sid);
			chain.company_user_pkg.ActivateUser(v_user_sid);

			--now process the company type roles
			MergeAndLogCompanyTypeRoles(
				in_processed_record_id	=> v_processed_record_id,
				in_matched_company_sid	=> in_matched_company_sid,
				in_roles_t				=> v_source_roles_t,
				in_user_name			=> v_source_user_row.user_name,
				in_user_sid				=> v_user_sid,
				in_company_type_id		=> in_company_type_id
			);

			v_data_merged := TRUE;
		END IF;

		--handle the logging
		IF v_data_merged THEN
			v_field_val_changes := T_DEDUPE_VAL_CHANGE_TABLE();

			PutUserChangesToMemTable(
				in_user_row		=> v_source_user_row,
				in_val_changes	=> v_field_val_changes,
				in_old_row		=> v_old_user_row
			);

			LogChanges(v_processed_record_id, v_field_val_changes);

			--have we actually merged anything?
			SELECT COUNT(*)
			  INTO v_count
			  FROM dedupe_merge_log
			 WHERE dedupe_processed_record_id = v_processed_record_id
			   AND error_message IS NULL;

			IF v_count > 0 THEN
				UPDATE dedupe_processed_record
				   SET data_merged = 1
				 WHERE dedupe_processed_record_id = v_processed_record_id;
			END IF;
		END IF;

		UPDATE dedupe_processed_record
		   SET imported_user_sid = v_user_sid
		 WHERE dedupe_processed_record_id = v_processed_record_id;
	END LOOP;
END;

FUNCTION TryUpdateChildCmsData (
	in_oracle_schema 			IN	cms.tab.oracle_schema%TYPE,
	in_oracle_table 			IN	cms.tab.oracle_table%TYPE,
	in_tab_sid 					IN	cms.tab.tab_sid%TYPE,
	in_company_sid				IN	security.security_pkg.T_SID_ID,
	in_processed_record_id 		IN	tt_dedupe_cms_data.processed_record_id%TYPE,
	in_uk_cons_cols				IN	security.T_VARCHAR2_TABLE,
	in_cons_val_array			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_where_clause				IN VARCHAR2
) RETURN BOOLEAN
AS
	v_idx 				NUMBER(10) := 0;
	v_inner_sql 		VARCHAR2(4000);
	v_sql 				VARCHAR2(4000);
	v_col_type 			cms.tab_column.col_type%TYPE;
	v_company_col_name 	cms.tab_column.oracle_column%TYPE;
	v_cur 				INTEGER;
	v_uk_col_val 		VARCHAR2(4000);
	v_current_desc 		VARCHAR2(4000);
	v_enum_tab_sid		security.security_pkg.T_SID_ID;
	v_success			BOOLEAN;
	v_str_val			VARCHAR2(4000);
	v_ret				NUMBER;
BEGIN
	-- Go over each destination column for the destination table and update the current values in the TT
	FOR s IN (
		SELECT tt.destination_column, tc.data_type, tt.destination_col_type, tt.destination_col_sid
		  FROM tt_dedupe_cms_data tt
		  JOIN cms.tab_column tc ON tc.column_sid = tt.destination_col_sid
		 WHERE tt.processed_record_id = in_processed_record_id
		   AND tt.destination_tab_sid = in_tab_sid
		   AND (tt.new_date_value IS NOT NULL OR tt.new_str_value IS NOT NULL)
	) LOOP
		IF s.data_type = 'DATE' THEN
			v_inner_sql := ' current_date_value = (';
		ELSE
			v_inner_sql := ' current_str_value = (';
		END IF;

		v_inner_sql := v_inner_sql||'SELECT '||s.destination_column;
		v_inner_sql := v_inner_sql||' FROM '||in_oracle_schema||'.'||in_oracle_table;
		v_inner_sql := v_inner_sql||' WHERE '||in_where_clause|| ')';

		v_sql := 'UPDATE tt_dedupe_cms_data
							   SET '||v_inner_sql||'
							 WHERE processed_record_id = :PID
							   AND destination_col_sid = :COLSID';

		--security_pkg.debugmsg('update sql: '||v_sql||' processed record: '||in_processed_record_id);

		BEGIN
			v_cur := dbms_sql.open_cursor;
			dbms_sql.parse(v_cur, v_sql, dbms_sql.native);

			FOR i IN in_cons_val_array.FIRST .. in_cons_val_array.LAST
			LOOP
				dbms_sql.bind_variable(v_cur, ':UC'||i, in_cons_val_array(i));
			END LOOP;

			dbms_sql.bind_variable(v_cur, ':PID', in_processed_record_id);
			dbms_sql.bind_variable(v_cur, ':COLSID', s.destination_col_sid);

			v_ret := dbms_sql.execute(v_cur);
			dbms_sql.close_cursor(v_cur);
		EXCEPTION
			WHEN OTHERS THEN
				IF v_cur IS NOT NULL THEN
					dbms_sql.close_cursor(v_cur);
				END IF;
				RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace||' sql:'||v_sql);
		END;

		-- Get the current column description
		SELECT current_str_value
		  INTO v_str_val
		  FROM tt_dedupe_cms_data
		 WHERE processed_record_id = in_processed_record_id
		   AND destination_col_sid = s.destination_col_sid;

		v_current_desc := NULL;

		IF s.destination_col_type IN (cms.tab_pkg.CT_ENUMERATED, cms.tab_pkg.CT_SEARCH_ENUM, cms.tab_pkg.CT_CASCADE_ENUM, cms.tab_pkg.CT_CONSTRAINED_ENUM) THEN
			v_enum_tab_sid := cms.tab_pkg.GetParentTabSid(s.destination_col_sid);
			v_success := cms.tab_pkg.TryGetEnumDescription(v_enum_tab_sid, s.destination_col_sid, TO_NUMBER(v_str_val), v_current_desc);

		ELSIF s.destination_col_type = cms.tab_pkg.CT_USER THEN
			SELECT full_name
			  INTO v_current_desc
			  FROM csr.csr_user
			 WHERE csr_user_sid = TO_NUMBER(v_str_val);
		END IF;

		IF v_current_desc IS NOT NULL THEN
			UPDATE tt_dedupe_cms_data
			   SET current_desc_val = v_current_desc
			 WHERE processed_record_id = in_processed_record_id
			   AND destination_col_sid = s.destination_col_sid;
		END IF;
	END LOOP;

	--update the destination table
	UpdateCmsData (
		in_oracle_schema		=> in_oracle_schema,
		in_oracle_table			=> in_oracle_table,
		in_destination_tab_sid	=> in_tab_sid,
		in_uk_cons_cols			=> in_uk_cons_cols,
		in_cons_val_array		=> in_cons_val_array,
		in_processed_record_id 	=> in_processed_record_id
	);

	RETURN TRUE;
END;

PROCEDURE UpdateCmsData (
	in_oracle_schema		IN cms.tab.oracle_schema%TYPE,
	in_oracle_table			IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid	IN security_pkg.T_SID_ID,
	in_uk_cons_cols			IN security.T_VARCHAR2_TABLE,
	in_cons_val_array		IN security_pkg.T_VARCHAR2_ARRAY,
	in_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE
)
AS
	v_sql				VARCHAR2(4000);
	v_col_count			NUMBER(10) DEFAULT 0;
	v_cur				INTEGER;
	v_ret				NUMBER;
	v_set_sql			VARCHAR2(4000);
	v_where				VARCHAR2(4000);
BEGIN
	FOR r IN (
		SELECT destination_column
		  FROM tt_dedupe_cms_data
		 WHERE processed_record_id = in_processed_record_id
		   AND destination_tab_sid = in_destination_tab_sid
		   AND (new_str_value IS NOT NULL OR new_date_value IS NOT NULL)
		 ORDER BY destination_col_sid
	)
	LOOP
		v_col_count := v_col_count + 1;
		IF v_set_sql IS NULL THEN
			v_set_sql := ' SET ';
		ELSE
			v_set_sql := v_set_sql || ', ';
		END IF;

		v_set_sql := v_set_sql || r.destination_column || ' = :'||v_col_count;
	END LOOP;

	IF v_col_count = 0 THEN
		-- No data to import (e.g. nothing in tt_dedupe_cms_data because of the source priority)
		RETURN;
	END IF;

	v_sql := 'UPDATE ' || in_oracle_schema || '.' || in_oracle_table || v_set_sql;

	FOR i IN in_uk_cons_cols.FIRST .. in_uk_cons_cols.LAST
	LOOP
		IF v_where IS NULL THEN
			v_where := ' WHERE ';
		ELSE
			v_where := v_where || ' AND ';
		END IF;

		v_where := v_where||' "'||in_uk_cons_cols(i).value||'" = :UC'||i;
	END LOOP;

	v_sql := v_sql || v_where;

	--reset
	v_col_count := 0;
	BEGIN
		v_cur := dbms_sql.open_cursor;

		dbms_sql.parse(v_cur, v_sql, dbms_sql.native);

		FOR r IN (
			SELECT destination_column, new_str_value, new_date_value
			  FROM tt_dedupe_cms_data
			 WHERE processed_record_id = in_processed_record_id
			   AND destination_tab_sid = in_destination_tab_sid
			   AND (new_str_value IS NOT NULL OR new_date_value IS NOT NULL)
			 ORDER BY destination_col_sid
		)
		LOOP
			v_col_count := v_col_count + 1;

			IF r.new_date_value IS NOT NULL THEN
				dbms_sql.bind_variable(v_cur, ':'||v_col_count, r.new_date_value);
			ELSE
				dbms_sql.bind_variable(v_cur, ':'||v_col_count, r.new_str_value);
			END IF;
		END LOOP;

		FOR i IN in_cons_val_array.FIRST .. in_cons_val_array.LAST
		LOOP
			dbms_sql.bind_variable(v_cur, ':UC'||i, in_cons_val_array(i));
		END LOOP;

		v_ret := dbms_sql.execute(v_cur);

		--check the number of rows affected
		IF v_ret <> 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Expected 1 updated row in the destination table. Got:'||v_ret||' '||in_cons_val_array(1)||' '||in_cons_val_array(2)||' '||in_cons_val_array(3));
		END IF;

		--security_pkg.debugmsg(v_sql);
		dbms_sql.close_cursor(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			IF v_cur IS NOT NULL THEN
				dbms_sql.close_cursor(v_cur);
			END IF;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace||' '||v_sql);
	END;
END;

FUNCTION TryInsertCmsData (
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_oracle_table					IN cms.tab.oracle_table%TYPE,
	in_company_column				IN cms.tab_column.oracle_column%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_auto_incr_col_name			IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	out_cms_record_id				OUT NUMBER
) RETURN BOOLEAN
AS
	v_insert_sql					VARCHAR2(4000);
	v_values_sql					VARCHAR2(4000);
	v_sql							VARCHAR2(4000);
	v_col_count						NUMBER(10) := 1;
	v_cur							INTEGER;
	v_ret							NUMBER;
	v_missing_mandatory_fields		BOOLEAN;
BEGIN
	--check for mandatory missing values
	FOR r IN (
		SELECT tc.description, dm.dedupe_mapping_id, t.tab_sid, tc.column_sid, tc.description col
		  FROM cms.tab t
		  JOIN cms.tab_column tc ON t.tab_sid = tc.tab_sid
		  JOIN dedupe_mapping dm ON dm.destination_tab_sid = t.tab_sid AND dm.destination_col_sid = tc.column_sid
		  JOIN dedupe_processed_record dpr ON dpr.dedupe_staging_link_id = dm.dedupe_staging_link_id
		 WHERE dpr.dedupe_processed_record_id = in_processed_record_id
		   AND t.oracle_schema = in_oracle_schema
		   AND t.oracle_table = in_oracle_table
		   AND tc.nullable = 'N'
		   AND tc.oracle_column <> in_company_column
		   AND tc.column_sid NOT IN (
			SELECT destination_col_sid
			  FROM tt_dedupe_cms_data
			 WHERE oracle_schema = in_oracle_schema
			   AND processed_record_id = in_processed_record_id
			   AND destination_table = in_oracle_table
			   AND (new_str_value IS NOT NULL OR new_date_value IS NOT NULL)
		   )
	)
	LOOP
		v_missing_mandatory_fields := TRUE;
		LogError (
			in_dedupe_processed_record_id => in_processed_record_id,
			in_destination_tab_sid => r.tab_sid,
			in_destination_col_sid => r.column_sid,
			in_error_message => 'Mandatory field missing'
		);
	END LOOP;

	IF v_missing_mandatory_fields THEN
		RETURN FALSE;
	END IF;

	FOR r IN (
		SELECT destination_column
		  FROM tt_dedupe_cms_data
		 WHERE oracle_schema = in_oracle_schema
		   AND processed_record_id = in_processed_record_id
		   AND destination_table = in_oracle_table
		   AND (new_str_value IS NOT NULL OR new_date_value IS NOT NULL)
		 ORDER BY destination_col_sid
	)
	LOOP
		v_col_count := v_col_count + 1;
		IF v_insert_sql IS NULL THEN
			v_insert_sql := 'INSERT INTO "' || in_oracle_schema || '"."' || in_oracle_table || '" ("' || in_company_column||'"';
		END IF;

		v_insert_sql := v_insert_sql || ', "' || r.destination_column||'"';

		IF v_values_sql IS NULL THEN
			v_values_sql := 'VALUES (:1';
		END IF;

		v_values_sql := v_values_sql || ', :' || v_col_count;
	END LOOP;

	IF v_col_count = 1 THEN
		-- No data to import (e.g. nothing in tt_dedupe_cms_data because of the source priority)
		RETURN TRUE;
	END IF;

	IF in_auto_incr_col_name IS NOT NULL THEN
		v_insert_sql := v_insert_sql || ', "'||in_auto_incr_col_name||'")';

		v_col_count := v_col_count +1;
		v_values_sql := v_values_sql || ', :'||v_col_count|| ')';

		v_col_count := v_col_count +1;
		v_values_sql := v_values_sql || ' RETURNING "'||in_auto_incr_col_name||'" INTO :'||v_col_count;
	ELSE
		v_insert_sql := v_insert_sql || ') ';
		v_values_sql := v_values_sql || ')';
	END IF;

	v_sql := v_insert_sql || v_values_sql;

	BEGIN
		v_cur := dbms_sql.open_cursor;

		dbms_sql.parse(v_cur, v_sql, dbms_sql.native);

		dbms_sql.bind_variable(v_cur, ':1', in_company_sid);

		v_col_count := 1;

		FOR r IN (
			SELECT destination_column, new_str_value, new_date_value
			  FROM tt_dedupe_cms_data
			 WHERE oracle_schema = in_oracle_schema
			   AND processed_record_id = in_processed_record_id
			   AND destination_table = in_oracle_table
			   AND (new_str_value IS NOT NULL OR new_date_value IS NOT NULL)
			 ORDER BY destination_col_sid
		)
		LOOP
			v_col_count := v_col_count + 1;

			IF r.new_date_value IS NOT NULL THEN
				dbms_sql.bind_variable(v_cur, ':'||v_col_count, r.new_date_value);
			ELSE
				dbms_sql.bind_variable(v_cur, ':'||v_col_count, r.new_str_value);
			END IF;
		END LOOP;

		IF in_auto_incr_col_name IS NOT NULL THEN
			v_col_count := v_col_count+1;
			dbms_sql.bind_variable(v_cur, ':'||v_col_count, cms.item_id_seq.nextval);

			v_col_count := v_col_count+1;
			dbms_sql.bind_variable(v_cur, ':'||v_col_count, out_cms_record_id);
		END IF;

		v_ret := dbms_sql.execute(v_cur);


		IF in_auto_incr_col_name IS NOT NULL THEN
			dbms_sql.variable_value(v_cur, ':'||v_col_count, out_cms_record_id);
		END IF;

		dbms_sql.close_cursor(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			IF v_cur IS NOT NULL THEN
				dbms_sql.close_cursor(v_cur);
			END IF;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace||' sql:'||v_sql);
	END;

	RETURN TRUE;
END;

PROCEDURE MergePreparedCmsData (
	in_oracle_schema				IN cms.tab.oracle_schema%TYPE,
	in_destination_table			IN cms.tab.oracle_table%TYPE,
	in_destination_tab_sid			IN cms.tab.oracle_table%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE
)
AS
	v_company_col_name			cms.tab_column.oracle_column%TYPE;
	v_data_merged				BOOLEAN DEFAULT FALSE;
	v_cms_record_id				NUMBER;
	v_uk_cons_cols 				security.T_VARCHAR2_TABLE DEFAULT security.T_VARCHAR2_TABLE();
	v_cons_val_array			security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	IF NOT FindCompanyColumnName(
			in_tab_sid					=> in_destination_tab_sid,
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			out_col_name				=> v_company_col_name
		) 
	THEN
		RETURN;
	END IF;

	IF (CheckForExistingCmsRecord(in_oracle_schema, in_destination_table, v_company_col_name, in_company_sid)) THEN

		v_uk_cons_cols.extend(1);
		v_uk_cons_cols(1) := security.T_VARCHAR2_ROW(1, v_company_col_name);
		v_cons_val_array(1) := in_company_sid;

		UpdateCmsData (
			in_oracle_schema		=> in_oracle_schema,
			in_oracle_table			=> in_destination_table,
			in_uk_cons_cols			=> v_uk_cons_cols,
			in_cons_val_array		=> v_cons_val_array,
			in_destination_tab_sid	=> in_destination_tab_sid,
			in_processed_record_id 	=> in_processed_record_id
		);

		v_data_merged := TRUE;
	ELSE
		v_data_merged := TryInsertCmsData(
			in_oracle_schema		=> in_oracle_schema,
			in_oracle_table			=> in_destination_table,
			in_company_column		=> v_company_col_name,
			in_company_sid			=> in_company_sid,
			in_processed_record_id	=> in_processed_record_id,
			out_cms_record_id		=> v_cms_record_id
		);
	END IF;

	IF v_data_merged THEN
		--do the merge logging
		FOR i IN(
			SELECT processed_record_id, current_str_value, new_str_value, current_date_value, new_date_value,
				destination_tab_sid, destination_col_sid, current_desc_val, new_raw_value, new_translated_value
			  FROM tt_dedupe_cms_data
			 WHERE processed_record_id = in_processed_record_id
			   AND destination_table = in_destination_table
			   AND (new_date_value IS NOT NULL OR new_str_value IS NOT NULL)
		)
		LOOP
			LogValueChange(
				in_dedupe_processed_record_id	=> in_processed_record_id,
				in_old_value					=> CASE WHEN i.current_date_value IS NOT NULL THEN TO_CHAR(i.current_date_value) ELSE i.current_str_value END,
				in_new_value					=> CASE WHEN i.new_date_value IS NOT NULL THEN TO_CHAR(i.new_date_value) ELSE i.new_str_value END,
				in_destination_tab_sid			=> i.destination_tab_sid,
				in_destination_col_sid			=> i.destination_col_sid,
				in_current_desc_value			=> i.current_desc_val,
				in_new_raw_val					=> i.new_raw_value,
				in_new_translated_value			=> i.new_translated_value
			);
		END LOOP;
	END IF;

	-- Just to be sure we clean after
	DELETE FROM tt_dedupe_cms_data;
END;

PROCEDURE ProcessChildStagingRecords(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_source_lookup				IN VARCHAR2 DEFAULT NULL,
	in_parent_proc_record_id		IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	out_processed_record_ids		OUT security_pkg.T_SID_IDS
)
AS
	v_staging_tab_schema			cms.tab.oracle_schema%TYPE;
	v_staging_tab_name				cms.tab.oracle_table%TYPE;
	v_staging_id_col_name			cms.tab_column.oracle_column%TYPE;
	v_staging_batch_num_col_name	cms.tab_column.oracle_column%TYPE;
	v_staging_source_lookup_col		cms.tab_column.oracle_column%TYPE;
	v_staging_tab_sid				security_pkg.T_SID_ID;
	v_destination_tab_sid			security_pkg.T_SID_ID;

	v_matched_to_company_sid 		security_pkg.T_SID_ID;
	v_import_source_position		import_source.position%TYPE;
	v_system_source_position		import_source.position%TYPE;
	v_iteration_num					NUMBER;
	v_dedupe_action_type_id			dedupe_processed_record.dedupe_action_type_id%TYPE;
BEGIN
	IF in_parent_proc_record_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'No parent processed record specified for the staging link with id:'||in_dedupe_staging_link_id);
	END IF;

	SELECT iteration_num, NVL(matched_to_company_sid, created_company_sid), dedupe_action_type_id
	  INTO v_iteration_num, v_matched_to_company_sid, v_dedupe_action_type_id
	  FROM dedupe_processed_record
	 WHERE dedupe_processed_record_id = in_parent_proc_record_id;

	SELECT position
	  INTO v_system_source_position
	  FROM import_source
	 WHERE is_owned_by_system = 1;

	SELECT t.oracle_schema, t.oracle_table, tc.oracle_column, tcb.oracle_column, t.tab_sid,
			s.position, dsl.destination_tab_sid, tcs.oracle_column
	  INTO v_staging_tab_schema, v_staging_tab_name, v_staging_id_col_name, v_staging_batch_num_col_name, v_staging_tab_sid,
			v_import_source_position, v_destination_tab_sid, v_staging_source_lookup_col
	  FROM dedupe_staging_link dsl
	  JOIN import_source s ON dsl.import_source_id = s.import_source_id
	  JOIN cms.tab t ON t.tab_sid = dsl.staging_tab_sid
	  JOIN cms.tab_column tc ON tc.column_sid = dsl.staging_id_col_sid
	  LEFT JOIN cms.tab_column tcb ON tcb.column_sid = dsl.staging_batch_num_col_sid
	  LEFT JOIN cms.tab_column tcs ON tcs.column_sid = dsl.staging_source_lookup_col_sid
	 WHERE dsl.dedupe_staging_link_id = in_dedupe_staging_link_id;

	--if there is a destination CMS table defined we assume we are merging CMS data
	IF v_destination_tab_sid IS NOT NULL THEN
		MergeChildCmsData(
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_staging_tab_schema		=> v_staging_tab_schema,
			in_staging_tab_name			=> v_staging_tab_name,
			in_staging_id_col_name		=> v_staging_id_col_name,
			in_staging_tab_sid			=> v_staging_tab_sid,
			in_batch_num_column			=> v_staging_batch_num_col_name,
			in_source_lookup_column		=> v_staging_source_lookup_col,
			in_reference				=> in_reference,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_matched_company_sid		=> v_matched_to_company_sid,
			in_import_source_position 	=> v_import_source_position,
			in_iteration_num			=> v_iteration_num,
			in_can_update				=> v_import_source_position < v_system_source_position,
			in_parent_proc_record_id	=> in_parent_proc_record_id,
			in_dedupe_action_type_id	=> v_dedupe_action_type_id,
			out_processed_record_ids	=> out_processed_record_ids
		);
	ELSE
		MergeUserData(
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_staging_tab_schema		=> v_staging_tab_schema,
			in_staging_tab_name			=> v_staging_tab_name,
			in_staging_id_col_name		=> v_staging_id_col_name,
			in_batch_num_column			=> v_staging_batch_num_col_name,
			in_source_lookup_column		=> v_staging_source_lookup_col,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_reference				=> in_reference,
			in_iteration_num			=> v_iteration_num,
			in_parent_proc_record_id	=> in_parent_proc_record_id,
			in_matched_company_sid		=> v_matched_to_company_sid,
			in_company_type_id			=> company_type_pkg.GetCompanytypeId(v_matched_to_company_sid),
			in_import_source_position 	=> v_import_source_position,
			in_can_update				=> v_import_source_position < v_system_source_position,
			out_processed_record_ids	=> out_processed_record_ids
		);
	END IF;
END;

PROCEDURE PopulateFillNullMappings(
	in_import_source_id				IN	import_source.import_source_id%TYPE,
	out_fill_null_map_ids			OUT	security.T_SID_TABLE
)
AS
BEGIN
	 SELECT	dedupe_mapping_id
	   BULK	COLLECT INTO out_fill_null_map_ids
	   FROM	dedupe_mapping dm
	   JOIN	dedupe_staging_link dsl ON dm.dedupe_staging_link_id = dsl.dedupe_staging_link_id
	  WHERE dm.fill_nulls_under_ui_source = 1
	    AND	dsl.import_source_id = in_import_source_id;
END;

PROCEDURE MergeRecord (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_company_row					IN T_DEDUPE_COMPANY_ROW,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE,
	in_staging_source_lookup_col	IN cms.tab_column.oracle_column%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER,
	in_source_lookup				IN VARCHAR2,
	in_import_source_position		IN NUMBER,
	in_dedupe_action_type_id		IN dedupe_processed_record.dedupe_action_type_id%TYPE,
	out_child_proc_record_ids		OUT security.security_pkg.T_SID_IDS
)
AS
	v_top_company_sid				security.security_pkg.T_SID_ID DEFAULT helper_pkg.GetTopCompanySid;
	v_system_source_position		NUMBER(10);
	v_import_source_id				import_source.import_source_id%TYPE;
	v_created_company_sid			security.security_pkg.T_SID_ID;
	v_fill_nulls_map_ids			security.T_SID_TABLE;
	v_child_proc_record_ids			security_pkg.T_SID_IDS;
	v_override_company_active		import_source.override_company_active%TYPE;
	v_action						chain_pkg.T_ACTIVE;
	v_action_dtm					company.activated_dtm%TYPE;
	v_old_company_row				T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW();
BEGIN
	 SELECT	position
	   INTO	v_system_source_position
	   FROM	import_source
	  WHERE	is_owned_by_system = 1;

	 SELECT	import_source_id
	   INTO	v_import_source_id
	   FROM	dedupe_staging_link
	  WHERE	dedupe_staging_link_id = in_dedupe_staging_link_id;

	 SELECT override_company_active
	   INTO v_override_company_active
	   FROM import_source ims
	   JOIN dedupe_staging_link dsl ON ims.import_source_id = dsl.import_source_id
	  WHERE dedupe_staging_link_id = in_dedupe_staging_link_id;

	PopulateFillNullMappings(
		in_import_source_id		=> v_import_source_id,
		out_fill_null_map_ids	=> v_fill_nulls_map_ids
	);

	IF in_company_sid IS NULL THEN
		--no matches
		UPDATE dedupe_processed_record
		   SET dedupe_action = chain_pkg.ACTION_CREATE,
		  dedupe_action_type_id = in_dedupe_action_type_id
		 WHERE dedupe_processed_record_id = in_processed_record_id;

		v_created_company_sid := CreateCompany(
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_staging_tab_schema		=> in_staging_tab_schema,
			in_staging_tab_name			=> in_staging_tab_name,
			in_staging_id_col_name		=> in_staging_id_col_name,
			in_batch_num_column			=> in_staging_batch_num_col_name,
			in_source_lookup_column		=> in_staging_source_lookup_col,
			in_reference				=> in_reference,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_company_row				=> in_company_row,
			in_processed_record_id		=> in_processed_record_id
		);

		IF v_created_company_sid IS NULL THEN
			RETURN;
		END IF;

		MergeCmsData(
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_staging_tab_schema		=> in_staging_tab_schema,
			in_staging_tab_name			=> in_staging_tab_name,
			in_staging_id_col_name		=> in_staging_id_col_name,
			in_batch_num_column			=> in_staging_batch_num_col_name,
			in_source_lookup_column		=> in_staging_source_lookup_col,
			in_reference				=> in_reference,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_processed_record_id		=> in_processed_record_id,
			in_company_sid				=> v_created_company_sid,
			in_import_source_position 	=> in_import_source_position
		);

		UPDATE dedupe_processed_record
		   SET created_company_sid = v_created_company_sid,
			   data_merged = 1
		 WHERE dedupe_processed_record_id = in_processed_record_id;

	ELSIF (in_import_source_position < v_system_source_position OR v_fill_nulls_map_ids.count > 0) THEN

		UPDATE dedupe_processed_record
		   SET dedupe_action = chain_pkg.ACTION_UPDATE,
		  dedupe_action_type_id = in_dedupe_action_type_id,
		  matched_to_company_sid = in_company_sid
		 WHERE dedupe_processed_record_id = in_processed_record_id;

		MergeCompanyData(
			in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
			in_staging_tab_schema		=> in_staging_tab_schema,
			in_staging_tab_name			=> in_staging_tab_name,
			in_staging_id_col_name		=> in_staging_id_col_name,
			in_batch_num_column			=> in_staging_batch_num_col_name,
			in_source_lookup_column		=> in_staging_source_lookup_col,
			in_reference				=> in_reference,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_processed_record_id		=> in_processed_record_id,
			in_matched_company_sid		=> in_company_sid,
			in_company_row				=> in_company_row,
			in_import_source_position	=> in_import_source_position,
			in_fill_nulls_map_ids		=> v_fill_nulls_map_ids
		);
	ELSIF v_override_company_active = 1 THEN
		BEGIN
			ActivateOrDeactivate(
				in_active				=> in_company_row.active,
				in_activated_dtm		=> in_company_row.activated_dtm,
				in_deactivated_dtm		=> in_company_row.deactivated_dtm,
				out_action				=> v_action,
				out_action_dtm			=> v_action_dtm
			);
			IF v_action IS NULL OR v_action = chain_pkg.ACTIVE THEN
				GetOldCompanyRow(in_company_sid, v_old_company_row);
				
				company_pkg.ReActivateCompany(in_company_sid);
				company_pkg.ActivateRelationship(v_top_company_sid, in_company_sid);

				UPDATE company
				   SET activated_dtm = CASE WHEN v_action = chain_pkg.ACTIVE THEN NVL(v_action_dtm, activated_dtm) ELSE activated_dtm END
				 WHERE company_sid = in_company_sid;

				LogValueChange(
					in_dedupe_processed_record_id	=> in_processed_record_id,
					in_old_value					=> v_old_company_row.active,
					in_new_value					=> chain_pkg.ACTIVE,
					in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_ACTIVE
				);
				 
				LogValueChange(
					in_dedupe_processed_record_id	=> in_processed_record_id,
					in_old_value					=> v_old_company_row.activated_dtm,
					in_new_value					=> v_action_dtm,
					in_dedupe_field_id				=> chain_pkg.FLD_COMPANY_ACTIVATED_DTM
				);

				UPDATE dedupe_processed_record
				   SET data_merged = 1,
					   dedupe_action = chain_pkg.ACTION_UPDATE,
		  			   dedupe_action_type_id = in_dedupe_action_type_id,
		  			   matched_to_company_sid = in_company_sid
			 	 WHERE dedupe_processed_record_id = in_processed_record_id;
			END IF;
		EXCEPTION
			WHEN chain_pkg.DEDUPE_INVALID_COMP_DATA THEN
				LogError (
					in_dedupe_processed_record_id	=> in_processed_record_id,
					in_error_message				=> SUBSTR(SQLERRM, 12)
				);
		END;
	END IF;

	FOR r IN (
		SELECT dedupe_staging_link_id
		  FROM dedupe_staging_link
		 WHERE app_sid = security_pkg.getapp
		   AND parent_staging_link_id = in_dedupe_staging_link_id
		 ORDER BY position
	)
	LOOP
		ProcessChildStagingRecords(
			in_dedupe_staging_link_id	=> r.dedupe_staging_link_id,
			in_reference				=> in_reference,
			in_batch_num				=> in_batch_num,
			in_source_lookup			=> in_source_lookup,
			in_parent_proc_record_id	=> in_processed_record_id,
			out_processed_record_ids	=> v_child_proc_record_ids
		);

		IF v_child_proc_record_ids IS NOT NULL AND v_child_proc_record_ids.COUNT > 0 THEN
			FOR i IN v_child_proc_record_ids.FIRST .. v_child_proc_record_ids.LAST
			LOOP
				out_child_proc_record_ids(out_child_proc_record_ids.COUNT + 1) := v_child_proc_record_ids(i);
			END LOOP;
		END IF;
	END LOOP;
END;

PROCEDURE MergeRecord (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID
)
AS
	v_child_processed_record_ids			security_pkg.T_SID_IDS;
BEGIN
	MergeRecord(
		in_processed_record_id 			=> in_processed_record_id,
		in_company_sid 					=> in_company_sid,
		out_child_proc_record_ids 		=> v_child_processed_record_ids
	);
END;

PROCEDURE MergeRecord (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID,
	out_child_proc_record_ids		OUT security.security_pkg.T_SID_IDS
)
AS
	v_company_row					T_DEDUPE_COMPANY_ROW;
	v_dedupe_staging_link_id		dedupe_staging_link.dedupe_staging_link_id%TYPE;

	v_staging_tab_schema			cms.tab.oracle_schema%TYPE;
	v_staging_tab_name				cms.tab.oracle_table%TYPE;
	v_staging_id_col_name			cms.tab_column.oracle_column%TYPE;
	v_staging_batch_num_col_name	cms.tab_column.oracle_column%TYPE;
	v_staging_source_lookup_col		cms.tab_column.oracle_column%TYPE;
	v_staging_tab_sid				security_pkg.T_SID_ID;
	v_import_source_position		NUMBER(10);
	v_reference						dedupe_processed_record.reference%TYPE;
	v_batch_num						dedupe_processed_record.batch_num%TYPE;
	v_source_lookup					import_source.lookup_key%TYPE;
BEGIN

	SELECT t.oracle_schema, t.oracle_table, tc.oracle_column, tcb.oracle_column, t.tab_sid,
		s.position, dpr.reference, dpr.batch_num, dsl.dedupe_staging_link_id, tcs.oracle_column, s.lookup_key
	  INTO v_staging_tab_schema, v_staging_tab_name, v_staging_id_col_name, v_staging_batch_num_col_name, v_staging_tab_sid,
		v_import_source_position, v_reference, v_batch_num, v_dedupe_staging_link_id, v_staging_source_lookup_col, v_source_lookup
	  FROM dedupe_processed_record dpr
	  JOIN dedupe_staging_link dsl ON dpr.dedupe_staging_link_id = dsl.dedupe_staging_link_id
	  JOIN import_source s ON dsl.import_source_id = s.import_source_id
	  JOIN cms.tab t ON t.tab_sid = dsl.staging_tab_sid
	  JOIN cms.tab_column tc ON tc.column_sid = dsl.staging_id_col_sid
	  LEFT JOIN cms.tab_column tcb ON tcb.column_sid = dsl.staging_batch_num_col_sid
	  LEFT JOIN cms.tab_column tcs ON tcs.column_sid = dsl.staging_source_lookup_col_sid
	 WHERE dpr.dedupe_processed_record_id = in_processed_record_id;

	IF v_staging_source_lookup_col IS NULL THEN
		v_source_lookup := NULL;
	END IF;

	v_company_row := GetStagingCompanyRow(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id,
		in_staging_tab_schema		=> v_staging_tab_schema,
		in_staging_tab_name			=> v_staging_tab_name,
		in_staging_id_col_name		=> v_staging_id_col_name,
		in_batch_num_column			=> v_staging_batch_num_col_name,
		in_source_lookup_col		=> v_staging_source_lookup_col,
		in_reference				=> v_reference,
		in_batch_num				=> v_batch_num,
		in_source_lookup			=> v_source_lookup
	);

	MergeRecord(
		in_processed_record_id 			=> in_processed_record_id,
		in_company_sid 					=> in_company_sid,
		in_company_row					=> v_company_row,
		in_dedupe_staging_link_id		=> v_dedupe_staging_link_id,
		in_staging_tab_schema			=> v_staging_tab_schema,
		in_staging_tab_name				=> v_staging_tab_name,
		in_staging_id_col_name			=> v_staging_id_col_name,
		in_staging_batch_num_col_name	=> v_staging_batch_num_col_name,
		in_staging_source_lookup_col	=> v_staging_source_lookup_col,
		in_reference					=> v_reference,
		in_batch_num					=> v_batch_num,
		in_source_lookup				=> v_source_lookup,
		in_import_source_position		=> v_import_source_position,
		in_dedupe_action_type_id		=> chain_pkg.DEDUPE_MANUAL,
		out_child_proc_record_ids		=> out_child_proc_record_ids
	);
END;

PROCEDURE QueueDedupeBatchJob(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_batch_job_id				OUT	dedupe_batch_job.batch_job_id%TYPE
)
AS
BEGIN
	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id	=> csr.batch_job_pkg.JT_DEDUPE_PROCESS_RECORDS,
		out_batch_job_id		=> out_batch_job_id
	);

	INSERT INTO dedupe_batch_job (batch_job_id, import_source_id, batch_number, force_re_eval)
	VALUES (out_batch_job_id, in_import_source_id, in_batch_num, in_force_re_eval);
END;

PROCEDURE LockAndQueueDedupeBatchJob(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_batch_job_id				OUT	dedupe_batch_job.batch_job_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'LockAndQueueDedupeBatchJob can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;
	
	IF NOT TryLockImportSource(in_import_source_id) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_IMPORT_SOURCE_LOCKED, 'The import source resource with id:'||in_import_source_id||' is being locked');
	END IF;

	QueueDedupeBatchJob(
		in_import_source_id => in_import_source_id,
		in_batch_num		=> in_batch_num,
		in_force_re_eval	=> in_force_re_eval,
		out_batch_job_id	=> out_batch_job_id
	);
END;

PROCEDURE GetDedupeBatchJob(
	in_batch_job_id					IN csr.batch_job.batch_job_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT batch_job_id,import_source_id, batch_number, force_re_eval
		  FROM dedupe_batch_job
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND batch_job_id = in_batch_job_id;
END;

PROCEDURE GetStagingRecords(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dedupe_staging_link_id		dedupe_staging_link.dedupe_staging_link_id%TYPE;
	v_staging_tab_schema			cms.tab.oracle_schema%TYPE;
	v_staging_tab_name				cms.tab.oracle_table%TYPE;
	v_staging_id_col_name			cms.tab_column.oracle_column%TYPE;
	v_staging_batch_num_col_name	cms.tab_column.oracle_column%TYPE;
	v_staging_source_lookup_col		cms.tab_column.oracle_column%TYPE;
	v_source_lookup					import_source.lookup_key%TYPE;
	v_sql							VARCHAR2(4000);
BEGIN
	SELECT dsl.dedupe_staging_link_id, t.oracle_schema, t.oracle_table, tc.oracle_column,
		   tcb.oracle_column, CASE WHEN tcs.oracle_column IS NOT NULL THEN s.lookup_key ELSE NULL END, tcs.oracle_column
	  INTO v_dedupe_staging_link_id, v_staging_tab_schema, v_staging_tab_name, v_staging_id_col_name,
		   v_staging_batch_num_col_name, v_source_lookup, v_staging_source_lookup_col
	  FROM dedupe_staging_link dsl
	  JOIN import_source s ON dsl.import_source_id = s.import_source_id
	  JOIN cms.tab t ON t.tab_sid = dsl.staging_tab_sid
	  JOIN cms.tab_column tc ON tc.column_sid = dsl.staging_id_col_sid
	  LEFT JOIN cms.tab_column tcb ON tcb.column_sid = dsl.staging_batch_num_col_sid
	  LEFT JOIN cms.tab_column tcs ON tcs.column_sid = dsl.staging_source_lookup_col_sid
	 WHERE dsl.import_source_id = in_import_source_id
	   AND dsl.parent_staging_link_id IS NULL;

	v_sql := 'SELECT DISTINCT st."'|| v_staging_id_col_name || '" reference, ';

	IF v_staging_batch_num_col_name IS NULL THEN
		v_sql := v_sql || 'null batch_number ';
	ELSE
		v_sql := v_sql || 'st."'|| v_staging_batch_num_col_name || '" batch_number ';
	END IF;

	v_sql := v_sql || ' FROM "'|| v_staging_tab_schema || '"."' || v_staging_tab_name || '" st ' ||
					  ' LEFT JOIN chain.dedupe_processed_record dpr ON dpr.dedupe_staging_link_id =  :1 ' ||
					  '  AND dpr.reference = st."'|| v_staging_id_col_name || '"' ;

	IF v_staging_batch_num_col_name IS NOT NULL THEN
		v_sql := v_sql || ' AND dpr.batch_num = st."'|| v_staging_batch_num_col_name || '" ' ||
						  ' WHERE  st."'|| v_staging_batch_num_col_name || '" = :2 ';
	ELSE
		v_sql := v_sql || ' WHERE :2 IS NULL ';
	END IF;

	IF v_staging_source_lookup_col IS NOT NULL THEN
		v_sql := v_sql || ' AND st."'|| v_staging_source_lookup_col || '" = :3';
	ELSE
		v_sql := v_sql || ' AND :3 IS NULL';
	END IF;

	IF in_force_re_eval = 0 THEN
		v_sql := v_sql || ' AND dpr.dedupe_processed_record_id IS NULL';
	END IF;

	OPEN out_cur
	 FOR v_sql
   USING v_dedupe_staging_link_id, in_batch_num, v_source_lookup;
END;

PROCEDURE ProcessParentStagingRecord(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0
)
AS
	v_proc_record_ids			security_pkg.T_SID_IDS;
BEGIN
	ProcessParentStagingRecord(
		in_import_source_id			=> in_import_source_id,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num,
		in_force_re_eval			=> in_force_re_eval,
		out_processed_record_ids	=> v_proc_record_ids
	);
	commit;
END;

PROCEDURE ProcessParentStagingRecord(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_processed_record_ids		OUT security_pkg.T_SID_IDS
)
AS
	v_no_match_action				import_source.dedupe_no_match_action_id%TYPE;
	v_import_source_id				import_source.import_source_id%TYPE;
	v_processed_record_id			dedupe_processed_record.dedupe_processed_record_id%TYPE;
	v_dedupe_staging_link_id		dedupe_staging_link.dedupe_staging_link_id%TYPE;

	v_staging_tab_schema			cms.tab.oracle_schema%TYPE;
	v_staging_tab_name				cms.tab.oracle_table%TYPE;
	v_staging_id_col_name			cms.tab_column.oracle_column%TYPE;
	v_staging_batch_num_col_name	cms.tab_column.oracle_column%TYPE;
	v_staging_source_lookup_col		cms.tab_column.oracle_column%TYPE;
	v_staging_tab_sid				security_pkg.T_SID_ID;
	v_source_lookup					import_source.lookup_key%TYPE;

	v_matched_to_company_sid 		security_pkg.T_SID_ID;
	v_created_company_sid 			security_pkg.T_SID_ID;
	v_import_source_position		import_source.position%TYPE;
	v_system_source_position		import_source.position%TYPE;
	v_resulted_match_type_id		dedupe_rule_set.dedupe_match_type_id%TYPE;
	v_rule_set_id					dedupe_rule_set.dedupe_rule_set_id%TYPE;

	v_child_proc_record_ids			security_pkg.T_SID_IDS;
	v_matched_sid_ids				security_pkg.T_SID_IDS;
	v_company_row					T_DEDUPE_COMPANY_ROW;
	v_do_merge						BOOLEAN DEFAULT FALSE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR security.user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ProcessStagingRecord can be either run by BuiltIn Admin or CSR Super Admin');
	END IF;

	SELECT dsl.dedupe_staging_link_id, t.oracle_schema, t.oracle_table, tc.oracle_column, tcb.oracle_column, t.tab_sid,
		s.dedupe_no_match_action_id, s.position, s.lookup_key, tcs.oracle_column
	  INTO v_dedupe_staging_link_id, v_staging_tab_schema, v_staging_tab_name, v_staging_id_col_name,
		v_staging_batch_num_col_name, v_staging_tab_sid, v_no_match_action, v_import_source_position, v_source_lookup,
		v_staging_source_lookup_col
	  FROM dedupe_staging_link dsl
	  JOIN import_source s ON dsl.import_source_id = s.import_source_id
	  JOIN cms.tab t ON t.tab_sid = dsl.staging_tab_sid
	  JOIN cms.tab_column tc ON tc.column_sid = dsl.staging_id_col_sid
	  LEFT JOIN cms.tab_column tcb ON tcb.column_sid = dsl.staging_batch_num_col_sid
	  LEFT JOIN cms.tab_column tcs ON tcs.column_sid = dsl.staging_source_lookup_col_sid
	 WHERE dsl.import_source_id = in_import_source_id
	   AND dsl.parent_staging_link_id IS NULL;

	SELECT position
	  INTO v_system_source_position
	  FROM import_source
	 WHERE is_owned_by_system = 1;

	IF v_staging_source_lookup_col IS NULL THEN
		v_source_lookup := NULL;
	END IF;

	v_company_row := GetStagingCompanyRow(
		in_dedupe_staging_link_id	=> v_dedupe_staging_link_id,
		in_staging_tab_schema		=> v_staging_tab_schema,
		in_staging_tab_name			=> v_staging_tab_name,
		in_staging_id_col_name		=> v_staging_id_col_name,
		in_batch_num_column			=> v_staging_batch_num_col_name,
		in_source_lookup_col		=> v_staging_source_lookup_col,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num,
		in_source_lookup			=> v_source_lookup
	);

	--try to find matches only for parent staging data
	v_matched_sid_ids := FindMatches(
		in_dedupe_staging_link_id		=> v_dedupe_staging_link_id,
		in_staging_tab_schema			=> v_staging_tab_schema,
		in_staging_tab_name				=> v_staging_tab_name,
		in_staging_id_col_name			=> v_staging_id_col_name,
		in_staging_batch_num_col_name	=> v_staging_batch_num_col_name,
		in_staging_source_lookup_col	=> v_staging_source_lookup_col,
		in_reference					=> in_reference,
		in_batch_num					=> in_batch_num,
		in_source_lookup				=> v_source_lookup,
		in_force_re_eval				=> in_force_re_eval,
		in_company_row					=> v_company_row,
		out_rule_set_id					=> v_rule_set_id,
		out_resulted_match_type_id		=> v_resulted_match_type_id
	);

	StoreMatches(
		in_dedupe_staging_link_id		=> v_dedupe_staging_link_id,
		in_reference					=> in_reference,
		in_batch_num					=> in_batch_num,
		in_matched_sids 				=> v_matched_sid_ids,
		in_rule_set_used 				=> v_rule_set_id,
		in_resulted_match_type_id		=> v_resulted_match_type_id,
		out_dedupe_processed_record_id	=> v_processed_record_id
	);

	out_processed_record_ids(1) := v_processed_record_id;

	IF v_matched_sid_ids IS NULL OR v_matched_sid_ids.COUNT = 0 THEN
		--no matches
		IF v_no_match_action <> chain_pkg.AUTO_CREATE THEN
			UPDATE dedupe_processed_record
			   SET dedupe_action_type_id = chain_pkg.DEDUPE_MANUAL,
			   dedupe_action = DECODE(v_no_match_action, chain_pkg.IGNORE_RECORD, chain_pkg.ACTION_IGNORE, NULL)
			 WHERE dedupe_processed_record_id = v_processed_record_id;

			RETURN;
		END IF;
		v_do_merge := TRUE;
	ELSIF v_matched_sid_ids.COUNT = 1 AND v_resulted_match_type_id = chain_pkg.DEDUPE_AUTO THEN
		v_do_merge := TRUE;
		v_matched_to_company_sid := v_matched_sid_ids(1);
	END IF;

	IF v_do_merge THEN
		MergeRecord(
			in_processed_record_id 			=> v_processed_record_id,
			in_company_sid 					=> v_matched_to_company_sid,
			in_company_row					=> v_company_row,
			in_dedupe_staging_link_id		=> v_dedupe_staging_link_id,
			in_staging_tab_schema			=> v_staging_tab_schema,
			in_staging_tab_name				=> v_staging_tab_name,
			in_staging_id_col_name			=> v_staging_id_col_name,
			in_staging_batch_num_col_name	=> v_staging_batch_num_col_name,
			in_staging_source_lookup_col	=> v_staging_source_lookup_col,
			in_reference					=> in_reference,
			in_batch_num					=> in_batch_num,
			in_source_lookup				=> v_source_lookup,
			in_import_source_position		=> v_import_source_position,
			in_dedupe_action_type_id		=> chain_pkg.DEDUPE_AUTO,
			out_child_proc_record_ids 		=> v_child_proc_record_ids
		);
	END IF;

	IF v_child_proc_record_ids IS NOT NULL AND v_child_proc_record_ids.COUNT > 0 THEN
		FOR i IN v_child_proc_record_ids.FIRST .. v_child_proc_record_ids.LAST
		LOOP
			out_processed_record_ids(out_processed_record_ids.COUNT + 1) := v_child_proc_record_ids(i);
		END LOOP;
	END IF;
END;

FUNCTION CreateUserMergeJob
RETURN csr.batch_job.batch_job_id%TYPE
AS
	v_batch_job_id					csr.batch_job.batch_job_id%TYPE;
BEGIN
	IF NOT dedupe_admin_pkg.HasProcessedRecordAccess THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateUserMergeJob can only be run by a top company admin or Super Admin');
	END IF;

	--todo: maybe we can require the lock only for the import sources of records with user actions
	FOR r IN (
		SELECT import_source_id
		  FROM import_source
		 WHERE app_sid = security_pkg.Getapp
		   AND is_owned_by_system = 0
	)
	LOOP
		IF NOT TryLockImportSource(r.import_source_id) THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_IMPORT_SOURCE_LOCKED, 'The import source resource with id:'||r.import_source_id||' is being locked');
		END IF;
	END LOOP;

	csr.batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.JT_DEDUPE_MANUAL_MERGE,
		in_description => 'Dedupe manual merge',
		out_batch_job_id => v_batch_job_id);

	RETURN v_batch_job_id;
END;

-- This should be called directly after CreateUserMergeJob in the same transaction. Security
-- checks should be performed in that method.
PROCEDURE SetUserAction (
	in_batch_job_id					IN dedupe_processed_record.batch_job_id%TYPE,
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_dedupe_action				IN dedupe_processed_record.dedupe_action%TYPE,
	in_company_sid					IN security.security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE dedupe_processed_record
	   SET dedupe_action = in_dedupe_action,
	       matched_to_company_sid = in_company_sid,
		   batch_job_id = in_batch_job_id,
		   merge_status_id = chain_pkg.DEDUPE_MS_IN_PROGRESS
	 WHERE dedupe_processed_record_id = in_processed_record_id;
END;

-- Internal method - assume security checks are done by whatever calls this.
PROCEDURE LogMergeStatus (
	in_processed_record_id			IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_status						IN chain_pkg.T_DEDUPE_MERGE_STATUS,
	in_error_message				IN dedupe_processed_record.error_message%TYPE DEFAULT NULL,
	in_error_detail					IN dedupe_processed_record.error_detail%TYPE DEFAULT NULL
)
AS
BEGIN
	UPDATE dedupe_processed_record
	   SET merge_status_id = in_status,
	       error_message = in_error_message,
		   error_detail = in_error_detail
	 WHERE dedupe_processed_record_id = in_processed_record_id;
END;

PROCEDURE ProcessUserActions (
	in_batch_job_id					IN	csr.batch_job.batch_job_id%TYPE,
	out_result						OUT	csr.batch_job.result%TYPE,
	out_result_url					OUT	csr.batch_job.result_url%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_total_work					NUMBER(10);
	v_work_done						NUMBER(10) := 0;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ProcessUserActions can only be run by BuiltIn Admin');
	END IF;

	SELECT COUNT(*)
	  INTO v_total_work
	  FROM dedupe_processed_record dpr
	  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
	 WHERE batch_job_id = in_batch_job_id
	   AND (dpr.matched_to_company_sid IS NULL OR c.deleted = 0)
	   AND ((dpr.matched_to_company_sid IS NULL AND dedupe_action = chain_pkg.ACTION_CREATE)
		OR (c.company_sid IS NOT NULL AND dedupe_action = chain_pkg.ACTION_UPDATE));

	security_pkg.SetContext('CHAIN_SUP_ROLE_SYNC_BATCH_MODE', 'TRUE');

	FOR r IN (
		SELECT dpr.dedupe_processed_record_id, c.company_sid
		  FROM dedupe_processed_record dpr
		  LEFT JOIN company c ON c.company_sid = dpr.matched_to_company_sid
		 WHERE batch_job_id = in_batch_job_id
		   AND (dpr.matched_to_company_sid IS NULL OR c.deleted = 0)
		   AND ((dpr.matched_to_company_sid IS NULL AND dedupe_action = chain_pkg.ACTION_CREATE)
		    OR (c.company_sid IS NOT NULL AND dedupe_action = chain_pkg.ACTION_UPDATE))
	)
	LOOP
		BEGIN
			MergeRecord(
				in_processed_record_id => r.dedupe_processed_record_id,
				in_company_sid => r.company_sid
			);

			LogMergeStatus(r.dedupe_processed_record_id, chain_pkg.DEDUPE_MS_SUCCESS);
			v_work_done := v_work_done + 1;
			csr.batch_job_pkg.SetProgress(
				in_batch_job_id => in_batch_job_id,
				in_work_done => v_work_done,
				in_total_work => v_total_work
			);

			COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				ROLLBACK;

				LogMergeStatus(r.dedupe_processed_record_id, chain_pkg.DEDUPE_MS_FAIL, 'An unexpected error occurred',
					SUBSTR(SQLERRM, 1, 255) || dbms_utility.format_error_backtrace());
				IF out_result IS NULL THEN
					out_result := 'Merge completed with errors';
				END IF;
				COMMIT;
		END;
	END LOOP;

	security_pkg.SetContext('CHAIN_SUP_ROLE_SYNC_BATCH_MODE', 'FALSE');
	csr.supplier_pkg.SyncCompanyTypeRoles(NULL);
	ReleaseImportSourceLock;
	COMMIT;

	IF out_result IS NULL THEN
		out_result := 'Merge completed successfully';
	END IF;

	out_result_url := '/csr/site/chain/dedupe/processedRecords.acds';
END;

/* Used for tests only */
FUNCTION TestFindMatchesForRuleSet(
	in_rule_set_id					IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.ORACLE_SCHEMA%TYPE,
	in_staging_tab_name				IN cms.tab.ORACLE_TABLE%TYPE,
	in_staging_id_col_name			IN cms.tab_column.ORACLE_COLUMN%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.ORACLE_COLUMN%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN VARCHAR2 DEFAULT NULL
)RETURN security.T_SID_TABLE
AS
	v_company_row		T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW;
	v_map_ref_vals		security.T_VARCHAR2_TABLE;
	v_map_tag_vals		T_NUMERIC_TABLE;
BEGIN
	v_company_row := GetStagingCompanyRow(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_staging_batch_num_col_name,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num
	);

	GetRefsAndTagsFromStaging(
		in_dedupe_staging_link_id		=>	in_dedupe_staging_link_id,
		in_staging_tab_schema			=>	in_staging_tab_schema,
		in_staging_tab_name				=>	in_staging_tab_name,
		in_staging_id_col_name			=>	in_staging_id_col_name,
		in_staging_batch_num_col_name	=>	in_staging_batch_num_col_name,
		in_staging_source_lookup_col	=>	NULL,
		in_reference					=>	in_reference,
		in_batch_num					=>	in_batch_num,
		in_source_lookup				=>	NULL,
		out_map_ref_vals				=>	v_map_ref_vals,
		out_map_tag_vals				=>	v_map_tag_vals
	);

	RETURN FindMatchesForRuleSet(
		in_rule_set_id					=> in_rule_set_id,
		in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
		in_company_row					=> v_company_row,
		in_map_ref_vals					=> v_map_ref_vals,
		in_map_tag_vals					=> v_map_tag_vals
	);
END;

/* Used for tests only */
FUNCTION FindAndStoreMatches(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_staging_tab_schema			IN cms.tab.oracle_schema%TYPE,
	in_staging_tab_name				IN cms.tab.oracle_table%TYPE,
	in_staging_id_col_name			IN cms.tab_column.oracle_column%TYPE,
	in_staging_batch_num_col_name	IN cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_reference					IN VARCHAR2,
	in_batch_num					IN NUMBER DEFAULT NULL,
	in_force_re_eval				IN NUMBER DEFAULT 0,
	out_rule_set_id					OUT dedupe_rule_set.dedupe_rule_set_id%TYPE,
	out_resulted_match_type_id		OUT dedupe_rule_set.dedupe_match_type_id%TYPE,
	out_processed_record_id			OUT dedupe_processed_record.dedupe_processed_record_id%TYPE
)RETURN security_pkg.T_SID_IDS
AS
	v_company_row					T_DEDUPE_COMPANY_ROW DEFAULT T_DEDUPE_COMPANY_ROW;
	v_matched_sids					security_pkg.T_SID_IDS;
BEGIN
	v_company_row := GetStagingCompanyRow(
		in_dedupe_staging_link_id	=> in_dedupe_staging_link_id,
		in_staging_tab_schema		=> in_staging_tab_schema,
		in_staging_tab_name			=> in_staging_tab_name,
		in_staging_id_col_name		=> in_staging_id_col_name,
		in_batch_num_column			=> in_staging_batch_num_col_name,
		in_reference				=> in_reference,
		in_batch_num				=> in_batch_num
	);

	v_matched_sids := FindMatches(
		in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
		in_staging_tab_schema			=> in_staging_tab_schema,
		in_staging_tab_name				=> in_staging_tab_name,
		in_staging_id_col_name			=> in_staging_id_col_name,
		in_staging_batch_num_col_name	=> in_staging_batch_num_col_name,
		in_reference					=> in_reference,
		in_batch_num					=> in_batch_num,
		in_force_re_eval				=> in_force_re_eval,
		in_company_row					=> v_company_row,
		out_rule_set_id					=> out_rule_set_id,
		out_resulted_match_type_id		=> out_resulted_match_type_id
	);

	StoreMatches(
		in_dedupe_staging_link_id		=> in_dedupe_staging_link_id,
		in_reference					=> in_reference,
		in_batch_num					=> in_batch_num,
		in_matched_sids 				=> v_matched_sids,
		in_rule_set_used 				=> out_rule_set_id,
		in_resulted_match_type_id		=> out_resulted_match_type_id,
		out_dedupe_processed_record_id	=> out_processed_record_id
	);

	RETURN v_matched_sids;
END;

FUNCTION GetWebsiteDomainName(
	in_website				IN company.website%TYPE
)RETURN company.website%TYPE
DETERMINISTIC AS
	v_website company.website%TYPE;
BEGIN
	/*
	This isn't a perfect reg-exp but it deals with the common formats below and is superior to the very restricted "com" and "co.uk" only support that was there
		google.com
		www.google.com
		www.google.co.in
		www22.google.co.in
		www.shopping.google.co.in ->Comes back as shopping.google - ok for dedupe. 
									Could deal with, with 2nd regexp_replace but prob not worth performance as this is called lots. 
									I think could be done with a "not" part to reg-exp but this was discussed as "sufficient" without fiddling longer
	*/
	SELECT REGEXP_REPLACE(LOWER(TRIM(in_website)),'^[a-z]+://www[0-9]*[\\.]|^www[0-9]*[\\.]|^[a-z0-9]+://|[\\.]co[\\.][a-z0-9]+$|[\\.][a-z0-9]+$','') 
		INTO v_website
		FROM dual;

	RETURN v_website;
END;

FUNCTION TryLockImportSource(
	in_import_source_id		IN import_source.import_source_id%TYPE
) RETURN BOOLEAN
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	UPDATE import_source_lock
	   SET is_locked = 1
	 WHERE app_sid = security_pkg.getApp 
	   AND import_source_id = in_import_source_id
	   AND is_locked = 0;
	
	IF SQL%ROWCOUNT = 0 THEN
		commit;
		RETURN FALSE;
	END IF;

	commit;
	RETURN TRUE;
END;

PROCEDURE ReleaseImportSourceLock(
	in_import_source_id		IN import_source.import_source_id%TYPE DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;	
BEGIN
	UPDATE import_source_lock
	   SET is_locked = 0
	 WHERE app_sid = security_pkg.getApp 
	   AND (in_import_source_id IS NULL OR import_source_id = in_import_source_id);
	
	commit;
END;

END company_dedupe_pkg;
/