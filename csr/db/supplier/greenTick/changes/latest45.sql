-- Please update version.sql too -- this keeps clean builds in sync
define version=45

@update_header

-- update descriptions
	UPDATE SUPPLIER.GT_PDA_PROVENANCE_TYPE SET DESCRIPTION =  'Intensively farmed (inc. large plantations, glasshouse horticulture, commercial fishing and forestry)'
		WHERE  GT_PDA_PROVENANCE_TYPE_ID = 2;

	UPDATE SUPPLIER.GT_PDA_PROVENANCE_TYPE SET DESCRIPTION =  'Palm oil and close derivatives (one processing step from natural palm oil material)'
		WHERE  GT_PDA_PROVENANCE_TYPE_ID = 3;
		
	UPDATE SUPPLIER.GT_PDA_PROVENANCE_TYPE SET DESCRIPTION =  'Processed materials derived from palm or vegetable oils (this is not regarded as naturally derived)'
		WHERE  GT_PDA_PROVENANCE_TYPE_ID = 4;

	UPDATE SUPPLIER.GT_PDA_PROVENANCE_TYPE SET DESCRIPTION =  'Wild harvested (includes wild gathered material and fishing)'
		WHERE  GT_PDA_PROVENANCE_TYPE_ID = 5;
	
@update_tail