trigger TestObjectTrigger on TestObject__c (after update) {
    new TestObjectTriggerHandler().run();
}