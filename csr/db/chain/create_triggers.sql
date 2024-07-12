CREATE OR REPLACE TRIGGER NEWSFLASH_INSERT_TRIGGER
BEFORE INSERT ON NEWSFLASH FOR EACH ROW
BEGIN
	IF :NEW.NEWSFLASH_ID IS NULL THEN
		SELECT NEWSFLASH_ID_SEQ.NEXTVAL INTO :NEW.NEWSFLASH_ID FROM DUAL;
	END IF;
END;
/
