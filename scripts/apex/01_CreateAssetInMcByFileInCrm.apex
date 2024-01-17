//---------------------------------------------------------------------------------------------
// 01_CreateAssetInMcByFileInCrm
//---------------------------------------------------------------------------------------------
// Данный процесс расчитан на то, что в CRM уже есть запись с прикрепленным к ней файлом !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Перед запуском нужно очистить поле TextField__c на объекте TestObject__c с именеи 'Mid-Term Solution_2'

// Select existing TestObject__c with Fail. You have to create if before
TestObject__c testObject = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name = 'Mid-Term Solution_2'
    LIMIT 1
];

// Get file in base64 format
ContentDocumentLink contentDocumentLink = [
    SELECT ContentDocumentId 
    FROM ContentDocumentLink 
    WHERE LinkedEntityId = :testObject.Id
];

ContentVersion file = [
    SELECT Title, VersionData 
    FROM ContentVersion 
    WHERE IsLatest = TRUE 
        AND ContentDocumentId = :contentDocumentLink.ContentDocumentId
];

System.debug('-----file: ' + file);
String bodyBase64 = EncodingUtil.base64Encode(file.VersionData);

// Create HTTP requests for creating content in Content Builder
Http http = new Http();

// Get accessToken from Marketing Cloud
HttpRequest getMcTokenRequest = new HttpRequest();
getMcTokenRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.auth.marketingcloudapis.com/v2/token');
getMcTokenRequest.setMethod('POST');
getMcTokenRequest.setHeader('Content-Type', 'application/json');
getMcTokenRequest.setBody(createMcTocenRequestBody());
HttpResponse mcTokenResponce = http.send(getMcTokenRequest);
//String mcTokenResponseBody = mcTokenResponce.getBody();
Map<String, Object> mcTokenResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(mcTokenResponce.getBody());
String mcAccessToken = mcTokenResponseBodyMap.get('access_token').toString();

// Create asset in Contact Builder of Marketing Cloud
HttpRequest createAssetRequest = new HttpRequest();
createAssetRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.rest.marketingcloudapis.com/asset/v1/content/assets');
createAssetRequest.setMethod('POST');
createAssetRequest.setHeader('Authorization', 'Bearer ' + mcAccessToken);
createAssetRequest.setHeader('Content-Type', 'application/json');
createAssetRequest.setBody(createAssetRequestBody());
HttpResponse createAssetResponse = http.send(createAssetRequest);
System.debug('-----createAssetResponse: ' + createAssetResponse);


// Put assetCustomerKey and assetId to TestObject__c.TextField__c
Map<String, Object> assetParameters = (Map<String, Object>)JSON.deserializeUntyped(createAssetResponse.getBody());
String assetCustomerKey = assetParameters.get('customerKey').toString();
Integer assetId = (Integer) assetParameters.get('id');
testObject.TextField__c = assetCustomerKey + ';' + assetId;
testObject.TextAreaField__c = 'Updated from Anonimus. Asset data aded to TextField';
update testObject;


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
        + '"name": "KS_PdfFromDocCreatedViaApiFromAnonimus' + Datetime.now() + '.pdf",'
        + '"assetType": {'
        + '    "name": "pdf",'
        + '    "id": 127'
        + '},'
        + '"category": {'
        + '    "id": 125648,'
        + '    "name": "FileAttachments"'
        + '},'
        + '"file": "' + bodyBase64 + '"'
        +'}';
}