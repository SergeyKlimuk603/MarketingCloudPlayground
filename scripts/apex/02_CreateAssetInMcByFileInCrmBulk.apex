//---------------------------------------------------------------------------------------------
// 02_CreateAssetInMcByFileInCrmBulk
//---------------------------------------------------------------------------------------------
// Данный процесс расчитан на то, что в CRM уже есть записи с прикрепленными к ним файломи !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// Перед запуском нужно очистить поля TextField__c на объектах TestObject__c с именеи 'Mid-Term Solution_2'

class MyException extends Exception {}

// Select existing TestObject__cs with Fails. You have to create if before
Map<Id, TestObject__c> testObjectByIds = getTestObjects();
if (testObjectByIds.isEmpty()) {
    throw new MyException('You need to create TestObjects__cs with attached Files before');
}

Map<Id, String> base64ContentByTestObjectIds =  getBase64ContentByTestObjectIds(testObjectByIds);

Map<Id, HttpResponse> responseByTestObjectIds = createAssetsInMc(testObjectByIds, base64ContentByTestObjectIds);

List<TestObject__c> testObjectsWithAssetParameters = fillAssetParametersInTestObjects(testObjectByIds, responseByTestObjectIds);

update testObjectsWithAssetParameters;


//---------------------------------------------------------------------------------------------


private static Map<Id, TestObject__c> getTestObjects() {
    return new Map<Id, TestObject__c>([
        SELECT Id, TextField__c, NumberField__c
        FROM TestObject__c
        WHERE Name LIKE 'Mid-Term Solution_2 %'
    ]);
}

private static Map<Id, String> getBase64ContentByTestObjectIds(Map<Id, TestObject__c> testObjectByIds) {
    Set<Id> testObjectIds = testObjectByIds.keySet();
    List<ContentDocumentLink> contentDocumentLinks = [
        SELECT ContentDocumentId, LinkedEntityId
        FROM ContentDocumentLink 
        WHERE LinkedEntityId IN :testObjectIds
    ];

    Map<Id, Id> testObjectIdByContentDocumentIds = new Map<Id, Id>(); // Map<contentDocumentId, testObject.Id>
    for (ContentDocumentLink cdLink : contentDocumentLinks) {
        testObjectIdByContentDocumentIds.put(cdLink.ContentDocumentId, cdLink.LinkedEntityId);
    }

    Set<Id> contentDocumentIds = testObjectIdByContentDocumentIds.keySet();
    List<ContentVersion> contentVersions = [
        SELECT Title, VersionData, ContentDocumentId
        FROM ContentVersion 
        WHERE IsLatest = TRUE 
            AND ContentDocumentId IN :contentDocumentIds
    ];
    Map<Id, String> base64ContentByTestObjectIds = new Map<Id, String>(); // Map<contentVersion.ContentDocumentId, base64Content>
    for (ContentVersion contentVersion : contentVersions) {
        base64ContentByTestObjectIds.put(
            testObjectIdByContentDocumentIds.get(contentVersion.ContentDocumentId),
            EncodingUtil.base64Encode(contentVersion.VersionData)
        );
    }

    return base64ContentByTestObjectIds;
}

private static Map<Id, HttpResponse> createAssetsInMc(
    Map<Id, TestObject__c> testObjectByIds, 
    Map<Id, String> base64ContentByTestObjectIds
) {
    String mcAccessToken = getMcToken();
    
    Map<Id, HttpResponse> responseByTestObjectId = new Map<Id, HttpResponse>();
    for (Id testObjectId : base64ContentByTestObjectIds.keySet()) {
        HttpResponse response = createAssetInMc(
            mcAccessToken,
            'KS_PdfFromDocCreatedViaApiFromAnonimus_' + testObjectId + '_', 
            base64ContentByTestObjectIds.get(testObjectId)
        );
        responseByTestObjectId.put(testObjectId, response);
    }

    return responseByTestObjectId;
}

private static String getMcToken() {
    Http http = new Http();

    HttpRequest getMcTokenRequest = new HttpRequest();
    getMcTokenRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.auth.marketingcloudapis.com/v2/token');
    getMcTokenRequest.setMethod('POST');
    getMcTokenRequest.setHeader('Content-Type', 'application/json');
    getMcTokenRequest.setBody(createMcTocenRequestBody());
    HttpResponse mcTokenResponce = http.send(getMcTokenRequest);
    String mcTokenResponseBody = mcTokenResponce.getBody();
    Map<String, Object> mcTokenResponseBodyMap = (Map<String, Object>)JSON.deserializeUntyped(mcTokenResponseBody);
    String mcAccessToken = mcTokenResponseBodyMap.get('access_token').toString();
    System.debug('-----mcAccessToken: ' + mcAccessToken);

    return mcAccessToken;
}

public static String createMcTocenRequestBody() {
    return '{'
        + '"grant_type": "client_credentials",'
        + '"client_id": "ewtrxspazumgmt58gqx81byr",'
        + '"client_secret": "t1P8Ax1LHkNq34LHUqNbeHCX",'
        + '"account_id": "510001082,"'
        +'}';
}

private static HttpResponse createAssetInMc(String mcAccessToken, String contentName, String contentBody) {
    Http http = new Http();

    HttpRequest createAssetRequest = new HttpRequest();
    createAssetRequest.setEndpoint('https://mc7zjpjxybznqygjvlpmzds99qn8.rest.marketingcloudapis.com/asset/v1/content/assets');
    createAssetRequest.setMethod('POST');
    createAssetRequest.setHeader('Authorization', 'Bearer ' + mcAccessToken);
    createAssetRequest.setHeader('Content-Type', 'application/json');
    createAssetRequest.setBody(createAssetRequestBody(contentName, contentBody));
    HttpResponse response = http.send(createAssetRequest);
    System.debug('-----response.getBody(): ' + response.getBody());
    
    return response;
}

public static String createAssetRequestBody(String contentName, String contentBody) {
    return '{'
        //+ '"name": "KS_PdfFromDocCreatedViaApiFromAnonimus' + Datetime.now() + '.pdf",'
        + '"name": "' + contentName + '_' + Datetime.now() + '.pdf",'
        + '"assetType": {'
        + '    "name": "pdf",'
        + '    "id": 127'
        + '},'
        + '"category": {'
        + '    "id": 125648,'
        + '    "name": "FileAttachments"'
        + '},'
        + '"file": "' + contentBody + '"'
        +'}';
}

private static List<TestObject__c> fillAssetParametersInTestObjects(
    Map<Id, TestObject__c> testObjectByIds, 
    Map<Id, HttpResponse> responseByTestObjectIds
) {
    List<TestObject__c> testObjectsWithAssetParameters = new List<TestObject__c>();
    for (Id testObjectId : responseByTestObjectIds.keySet()) {
        // Put assetCustomerKey and assetId to TestObject__c.TextField__c
        TestObject__c testObject = testObjectByIds.get(testObjectId);
        Map<String, Object> assetParameters = (Map<String, Object>)JSON.deserializeUntyped(responseByTestObjectIds.get(testObjectId).getBody());
        String assetCustomerKey = assetParameters.get('customerKey').toString();
        Integer assetId = (Integer) assetParameters.get('id');
        testObject.TextField__c = assetCustomerKey + ';' + assetId;
        testObject.TextAreaField__c = 'Updated from Anonimus. Asset data aded to TextField';

        testObjectsWithAssetParameters.add(testObject);
    }

    return testObjectsWithAssetParameters;
}