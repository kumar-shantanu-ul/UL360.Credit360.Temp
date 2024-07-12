PROMPT - this lives out of version flow as it needs to be applied but a raft of other changes are prepared to go 
PROMPT affects nothing but report - exclude members of FSC


CREATE TABLE FSC_MEMBER(
    COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK280 PRIMARY KEY (COMPANY_SID)
)
;

ALTER TABLE FSC_MEMBER ADD CONSTRAINT RefALL_COMPANY431 
    FOREIGN KEY (COMPANY_SID)
    REFERENCES ALL_COMPANY(COMPANY_SID)
;

-- kimberly clarke europe and limited
INSERT INTO FSC_MEMBER 
	SELECT company_sid FROM all_company WHERE lower(name) like '%kimberly-clark%';