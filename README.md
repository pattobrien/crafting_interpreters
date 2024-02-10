# dlox

A lox interpreter written in Dart.

## Bookmarks

- 5.3.2
- 6.1
- 6.3.1
- chapter 7: https://craftinginterpreters.com/evaluating-expressions.html
- 8.1
- 8.2
- 9.2: Conditional Execution
- 9.3: Logical Operators
- 9.4: While loops

## Notes

### 8. Statements and State

#### AssignmentExpressions

```dart
var x = 123;
x = 234; // AssignmentExpression(token: x, value: 234)
```

Assignment expressions are more complex than other expressions because the left part of the expression is not an "expression", as is typically expected by a binary expression like `1 + 1`; it's simply a token, that needs to be used once the parser gets to the `=` token. See (8.4.1)[https://craftinginterpreters.com/statements-and-state.html#assignment-syntax]

#### Dangling Else Problem

see: https://craftinginterpreters.com/control-flow.html#conditional-execution

```
if (first) if (second) whenTrue(); else whenFalse();
```

The problem relates to the ambiguity of the `else` statement, and whether it belongs to the first or second `if` statement.

NOTE: most langs choose to use the same interpretation: the else is bound to the nearest if that precedes it.

## Notes for a "Dream" PL

- pattern matching
- meta programming syntax
