# Assignment №2:  Dictionary in assembly

## Диздок словаря

### Интерфейс
- `dict_find_node_with_key` - функция, находит на пару `(key, value)` по ключу,
                         принимает ссылку на словарь и ключ,
                         возвращает ссылку на пару или NULL, если ключ не найден
- `dict_entry`         - макрос, принимает ключ и значение, добавляет к словарю новое 
                         значение

### Реализация 

В основе будет лежать связный список пар `(key, value)`, где `key`, `value` - нуль-терминированные строки.  
Структура связного списка: `Node(next: Node*, key: char*, value: char*)`.
Если `node` - первая нода словаря и `node.next == nullptr`, то текущая нода последняя в словаре, 
если `node == nullptr`, то словарь пуст. 

Сама нода будет упакована в памяти таким образом:
```asm
node:
  .next_node:    db ADDRESS_OR_NULL
  .key_string:   db KEY
  .value_string: db VALUE
```
Для работы с ней реализую геттеры:
- `dict_node_get_next`
- `dict_node_get_key`
- `dict_node_get_value`

