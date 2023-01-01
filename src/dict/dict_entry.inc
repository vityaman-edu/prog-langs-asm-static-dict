; dict_entry.inc

%define NULL 0

%macro dict_entry 2

  %ifnstr %1
    %fatal 'Dict node key must be a string'
  %endif
  
  %ifnid %2
    %fatal 'Dict node value must be a label'
  %endif

  %ifndef LAST_ADDED_NODE
    %%next: db NULL
  %else
    %%next: db LAST_ADDED_NODE
  %endif
  ; as `next` is the first element of struct 
  ; Node(next, key, value) it is also node pointer
  %define LAST_ADDED_NODE %%next  
  
  db %%key_string
  db %2
  
  %%key_string: db %1, 0
  %2: 
  ; expect on the next line for example 
  ; db "some string value value", 0  

%endmacro
