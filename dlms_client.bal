
import ballerina/io;
import ballerina/lang.'int as ints;
import ballerina/http;

final http:Client clientEndpoint = check new ("http://localhost:9090/api/v1");

const BOOK = "BOOK";
const ELECTRONIC_RESOURCE = "ELECTRONIC_RESOURCE";
const PHYSICAL_SPACE = "PHYSICAL_SPACE";
const AVAILABLE = "AVAILABLE";
const LOANED_OUT = "LOANED_OUT";
const OCCUPIED = "OCCUPIED";
const UNDER_MAINTENANCE = "UNDER_MAINTENANCE";
const DISPOSED = "DISPOSED";
const ACTIVE = "ACTIVE";
const CLOSED = "CLOSED";
const MAINTENANCE = "MAINTENANCE";
const SERVICING = "SERVICING";
const BOOKING = "BOOKING";
const OPEN = "OPEN";
const PENDING = "PENDING";

type ResourceType BOOK|ELECTRONIC_RESOURCE|PHYSICAL_SPACE;
type ResourceStatus AVAILABLE|LOANED_OUT|OCCUPIED|UNDER_MAINTENANCE|DISPOSED;
type ScheduleType MAINTENANCE|SERVICING|BOOKING;
type TransactionStatus ACTIVE|CLOSED;
type WorkOrderStatus OPEN|CLOSED;
type TaskStatus PENDING|"COMPLETED";

type Component record {|
    string componentId;
    string name;
    string description;
|};

type Task record {|
    string taskId;
    string description;
    TaskStatus status;
|};

type WorkOrder record {|
    string workOrderId;
    string description;
    WorkOrderStatus status;
    string createdDate;
    Task[] tasks;
|};

type Schedule record {|
    string scheduleId;
    ScheduleType scheduleType;
    string dueDate;
    string description;
|};

type Transaction record {|
    string transactionId;
    string assetTag;
    string userName;
    string institution;
    string startDate;
    string dueDate;
    TransactionStatus status;
|};

type Resource record {|
    string assetTag;
    string name;
    string description;
    string institution;
    string site;
    string dateAcquired;
    ResourceStatus status;
    ResourceType resourceType;
    string? author = ();
    string? isbn = ();
    string? genre = ();
    string? category = ();
    string? serialNumber = ();
    string? spaceType = ();
    int? capacity = ();
    Component[] components = [];
    Schedule[] schedules = [];
    WorkOrder[] workOrders = [];
|};

function LoanOrBookAssetRequest() returns error? {
    io:println("");
    string transactionId = io:readln("Enter Transaction ID: ");
    string assetTag = io:readln("Enter Asset Tag to Loan/Book: ");
    string userName = io:readln("Enter User Name: ");
    string institution = io:readln("Enter User's Institution: ");
    string startDate = io:readln("Enter Start Date (YYYY-MM-DD): ");
    string dueDate = io:readln("Enter Due Date (YYYY-MM-DD): ");

    Transaction newTransaction = {
        transactionId: transactionId,
        assetTag: assetTag,
        userName: userName,
        institution: institution,
        startDate: startDate,
        dueDate: dueDate,
        status: ACTIVE
    };

    io:println("");
    io:println("Processing Loan/Booking...");
    io:println("===========================");
    json resp = check clientEndpoint->post("/transactions", newTransaction);
    io:println(resp.toJsonString());
    io:println("");
}

function ReturnOrEndBookingRequest() returns error? {
    io:println("");
    string transactionId = io:readln("Enter Transaction ID to Close: ");
    io:println("");
    io:println("Closing Transaction...");
    io:println("========================");
    json resp = check clientEndpoint->put("/transactions/" + transactionId + "/close", {});
    io:println(resp.toJsonString());
    io:println("");
}

function GlobalAssetViewRequest() returns error? {
    io:println("");
    json resp = check clientEndpoint->get("/resources");
    io:println("Global Asset List (All Institutions):");
    io:println("======================================");
    if resp is json[] {
        int count = 1;
        foreach json r in resp {
            io:println("Asset " + count.toString() + ":");
            io:println(r.toJsonString());
            io:println("");
            count = count + 1;
        }
    } else {
        io:println(resp.toJsonString());
    }
    io:println("");
}

function CampusViewRequest() returns error? {
    io:println("");
    io:println("Filter by: 1. Institution  2. Site/Campus");
    string choice = io:readln("Choose (1/2): ");

    json resp;
    if choice == "2" {
        string site = io:readln("Enter Site/Campus Name: ");
        resp = check clientEndpoint->get("/resources/site/" + site);
    } else {
        string institution = io:readln("Enter Institution Name: ");
        resp = check clientEndpoint->get("/resources/institution/" + institution);
    }

    io:println("");
    io:println("Campus/Institution Asset View:");
    io:println("===============================");
    io:println(resp.toJsonString());
    io:println("");
}

function OverdueDashboardRequest() returns error? {
    io:println("");
    io:println("===== Overdue Dashboard =====");

    io:println("");
    io:println("-- Overdue Maintenance/Servicing --");
    json maintenanceResp = check clientEndpoint->get("/resources/maintenance/overdue");
    io:println(maintenanceResp.toJsonString());

    io:println("");
    io:println("-- Overdue Loans/Bookings --");
    json transactionResp = check clientEndpoint->get("/transactions/overdue");
    io:println(transactionResp.toJsonString());
    io:println("");
}

function ScheduleTypeInput() returns ScheduleType {
    string input = io:readln("Enter Schedule Type (MAINTENANCE/SERVICING/BOOKING): ");
    if input == "SERVICING" {
        return SERVICING;
    } else if input == "BOOKING" {
        return BOOKING;
    }
    return MAINTENANCE;
}

function AddScheduleRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string scheduleId = io:readln("Enter Schedule ID: ");
    ScheduleType scheduleType = ScheduleTypeInput();
    string dueDate = io:readln("Enter Due Date (YYYY-MM-DD): ");
    string description = io:readln("Enter Description: ");

    Schedule newSchedule = {
        scheduleId: scheduleId,
        scheduleType: scheduleType,
        dueDate: dueDate,
        description: description
    };

    io:println("");
    io:println("Adding Schedule...");
    io:println("===================");
    json resp = check clientEndpoint->post("/resources/" + assetTag + "/schedules", newSchedule);
    io:println(resp.toJsonString());
    io:println("");
}

function ModifyScheduleRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string scheduleId = io:readln("Enter Schedule ID to Modify: ");
    ScheduleType scheduleType = ScheduleTypeInput();
    string dueDate = io:readln("Enter New Due Date (YYYY-MM-DD): ");
    string description = io:readln("Enter New Description: ");

    Schedule updatedSchedule = {
        scheduleId: scheduleId,
        scheduleType: scheduleType,
        dueDate: dueDate,
        description: description
    };

    io:println("");
    io:println("Modifying Schedule...");
    io:println("======================");
    json resp = check clientEndpoint->put("/resources/" + assetTag + "/schedules/" + scheduleId, updatedSchedule);
    io:println(resp.toJsonString());
    io:println("");
}

function RemoveScheduleRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string scheduleId = io:readln("Enter Schedule ID to Remove: ");
    io:println("");
    io:println("Removing Schedule...");
    io:println("======================");
    json resp = check clientEndpoint->delete("/resources/" + assetTag + "/schedules/" + scheduleId);
    io:println(resp.toJsonString());
    io:println("");
}

function readResourceType() returns ResourceType {
    string input = io:readln("Enter Resource Type (BOOK/ELECTRONIC_RESOURCE/PHYSICAL_SPACE): ");
    if input == "ELECTRONIC_RESOURCE" {
        return ELECTRONIC_RESOURCE;
    } else if input == "PHYSICAL_SPACE" {
        return PHYSICAL_SPACE;
    }
    return BOOK;
}

function readResourceStatus() returns ResourceStatus {
    string input = io:readln("Enter Status (AVAILABLE/LOANED_OUT/OCCUPIED/UNDER_MAINTENANCE/DISPOSED): ");
    if input == "LOANED_OUT" {
        return LOANED_OUT;
    } else if input == "OCCUPIED" {
        return OCCUPIED;
    } else if input == "UNDER_MAINTENANCE" {
        return UNDER_MAINTENANCE;
    } else if input == "DISPOSED" {
        return DISPOSED;
    }
    return AVAILABLE;
}

function CreateAssetRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag (must be unique): ");
    string name = io:readln("Enter Name: ");
    string description = io:readln("Enter Description: ");
    string institution = io:readln("Enter Institution: ");
    string site = io:readln("Enter Site/Campus: ");
    string dateAcquired = io:readln("Enter Date Acquired (YYYY-MM-DD): ");
    ResourceType resourceType = readResourceType();
    ResourceStatus status = readResourceStatus();

    Resource newResource = {
        assetTag: assetTag,
        name: name,
        description: description,
        institution: institution,
        site: site,
        dateAcquired: dateAcquired,
        status: status,
        resourceType: resourceType,
        author: (),
        isbn: (),
        genre: (),
        category: (),
        serialNumber: (),
        spaceType: (),
        capacity: (),
        components: [],
        schedules: [],
        workOrders: []
    };

    io:println("");
    io:println("Creating Asset...");
    io:println("==================");
    json resp = check clientEndpoint->post("/resources", newResource);
    io:println(resp.toJsonString());
    io:println("");
}

function UpdateAssetRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag to Update: ");
    string name = io:readln("Enter New Name: ");
    string description = io:readln("Enter New Description: ");
    string institution = io:readln("Enter New Institution: ");
    string site = io:readln("Enter New Site/Campus: ");
    string dateAcquired = io:readln("Enter New Date Acquired (YYYY-MM-DD): ");
    ResourceType resourceType = readResourceType();
    ResourceStatus status = readResourceStatus();

    Resource updated = {
        assetTag: assetTag,
        name: name,
        description: description,
        institution: institution,
        site: site,
        dateAcquired: dateAcquired,
        status: status,
        resourceType: resourceType,
        author: (),
        isbn: (),
        genre: (),
        category: (),
        serialNumber: (),
        spaceType: (),
        capacity: (),
        components: [],
        schedules: [],
        workOrders: []
    };

    io:println("");
    io:println("Updating Asset...");
    io:println("==================");
    json resp = check clientEndpoint->put("/resources/" + assetTag, updated);
    io:println(resp.toJsonString());
    io:println("");
}

function DeleteAssetRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag to Delete: ");
    io:println("");
    io:println("Deleting Asset...");
    io:println("==================");
    json|string resp = check clientEndpoint->delete("/resources/" + assetTag);
    io:println(resp.toJsonString());
    io:println("");
}

function GetSingleAssetRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    json|string resp = check clientEndpoint->get("/resources/" + assetTag);
    io:println("Asset Details:");
    io:println("==============");
    io:println(resp.toJsonString());
    io:println("");
}



function OpenWorkOrderRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string workOrderId = io:readln("Enter Work Order ID: ");
    string description = io:readln("Enter Description (e.g. 'replace screen'): ");
    string createdDate = io:readln("Enter Created Date (YYYY-MM-DD): ");

    WorkOrder newWorkOrder = {
        workOrderId: workOrderId,
        description: description,
        status: OPEN,
        createdDate: createdDate,
        tasks: []
    };

    io:println("");
    io:println("Opening Work Order...");
    io:println("======================");
    json resp = check clientEndpoint->post("/resources/" + assetTag + "/workorders", newWorkOrder);
    io:println(resp.toJsonString());
    io:println("");
}

function CloseWorkOrderRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string workOrderId = io:readln("Enter Work Order ID to Close: ");
    io:println("");
    io:println("Closing Work Order...");
    io:println("======================");
    json resp = check clientEndpoint->put("/resources/" + assetTag + "/workorders/" + workOrderId + "/close", {});
    io:println(resp.toJsonString());
    io:println("");
}

function AddTaskRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string workOrderId = io:readln("Enter Work Order ID: ");
    string taskId = io:readln("Enter Task ID: ");
    string description = io:readln("Enter Task Description: ");

    Task newTask = {
        taskId: taskId,
        description: description,
        status: PENDING
    };

    io:println("");
    io:println("Adding Task...");
    io:println("==============");
    json resp = check clientEndpoint->post(
        "/resources/" + assetTag + "/workorders/" + workOrderId + "/tasks", newTask);
    io:println(resp.toJsonString());
    io:println("");
}

function AddComponentRequest() returns error? {
    io:println("");
    string assetTag = io:readln("Enter Asset Tag: ");
    string componentId = io:readln("Enter Component ID: ");
    string name = io:readln("Enter Component Name: ");
    string description = io:readln("Enter Component Description: ");

    Component newComponent = {
        componentId: componentId,
        name: name,
        description: description
    };

    io:println("");
    io:println("Adding Component...");
    io:println("====================");
    json resp = check clientEndpoint->post("/resources/" + assetTag + "/components", newComponent);
    io:println(resp.toJsonString());
    io:println("");
}

public function clientMain() returns error? {
    boolean cont = true;

    while cont {
        io:println("===== Distributed Library Management System =====");
        io:println("1. Loan an Asset / Book a Room or Lab");
        io:println("2. Return / End a Loan or Booking");
        io:println("3. Global Asset View (all institutions)");
        io:println("4. Campus View (filter by institution/site)");
        io:println("5. Overdue Dashboard (maintenance + loans)");
        io:println("6. Add Servicing/Maintenance Schedule");
        io:println("7. Modify Schedule");
        io:println("8. Remove Schedule");
        io:println("--- Asset CRUD ---");
        io:println("9. Get a Single Asset");
        io:println("10. Create Asset");
        io:println("11. Update Asset");
        io:println("12. Delete Asset");
        io:println("--- Work Orders & Components ---");
        io:println("13. Open Work Order");
        io:println("14. Close Work Order");
        io:println("15. Add Task to Work Order");
        io:println("16. Add Component to Asset");

        string ans = io:readln("Which Option Would you like: ");
        io:println("");

        int|error res1 = ints:fromString(ans);
        if res1 is error {
            io:println("Please enter a valid number");
            continue;
        }

        if res1 == 1 {
            _ = check LoanOrBookAssetRequest();
        } else if res1 == 2 {
            _ = check ReturnOrEndBookingRequest();
        } else if res1 == 3 {
            _ = check GlobalAssetViewRequest();
        } else if res1 == 4 {
            _ = check CampusViewRequest();
        } else if res1 == 5 {
            _ = check OverdueDashboardRequest();
        } else if res1 == 6 {
            _ = check AddScheduleRequest();
        } else if res1 == 7 {
            _ = check ModifyScheduleRequest();
        } else if res1 == 8 {
            _ = check RemoveScheduleRequest();
        } else if res1 == 9 {
            _ = check GetSingleAssetRequest();
        } else if res1 == 10 {
            _ = check CreateAssetRequest();
        } else if res1 == 11 {
            _ = check UpdateAssetRequest();
        } else if res1 == 12 {
            _ = check DeleteAssetRequest();
        } else if res1 == 13 {
            _ = check OpenWorkOrderRequest();
        } else if res1 == 14 {
            _ = check CloseWorkOrderRequest();
        } else if res1 == 15 {
            _ = check AddTaskRequest();
        } else if res1 == 16 {
            _ = check AddComponentRequest();
        } else {
            io:println("Please pick a number from 1-16");
        }

        string answer1 = io:readln("Do you want to call another function? y/n: ");
        if answer1 != "y" {
            cont = false;
        }
    }
}
