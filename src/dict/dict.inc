; dict.lib 
section .text

; Find Dict::Node* with given key in given dict instance
; pred: rdi: Dict* - dict instance pointer
;       rsi: char* - search key
; post: rax: Dict::Node* - dict node a such that a.key is equal to given key
extern dict_find_entry_by_key

; Get Dict::Node::next pointer value
; pred: rdi: Dict::Node* - node instance pointer
; post: rax: Dict::Node* - node.next value 
extern dict_node_get_next

; Get Dict::Node::key pointer value
; pred: rdi: Dict::Node* - node instance pointer
; post: rax: Dict::char* - node.key value
extern dict_node_get_key

; Get Dict::Node::key pointer value
; pred: rdi: Dict::Node* - node instance pointer
; post: rax: Dict::char* - node.value value
extern dict_node_get_value
