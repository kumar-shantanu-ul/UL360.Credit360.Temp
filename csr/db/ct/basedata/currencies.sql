/**********************************************************************************

Currencies.sql should not be run directly as SQLPlus won't transfer the Unicode 
symbols correctly. 

Any new currencies should be added to currencies.sql, and then run through the 
UTF8ScriptMangler in:

C:\cvs\aspen2\tools\UTF8ScriptMangler\

To convert currencies.sql into something that can be inserted into the db, run:

UTF8ScriptMangler currencies.sql currencies_mangled.sql 

- All changes should be made to currencies.sql.
- currencies_mangled.sql should then be run against the db. 
- Both files will be checked in.

**********************************************************************************/


BEGIN
	UPDATE CT.CURRENCY SET SYMBOL = '$' WHERE ACRONYM IN ('USD', 'AUD');
	UPDATE CT.CURRENCY SET SYMBOL = '£' WHERE ACRONYM IN ('GBP');
	UPDATE CT.CURRENCY SET SYMBOL = '€' WHERE ACRONYM IN ('EUR');
	UPDATE CT.CURRENCY SET SYMBOL = '¥' WHERE ACRONYM IN ('CNY');
	UPDATE CT.CURRENCY SET SYMBOL = '¥' WHERE ACRONYM IN ('JPY');
END;
/

