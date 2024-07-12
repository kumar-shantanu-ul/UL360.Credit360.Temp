PROMPT >> Inserting file upload basedata
BEGIN
	INSERT INTO chain.DOWNLOAD_PERMISSION (DOWNLOAD_PERMISSION_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.DOWNLOAD_PERM_STANDARD, 'Standard capability based permissions');

	INSERT INTO chain.DOWNLOAD_PERMISSION (DOWNLOAD_PERMISSION_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.DOWNLOAD_PERM_EVERYONE, 'Everyone can downloadaccess this file');

	INSERT INTO chain.DOWNLOAD_PERMISSION (DOWNLOAD_PERMISSION_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.DOWNLOAD_PERM_SUPPLIERS, 'My company and my suppliers can download this file');

	INSERT INTO chain.DOWNLOAD_PERMISSION (DOWNLOAD_PERMISSION_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.DOWNLOAD_PERM_STND_TRANS, 'Standard capability based permissions OR permission for any company that passes transparency check for the ownwer company');

	INSERT INTO chain.DOWNLOAD_PERMISSION (DOWNLOAD_PERMISSION_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.DOWNLOAD_PERM_PRTCTD_TRANS, 'Owner company and any company that passes transparency check for the owner company - standard checks not used');
	
	
	INSERT INTO chain.FILE_GROUP_MODEL (FILE_GROUP_MODEL_ID, DESCRIPTION)
	VALUES (chain.chain_pkg.LANGUAGE_GROUP, 'Groups files by thier language and provides the user with the best file when downloading based on their language settings.');
END;
/
