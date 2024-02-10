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
- 10: Functions <- ended at the start of this section

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

#### For Loops are Syntactic Sugar

The for loop:

```
for (var i = 0; i < 10; i = i + 1) print i;
```

...can be written like:

```
{
  var i = 0;
  while (i < 10) {
    print i;
    i = i + 1;
  }
}
```

Excerpts from the book: "This script has the exact same semantics as the previous one, though it’s not as easy on the eyes. Syntactic sugar features like Lox’s for loop make a language more pleasant and productive to work in. But, especially in sophisticated language implementations, every language feature that requires back-end support and optimization is expensive.

We can have our cake and eat it too by desugaring. That funny word describes a process where the front end takes code using syntax sugar and translates it to a more primitive form that the back end already knows how to execute."

NOTE: The implementation of the for statement sugar means that we don't implement a separate AstNode for a `ForStatement`, and therefore don't implement a separate visit method in the Interpreter. All we do is implement a method in the `Parser` that handles the `desugaring` (see: `Parser.parseForStatement`).

## Notes for a "Dream" PL

- pattern matching
- meta programming syntax
