-- Please update version.sql too -- this keeps clean builds in sync
define version=2108
@update_header

grant create table to csr;

BEGIN
	--ctx_ddl.drop_preference('CSR.STEM_FUZZY_PREF');
	ctx_ddl.create_preference('CSR.STEM_FUZZY_PREF', 'BASIC_WORDLIST');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_MATCH','ENGLISH');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_SCORE','1');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','FUZZY_NUMRESULTS','5000');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','SUBSTRING_INDEX','TRUE');
	ctx_ddl.set_attribute('CSR.STEM_FUZZY_PREF','STEMMER','AUTO');
END;
/

DROP INDEX csr.ix_section_title_search;

CREATE INDEX csr.ix_section_title_search ON csr.section_version(title)
indextype is ctxsys.context parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist Wordlist CSR.STEM_FUZZY_PREF');

DROP INDEX csr.ix_section_body_search;

CREATE INDEX csr.ix_section_body_search ON csr.section_version(body)
indextype is ctxsys.context parameters ('filter CTXSYS.NULL_FILTER section group ctxsys.html_section_group stoplist ctxsys.empty_stoplist Wordlist CSR.STEM_FUZZY_PREF');

revoke create table from csr;

@update_tail