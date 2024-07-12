-- Please update version.sql too -- this keeps clean builds in sync
define version=521
@update_header

-- check for right version of cms
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM cms.version;
	IF v_version < 55 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***CMS*** DATABASE OF VERSION '||v_version||' (cvs\aspen2\cms\db\changes) =======');
	END IF;
END;
/


connect cms/cms@&_CONNECT_IDENTIFIER;
grant execute on cms_tab_pkg to csr;
grant execute on web_publication_pkg to csr;
grant select,references on web_publication to csr;

connect csr/csr@&_CONNECT_IDENTIFIER;


ALTER TABLE axis ADD (
	CMS_OWNER	VARCHAR2(30)
);

-- it's just frontenac ATM
UPDATE axis SET cms_owner = 'FRONTENAC'; 

ALTER TABLE axis MODIFY CMS_OWNER NOT NULL;


@..\strategy_pkg
@..\strategy_body

@update_tail


