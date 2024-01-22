List<TestObject__c> families = new List<TestObject__c>();
for (Integer i = 0; i < 500; i++) {
    TestObject__c family = new TestObject__c(Name = 'Test SOQL for loop ' + i);
    families.add(family);
}
insert families;

for (TestObject__c testObject : [SELECT Id FROM TestObject__c]) {
    testObject.TextField__c = 'some text';
}

List<TestObject__c> testObjectsForDelete = [SELECT Id FROM TestObject__c WHERE Name LIKE 'Test SOQL for loop %'];
delete testObjectsForDelete;
