CREATE OR REPLACE PACKAGE BODY csr.doc_helper_pkg AS

-------------------------------------------------
-- Delete procedures for all the modules:
-------------------------------------------------

-- Corporate reporter
PROCEDURE InternalDeleteFromSections(
	in_doc_id	IN	doc.doc_id%TYPE
) AS
BEGIN
	DELETE FROM attachment_history
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND attachment_id in (SELECT attachment_id FROM attachment where doc_id = in_doc_id);

	DELETE FROM attachment
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;
	  
	DELETE FROM section_content_doc_wait
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;

	DELETE FROM section_content_doc
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;
END;

-- Terms and Conditions
PROCEDURE InternalDeleteFromTermsCond(
	in_doc_id	IN	doc.doc_id%TYPE
) AS
BEGIN
	DELETE FROM term_cond_doc
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;

	DELETE FROM term_cond_doc_log
	 WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;
END;

-- Region event and documents
PROCEDURE InternalDeleteFromEventsDocs(
	in_doc_id	IN	doc.doc_id%TYPE
) AS
BEGIN
	DELETE FROM region_proc_doc
	  WHERE app_sid = SECURITY.SECURITY_PKG.GetApp AND doc_id = in_doc_id;
END;

-------------------------------------------------
-- Get references procedures for all the modules:
-------------------------------------------------

-- Corporate reporter
PROCEDURE InternalGetRefsFromSections(
	in_doc_id	IN	doc.doc_id%TYPE
)
AS
BEGIN
	INSERT INTO TEMP_DOC_REFERENCE (MODULE, DESCRIPTION, URL)
	SELECT
		'Corporate Reporter', 
		section_pkg.GetModuleName(s.section_sid)||' / ' || section_pkg.GetPathFROMSectionSID(NULL, s.section_sid, ' / ', 1) || ' / ' || sv.title, 
		'/csr/site/text/overview/filter.acds?sectionSid=' || to_char(s.section_sid)
	  FROM section s
	  JOIN section_version sv ON s.section_sid = sv.section_sid and s.VISIBLE_VERSION_NUMBER = sv.VERSION_NUMBER
      LEFT JOIN SECTION_CONTENT_DOC scd 
		ON scd.section_sid = s.section_sid and scd.doc_id = in_doc_id
	  LEFT JOIN 
	(
		attachment_history ah 
		  JOIN attachment a 
			ON ah.attachment_id = a.attachment_id and a.doc_id = in_doc_id
	)  ON s.section_sid = ah.section_sid
  WHERE scd.doc_id is not null or a.doc_id is not null;
END;

-- Terms and Conditions
PROCEDURE InternalGetRefsFromTermsCond(
	in_doc_id	IN	doc.doc_id%TYPE
)
AS
BEGIN
	INSERT INTO TEMP_DOC_REFERENCE (MODULE, DESCRIPTION, URL)
	SELECT 
		'Terms and Conditions', 
		ct.SINGULAR,
		'/csr/site/profile/Terms.acds'
	  FROM TERM_COND_DOC  tcd
	  JOIN CHAIN.Company_type ct 
		ON ct.company_type_id = tcd.company_type_id
WHERE doc_id = in_doc_id;

END;

-- Region event and documents
PROCEDURE InternalGetRefsFromEventsDocs(
	in_doc_id	IN		doc.doc_id%TYPE
)
AS
BEGIN
	INSERT INTO TEMP_DOC_REFERENCE (MODULE, DESCRIPTION, URL)
	SELECT 
		'Events and Documents',
		LTRIM(region_pkg.GetFlattenedRegionPath(security.security_pkg.getAct, rpd.REGION_SID), '/'),
		'/csr/site/schema/nonAdmin/regionEventsAndDocs.acds'
	  FROM region_proc_doc rpd 
	  JOIN region r 
		ON r.REGION_SID = rpd.REGION_SID 
	 WHERE rpd.doc_id = in_doc_id AND inherited = 0;
END;

-------------------------------------------------
-- General procedures using the modules procedures:
-------------------------------------------------

PROCEDURE DeleteDocReferences(
	in_doc_id	IN	doc.doc_id%TYPE
) AS
BEGIN
	InternalDeleteFromSections(in_doc_id);
	InternalDeleteFromTermsCond(in_doc_id);
	InternalDeleteFromEventsDocs(in_doc_id);
END;

PROCEDURE GetDocReferences(
	in_doc_id	IN	doc.doc_id%TYPE,
	out_cur		OUT	SYS_REFCURSOR
) AS
BEGIN
	doc_pkg.CheckDocReadPermissions(in_doc_id);
-- references FROM Sections (corp rep)
	InternalGetRefsFromSections(in_doc_id);
-- references FROM Terms and Conditions
	InternalGetRefsFromTermsCond(in_doc_id);
-- references FROM Documents for regions
	InternalGetRefsFromEventsDocs(in_doc_id);
	OPEN out_cur FOR
		SELECT module, description, url
		  FROM TEMP_DOC_REFERENCE;
END;

END;
/
