open WebAPI
open Document

// Test the VDOM implementation
let () = {
  // Get the app container
  let app = document->getElementById("app")
  
  // Mutable ref to store the current vdom
  let currentVdom = ref(None)
  
  // Create initial VDOM
  let initialVdom = Vdom.h(
    "div",
    ~properties=dict{
      "id": "counter"->Obj.magic,
      "class": "container"->Obj.magic,
    },
    [
      Vdom.h("h1", [Vdom.text("Counter App")]),
      Vdom.h(
        "button",
        ~properties=dict{
          "onClick": ((_event: EventAPI.event) => {
            Console.log("Increment button clicked!")
          })->Obj.magic,
        },
        [Vdom.text("Increment")],
      ),
      Vdom.h("p", [Vdom.text("Count: 0")]),
    ],
  )

  // Create the DOM element
  let domElement = Vdom.create(initialVdom)
  
  // Append to the app container
  let _ = Element.appendChild(app, domElement)
  
  // Store the current vdom
  currentVdom := Some(initialVdom)

  // Create updated VDOM
  let updatedVdom = Vdom.h(
    "div",
    ~properties=dict{
      "id": "counter"->Obj.magic,
      "class": "container"->Obj.magic,
      "style": "color: blue;"->Obj.magic,
    },
    [
      Vdom.h("h1", [Vdom.text("Counter App - Updated")]),
      Vdom.h(
        "button",
        ~properties=dict{
          "onClick": ((_event: EventAPI.event) => {
            Console.log("Increment button clicked!")
          })->Obj.magic,
        },
        [Vdom.text("Increment")],
      ),
      Vdom.h("p", [Vdom.text("Count: 1")]),
    ],
  )

  // Create click handler for apply diff button
  let applyDiffHandler = (_event: EventAPI.event) => {
    Console.log("Applying diff...")
    switch currentVdom.contents {
    | None => Console.error("Current vdom not found!")
    | Some(current) => 
      let diff = Vdom.diffOne(current, updatedVdom)
      
      switch diff {
      | Vdom.Modify(modifyData) => 
        // Get the root element that was created
        let rootElement = app->Element.querySelector("div#counter")
        switch Null.toOption(rootElement) {
        | Some(elem) => {
            Console.log("Modifying element...")
            Vdom.modify(elem, ~remove=modifyData.remove, ~set=modifyData.set)
            // Update the stored vdom
            currentVdom := Some(updatedVdom)
            Console.log("Diff applied successfully!")
          }
        | None => Console.error("Root element not found!")
        }
      | _ => Console.log("No modifications needed")
      }
    }
  }

  // Create "Apply Diff" button as VDOM
  let applyDiffButton = Vdom.h(
    "button",
    ~properties=dict{
      "style": "margin-top: 20px; padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-size: 16px;"->Obj.magic,
      "onClick": applyDiffHandler->Obj.magic,
    },
    [Vdom.text("Apply Diff")],
  )

  // Create and append the button
  let buttonElement = Vdom.create(applyDiffButton)
  let _ = Element.appendChild(app, buttonElement)
}
