# Copilot Instructions for SF User Sync

## Project Overview
This is a Salesforce DX project for synchronizing external user data. The core functionality revolves around the `External_User__c` custom object and bulk data operations.

## Key Architecture Patterns

### Data Transfer Objects (DTOs)
- Use `ExternalUserDTO` nested class pattern in services for LWC/Aura compatibility
- All DTO fields are `@AuraEnabled` for Lightning component consumption
- DTOs serve as the API contract between Apex services and frontend components

### External ID Pattern
- `External_User__c` object uses `External_User_Id__c` as the external ID field
- Always use `upsert` operations with external ID for data synchronization
- External ID is required - operations skip records without valid external IDs
- Minimal field set: External ID, Email, FirstName, LastName, Phone, Deleted flag

### Service Layer Architecture
- Services follow naming convention: `[Entity]Service` (e.g., `ExternalUserService`)
- Use `with sharing` for all service classes to respect field-level security
- Static methods for stateless operations, return Lists of IDs for bulk operations

## Code Conventions

### Apex Classes
- Place all Apex classes in `force-app/main/default/classes/`
- Each class requires a corresponding `.cls-meta.xml` file
- Use API version 47.0+ consistently (check existing meta files for current standard)
- Null-safe programming: check for null/empty collections before processing

### Field Mapping Patterns
```apex
// Pattern for DTO to sObject mapping
External_User__c eu = new External_User__c();
eu.External_User_Id__c = r.externalId;           // External ID (required)
eu.Email__c           = r.email;                 // Direct mapping
eu.FirstName__c       = r.firstName;             // Direct mapping
eu.LastName__c        = r.lastName;              // Direct mapping
eu.Phone__c           = r.phone;                 // Direct mapping
eu.Deleted__c         = r.deleted == null ? false : r.deleted; // Default handling
```

### Bulk Operations
- Always process collections, never single records
- Use `upsert` with external ID field specification: `upsert records External_Field__c;`
- Return `List<Id>` from service methods for downstream processing
- Extract IDs using: `new List<Id>(new Map<Id, SObject>(records).keySet())`

## Development Workflow

### File Structure
- Apex classes: `force-app/main/default/classes/`
- LWC components: `force-app/main/default/lwc/` (uses Salesforce ESLint config)
- Custom objects: `force-app/main/default/objects/` (currently empty - objects deployed separately)

### Testing Approach
- Each service class should have comprehensive test coverage
- Test bulk operations with both valid and invalid data
- Verify external ID upsert behavior (create vs update scenarios)

## Integration Points

### Custom Objects
The project references `External_User__c` with these minimal fields:
- `External_User_Id__c` - External ID field for upserts
- `Email__c`, `FirstName__c`, `LastName__c`, `Phone__c` - Standard contact fields
- `Deleted__c` - Boolean flag for soft deletes

### Lightning Web Components
- DTOs are designed for LWC consumption (`@AuraEnabled` annotations)
- ESLint configuration extends Salesforce LWC recommended rules
- Components should call service methods for all data operations