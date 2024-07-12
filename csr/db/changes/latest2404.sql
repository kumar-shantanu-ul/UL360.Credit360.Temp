-- Please update version.sql too -- this keeps clean builds in sync
define version=2404
@update_header

--Created from latest 2108; Dropping the index so the column can be modified. Then re-add it

grant create table to csr;

DROP INDEX csr.ix_section_title_search;

ALTER TABLE csr.SECTION_VERSION  
	MODIFY (TITLE VARCHAR2(2047 BYTE) );

CREATE INDEX csr.ix_section_title_search ON csr.section_version(title)
indextype is ctxsys.context parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist Wordlist CSR.STEM_FUZZY_PREF');

revoke create table from csr;

@update_tail