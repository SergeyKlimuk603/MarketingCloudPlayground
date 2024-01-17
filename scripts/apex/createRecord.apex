//---------------------------------------------------------------------------------------------
// Delete all TestObject__c records for Mid-Term Solution_2
List<TestObject__c> midTermSolutionTwoTestObjectsForDelete = [
    SELECT Id
    FROM TestObject__c
    WHERE Name = 'Mid-Term Solution_2'
];
delete midTermSolutionTwoTestObjectsForDelete;
//---------------------------------------------------------------------------------------------
// Create TestObject__c record for Mid-Term Solution_2

insert new TestObject__c(
    Name = 'Mid-Term Solution_2',
    EmailField__c = 'sergeyklimuk79@gmail.com'
);
// sergeyklimuk79@gmail.com
// siarhei_klimuk@senla.eu
// sergey_klimuk@mail.ru


//---------------------------------------------------------------------------------------------
// Update TextField__c to null for all TestObject__c records for Mid-Term Solution_2
TestObject__c testObject = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name = 'Mid-Term Solution_2'
    LIMIT 1
];

testObject.TextField__c = null;

update testObject;

// Update TextField__c to 'Attachment: 1' for all TestObject__c records for Mid-Term Solution_2
TestObject__c testObject1 = [
    SELECT Id, TextField__c, NumberField__c
    FROM TestObject__c
    WHERE Name = 'Mid-Term Solution_2'
    LIMIT 1
];

testObject1.TextField__c = 'Attachment: 1';
testObject1.TextAreaField__c = 'Record was updated from anonimus';
testObject1.NumberField__c = 6;

update testObject1;
//---------------------------------------------------------------------------------------------
