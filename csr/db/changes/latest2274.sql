-- Please update version.sql too -- this keeps clean builds in sync
define version=2274
@update_header

--Adding PUBLIC_BY_DEFAULT not null column in few steps
ALTER TABLE CSR.ISSUE_TYPE ADD (
	PUBLIC_BY_DEFAULT		NUMBER(1,0),
	CONSTRAINT CHK_PUBLIC_BY_DEFAULT CHECK (NOT(PUBLIC_BY_DEFAULT = 1 AND CAN_BE_PUBLIC = 0))
);

exec SECURITY.USER_PKG.logonadmin('');

UPDATE CSR.ISSUE_TYPE
   SET PUBLIC_BY_DEFAULT = 0;

COMMIT;

ALTER TABLE CSR.ISSUE_TYPE
     MODIFY PUBLIC_BY_DEFAULT NUMBER(1,0)  DEFAULT 0  NOT NULL;

@@..\issue_pkg  
@@..\issue_body

@update_tail

