public with sharing class TestObjectTriggerHandler {
    private static final String NOT_ASSET_ID = '';

    public void run() {
        List<TestObject__c> newRecords = Trigger.new;
        Map<Id, TestObject__c> oldRecordsMap = 
            new Map<Id, TestObject__c>((List<TestObject__c>) Trigger.oldMap.values());

        Set<String> assetIdsForDeleteFromMc = getAssetIdsForDeleteFromMc(newRecords, oldRecordsMap);
    
        if (assetIdsForDeleteFromMc.isEmpty()) {
            System.debug('-----no assets for delete');
            return;
        }

        deleteAssetsFromMc(assetIdsForDeleteFromMc);
    }

    private Set<String> getAssetIdsForDeleteFromMc(
        List<TestObject__c> newRecords, 
        Map<Id, TestObject__c> oldRecordsMap
    ) {
        Set<String> assetIdsForDeleteFromMc = new Set<String>();
        for (TestObject__c testObjectNew : newRecords) {
            TestObject__c testObjectOld = oldRecordsMap.get(testObjectNew.Id);
            if (String.isBlank(testObjectNew.TextField__c) && String.isNotBlank(testObjectOld.TextField__c)) {
                assetIdsForDeleteFromMc.add(getAssetId(testObjectOld.TextField__c));
            }
        }

        assetIdsForDeleteFromMc.remove(NOT_ASSET_ID);

        return assetIdsForDeleteFromMc;
    }

    private String getAssetId(String textField) {
        List<String> assetParameters = textField.split(';');

        return assetParameters.size() > 1 ? assetParameters.get(1) : NOT_ASSET_ID;
    }

    @future(callout=true)
    private static void deleteAssetsFromMc(Set<String> assetIdsForDelete) {
        String mcAccessToken = getMcToken();
        
        List<HttpResponse> responses = new List<HttpResponse>();
        for (String assetIdForDelete : assetIdsForDelete) {
            HttpResponse response = deleteAssetFromMc(assetIdForDelete, mcAccessToken);
            responses.add(response);
        }
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

        return mcAccessToken;
    }

    private static String createMcTocenRequestBody() {
        return '{'
            + '"grant_type": "client_credentials",'
            + '"client_id": "ewtrxspazumgmt58gqx81byr",'
            + '"client_secret": "t1P8Ax1LHkNq34LHUqNbeHCX",'
            + '"account_id": "510001082,"'
            +'}';
    }

    private static HttpResponse deleteAssetFromMc(String assetIdForDelete, String mcAccessToken) {
        Http http = new Http();
        HttpRequest deleteAssetRequest = new HttpRequest();
        deleteAssetRequest.setEndpoint(
            'https://mc7zjpjxybznqygjvlpmzds99qn8.rest.marketingcloudapis.com/asset/v1/content/assets/' 
            + assetIdForDelete
        );
        deleteAssetRequest.setMethod('DELETE');
        deleteAssetRequest.setHeader('Authorization', 'Bearer ' + mcAccessToken);

        return http.send(deleteAssetRequest);
    }
}