#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

/*
The best advice I can offer when it comes to pointer management is to 
always keep track of how many bytes you have allocated and freed.
This will help you identify memory leaks and ensure that your program
is managing memory correctly. My favourite analogy is to think of memory 
allocation as akin to postage: the thing you post has weight, as does 
the thing you post it in. When discussing weight the term 'tare' is used 
to describe the weight of the empty container. In memory management terms, 
tare is the sizeof the data structure (e.g., struct Node), while the 
contents are the data being stored (e.g., struct Employee).
*/

static const bool verbose = false;  // set true for detailed allocation output

static size_t allocated_bytes = 0;  // tracking total allocated bytes

// generic node structure
struct Node {
    void *data;
    struct Node *next;
};

// custom employee structure
struct Employee {
    char *forename;
    char *lastname;
};

size_t employeeSize(void *data) {
    // custom function to calculate the size of an Employee structure
    struct Employee *employee = (struct Employee *)data;
    return sizeof(struct Employee) + strlen(employee->forename) + 1 + strlen(employee->lastname) + 1;
}

struct Node *createNode(void *data, size_t (*dataSize)(void *)) {

    // generic function to create a new Node 
    // using custom data size function

    struct Node *newNode = (struct Node *)malloc(sizeof(struct Node));

    newNode->data = data;

    newNode->next = NULL;

    allocated_bytes += sizeof(struct Node);

    if ( verbose )
        printf("createNode: tare - %zu data - %zu\n", 
            sizeof(struct Node), 
            dataSize(data)
        );

    return newNode;

}

struct Node *appendNode(struct Node *head, void *data) {

    // generic function to append a Node to the end 
    // of the list using custom data size function

    struct Node *newNode = createNode(data, employeeSize);

    if ( head == NULL ) {
        return newNode;
    }

    struct Node *current = head;

    while ( current->next != NULL ) {
        current = current->next;
    }

    current->next = newNode;

    return head;

}

void deleteNode(struct Node *node){

    // generic function to delete a Node

    allocated_bytes -= sizeof(struct Node);

    free(node);

    node = NULL;

}

void deleteNodeFromList(struct Node **head, void *data, void (*deleteData)(void *)) {

    // custom function to delete a Node from list
    // using custom data deletion function

    struct Node *current = *head;
    
    struct Node *prev = NULL;

    while ( current != NULL && current->data != data ) {
        prev = current;
        current = current->next;
    }

    if ( current == NULL ) {
        return;
    }

    if ( prev == NULL ) {
        *head = current->next;
    } else {
        prev->next = current->next;
    }

    if ( current->data != NULL )
        deleteData(current->data);

    deleteNode(current);

}

void lineOutput(void *data){
    // custom function to output formatted data
    printf("%s,%s -> ", ((struct Employee *)data)->lastname, ((struct Employee *)data)->forename);
}

void listOutput(void *data){
    // custom function to output formatted data
    printf("%s,%s\n", ((struct Employee *)data)->lastname, ((struct Employee *)data)->forename);
}

void printList(struct Node *head, void (*formatOutput)(void *)) {

    // generic function to print the list using custom formatting function

    struct Node *current = head;

    while ( current != NULL ) {
        formatOutput(current->data);
        current = current->next;
    }

    printf("NULL\n");

}

int employeeCompare(void *data1, void *data2) {

    // custom comparison function (sorting by lastname, forename)

    struct Employee *e1 = (struct Employee *)data1;
    struct Employee *e2 = (struct Employee *)data2;

    int lastNameComparison = strcmp(e1->lastname, e2->lastname);

    if ( lastNameComparison != 0 ) {
        return lastNameComparison;
    }

    return strcmp(e1->forename, e2->forename);

}

void sortList(struct Node **head, int (*compare)(void *, void *)) {

    // generic function to bubble sort linked 
    // list using custom comparison function

    struct Node *current = *head;

    while ( current != NULL ) {

        struct Node *nextNode = current->next;

        while ( nextNode != NULL ) {
            if ( compare(current->data, nextNode->data) > 0 ) {
                void *temp = current->data;
                current->data = nextNode->data;
                nextNode->data = temp;
            }
            nextNode = nextNode->next;
        }

        current = current->next;

    }

}

void deleteList(struct Node *head, void (*deleteData)(void *)) {

    // generic function to delete entire list 
    // using custom data deletion function

    struct Node *current = head;

    while ( current != NULL ) {

        struct Node *nextNode = current->next;

        if ( current->data != NULL )
            deleteData(current->data);

        deleteNode(current);

        current = nextNode;

    }

}

struct Employee* createEmployee(char *forename, char *lastname) {

    // custom function to create new Employee

    struct Employee* employee = malloc(sizeof(struct Employee));

    employee->forename = strdup(forename);
    employee->lastname = strdup(lastname);

    allocated_bytes += employeeSize(employee);

    if ( verbose )
        printf("createEmployee: %s %s tare - %zu data - %zu = %zu\n", 
            employee->forename, 
            employee->lastname,
            sizeof(struct Employee), 
            sizeof(employee->forename) + sizeof(employee->lastname), 
            employeeSize(employee)
        );

    return employee;

}

void deleteEmployee(void *data) {

    // custom function to delete an Employee

    struct Employee *employee = data;

    allocated_bytes -= sizeof(struct Employee) + strlen(employee->forename) + 1 + strlen(employee->lastname) + 1;

    free(employee->forename);
    
    free(employee->lastname);
    
    free(employee);

    data = NULL;

}

int main(void) {

    // main function to test the linked list implementation

    struct Node *head = NULL;

    printf("Starting list test\n");

    printf("size of pointer = %zu\n", sizeof(void *));

    printf("size of struct node = %zu\n", sizeof(struct Node));   

    printf("size of struct employee = %zu\n", sizeof(struct Employee));   

    printf("Allocated bytes at start: %zu\n", allocated_bytes);

    head = appendNode(head, createEmployee("Paul","McCartney"));
    printf("Allocated bytes after adding employee: %zu\n", allocated_bytes);

    appendNode(head, createEmployee("Ringo","Starr"));
    printf("Allocated bytes after adding employee: %zu\n", allocated_bytes);

    appendNode(head, createEmployee("John","Lennon"));
    printf("Allocated bytes after adding employee: %zu\n", allocated_bytes);

    appendNode(head, createEmployee("George","Harrison"));
    printf("Allocated bytes after adding employee: %zu\n", allocated_bytes);

    printf("List before sorting:\n");
    printList(head, listOutput);

    sortList(&head, employeeCompare);

    printf("List after sorting:\n");
    printList(head, listOutput);

    deleteNodeFromList(&head, head->data, deleteEmployee);

    printf("Allocated bytes after deleting head: %zu\n", allocated_bytes);

    printf("List after deleting head:\n");
    printList(head, listOutput);

    deleteList(head, deleteEmployee);

    printf("Allocated bytes at end: %zu\n", allocated_bytes);

    return 0;

}