//---------------------------------------------------------------------------------------------
// delete ContentDistribution by Id
delete new ContentDistribution(Id = '05D2w000001F56zEAC');
//---------------------------------------------------------------------------------------------
// show ContentDistribution
List<ContentDistribution> contentDistributions = [
    SELECT Id, Name, ContentDocumentId, ContentVersionId, DistributionPublicUrl, PdfDownloadUrl, Password, ExpiryDate
    FROM ContentDistribution
    WHERE Id = '05D2w000001F4z0EAC'
];
if (contentDistributions.isEmpty()) {
    System.debug('-----no ContentDistribution');
} else {
    System.debug('-----contentDistributions.get(0): ' + contentDistributions.get(0));
}
//---------------------------------------------------------------------------------------------
// variant 1
ContentDocumentLink cdl = [
    SELECT contentdocument.id, contentdocument.title, contentdocument.filetype 
    FROM Contentdocumentlink 
    WHERE linkedentityid = '<ParentObjectId>'
        AND
    LIMIT 1
];
ContentVersion cv = [
    SELECT id 
    FROM Contentversion 
    WHERE IsLatest = TRUE
        AND contentdocumentid = :cdl.contentdocument.id
];

ContentDistribution cd = new ContentDistribution();
cd.Name = 'File Public Link (from ContentVersion)';
cd.ContentVersionId = cv.id;
cd.PreferencesAllowViewInBrowser= true;
cd.PreferencesLinkLatestVersion=true;
// cd.PreferencesNotifyOnVisit=false;
// cd.PreferencesPasswordRequired=false;
// cd.PreferencesAllowOriginalDownload= true;
insert cd; // cd.Id: 05D2w000001F4z0EAC

cd = [
    SELECT Id, Name, ContentDocumentId, ContentVersionId, DistributionPublicUrl, PdfDownloadUrl, Password, ExpiryDate
    FROM ContentDistribution
    WHERE Id = :cd.Id
];
System.debug('-----cd: ' + cd);

String publicLink = cd.DistributionPublicUrl;
System.debug('-----publicLink: ' + publicLink);
String pdfDownloadLink = cd.PdfDownloadUrl;
System.debug('-----pdfDownloadLink: ' + pdfDownloadLink);
//---------------------------------------------------------------------------------------------
// variant 2 (не работает, выдает ошибку: Field is not writeable: ContentDistribution.ContentDocumentId)
ContentDocumentLink cdl = [
    SELECT contentdocument.id, contentdocument.title, contentdocument.filetype 
    FROM Contentdocumentlink 
    WHERE linkedentityid = 'a162w00000EL5sXAAT'
    LIMIT 1
];

System.debug('-----cdl.ContentDocumentId: ' + cdl.ContentDocumentId);

ContentDistribution cd = new ContentDistribution();
cd.ContentDocumentId = cdl.ContentDocumentId;
cd.Name = 'File Public Link (from ContentDocument)';
cd.PreferencesAllowViewInBrowser = true;
cd.PreferencesLinkLatestVersion = true;
insert cd;

cd = [
    SELECT Id, Name, ContentDocumentId, ContentVersionId, DistributionPublicUrl, PdfDownloadUrl, Password, ExpiryDate
    FROM ContentDistribution
    WHERE Id = :cd.Id
];
System.debug('-----cd: ' + cd);

String publicLink = cd.DistributionPublicUrl;
System.debug('-----publicLink: ' + publicLink);
String pdfDownloadLink = cd.PdfDownloadUrl;
System.debug('-----pdfDownloadLink: ' + pdfDownloadLink);
//---------------------------------------------------------------------------------------------
// get public link and set it to field
List<Id> accountIds = new List<Id>{'0012w0000247CYBAA2'};

List<ContentDocumentLink> cdLinks = [
    SELECT ContentDocumentId, LinkedEntityId, SystemModstamp
    FROM ContentDocumentLink
    WHERE LinkedEntityId IN :accountIds
    ORDER BY SystemModstamp DESC
];

System.debug('-----cdLinks: ' + cdLinks);

Map<Id, Id> lastCdIdByAccountIds = new Map<Id, Id>(); // Map<AccountId, ContentDocumentId>
for (ContentDocumentLink cdLink : cdLinks) {
    if (lastCdIdByAccountIds.get(cdLink.LinkedEntityId) == null) {
        lastCdIdByAccountIds.put(cdLink.LinkedEntityId, cdLink.ContentDocumentId);
    }
}
System.debug('-----lastCdIdByAccountIds: ' + lastCdIdByAccountIds);

List<ContentVersion> contentVersions = [
    SELECT Id, Title, VersionData, ContentDocumentId
    FROM ContentVersion
    WHERE IsLatest = TRUE
        AND ContentDocumentId IN :lastCdIdByAccountIds.values()
];

System.debug('-----contentVersions: ' + contentVersions);

Map<Id, ContentVersion> cvByCdIds = new Map<Id, ContentVersion>(); // Map<ContentDocumentId, ContentVersion>
for (ContentVersion cv : contentVersions) {
    cvByCdIds.put(cv.ContentDocumentId, cv);
}

System.debug('-----cvByCdIds: ' + cvByCdIds);

List<ContentDistribution> cDistribs = new List<ContentDistribution>();
for (Id accountId : lastCdIdByAccountIds.keySet()) {
    Id cdId = lastCdIdByAccountIds.get(accountId);
    Id cvId = cvByCdIds.get(cdId).Id;

    ContentDistribution cDistrib = new ContentDistribution();
    cDistrib.ContentVersionId = cvId;
    cDistrib.Name = 'File Public Link ' + cvId;
    cDistrib.PreferencesAllowViewInBrowser = true;
    cDistrib.PreferencesLinkLatestVersion = true;
    cDistribs.add(cDistrib);
}

insert cDistribs;

List<ContentDistribution> contentDistributions = [
    SELECT Id, Name, ContentDocumentId, ContentVersionId, DistributionPublicUrl, PdfDownloadUrl, Password, ExpiryDate
    FROM ContentDistribution
    WHERE Id IN :cDistribs
];
Map<Id, ContentDistribution> cDistribByCdIds = new Map<Id, ContentDistribution>(); // Map<ContentDocumentId, ContentDistribution>
for (ContentDistribution cDistrib : contentDistributions) {
    cDistribByCdIds.put(cDistrib.ContentDocumentId, cDistrib);
}

List<Account> accounsForUpdate = new List<Account>();
for (Id accountId : lastCdIdByAccountIds.keySet()) {
    Id cdId = lastCdIdByAccountIds.get(accountId);
    accounsForUpdate.add(new Account(
        Id = accountId,
        SendDocumentPublicLink__c = cDistribByCdIds.get(cdId).DistributionPublicUrl
    ));
}

update accounsForUpdate;



