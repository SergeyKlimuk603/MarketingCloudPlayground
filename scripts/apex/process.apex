//---------------------------------------------------------------------------------------------
// Process
//---------------------------------------------------------------------------------------------
// Delete add old TestObject__c
// List<TestObject__c> midTermSolutionTwoTestObjectsForDelete = [
//     SELECT Id
//     FROM TestObject__c
//     WHERE Name = 'Mid-Term Solution_2'
// ];
// delete midTermSolutionTwoTestObjectsForDelete;

// // Create new TestObject__c or select existing one
// Boolean createNewRecord = false; // change this
// TestObject__c testObject;
// if (createNewRecord) {
//     testObject = new TestObject__c(
//         Name = 'Mid-Term Solution_2',
//         EmailField__c = 'sergeyklimuk79@gmail.com'
//     );

//     insert testObject;
// } else {
//     testObject = [
//         SELECT Id, TextField__c, NumberField__c
//         FROM TestObject__c
//         WHERE Name = 'Mid-Term Solution_2'
//         LIMIT 1
//     ];
// }

// Select existing TestObject__c with Fail. You have to create if before
TestObject__c testObject = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name = 'Mid-Term Solution_2'
    LIMIT 1
];

// Get file in base64 format
ContentDocumentLink contentDocumentLink = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testObject.Id];

ContentVersion file = [
    SELECT Title, VersionData 
    FROM ContentVersion 
    WHERE IsLatest = TRUE 
        AND ContentDocumentId = :contentDocumentLink.ContentDocumentId
];

System.debug('-----file: ' + file);
String bodyBase64 = EncodingUtil.base64Encode(file.VersionData);

// Get accessToken from Marketing Cloud
HttpRequest getMcTokenRequest = new HttpRequest();
getMcTokenRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.auth.marketingcloudapis.com/v2/token');
getMcTokenRequest.setMethod('POST');
getMcTokenRequest.setHeader('Content-Type', 'application/json');
getMcTokenRequest.setBody(createMcTocenRequestBody());
Http http = new Http();
HttpResponse mcTokenResponce = http.send(getMcTokenRequest);
System.debug('-----mcTokenResponce: ' + mcTokenResponce);
String mcTokenResponseBody = mcTokenResponce.getBody();
System.debug('-----mcTokenResponceBody: ' + mcTokenResponseBody);
//String mcTokenResponceBody = '{"access_token": "SECRET_TOKEN_GOES_HERE", "token_type": "Bearer"}';
Map<String, Object> mcTokenResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(mcTokenResponseBody);
System.debug('-----mcTokenResponceBodyMap: ' + mcTokenResponseBodyMap);
String mcAccessToken = mcTokenResponseBodyMap.get('access_token').toString();
System.debug('-----mcAccessToken: ' + mcAccessToken);

// Create asset in Contact Builder of Marketing Cloud
HttpRequest createAssetRequest = new HttpRequest();
createAssetRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.rest.marketingcloudapis.com/asset/v1/content/assets');
createAssetRequest.setMethod('POST');
createAssetRequest.setHeader('Authorization', 'Bearer ' + mcAccessToken);
createAssetRequest.setHeader('Content-Type', 'application/json');
createAssetRequest.setBody(createAssetRequestBody());
HttpResponse createAssetResponse = http.send(createAssetRequest);
System.debug('-----createAssetResponse: ' + createAssetResponse);

public static String createMcTocenRequestBody() {
    return '{'
        + '"grant_type": "client_credentials",'
        + '"client_id": "ewtrxspazumgmt58gqx81byr",'
        + '"client_secret": "t1P8Ax1LHkNq34LHUqNbeHCX",'
        + '"account_id": "510001082,"'
        +'}';
}

public static String createAssetRequestBody() {
    return '{'
        + '"name": "KS_PdfFromDocCreatedViaApiFromAnonimus.pdf",'
        + '"assetType": {'
        + '    "name": "pdf",'
        + '    "id": 127'
        + '},'
        + '"category": {'
        + '    "id": 125648,'
        + '    "name": "FileAttachments"'
        + '},'
        + '"file": "JVBERi0xLjUKJeLjz9MKNyAwIG9iago8PAovVHlwZSAvRm9udERlc2NyaXB0b3IKL0ZvbnROYW1lIC9UaW1lcyMyME5ldyMyMFJvbWFuCi9GbGFncyAzMgovSXRhbGljQW5nbGUgMAovQXNjZW50IDg5MQovRGVzY2VudCAtMjE2Ci9DYXBIZWlnaHQgNjkzCi9BdmdXaWR0aCA0MDEKL01heFdpZHRoIDI2MTQKL0ZvbnRXZWlnaHQgNDAwCi9YSGVpZ2h0IDI1MAovTGVhZGluZyA0MgovU3RlbVYgNDAKL0ZvbnRCQm94IFstNTY4IC0yMTYgMjA0NiA2OTNdCj4+CmVuZG9iago4IDAgb2JqClsyNTAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDcyMiAwIDU1NiAwIDAgMCAwIDAgMCAwIDAgMCA1NTYgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgMCAwIDAgNDQ0IDAgMCAzMzMgMCAwIDAgMCAwIDAgNzc4IDAgNTAwIDAgMCAzMzNdCmVuZG9iago2IDAgb2JqCjw8Ci9UeXBlIC9Gb250Ci9TdWJ0eXBlIC9UcnVlVHlwZQovTmFtZSAvRjEKL0Jhc2VGb250IC9UaW1lcyMyME5ldyMyMFJvbWFuCi9FbmNvZGluZyAvV2luQW5zaUVuY29kaW5nCi9Gb250RGVzY3JpcHRvciA3IDAgUgovRmlyc3RDaGFyIDMyCi9MYXN0Q2hhciAxMTQKL1dpZHRocyA4IDAgUgo+PgplbmRvYmoKOSAwIG9iago8PAovVHlwZSAvRXh0R1N0YXRlCi9CTSAvTm9ybWFsCi9jYSAxCj4+CmVuZG9iagoxMCAwIG9iago8PAovVHlwZSAvRXh0R1N0YXRlCi9CTSAvTm9ybWFsCi9DQSAxCj4+CmVuZG9iagoxMSAwIG9iago8PAovRmlsdGVyIC9GbGF0ZURlY29kZQovTGVuZ3RoIDE5Mgo+PgpzdHJlYW0KeJytjzELwjAQhfdA/sMbE6FpLiYmheJgW0WhULHgIE5iO6mo/x9MtYODozfde7w73oe0QZ6ndbEuoedzLMoCd8600sOE4KfQcJlT1iJYo7TF48zZfoIrZ4uWs3RJIFIhoO04o5jWILiZcvHCe6s82kuMrXYe/TN+Rv9WYVQrzg6ikUSilIkVy2GDTIwR3eMmE3LiIpMsWuETGDwrTvKIdsNZFRtsOUNVF8AXCv0PhYxXwX+hvAnG4vjR4wW0EkJLCmVuZHN0cmVhbQplbmRvYmoKNSAwIG9iago8PAovVHlwZSAvUGFnZQovTWVkaWFCb3ggWzAgMCA1OTUuNDQgODQyLjA0XQovUmVzb3VyY2VzIDw8Ci9Gb250IDw8Ci9GMSA2IDAgUgo+PgovRXh0R1N0YXRlIDw8Ci9HUzcgOSAwIFIKL0dTOCAxMCAwIFIKPj4KL1Byb2NTZXQgWy9QREYgL1RleHQgL0ltYWdlQiAvSW1hZ2VDIC9JbWFnZUldCj4+Ci9Db250ZW50cyAxMSAwIFIKL0dyb3VwIDw8Ci9UeXBlIC9Hcm91cAovUyAvVHJhbnNwYXJlbmN5Ci9DUyAvRGV2aWNlUkdCCj4+Ci9UYWJzIC9TCi9TdHJ1Y3RQYXJlbnRzIDAKL1BhcmVudCAyIDAgUgo+PgplbmRvYmoKMTIgMCBvYmoKPDwKL1MgL1NwYW4KL1R5cGUgL1N0cnVjdEVsZW0KL0FjdHVhbFRleHQgKFBERiBmcm9tIERvYykKL0sgWzBdCi9QIDEzIDAgUgovUGcgNSAwIFIKPj4KZW5kb2JqCjE1IDAgb2JqCjw8Ci9TIC9TcGFuCi9UeXBlIC9TdHJ1Y3RFbGVtCi9BY3R1YWxUZXh0ICggKQovSyBbMV0KL1AgMTMgMCBSCi9QZyA1IDAgUgo+PgplbmRvYmoKMTMgMCBvYmoKPDwKL1MgL1AKL1R5cGUgL1N0cnVjdEVsZW0KL0sgWzEyIDAgUiAxNSAwIFJdCi9QIDE0IDAgUgo+PgplbmRvYmoKMTQgMCBvYmoKPDwKL1MgL1BhcnQKL1R5cGUgL1N0cnVjdEVsZW0KL0sgWzEzIDAgUl0KL1AgMyAwIFIKPj4KZW5kb2JqCjE2IDAgb2JqCjw8Ci9OdW1zIFswIFsxMiAwIFIgMTUgMCBSXV0KPj4KZW5kb2JqCjQgMCBvYmoKPDwKL0Zvb3Rub3RlIC9Ob3RlCi9FbmRub3RlIC9Ob3RlCi9UZXh0Ym94IC9TZWN0Ci9IZWFkZXIgL1NlY3QKL0Zvb3RlciAvU2VjdAovSW5saW5lU2hhcGUgL1NlY3QKL0Fubm90YXRpb24gL1NlY3QKL0FydGlmYWN0IC9TZWN0Ci9Xb3JrYm9vayAvRG9jdW1lbnQKL1dvcmtzaGVldCAvUGFydAovTWFjcm9zaGVldCAvUGFydAovQ2hhcnRzaGVldCAvUGFydAovRGlhbG9nc2hlZXQgL1BhcnQKL1NsaWRlIC9QYXJ0Ci9DaGFydCAvU2VjdAovRGlhZ3JhbSAvRmlndXJlCj4+CmVuZG9iagozIDAgb2JqCjw8Ci9UeXBlIC9TdHJ1Y3RUcmVlUm9vdAovUm9sZU1hcCA0IDAgUgovSyBbMTQgMCBSXQovUGFyZW50VHJlZSAxNiAwIFIKL1BhcmVudFRyZWVOZXh0S2V5IDEKPj4KZW5kb2JqCjIgMCBvYmoKPDwKL1R5cGUgL1BhZ2VzCi9LaWRzIFs1IDAgUl0KL0NvdW50IDEKPj4KZW5kb2JqCjEgMCBvYmoKPDwKL1R5cGUgL0NhdGFsb2cKL1BhZ2VzIDIgMCBSCi9MYW5nIChlbi1VUykKL1N0cnVjdFRyZWVSb290IDMgMCBSCi9NYXJrSW5mbyA8PAovTWFya2VkIHRydWUKPj4KPj4KZW5kb2JqCjE3IDAgb2JqCjw8Ci9DcmVhdG9yIDxGRUZGMDA0RDAwNjkwMDYzMDA3MjAwNkYwMDczMDA2RjAwNjYwMDc0MDBBRTAwMjAwMDU3MDA2RjAwNzIwMDY0MDAyMDAwMzIwMDMwMDAzMTAwMzY+Ci9DcmVhdGlvbkRhdGUgKEQ6MjAyNDAxMTYwODEwMTMrMDAnMDAnKQovUHJvZHVjZXIgKHd3dy5pbG92ZXBkZi5jb20pCi9Nb2REYXRlIChEOjIwMjQwMTE2MDgxMDEzWikKPj4KZW5kb2JqCnhyZWYKMCAxOAowMDAwMDAwMDAwIDY1NTM1IGYNCjAwMDAwMDIxNzAgMDAwMDAgbg0KMDAwMDAwMjExMyAwMDAwMCBuDQowMDAwMDAyMDAzIDAwMDAwIG4NCjAwMDAwMDE3MjAgMDAwMDAgbg0KMDAwMDAwMTAyOSAwMDAwMCBuDQowMDAwMDAwNDY3IDAwMDAwIG4NCjAwMDAwMDAwMTUgMDAwMDAgbg0KMDAwMDAwMDI2NiAwMDAwMCBuDQowMDAwMDAwNjUxIDAwMDAwIG4NCjAwMDAwMDA3MDcgMDAwMDAgbg0KMDAwMDAwMDc2NCAwMDAwMCBuDQowMDAwMDAxMzMyIDAwMDAwIG4NCjAwMDAwMDE1MjcgMDAwMDAgbg0KMDAwMDAwMTYwMiAwMDAwMCBuDQowMDAwMDAxNDM1IDAwMDAwIG4NCjAwMDAwMDE2NzIgMDAwMDAgbg0KMDAwMDAwMjI4NCAwMDAwMCBuDQp0cmFpbGVyCjw8Ci9TaXplIDE4Ci9Sb290IDEgMCBSCi9JbmZvIDE3IDAgUgovSUQgWzxBNjdGNTI1Mzc2NjIwMzcwMjE0QTY4NThERTI4MTIxMj4gKF8hXDI1MEJyIVwyMjNsX1wwMDZhclpBXDM0NVwwMzUpXQo+PgpzdGFydHhyZWYKMjUwMAolJUVPRgo="'
        +'}';
}