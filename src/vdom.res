open WebAPI
external htmlCollectionToArray: DOMAPI.htmlCollection => array<DOMAPI.element> = "Array.from"

type rec node =
  | ElementNode({tag: string, properties: dict<unknown>, children: array<node>})
  | TextNode(string)

type diffOperation =
  | Create(node)
  | Remove
  | Replace(node)
  | Modify({remove: array<unknown>, set: dict<unknown>})
  | Nothing

let h = (tag, ~properties=dict{}, children) => {
  ElementNode({
    tag,
    properties,
    children,
  })
}

let text = (str: string): node => {TextNode(str)}

let rec diffOne = (l, r) => {
  switch (l, r) {
  // if text nodes match do nothing
  | (TextNode(tl), TextNode(tr)) if tl == tr => Nothing

  // if text nodes do not match replace
  | (TextNode(tl), TextNode(tr)) if tl != tr => Replace(r)

  // if the tags are not the same just replace
  | (ElementNode(el), ElementNode(er)) if el.tag != er.tag => Replace(r)

  // nodes have the same tag, so figure out what attributes set and removed
  | (ElementNode(l), ElementNode(r)) => {
      // get attributes to remove
      let remove: array<unknown> = []
      Dict.forEachWithKey(l.properties, (_v, k) => {
        switch Dict.get(r.properties, k) {
        | None => Array.push(remove, k->Obj.magic)
        | Some(_) => ()
        }
      })

      // get properties to set
      let set = dict{}
      Dict.forEachWithKey(r.properties, (rv, k) => {
        switch Dict.get(l.properties, k) {
        | Some(lv) if lv == rv => ()
        | _ => Dict.set(set, k, rv)
        }
      })

      Modify({remove, set})
    }
  | (_, _) => Replace(r) // different node types, so replace the node
  }
}
and diffList = (ls, rs) => {
  let length = Math.Int.max(Array.length(ls), Array.length(rs))
  let changeList = []
  for i in 0 to length - 1 {
    switch (ls[i], rs[i]) {
    | (Some(lv), Some(rv)) => Array.push(changeList, diffOne(lv, rv))
    | (Some(_), None) => Array.push(changeList, Remove)
    | (None, Some(rv)) => Array.push(changeList, Create(rv))
    | _ => () // should never get here
    }
  }
  changeList
}

let rec create = vnode => {
  open Document
  // Create a text node or element node
  switch vnode {
  | TextNode(str) => {
      let text = document->createTextNode(str)
      text->Obj.magic
    }
  | ElementNode({tag, properties, children}) => {
      // Create the DOM element with the correct tag and
      // already add our object of listeners to it.
      let el = document->createElement(tag)
      Listeners.setEmptyListeners(el)

      Dict.forEachWithKey(properties, (value, key) => {
        // If it's an event set it otherwise set the value as a property.
        switch Listeners.eventName(key) {
        | Some(event) => {
            let handle: EventAPI.event => unit = Obj.magic(value)
            Listeners.setListener(el, event, handle)
          }
        | None => Properties.setProperty(key, value, el)
        }
      })

      // Recursively create all the children and append one by one.
      Array.forEach(children, vNodeChild => {
        let child = create(vNodeChild)
        let _ = Element.appendChild(el, child->Obj.magic)
      })

      el->Obj.magic
    }
  }
}

let rec modify = (el: DOMAPI.element, ~remove: array<unknown>, ~set: dict<unknown>) => {
  // Remove properties
  Array.forEach(remove, prop => {
    let prop: string = Obj.magic(prop)
    let event = Listeners.eventName(prop)
    switch event {
    | None => el->Element.removeAttribute(prop)
    | Some(evt) => {
        let ui = Listeners.getUI(el)
        // Remove the listener by deleting from the dict
        Dict.delete(ui.listeners, (evt :> string))
        el->Element.removeEventListener(evt, Listeners.listener)
      }
    }
  })

  // Set properties
  Dict.forEachWithKey(set, (value, prop) => {
    let event = Listeners.eventName(prop)
    switch event {
    | Some(evt) => {
        let handle: EventAPI.event => unit = Obj.magic(value)
        Listeners.setListener(el, evt, handle)
      }
    | None => Properties.setProperty(prop, value, el)
    }
  })
}
and apply = (el: DOMAPI.element, childrenDiff) => {
  let children = htmlCollectionToArray(el.children)

  childrenDiff->Array.forEachWithIndex((diff, i) => {
    switch diff {
    | Remove =>
      switch children[i] {
      | Some(child) => Element.remove(child)
      | None => ()
      }
    | Modify(modifyData) =>
      switch children[i] {
      | Some(child) => modify(child, ~remove=modifyData.remove, ~set=modifyData.set)
      | None => ()
      }
    | Create(node) => {
        let child = create(node)
        let _ = Element.appendChild(el, child)
      }
    | Replace(node) => {
        let child = create(node)
        switch children[i] {
        | Some(old_child) => Element.replaceWith(old_child, (child :> DOMAPI.node))
        | None => ()
        }
      }
    | _ => ()
    }
  })
}
