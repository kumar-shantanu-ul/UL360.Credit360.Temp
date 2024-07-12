define version=1986
@update_header

ALTER TABLE cms.tab_column ADD (
    DEFAULT_LENGTH NUMBER(10),
    DATA_DEFAULT VARCHAR2(255)
);

DECLARE
	v_data_default		VARCHAR2(255);
BEGIN
	-- Have to do a FOR loop as pl/sql can handle longs better than sql
	FOR r IN (
		SELECT tc.app_sid, tc.column_sid, atc.data_type, atc.data_length, atc.data_precision, atc.data_scale, atc.nullable, atc.char_length, atc.default_length, atc.data_default
		  FROM cms.tab t 
		  JOIN cms.tab_column tc ON t.tab_sid = tc.tab_sid AND t.app_sid = tc.app_sid
		  JOIN all_tab_columns atc
			ON t.oracle_schema = atc.owner AND tc.oracle_column = atc.column_name
		   AND ((t.managed = 0 AND t.oracle_table = atc.table_name) OR (t.managed = 1 AND 'C$' || t.oracle_table = atc.table_name))
	) LOOP
		
		-- data_default is a long which is massively restrictive
		v_data_default := substr(r.data_default, 1, 255);
		
		UPDATE cms.tab_column utc
		   SET data_type = r.data_type,
			   data_length = r.data_length,
			   data_precision = r.data_precision,
			   data_scale = r.data_scale,
			   nullable = r.nullable,
			   char_length = r.char_length,
			   default_length = r.default_length,
			   data_default = v_data_default
		 WHERE app_sid = r.app_sid
		   AND column_sid = r.column_sid;
		
	END LOOP;
END;
/

ALTER TABLE cms.tab_column MODIFY data_type NOT NULL;

ALTER TABLE csrimp.cms_tab_column ADD (
    DEFAULT_LENGTH NUMBER(10),
    DATA_DEFAULT VARCHAR2(255)
);

@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
