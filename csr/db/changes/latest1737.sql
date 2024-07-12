-- Please update version too -- this keeps clean builds in sync
define version=1737
@update_header

CREATE GLOBAL TEMPORARY TABLE csr.tmp_deleg_search (
	app_sid             NUMBER(10) NOT NULL,
	delegation_sid      NUMBER(10) NOT NULL,
	name                VARCHAR2(1023) NOT NULL,
	start_dtm           DATE NOT NULL,
	end_dtm             DATE NOT NULL,
	interval            VARCHAR2(32) NOT NULL,
	editing_url         VARCHAR2(255) NOT NULL,
	root_delegation_sid NUMBER(10) NOT NULL,
	lvl                 NUMBER(10) NOT NULL,
	max_lvl             NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;

grant select, insert, update, delete on csr.tmp_deleg_search to web_user;

@../delegation_body

@update_tail