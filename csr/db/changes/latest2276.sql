-- Please update version.sql too -- this keeps clean builds in sync
define version=2276
@update_header

ALTER TABLE CSR.FEED_REQUEST ADD (
	FILE_DATA BLOB, 
	FILE_TYPE VARCHAR2(10),
	SUMMARY_XML CLOB,
	ERROR_DATA BLOB
);

ALTER TABLE CSR.FEED ADD (
	HELPER_PKG VARCHAR2(100)
);

-- Converting all the xml_data clob to file_data blob column
DECLARE
	l_blob          BLOB;
	l_dest_offset   INTEGER := 1;
	l_source_offset INTEGER := 1;
	l_lang_context  INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
	l_warning       INTEGER := DBMS_LOB.WARN_INCONVERTIBLE_CHAR;
BEGIN
  UPDATE csr.feed_request 
     SET file_type = 'xml';

  FOR x IN (
	SELECT feed_request_id, xml_data 
	  FROM csr.feed_request 
	 WHERE LOWER(file_type) = 'xml' AND xml_data IS NOT NULL)
  LOOP
    DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
    DBMS_LOB.CONVERTTOBLOB (
      dest_lob    => l_blob,
      src_clob    => x.xml_data,
      amount      => DBMS_LOB.LOBMAXSIZE,
      dest_offset => l_dest_offset,
      src_offset  => l_source_offset,
      blob_csid   => DBMS_LOB.DEFAULT_CSID,
      lang_context=> l_lang_context,
      warning     => l_warning
    );
    UPDATE csr.FEED_REQUEST
       SET FILE_DATA = l_blob
     WHERE feed_request_id = x.feed_request_id;
  END LOOP;
END;
/

@../feed_pkg
@../feed_body

@update_tail
