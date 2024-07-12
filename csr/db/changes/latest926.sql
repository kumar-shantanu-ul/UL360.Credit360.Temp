-- Please update version.sql too -- this keeps clean builds in sync
define version=926
@update_header
-- 
-- TABLE: CSR.IMG_CHART 
--

CREATE TABLE CSR.IMG_CHART(
    APP_SID              NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    IMG_CHART_SID        NUMBER(10, 0)     NOT NULL,
    PARENT_SID           NUMBER(10, 0)     NOT NULL,
    LABEL                VARCHAR2(1023)    NOT NULL,
    MIME_TYPE            VARCHAR2(255)     NOT NULL,
    DATA                 BLOB              NOT NULL,
    SHA1                 RAW(20)           NOT NULL,
    LAST_MODIFIED_DTM    DATE              DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_IMG_CHART PRIMARY KEY (APP_SID, IMG_CHART_SID)
);



-- 
-- TABLE: CSR.IMG_CHART_IND 
--

CREATE TABLE CSR.IMG_CHART_IND(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    IMG_CHART_SID            NUMBER(10, 0)     NOT NULL,
    IND_SID                  NUMBER(10, 0)     NOT NULL,
    DESCRIPTION              VARCHAR2(1023),
    MEASURE_CONVERSION_ID    NUMBER(10, 0),
    X                        NUMBER(10, 0)     NOT NULL,
    Y                        NUMBER(10, 0)     NOT NULL,
    BACKGROUND_COLOR         NUMBER(10, 0)     NOT NULL,
    BORDER_COLOR             NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_IMG_CHART_IND PRIMARY KEY (APP_SID, IMG_CHART_SID, IND_SID)
);

 
-- TABLE: CSR.IMG_CHART 
--

ALTER TABLE CSR.IMG_CHART ADD CONSTRAINT FK_CUSTOMER_IMG_CHART 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID);


-- 
-- TABLE: CSR.IMG_CHART_IND 
--

ALTER TABLE CSR.IMG_CHART_IND ADD CONSTRAINT FK_IMG_CHART_IMG_CH_SID 
    FOREIGN KEY (APP_SID, IMG_CHART_SID)
    REFERENCES CSR.IMG_CHART(APP_SID, IMG_CHART_SID);

ALTER TABLE CSR.IMG_CHART_IND ADD CONSTRAINT FK_IND_IMG_CHART_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID);

ALTER TABLE CSR.IMG_CHART_IND ADD CONSTRAINT FK_MEAS_CONV_IMG_CHART_IND 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID);


@../img_chart_pkg
@../img_chart_body

GRANT EXECUTE ON csr.img_chart_pkg to security;
GRANT EXECUTE ON csr.img_chart_pkg to web_user;

-- CSRImgChart class
DECLARE
	v_act_id	security.security_pkg.T_ACT_ID;
	v_class_id	security.security_pkg.T_CLASS_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	security.class_pkg.CreateClass(v_act_id, security.class_pkg.GetClassId('Container'), 'CSRImgChart', 'csr.img_chart_pkg', null, v_class_id);
	COMMIT;
END;
/




@update_tail
