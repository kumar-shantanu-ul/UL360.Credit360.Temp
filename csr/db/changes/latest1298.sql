-- Please update version.sql too -- this keeps clean builds in sync
define version=1298
@update_header

ALTER TABLE csr.delegation_ind
DROP CONSTRAINT CK_META_ROLE;

ALTER TABLE csr.delegation_ind
ADD CONSTRAINT CK_META_ROLE
CHECK (META_ROLE IN(
'MERGED','MERGED_ON_TIME', 'DP_COMPLETE', 'TOTAL_DP', 'IND_SEL_COUNT', 'IND_SEL_TOTAL')) ENABLE;


CREATE TABLE CSR.DELEG_META_ROLE_IND_SELECTION (
  APP_SID         NUMBER(10) NOT NULL,
  DELEGATION_SID  NUMBER(10) NOT NULL,
  IND_SID         NUMBER(10) NOT NULL,
  LANG            VARCHAR2(10) NOT NULL,
  DESCRIPTION     VARCHAR2(500) NOT NULL
);

ALTER TABLE csr.deleg_meta_role_ind_selection
ADD CONSTRAINT PK_DELEG_META_ROLE_IND_SEL PRIMARY KEY (app_sid, delegation_sid, ind_sid);

ALTER TABLE csr.deleg_meta_role_ind_selection
ADD CONSTRAINT FK_DELEG_META_ROLE_IND_ASPN2TS
FOREIGN KEY (app_sid, lang)
REFERENCES aspen2.translation_set;

ALTER TABLE csr.deleg_meta_role_ind_selection
ADD CONSTRAINT FK_DELEG_META_ROLE_IND_DELG
FOREIGN KEY (app_sid, delegation_sid)
REFERENCES csr.delegation;

ALTER TABLE csr.deleg_meta_role_ind_selection
ADD CONSTRAINT FK_DELEG_META_ROLE_IND_IND
FOREIGN KEY (app_sid, ind_sid)
REFERENCES csr.ind;

@..\sheet_body

@update_tail

