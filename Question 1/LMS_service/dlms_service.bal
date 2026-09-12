import ballerina/http;
import ballerina/time;

map<Resource> resourceStore = {};
map<Transaction> transactionStore = {};

function today() returns string {
    return time:utcToString(time:utcNow()).substring(0, 10);
}

service /api/v1 on new http:Listener(9090) {

    resource function get resources() returns Resource[] {
        return resourceStore.toArray();
    }

    resource function get resources/[string assetTag]() returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        return r is Resource ? r : http:NOT_FOUND;
    }

    resource function post resources(@http:Payload Resource newResource) returns Resource|http:Conflict {
        if resourceStore.hasKey(newResource.assetTag) {
            return http:CONFLICT;
        }
        resourceStore[newResource.assetTag] = newResource;
        return newResource;
    }

    resource function put resources/[string assetTag](@http:Payload Resource updated) returns Resource|http:NotFound {
        if !resourceStore.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function delete resources/[string assetTag]() returns http:Ok|http:NotFound {
        if !resourceStore.hasKey(assetTag) {
            return http:NOT_FOUND;
        }
        _ = resourceStore.remove(assetTag);
        return http:OK;
    }

    resource function get resources/institution/[string institution]() returns Resource[] {
        return resourceStore.toArray().filter(r => r.institution == institution);
    }

    resource function get resources/site/[string site]() returns Resource[] {
        return resourceStore.toArray().filter(r => r.site == site);
    }

    resource function get resources/'type/[string resourceType]() returns Resource[] {
        return resourceStore.toArray().filter(r => r.resourceType.toString() == resourceType);
    }

    resource function get resources/status/[string status]() returns Resource[] {
        return resourceStore.toArray().filter(r => r.status.toString() == status);
    }

    resource function get resources/maintenance/overdue() returns Resource[] {
        string todayStr = today();
        return resourceStore.toArray().filter(r => isMaintenanceOverdue(r, todayStr));
    }

    resource function get transactions/overdue() returns Transaction[] {
        string todayStr = today();
        return transactionStore.toArray()
            .filter(t => t.status != COMPLETED && t.dueDate < todayStr);
    }

    resource function post resources/[string assetTag]/components(@http:Payload Component newComponent)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        updated.components.push(newComponent);
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function delete resources/[string assetTag]/components/[string componentId]()
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        updated.components = updated.components.filter(c => c.componentId != componentId);
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function post resources/[string assetTag]/schedules(@http:Payload Schedule newSchedule)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        updated.schedules.push(newSchedule);
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function put resources/[string assetTag]/schedules/[string scheduleId](@http:Payload Schedule updatedSchedule)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        Schedule[] newSchedules = [];
        foreach Schedule s in updated.schedules {
            newSchedules.push(s.scheduleId == scheduleId ? updatedSchedule : s);
        }
        updated.schedules = newSchedules;
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function delete resources/[string assetTag]/schedules/[string scheduleId]()
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        updated.schedules = updated.schedules.filter(s => s.scheduleId != scheduleId);
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function post resources/[string assetTag]/workorders(@http:Payload WorkOrder newWorkOrder)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        updated.workOrders.push(newWorkOrder);
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function put resources/[string assetTag]/workorders/[string workOrderId](@http:Payload WorkOrder updatedWorkOrder)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        WorkOrder[] newWorkOrders = [];
        foreach WorkOrder w in updated.workOrders {
            newWorkOrders.push(w.workOrderId == workOrderId ? updatedWorkOrder : w);
        }
        updated.workOrders = newWorkOrders;
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function put resources/[string assetTag]/workorders/[string workOrderId]/close()
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        WorkOrder[] newWorkOrders = [];
        foreach WorkOrder w in updated.workOrders {
            if w.workOrderId == workOrderId {
                WorkOrder closed = w.clone();
                closed.status = CLOSED;
                newWorkOrders.push(closed);
            } else {
                newWorkOrders.push(w);
            }
        }
        updated.workOrders = newWorkOrders;
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function post resources/[string assetTag]/workorders/[string workOrderId]/tasks(@http:Payload Task newTask)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        WorkOrder[] newWorkOrders = [];
        foreach WorkOrder w in updated.workOrders {
            if w.workOrderId == workOrderId {
                WorkOrder w2 = w.clone();
                w2.tasks.push(newTask);
                newWorkOrders.push(w2);
            } else {
                newWorkOrders.push(w);
            }
        }
        updated.workOrders = newWorkOrders;
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function put resources/[string assetTag]/workorders/[string workOrderId]/tasks/[string taskId](@http:Payload Task updatedTask)
            returns Resource|http:NotFound {
        Resource? r = resourceStore[assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        Resource updated = r.clone();
        WorkOrder[] newWorkOrders = [];
        foreach WorkOrder w in updated.workOrders {
            if w.workOrderId == workOrderId {
                WorkOrder w2 = w.clone();
                Task[] newTasks = [];
                foreach Task t in w2.tasks {
                    newTasks.push(t.taskId == taskId ? updatedTask : t);
                }
                w2.tasks = newTasks;
                newWorkOrders.push(w2);
            } else {
                newWorkOrders.push(w);
            }
        }
        updated.workOrders = newWorkOrders;
        resourceStore[assetTag] = updated;
        return updated;
    }

    resource function get transactions() returns Transaction[] {
        return transactionStore.toArray();
    }

    resource function get transactions/[string id]() returns Transaction|http:NotFound {
        Transaction? t = transactionStore[id];
        return t is Transaction ? t : http:NOT_FOUND;
    }

    resource function post transactions(@http:Payload Transaction newTransaction)
            returns Transaction|http:NotFound|http:Conflict {
        Resource? r = resourceStore[newTransaction.assetTag];
        if r is () {
            return http:NOT_FOUND;
        }
        if r.status != AVAILABLE {
            return http:CONFLICT;
        }
        if transactionStore.hasKey(newTransaction.transactionId) {
            return http:CONFLICT;
        }

        transactionStore[newTransaction.transactionId] = newTransaction;

        Resource updatedResource = r.clone();
        updatedResource.status = r.resourceType == PHYSICAL_SPACE ? OCCUPIED : LOANED_OUT;
        resourceStore[r.assetTag] = updatedResource;

        return newTransaction;
    }

    resource function put transactions/[string id]/close() returns Transaction|http:NotFound {
        Transaction? t = transactionStore[id];
        if t is () {
            return http:NOT_FOUND;
        }

        Transaction updated = t.clone();
        updated.status = COMPLETED;
        transactionStore[id] = updated;

        Resource? r = resourceStore[t.assetTag];
        if r is Resource {
            Resource updatedResource = r.clone();
            updatedResource.status = AVAILABLE;
            resourceStore[r.assetTag] = updatedResource;
        }

        return updated;
    }
}

function isMaintenanceOverdue(Resource r, string todayStr) returns boolean {
    foreach Schedule s in r.schedules {
        if (s.scheduleType == MAINTENANCE || s.scheduleType == SERVICING) && s.dueDate < todayStr {
            return true;
        }
    }
    return false;
}
