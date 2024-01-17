//---------------------------------------------------------------------------------------------
// Delete all TestObject__c records for Mid-Term Solution_2
String midTermSolutionTwoPattern = 'Mid-Term Solution_2';
String testObjectNamesForDelete = midTermSolutionTwoPattern + '%';
List<TestObject__c> midTermSolutionTwoTestObjectsForDelete = [
    SELECT Id
    FROM TestObject__c
    WHERE Name LIKE :testObjectNamesForDelete
];
delete midTermSolutionTwoTestObjectsForDelete;
//---------------------------------------------------------------------------------------------
// Create TestObject__c records for Mid-Term Solution_2
String midTermSolutionTwoPattern = 'Mid-Term Solution_2';
Integer testObjectAmount = 2;
List<TestObject__c> midTermSolutionTwoTestObjects = new List<TestObject__c>();
for(Integer i = 0; i < testObjectAmount; i++) {
    midTermSolutionTwoTestObjects.add(
        new TestObject__c(
            Name = midTermSolutionTwoPattern + ' r' + i
        )
    );
}
insert midTermSolutionTwoTestObjects;

//---------------------------------------------------------------------------------------------
// Update TextField__c to null for all TestObject__c records for Mid-Term Solution_2
String testObjectNamesForUpdatePattern = 'Mid-Term Solution_2%';
List<TestObject__c> midTermSolutionTwoTestObjectsUpdate = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name LIKE :testObjectNamesForUpdatePattern
];
for(TestObject__c testObject : midTermSolutionTwoTestObjectsUpdate) {
    testObject.TextField__c = null;
}
update midTermSolutionTwoTestObjectsUpdate;

// Update TextField__c to 'Attachment: 1' for all TestObject__c records for Mid-Term Solution_2
String testObjectNamesForUpdatePattern1 = 'Mid-Term Solution_2%';
List<TestObject__c> midTermSolutionTwoTestObjectsUpdate1 = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name LIKE :testObjectNamesForUpdatePattern1
];
for(Integer i = 0; i < midTermSolutionTwoTestObjectsUpdate1.size(); i++) {
    TestObject__c testObject = midTermSolutionTwoTestObjectsUpdate1.get(i);
    testObject.TextField__c = 'Attachment: 1';
    testObject.NumberField__c = i * 3;
}
update midTermSolutionTwoTestObjectsUpdate1;
//---------------------------------------------------------------------------------------------

TestObject__c testObject = new TestObject__c(Name = 'TestString', TextField__c = '\s');
insert testObject;
System.debug('-----1-----' + testObject.TextField__c + '-----');
TestObject__c testObjectAfterSelect = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Id = :testObject.Id
];
System.debug('-----2-----' + testObjectAfterSelect.TextField__c + '-----');