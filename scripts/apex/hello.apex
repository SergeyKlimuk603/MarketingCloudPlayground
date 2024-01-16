// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

string tempvar = 'Enter_your_name_here';
System.debug('Hello World!');
System.debug('My name is ' + tempvar);



ContentVersion file = [SELECT Title, VersionData FROM ContentVersion WHERE IsLatest = TRUE and ContentDocumentId='0692w00000WODJrAAP'];
String bodyBase64 = EncodingUtil.base64Encode(file.VersionData);
System.debug('-----bodyBase64: ' + bodyBase64);
System.debug('-----file.VersionData: ' + file.VersionData);
System.debug('-----file: ' + file);


