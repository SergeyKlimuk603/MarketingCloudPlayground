public with sharing class AccountTriggerHandler {
    public AccountTriggerHandler() {

    }

    public void run() {
        switch on Trigger.operationType {
            when AFTER_UPDATE {
                this.afterUpdate();
            } 
        }
    }

    private void afterUpdate() {
        List<Account> newAccounts = Trigger.new;
        Map<Id, Account> oldAccountsMap = new Map<Id, Account>((List<Account>) Trigger.oldMap.values());

        createAssetsForEmailSending(newAccounts, oldAccountsMap);
        deleteAssetsFromContentBuilder(newAccounts, oldAccountsMap);
    }

    private void createAssetsForEmailSending(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<Id> accountIds = getAccountsForEmailSending(newAccounts, oldAccountsMap);

        if (accountIds.isEmpty()) {
            return;
        }

        createAssetsInContentBuilder(accountIds);
    }

    private List<Id> getAccountsForEmailSending(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        List<Id> accountIdsForEmailSending = new List<Id>();

        for (Account account : newAccounts) {
            if (account.SendEmail__c == true && oldAccountsMap.get(account.Id).SendEmail__c == false) {
                accountIdsForEmailSending.add(account.Id);
            }
        }

        return accountIdsForEmailSending;
    }

    @future(callout=true)
    private static void createAssetsInContentBuilder(List<Id> accountIds) {

        Map<Id, String> base64ContentByAccountIds =  getBase64ContentByAccountIds(accountIds);
        System.debug('-----base64ContentByAccountIds: ' + base64ContentByAccountIds);

        Map<Id, HttpResponse> responseByAccountIds = createAssetsInMc(base64ContentByAccountIds);

        System.debug('-----responseByAccountIds: ' + responseByAccountIds);

        List<Account> accountsWithAssetParameters = fillAssetParametersInAccounts(accountIds, responseByAccountIds);

        System.debug('-----accountsWithAssetParameters: ' + accountsWithAssetParameters);

        update accountsWithAssetParameters;

    }

    private static Map<Id, String> getBase64ContentByAccountIds(List<Id> accountIds) {
        List<ContentDocumentLink> cdLinks = [
            SELECT ContentDocumentId, LinkedEntityId, SystemModstamp
            FROM ContentDocumentLink 
            WHERE LinkedEntityId IN :accountIds
            ORDER BY SystemModstamp DESC
        ];

        Map<Id, ContentDocumentLink> lastCdLinkByAccounts = new Map<Id, ContentDocumentLink>();
        for (ContentDocumentLink cdLink : cdLinks) {
            if (lastCdLinkByAccounts.get(cdLink.LinkedEntityId) == null) {
                lastCdLinkByAccounts.put(cdLink.LinkedEntityId, cdLink);
            }
        }

        Map<Id, Id> accountIdByCdIds = new Map<Id, Id>(); // Map<ContentDocumentId, account.Id>
        for (ContentDocumentLink cdLink : lastCdLinkByAccounts.values()) {
            accountIdByCdIds.put(cdLink.ContentDocumentId, cdLink.LinkedEntityId);
        }

        System.debug('-----accountIdByCdIds: ' + accountIdByCdIds);

        Set<Id> cdIds = accountIdByCdIds.keySet();
        List<ContentVersion> contentVersions = [
            SELECT Title, VersionData, ContentDocumentId
            FROM ContentVersion 
            WHERE IsLatest = TRUE 
                AND ContentDocumentId IN :cdIds
        ];
        Map<Id, String> base64ContentByAccountIds = new Map<Id, String>(); // Map<contentVersion.ContentDocumentId, base64Content>
        for (ContentVersion contentVersion : contentVersions) {
            base64ContentByAccountIds.put(
                accountIdByCdIds.get(contentVersion.ContentDocumentId),
                EncodingUtil.base64Encode(contentVersion.VersionData)
            );
        }

        return base64ContentByAccountIds;
    }

    private static Map<Id, HttpResponse> createAssetsInMc(Map<Id, String> base64ContentByAccountIds) {
        String mcAccessToken = getMcToken();
        
        Map<Id, HttpResponse> responseByAccountId = new Map<Id, HttpResponse>();
        for (Id accountId : base64ContentByAccountIds.keySet()) {
            HttpResponse response = createAssetInMc(
                mcAccessToken,
                'Asset_to_attach_to_Email_' + accountId, 
                base64ContentByAccountIds.get(accountId)
            );
            responseByAccountId.put(accountId, response);
        }

        return responseByAccountId;
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

        return mcTokenResponseBodyMap.get('access_token').toString();
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
        createAssetRequest.setBody(createPdfAssetRequestBody(contentName, contentBody));
        
        return http.send(createAssetRequest);
    }

    public static String createPdfAssetRequestBody(String contentName, String contentBody) {
        return '{'
            + '"name": "' + contentName + '_' + Datetime.now() + '.pdf",'
            + '"assetType": {'
            + '    "name": "pdf",'
            + '    "id": 127'
            + '},'
            + '"category": {'
            + '    "id": 126575,'
            + '    "name": "Attachments"'
            + '},'
            + '"file": "' + contentBody + '"'
            + '}';
    }

    private static List<Account> fillAssetParametersInAccounts(
        List<Id> accountIds, 
        Map<Id, HttpResponse> responseByAccountIds
    ) {
        List<Account> accountsWithAssetParameters = new List<Account>();
        for (Id accountId : responseByAccountIds.keySet()) {
            Account account = new Account(Id = accountId);
            Map<String, Object> assetParameters = 
                (Map<String, Object>)JSON.deserializeUntyped(responseByAccountIds.get(accountId).getBody());
            String assetCustomerKey = assetParameters.get('customerKey').toString();
            String assetId = String.valueOf((Integer) assetParameters.get('id'));
            account.MC_AssetCustomerKey__c = assetCustomerKey;
            account.MC_AssetId__c = assetId;
            account.SendedAssetData__c = assetCustomerKey + ';' + assetId;

            accountsWithAssetParameters.add(account);
        }

        return accountsWithAssetParameters;
    }

    private void deleteAssetsFromContentBuilder(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<String> assetIds = getAssetIdForDelete(newAccounts, oldAccountsMap);

        if (assetIds.isEmpty()) {
            return;
        }

        deleteAssets(assetIds);
    }

    private Set<String> getAssetIdForDelete(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<String> assetIdsForDelete = new Set<String>();

        for (Account account : newAccounts) {
            Account oldAccount = oldAccountsMap.get(account.Id);
            if (String.isBlank(account.MC_AssetId__c) && String.isNotBlank(oldAccount.MC_AssetId__c)) {
                assetIdsForDelete.add(oldAccount.MC_AssetId__c);
            }
        }

        return assetIdsForDelete;
    }

    @future(callout=true)
    private static void deleteAssets(Set<String> assetIdsForDelete) {
        String mcAccessToken = getMcToken();
        
        List<HttpResponse> responses = new List<HttpResponse>();
        for (String assetIdForDelete : assetIdsForDelete) {
            HttpResponse response = deleteAssetFromMc(assetIdForDelete, mcAccessToken);
            responses.add(response);
        }
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