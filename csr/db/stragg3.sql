CREATE OR REPLACE TYPE csr.stragg3_type AS OBJECT
(

m_string	VARCHAR2(4000),
m_clob		CLOB,
m_first 	NUMBER(1),
m_sep 		VARCHAR2(1),

STATIC FUNCTION ODCIAggregateInitialize
(
	sctx							IN OUT stragg3_type
)
RETURN NUMBER,

MEMBER FUNCTION ODCIAggregateIterate
(
	self						IN OUT stragg3_type,
	value						IN VARCHAR2
)
RETURN NUMBER,

MEMBER FUNCTION ODCIAggregateTerminate
(
	self        				IN stragg3_type,
	returnvalue					OUT CLOB,
	flags						IN NUMBER
)
RETURN NUMBER,

MEMBER FUNCTION ODCIAggregateMerge
(
	self 						IN OUT NOCOPY stragg3_type,
	ctx2 						IN stragg3_type
)
RETURN NUMBER

);
/

CREATE OR REPLACE TYPE BODY csr.stragg3_type
IS

STATIC FUNCTION ODCIAggregateInitialize
(
	sctx							IN OUT stragg3_type
)
RETURN NUMBER
IS
BEGIN  
	-- check if there's any separator set, otherwise use default ',' 
    sctx := stragg3_type( null, null, 1, NVL(SYS_CONTEXT('SECURITY', 'STRAGG2_SEP'), ',') ) ;
    RETURN ODCIConst.Success;
END;

MEMBER FUNCTION ODCIAggregateIterate
(
	self						IN OUT stragg3_type,
	value						IN VARCHAR2
)
RETURN NUMBER
IS
	v_len 							NUMBER;
BEGIN
	IF self.m_clob IS NULL THEN
		v_len := NVL(LENGTHB(value), 0) + CASE WHEN self.m_first = 0 THEN 1 ELSE 0 END;
		IF NVL(LENGTHB(m_string), 0) + v_len <= 4000 THEN
			IF self.m_first = 0 THEN
				self.m_string := self.m_string || self.m_sep;
			END IF;
			self.m_first := 0;
			self.m_string := self.m_string || value;
			RETURN ODCIConst.Success;
		END IF;
		
	    dbms_lob.createtemporary(self.m_clob, TRUE, dbms_lob.call);
		dbms_lob.open(self.m_clob, dbms_lob.lob_readwrite);
		
		IF m_string IS NOT NULL THEN
			dbms_lob.writeappend(self.m_clob, LENGTH(self.m_string), self.m_string);
		END IF;
	END IF;
	
	IF self.m_first = 0 THEN
  		dbms_lob.writeappend(self.m_clob, 1, self.m_sep);
	END IF;
	self.m_first := 0;
	dbms_lob.writeappend(self.m_clob, LENGTH(value), value);

	return ODCIConst.Success;
END;

MEMBER FUNCTION ODCIAggregateTerminate
(
	self        				IN stragg3_type,
	returnvalue					OUT CLOB,
	flags						IN NUMBER
)
RETURN NUMBER
IS
BEGIN

	--  Can't close this, oh well...
	--  dbms_lob.close(self.string);
	IF self.m_clob IS NULL THEN
		returnValue := self.m_string;
	ELSE
    	returnValue := self.m_clob;
	END IF;
    return ODCIConst.Success;
END;

MEMBER FUNCTION ODCIAggregateMerge
(
	self 						IN OUT NOCOPY stragg3_type,
	ctx2 						IN stragg3_type
)
RETURN NUMBER
IS
BEGIN
	IF ctx2.m_clob IS NULL THEN
		IF ctx2.m_string IS NOT NULL THEN
			return self.ODCIAggregateIterate(ctx2.m_string);
		END IF;
		-- (else there's no input data)
	ELSE
		IF self.m_clob IS NULL THEN
		    dbms_lob.createtemporary(self.m_clob, TRUE, dbms_lob.call);
			dbms_lob.open(self.m_clob, dbms_lob.lob_readwrite);
			
			IF m_string IS NOT NULL THEN
				dbms_lob.writeappend(self.m_clob, LENGTH(self.m_string), self.m_string);
			END IF;
		END IF;
		
		IF self.m_first = 0 THEN
  			dbms_lob.writeappend(self.m_clob, 1, self.m_sep);
		END IF;
		self.m_first := 0;
		
		-- Gets ORA-22922: nonexistent LOB value
		-- ORA-06512: at "SYS.DBMS_LOB", line 639
		-- ORA-06512: at "CSR.STRAGG3_TYPE", line 108
		-- 22922. 00000 -  "nonexistent LOB value"
		-- *Cause:    The LOB value associated with the input locator does not exist.
        --   The information in the locator does not refer to an existing LOB.
		-- *Action:   Repopulate the locator by issuing a select statement and retry
        --   the operation.
        -- I think the issue must the temporary lobs from the other parallel server
        -- session can't be seen (the lob value isn't null)
        -- Worked around by not marking the function as parallel_enable
        -- which seems to stop e.g.
        -- select /*+ parallel(ss 2) */ csr.stragg3(s) from mark.ss
        -- from failing at least.
		dbms_lob.append(self.m_clob, ctx2.m_clob);
	END IF;

    return ODCIConst.Success;
END;

END;
/

create or replace function csr.stragg3
  ( input varchar2 )
  return clob
  deterministic
--  parallel_enable
  aggregate using stragg3_type
;
/
