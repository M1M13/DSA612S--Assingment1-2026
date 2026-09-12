// Resource types and statuses 

public enum ResourceType {
    BOOK,
    ELECTRONIC_RESOURCE,
    PHYSICAL_SPACE
}

public enum ResourceStatus {
    AVAILABLE,
    LOANED_OUT,       
    OCCUPIED,          
    UNDER_MAINTENANCE,
    DISPOSED
}


public enum TransactionStatus {
    ACTIVE,
    OVERDUE,
    COMPLETED
}

public type Transaction record {
    string transactionId;
    string assetTag;            
    string userName;
    string institution;        
    string startDate;           
    string dueDate;            
    TransactionStatus status;
};

public type Component record {
    string componentId;
    string name;
    string description;
};

public enum ScheduleType {
    MAINTENANCE,
    SERVICING,
    BOOKING
}

public type Schedule record {
    string scheduleId;
    ScheduleType scheduleType;
    string dueDate;
    string description;
};

public enum WorkOrderStatus {
    OPEN,
    IN_PROGRESS,
    CLOSED
}

public enum TaskStatus {
    PENDING,
    IN_PROGRESS,
    COMPLETED
}

public type Task record {
    string taskId;
    string description;
    TaskStatus status;
};

public type WorkOrder record {
    string workOrderId;
    string description;
    WorkOrderStatus status;
    string createdDate;
    Task[] tasks;
};
public type Resource record {
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    string dateAcquired;
    ResourceStatus status;
    ResourceType resourceType;

    string? author;
    string? isbn;
    string? genre;

    string? category;
    string? serialNumber;

    string? spaceType;
    int? capacity;

    Component[] components;
    Schedule[] schedules;
    WorkOrder[] workOrders;
};
