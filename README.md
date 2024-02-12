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
- 10: Functions
- 10.5: Return Statements
- 11: Resolving and Binding
- 12: Classes
- 14: JVM <- we are at the beginning of this section

## Notes

### 2. Map of the Territory

The `Front End` of the implementation (i.e. everything to do with the source language):

- 1. Scanner
- 2. Parser - Takes a flat list of tokens and generates nested ASTNodes (i.e. an Abstract Syntax Tree)
- 3. Static Analysis - resolve and bind variable/class/function identifiers to their definitions

  - this includes defining Scopes
  - note: this is where we would also type-check in a statically typed language

- `Intermediate Representations` (acts as an interface between the source and destination languages):
- Optimization
- Code generation
- Virtual machine
- Runtime

Sections 3->13 create a `Tree-walk interpreter` using Dart.

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

### OOP and Classes

There are three broad paths to object-oriented programming: classes, prototypes, and multimethods.

### Variable Resolution

Local variables (e.g. in nested block bodies) are resolved to the proper scope statically, via the [Resolver] visitor class. We through a compile-time error if a variable is not initialized properly, which for Lox only happens if there is already a variable with the same name in the current scope.

### Method References

see: https://craftinginterpreters.com/classes.html#methods-on-classes

In the below code, should `bill.sayName` print `Bill` or `Jane`?

```
class Person {
  sayName() {
    print this.name;
  }
}

var jane = Person();
jane.name = "Jane";

var bill = Person();
bill.name = "Bill";

bill.sayName = jane.sayName;
bill.sayName(); // ?
```

In practice, you typically want to bind `sayName` to the _original instance_ that the referenced method was bound to.

### Class Constructors

Excerpts from the book (regarding constructors):

"I find them one of the trickiest parts of a language to design, and if you peer closely at most other languages, you’ll see cracks around object construction where the seams of the design don’t quite fit together perfectly. Maybe there’s something intrinsically messy about the moment of birth."

"Languages have a variety of notations for the chunk of code that sets up a new object for a class. C++, Java, and C# use a method whose name matches the class name. Ruby and Python call it init()."

## Notes for a "Dream" PL

- pattern matching
- meta programming syntax
- first-class functions
- nested functions
- closures
- classes
- static typing
- static method dispatch
- a good amount of type inference capabilities
- null safety
- no `fun` keyword
- for-in loop
- extension methods (?)
