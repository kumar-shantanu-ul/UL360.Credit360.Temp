-- Please update version.sql too -- this keeps clean builds in sync
define version=570
@update_header

ALTER TABLE SUPPLIER ADD (
    LOGO_FILE_SID NUMBER(10)
);

-- FK constraint can't include APP_SID or the DELETE operation
-- will try and set the APP_SID column to null, so uses a new
-- unique constraint on FILE_UPLOAD
ALTER TABLE FILE_UPLOAD ADD CONSTRAINT UK_FILE_UPLOAD UNIQUE (FILE_UPLOAD_SID);

ALTER TABLE SUPPLIER ADD CONSTRAINT FK_SUPPLIER_LOGO_FILE
    FOREIGN KEY (LOGO_FILE_SID)
    REFERENCES FILE_UPLOAD(FILE_UPLOAD_SID) ON DELETE SET NULL
;

ALTER TABLE FILE_UPLOAD ADD LAST_MODIFIED_DTM DATE DEFAULT SYSDATE;


INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Member company logo', 'Credit360.Portlets.CompanyLogo', '/csr/site/portal/Portlets/CompanyLogo.js');

ALTER TABLE DELEGATION_IND ADD (
    VISIBILITY            VARCHAR2(32)      DEFAULT 'SHOW' NOT NULL,
    CSS_CLASS             VARCHAR2(64),
    CONSTRAINT CK_DELEG_IND_VISIBLE CHECK (VISIBILITY IN ('SHOW','READONLY'))
);

@@..\delegation_pkg
@@..\fileupload_pkg
@@..\indicator_pkg

@@..\delegation_body
@@..\fileupload_body
@@..\indicator_body
@@..\sheet_body
--chain\chain_link_body.sql

-- fix tolerances
begin
	-- disable tolerances where upper and lower are the same, unless
	-- there's some rows in the ind_window table which would imply
	-- they were turned on deliberately (i.e. any change => breach)
	update ind
	   set tolerance_type = 0
	 where ind_sid in (
		select i.ind_sid
		  from ind i    
			left join ind_window iw on i.ind_sid = iw.ind_sid
		 where pct_upper_tolerance = 1
		   and pct_lower_tolerance = 1
		   and tolerance_type != 0
		   and iw.ind_sid is null
	  );

	-- turn on this period previous year where we've got a < -1 comparison offset
	update ind
	   set tolerance_type = 2
	 where ind_sid in (
		select i.ind_sid
		  from ind i    
			join ind_window iw on i.ind_sid = iw.ind_sid
		 where pct_upper_tolerance != pct_lower_tolerance
		   and tolerance_type != 2
		   and iw.comparison_offset < - 1
	  );
	  
	-- all the rest are type 1
	update ind
	   set tolerance_type = 1
	 where ind_sid in (
		select i.ind_sid
		  from ind i    
			join ind_window iw on i.ind_sid = iw.ind_sid
		 where pct_upper_tolerance != pct_lower_tolerance
		   and tolerance_type != 1
		   and iw.comparison_offset = - 1
	  );
end;
/


-- TABLE: TAB_PORTLET_USER_STATE 
--

CREATE TABLE TAB_PORTLET_USER_STATE(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAB_PORTLET_ID    NUMBER(10, 0)    NOT NULL,
    STATE             CLOB,
    CSR_USER_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TAB_PORTLET_USER_STATE PRIMARY KEY (APP_SID, TAB_PORTLET_ID, CSR_USER_SID)
)
;



-- 
-- TABLE: TAB_PORTLET_USER_STATE 
--

ALTER TABLE TAB_PORTLET_USER_STATE ADD CONSTRAINT FK_TAB_PRT_TAB_PRT_USR_STATE 
    FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
    REFERENCES TAB_PORTLET(APP_SID, TAB_PORTLET_ID)
;

ALTER TABLE TAB_PORTLET_USER_STATE ADD CONSTRAINT FK_USER_TAB_PORT_USR_STATE 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;


@@..\portlet_body

@update_tail
