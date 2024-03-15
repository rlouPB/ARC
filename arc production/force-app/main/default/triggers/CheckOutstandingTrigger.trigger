trigger CheckOutstandingTrigger on Check_Outstanding__e (after insert) {
    OutstandingItems.checkOutstandingItems(Trigger.new);
}