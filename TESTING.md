# VDOM Testing Guide

## Running the Application

The app is already running with two servers:

### ReScript Watcher
Monitors `src/*.res` files and compiles them to JavaScript automatically.
```bash
npm run dev:res
```

### Vite Dev Server
Serves the application at `http://localhost:5173/`
```bash
npm run dev
```

## Testing the Diff Application

### What You'll See:
1. **Initial Counter App** - Displays:
   - "Counter App" heading
   - "Increment" button
   - "Count: 0" paragraph

2. **Apply Diff Button** - Green button below the counter app

3. **Click "Apply Diff"** - This will:
   - Update the heading to "Counter App - Updated"
   - Change the text color to blue
   - Update the count from 0 to 1
   - Add a style attribute with `color: blue;`

### How It Works:

```rescript
// Step 1: Initial VDOM is created and rendered
let initialVdom = Vdom.h("div", ~properties=..., [
  Vdom.h("h1", [Vdom.text("Counter App")]),
  Vdom.h("button", ...),
  Vdom.h("p", [Vdom.text("Count: 0")]),
])
let domElement = Vdom.create(initialVdom)
Element.appendChild(app, domElement)

// Step 2: Updated VDOM is defined (not rendered yet)
let updatedVdom = Vdom.h("div", ~properties=..., [
  Vdom.h("h1", [Vdom.text("Counter App - Updated")]),
  Vdom.h("button", ...),
  Vdom.h("p", [Vdom.text("Count: 1")]),
])

// Step 3: When "Apply Diff" button is clicked:
// - Compute the diff between initial and updated
let diff = Vdom.diffOne(initialVdom, updatedVdom)

// - Apply only the changes to the existing DOM
Vdom.modify(elem, ~remove=modifyData.remove, ~set=modifyData.set)
```

### Console Output:

When you click "Apply Diff", you'll see in the browser console:
```
Applying diff...
Modifying element...
Diff applied successfully!
```

## Browser Console

Open DevTools (F12) to see:
- Console logs from the application
- DOM changes as they happen
- Any errors that occur

## Files

- `src/test.res` - Main test demonstrating VDOM with diff application
- `src/vdom.res` - Core VDOM implementation (diffOne, create, modify, apply)
- `src/listeners.res` - Event listener management
- `src/properties.res` - Property/attribute handling
- `index.html` - Entry point for the web app
