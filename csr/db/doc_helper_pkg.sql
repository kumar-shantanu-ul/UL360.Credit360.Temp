CREATE OR REPLACE PACKAGE CSR.doc_helper_pkg 
AS

PROCEDURE DeleteDocReferences(
	in_doc_id	IN	doc.doc_id%TYPE
);

PROCEDURE GetDocReferences(
	in_doc_id	IN	doc.doc_id%TYPE,
	out_cur		OUT	SYS_REFCURSOR
);

END;
/