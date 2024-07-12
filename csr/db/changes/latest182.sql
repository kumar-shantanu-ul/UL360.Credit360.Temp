-- Please update version.sql too -- this keeps clean builds in sync
define version=182
@update_header


PROMPT Enter connect (e.g. aspen)
connect security/security@&&1
@c:\cvs\security\db\oracle\act_pkg
@c:\cvs\security\db\oracle\act_body
grant execute on security.act_pkg to csr;

connect csr/csr@&&1

-- 
-- TABLE: TAB_GROUP 
--

CREATE TABLE TAB_GROUP(
    TAB_ID       NUMBER(10, 0)    NOT NULL,
    GROUP_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK455 PRIMARY KEY (TAB_ID, GROUP_SID)
)
;



-- 
-- TABLE: TAB_GROUP 
--

ALTER TABLE TAB_GROUP ADD CONSTRAINT RefTAB891 
    FOREIGN KEY (TAB_ID)
    REFERENCES TAB(TAB_ID)
;



@..\portlet_pkg
@..\portlet_body
	 
@update_tail
